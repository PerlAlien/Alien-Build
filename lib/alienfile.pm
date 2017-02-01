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

 use alienfile;
 
 probe sub {
   system 'pkg-config', '--exists', 'libarchive';
   $? ? 'share' : 'system';
 };
 
 share {

   # the first one which succeeds will be used
   download [ 'wget http://libarchive.org/downloads/libarchive-3.2.2.tar.gz' ];
   download [ 'curl -o http://libarchive.org/downloads/libarchive-3.2.2.tar.gz' ];
   
   extract [ 'tar xf %{alien.install.download}' ];
   
   plugin 'Build::Autoconf';
   
   build [ 
     '%{configure} --prefix=%{alien.runtime.prefix} --disable-shared',
     '%{make}',
     '%{make} install',
   ];   
 }
 
 sub pkgconfig_value
 {
   my($name, $build, $args) = @_;
   my $value = $args->{out}; # stdout from the pkg-config command
   chomp $value; # probably has \n
   $build->runtime_prop->{$name} = $value;
 }
 
 gather [
   [ 'pkg-config', '--modversion', 'libarchive', sub { pkgconfig_value 'version', @_ } ],
   [ 'pkg-config', '--cflags',     'libarchive', sub { pkgconfig_value 'cflags', @_ }  ],
   [ 'pkg-config', '--libs',       'libarchive', sub { pkgconfig_value 'libs', @_ }    ],
 ];

=head1 DESCRIPTION

An alienfile is a recipe used by L<Alien::Build> to, probe for system libraries or download from the internet, and build source
for those libraries.

=cut

our @EXPORT = qw( requires on plugin probe configure share sys download fetch decode prefer extract patch build gather meta_prop );

=head1 DIRECTIVES

=head2 requires

"any" requirement (either share or system):

 requires $module;
 requires $module => $verson;

configure time requirement:

 configure {
   requires $module;
   requires $module => $verson;
 };

system requirement:

 sys {
   requires $module;
   requires $module => $verson;
 };

share requirement:

 share {
   requires $module;
   requires $module => $verson;
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
 plugin '=Badly::Named::Plugin::Not::In::Alien::Build::Namespace' => ();

 # explicitly loads Alien::Build::Plugin::Prefer::SortVersions
 plugin 'Prefer::SortVersions => (
   filter => qr/^gcc-.*\.tar.gz$/,
   version => qr/([0-9\.]+)/,
 );
 
=cut

sub plugin
{
  my($name, @args) = @_;
  
  my $class;
  my $pm;
  my $found;
  
  if($name =~ /^=(.*)$/)
  {
    $class = $1;
    $pm    = $class;
    $pm =~ s!::!/!g;
    $pm .= ".pm";
    $found = 1;
  }
  
  if($name !~ /::/ && ! $found)
  {
    foreach my $inc (@INC)
    {
      # TODO: allow negotiators to work with
      # @INC hooks
      next if ref $inc;
      my $file = _path("$inc/Alien/Build/Plugin/$name/Negotiate.pm");
      if(-r $file)
      {
        $class = "Alien::Build::Plugin::${name}::Negotiate";
        $pm    = "Alien/Build/Plugin/$name/Negotiate.pm";
        $found = 1;
        last;
      }
    }
  }
  
  unless($found)
  {
    $class = "Alien::Build::Plugin::$name";
    $pm    = do {
      my $name = $name;
      $name =~ s!::!/!g;
      "Alien/Build/Plugin/$name.pm";
    };
  }
  
  unless($INC{$pm})
  {
    require $pm;
  }
  my $caller = caller;
  my $plugin = $class->new(@args);
  $plugin->init($caller->meta);
  return;
}

=head2 probe

 probe $code;
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

=head2 download

 share {
   download $code;
   download \@commandlist;
 };

Instructions for the download stage.  May be either a
code reference, or a command list.

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
   fetch $code;
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
   decode $code;
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
   prefer $code;
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
   extract $code;
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
   patch $code;
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
  $caller->meta->register_hook(patch => $instr);
  return;
}

=head2 build

 share {
   build $code;
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
  $caller->meta->register_hook(build => $instr);
  return;
}

=head2 gather

 gather $code;
 gather \@commandlist;
 
 share {
   gather $code;
   gather \@commandlist;
 };
 
 sys {
   gather $code;
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
  $meta->register_hook(gather_system => $instr) if $phase =~ /^(any|system)$/;
  $meta->register_hook(gather_share => $instr)  if $phase =~ /^(any|share)$/;
  return;;
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

sub import
{
  strict->import;
  warnings->import;
  goto &Exporter::import;
}

1;

=head1 SEE ALSO

L<Alien::Build>, L<Alien::Build::MM>, L<Alien::Base>

=cut
