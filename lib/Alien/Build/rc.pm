package Alien::Build::rc;

use strict;
use warnings;
use 5.008004;

# ABSTRACT: Alien::Build local config
# VERSION

=head1 SYNOPSIS

in your C<~/.alienbuild/rc.pl>:

 preload 'Foo::Bar';
 postload 'Baz::Frooble';

=head1 DESCRIPTION

L<Alien::Build> will load your C<~/.alienbuild/rc.pl> file, if it exists
before running the L<alienfile> recipe.  This allows you to alter the
behavior of L<Alien::Build> based L<Alien>s if you have local configuration
requirements.  For example you can prompt before downloading remote content
or fetch from a local mirror.

=head1 FUNCTIONS

=head2 logx

 log $message;

Send a message to the L<Alien::Build> log.

=cut

sub logx ($)
{
  unshift @_, 'Alien::Build';
  goto &Alien::Build::log;
}

=head2 preload_plugin

 preload_plugin $plugin, @args;

Preload the given plugin, with arguments.

=cut

sub preload_plugin
{
  my(@args) = @_;
  push @Alien::Build::rc::PRELOAD, sub {
    shift->apply_plugin(@args);
  };
}

=head2 postload_plugin

 postload_plugin $plugin, @args;

Postload the given plugin, with arguments.

=cut

sub postload_plugin
{
  my(@args) = @_;
  push @Alien::Build::rc::POSTLOAD, sub {
    shift->apply_plugin(@args);
  };
}

=head2 preload

[deprecated]

 preload $plugin;

Preload the given plugin.

=cut

sub preload ($)
{
  push @Alien::Build::rc::PRELOAD, $_[0];
}

=head2 postload

[deprecated]

 postload $plugin;

Postload the given plugin.

=cut

sub postload ($)
{
  push @Alien::Build::rc::POSTLOAD, $_[0];
}

1;

=head1 SEE ALSO

=over 4

=item L<Alien::Build::Plugin::Fetch::Cache>

=item L<Alien::Build::Plugin::Fetch::Prompt>

=item L<Alien::Build::Plugin::Fetch::Rewrite>

=item L<Alien::Build::Plugin::Probe::Override>

=back

