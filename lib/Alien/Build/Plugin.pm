package Alien::Build::Plugin;

use strict;
use warnings;
use Carp ();

# ABSTRACT: Plugin base class for Alien::Build
# VERSION

=head1 CONSTRUCTOR

=head2 new

 my $plugin = Alien::Build::Plugin->new;

=cut

sub new
{
  my $class = shift;
  my %args = @_ == 1 ? ($class->meta->default => $_[0]) : @_;
  my $self = bless {}, $class;
  
  my $prop = $self->meta->prop;
  foreach my $name (keys %$prop)
  {
    $self->{$name} = defined $args{$name} 
      ? delete $args{$name} 
      : ref($prop->{$name}) eq 'CODE'
        ? $prop->{$name}->()
        : $prop->{$name};
  }
  
  foreach my $name (keys %args)
  {
    Carp::carp "$class has no $name property";
  }
  
  $self;
}

=head1 METHODS

=head2 init

 $plugin->init($ab->meta); # $ab isa Alien::Build

=cut

sub init
{
  my($self) = @_;
  $self;
}

sub import
{
  my($class) = @_;

  return if $class ne __PACKAGE__;

  my $caller = caller;
  { no strict 'refs'; @{ "${caller}::ISA" } = __PACKAGE__ }
  
  my $meta = $caller->meta;
  my $has = sub {
    my($name, $default) = @_;
    $meta->add_property($name, $default);
  };
  
  { no strict 'refs'; *{ "${caller}::has" } = $has }
}

my %meta;
sub meta
{
  my($class) = @_;
  $class = ref $class if ref $class;
  $meta{$class} ||= Alien::Build::PluginMeta->new( class => $class );
}

package Alien::Build::PluginMeta;

sub new
{
  my($class, %args) = @_;
  my $self = bless {
    prop => {},
    %args,
  }, $class;
}

sub default
{
  my($self) = @_;
  $self->{default} || do {
    Carp::croak "No default for @{[ $self->{class} ]}";
  };
}

sub add_property
{
  my($self, $name, $default) = @_;
  my $single = $name =~ s{^(\+)}{};
  $self->{default} = $name if $single;
  $self->{prop}->{$name} = $default;

  my $accessor = sub {
    my($self, $new) = @_;
    $self->{$name} = $new if defined $new;
    $self->{$name};
  };
  
  # add the accessor
  { no strict 'refs'; *{ $self->{class} . '::' . $name} = $accessor }

  $self;
}

sub prop
{
  shift->{prop};
}

1;
