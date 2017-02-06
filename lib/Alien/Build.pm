package Alien::Build;

use strict;
use warnings;
use Path::Tiny ();
use Carp ();
use File::chdir;
use JSON::PP ();
use Env qw( @PATH );

# ABSTRACT: Build external dependencies for use in CPAN
# VERSION

=head1 SYNOPSIS

 my $build = Alien::Build->load('./alienfile');
 $build->load_requires('configure');
 $build->set_prefix('/usr/local');
 $build->set_stage('/foo/mystage');  # needs to be absolute
 $build->load_requires($build->install_type);
 $build->download;
 $build->build;
 # files are now in /foo/mystage, it is your job (or
 # ExtUtils::MakeMaker, Module::Build, etc) to copy
 # those files into /usr/local

=head1 DESCRIPTION

B<NOTE>: This is still experimental, and documentation is currently highly
incomplete.

This module provides tools for building external (non-CPAN) dependencies 
for CPAN.  It is mainly designed to be used at install time of a CPAN 
client, and work closely with L<Alien::Base> which is used at runtime.

This is the detailed documentation for L<Alien::Build> class.  If you are
starting out as a user of an L<Alien::Build> based L<Alien> module, see
L<Alien::Build::Manual::AlienUser>.  If you are starting out writing a new
L<Alien::Build> based L<Alien> module, see L<Alien::Build::Manual::ALienAuthor>.
As an L<Alien> author, you will also likely be interested in
L<Alien::Build::Manual::FAQ>.  If you are interested in writing a
L<Alien::Build> plugin, see L<Alien::Build::Manual::PluginAuthor>.

Note that you will usually not usually create a L<Alien::Build> instance
directly, but rather be using a thin installer layer, such as
L<Alien::Build::MM> (for use with L<ExtUtils::MakeMaker>).  One of the
goals of this project is to remain installer agnostic.

=cut

sub _path { goto \&Path::Tiny::path }

=head1 CONSTRUCTOR

=head2 new

 my $build = Alien::Build->new;

This creates a new empty instance of L<Alien::Build>.  Normally you will
want to use C<load> below to create an instance of L<Alien::Build> from
an L<alienfile> recipe.

=cut

sub new
{
  my($class, %args) = @_;
  my $self = bless {
    install_prop => {
      root  => _path($args{root} || "_alien")->absolute->stringify,
      patch => (defined $args{patch}) ? _path($args{patch})->absolute->stringify : undef,
    },
    runtime_prop => {
    },
    bin_dir => [],
  }, $class;
  
  $self->meta->filename(
    $args{filename} || do {
      my(undef, $filename) = caller;
      _path($filename)->absolute->stringify;
    }
  );
  
  $self;
}

=head1 PROPERTIES

There are three main properties for L<Alien::Build>.  There are a number
of properties documented here with a specific usage.  Note that these
properties may need to be serialized into something primitive like JSON
that does not support: regular expressions, code references of blessed
objects.

If you are writing a plugin (L<Alien::Build::Plugin>) you should use a 
prefix like "plugin_I<name>" (where I<name> is the name of your plugin) 
so that it does not interfere with other plugin or future versions of
L<Alien::Build>.  For example, if you were writing
C<Alien::Build::Plugin::Fetch::NewProtocol>, please use the prefix
C<plugin_fetch_newprotocol>:

 sub init
 {
   my($self, $meta) = @_;
   
   $meta->prop( plugin_fetch_newprotocol_foo => 'some value' );
   
   $meta->register_hook(
     some_hook => sub {
       my($build) = @_;
       $build->install_prop->{plugin_fetch_newprotocol_bar => 'some other value' );
       $build->runtime_prop->{plugin_fetch_newprotocol_baz => 'and another value' );
     }
   );
 }

If you are writing a L<alienfile> recipe please use the prefix C<my_>:

 use alienfile;
 
 meta_prop->{my_foo} = 'some value';
 
 probe sub {
   my($build) = @_;
   $build->install_prop->{my_bar} = 'some other value';
   $build->install_prop->{my_baz} = 'and another value';
 };

Any property may be used from a command:

 probe [ 'some command %{alien.meta.plugin_fetch_newprotocol_foo}' ];
 probe [ 'some command %{alien.install.plugin_fetch_newprotocol_bar}' ];
 probe [ 'some command %{alien.runtime.plugin_fetch_newprotocol_baz}' ];
 probe [ 'some command %{alien.meta.my_foo}' ];
 probe [ 'some command %{alien.install.my_bar}' ];
 probe [ 'some command %{alien.runtime.my_baz}' ];

=head2 meta_prop

 my $href = $build->meta_prop;
 my $href = Alien::Build->meta_prop;

Meta properties have to do with the recipe itself, and not any particular
instance that probes or builds that recipe.  Meta properties can be changed
from within an L<alienfile> using the C<meta_prop> directive, or from
a plugin from its C<init> method (though should NOT be modified from any
hooks registered within that C<init> method).  This is not strictly enforced,
but if you do not follow this rule your recipe will likely be broken.

=over

=item arch

This is a hint to an installer like L<Alien::Build::MM> or L<Alien::Build::MB>,
that the library or tool contains architecture dependent files and so should
be stored in an architecture dependent location.  If not specified by your
L<alienfile> then it will be set to true.

=item destdir

Use the C<DESTDIR> environment variable to stage your install before
copying the files into C<blib>.  This is the preferred method of
installing libraries because it improves reliability.  This technique
is supported by C<autoconf> and others.

=item destdir_filter

Regular expression for the files that should be copied from the C<DESTDIR>
into the stage directory.  If not defined, then all files will be copied.

=item platform

Hash reference.  Contains information about the platform beyond just C<$^O>.

=over 4

=item compiler_type

Refers to the type of flags that the compiler accepts.  May be expanded in the
future, but for now, will be one of:

=over 4

=item microsoft

On Windows when using Microsoft Visual C++

=item unix

Virtually everything else, including gcc on windows.

=back

The main difference is that with Visual C++ C<-LIBPATH> should be used instead
of C<-L>, and static libraries should have the C<.LIB> suffix instead of C<.a>.

=back

=back

=cut

sub meta_prop
{
  my($class) = @_;
  $class->meta->prop;
}

=head2 install_prop

 my $href = $build->install_prop;

Install properties are used during the install phase (either
under C<share> or C<system> install).  They are remembered for
the entire install phase, but not kept around during the runtime
phase.  Thus they cannot be accessed from your L<Alien::Base>
based module.

=over

=item root

The build root directory.  This will be an absolute path.  It is the
absolute form of C<./_alien> by default.

=item patch

Directory with patches.

=item prefix

The install time prefix.  Under a C<destdir> install this is the
same as the runtime or final install location.  Under a non-C<destdir>
install this is the C<stage> directory (usually the appropriate
share directory under C<blib>).

=item autoconf_prefix

The prefix as understood by autoconf.  This is only different on Windows
Where MSYS is used and paths like C<C:/foo> are  represented as C</C/foo>
which are understood by the MSYS tools, but not by Perl.  You should
only use this if you are using L<Alien::Build::Plugin::Autoconf> in
your L<alienfile>.

=item stage

The stage directory where files will be copied.  This is usually the
root of the blib share directory.

=back

=cut

sub install_prop
{
  shift->{install_prop};
}

=head2 runtime_prop

 my $href = $build->runtime_prop;

Runtime properties are used during the install and runtime phases
(either under C<share> or C<system> install).  This should include
anything that you will need to know to use the library or tool
during runtime, and shouldn't include anything that is no longer
relevant once the install process is complete.

=over 4

=item cflags

The compiler flags

=item cflags_static

The static compiler flags

=item command

The command name for tools where the name my differ from platform to
platform.  For example, the GNU version of make is usually C<make> in
Linux and C<gmake> on FreeBSD.

=item libs

The library flags

=item libs_static

The static library flags

=item version

The version of the library or tool

=item prefix

The final install root.  This is usually they share directory.

=item install_type

The install type.  Is one of:

=over

=item system

For when the library or tool is provided by the operating system, can be
detected by L<Alien::Build>, and is considered satisfactory by the
C<alienfile> recipe.

=item share

For when a system install is not possible, the library source will be
downloaded from the internet or retrieved in another appropriate fashion
and built.

=back

=back

=cut

sub runtime_prop
{
  shift->{runtime_prop};
}

=head1 METHODS

=head2 load

 my $build = Alien::Build->load($alienfile);

This creates an L<Alien::Build> instance with the given L<alienfile>
recipe.

=cut

my $count = 0;

sub load
{
  my(undef, $alienfile, @args) = @_;

  unless(-r $alienfile)
  {
    require Carp;
    Carp::croak "Unable to read alienfile: $alienfile";
  }

  my $file = _path $alienfile;
  my $name = $file->parent->basename;
  $name =~ s/^alien-//i;
  $name =~ s/[^a-z]//g;
  $name = 'x' if $name eq '';
  $name = ucfirst $name;

  my $class = "Alien::Build::Auto::$name@{[ $count++ ]}";

  { no strict 'refs';  
  @{ "${class}::ISA" } = ('Alien::Build');
  *{ "${class}::Alienfile::meta" } = sub {
    my($class) = @_;
    $class =~ s{::Alienfile$}{};
    $class->meta;
  }};

  my @preload = qw( Core::Setup );
  @preload = split ';', $ENV{ALIEN_BUILD_PRELOAD}
    if defined $ENV{ALIEN_BUILD_PRELOAD};
  
  my @postload = qw( Core::Legacy Core::Gather );
  @postload = split ';', $ENV{ALIEN_BUILD_POSTLOAD}
    if defined $ENV{ALIEN_BUILD_POSTLOAD};

  my $self = $class->new(
    filename => $file->absolute->stringify,
    @args,
  );
  
  require alienfile;

  eval '# line '. __LINE__ . ' "' . __FILE__ . qq("\n) . qq{
    package ${class}::Alienfile;
    alienfile::plugin(\$_) for \@preload;
    do '@{[ $file->absolute->stringify ]}';
    die \$\@ if \$\@;
    alienfile::plugin(\$_) for \@postload;
  };
  die $@ if $@;
  
  $self->{args} = \@args;
  unless(defined $self->meta->prop->{arch})
  {
    $self->meta->prop->{arch} = 1;
  }

  return $self;
}

=head2 checkpoint

 $build->checkpoint;

Save any install or runtime properties so that they can be reloaded on
a subsequent run.  This is useful if your build needs to be done in
multiple stages from a C<Makefile>, such as with L<ExtUtils::MakeMaker>.

=cut

sub checkpoint
{
  my($self) = @_;
  my $root = $self->root;
  _path("$root/state.json")->spew(
    JSON::PP->new->pretty->encode({
      install => $self->install_prop,
      runtime => $self->runtime_prop,
      args    => $self->{args},
    })
  );
  $self;
}

=head2 resume

 my $build = Alien::Build->resume($alienfile, $root);

Load a checkpointed L<Alien::Build> instance.  You will need the original
L<alienfile> and the build root (usually C<_alien>).

=cut

sub resume
{
  my(undef, $alienfile, $root) = @_;
  my $h = JSON::PP::decode_json(_path("$root/state.json")->slurp);
  my $self = Alien::Build->load("$alienfile", @{ $h->{args} });
  $self->{install_prop} = $h->{install};
  $self->{runtime_prop} = $h->{runtime};
  $self;
}

=head2 root

 my $dir = $build->root;

This is just a shortcut for:

 my $root = $build->install_prop->{root};

Except that it will be created if it does not already exist.  

=cut

sub root
{
  my($self) = @_;
  my $root = $self->install_prop->{root};
  _path($root)->mkpath unless -d $root;
  $root;
}

=head2 install_type

 my $type = $build->install_type;

This will return the install type.  (See the like named install property
above for details).  This method will call C<probe> if it has not already
been called.

=cut

sub install_type
{
  my($self) = @_;
  $self->{runtime_prop}->{install_type} ||= $self->probe;
}

=head2 set_prefix

 $build->set_prefix($prefix);

Set the final (unstaged) prefix.  This is normally only called by L<Alien::Build::MM>
and similar modules.  It is not intended for use from plugins or from an L<alienfile>.

=cut

sub set_prefix
{
  my($self, $prefix) = @_;
  
  if($self->meta_prop->{destdir})
  {
    $self->runtime_prop->{prefix} = 
    $self->install_prop->{prefix} = $prefix;
  }
  else
  {
    $self->runtime_prop->{prefix} = $prefix;
    $self->install_prop->{prefix} = $self->install_prop->{stage};
  }
}

=head2 set_stage

 $build->set_stage($dir);

Sets the stage directory.  This is normally only called by L<Alien::Build::MM>
and similar modules.  It is not intended for use from plugins or from an L<alienfile>.

=cut

sub set_stage
{
  my($self, $dir) = @_;
  $self->install_prop->{stage} = $dir;
}

sub _merge
{
  my %h;
  while(@_)
  {
    my $mod = shift;
    my $ver = shift;
    if((!defined $h{$mod}) || $ver > $h{$mod})
    { $h{$mod} = $ver }
  }
  \%h;
}

=head2 requires

 my $hash = $build->requires($phase);

Returns a hash reference of the modules required for the given phase.  Phases
include:

=over 4

=item configure

These modules must already be available when the L<alienfile> is read.

=item any

These modules are used during either a C<system> or C<share> install.

=item share

These modules are used during the build phase of a C<share> install.

=item system

These modules are used during the build phase of a C<system> install.

=back

=cut

sub requires
{
  my($self, $phase) = @_;
  $phase ||= 'any';
  my $meta = $self->meta;
  $phase =~ /^(?:any|configure)$/
  ? $meta->{require}->{$phase}
  : _merge %{ $meta->{require}->{any} }, %{ $meta->{require}->{$phase} };
}

=head2 load_requires

 $build->load_requires($phase);

This loads the appropriate modules for the given phase (see C<requires> above
for a description of the phases).

=cut

sub load_requires
{
  my($self, $phase) = @_;
  my $reqs = $self->requires($phase);
  foreach my $mod (keys %$reqs)
  {
    my $ver = $reqs->{$mod};
    eval qq{ use $mod @{[ $ver ? $ver : '' ]} () };
    die if $@;
    if($mod->can('bin_dir'))
    {
      push @{ $self->{bin_dir} }, $mod->bin_dir;
    }
  }
  1;
}

sub _call_hook
{
  my $self = shift;
  
  local $ENV{PATH} = $ENV{PATH};
  unshift @PATH, @{ $self->{bin_dir} };
  
  my $config = ref($_[0]) eq 'HASH' ? shift : {};
  my($name, @args) = @_;
  $self->meta->call_hook( $config, $name => $self, @args );
}

=head2 probe

 my $install_type = $build->probe;

Attempts to determine if the operating system has the library or
tool already installed.  If so, then the string C<system> will
be returned and a system install will be performed.  If not,
then the string C<share> will be installed and the tool or
library will be downloaded and built from source.

If the environment variable C<ALIEN_INSTALL_TYPE> is set, then that
will force a specific type of install.  If the detection logic
cannot accommodate the install type requested then it will fail with
an exception.

=cut

sub probe
{
  my($self) = @_;
  local $CWD = $self->root;
  my $dir;
  
  my $env = $ENV{ALIEN_INSTALL_TYPE} || '';
  my $type;
  my $error;
  
  if($env eq 'share')
  {
    $type = 'share';
  }
  else
  {
    $type = eval {
      $self->_call_hook(
        {
          before   => sub {
            $dir = Alien::Build::TempDir->new($self, "probe");
            $CWD = "$dir";
          },
          after    => sub {
            $CWD = $self->root;
          },
          ok       => 'system',
          continue => sub { $_[0] ne 'system' },
        },
        'probe',
      );
    };
    $error = $@;
    $type = 'share' unless defined $type;
  }
  
  if($error)
  {
    if($env eq 'system')
    {
      die $error;
    }
    $self->log("error in probe (will do a share install): $@");
    $type = 'share';
  }
  
  if($env && $env ne $type)
  {
    die "requested $env install not available";
  }
  
  if($type !~ /^(system|share)$/)
  {
    Carp::croak "probe hook returned something other than system or share: $type";
  }
  
  $self->runtime_prop->{install_type} = $type;
  
  $type;
}

=head2 download

 $build->download;

Download the source, usually as a tarball, usually from the internet.

Under a C<system> install this does not do anything.

=cut

sub download
{
  my($self) = @_;
  
  return $self unless $self->install_type eq 'share';
  return $self if $self->install_prop->{complete}->{download};
  
  if($self->meta->has_hook('download'))
  {
    my $tmp;
    local $CWD;
    my $valid = 0;
    
    $self->_call_hook(
      {
        before => sub {
          $tmp = Alien::Build::TempDir->new($self, "download");
          $CWD = "$tmp";
        },
        verify => sub {
          my @list = grep { $_->basename !~ /^\./, } _path('.')->children;
    
          my $count = scalar @list;
    
          if($count == 0)
          {
            die "no files downloaded";
          }
          elsif($count == 1)
          {
            my($archive) = $list[0];
            if(-d $archive)
            {
              $self->log("single dir, assuming directory");
            }
            else
            {
              $self->log("single file, assuming archive");
            }
            $self->install_prop->{download} = $archive->absolute->stringify;
            $self->install_prop->{complete}->{download} = 1;
            $valid = 1;
          }
          else
          {
            $self->log("multiple files, assuming directoryn");
            $self->install_prop->{complete}->{download} = 1;
            $self->install_prop->{download} = _path('.')->absolute->stringify;
            $valid = 1;
          }   
        },
        after  => sub {
          $CWD = $self->root;
        },
      },
      'download',
    );
    
    return $self if $valid;
  }
  else
  {
    my $res = $self->fetch;

    if($res->{type} =~ /^(?:html|dir_listing)$/)
    {
      my $type = $res->{type};
      $type =~ s/_/ /;
      $self->log("decoding $type");
      $res = $self->decode($res);
    }
    
    if($res->{type} eq 'list')
    {
      $res = $self->prefer($res);
      my $version = $res->{list}->[0]->{version};
      die "no matching files in listing" if @{ $res->{list} } == 0;
      my($pick, @other) = map { $_->{url} } @{ $res->{list} };
      if(@other > 8)
      {
        splice @other, 7;
        push @other, '...';
      }
      $self->log("candidate *$pick");
      $self->log("candidate  $_") for @other;
      $res = $self->fetch($pick);
      
      if($version)
      {
        $version =~ s/\.+$//;
        $self->log("setting version based on archive to $version");
        $self->install_prop->{version} = $version;
      }
    }

    my $tmp = Alien::Build::TempDir->new($self, "download");
    
    if($res->{type} eq 'file')
    {
      my $alienfile = $res->{filename};
      $self->log("downloaded $alienfile");
      if($res->{content})
      {
        my $path = _path("$tmp/$alienfile");
        $path->spew_raw($res->{content});
        $self->install_prop->{download} = $path->stringify;
        $self->install_prop->{complete}->{download} = 1;
        return $self;
      }
      elsif($res->{path})
      {
        require File::Copy;
        my $from = _path $res->{path};
        my $to   = _path("$tmp/@{[ $from->basename ]}");
        File::Copy::copy(
          "$from" => "$to",
        ) || die "copy $from => $to failed: $!";
        $self->install_prop->{download} = $to->stringify;
        $self->install_prop->{complete}->{download} = 1;
        return $self;
      }
      die "file without content or path";
    }
    
    die "unknown fetch response type: @{[ $res->{type} ]}";
  }
  
  die "download failed";
}

=head2 fetch

 my $res = $build->fetch;
 my $res = $build->fetch($url);

Fetch a resource using the fetch hook.  Returns the same hash structure
described below in the hook documentation.

=cut

sub fetch
{
  my($self, $url) = @_;
  $self->_call_hook( 'fetch' => $url );
}

=head2 decode

 my $decoded_res = $build->decode($res);

Decode the HTML or file listing returned by C<fetch>.  Returns the same
hash structure described below in the hook documentation.

=cut

sub decode
{
  my($self, $res) = @_;
  $self->_call_hook( decode => $res );
}

=head2 prefer

 my $sorted_res = $build->prefer($res);

Filter and sort candidates.  The preferred candidate will be returned first in the list.
The worst candidate will be returned last.  Returns the same hash structure described
below in the hook documentation.

=cut

sub prefer
{
  my($self, $res) = @_;
  $self->_call_hook( prefer => $res );
}

=head2 extract

 my $dir = $build->extract;
 my $dir = $build->extract($archive);

Extracts the given archive into a fresh directory.  This is normally called internally
to L<Alien::Build>, and for normal usage is not needed from a plugin or L<alienfile>.

=cut

sub extract
{
  my($self, $archive) = @_;
  
  $archive ||= $self->install_prop->{download};
  
  unless(defined $archive)
  {
    die "tried to call extract before download";
  }
  
  my $tmp;
  local $CWD;
  my $ret;

  $self->_call_hook({
  
    before => sub {
      # called build instead of extract, because this 
      # will be used for the build step, and technically
      # extract is a substage of build anyway.
      $tmp = Alien::Build::TempDir->new($self, "build");
      $CWD = "$tmp";
    },
    verify => sub {
      my @list = grep { $_->basename !~ /^\./, } _path('.')->children;
      
      my $count = scalar @list;
      
      if($count == 0)
      {
        die "no files extracted";
      }
      elsif($count == 1 && -d $list[0])
      {
        $ret = $list[0]->absolute->stringify;
      }
      else
      {
        $ret = "$tmp";
      }
    
    },
    after => sub {
      $CWD = $self->root;
    },
  
  }, 'extract', $archive);
  
  $ret ? $ret : ();
}

=head2 build

 $build->build;

Run the build step.  It is expected that C<probe> and C<download>
have already been performed.  What it actually does depends on the
type of install:

=over 4

=item share

The source is extracted, and built as determined by the L<alienfile>
recipe.  If there is a C<gather_share> that will be executed last.

=item system

The C<gather_system> hook will be executed.

=back

=cut

sub build
{
  my($self) = @_;

  # save the evironment, in case some plugins decide
  # to alter it.  Or us!  See just a few lines below.
  local %ENV = %ENV;
  
  my $stage = _path($self->install_prop->{stage});
  $stage->mkpath;
  
  if($self->install_type eq 'share')
  {
    local $CWD;
  
    unless($self->meta_prop->{destdir})
    {
      delete $ENV{DESTDIR};
    }
  
    %ENV = (%ENV, %{ $self->meta_prop->{env} || {} });
    %ENV = (%ENV, %{ $self->install_prop->{env} || {} });
  
    my $destdir;
  
    $self->_call_hook(
    {
      before => sub {
        $CWD = $self->extract;
        if($self->meta_prop->{destdir})
        {
          $destdir = Alien::Build::TempDir->new($self, 'destdir');
          $ENV{DESTDIR} = "$destdir";
        }
        $self->_call_hook({ all => 1 }, 'patch');
      },
      after => sub {
        $destdir = "$destdir" if $destdir;
      },
    }, 'build');
  
  
    $self->_call_hook('gather_share');
  }
  
  elsif($self->install_type eq 'system')
  {
    local $CWD = $self->root;
    my $dir;
  
    $self->_call_hook(
      {
        before => sub {
          $dir = Alien::Build::TempDir->new($self, "gather");
          $CWD = "$dir";
        },
        after  => sub {
          $CWD = $self->root;
        },
      },
      'gather_system',
    );
  
    $self->install_prop->{finished} = 1;
    $self->install_prop->{complete}->{gather_system} = 1;  
  }
  
  $self;
}

=head2 log

 $build->log($message);

Send a message to the log.  By default this prints to C<STDOUT>.

=cut

sub log
{
  my(undef, $message) = @_;
  my $caller = caller;
  chomp $message;
  print "$caller> $message\n";
}

=head2 meta

 my $meta = Alien::Build->meta;
 my $meta = $build->meta;

Returns the meta object for your L<Alien::Build> class or instance.  The
meta object is a way to manipulate the recipe, and so any changes to the
meta object should be made before the C<probe>, C<download> or C<build> steps.

=cut

{
  my %meta;

  sub meta
  {
    my($class) = @_;
    $class = ref $class if ref $class;
    $meta{$class} ||= Alien::Build::Meta->new( class => $class );
  }
}

package Alien::Build::Meta;

our @CARP_NOT = qw( alienfile );

sub new
{
  my($class, %args) = @_;
  my $self = bless {
    phase => 'any',
    require => {
      any    => {},
      share  => {},
      system => {},
    },
    around => {},
    prop => {},
    %args,
  }, $class;
  $self;
}

=head1 META METHODS

=head2 prop

 my $href = $build->meta->prop;
 my $href = Alien::Build->meta->prop;

Meta properties.  This is the same as calling C<meta_prop> on
the class or L<Alien::Build> instance.

=cut

sub prop
{
  shift->{prop};
}

sub filename
{
  my($self, $new) = @_;
  $self->{filename} = $new if defined $new;
  $self->{filename};
}

=head2 add_requires

 Alien::Build->meta->add_requires($phase, $module => $version, ...);

Add the requirement to the given phase.  Phase should be one of:

=over 4

=item configure

=item any

=item share

=item system

=back

=cut

sub add_requires
{
  my $self = shift;
  my $phase = shift;
  while(@_)
  {
    my $module = shift;
    my $version = shift;
    my $old = $self->{require}->{$phase}->{$module};
    if((!defined $old) || $version > $old)
    { $self->{require}->{$phase}->{$module} = $version }
  }
  $self;
}

=head2 interpolator

 my $interpolator = $build->meta->interpolator;
 my $interpolator = Alien::Build->interpolator;

Returns the L<Alien::Build::Interpolate> instance for the L<Alien::Build> class.

=cut

sub interpolator
{
  my($self, $new) = @_;
  if(defined $new)
  {
    if(defined $self->{intr})
    {
      Carp::croak "tried to set interpolator twice";
    }
    if(ref $new)
    {
      $self->{intr} = $new;
    }
    else
    {
      $self->{intr} = $new->new;
    }
  }
  elsif(!defined $self->{intr})
  {
    require Alien::Build::Interpolate::Default;
    $self->{intr} = Alien::Build::Interpolate::Default->new;
  }
  $self->{intr};
}

=head2 has_hook

 my $bool = $build->meta->has_hook($name);
 my $bool = Alien::Build->has_hook($name);

Returns if there is a usable hook registered with the given name.

=cut

sub has_hook
{
  my($self, $name) = @_;
  defined $self->{hook}->{$name};
}

=head2 register_hook

 $build->meta->register_hook($name, $instructions);
 Alien::Build->meta->register_hook($name, $instructions);

Register a hook with the given name.  C<$instruction> should be either
a code reference, or a command sequence, which is an array reference.

=cut

sub _instr
{
  my($self, $name, $instr) = @_;
  if(ref($instr) eq 'CODE')
  {
    return $instr;
  }
  elsif(ref($instr) eq 'ARRAY')
  {
    my %phase = (
      download      => 'share',
      fetch         => 'share',
      decode        => 'share',
      prefer        => 'share',
      extract       => 'share',
      patch         => 'share',
      build         => 'share',
      stage         => 'share',
      gather_share  => 'share',
      gather_system => 'system',
    );
    require Alien::Build::CommandSequence;
    my $seq = Alien::Build::CommandSequence->new(@$instr);
    $seq->apply_requirements($self, $phase{$name} || 'any');
    return $seq;
  }
  else
  {
    Carp::croak "type not supported as a hook";
  }
}

sub register_hook
{
  my($self, $name, $instr) = @_;
  push @{ $self->{hook}->{$name} }, _instr $self, $name, $instr;
  $self;
}

=head2 default_hook

 $build->meta->default_hook($name, $instructions);
 Alien::Build->meta->default_hook($name, $instructions);

Register a default hook, which will be used if the L<alienfile> does not
register its own hook with that name.

=cut

sub default_hook
{
  my($self, $name, $instr) = @_;
  $self->{default_hook}->{$name} = _instr $self, $name, $instr;
  $self;
}

=head2 around_hook

 $build->meta->around_hook($hook, $code);
 Alien::Build->meta->around_hook($name, $code);

Wrap the given hook with a code reference.  This is similar to a L<Moose>
method modifier, except that it wraps around the given hook instead of
a method.  For example, this will add a probe system requirement:

 $build->meta->around_hook(
   probe => sub {
     my $orig = shift;
     my $build = shift;
     my $type = $orig->($build, @_);
     return $type unless $type eq 'system';
     # also require a configuration file
     if(-f '/etc/foo.conf')
     {
       return 'system';
     }
     else
     {
       return 'share';
     }
   },
 );

=cut

sub around_hook
{
  my($self, $name, $code) = @_;
  if(my $old = $self->{around}->{$name})
  {
    # this is the craziest shit I have ever
    # come up with.
    $self->{around}->{$name} = sub {
      my $orig = shift;
      $code->(sub { $old->($orig, @_) }, @_);
    };
  }
  else
  {
    $self->{around}->{$name} = $code;
  }
}

sub after_hook
{
  my($self, $name, $code) = @_;
  $self->around_hook(
    $name => sub {
      my $orig = shift;
      my $ret = $orig->(@_);
      $code->(@_);
      $ret;
    }
  );
}

sub before_hook
{
  my($self, $name, $code) = @_;
  $self->around_hook(
    $name => sub {
      my $orig = shift;
      $code->(@_);
      my $ret = $orig->(@_);
      $ret;
    }
  );
}


sub call_hook
{
  my $self = shift;
  my %args = ref $_[0] ? %{ shift() } : ();
  my($name, @args) = @_;
  my $error;
  
  my @hooks = @{ $self->{hook}->{$name} || []};
  
  if(@hooks == 0)
  {
    if(defined $self->{default_hook}->{$name})
    {
      @hooks = ($self->{default_hook}->{$name})
    }
    elsif(!$args{all})
    {
      Carp::croak "No hooks registered for $name";
    }
  }
  
  my $value;

  foreach my $hook (@hooks)
  {
    my $wrapper = $self->{around}->{$name} || sub { my $code = shift; $code->(@_) };
    my $value;
    $args{before}->() if $args{before};
    if(ref($hook) eq 'CODE')
    {
      $value = eval {
        my $value = $wrapper->(sub { $hook->(@_) }, @args);
        $args{verify}->('code') if $args{verify};
        $value;
      };
    }
    else
    {
      $value = $wrapper->(sub {
        eval {
          $hook->execute(@_);
          $args{verify}->('command') if $args{verify};
        };
        defined $args{ok} ? $args{ok} : 1;
      }, @args);
    }
    $error = $@;
    $args{after}->() if $args{after};
    if($args{all})
    {
      die if $error;
    }
    else
    {
      next if $error;
      next if $args{continue} && $args{continue}->($value);
      return $value;
    }
  }
  
  die $error if $error && ! $args{all};
  
  $value;
}

package Alien::Build::TempDir;

use Path::Tiny qw( path );
use overload '""' => sub { shift->as_string };
use File::Temp qw( tempdir );

sub new
{
  my($class, $build, $name) = @_;
  my $root = $build->install_prop->{root};
  path($root)->mkpath unless -d $root;
  bless {
    dir => path(tempdir( "${name}_XXXX", DIR => $root)),
  }, $class;
}

sub as_string
{
  shift->{dir}->stringify;
}

sub DESTROY
{
  my($self) = @_;
  if(-d $self->{dir} && $self->{dir}->children == 0)
  {
    rmdir($self->{dir}) || warn "unable to remove @{[ $self->{dir} ]} $!";
  }
}

1;

=head1 ENVIRONMENT

L<Alien::Build> responds to these environment variables:

=over 4

=item ALIEN_INSTALL_TYPE

If set to C<share> or C<system>, it will override the system detection logic.

=item ALIEN_BUILD_PRELOAD

semicolon separated list of plugins to automatically load before parsing
your L<alienfile>.

=item ALIEN_BUILD_PRELOAD

semicolon separated list of plugins to automatically load after parsing
your L<alienfile>.

=item DESTDIR

This environment variable will be manipulated during a destdir install.

=item PKG_CONFIG

This environment variable can be used to override the program name for C<pkg-config>
for some PkgConfig plugins: L<Alien::Build::Plugin::PkgConfig>.

=item ftp_proxy, all_proxy

If these environment variables are set, it may influence the Download negotiation
plugin L<Alien::Build::Plugin::Downaload::Negotiate>.  Other proxy variables may
be used by some Fetch plugins, if they support it.

=back

=head1 SEE ALSO

L<Alien::Build::Manual::AlienAuthor>,
L<Alien::Build::Manual::AlienUser>,
L<Alien::Build::Manual::Contributing>,
L<Alien::Build::Manual::FAQ>,
L<Alien::Build::Manual::PluginAuthor>

L<alienfile>, L<Alien::Build::MM>, L<Alien::Build::Plugin>, L<Alien::Base>, L<Alien>

=cut
