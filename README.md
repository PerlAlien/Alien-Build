# Alien::Build [![Build Status](https://secure.travis-ci.org/plicease/Alien-Build.png)](http://travis-ci.org/plicease/Alien-Build) [![Build status](https://ci.appveyor.com/api/projects/status/22odutjphx45248s/branch/master?svg=true)](https://ci.appveyor.com/project/plicease/Alien-Build/branch/master)

Build external dependencies for use in CPAN

# CONSTRUCTOR

## new

    my $build = Alien::Build->new;

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

## fetch

    my $res = $build->fetch;
    my $res = $build->fetch($url);

Fetch a resource using the fetch hook.  Returns the same hash structure
described below in the hook documentation.

## decode

    my $decoded_res = $build->decode($res);

Decode the HTML or file listing returned by `fetch`.

# HOOKS

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
        my($url) = @_;
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

## decode\_html hook

    package Alien::Build::Plugin::MyPlugin;
    
    use strict;
    use warnings;
    use Alien::Build::Plugin;
    
    sub init
    {
      my($self, $meta) = @_;
      
      $meta->register_hook( decode_html => sub {
        my($res) = @_;
        ...
      }
    }
    
    1;

This hook takes a response hash reference from the `fetch` hook above
with a type of `html` and converts it into a response hash reference
of type `list`.  In short it takes an HTML response from a fetch hook
and converts it into a list of filenames and links that can be used
by the select hook to choose the correct file to download.  See `fetch`
for the specification of the input and response hash references.

## decode\_dir\_listing

    package Alien::Build::Plugin::MyPlugin;
    
    use strict;
    use warnings;
    use Alien::Build::Plugin;
    
    sub init
    {
      my($self, $meta) = @_;
      
      $meta->register_hook( decode_html => sub {
        my($res) = @_;
        ...
      }
    }
    
    1;

This is the same as the `decode_html` hook above, but it decodes hash
reference with type `dir_listing`.

# AUTHOR

Graham Ollis <plicease@cpan.org>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
