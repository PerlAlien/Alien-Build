package Alien::Build::CommandSequence;

use strict;
use warnings;
use Capture::Tiny qw( capture );

# ABSTRACT: Alien::Build command sequence
# VERSION

=head1 CONSTRUCTOR

=head2 new

 my $seq = Alien::Build::CommandSequence->new(@commands);

=cut

sub new
{
  my($class, @commands) = @_;
  my $self = bless {
    commands => \@commands,
  }, $class;
  $self;
}

=head1 METHODS

=head2 apply_requirements

 $seq->apply_requirements($meta, $phase);

=cut

sub apply_requirements
{
  my($self, $meta, $phase) = @_;
  my $intr = $meta->interpolator;
  foreach my $command (@{ $self->{commands} })
  {
    next if ref $command eq 'CODE';
    if(ref $command eq 'ARRAY')
    {
      foreach my $arg (@$command)
      {
        next if ref $arg eq 'CODE';
        $meta->add_requires($phase, $intr->requires($arg))
      }
    }
    else
    {
      $meta->add_requires($phase, $intr->requires($command));
    }
  }
  $self;
}

sub _run
{
  my($build, @cmd) = @_;
  $build->log("+ @cmd");
  system @cmd;
  die "external command failed" if $?;
}

sub _run_with_code
{
  my($build, @cmd) = @_;
  my $code = pop @cmd;
  $build->log("+ @cmd");
  my %args = ( command => \@cmd );
  ($args{out}, $args{err}, $args{exit}) = capture {
    system @cmd; $?
  };
  $build->log("[output consumed by Alien::Build recipe]");
  $code->($build, \%args);
}

=head2 execute

 $seq->execute($build);

=cut

sub _apply
{
  my($where, $prop, $value) = @_;
  if($where =~ /^(.*?)\.(.*?)$/)
  {
    _apply($2, $prop->{$1}, $value);
  }
  else
  {
    $prop->{$where} = $value;
  }
}

sub execute
{
  my($self, $build) = @_;
  my $intr = $build->meta->interpolator;

  my $prop = $build->_command_prop;
  
  foreach my $command (@{ $self->{commands} })
  {
    if(ref($command) eq 'CODE')
    {
      $command->($build);
    }
    elsif(ref($command) eq 'ARRAY')
    {
      my($command, @args) = @$command;
      my $code = pop @args if $args[-1] && ref($args[-1]) eq 'CODE';
      
      if($args[-1] && ref($args[-1]) eq 'SCALAR')
      {
        my $dest = ${ pop @args };
        if($dest =~ /^\%\{(alien\.(?:install|runtime|hook)\.[a-z\.]+)\}$/)
        {
          $dest = $1;
          $code = sub {
            my($build, $args) = @_;
            die "external command failed" if $args->{exit};
            my $out = $args->{out};
            chomp $out;
            _apply($dest, $prop, $out);
          };
        }
        else
        {
          die "illegal destination: $dest";
        }
      }
      
      ($command, @args) = map { $intr->interpolate($_, $prop) } ($command, @args);
      
      if($code)
      {
        _run_with_code $build, $command, @args, $code;
      }
      else
      {
        _run $build, $command, @args;
      }
    }
    else
    {
      my $command = $intr->interpolate($command,$prop);
      _run $build, $command;
    }
  }
}

1;
