package Alien::Build::Plugin::Fetch::LWP;

use strict;
use warnings;
use Alien::Build::Plugin;
use Carp ();

# ABSTRACT: LWP plugin for fetching files
# VERSION

=head1 SYNOPSIS

 use alienfile;
 meta->prop->{start_url} = 'http://ftp.gnu.org/gnu/make';
 plugin 'Fetch::LWP' => ();

=head1 DESCRIPTION

Note: in most case you will want to use L<Alien::Build::Plugin::Download::Negotiate>
instead.  It picks the appropriate fetch plugin based on your platform and environment.
In some cases you may need to use this plugin directly instead.

This fetch plugin fetches files and directory listings via the C<http> C<https>, C<ftp>,
C<file> protocol using L<LWP>.  If the URL specified uses the C<https> scheme, then
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

  $meta->add_requires('share' => 'LWP::UserAgent' => 0 );
  
  $meta->prop->{start_url} ||= $self->url;
  $self->url($meta->prop->{start_url});
  $self->url || Carp::croak('url is a required property');

  if($self->url =~ /^https:/ || $self->ssl)
  {
    $meta->add_requires('share' => 'LWP::Protocol::https' => 0 );
  }

  $meta->register_hook( fetch => sub {
    my(undef, $url) = @_;
    $url ||= $self->url;

    my $ua = LWP::UserAgent->new;
    $ua->env_proxy;
    my $res = $ua->get($url);

    die "error fetching $url: @{[ $res->status_line ]}"
      unless $res->is_success;

    my($type, $charset) = $res->content_type_charset;
    my $base            = $res->base;
    my $filename        = $res->filename;

    if($type eq 'text/html')
    {
      return {
        type    => 'html',
        charset => $charset,
        base    => "$base",
        content => $res->decoded_content,
      };
    }
    elsif($type eq 'text/ftp-dir-listing')
    {
      return {
        type => 'dir_listing',
        base => "$base",
        content => $res->decoded_content,
      };
    }
    else
    {
      return {
        type     => 'file',
        filename => $filename || 'downloadedfile',
        content  => $res->content,
      };
    }
    
  });

  $self;
}

1;

=head1 SEE ALSO

L<Alien::Build::Plugin::Download::Negotiate>, L<Alien::Build>, L<alienfile>, L<Alien::Build::MM>, L<Alien>

=cut
