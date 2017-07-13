package Alien::Build::Plugin::Fetch::HTTPTiny;

use strict;
use warnings;
use Alien::Build::Plugin;
use File::Basename ();
use Carp ();

# ABSTRACT: LWP plugin for fetching files
# VERSION

=head1 SYNOPSIS

 use alienfile;
 meta->prop->{start_url} = 'http://ftp.gnu.org/gnu/make';
 plugin 'Fetch::HTTPTiny' => ();

=head1 DESCRIPTION

Note: in most case you will want to use L<Alien::Build::Plugin::Download::Negotiate>
instead.  It picks the appropriate fetch plugin based on your platform and environment.
In some cases you may need to use this plugin directly instead.

This fetch plugin fetches files and directory listings via the C<http> and C<https>
protocol using L<HTTP::Tiny>.  If the URL specified uses the C<https> scheme, then
the required SSL modules will automatically be injected as requirements.  If your
initial URL is not C<https>, but you know that it will be needed on a subsequent
request you can use the ssl property below.

=head1 PROPERTIES

=head2 url

The initial URL to fetch.  This may be a directory listing (in HTML) or the final file.

=cut

has '+url' => '';

=head2 ssl

If set to true, then the SSL modules required to make an C<https> connection will be
added as prerequisites.

=cut

has ssl => 0;

sub init
{
  my($self, $meta) = @_;

  $meta->add_requires('share' => 'HTTP::Tiny' => '0.044' );
  $meta->add_requires('share' => 'URI' => 0 );

  $meta->prop->{start_url} ||= $self->url;
  $self->url($meta->prop->{start_url});
  $self->url || Carp::croak('url is a required property');

  if($self->url =~ /^https:/ || $self->ssl)
  {
    $meta->add_requires('share' => 'IO::Socket::SSL' => '1.56' );
    $meta->add_requires('share' => 'Net::SSLeay'     => '1.49' );
  }
  
  $meta->register_hook( fetch => sub {
    my(undef, $url) = @_;
    $url ||= $self->url;

    my $ua = HTTP::Tiny->new;
    my $res = $ua->get($url);

    unless($res->{success})
    {
      my $status = $res->{status} || '---';
      my $reason = $res->{reason} || 'unknown';
      die "error fetching $url: $status $reason";
    }

    my($type) = split ';', $res->{headers}->{'content-type'};
    $type = lc $type;
    my $base            = URI->new($res->{url});
    my $filename        = File::Basename::basename do { my $name = $base->path; $name =~ s{/$}{}; $name };

    # TODO: this doesn't get exercised by t/bin/httpd
    if(my $disposition = $res->{headers}->{"content-disposition"})
    {
      # Note: from memory without quotes does not match the spec,
      # but many servers actually return this sort of value.
      if($disposition =~ /filename="([^"]+)"/ || $disposition =~ /filename=([^\s]+)/)
      {
        $filename = $1;
      }
    }
    
    if($type eq 'text/html')
    {
      return {
        type    => 'html',
        base    => $base->as_string,
        content => $res->{content},
      };
    }
    else
    {
      return {
        type     => 'file',
        filename => $filename || 'downloadedfile',
        content  => $res->{content},
      };
    }
    
  });

  $self;
}

1;

=head1 SEE ALSO

L<Alien::Build::Plugin::Download::Negotiate>, L<Alien::Build>, L<alienfile>, L<Alien::Build::MM>, L<Alien>

=cut
