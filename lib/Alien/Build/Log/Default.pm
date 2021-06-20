package Alien::Build::Log::Default;

use strict;
use warnings;
use 5.008004;
use parent qw( Alien::Build::Log );

# ABSTRACT: Default Alien::Build log class
# VERSION

=head1 SYNOPSIS

 Alien::Build->log("message1");
 $build->log("message2");

=head1 DESCRIPTION

This is the default log class for L<Alien::Build>.  It does
the sensible thing of sending the message to stdout, along
with the class that made the log call.  For more details
about logging with L<Alien::Build>, see L<Alien::Build::Log>.

=head1 METHODS

=head2 log

 $log->log(%opts);

Send single log line to stdout.

=cut

sub log
{
  my(undef, %args) = @_;
  my($message) = $args{message};
  my ($package, $filename, $line) = @{ $args{caller} };
  print "$package> $message\n";
}

1;

=head1 SEE ALSO

=over 4

=item L<Alien::Build>

=item L<Alien::Build::Log>

=back

=cut
