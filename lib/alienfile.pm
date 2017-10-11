package alienfile;

use strict;
use warnings;
use Alien::Build;
use base qw( Exporter );
use Path::Tiny ();
use Carp ();

sub _path { Path::Tiny::path(@_) }

# ABSTRACT: Specification for defining an external dependency for CPAN
# VERSION

=head1 SYNOPSIS

Do-it-yourself approach:

 use alienfile;
 
 probe [ 'pkg-config --exists libarchive' ];
 
 share {
   
   start_url 'http://libarchive.org/downloads/libarchive-3.2.2.tar.gz';
   
   # the first one which succeeds will be used
   download [ 'wget %{.meta.start_url}' ];
   download [ 'curl -o %{.meta.start_url}' ];
   
   extract [ 'tar xf %{.install.download}' ];
   
   build [ 
     # Note: will not work on Windows, better to use Build::Autoconf plugin
     # if you need windows support
     './configure --prefix=%{.install.prefix} --disable-shared',
     '%{make}',
     '%{make} install',
   ];   
 }
 
 gather [
   [ 'pkg-config', '--modversion', 'libarchive', \'%{.runtime.version}' ],
   [ 'pkg-config', '--cflags',     'libarchive', \'%{.runtime.cflags}'  ],
   [ 'pkg-config', '--libs',       'libarchive', \'%{.runtime.libs}'    ],
 ];

With plugins (better):

 use alienfile;
 
 plugin 'PkgConfig' => 'libarchive';
 
 share {
   start_url 'http://libarchive.org/downloads/';
   plugin Download => (
     filter => qr/^libarchive-.*\.tar\.gz$/,
     version => qr/([0-9\.]+)/,
   );
   plugin Extract => 'tar.gz';
   plugin 'Build::Autoconf';
   build [
     '%{configure} --disable-shared',
     '%{make}',
     '%{make} install',
   ];
 };

=head1 DESCRIPTION

An alienfile is a recipe used by L<Alien::Build> to, probe for system libraries or download from the internet, and build source
for those libraries.

=cut

our @EXPORT = qw( requires on plugin probe configure share sys download fetch decode prefer extract patch patch_ffi build build_ffi gather gather_ffi meta_prop ffi log test start_url );

=head1 DIRECTIVES

=head2 requires

"any" requirement (either share or system):

 requires $module;
 requires $module => $version;

configure time requirement:

 configure {
   requires $module;
   requires $module => $version;
 };

system requirement:

 sys {
   requires $module;
   requires $module => $version;
 };

share requirement:

 share {
   requires $module;
   requires $module => $version;
 };

specifies a requirement.  L<Alien::Build> takes advantage of dynamic requirements, so only
modules that are needed for the specific type of install need to be loaded.  Here are the
different types of requirements:

=over

=item configure

Configure requirements should already be installed before the alienfile is loaded.

=item any

"Any" requirements are those that are needed either for the probe stage, or in either the
system or share installs.

=item share

Share requirements are those modules needed when downloading and building from source.

=item system

System requirements are those modules needed when the system provides the library or tool.

=back

=cut

sub requires
{
  my($module, $version) = @_;
  $version ||= 0;
  my $caller = caller;
  my $meta = $caller->meta;
  $meta->add_requires($meta->{phase}, $module, $version);
  ();
}

=head2 plugin

 plugin $name => (%args);
 plugin $name => $arg;

Load the given plugin.  If you prefix the plugin name with an C<=> sign,
then it will be assumed to be a fully qualified path name.  Otherwise the
plugin will be assumed to live in the C<Alien::Build::Plugin> namespace.
If there is an appropriate negotiate plugin, that one will be loaded.
Examples:

 # Loads Alien::Build::Plugin::Fetch::Negotiate
 # which will pick the best Alien::Build::Plugin::Fetch
 # plugin based on the URL, and system configuration
 plugin 'Fetch' => 'http://ftp.gnu.org/gnu/gcc';
 
 # loads the plugin with the badly named class!
 plugin '=Badly::Named::Plugin::Not::In::Alien::Build::Namespace';

 # explicitly loads Alien::Build::Plugin::Prefer::SortVersions
 plugin 'Prefer::SortVersions => (
   filter => qr/^gcc-.*\.tar\.gz$/,
   version => qr/([0-9\.]+)/,
 );
 
=cut

sub plugin
{
  my($name, @args) = @_;
  
  my $caller = caller;
  $caller->meta->apply_plugin($name, @args);
  return;
}

=head2 probe

 probe \&code;
 probe \@commandlist;

Instructions for the probe stage.  May be either a
code reference, or a command list.

=cut

sub probe
{
  my($instr) = @_;
  my $caller = caller;
  if(my $phase = $caller->meta->{phase})
  {
    Carp::croak "probe must not be in a $phase block" if $phase ne 'any';
  }
  $caller->meta->register_hook(probe => $instr);
  return;
}

=head2 configure

 configure {
   ...
 };

Configure block.  The only directive allowed in a configure block is
requires.

=cut

sub _phase
{
  my($code, $phase) = @_;
  my $caller = caller(1);
  my $meta = $caller->meta;
  local $meta->{phase} = $phase;
  $code->();
  return;
}

sub configure (&)
{
  _phase($_[0], 'configure');
}

=head2 sys

 sys {
   ...
 };

System block.  Allowed directives are: requires and gather.

=cut

sub sys (&)
{
  _phase($_[0], 'system');
}


=head2 share

 share {
   ...
 };

System block.  Allowed directives are: download, fetch, decode, prefer, extract, build, gather.

=cut

sub share (&)
{
  _phase($_[0], 'share');
}

=head2 start_url

 share {
   start_url $url;
 };

Set the start URL for download.  This should be the URL to an index page, or the actual tarball of the source.

=cut

sub _in_phase
{
  my($phase) = @_;
  my $caller = caller(1);
  my(undef, undef, undef, $sub) = caller(1);
  my $meta = $caller->meta;
  $sub =~ s/^.*:://;
  Carp::croak "$sub must be in a $phase block"
    unless $meta->{phase} eq $phase;
}

sub start_url
{
  my($url) = @_;
  _in_phase 'share';
  my $caller = caller;
  my $meta = $caller->meta;
  $meta->prop->{start_url} = $url;
  $meta->add_requires('configure' => 'Alien::Build' => '1.19');
  return;
}

=head2 download

 share {
   download \&code;
   download \@commandlist;
 };

Instructions for the download stage.  May be either a
code reference, or a command list.

=cut

sub download
{
  my($instr) = @_;
  _in_phase 'share';
  my $caller = caller;
  $caller->meta->register_hook(download => $instr);
  return;
}

=head2 fetch

 share {
   fetch \&code;
   fetch \@commandlist;
 };

Instructions for the fetch stage.  May be either a
code reference, or a command list.

=cut

sub fetch
{
  my($instr) = @_;
  _in_phase 'share';
  my $caller = caller;
  $caller->meta->register_hook(fetch => $instr);
  return;
}

=head2 decode

 share {
   decode \&code;
   decode \@commandlist;
 };

Instructions for the decode stage.  May be either a
code reference, or a command list.

=cut

sub decode
{
  my($instr) = @_;
  _in_phase 'share';
  my $caller = caller;
  $caller->meta->register_hook(decode => $instr);
  return;
}

=head2 prefer

 share {
   prefer \&code;
   prefer \@commandlist;
 };

Instructions for the prefer stage.  May be either a
code reference, or a command list.

=cut

sub prefer
{
  my($instr) = @_;
  _in_phase 'share';
  my $caller = caller;
  $caller->meta->register_hook(prefer => $instr);
  return;
}

=head2 extract

 share {
   extract \&code;
   extract \@commandlist;
 };

Instructions for the extract stage.  May be either a
code reference, or a command list.

=cut

sub extract
{
  my($instr) = @_;
  _in_phase 'share';
  my $caller = caller;
  $caller->meta->register_hook(extract => $instr);
  return;
}

=head2 patch

 share {
   patch \&code;
   patch \@commandlist;
 };

Instructions for the patch stage.  May be either a
code reference, or a command list.

=cut

sub patch
{
  my($instr) = @_;
  _in_phase 'share';
  my $caller = caller;
  my $suffix = $caller->meta->{build_suffix};
  $caller->meta->register_hook("patch$suffix" => $instr);
  return;
}

=head2 patch_ffi

 share {
   patch_ffi \&code;
   patch_ffi \@commandlist;
 };

[DEPRECATED]

Instructions for the patch_ffi stage.  May be either a
code reference, or a command list.

=cut

sub patch_ffi
{
  my($instr) = @_;
  Carp::carp("patch_ffi is deprecated, use ffi { patch ... } } instead");
  _in_phase 'share';
  my $caller = caller;
  $caller->meta->register_hook(patch_ffi => $instr);
  return;
}

=head2 build

 share {
   build \&code;
   build \@commandlist;
 };

Instructions for the build stage.  May be either a
code reference, or a command list.

=cut

sub build
{
  my($instr) = @_;
  _in_phase 'share';
  my $caller = caller;
  my $suffix = $caller->meta->{build_suffix};
  $caller->meta->register_hook("build$suffix" => $instr);
  return;
}

=head2 build_ffi

 share {
   build \&code;
   build \@commandlist;
 };

[DEPRECATED]

Instructions for the build FFI stage.  Builds shared libraries instead of static.
This is optional, and is only necessary if a fresh and separate build needs to be
done for FFI.

=cut

sub build_ffi
{
  my($instr) = @_;
  Carp::carp("build_ffi is deprecated, use ffi { build ... } } instead");
  _in_phase 'share';
  my $caller = caller;
  $caller->meta->register_hook(build_ffi => $instr);
  return;
}

=head2 gather

 gather \&code;
 gather \@commandlist;
 
 share {
   gather \&code;
   gather \@commandlist;
 };
 
 sys {
   gather \&code;
   gather \@commandlist;
 };

Instructions for the gather stage.  May be either a code reference, or a command list.
In the root block of the alienfile it will trigger in both share and system build.
In the share or sys block it will only trigger in the corresponding build.

=cut

sub gather
{
  my($instr) = @_;
  my $caller = caller;
  my $meta = $caller->meta;
  my $phase = $meta->{phase};
  Carp::croak "gather is not allowed in configure block"
    if $phase eq 'configure';
  my $suffix = $caller->meta->{build_suffix};
  if($suffix eq '_ffi')
  {
    $meta->register_hook(gather_ffi => $instr)
  }
  else
  {
    $meta->register_hook(gather_system => $instr) if $phase =~ /^(any|system)$/;
    $meta->register_hook(gather_share => $instr)  if $phase =~ /^(any|share)$/;
  }
  return;
}

=head2 gather_ffi

 share {
   gather_ffi \&code;
   gather_ffi \@commandlist;
 }

[DEPRECATED]

Gather specific to C<build_ffi>.  Not usually necessary.

=cut

sub gather_ffi
{
  my($instr) = @_;
  Carp::carp("gather_ffi is deprecated, use ffi { gather ... } } instead");
  _in_phase 'share';
  my $caller = caller;
  $caller->meta->register_hook(gather_ffi => $instr);
  return;
}

=head2 ffi

 share {
   ffi {
     patch \&code;
     patch \@commandlist;
     build \&code;
     build \@commandlist;
     gather \&code;
     gather \@commandlist;
   }
 }

Specify patch, build or gather stages related to FFI.

=cut

sub ffi (&)
{
  my($code) = @_;
  _in_phase 'share';
  my $caller = caller;
  local $caller->meta->{build_suffix} = '_ffi';
  $code->();
  return;
}

=head2 meta_prop

 my $hash = meta_prop;

Get the meta_prop hash reference.

=cut

sub meta_prop
{
  my $caller = caller;
  my $meta = $caller->meta;
  $meta->prop;
}

=head2 meta

 my $meta = meta;

Returns the meta object for your L<alienfile>.

=head2 log

 log($message);

Prints the given log to stdout.

=cut

sub log
{
  unshift @_, 'Alien::Build';
  goto &Alien::Build::log;
}

=head2 test

 share {
   test \&code;
   test \@commandlist;
 };
 sys {
   test \&code;
   test \@commandlist;
 };

Run the tests

=cut

sub test
{
  my($instr) = @_;
  my $caller = caller;
  my $meta = $caller->meta;
  my $phase = $meta->{phase};
  Carp::croak "test is not allowed in $phase block"
    if $phase eq 'any' || $phase eq 'configure';
  
  $meta->add_requires('configure' => 'Alien::Build' => '1.14');
  
  if($phase eq 'share')
  {
    my $suffix = $caller->meta->{build_suffix} || '_share';
    $meta->register_hook(
      "test$suffix" => $instr,
    );
  }
  elsif($phase eq 'system')
  {
    $meta->register_hook(
      "test_system" => $instr,
    );
  }
  else
  {
    die "unknown phase: $phase";
  }
}

sub import
{
  strict->import;
  warnings->import;
  goto &Exporter::import;
}

1;

=head1 SEE ALSO

=over 4

=item L<Alien>

=item L<Alien::Build>

=item L<Alien::Build::MM>

=item L<Alien::Base>

=back

=cut
