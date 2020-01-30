package Alien::Build::Plugin::Decode::Mojo;

use strict;
use warnings;
use 5.008001;
use Alien::Build::Plugin;

# ABSTRACT: Plugin to extract links from HTML using Mojo::DOM or Mojo::DOM58
# VERSION

=head1 SYNOPSIS

 use alienfile;
 plugin 'Decode::Mojo';

Force using C<Decode::Mojo> via the download negotiator:

 use alienfile 1.68;
 
 configure {
   requires 'Alien::Build::Plugin::Decode::Mojo';
 };
 
 plugin 'Download' => (
   ...
   decoder => 'Decode::Mojo',
 );

=head1 DESCRIPTION

Note: in most cases you will want to use L<Alien::Build::Plugin::Download::Negotiate>
instead.  It picks the appropriate decode plugin based on your platform and environment.
In some cases you may need to use this plugin directly instead.

This plugin decodes an HTML file listing into a list of candidates for your Prefer plugin.
It works just like L<Alien::Build::Plugin::Decode::HTML> except it uses either L<Mojo::DOM>
or L<Mojo::DOM58> to do its job.

This plugin is much lighter than The C<Decode::HTML> plugin, and doesn't require XS.  It
is the default decode plugin used by L<Alien::Build::Plugin::Download::Negotiate> if it
detects that you need to parse an HTML index.

=cut

sub _load ($;$)
{
  my($class, $version) = @_;
  my $pm = "$class.pm";
  $pm =~ s/::/\//g;
  eval { require $pm };
  return 0 if $@;
  if(defined $version)
  {
    eval { $class->VERSION($version) };
    return 0 if $@;
  }
  return 1;
}

has _class => sub {
  return 'Mojo::DOM58' if _load 'Mojo::DOM58';
  return 'Mojo::DOM'   if _load 'Mojo::DOM' && _load 'Mojolicious', 7.00;
  return 'Mojo::DOM58';
};

sub init
{
  my($self, $meta) = @_;

  $meta->add_requires('share' => 'URI' => 0);
  $meta->add_requires('share' => 'URI::Escape' => 0);

  my $class = $meta->prop->{plugin_decode_mojo_class} ||= $self->_class;

  if($class eq 'Mojo::DOM58')
  {
    $meta->add_requires('share' => 'Mojo::DOM58' => '1.00');
  }
  elsif($class eq 'Mojo::DOM')
  {
    $meta->add_requires('share' => 'Mojolicious' => '7.00');
    $meta->add_requires('share' => 'Mojo::DOM'   => '0');
  }
  else
  {
    die "bad class";
  }

  $meta->register_hook( decode => sub {
    my(undef, $res) = @_;

    die "do not know how to decode @{[ $res->{type} ]}"
      unless $res->{type} eq 'html';

    my $dom = $class->new($res->{content});

    my $base = URI->new($res->{base});

    if(my $base_element = $dom->find('head base')->first)
    {
      my $href = $base_element->attr('href');
      $base = URI->new($href) if defined $href;
    }

    my @list = map {
                 my $url = URI->new_abs($_, $base);
                 my $path = $url->path;
                 $path =~ s{/$}{}; # work around for Perl 5.8.7- gh#8
                 {
                   filename => URI::Escape::uri_unescape(File::Basename::basename($path)),
                   url      => URI::Escape::uri_unescape($url->as_string),
                 }
               }
               grep !/^\.\.?\/?$/,
               map { $_->attr('href') || () }
               @{ $dom->find('a')->to_array };

    return {
      type => 'list',
      list => \@list,
    };
  })


}

1;
