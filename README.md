# Alien::Build::Plugin::Build::CMake [![Build Status](https://secure.travis-ci.org/plicease/Alien-Build-Plugin-Build-CMake.png)](http://travis-ci.org/plicease/Alien-Build-Plugin-Build-CMake)

CMake plugin for Alien::Build

# SYNOPSIS

    use alienfile;
    
    share {
      plugin 'Build::CMake';
      build [
        # this is the default build step, if you do not specify one.
        [ '%{cmake}', -G => '%{cmake_generator}', '-DCMAKE_POSITION_INDEPENDENT_CODE:BOOL=true', '-DCMAKE_INSTALL_PREFIX:PATH=%{.install.prefix}', '.' ],
        '%{make}',
        '%{make} install',
      ];
    };

# DESCRIPTION

This plugin helps build alienized projects that use `cmake`.
The intention is to make this a core [Alien::Build](https://metacpan.org/pod/Alien::Build) plugin if/when
it becomes stable enough.

# METHODS

## cmake\_generator

Returns the `cmake` generator according to your Perl's `make`.

## is\_dmake

Returns true if your Perls `make` appears to be `dmake`.

# HELPERS

## cmake

This plugin replaces the default `cmake` helper with the one that comes from [Alien::cmake3](https://metacpan.org/pod/Alien::cmake3).

## cmake\_generator

This is the appropriate `cmake` generator to use based on the make used by your Perl.

## make

This plugin _may_ replace the default `make` helper with the appropriate one for [Alien::gmake](https://metacpan.org/pod/Alien::gmake),
if it is determined that your `make` is not compatible with `cmake`.  In particular this is
the case for `dmake` on windows, which came with older versions of Strawberry Perl.

# SEE ALSO

- [Alien::Build](https://metacpan.org/pod/Alien::Build)
- [Alien::Build::Plugin::Build::Autoconf](https://metacpan.org/pod/Alien::Build::Plugin::Build::Autoconf)
- [alienfile](https://metacpan.org/pod/alienfile)

# AUTHOR

Graham Ollis <plicease@cpan.org>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
