package Alien::Build::Plugin;

use strict;
use warnings;

# ABSTRACT: Plugin base class for Alien::Build
# VERSION

=head1 CONSTRUCTOR

=head2 new

 my $plugin = Alien::Build::Plugin->new;

=cut

sub new
{
  my($class) = @_;
  bless {}, $class;
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
  my $meta = $class->meta;
  my $has = sub {
    my($name, $default) = @_;
    $meta->add_property($name, $default);
  };
  my $caller = caller;
  no strict 'refs';
  @{ "${caller}::ISA" } = __PACKAGE__;
  *{ "${caller}::has" } = $has;
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

sub add_property
{
  my($self, $name, $default) = @_;
  $self->{prop}->{$name} = $default;
}

1;
