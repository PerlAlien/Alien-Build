package Alien::Build;

use strict;
use warnings;
use Path::Tiny ();

# ABSTRACT: Build external dependencies for use in CPAN
# VERSION

sub _path { Path::Tiny::path(@_) }

=head1 CONSTRUCTOR

=head2 new

 my $build = Alien::Build->new;

=cut

sub new
{
  my($class) = @_;
  my $self = bless {}, $class;
  my(undef, $filename) = caller;
  $self->meta->filename(_path($filename)->absolute->stringify);
  $self;
}

my $count = 0;

=head1 METHODS

=head2 load

 my $build = Alien::Build->load($filename);

=cut

sub load
{
  my(undef, $filename) = @_;

  unless(-r $filename)
  {
    require Carp;
    Carp::croak "Unable to read alienfile: $filename";
  }

  my $file = _path $filename;
  my $name = $file->parent->basename;
  $name =~ s/^alien-//i;
  $name =~ s/[^a-z]//g;
  $name = 'x' if $name eq '';
  $name = ucfirst $name;

  my $class = "Alien::Build::Auto::$name@{[ $count++ ]}";

  { no strict 'refs';  
  @{ "${class}::ISA" } = ('Alien::Build');
  *{ "${class}::Alienfile::meta" } = sub {
    my($class) = @_;
    $class =~ s{::Alienfile$}{};
    $class->meta;
  }};
  
  $class->meta->filename($file->absolute->stringify);
  
  my $self = bless {}, $class;

  eval '# line '. __LINE__ . ' "' . __FILE__ . qq("\n) . qq{
    package ${class}::Alienfile;
    do '@{[ $file->absolute->stringify ]}';
    die \$\@ if \$\@;
  };
  die $@ if $@;

  return $self;
}

sub _merge
{
  my %h;
  while(@_)
  {
    my $mod = shift;
    my $ver = shift;
    if($ver > ($h{$mod} || 0))
    { $h{$mod} = $ver }
  }
  \%h;
}

=head2 requires

 my $hash = Alien::Build->requires;
 my $hash = $build->requires;

=cut

sub requires
{
  my($class, $phase) = @_;
  $phase ||= 'any';
  my $meta = $class->meta;
  $phase eq 'any'
  ? $meta->{require}->{any}
  : _merge %{ $meta->{require}->{any} }, %{ $meta->{require}->{$phase} };
}

my %meta;

=head2 meta

 my $meta = Alien::Build->meta;
 my $meta = $build->meta;

=cut

sub meta
{
  my($class) = @_;
  $class = ref $class if ref $class;
  $meta{$class} ||= Alien::Build::Meta->new( class => $class );
}

package Alien::Build::Meta;

sub new
{
  my($class, %args) = @_;
  my $self = bless {
    phase => 'any',
    require => {
      any    => {},
      share  => {},
      system => {},
    },
    %args
  }, $class;
  $self;
}

sub filename
{
  my($self, $new) = @_;
  $self->{filename} = $new if defined $new;
  $self->{filename};
}

sub add_requires
{
  my($self, $module, $version) = @_;
  my $phase = $self->{phase};
  my $old = $self->{require}->{$phase}->{$module} || 0;
  if($version > $old)
  { $self->{require}->{$phase}->{$module} = $version }
  $self;
}

sub interpolator
{
  my($self, $new) = @_;
  if(defined $new)
  {
    if(defined $self->{intr})
    {
      require Carp;
      Carp::croak "tried to set interpolator twice";
    }
    if(ref $new)
    {
      $self->{intr} = $new;
    }
    else
    {
      $self->{intr} = $new->new;
    }
  }
  elsif(!defined $self->{intr})
  {
    require Alien::Build::Interpolate::Default;
    $self->{intr} = Alien::Build::Interpolate::Default->new;
  }
  $self->{intr};
}

sub _dump
{
  my($self) = @_;
  if(eval { require YAML })
  {
    return YAML::Dump($self);
  }
  else
  {
    require Data::Dumper;
    return Data::Dumper::Dumper($self);
  }
}

1;
