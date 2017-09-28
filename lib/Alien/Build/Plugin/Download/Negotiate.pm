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
 share {
   start_url 'http://ftp.gnu.org/gnu/make';
   plugin 'Download' => (
     filter => qr/^make-.*\.tar.\gz$/,
     version => qr/([0-9\.]+)/,
   );
 };

=head1 DESCRIPTION

This is a negotiator plugin for downloading packages from the internet.  This
plugin picks the best Fetch, Decode and Prefer plugins to do the actual work.
Which plugins are picked depend on the properties you specify, your platform
and environment.  It is usually preferable to use a negotiator plugin rather
than the Fetch, Decode and Prefer plugins directly from your L<alienfile>.

=head1 PROPERTIES

=head2 url

[DEPRECATED] use C<start_url> instead.

The Initial URL for your package.  This may be a directory listing (either in
HTML or ftp listing format) or the final tarball intended to be downloaded.

=cut

has '+url' => undef;

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

=head2 passive

If using FTP, attempt a passive mode transfer first, before trying an active mode transfer.

=cut

has 'passive' => 0;

has 'scheme'  => undef;

=head1 METHODS

=head2 pick

 my($fetch, @decoders) = $plugin->pick;

Returns the fetch plugin and any optional decoders that should be used.

=cut

sub pick
{
  my($self) = @_;
  
  $self->scheme(
    $self->url !~ m!(ftps?|https?|file):!i
      ? 'file'
      : $self->url =~ m!^([a-z]+):!i
  ) unless defined $self->scheme;
  
  if($self->scheme =~ /^https?$/)
  {
    return ('Fetch::HTTPTiny', 'Decode::HTML');
  }
  elsif($self->scheme eq 'ftp')
  {
    if($ENV{ftp_proxy} || $ENV{all_proxy})
    {
      return $self->scheme =~ /^ftps?/
        ? ('Fetch::LWP', 'Decode::DirListing', 'Decode::HTML')
        : ('Fetch::LWP', 'Decode::HTML');
    }
    else
    {
      return ('Fetch::NetFTP');
    }
  }
  elsif($self->scheme eq 'file')
  {
    return ('Fetch::Local');
  }
  else
  {
    die "do not know how to handle scheme @{[ $self->scheme ]} for @{[ $self->url ]}";
  }
}

sub init
{
  my($self, $meta) = @_;
  
  unless(defined $self->url)
  {
    if(defined $meta->prop->{start_url})
    {
      $self->url($meta->prop->{start_url});
    }
    else
    {
      Carp::croak "url is a required property unless you use the start_url directive";
    }
  }
  
  $meta->add_requires('share' => 'Alien::Build::Plugin::Download::Negotiate' => '0.61')
    if $self->passive;

  $meta->prop->{plugin_download_negotiate_default_url} = $self->url;

  my($fetch, @decoders) = $self->pick;
  
  $meta->apply_plugin($fetch,
    url     => $self->url,
    ssl     => $self->ssl,
    ($fetch eq 'Fetch::NetFTP' ? (passive => $self->passive) : ()),
  );
  
  if($self->version)
  {
    $meta->apply_plugin($_) for @decoders;
    $meta->apply_plugin('Prefer::SortVersions', 
      (defined $self->filter ? (filter => $self->filter) : ()),
      version => $self->version,
    );
  }
}

1;

=head1 SEE ALSO

L<Alien::Build>, L<alienfile>, L<Alien::Build::MM>, L<Alien>

=cut
