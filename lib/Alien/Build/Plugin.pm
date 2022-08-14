package Alien::Build::Plugin;

use strict;
use warnings;
use 5.008004;
use Data::Dumper ();
use Carp ();
use Digest::SHA ();

our @CARP_NOT = qw( alienfile Alien::Build Alien::Build::Meta );

# ABSTRACT: Plugin base class for Alien::Build
# VERSION

=head1 SYNOPSIS

Create your plugin:

 package Alien::Build::Plugin::Type::MyPlugin;
 
 use Alien::Build::Plugin;
 use Carp ();
 
 has prop1 => 'default value';
 has prop2 => sub { 'default value' };
 has prop3 => sub { Carp::croak 'prop3 is a required property' };
 
 sub init
 {
   my($self, $meta) = @_;
 
   my $prop1 = $self->prop1;
   my $prop2 = $self->prop2;
   my $prop3 = $self->prop3;
 
   $meta->register_hook(sub {
     build => [ '%{make}', '%{make} install' ],
   });
 }

From your L<alienfile>

 use alienfile;
 plugin 'Type::MyPlugin' => (
   prop2 => 'different value',
   prop3 => 'need to provide since it is required',
 );

=head1 DESCRIPTION

This document describes the L<Alien::Build> plugin base class.  For details
on how to write a plugin, see L<Alien::Build::Manual::PluginAuthor>.

Listed are some common types of plugins:

=over 4

=item L<Alien::Build::Plugin::Build>

Tools for building.

=item L<Alien::Build::Plugin::Core>

Tools already included.

=item L<Alien::Build::Plugin::Download>

Methods for retrieving from the internet.

=item L<Alien::Build::Plugin::Decode>

Normally use Download plugins which will pick the correct Decode plugins.

=item L<Alien::Build::Plugin::Extract>

Extract from archives that have been downloaded.

=item L<Alien::Build::Plugin::Fetch>

Normally use Download plugins which will pick the correct Fetch plugins.

=item L<Alien::Build::Plugin::Prefer>

Normally use Download plugins which will pick the correct Prefer plugins.

=item L<Alien::Build::Plugin::Probe>

Look for packages already installed on the system.

=back

=head1 CONSTRUCTOR

=head2 new

 my $plugin = Alien::Build::Plugin->new(%props);

=cut

sub new
{
  my $class = shift;
  my %args = @_ == 1 ? ($class->meta->default => $_[0]) : @_;

  my $instance_id = Digest::SHA::sha1_hex(Data::Dumper->new([$class, \%args])->Sortkeys(1)->Dump);
  my $self = bless { instance_id => $instance_id }, $class;

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

=head2 PROPERTIES

=head2 instance_id

 my $id = $plugin->instance_id;

Returns an instance id for the plugin.  This is computed from the class and
arguments that are passed into the plugin constructor, so technically two
instances with the exact same arguments will have the same instance id, but
in practice you should never have two instances with the exact same arguments.

=cut

sub instance_id { shift->{instance_id} }

=head1 METHODS

=head2 init

 $plugin->init($ab_class->meta); # $ab is an Alien::Build class name

You provide the implementation for this.  The intent is to register
hooks and set meta properties on the L<Alien::Build> class.

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

=head2 has

 has $prop_name;
 has $prop_name => $default;

Specifies a property of the plugin.  You may provide a default value as either
a string scalar, or a code reference.  The code reference will be called to
compute the default value, and if you want the default to be a list or hash
reference, this is how you want to do it:

 has foo => sub { [1,2,3] };

=head2 meta

 my $meta = $plugin->meta;

Returns the plugin meta object.

=cut

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

=head1 SEE ALSO

L<Alien::Build>, L<alienfile>, L<Alien::Build::Manual::PluginAuthor>

=cut

