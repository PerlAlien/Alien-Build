# Alien::Build [![Build Status](https://secure.travis-ci.org/Perl5-Alien/Alien-Build.png)](http://travis-ci.org/Perl5-Alien/Alien-Build) [![Build status](https://ci.appveyor.com/api/projects/status/22odutjphx45248s/branch/master?svg=true)](https://ci.appveyor.com/project/Perl5-Alien/Alien-Build/branch/master)

Build external dependencies for use in CPAN

# SYNOPSIS

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

# DESCRIPTION

This module provides tools for building external (non-CPAN) dependencies 
for CPAN.  It is mainly designed to be used at install time of a CPAN 
client, and work closely with [Alien::Base](https://metacpan.org/pod/Alien::Base) which is used at runtime.

This is the detailed documentation for the [Alien::Build](https://metacpan.org/pod/Alien::Build) class.
If you
are starting out you probably want to do so from one of these documents:

- [Alien::Build::Manual::AlienUser](https://metacpan.org/pod/Alien::Build::Manual::AlienUser)

    For users of an `Alien::libfoo` that is implemented using [Alien::Base](https://metacpan.org/pod/Alien::Base).
    (The developer of `Alien::libfoo` _should_ provide the documentation
    necessary, but if not, this is the place to start).

- [Alien::Build::Manual::AlienAuthor](https://metacpan.org/pod/Alien::Build::Manual::AlienAuthor)

    If you are writing your own [Alien](https://metacpan.org/pod/Alien) based on [Alien::Build](https://metacpan.org/pod/Alien::Build) and [Alien::Base](https://metacpan.org/pod/Alien::Base).

- [Alien::Build::Manual::FAQ](https://metacpan.org/pod/Alien::Build::Manual::FAQ)

    If you have a common question that has already been answered, like
    "How do I use [alienfile](https://metacpan.org/pod/alienfile) with some build system".

- [Alien::Build::Manual::PluginAuthor](https://metacpan.org/pod/Alien::Build::Manual::PluginAuthor)

    This is for the brave souls who want to write plugins that will work with
    [Alien::Build](https://metacpan.org/pod/Alien::Build) + [alienfile](https://metacpan.org/pod/alienfile).

Note that you will usually not usually create a [Alien::Build](https://metacpan.org/pod/Alien::Build) instance
directly, but rather be using a thin installer layer, such as
[Alien::Build::MM](https://metacpan.org/pod/Alien::Build::MM) (for use with [ExtUtils::MakeMaker](https://metacpan.org/pod/ExtUtils::MakeMaker)).  One of the
goals of this project is to remain installer agnostic.

# CONSTRUCTOR

## new

    my $build = Alien::Build->new;

This creates a new empty instance of [Alien::Build](https://metacpan.org/pod/Alien::Build).  Normally you will
want to use `load` below to create an instance of [Alien::Build](https://metacpan.org/pod/Alien::Build) from
an [alienfile](https://metacpan.org/pod/alienfile) recipe.

# PROPERTIES

There are three main properties for [Alien::Build](https://metacpan.org/pod/Alien::Build).  There are a number
of properties documented here with a specific usage.  Note that these
properties may need to be serialized into something primitive like JSON
that does not support: regular expressions, code references of blessed
objects.

If you are writing a plugin ([Alien::Build::Plugin](https://metacpan.org/pod/Alien::Build::Plugin)) you should use a 
prefix like "plugin\__name_" (where _name_ is the name of your plugin) 
so that it does not interfere with other plugin or future versions of
[Alien::Build](https://metacpan.org/pod/Alien::Build).  For example, if you were writing
`Alien::Build::Plugin::Fetch::NewProtocol`, please use the prefix
`plugin_fetch_newprotocol`:

    sub init
    {
      my($self, $meta) = @_;
      
      $meta->prop( plugin_fetch_newprotocol_foo => 'some value' );
      
      $meta->register_hook(
        some_hook => sub {
          my($build) = @_;
          $build->install_prop->{plugin_fetch_newprotocol_bar} = 'some other value';
          $build->runtime_prop->{plugin_fetch_newprotocol_baz} = 'and another value';
        }
      );
    }

If you are writing a [alienfile](https://metacpan.org/pod/alienfile) recipe please use the prefix `my_`:

    use alienfile;
    
    meta_prop->{my_foo} = 'some value';
    
    probe sub {
      my($build) = @_;
      $build->install_prop->{my_bar} = 'some other value';
      $build->install_prop->{my_baz} = 'and another value';
    };

Any property may be used from a command:

    probe [ 'some command %{.meta.plugin_fetch_newprotocol_foo}' ];
    probe [ 'some command %{.install.plugin_fetch_newprotocol_bar}' ];
    probe [ 'some command %{.runtime.plugin_fetch_newprotocol_baz}' ];
    probe [ 'some command %{.meta.my_foo}' ];
    probe [ 'some command %{.install.my_bar}' ];
    probe [ 'some command %{.runtime.my_baz}' ];

## meta\_prop

    my $href = $build->meta_prop;
    my $href = Alien::Build->meta_prop;

Meta properties have to do with the recipe itself, and not any particular
instance that probes or builds that recipe.  Meta properties can be changed
from within an [alienfile](https://metacpan.org/pod/alienfile) using the `meta_prop` directive, or from
a plugin from its `init` method (though should NOT be modified from any
hooks registered within that `init` method).  This is not strictly enforced,
but if you do not follow this rule your recipe will likely be broken.

- arch

    This is a hint to an installer like [Alien::Build::MM](https://metacpan.org/pod/Alien::Build::MM) or [Alien::Build::MB](https://metacpan.org/pod/Alien::Build::MB),
    that the library or tool contains architecture dependent files and so should
    be stored in an architecture dependent location.  If not specified by your
    [alienfile](https://metacpan.org/pod/alienfile) then it will be set to true.

- destdir

    Use the `DESTDIR` environment variable to stage your install before
    copying the files into `blib`.  This is the preferred method of
    installing libraries because it improves reliability.  This technique
    is supported by `autoconf` and others.

- destdir\_filter

    Regular expression for the files that should be copied from the `DESTDIR`
    into the stage directory.  If not defined, then all files will be copied.

- destdir\_ffi\_filter

    Same as `destdir_filter` except applies to `build_ffi` instead of `build`.

- env

    Environment variables to override during the build stage.

- local\_source

    Set to true if source code package is available locally.  (that is not fetched
    over the internet).  This is computed by default based on the `start_url`
    property.  Can be set by an [alienfile](https://metacpan.org/pod/alienfile) or plugin.

- platform

    Hash reference.  Contains information about the platform beyond just `$^O`.

    - compiler\_type

        Refers to the type of flags that the compiler accepts.  May be expanded in the
        future, but for now, will be one of:

        - microsoft

            On Windows when using Microsoft Visual C++

        - unix

            Virtually everything else, including gcc on windows.

        The main difference is that with Visual C++ `-LIBPATH` should be used instead
        of `-L`, and static libraries should have the `.LIB` suffix instead of `.a`.

    - system\_type

        `$^O` is frequently good enough to make platform specific logic in your
        [alienfile](https://metacpan.org/pod/alienfile), this handles the case when $^O can cover platforms that provide
        multiple environments that Perl might run under.  The main example is windows,
        but others may be added in the future.

        - unix
        - vms
        - windows-activestate
        - windows-microsoft
        - windows-mingw
        - windows-strawberry
        - windows-unknown

        Note that `cygwin` and `msys` are considered `unix` even though they run
        on windows!

- out\_of\_source

    Build in a different directory from the where the source code is stored.
    In autoconf this is referred to as a "VPATH" build.  Everyone else calls this
    an "out-of-source" build.  When this property is true, instead of extracting
    to the source build root, the downloaded source will be extracted to an source
    extraction directory and the source build root will be empty.  You can use the
    `extract` install property to get the location of the extracted source.

- network

    True if a network fetch is available.  This should NOT be set by an [alienfile](https://metacpan.org/pod/alienfile)
    or plugin.  This is computed based on the `NO_NETWORK_TESTING` and 
    `ALIEN_INSTALL_NETWORK` environment variables.

- start\_url

    The default or start URL used by fetch plugins.

## install\_prop

    my $href = $build->install_prop;

Install properties are used during the install phase (either
under `share` or `system` install).  They are remembered for
the entire install phase, but not kept around during the runtime
phase.  Thus they cannot be accessed from your [Alien::Base](https://metacpan.org/pod/Alien::Base)
based module.

- autoconf\_prefix

    The prefix as understood by autoconf.  This is only different on Windows
    Where MSYS is used and paths like `C:/foo` are  represented as `/C/foo`
    which are understood by the MSYS tools, but not by Perl.  You should
    only use this if you are using [Alien::Build::Plugin::Autoconf](https://metacpan.org/pod/Alien::Build::Plugin::Autoconf) in
    your [alienfile](https://metacpan.org/pod/alienfile).

- download

    The location of the downloaded archive (tar.gz, or similar) or directory.

- env

    Environment variables to override during the build stage.

- extract

    The location of the last source extraction.  For a "out-of-source" build
    (see the `out_of_source` meta property above), this will only be set once.
    For other types of builds, the source code may be extracted multiple times,
    and thus this property may change.

- old

    Hash containing information on a previously installed Alien of the same
    name, if available.  This may be useful in cases where you want to
    reuse the previous install if it is still sufficient.

    - prefix

        The prefix for the previous install.

    - runtime

        The runtime properties from the previous install.

- patch

    Directory with patches.

- prefix

    The install time prefix.  Under a `destdir` install this is the
    same as the runtime or final install location.  Under a non-`destdir`
    install this is the `stage` directory (usually the appropriate
    share directory under `blib`).

- root

    The build root directory.  This will be an absolute path.  It is the
    absolute form of `./_alien` by default.

- stage

    The stage directory where files will be copied.  This is usually the
    root of the blib share directory.

## runtime\_prop

    my $href = $build->runtime_prop;

Runtime properties are used during the install and runtime phases
(either under `share` or `system` install).  This should include
anything that you will need to know to use the library or tool
during runtime, and shouldn't include anything that is no longer
relevant once the install process is complete.

- alien\_build\_version

    The version of [Alien::Build](https://metacpan.org/pod/Alien::Build) used to install the library or tool.

- alt

    Alternate configurations.  If the alienized package has multiple
    libraries this could be used to store the different compiler or
    linker flags for each library.

- cflags

    The compiler flags

- cflags\_static

    The static compiler flags

- command

    The command name for tools where the name my differ from platform to
    platform.  For example, the GNU version of make is usually `make` in
    Linux and `gmake` on FreeBSD.

- ffi\_name

    The name DLL or shared object "name" to use when searching for dynamic
    libraries at runtime.  This is passed into [FFI::CheckLib](https://metacpan.org/pod/FFI::CheckLib), so if
    your library is something like `libarchive.so` or `archive.dll` you
    would set this to `archive`.  This may be a string or an array of 
    strings.

- install\_type

    The install type.  Is one of:

    - system

        For when the library or tool is provided by the operating system, can be
        detected by [Alien::Build](https://metacpan.org/pod/Alien::Build), and is considered satisfactory by the
        `alienfile` recipe.

    - share

        For when a system install is not possible, the library source will be
        downloaded from the internet or retrieved in another appropriate fashion
        and built.

- libs

    The library flags

- libs\_static

    The static library flags

- perl\_module\_version

    The version of the Perl module used to install the alien (if available).
    For example if [Alien::curl](https://metacpan.org/pod/Alien::curl) is installing `libcurl` this would be the
    version of [Alien::curl](https://metacpan.org/pod/Alien::curl) used during the install step.

- prefix

    The final install root.  This is usually they share directory.

- version

    The version of the library or tool

## hook\_prop

    my $href = $build->hook_prop;

Hook properties are for the currently running (if any) hook.  They are
used only during the execution of each hook and are discarded after.
If no hook is currently running then `hook_prop` will return `undef`.

- name

    The name of the currently running hook.

# METHODS

## load

    my $build = Alien::Build->load($alienfile);

This creates an [Alien::Build](https://metacpan.org/pod/Alien::Build) instance with the given [alienfile](https://metacpan.org/pod/alienfile)
recipe.

## checkpoint

    $build->checkpoint;

Save any install or runtime properties so that they can be reloaded on
a subsequent run.  This is useful if your build needs to be done in
multiple stages from a `Makefile`, such as with [ExtUtils::MakeMaker](https://metacpan.org/pod/ExtUtils::MakeMaker).

## resume

    my $build = Alien::Build->resume($alienfile, $root);

Load a checkpointed [Alien::Build](https://metacpan.org/pod/Alien::Build) instance.  You will need the original
[alienfile](https://metacpan.org/pod/alienfile) and the build root (usually `_alien`).

## root

    my $dir = $build->root;

This is just a shortcut for:

    my $root = $build->install_prop->{root};

Except that it will be created if it does not already exist.  

## install\_type

    my $type = $build->install_type;

This will return the install type.  (See the like named install property
above for details).  This method will call `probe` if it has not already
been called.

## set\_prefix

    $build->set_prefix($prefix);

Set the final (unstaged) prefix.  This is normally only called by [Alien::Build::MM](https://metacpan.org/pod/Alien::Build::MM)
and similar modules.  It is not intended for use from plugins or from an [alienfile](https://metacpan.org/pod/alienfile).

## set\_stage

    $build->set_stage($dir);

Sets the stage directory.  This is normally only called by [Alien::Build::MM](https://metacpan.org/pod/Alien::Build::MM)
and similar modules.  It is not intended for use from plugins or from an [alienfile](https://metacpan.org/pod/alienfile).

## requires

    my $hash = $build->requires($phase);

Returns a hash reference of the modules required for the given phase.  Phases
include:

- configure

    These modules must already be available when the [alienfile](https://metacpan.org/pod/alienfile) is read.

- any

    These modules are used during either a `system` or `share` install.

- share

    These modules are used during the build phase of a `share` install.

- system

    These modules are used during the build phase of a `system` install.

## load\_requires

    $build->load_requires($phase);

This loads the appropriate modules for the given phase (see `requires` above
for a description of the phases).

## probe

    my $install_type = $build->probe;

Attempts to determine if the operating system has the library or
tool already installed.  If so, then the string `system` will
be returned and a system install will be performed.  If not,
then the string `share` will be installed and the tool or
library will be downloaded and built from source.

If the environment variable `ALIEN_INSTALL_TYPE` is set, then that
will force a specific type of install.  If the detection logic
cannot accommodate the install type requested then it will fail with
an exception.

## download

    $build->download;

Download the source, usually as a tarball, usually from the internet.

Under a `system` install this does not do anything.

## fetch

    my $res = $build->fetch;
    my $res = $build->fetch($url);

Fetch a resource using the fetch hook.  Returns the same hash structure
described below in the hook documentation.

## decode

    my $decoded_res = $build->decode($res);

Decode the HTML or file listing returned by `fetch`.  Returns the same
hash structure described below in the hook documentation.

## prefer

    my $sorted_res = $build->prefer($res);

Filter and sort candidates.  The preferred candidate will be returned first in the list.
The worst candidate will be returned last.  Returns the same hash structure described
below in the hook documentation.

## extract

    my $dir = $build->extract;
    my $dir = $build->extract($archive);

Extracts the given archive into a fresh directory.  This is normally called internally
to [Alien::Build](https://metacpan.org/pod/Alien::Build), and for normal usage is not needed from a plugin or [alienfile](https://metacpan.org/pod/alienfile).

## build

    $build->build;

Run the build step.  It is expected that `probe` and `download`
have already been performed.  What it actually does depends on the
type of install:

- share

    The source is extracted, and built as determined by the [alienfile](https://metacpan.org/pod/alienfile)
    recipe.  If there is a `gather_share` that will be executed last.

- system

    The `gather_system` hook will be executed.

## test

    $build->test;

Run the test phase

## system

    $build->system($command);
    $build->system($command, @args);

Interpolates the command and arguments and run the results using
the Perl `system` command.

## log

    $build->log($message);

Send a message to the log.  By default this prints to `STDOUT`.

## meta

    my $meta = Alien::Build->meta;
    my $meta = $build->meta;

Returns the meta object for your [Alien::Build](https://metacpan.org/pod/Alien::Build) class or instance.  The
meta object is a way to manipulate the recipe, and so any changes to the
meta object should be made before the `probe`, `download` or `build` steps.

# META METHODS

## prop

    my $href = $build->meta->prop;

Meta properties.  This is the same as calling `meta_prop` on
the class or [Alien::Build](https://metacpan.org/pod/Alien::Build) instance.

## add\_requires

    Alien::Build->meta->add_requires($phase, $module => $version, ...);

Add the requirement to the given phase.  Phase should be one of:

- configure
- any
- share
- system

## interpolator

    my $interpolator = $build->meta->interpolator;
    my $interpolator = Alien::Build->interpolator;

Returns the [Alien::Build::Interpolate](https://metacpan.org/pod/Alien::Build::Interpolate) instance for the [Alien::Build](https://metacpan.org/pod/Alien::Build) class.

## has\_hook

    my $bool = $build->meta->has_hook($name);
    my $bool = Alien::Build->has_hook($name);

Returns if there is a usable hook registered with the given name.

## register\_hook

    $build->meta->register_hook($name, $instructions);
    Alien::Build->meta->register_hook($name, $instructions);

Register a hook with the given name.  `$instruction` should be either
a code reference, or a command sequence, which is an array reference.

## default\_hook

    $build->meta->default_hook($name, $instructions);
    Alien::Build->meta->default_hook($name, $instructions);

Register a default hook, which will be used if the [alienfile](https://metacpan.org/pod/alienfile) does not
register its own hook with that name.

## around\_hook

    $build->meta->around_hook($hook, $code);
    Alien::Build->meta->around_hook($name, $code);

Wrap the given hook with a code reference.  This is similar to a [Moose](https://metacpan.org/pod/Moose)
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

## apply\_plugin

    Alien::Build->meta->apply_plugin($name);
    Alien::Build->meta->apply_plugin($name, @args);

Apply the given plugin with the given arguments.

# ENVIRONMENT

[Alien::Build](https://metacpan.org/pod/Alien::Build) responds to these environment variables:

- ALIEN\_INSTALL\_NETWORK

    If set to true (the default), then network fetch will be allowed.  If set to
    false, then network fetch will not be allowed.

    What constitutes a local vs. network fetch is determined based on the `start_url`
    and `local_source` meta properties.  An [alienfile](https://metacpan.org/pod/alienfile) or plugin `could` override
    this detection (possibly inappropriately), so this variable is not a substitute
    for properly auditing of Perl modules for environments that require that.

    This variable overrides `NO_NETWORK_TESTING` if both are set.

- ALIEN\_INSTALL\_TYPE

    If set to `share` or `system`, it will override the system detection logic.
    If set to `default`, it will use the default setting for the [alienfile](https://metacpan.org/pod/alienfile).
    The behavior of other values is undefined.

- ALIEN\_BUILD\_RC

    Perl source file which can override some global defaults for [Alien::Build](https://metacpan.org/pod/Alien::Build),
    by, for example, setting preload and postload plugins.

- ALIEN\_BUILD\_PKG\_CONFIG

    Override the logic in [Alien::Build::Plugin::PkgConfig::Negotiate](https://metacpan.org/pod/Alien::Build::Plugin::PkgConfig::Negotiate) which
    chooses the best `pkg-config` plugin.

- ALIEN\_BUILD\_PRELOAD

    semicolon separated list of plugins to automatically load before parsing
    your [alienfile](https://metacpan.org/pod/alienfile).

- ALIEN\_BUILD\_PRELOAD

    semicolon separated list of plugins to automatically load after parsing
    your [alienfile](https://metacpan.org/pod/alienfile).

- DESTDIR

    This environment variable will be manipulated during a destdir install.

- PKG\_CONFIG

    This environment variable can be used to override the program name for `pkg-config`
    for some PkgConfig plugins: [Alien::Build::Plugin::PkgConfig](https://metacpan.org/pod/Alien::Build::Plugin::PkgConfig).

- ftp\_proxy, all\_proxy

    If these environment variables are set, it may influence the Download negotiation
    plugin [Alien::Build::Plugin::Downaload::Negotiate](https://metacpan.org/pod/Alien::Build::Plugin::Downaload::Negotiate).  Other proxy variables may
    be used by some Fetch plugins, if they support it.

- NO\_NETWORK\_TESTING

    If set to true then network fetch will not be allowed.

    What constitutes a local vs. network fetch is determined based on the `start_url`
    and `local_source` meta properties.  An [alienfile](https://metacpan.org/pod/alienfile) or plugin `could` override
    this detection (possibly inappropriately), so this variable is not a substitute
    for properly auditing of Perl modules for environments that require that.

    This variable is overridden by `ALIEN_INSTALL_NETWORK` if both are set.

# SUPPORT

The intent of the `Alien-Build` team is to support as best as possible 
all Perls from 5.8.1 to the latest production version.  So long as they 
are also supported by the Perl toolchain.

Please feel encouraged to report issues that you encounter to the 
project GitHub Issue tracker:

- [https://github.com/Perl5-Alien/Alien-Build/issues](https://github.com/Perl5-Alien/Alien-Build/issues)

Better if you can fix the issue yourself, please feel encouraged to open 
pull-request on the project GitHub:

- [https://github.com/Perl5-Alien/Alien-Build/pulls](https://github.com/Perl5-Alien/Alien-Build/pulls)

If you are confounded and have questions, join us on the `#native` 
channel on irc.perl.org.  The `Alien-Build` developers frequent this 
channel and can probably help point you in the right direction.  If you
don't have an IRC client handy, you can use this web interface:

- [https://chat.mibbit.com/?channel=%23native&server=irc.perl.org](https://chat.mibbit.com/?channel=%23native&server=irc.perl.org)

# SEE ALSO

[Alien::Build::Manual::AlienAuthor](https://metacpan.org/pod/Alien::Build::Manual::AlienAuthor),
[Alien::Build::Manual::AlienUser](https://metacpan.org/pod/Alien::Build::Manual::AlienUser),
[Alien::Build::Manual::Contributing](https://metacpan.org/pod/Alien::Build::Manual::Contributing),
[Alien::Build::Manual::FAQ](https://metacpan.org/pod/Alien::Build::Manual::FAQ),
[Alien::Build::Manual::PluginAuthor](https://metacpan.org/pod/Alien::Build::Manual::PluginAuthor)

[alienfile](https://metacpan.org/pod/alienfile), [Alien::Build::MM](https://metacpan.org/pod/Alien::Build::MM), [Alien::Build::Plugin](https://metacpan.org/pod/Alien::Build::Plugin), [Alien::Base](https://metacpan.org/pod/Alien::Base), [Alien](https://metacpan.org/pod/Alien)

# THANKS

[Alien::Base](https://metacpan.org/pod/Alien::Base) was originally written by Joel Berger, the rest of this project would
not have been possible without him getting the project started.  Thanks to his support
I have been able to augment the original [Alien::Base](https://metacpan.org/pod/Alien::Base) system with a reliable set
of tools ([Alien::Build](https://metacpan.org/pod/Alien::Build), [alienfile](https://metacpan.org/pod/alienfile), [Test::Alien](https://metacpan.org/pod/Test::Alien)), which make up this toolset.

The original [Alien::Base](https://metacpan.org/pod/Alien::Base) is still copyright (c) 2012-2017 Joel Berger.  It has
the same license as the rest of the Alien::Build and related tools distributed as
`Alien-Build`.  Joel Berger thanked a number of people who helped in in the development
of [Alien::Base](https://metacpan.org/pod/Alien::Base), in the documentation for that module.

I would also like to acknowledge the other members of the Perl5-Alien github
organization, Zakariyya Mughal (sivoais, ZMUGHAL) and mohawk (ETJ).  Also important
in the early development of [Alien::Build](https://metacpan.org/pod/Alien::Build) were the early adopters Chase Whitener
(genio, CAPOEIRAB, author of [Alien::libuv](https://metacpan.org/pod/Alien::libuv)), William N. Braswell, Jr (willthechill,
WBRASWELL, author of [Alien::JPCRE2](https://metacpan.org/pod/Alien::JPCRE2) and [Alien::PCRE2](https://metacpan.org/pod/Alien::PCRE2)) and Ahmad Fatoum (a3f,
ATHREEF, author of [Alien::libudev](https://metacpan.org/pod/Alien::libudev) and [Alien::LibUSB](https://metacpan.org/pod/Alien::LibUSB)).

# AUTHOR

Author: Graham Ollis <plicease@cpan.org>

Contributors:

Diab Jerius (DJERIUS)

Roy Storey

Ilya Pavlov

David Mertens (run4flat)

Mark Nunberg (mordy, mnunberg)

Christian Walde (Mithaldu)

Brian Wightman (MidLifeXis)

Zaki Mughal (zmughal)

mohawk (mohawk2, ETJ)

Vikas N Kumar (vikasnkumar)

Flavio Poletti (polettix)

Salvador Fandiño (salva)

Gianni Ceccarelli (dakkar)

Pavel Shaydo (zwon, trinitum)

Kang-min Liu (劉康民, gugod)

Nicholas Shipp (nshp)

Juan Julián Merelo Guervós (JJ)

Joel Berger (JBERGER)

Petr Pisar (ppisar)

Lance Wicks (LANCEW)

Ahmad Fatoum (a3f, ATHREEF)

José Joaquín Atria (JJATRIA)

Duke Leto (LETO)

# COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
