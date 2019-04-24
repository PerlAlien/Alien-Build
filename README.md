# Alien::Build::Plugin::Decode::Mojo [![Build Status](https://secure.travis-ci.org/Perl5-Alien/Alien-Build-Plugin-Decode-Mojo.png)](http://travis-ci.org/Perl5-Alien/Alien-Build-Plugin-Decode-Mojo)

Plugin to extract links from HTML using Mojo::DOM or Mojo::DOM58

# SYNOPSIS

    use alienfile;
    plugin 'Decode::Mojo';

Force using `Decode::Mojo` via the download negotiator:

    use alienfile;
    
    configure {
      requires 'Alien::Build::Plugin::Decod::Mojo';
    };
    
    plugin 'Download' => (
      ...
      decoder => 'Decode::Mojo',
    );

# DESCRIPTION

Note: in most cases you will want to use [Alien::Build::Plugin::Download::Negotiate](https://metacpan.org/pod/Alien::Build::Plugin::Download::Negotiate)
instead.  It picks the appropriate decode plugin based on your platform and environment.
In some cases you may need to use this plugin directly instead.

This plugin decodes an HTML file listing into a list of candidates for your Prefer plugin.
It works just like [Alien::Build::Plugin::Decode::HTML](https://metacpan.org/pod/Alien::Build::Plugin::Decode::HTML) except it uses either [Mojo::DOM](https://metacpan.org/pod/Mojo::DOM)
or [Mojo::DOM58](https://metacpan.org/pod/Mojo::DOM58) to do its job.

This plugin is much lighter than The `Decode::HTML` plugin, and doesn't require XS.  The
intent is if this plugin proves its self reliable that it will be merged into `Alien-Build`,
and the download negotiator may eventually prefer it.

# AUTHOR

Graham Ollis <plicease@cpan.org>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
