# Alien::Build [![Build Status](https://api.cirrus-ci.com/github/PerlAlien/Alien-Build.svg)](https://cirrus-ci.com/github/PerlAlien/Alien-Build) ![static](https://github.com/PerlAlien/Alien-Build/workflows/static/badge.svg) ![linux](https://github.com/PerlAlien/Alien-Build/workflows/linux/badge.svg) ![macos](https://github.com/PerlAlien/Alien-Build/workflows/macos/badge.svg) ![windows](https://github.com/PerlAlien/Alien-Build/workflows/windows/badge.svg) ![cygwin](https://github.com/PerlAlien/Alien-Build/workflows/cygwin/badge.svg) ![msys2-mingw](https://github.com/PerlAlien/Alien-Build/workflows/msys2-mingw/badge.svg)

Build external dependencies for use in CPAN

# SYNOPSIS

```perl
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
```

# DESCRIPTION

This module provides tools for building external (non-CPAN) dependencies
for CPAN.  It is mainly designed to be used at install time of a CPAN
client, and work closely with [Alien::Base](https://metacpan.org/pod/Alien::Base) which is used at runtime.

This is the detailed documentation for the [Alien::Build](https://metacpan.org/pod/Alien::Build) class.
If you are starting out you probably want to do so from one of these documents:

- [Alien::Build::Manual::Alien](https://metacpan.org/pod/Alien::Build::Manual::Alien)

    A broad overview of `Alien-Build` and its ecosystem.

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

- [Alien::Build::Manual::Security](https://metacpan.org/pod/Alien::Build::Manual::Security)

    If you are concerned that [Alien](https://metacpan.org/pod/Alien)s might be downloading tarballs off
    the internet, then this is the place for you.  This will discuss some
    of the risks of downloading (really any) software off the internet
    and will give you some tools to remediate these risks.

Note that you will not usually create a [Alien::Build](https://metacpan.org/pod/Alien::Build) instance
directly, but rather be using a thin installer layer, such as
[Alien::Build::MM](https://metacpan.org/pod/Alien::Build::MM) (for use with [ExtUtils::MakeMaker](https://metacpan.org/pod/ExtUtils::MakeMaker)) or
[Alien::Build::MB](https://metacpan.org/pod/Alien::Build::MB) (for use with [Module::Build](https://metacpan.org/pod/Module::Build)).  One of the
goals of this project is to remain installer agnostic.

# CONSTRUCTORS

## new

```perl
my $build = Alien::Build->new;
```

This creates a new empty instance of [Alien::Build](https://metacpan.org/pod/Alien::Build).  Normally you will
want to use `load` below to create an instance of [Alien::Build](https://metacpan.org/pod/Alien::Build) from
an [alienfile](https://metacpan.org/pod/alienfile) recipe.

## load

```perl
my $build = Alien::Build->load($alienfile);
```

This creates an [Alien::Build](https://metacpan.org/pod/Alien::Build) instance with the given [alienfile](https://metacpan.org/pod/alienfile)
recipe.

## resume

```perl
my $build = Alien::Build->resume($alienfile, $root);
```

Load a checkpointed [Alien::Build](https://metacpan.org/pod/Alien::Build) instance.  You will need the original
[alienfile](https://metacpan.org/pod/alienfile) and the build root (usually `_alien`), and a build that
had been properly checkpointed using the `checkpoint` method below.

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

```perl
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
```

If you are writing a [alienfile](https://metacpan.org/pod/alienfile) recipe please use the prefix `my_`:

```perl
use alienfile;

meta_prop->{my_foo} = 'some value';

probe sub {
  my($build) = @_;
  $build->install_prop->{my_bar} = 'some other value';
  $build->install_prop->{my_baz} = 'and another value';
};
```

Any property may be used from a command:

```perl
probe [ 'some command %{.meta.plugin_fetch_newprotocol_foo}' ];
probe [ 'some command %{.install.plugin_fetch_newprotocol_bar}' ];
probe [ 'some command %{.runtime.plugin_fetch_newprotocol_baz}' ];
probe [ 'some command %{.meta.my_foo}' ];
probe [ 'some command %{.install.my_bar}' ];
probe [ 'some command %{.runtime.my_baz}' ];
```

## meta\_prop

```perl
my $href = $build->meta_prop;
my $href = Alien::Build->meta_prop;
```

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

- check\_digest

    True if cryptographic digest should be checked when files are fetched
    or downloaded.  This is set by
    [Digest negotiator plugin](https://metacpan.org/pod/Alien::Build::Plugin::Digest::Negotiate).

- destdir

    Some plugins ([Alien::Build::Plugin::Build::Autoconf](https://metacpan.org/pod/Alien::Build::Plugin::Build::Autoconf) for example) support
    installing via `DESTDIR`.  They will set this property to true if they
    plan on doing such an install.  This helps [Alien::Build](https://metacpan.org/pod/Alien::Build) find the staged
    install files and how to locate them.

    If available, `DESTDIR` is used to stage install files in a sub directory before
    copying the files into `blib`.  This is generally preferred method
    if available.

- destdir\_filter

    Regular expression for the files that should be copied from the `DESTDIR`
    into the stage directory.  If not defined, then all files will be copied.

- destdir\_ffi\_filter

    Same as `destdir_filter` except applies to `build_ffi` instead of `build`.

- digest

    This properties contains the cryptographic digests (if any) that should
    be used when verifying any fetched and downloaded files.  It is a hash
    reference where the key is the filename and the value is an array
    reference containing a pair of values, the first being the algorithm
    ('SHA256' is recommended) and the second is the actual digest.  The
    special filename `*` may be specified to indicate that any downloaded
    file should match that digest.  If there are both real filenames and
    the `*` placeholder, the real filenames will be used for filenames
    that match and any other files will use the placeholder.  Example:

    ```perl
    $build->meta_prop->{digest} = {
      'foo-1.00.tar.gz' => [ SHA256 => '9feac593aa49a44eb837de52513a57736457f1ea70078346c60f0bfc5f24f2c1' ],
      'foo-1.01.tar.gz' => [ SHA256 => '6bbde6a7f10ae5924cf74afc26ff5b7bc4b4f9dfd85c6b534c51bd254697b9e7' ],
      '*'               => [ SHA256 => '33a20aae3df6ecfbe812b48082926d55391be4a57d858d35753ab1334b9fddb3' ],
    };
    ```

    Cryptographic signatures will only be checked
    if the [check\_digest meta property](#check_digest) is set and if the
    [Digest negotiator plugin](https://metacpan.org/pod/Alien::Build::Plugin::Digest::Negotiate) is loaded.
    (The Digest negotiator can be used directly, but is also loaded automatically
    if you use the [digest directive](https://metacpan.org/pod/alienfile#digest) is used by the [alienfile](https://metacpan.org/pod/alienfile)).

- env

    Environment variables to override during the build stage.

- env\_interpolate

    Environment variable values will be interpolated with helpers.  Example:

    ```
    meta->prop->{env_interpolate} = 1;
    meta->prop->{env}->{PERL} = '%{perl}';
    ```

- local\_source

    Set to true if source code package is available locally.  (that is not fetched
    over the internet).  This is computed by default based on the `start_url`
    property.  Can be set by an [alienfile](https://metacpan.org/pod/alienfile) or plugin.

- platform

    Hash reference.  Contains information about the platform beyond just `$^O`.

    - platform.compiler\_type

        Refers to the type of flags that the compiler accepts.  May be expanded in the
        future, but for now, will be one of:

        - microsoft

            On Windows when using Microsoft Visual C++

        - unix

            Virtually everything else, including gcc on windows.

        The main difference is that with Visual C++ `-LIBPATH` should be used instead
        of `-L`, and static libraries should have the `.LIB` suffix instead of `.a`.

    - platform.system\_type

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
    or plugin.  This is computed based on the `ALIEN_INSTALL_NETWORK` environment
    variables.

- start\_url

    The default or start URL used by fetch plugins.

## install\_prop

```perl
my $href = $build->install_prop;
```

Install properties are used during the install phase (either
under `share` or `system` install).  They are remembered for
the entire install phase, but not kept around during the runtime
phase.  Thus they cannot be accessed from your [Alien::Base](https://metacpan.org/pod/Alien::Base)
based module.

- autoconf\_prefix

    The prefix as understood by autoconf.  This is only different on Windows
    Where MSYS is used and paths like `C:/foo` are  represented as `/C/foo`
    which are understood by the MSYS tools, but not by Perl.  You should
    only use this if you are using [Alien::Build::Plugin::Build::Autoconf](https://metacpan.org/pod/Alien::Build::Plugin::Build::Autoconf) in
    your [alienfile](https://metacpan.org/pod/alienfile).  This is set during before the
    [build hook](https://metacpan.org/pod/Alien::Build::Manual::PluginAuthor#build-hook) is run.

- download

    The location of the downloaded archive (tar.gz, or similar) or directory.
    This will be undefined until the archive is actually downloaded.

- download\_detail

    This property contains optional details about a downloaded file.  This
    property is populated by [Alien::Build](https://metacpan.org/pod/Alien::Build) core.  This property is a
    hash reference.  The key is the path to the file that has been downloaded
    and the value is a hash reference with additional detail.  All fields
    are optional.

    - download\_detail.digest

        This, if available, with the cryptographic signature that was successfully
        matched against the downloaded file.  It is an array reference with a
        pair of values, the algorithm (typically something like `SHA256`) and
        the digest.

    - download\_detail.protocol

        This, if available, will be the URL protocol used to fetch the downloaded
        file.

- env

    Environment variables to override during the build stage.  Plugins are
    free to set additional overrides using this hash.

- extract

    The location of the last source extraction.  For a "out-of-source" build
    (see the `out_of_source` meta property above), this will only be set once.
    For other types of builds, the source code may be extracted multiple times,
    and thus this property may change.

- old

    \[deprecated\]

    Hash containing information on a previously installed Alien of the same
    name, if available.  This may be useful in cases where you want to
    reuse the previous install if it is still sufficient.

    - old.prefix

        \[deprecated\]

        The prefix for the previous install.  Versions prior to 1.42 unfortunately
        had this in typo form of `preifx`.

    - old.runtime

        \[deprecated\]

        The runtime properties from the previous install.

- patch

    Directory with patches, if available.  This will be `undef` if there
    are no patches.  When initially installing an alien this will usually
    be a sibling of the `alienfile`, a directory called `patch`.  Once
    installed this will be in the share directory called `_alien/patch`.
    The former is useful for rebuilding an alienized package using
    [af](https://metacpan.org/pod/af).

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

- system\_probe\_class

    After the probe step this property may contain the plugin class that
    performed the system probe.  It shouldn't be filled in directly by
    the plugin (instead if should use the hook property `probe_class`,
    see below).  This is optional, and not all probe plugins will provide
    this information.

- system\_probe\_instance\_id

    After the probe step this property may contain the plugin instance id that
    performed the system probe.  It shouldn't be filled in directly by
    the plugin (instead if should use the hook property `probe_instance_id`,
    see below).  This is optional, and not all probe plugins will provide
    this information.

## plugin\_instance\_prop

```perl
my $href = $build->plugin_instance_prop($plugin);
```

This returns the private plugin instance properties for a given plugin.
This method should usually only be called internally by plugins themselves
to keep track of internal state.  Because the content can be used arbitrarily
by the owning plugin because it is private to the plugin, and thus is not
part of the [Alien::Build](https://metacpan.org/pod/Alien::Build) spec.

## runtime\_prop

```perl
my $href = $build->runtime_prop;
```

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
    linker flags for each library.  Typically this will be set by a
    plugin in the gather stage (for either share or system installs).

- cflags

    The compiler flags.  This is typically set by a plugin in the
    gather stage (for either share or system installs).

- cflags\_static

    The static compiler flags.  This is typically set by a plugin in the
    gather stage (for either share or system installs).

- command

    The command name for tools where the name my differ from platform to
    platform.  For example, the GNU version of make is usually `make` in
    Linux and `gmake` on FreeBSD.  This is typically set by a plugin in the
    gather stage (for either share or system installs).

- ffi\_name

    The name DLL or shared object "name" to use when searching for dynamic
    libraries at runtime.  This is passed into [FFI::CheckLib](https://metacpan.org/pod/FFI::CheckLib), so if
    your library is something like `libarchive.so` or `archive.dll` you
    would set this to `archive`.  This may be a string or an array of
    strings.  This is typically set by a plugin in the gather stage
    (for either share or system installs).

- ffi\_checklib

    This property contains two sub properties:

    - ffi\_checklib.share

        ```
        $build->runtime_prop->{ffi_checklib}->{share} = [ ... ];
        ```

        Array of additional [FFI::CheckLib](https://metacpan.org/pod/FFI::CheckLib) flags to pass in to `find_lib`
        for a `share` install.

    - ffi\_checklib.system

        Array of additional [FFI::CheckLib](https://metacpan.org/pod/FFI::CheckLib) flags to pass in to `find_lib`
        for a `system` install.

        Among other things, useful for specifying the `try_linker_script`
        flag:

        ```perl
        $build->runtime_prop->{ffi_checklib}->{system} = [ try_linker_script => 1 ];
        ```

    This is typically set by a plugin in the gather stage
    (for either share or system installs).

- inline\_auto\_include

    \[version 2.53\]

    This property is an array reference of C code that will be passed into
    [Inline::C](https://metacpan.org/pod/Inline::C) to make sure that appropriate headers are automatically
    included.  See ["auto\_include" in Inline::C](https://metacpan.org/pod/Inline::C#auto_include) for details.

- install\_type

    The install type.  This is set by AB core after the
    [probe hook](https://metacpan.org/pod/Alien::Build::Manual::PluginAuthor#probe-hook) is
    executed.  Is one of:

    - system

        For when the library or tool is provided by the operating system, can be
        detected by [Alien::Build](https://metacpan.org/pod/Alien::Build), and is considered satisfactory by the
        `alienfile` recipe.

    - share

        For when a system install is not possible, the library source will be
        downloaded from the internet or retrieved in another appropriate fashion
        and built.

- libs

    The library flags.  This is typically set by a plugin in the
    gather stage (for either share or system installs).

- libs\_static

    The static library flags.  This is typically set by a plugin in the
    gather stage (for either share or system installs).

- perl\_module\_version

    The version of the Perl module used to install the alien (if available).
    For example if [Alien::curl](https://metacpan.org/pod/Alien::curl) is installing `libcurl` this would be the
    version of [Alien::curl](https://metacpan.org/pod/Alien::curl) used during the install step.

- prefix

    The final install root.  This is usually they share directory.

- version

    The version of the library or tool.  This is typically set by a plugin in the
    gather stage (for either share or system installs).

## hook\_prop

```perl
my $href = $build->hook_prop;
```

Hook properties are for the currently running (if any) hook.  They are
used only during the execution of each hook and are discarded after.
If no hook is currently running then `hook_prop` will return `undef`.

- name

    The name of the currently running hook.

- version (probe)

    Probe and PkgConfig plugins _may_ set this property indicating the
    version of the alienized package.  Not all plugins and configurations
    may be able to provide this.

- probe\_class (probe)

    Probe and PkgConfig plugins _may_ set this property indicating the
    plugin class that made the probe.  If the probe results in a system
    install this will be propagated to `system_probe_class` for later
    use.

- probe\_instance\_id (probe)

    Probe and PkgConfig plugins _may_ set this property indicating the
    plugin instance id that made the probe.  If the probe results in a
    system install this will be propagated to `system_probe_instance_id`
    for later use.

# METHODS

## checkpoint

```
$build->checkpoint;
```

Save any install or runtime properties so that they can be reloaded on
a subsequent run in a separate process.  This is useful if your build
needs to be done in multiple stages from a `Makefile`, such as with
[ExtUtils::MakeMaker](https://metacpan.org/pod/ExtUtils::MakeMaker).  Once checkpointed you can use the `resume`
constructor (documented above) to resume the probe/build/install\]
process.

## root

```perl
my $dir = $build->root;
```

This is just a shortcut for:

```perl
my $root = $build->install_prop->{root};
```

Except that it will be created if it does not already exist.

## install\_type

```perl
my $type = $build->install_type;
```

This will return the install type.  (See the like named install property
above for details).  This method will call `probe` if it has not already
been called.

## download\_rule

```perl
my $rule = $build->download_rule;
```

This returns install rule as a string.  This is determined by the environment
and should be one of:

- `warn`

    Warn only if fetching via non secure source (secure sources include `https`,
    and bundled files, may include other encrypted protocols in the future).

- `digest`

    Require that any downloaded source package have a cryptographic signature in
    the [alienfile](https://metacpan.org/pod/alienfile) and that signature matches what was downloaded.

- `encrypt`

    Require that any downloaded source package is fetched via secure source.

- `digest_or_encrypt`

    Require that any downloaded source package is **either** fetched via a secure source
    **or** has a cryptographic signature in the [alienfile](https://metacpan.org/pod/alienfile) and that signature matches
    what was downloaded.

- `digest_and_encrypt`

    Require that any downloaded source package is **both** fetched via a secure source
    **and** has a cryptographic signature in the [alienfile](https://metacpan.org/pod/alienfile) and that signature matches
    what was downloaded.

The current default is `warn`, but in the near future this will be upgraded to
`digest_or_encrypt`.

## set\_prefix

```
$build->set_prefix($prefix);
```

Set the final (unstaged) prefix.  This is normally only called by [Alien::Build::MM](https://metacpan.org/pod/Alien::Build::MM)
and similar modules.  It is not intended for use from plugins or from an [alienfile](https://metacpan.org/pod/alienfile).

## set\_stage

```
$build->set_stage($dir);
```

Sets the stage directory.  This is normally only called by [Alien::Build::MM](https://metacpan.org/pod/Alien::Build::MM)
and similar modules.  It is not intended for use from plugins or from an [alienfile](https://metacpan.org/pod/alienfile).

## requires

```perl
my $hash = $build->requires($phase);
```

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

```
$build->load_requires($phase);
```

This loads the appropriate modules for the given phase (see `requires` above
for a description of the phases).

## probe

```perl
my $install_type = $build->probe;
```

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

```
$build->download;
```

Download the source, usually as a tarball, usually from the internet.

Under a `system` install this does not do anything.

## fetch

```perl
my $res = $build->fetch;
my $res = $build->fetch($url, %options);
```

Fetch a resource using the fetch hook.  Returns the same hash structure
described below in the
[fetch hook](https://metacpan.org/pod/Alien::Build::Manual::PluginAuthor#fetch-hook) documentation.

\[version 2.39\]

As of [Alien::Build](https://metacpan.org/pod/Alien::Build) 2.39, these options are supported:

- http\_headers

    ```perl
    my $res = $build->fetch($url, http_headers => [ $key1 => $value1, $key2 => $value 2, ... ]);
    ```

    Set the HTTP request headers on all outgoing HTTP requests.  Note that not all
    protocols or fetch plugins support setting request headers, but the ones that
    do not _should_ issue a warning if you try to set request headers and they
    are not supported.

## check\_digest

\[experimental\]

```perl
my $bool = $build->check_digest($path);
```

Checks any cryptographic signatures for the given file.  The
file is specified by `$path` which may be one of:

- string

    Containing the path to the file to be checked.

- [Path::Tiny](https://metacpan.org/pod/Path::Tiny)

    Containing the path to the file to be checked.

- `HASH`

    A Hash reference containing information about a file.  See
    the [fetch hook](https://metacpan.org/pod/Alien::Build::Manual::PluginAuthor#fetch-hook) for details
    on the format.

Returns true if the cryptographic signature matches, false if cryptographic
signatures are disabled.  Will throw an exception if the signature does not
match, or if no plugin provides the correct algorithm for checking the
signature.

## decode

```perl
my $decoded_res = $build->decode($res);
```

Decode the HTML or file listing returned by `fetch`.  Returns the same
hash structure described below in the
[decode hook](https://metacpan.org/pod/Alien::Build::Manual::PluginAuthor#decode-hook) documentation.

## prefer

```perl
my $sorted_res = $build->prefer($res);
```

Filter and sort candidates.  The preferred candidate will be returned first in the list.
The worst candidate will be returned last.  Returns the same hash structure described
below in the
[prefer hook](https://metacpan.org/pod/Alien::Build::Manual::PluginAuthor#prefer-hook) documentation.

## extract

```perl
my $dir = $build->extract;
my $dir = $build->extract($archive);
```

Extracts the given archive into a fresh directory.  This is normally called internally
to [Alien::Build](https://metacpan.org/pod/Alien::Build), and for normal usage is not needed from a plugin or [alienfile](https://metacpan.org/pod/alienfile).

## build

```
$build->build;
```

Run the build step.  It is expected that `probe` and `download`
have already been performed.  What it actually does depends on the
type of install:

- share

    The source is extracted, and built as determined by the [alienfile](https://metacpan.org/pod/alienfile)
    recipe.  If there is a `gather_share` that will be executed last.

- system

    The
    [gather\_system hook](https://metacpan.org/pod/Alien::Build::Manual::PluginAuthor#gather_system-hook)
    will be executed.

## test

```
$build->test;
```

Run the test phase

## clean\_install

```
$build->clean_install
```

Clean files from the final install location.  The default implementation removes all
files recursively except for the `_alien` directory.  This is helpful when you have
an old install with files that may break the new build.

For a non-share install this doesn't do anything.

## system

```
$build->system($command);
$build->system($command, @args);
```

Interpolates the command and arguments and run the results using
the Perl `system` command.

## log

```
$build->log($message);
```

Send a message to the log.  By default this prints to `STDOUT`.

## meta

```perl
my $meta = Alien::Build->meta;
my $meta = $build->meta;
```

Returns the meta object for your [Alien::Build](https://metacpan.org/pod/Alien::Build) class or instance.  The
meta object is a way to manipulate the recipe, and so any changes to the
meta object should be made before the `probe`, `download` or `build` steps.

# META METHODS

## prop

```perl
my $href = $build->meta->prop;
```

Meta properties.  This is the same as calling `meta_prop` on
the class or [Alien::Build](https://metacpan.org/pod/Alien::Build) instance.

## add\_requires

```perl
Alien::Build->meta->add_requires($phase, $module => $version, ...);
```

Add the requirement to the given phase.  Phase should be one of:

- configure
- any
- share
- system

## interpolator

```perl
my $interpolator = $build->meta->interpolator;
my $interpolator = Alien::Build->interpolator;
```

Returns the [Alien::Build::Interpolate](https://metacpan.org/pod/Alien::Build::Interpolate) instance for the [Alien::Build](https://metacpan.org/pod/Alien::Build) class.

## has\_hook

```perl
my $bool = $build->meta->has_hook($name);
my $bool = Alien::Build->has_hook($name);
```

Returns if there is a usable hook registered with the given name.

## register\_hook

```
$build->meta->register_hook($name, $instructions);
Alien::Build->meta->register_hook($name, $instructions);
```

Register a hook with the given name.  `$instruction` should be either
a code reference, or a command sequence, which is an array reference.

## default\_hook

```
$build->meta->default_hook($name, $instructions);
Alien::Build->meta->default_hook($name, $instructions);
```

Register a default hook, which will be used if the [alienfile](https://metacpan.org/pod/alienfile) does not
register its own hook with that name.

## around\_hook

```
$build->meta->around_hook($hook_name, $code);
Alien::Build->meta->around_hook($hook_name, $code);
```

Wrap the given hook with a code reference.  This is similar to a [Moose](https://metacpan.org/pod/Moose)
method modifier, except that it wraps around the given hook instead of
a method.  For example, this will add a probe system requirement:

```perl
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
```

## after\_hook

```perl
$build->meta->after_hook($hook_name, sub {
  my(@args) = @_;
  ...
});
```

Execute the given code reference after the hook.  The original
arguments are passed into the code reference.

## before\_hook

```perl
$build->meta->before_hook($hook_name, sub {
  my(@args) = @_;
  ...
});
```

Execute the given code reference before the hook.  The original
arguments are passed into the code reference.

## apply\_plugin

```
Alien::Build->meta->apply_plugin($name);
Alien::Build->meta->apply_plugin($name, @args);
```

Apply the given plugin with the given arguments.

# ENVIRONMENT

[Alien::Build](https://metacpan.org/pod/Alien::Build) responds to these environment variables:

- ALIEN\_BUILD\_LOG

    The default log class used.  See [Alien::Build::Log](https://metacpan.org/pod/Alien::Build::Log) and [Alien::Build::Log::Default](https://metacpan.org/pod/Alien::Build::Log::Default).

- ALIEN\_BUILD\_PKG\_CONFIG

    Override the logic in [Alien::Build::Plugin::PkgConfig::Negotiate](https://metacpan.org/pod/Alien::Build::Plugin::PkgConfig::Negotiate) which
    chooses the best `pkg-config` plugin.

- ALIEN\_BUILD\_POSTLOAD

    semicolon separated list of plugins to automatically load after parsing
    your [alienfile](https://metacpan.org/pod/alienfile).

- ALIEN\_BUILD\_PRELOAD

    semicolon separated list of plugins to automatically load before parsing
    your [alienfile](https://metacpan.org/pod/alienfile).

- ALIEN\_BUILD\_RC

    Perl source file which can override some global defaults for [Alien::Build](https://metacpan.org/pod/Alien::Build),
    by, for example, setting preload and postload plugins.

- ALIEN\_DOWNLOAD\_RULE

    This value determines the rules by which types of downloads are allowed.  The legal
    values listed under ["download\_rule"](#download_rule), plus `default` which will be the default for
    the current version of [Alien::Build](https://metacpan.org/pod/Alien::Build).  For this version that default is `warn`.

- ALIEN\_INSTALL\_NETWORK

    If set to true (the default), then network fetch will be allowed.  If set to
    false, then network fetch will not be allowed.

    What constitutes a local vs. network fetch is determined based on the `start_url`
    and `local_source` meta properties.  An [alienfile](https://metacpan.org/pod/alienfile) or plugin `could` override
    this detection (possibly inappropriately), so this variable is not a substitute
    for properly auditing of Perl modules for environments that require that.

- ALIEN\_INSTALL\_TYPE

    If set to `share` or `system`, it will override the system detection logic.
    If set to `default`, it will use the default setting for the [alienfile](https://metacpan.org/pod/alienfile).
    The behavior of other values is undefined.

    Although the recommended way for a consumer to use an [Alien::Base](https://metacpan.org/pod/Alien::Base) based [Alien](https://metacpan.org/pod/Alien)
    is to declare it as a static configure and build-time dependency, some consumers
    may prefer to fallback on using an [Alien](https://metacpan.org/pod/Alien) only when the consumer itself cannot
    detect the necessary package. In some cases the consumer may want the user to opt-in
    to using an [Alien](https://metacpan.org/pod/Alien) before requiring it.

    To keep the interface consistent among Aliens, the consumer of the fallback opt-in
    [Alien](https://metacpan.org/pod/Alien) may fallback on the [Alien](https://metacpan.org/pod/Alien) if the environment variable `ALIEN_INSTALL_TYPE`
    is set to any value. The rationale is that by setting this environment variable the
    user is aware that [Alien](https://metacpan.org/pod/Alien) modules may be installed and have indicated consent.
    The actual implementation of this, by its nature would have to be in the consuming
    CPAN module.

- DESTDIR

    This environment variable will be manipulated during a destdir install.

- PKG\_CONFIG

    This environment variable can be used to override the program name for `pkg-config`
    when using the command line plugin: [Alien::Build::Plugin::PkgConfig::CommandLine](https://metacpan.org/pod/Alien::Build::Plugin::PkgConfig::CommandLine).

- ftp\_proxy, all\_proxy

    If these environment variables are set, it may influence the Download negotiation
    plugin [Alien::Build::Plugin::Download::Negotiate](https://metacpan.org/pod/Alien::Build::Plugin::Download::Negotiate).  Other proxy variables may
    be used by some Fetch plugins, if they support it.

# SUPPORT

The intent of the `Alien-Build` team is to support as best as possible
all Perls from 5.8.4 to the latest production version.  So long as they
are also supported by the Perl toolchain.

Please feel encouraged to report issues that you encounter to the
project GitHub Issue tracker:

- [https://github.com/PerlAlien/Alien-Build/issues](https://github.com/PerlAlien/Alien-Build/issues)

Better if you can fix the issue yourself, please feel encouraged to open
pull-request on the project GitHub:

- [https://github.com/PerlAlien/Alien-Build/pulls](https://github.com/PerlAlien/Alien-Build/pulls)

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

The original [Alien::Base](https://metacpan.org/pod/Alien::Base) is still copyright (c) 2012-2020 Joel Berger.  It has
the same license as the rest of the Alien::Build and related tools distributed as
`Alien-Build`.  Joel Berger thanked a number of people who helped in in the development
of [Alien::Base](https://metacpan.org/pod/Alien::Base), in the documentation for that module.

I would also like to acknowledge the other members of the PerlAlien github
organization, Zakariyya Mughal (sivoais, ZMUGHAL) and mohawk (ETJ).  Also important
in the early development of [Alien::Build](https://metacpan.org/pod/Alien::Build) were the early adopters Chase Whitener
(genio, CAPOEIRAB, author of [Alien::libuv](https://metacpan.org/pod/Alien::libuv)), William N. Braswell, Jr (willthechill,
WBRASWELL, author of [Alien::JPCRE2](https://metacpan.org/pod/Alien::JPCRE2) and [Alien::PCRE2](https://metacpan.org/pod/Alien::PCRE2)) and Ahmad Fatoum (a3f,
ATHREEF, author of [Alien::libudev](https://metacpan.org/pod/Alien::libudev) and [Alien::LibUSB](https://metacpan.org/pod/Alien::LibUSB)).

The Alien ecosystem owes a debt to Dan Book, who goes by Grinnz on IRC, for answering
question about how to use [Alien::Build](https://metacpan.org/pod/Alien::Build) and friends.

# AUTHOR

Author: Graham Ollis <plicease@cpan.org>

Contributors:

Diab Jerius (DJERIUS)

Roy Storey (KIWIROY)

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

Petr Písař (ppisar)

Lance Wicks (LANCEW)

Ahmad Fatoum (a3f, ATHREEF)

José Joaquín Atria (JJATRIA)

Duke Leto (LETO)

Shoichi Kaji (SKAJI)

Shawn Laffan (SLAFFAN)

Paul Evans (leonerd, PEVANS)

Håkon Hægland (hakonhagland, HAKONH)

nick nauwelaerts (INPHOBIA)

# COPYRIGHT AND LICENSE

This software is copyright (c) 2011-2022 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
