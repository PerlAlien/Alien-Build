package Alien::Build::Plugin::Test::Mock;

use strict;
use warnings;
use Alien::Build::Plugin;
use Carp ();

=head1 SYNOPSIS

 use alienfile;
 plugin 'Test::Mock';

=head1 DESCRIPTION

This plugin is used for testing L<Alien::Build> plugins.  Usually you only want to test
one or two phases in an L<alienfile> for your plugin, but you still have to have a fully
formed L<alienfile> that contains all required phases.  This plugin lets you fill in the
other phases with the appropriate hooks.  This is usually better than using real plugins
which may pull in additional dynamic requirements that you do not want to rely on at
test time.

=head1 PROPERTIES

=head2 probe

 plugin 'Test::Mock' => (
   probe => $probe,
 );

Override the probe behavior by one of the following:

=over

=item share

For a C<share> build.

=item system

For a C<system> build.

=item die

To throw an exception in the probe hook.  This will usually cause L<Alien::Build>
to try the next probe hook, if available, or to assume a C<share> install.

=back

=cut

has 'probe';

sub init
{
  my($self, $meta) = @_;
  
  if(my $probe = $self->probe)
  {
    if($probe =~ /^(share|system)$/)
    {
      $meta->register_hook(
        probe => sub {
          $probe;
        },
      );
    }
    elsif($probe eq 'die')
    {
      $meta->register_hook(
        probe => sub {
          die "fail";
        },
      );
    }
    else
    {
      Carp::croak("usage: plugin 'Test::Mock' => ( probe => $probe ); where $probe is one of share, system or die");
    }
  }
}

1;
