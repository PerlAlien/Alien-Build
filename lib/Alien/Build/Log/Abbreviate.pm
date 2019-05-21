package Alien::Build::Log::Abbreviate;

use strict;
use warnings;
use 5.008001;
use base qw( Alien::Build );

# ABSTRACT: Log class for Alien::Build which is less verbose
# VERSION

=head1 SYNOPSIS

=head1 DESCRIPTION

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

  $package =~ s/^Alien::Build::Auto::[^:]+::Alienfile/alienfile/;
  $package =~ s/^Alien::Build::Plugin/ABP/;
  $package =~ s/^Alien::Build/AB/;
  printf "%s:%04d> %s\n", $package, $line, $message;
}

1;
