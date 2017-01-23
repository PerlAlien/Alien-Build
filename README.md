# Alien::Build [![Build Status](https://secure.travis-ci.org/plicease/Alien-Build.png)](http://travis-ci.org/plicease/Alien-Build) [![Build status](https://ci.appveyor.com/api/projects/status/22odutjphx45248s/branch/master?svg=true)](https://ci.appveyor.com/project/plicease/Alien-Build/branch/master)

Build external dependencies for use in CPAN

# SYNOPSIS

TODO

# DESCRIPTION

This module provides tools for building external (non-CPAN) dependencies 
for CPAN.  It is mainly designed to be used at install time of a CPAN 
client, and work closely with [Alien::Base](https://metacpan.org/pod/Alien::Base) which is used at runtime.

# CONSTRUCTOR

## new

    my $build = Alien::Build->new;

# PROPERTIES

## install\_prop

    my $href = $build->install_prop;

Hash of properties used during the install phase, for either a
`system` or `share` install.  For most things you will want to
use `runtime_prop` below.  Only use `install_prop` for properties
that are needed ONLY during the install phase.

## runtime\_prop

    my $href = $build->runtime_prop;

Hash of properties used during the runtime phase.  This can include
anything needed by your [Alien::Base](https://metacpan.org/pod/Alien::Base) based module, but these are
frequently useful:

- cflags

    The compiler flags

- libs

    The library flags

- version

    The version of the library or tool

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

## root

    my $dir = $build->root;

The build root directory.  This will be an absolute path.  It will be
created if it does not already exist.  It is the absolute form of
`./_alien` by default.

## install\_type

    my $type = $build->install_type;

This is just a shortcut for:

    my $type = $build->runtime_prop->{install_type};

# METHODS

## load

    my $build = Alien::Build->load($filename);

## requires

    my $hash = $build->requires($phase);

## load\_requires

    $build->load_requires;

## meta

    my $meta = Alien::Build->meta;
    my $meta = $build->meta;

## probe

    my $install_type = $build->probe;

Attempts to determine if the operating system has the library or
tool already installed.  If so, then the string `system` will
be returned and a system install will be performed.  If not,
then the string `share` will be installed and the tool or
library will be downloaded and built from source.

## fetch

    my $res = $build->fetch;
    my $res = $build->fetch($url);

Fetch a resource using the fetch hook.  Returns the same hash structure
described below in the hook documentation.

## decode

    my $decoded_res = $build->decode($res);

Decode the HTML or file listing returned by `fetch`.

## sort

    my $sorted_res = $build->sort($res);

Filter and sort candidates.  The best candidate will be returned first in the list.
The worst candidate will be returned last.

# HOOKS

## probe hook

    $meta->register_hook( probe => sub {
      my($build) = @_;
      return 'system' if ...; # system install
      return 'share';         # otherwise
    });
    
    $meta->register_hook( probe => [ $command ] );

This hook should return the string `system` if the operating
system provides the library or tool.  It should return `share`
otherwise.

You can also use a command that returns true when the tool
or library is available.  For example for use with `pkg-config`:

    $meta->register_hook( probe =>
      [ '%{pkgconf} --exists libfoo' ] );

Or if you needed a minimum version:

    $meta->register_hook( probe =>
      [ '%{pkgconf} --atleast-version=1.00 libfoo' ] );

## fetch hook

    package Alien::Build::Plugin::MyPlugin;
    
    use strict;
    use warnings;
    use Alien::Build::Plugin;
    use Carp ();
    
    has '+url' => sub { Carp::croak "url is required property" };

    sub init
    {
      my($self, $meta) = @_;
      
      $meta->register_hook( fetch => sub {
        my($build, $url) = @_;
        ...
      }
    }
    
    1;

Used to fetch a resource.  The first time it will be called without an
argument, so the configuration used to find the resource should be
specified by the plugin's properties.  On subsequent calls the first
argument will be a URL.

Normally the first fetch will be to either a file or a directory listing.
If it is a file then the content should be returned as a hash reference
with the following keys:

    # content of file stored in Perl
    return {
      type     => 'file',
      filename => $filename,
      content  => $content,
    };
    
    # content of file stored in the filesystem
    return {
      type     => 'file',
      filename => $filename,
      path     => $path,    # full file system path to file
    };

If the URL points to a directory listing you should return it as either
a hash reference containing a list of files:

    return {
      type => 'list',
      list => [
        # filename: each filename should be just the
        #   filename portion, no path or url.
        # url: each url should be the complete url
        #   needed to fetch the file.
        { filename => $filename1, url => $url1 },
        { filename => $filename2, url => $url2 },
      ]
    };

or if the listing is in HTML format as a hash reference containing the
HTML information:

    return {
      type => 'html',
      charset => $charset, # optional
      base    => $base,    # the base URL: used for computing relative URLs
      content => $content, # the HTML content
    };

or a directory listing (usually produced by ftp servers) as a hash
reference:

    return {
      type    => 'dir_listing',
      base    => $base,
      content => $content,
    };

## decode

    sub init
    {
      my($self, $meta) = @_;
      
      $meta->register_hook( decode => sub {
        my($build, $res) = @_;
        ...
      }
    }

This hook takes a response hash reference from the `fetch` hook above
with a type of `html` or `dir_listing` and converts it into a response
hash reference of type `list`.  In short it takes an HTML or FTP file
listing response from a fetch hook and converts it into a list of filenames
and links that can be used by the sort hook to choose the correct file to
download.  See `fetch` for the specification of the input and response
hash references.

## sort

    sub init
    {
      my($self, $meta) = @_;
      
      $meta->register_hook( sort => sub {
        my($build, $res) = @_;
        return {
          type => 'list',
          list => [sort @{ $res->{list} }],
        };
      }
    }

This hook sorts candidates from a listing generated from either the `fetch`
or `decode` hooks.  It should return a new list hash reference with the
candidates sorted from best to worst.  It may also remove candidates
that are totally unacceptable.

# META METHODS

## filename

    my $filename = $build->meta->filename;
    my $filename = Alien::Build->meta->filename;

## add\_requires

    $build->meta->add_requires($phase, $module => $version, ...);
    Alien::Build->meta->add_requires($phase, $module => $version, ...);

## interpolator

    my $interpolator = $build->meta->interpolator;
    my $interpolator = Alien::Build->interpolator;

## has\_hook

    my $bool = $build->meta->has_hook($name);
    my $bool = Alien::Build->has_hook($name);

## register\_hook

    $build->meta->register_hook($name, $instructions);
    Alien::Build->meta->register_hook($name, $instructions);

## default\_hook

    $build->meta->default_hook($phase, $name, $instructions);
    Alien::Build->meta->default_hook($phase, $name, $instructions);

# CONTRIBUTING

Thank you for considering to contribute to my open source project!  If 
you have a small patch please consider just submitting it.  Doing so 
through the project GitHub is probably the best way:

[https://github.com/plicease/Alien-Build/issues](https://github.com/plicease/Alien-Build/issues)

If you have a more invasive enhancement or bugfix to contribute, please 
take the time to review these guidelines.  In general it is good idea to 
work closely with the [Alien::Build](https://metacpan.org/pod/Alien::Build) developers, and the best way to 
contact them is on the `#native` IRC channel on irc.perl.org.

## History

Joel Berger wrote the original [Alien::Base](https://metacpan.org/pod/Alien::Base).  This distribution 
included the runtime code [Alien::Base](https://metacpan.org/pod/Alien::Base) and an installer class 
[Alien::Base::ModuleBuild](https://metacpan.org/pod/Alien::Base::ModuleBuild).  The significant thing about [Alien::Base](https://metacpan.org/pod/Alien::Base) 
was that it provided tools to make it relatively easy for people to roll 
their own [Alien](https://metacpan.org/pod/Alien) distributions.  Over time, the Perl5-Alien (github 
organization) or "Alien::Base team" has taken over development of 
[Alien::Base](https://metacpan.org/pod/Alien::Base) with myself (Graham Ollis) being responsible for 
integration and releases.  Joel Berger is still involved in the project.

Since the original development of [Alien::Base](https://metacpan.org/pod/Alien::Base), [Module::Build](https://metacpan.org/pod/Module::Build), on 
which [Alien::Base::ModuleBuild](https://metacpan.org/pod/Alien::Base::ModuleBuild) is based, has been removed from the 
core of Perl.  It seemed worthwhile to write a replacement installer 
that works with [ExtUtils::MakeMaker](https://metacpan.org/pod/ExtUtils::MakeMaker) which IS still bundled with the 
Perl core.  Because this is a significant undertaking it is my intention 
to integrate the many lessons learned by Joel Berger, myself and the 
"Alien::Base team" as possible.  If the interface seems good then it is 
because I've stolen the ideas from some pretty good places.

## Philosophy

### avoid dependencies

One of the challenges with [Alien](https://metacpan.org/pod/Alien) development is that you are by the 
nature of the problem, trying to make everyone happy.  Developers 
working out of CPAN just want stuff to work, and some build environments 
can be hostile in terms of tool availability, so for reliability you end 
up pulling a lot of dependencies.  On the other hand, operating system 
vendors who are building Perl modules usually want to use the system 
version of a library so that they do not have to patch libraries in 
multiple places.  Such vendors have to package any extra dependencies 
and having to do so for packages that the don't even use makes them 
understandably unhappy.

As general policy the [Alien::Build](https://metacpan.org/pod/Alien::Build) core should have as few 
dependencies as possible, and should only pull extra dependencies if 
they are needed.  Where dependencies cannot be avoidable, popular and 
reliable CPAN modules, which are already available as packages in the 
major Linux vendors (Debian, Red Hat) should be preferred.

As such [Alien::Build](https://metacpan.org/pod/Alien::Build) is hyper aggressive at using dynamic 
prerequisites.

### interface agnostic

One of the challenges with [Alien::Buil::ModuleBuild](https://metacpan.org/pod/Alien::Buil::ModuleBuild) was that 
[Module::Build](https://metacpan.org/pod/Module::Build) was pulled from the core.  In addition, there is a 
degree of hostility toward [Module::Build](https://metacpan.org/pod/Module::Build) in some corners of the Perl 
community.  I agree with Joel Berger's rationale for choosing 
[Module::Build](https://metacpan.org/pod/Module::Build) at the time, as I believe its interface more easily 
lends itself to building [Alien](https://metacpan.org/pod/Alien) distributions.

That said, an important feature of [Alien::Build](https://metacpan.org/pod/Alien::Build) is that it is 
installer agnostic.  Although it is initially designed to work with 
[ExtUtils::MakeMaker](https://metacpan.org/pod/ExtUtils::MakeMaker), it has been designed from the ground up to work 
with any installer (Perl, or otherwise).

As an extension of this, although [Alien::Build](https://metacpan.org/pod/Alien::Build) may have external CPAN 
dependencies, they should not be exposed to developers USING 
[Alien::Build](https://metacpan.org/pod/Alien::Build).  As an example, [Path::Tiny](https://metacpan.org/pod/Path::Tiny) is used heavily 
internally because it does what [File::Spec](https://metacpan.org/pod/File::Spec) does, plus the things that 
it doesn't, and uses forward slashes on Windows (backslashes are the 
"correct separator on windows, but actually using them tends to break 
everything).  However, there aren't any interfaces in [Alien::Build](https://metacpan.org/pod/Alien::Build) 
that will return a [Path::Tiny](https://metacpan.org/pod/Path::Tiny) object (or if there are, then this is a 
bug).

This means that if we ever need to port [Alien::Build](https://metacpan.org/pod/Alien::Build) to a platform 
that doesn't support [Path::Tiny](https://metacpan.org/pod/Path::Tiny) (such as VMS), then it may require 
some work to [Alien::Build](https://metacpan.org/pod/Alien::Build) itself, modules that USE [Alien::Build](https://metacpan.org/pod/Alien::Build) 
shouldn't need to be modified.

### plugable

The actual logic that probes the system, downloads source and builds it 
should be as pluggable as possible.  One of the challenges with 
[Alien::Build::ModuleBuild](https://metacpan.org/pod/Alien::Build::ModuleBuild) was that it was designed to work well with 
software that works with `autoconf` and `pkg-config`.  While you can 
build with other tools, you have to know a bit of how the installer 
logic works, and which hooks need to be tweaked.

[Alien::Build](https://metacpan.org/pod/Alien::Build) has plugins for `autoconf`, `pkgconf` (successor of 
`pkg-config`), vanilla Makefiles, and CMake.  If your build system 
doesn't have a plugin, then all you have to do is write one!  Plugins 
that prove their worth may be merged into the [Alien::Build](https://metacpan.org/pod/Alien::Build) core.  
Plugins that after a while feel like maybe not such a good idea may be 
removed from the core, or even from CPAN itself.

In addition, [Alien::Build](https://metacpan.org/pod/Alien::Build) has a special type of plugin, called a 
negotiator which picks the best plugin for the particular environment 
that it is running in.  This way, as development of the negotiator and 
plugins develop over time modules that use [Alien::Build](https://metacpan.org/pod/Alien::Build) will benefit, 
without having to change the way they interface with [Alien::Build](https://metacpan.org/pod/Alien::Build)

# ACKNOWLEDGEMENT

I would like to that Joel Berger for getting things running in the first 
place.  Also important to thank other members of the "Alien::Base team":

Zaki Mughal (SIVOAIS)

Ed J (ETJ, mohawk)

Also kind thanks to all of the developers who have contributed to 
[Alien::Base](https://metacpan.org/pod/Alien::Base) over the years:

[https://metacpan.org/pod/Alien::Base#CONTRIBUTORS](https://metacpan.org/pod/Alien::Base#CONTRIBUTORS)

# AUTHOR

Graham Ollis <plicease@cpan.org>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
