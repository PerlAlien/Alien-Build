package Alien::Build::Plugin::Download::Negotiate;

use strict;
use warnings;
use Alien::Build::Plugin;
use Module::Load ();
use Carp ();

# ABSTRACT: Download negotiation plugin
# VERSION

=head1 SYNOPSIS

 use alienfile;
 plugin 'Download' => (
   url => 'http://ftp.gnu.org/gnu/make',
   filter => qr/^make-.*\.tar.\gz$/,
   version => qr/([0-9\.]+)/,
 );

=head1 DESCRIPTION

This is a negotiator plugin for downloading packages from the internet.  This
plugin picks the best Fetch, Decode and Prefer plugins to do the actual work.
Which plugins are picked depend on the properties you specify, your platform
and environment.  It is usually preferable to use a negotiator plugin rather
than the Fetch, Decode and Prefer plugins directly from your L<alienfile>.

=head1 PROPERTIES

=head2 url

The Initial URL for your package.  This may be a directory listing (either in
HTML or ftp listing format) or the final tarball intended to be downloaded.

=cut

has '+url' => sub { Carp::croak "url is a required property" };

=head2 filter

This is a regular expression that lets you filter out files that you do not
want to consider downloading.  For example, if the directory listing contained
tarballs and readme files like this:

 foo-1.0.0.tar.gz
 foo-1.0.0.readme

You could specify a filter of C<qr/\.tar\.gz$/> to make sure only tarballs are
considered for download.

=cut

has 'filter'  => undef;

=head2 version

Regular expression to parse out the version from a filename.  The regular expression
should store the result in C<$1>.

=cut

has 'version' => undef;

=head2 ssl

If your initial URL does not need SSL, but you know ahead of time that a subsequent
request will need it (for example, if your directory listing is on C<http>, but includes
links to C<https> URLs), then you can set this property to true, and the appropriate
Perl SSL modules will be loaded.

=cut

has 'ssl'     => 0;
has 'scheme'  => undef;

sub _pick_fetch
{
  my($self) = @_;
  
  $self->scheme(
    $self->url !~ m!(ftps?|https?|file):!i
      ? 'file'
      : $self->url =~ m!^([a-z]+):!i
  ) unless defined $self->scheme;
  
  if($self->scheme =~ /^https?$/)
  {
    return 'HTTPTiny';
  }
  elsif($self->scheme eq 'ftp')
  {
    if($ENV{ftp_proxy} || $ENV{all_proxy})
    {
      return 'LWP';
    }
    else
    {
      return 'NetFTP';
    }
  }
  elsif($self->scheme eq 'file')
  {
    return 'Local';
  }
  else
  {
    die "do not know how to handle scheme @{[ $self->scheme ]} for @{[ $self->url ]}";
  }
}

sub init
{
  my($self, $meta) = @_;
  
  $meta->prop->{plugin_download_negotiate_default_url} = $self->url;

  my $fetch = $self->_pick_fetch;
  
  $self->_plugin($meta, 'Fetch', $fetch, url => $self->url, ssl => $self->ssl);
  
  if($self->version)
  {
    if($fetch eq 'NetFTP' || $fetch eq 'Local')
    {
      # no decoder necessary
    }
    elsif($fetch eq 'LWP' && $self->scheme =~ /^ftps?/)
    {
      # could be either a DirListing or HTML !
      $self->_plugin($meta, 'Decode', 'DirListing');
      $self->_plugin($meta, 'Decode', 'HTML');
    }
    else
    {
      $self->_plugin($meta, 'Decode', 'HTML');
    }
    
    $self->_plugin($meta, 'Prefer', 'SortVersions', 
      (defined $self->filter ? (filter => $self->filter) : ()),
      version => $self->version,
    );
  }
}

sub _plugin
{
  my($self, $meta, $type, $name, @args) = @_;
  my $class = "Alien::Build::Plugin::${type}::$name";
  Module::Load::load($class);
  my $plugin = $class->new(@args);
  $plugin->init($meta);
}

1;

=head1 SEE ALSO

L<Alien::Build>, L<alienfile>, L<Alien::Build::MM>, L<Alien>

=cut
