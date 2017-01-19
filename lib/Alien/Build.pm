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
    if((!defined $h{$mod}) || $ver > $h{$mod})
    { $h{$mod} = $ver }
  }
  \%h;
}

=head2 requires

 my $hash = $build->requires($phase);

=cut

sub requires
{
  my($class, $phase) = @_;
  $phase ||= 'any';
  my $meta = $class->meta;
  $phase =~ /^(?:any|configure)$/
  ? $meta->{require}->{$phase}
  : _merge %{ $meta->{require}->{any} }, %{ $meta->{require}->{$phase} };
}

=head2 load_requires

 $build->load_requires;

=cut

sub load_requires
{
  my($class, $phase) = @_;
  my $reqs = $class->requires($phase);
  foreach my $mod (keys %$reqs)
  {
    my $ver = $reqs->{$mod};
    eval qq{ use $mod $ver () };
    return 0 if $@;
  }
  1;
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

=head2 fetch

 my $response = $build->fetch;

=cut

sub fetch
{
  my($self, $url) = @_;
  my $meta = $self->meta;
  $meta->call_hook( 'fetch' => $url );
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
    %args,
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
  my $self = shift;
  my $phase = shift;
  while(@_)
  {
    my $module = shift;
    my $version = shift;
    my $old = $self->{require}->{$phase}->{$module};
    if((!defined $old) || $version > $old)
    { $self->{require}->{$phase}->{$module} = $version }
  }
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

sub register_hook
{
  my($self, $name, $instr) = @_;
  $self->{hook}->{$name} = $instr;
  $self;
}

sub call_hook
{
  my($self, $name, @args) = @_;
  my $hook = $self->{hook}->{$name};
  if(ref($hook) eq 'CODE')
  {
    return $hook->(@args);
  }
  else
  {
    die "fixme";
  }
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
