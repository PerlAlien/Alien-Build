package Alien::Build::Plugin::Decode::Mojo;

use strict;
use warnings;
use 5.008001;
use Alien::Build::Plugin;

# ABSTRACT: Plugin to extract links from HTML using Mojo::DOM or Mojo::DOM58
# VERSION

=head1 SYNOPSIS

 use alienfile;
 use 'Decode::Mojo';

=head1 DESCRIPTION

Note: in most cases you will want to use L<Alien::Build::Plugin::Download::Negotiate>
instead.  It picks the appropriate decode plugin based on your platform and environment.
In some cases you may need to use this plugin directly instead.

This plugin decodes an HTML file listing into a list of candidates for your Prefer plugin.
It works just like L<Alien::Build::Plugin::Decode::HTML> except it uses either L<Mojo::DOM>
or L<Mojo::DOM58> to do its job.

=cut

sub init
{
  my($self, $meta) = @_;
}

1;
