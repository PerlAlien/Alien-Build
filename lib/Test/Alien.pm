package Test::Alien;

use strict;
use warnings;
use 5.008001;
use Env qw( @PATH );
use File::Which 1.10 qw( which );
use Capture::Tiny qw( capture );
use Test::Stream::Context qw( context );
use Test::Stream::Exporter;
default_exports qw( alien_ok run_ok );
no Test::Stream::Exporter;

# ABSTRACT: Testing tools for Alien modules
# VERSION

=head1 FUNCTIONS

=head2 alien_ok

 alien_ok $alien, $message;
 alien_ok $alien;

Load the given L<Alien> instance or class.  Checks that the instance or class conforms to the same
interface as L<Alien::Base>.  Will be used by subsequent tests.

=cut

our @aliens;

sub alien_ok ($;$)
{
  my($alien, $message) = @_;

  my $name = ref $alien ? ref($alien) . '[instance]' : $alien;
  
  my @methods = qw( dist_dir cflags libs install_type config dynamic_libs bin_dir alien_helper );
  $message ||= "$name responds to: @methods";
  my @missing = grep { ! $alien->can($_) } @methods;
  
  my $ok = !@missing;
  my $ctx = context();
  $ctx->ok($ok, $message);
  $ctx->diag("  missing method $_") for @missing;
  $ctx->release;
  
  push @aliens, $alien if $ok;
  
  $ok;
}

=head2 run_ok

 my $run = run_ok $command;
 my $run = run_ok $command, $message;

Runs the given command, falling back on any C<Alien::Base#bin_dir> methods provided by L<Alien> modules
specified with L</alien_ok>.

C<$command> can be either a string or an array reference.

Only fails if the command cannot be found, or if it is killed by a signal!  Returns a L<Test::Alien::Run>
object, which you can use to test the exit status, output and standard error.

Always returns an instance of L<Test::Alien::Run>, even if the command could not be found.

=cut

sub run_ok
{
  my($command, $message) = @_;
  
  local @PATH = @PATH;
  unshift @PATH, map { $_->bin_dir } @aliens;
  
  my(@command) = ref $command ? @$command : ($command);
  $message ||= "run @command";
  
  require Test::Alien::Run;
  my $run = bless {
    out    => '',
    err    => '',
    exit   => 0,
    sig    => 0,
  }, 'Test::Alien::Run';
  
  my $ctx = context();
  my $exe = which shift @command;
  if(defined $exe)
  {
    my @diag;
    my $ok = 1;
    my($exit, $errno);
    ($run->{out}, $run->{err}, $exit, $errno) = capture { system $exe, @command; ($?,$!); };
  
    if($exit == -1)
    {
      $ok = 0;
      $run->{fail} = "failed to execute: $errno";
      push @diag, "  failed to execute: $errno";
    }
    elsif($exit & 127)
    {
      $ok = 0;
      push @diag, "  killed with signal: @{[ $exit & 127 ]}";
      $run->{sig} = $exit & 127;
    }
    else
    {
      $run->{exit} = $exit >> 8;
    }

    $ctx->ok($ok, $message);
    $ok 
      ? $ctx->note("  using $exe") 
      : $ctx->diag("  using $exe");
    $ctx->diag(@diag) for @diag;

  }
  else
  {
    $ctx->ok(0, $message);
    $ctx->diag("  command not found");
    $run->{fail} = 'command not found';
  }
  
  $ctx->release;
  
  $run;
}

1;
