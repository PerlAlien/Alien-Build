package Alien::Build::Plugin::Download::Negotiate;

use strict;
use warnings;
use Alien::Build::Plugin;
use Module::Load ();
use Alien::Build::Util qw( _has_ssl );
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

=head2 bootstrap_ssl

If set to true, then the download negotiator will avoid using plugins that have a dependency
on L<Net::SSLeay>, or other Perl SSL modules.  The intent for this option is to allow
OpenSSL to be alienized and be a useful optional dependency for L<Net::SSLeay>.

The implementation may improve over time, but as of this writing, this option relies on you
having a working C<curl> or C<wget> with SSL support in your C<PATH>.

=cut

has 'bootstrap_ssl' => 0;

=head2 prefer

How to sort candidates for selection.  This should be one of three types of values:

=over 4

=item code reference

This will be used as the prefer hook.

=item true value

Use L<Alien::Build::Plugin::Prefer::SortVersions>.

=item false value

Don't set any preference at all.  A hook must be installed, or another prefer plugin specified.

=back

=cut

has 'prefer' => 1;

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

  if($self->scheme eq 'https' || ($self->scheme eq 'http' && $self->ssl))
  {
    if($self->bootstrap_ssl && ! _has_ssl)
    {
      return (['Fetch::CurlCommand','Fetch::Wget'], 'Decode::HTML');
    }
    elsif(_has_ssl)
    {
      return ('Fetch::HTTPTiny', 'Decode::HTML');
    }
    elsif(do { require Alien::Build::Plugin::Fetch::CurlCommand; Alien::Build::Plugin::Fetch::CurlCommand->protocol_ok('https') })
    {
      return ('Fetch::CurlCommand', 'Decode::HTML');
    }
    else
    {
      return ('Fetch::HTTPTiny', 'Decode::HTML');
    }
  }
  elsif($self->scheme eq 'http')
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

  $fetch = [ $fetch ] unless ref $fetch;

  foreach my $fetch (@$fetch)
  {
    my @args;
    push @args, ssl => $self->ssl;
    # For historical reasons, we pass the URL into older fetch plugins, because
    # this used to be the interface.  Using start_url is now preferred!
    push @args, url => $self->url if $fetch =~ /^Fetch::(HTTPTiny|LWP|Local|LocalDir|NetFTP|CurlCommand)$/;
    push @args, passive => $self->passive if $fetch eq 'Fetch::NetFTP';
    push @args, bootstrap_ssl => $self->bootstrap_ssl if $self->bootstrap_ssl;

    $meta->apply_plugin($fetch, @args);
  }

  if($self->version)
  {
    $meta->apply_plugin($_) for @decoders;

    if(defined $self->prefer && ref($self->prefer) eq 'CODE')
    {
      $meta->add_requires('share' => 'Alien::Build::Plugin::Download::Negotiate' => '1.30');
      $meta->register_hook(
        prefer => $self->prefer,
      );
    }
    elsif($self->prefer)
    {
      $meta->apply_plugin('Prefer::SortVersions',
        (defined $self->filter ? (filter => $self->filter) : ()),
        version => $self->version,
      );
    }
    else
    {
      $meta->add_requires('share' => 'Alien::Build::Plugin::Download::Negotiate' => '1.30');
    }
  }
}

1;

=head1 SEE ALSO

L<Alien::Build>, L<alienfile>, L<Alien::Build::MM>, L<Alien>

=cut
