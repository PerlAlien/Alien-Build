# Alien::Build [![Build Status](https://secure.travis-ci.org/plicease/Alien-Build.png)](http://travis-ci.org/plicease/Alien-Build)

Build external dependencies for use in CPAN

# CONSTRUCTOR

## new

    my $build = Alien::Build->new;

# METHODS

## load

    my $build = Alien::Build->load($filename);

## requires

    my $hash = Alien::Build->requires;
    my $hash = $build->requires;

## meta

    my $meta = Alien::Build->meta;
    my $meta = $build->meta;

# AUTHOR

Graham Ollis <plicease@cpan.org>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
