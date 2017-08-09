# Alien::Build::Plugin::Build::CMake [![Build Status](https://secure.travis-ci.org/plicease/Alien-Build-Plugin-Build-CMake.png)](http://travis-ci.org/plicease/Alien-Build-Plugin-Build-CMake)

CMake plugin for Alien::Build

# SYNOPSIS

    use alienfile;
    
    share {
      plugin 'Build::CMake';
    };

# DESCRIPTION

This plugin helps build alienized projects that use `cmake`.
The intention is to make this a core [Alien::Build](https://metacpan.org/pod/Alien::Build) plugin if/when
it becomes stable enough.

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
