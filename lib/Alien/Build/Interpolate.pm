package Alien::Build::Interpolate;

use strict;
use warnings;

# ABSTRACT: Advanced interpolation engine for Alien builds
# VERSION

=head1 CONSTRUCTOR

=head2 new

 my $intr = Alien::Build::Interpolate->new;

=cut

sub new
{
  my($class) = @_;
  my $self = bless {
    helper  => {},
    classes => {},
  }, $class;
  $self;
}

=head2 add_helper

 $intr->add_helper($name => $code);
 $intr->add_helper($name => $code, %requirements);

=cut

sub add_helper
{
  my $self = shift;
  my $name = shift;
  my $code = shift;

  if(defined $self->{helper}->{$name})
  {
    require Carp;
    Carp::croak("duplicate implementation for interpolated key $name");
  }

  my @require;

  while(@_)
  {
    my $module = shift;
    my $version = shift;
    $version ||= 0;
    push @require, $module => $version;
  }

  $self->{helper}->{$name} = Alien::Build::Helper->new(
    $code,
    \@require,
  );
}

=head2 replace_helper

 $intr->replace_helper($name => $code);
 $intr->replace_helper($name => $code, %requirements);

=cut

sub replace_helper
{
  my $self = shift;
  my($name) = @_;
  delete $self->{helper}->{$name};
  $self->add_helper(@_);
}

=head2 has_helper

 my $coderef = $intr->has_helper($name);

Used to discover if a helper exists with the given name.
Returns the code reference.

=cut

sub has_helper
{
  my($self, $name) = @_;

  return unless defined $self->{helper}->{$name};

  my @require = @{ $self->{helper}->{$name}->{require} };

  while(@require)
  {
    my $module  = shift @require;
    my $version = shift @require;

    {
      my $pm = "$module.pm";
      $pm =~ s/::/\//g;
      require $pm;
      $module->VERSION($version) if $version;
    }

    unless($self->{classes}->{$module})
    {
      if($module->can('alien_helper'))
      {
        my $helpers = $module->alien_helper;
        foreach my $k (keys %$helpers)
        {
          $self->{helper}->{$k}->{code} = $helpers->{$k};
        }
      }
      $self->{classes}->{$module} = 1;
    }
  }

  my $code = $self->{helper}->{$name}->{code};

  return unless defined $code;

  if(ref($code) ne 'CODE')
  {
    my $perl = $code;
    package Alien::Build::Interpolate::Helper;
    $code = sub {
      ##  no critic
      my $value = eval $perl;
      ## use critic
      die $@ if $@;
      $value;
    };
  }

  $code;
}

=head2 execute_helper

 my $value = $intr->execute_helper($name);

=cut

sub execute_helper
{
  my($self, $name) = @_;

  my $code = $self->has_helper($name);
  die "no helper defined for $name" unless defined $code;

  $code->();
}

=head2 interpolate

 my $string = $intr->interpolate($template);

=cut

sub _get_prop
{
  my($name, $prop, $orig) = @_;

  $name =~ s/^\./alien./;

  if($name =~ /^(.*?)\.(.*)$/)
  {
    my($key,$rest) = ($1,$2);
    return _get_prop($rest, $prop->{$key}, $orig);
  }
  elsif(exists $prop->{$name})
  {
    return $prop->{$name};
  }
  else
  {
    require Carp;
    Carp::croak("No property $orig is defined");
  }
}

sub interpolate
{
  my($self, $string, $prop) = @_;
  $prop ||= {};

  $string =~ s{(?<!\%)\%\{([a-zA-Z_][a-zA-Z_0-9]+)\}}{$self->execute_helper($1)}eg;
  $string =~ s{(?<!\%)\%\{([a-zA-Z_\.][a-zA-Z_0-9\.]+)\}}{_get_prop($1,$prop,$1)}eg;
  $string =~ s/\%(?=\%)//g;
  $string;
}

=head2 requires

 my %requires = $intr->requires($template);

=cut

sub requires
{
  my($self, $string) = @_;
  map {
    @{ $self->{helper}->{$_}->{require} }
  } $string =~ m{(?<!\%)\%\{([a-zA-Z_][a-zA-Z_0-9]+)\}}g;
}

=head2 clone

 my $intr2 = $intr->clone;

=cut

sub clone
{
  my($self) = @_;

  require Storable;

  my %help;
  foreach my $name (keys %{ $self->{helper} })
  {
    $help{$name} = Alien::Build::Helper->new(
      $self->{helper}->{$name}->{code},
      $self->{helper}->{$name}->{require},
    );
  }

  my $new = bless {
    helper => \%help,
    classes => Storable::dclone($self->{classes}),
  }, ref $self;
}

package Alien::Build::Helper;

sub new
{
  my($class, $code, $require) = @_;
  bless {
    code    => $code,
    require => $require,
  }, $class;
}

1;
