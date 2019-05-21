package Alien::Build::Log::Abbreviate;

use strict;
use warnings;
use 5.008001;
use Term::ANSIColor ();
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

sub colored
{
  -t STDOUT ? Term::ANSIColor::colored(@_) : '';
}

sub log
{
  my(undef, %args) = @_;
  my($message) = $args{message};
  my ($package, $filename, $line) = @{ $args{caller} };

  my $source = $package;
  $source =~ s/^Alien::Build::Auto::[^:]+::Alienfile/alienfile/;
  $source =~ s/^Alien::Build::Plugin/ABP/;
  $source =~ s/^Alien::Build/AB/;

  print colored([ "bold on_black"          ], '[');
  print colored([ "bright_green on_black"  ], $source);
  print colored([ "on_black"               ], ' ');
  print colored([ "bright_yellow on_black" ], $line);
  print colored([ "bold on_black"          ], ']');
  print colored([ "white on_black"         ], ' ', $message);
  print "\n";
}

1;
