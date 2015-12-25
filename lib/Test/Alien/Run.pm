package Test::Alien::Run;

use strict;
use warnings;
use Test::Stream::Context qw( context );

# ABSTRACT: Run object
# VERSION

=head1 ATTRIBUTES

=head2 out

 my $str = $run->out;

The standard output from the run.

=head2 err

 my $str = $run->err;

The standard error from the run.

=head2 exit

 my $int = $run->exit;

The exit value of the run.

=head2 signal

 my $int = $run->signal;

The signal that killed the run, or zero if the process was terminated normally.

=cut

sub out    { shift->{out} }
sub err    { shift->{err} }
sub exit   { shift->{exit} }
sub signal { shift->{sig} }

=head1 METHODS

=head2 success

 $run->success;
 $run->success($message);

Passes if the process terminated normally with an exit value of 0.

=cut

sub success
{
  my($self, $message) = @_;
  $message ||= 'command succeeded';
  my $ok = $self->exit == 0 && $self->signal == 0;
  $ok = 0 if $self->{fail};

  my $ctx = context();
  $ctx->ok($ok, $message);
  unless($ok)
  {
    $ctx->diag("  command exited with @{[ $self->exit   ]}") if $self->exit;
    $ctx->diag("  command killed with @{[ $self->signal ]}") if $self->signal;
    $ctx->diag("  @{[ $self->{fail} ]}") if $self->{fail};
  }
  $ctx->release;
  $self;
}

=head2 exit_is

 $run->exit_is($exit);
 $run->exit_is($exit, $message);

Passes if the process terminated with the given exit value.

=cut

sub exit_is
{
  my($self, $exit, $message) = @_;
  
  $message ||= "command exited with value $exit";
  my $ok = $self->exit == $exit;
  
  my $ctx = context();
  $ctx->ok($ok, $message);
  $ctx->diag("  actual exit value was: @{[ $self->exit ]}") unless $ok;
  $ctx->release;
  $self;
}

1;
