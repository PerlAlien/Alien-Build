package Alien::Build::Log::Abbreviate;

use strict;
use warnings;
use 5.008001;
use Term::ANSIColor ();
use Path::Tiny qw( path );
use File::chdir;
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

sub _colored
{
  my($code, @out) = @_;
  -t STDOUT ? Term::ANSIColor::_colored($code, @out) : @out;
}

my $root = path("$CWD");

sub log
{
  my(undef, %args) = @_;
  my($message) = $args{message};
  my ($package, $filename, $line) = @{ $args{caller} };

  my $source = $package;
  $source =~ s/^Alien::Build::Auto::[^:]+::Alienfile/alienfile/;

  my $expected = $package;
  $expected .= '.pm' unless $package eq 'alienfile';
  $expected =~ s/::/\//g;
  if($filename !~ /\Q$expected\E$/)
  {
    $source = path($filename)->relative($root);
  }
  else
  {
    $source =~ s/^Alien::Build::Plugin/ABP/;
    $source =~ s/^Alien::Build/AB/;
  }

  print _colored([ "bold on_black"          ], '[');
  print _colored([ "bright_green on_black"  ], $source);
  print _colored([ "on_black"               ], ' ');
  print _colored([ "bright_yellow on_black" ], $line);
  print _colored([ "bold on_black"          ], ']');
  print _colored([ "white on_black"         ], ' ', $message);
  print "\n";
}

1;
