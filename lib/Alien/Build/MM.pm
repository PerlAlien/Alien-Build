package Alien::Build::MM;

use strict;
use warnings;
use Alien::Build;
use Path::Tiny ();
use Carp ();

# ABSTRACT: Alien::Build installer code for ExtUtils::MakeMaker
# VERSION

sub _path { goto \&Path::Tiny::path };

=head1 CONSTRUCTOR

=head2 new

 my $mm = Alien::Build::MM->new;

=cut

sub new
{
  my($class) = @_;
  
  my $self = bless {}, $class;
  
  $self->{build} =
    Alien::Build->load('alienfile',
      root     => "_alien",
      autosave => 1,
    )
  ;
  
  $self->build->load_requires('configure');
  $self->build->root;

  $self;
}

=head1 PROPERTIES

=head2 build

 my $build = $mm->build;

=cut

sub build
{
  shift->{build};
}

=head1 METHODS

=head2 mm_args

 my %args = $mm->mm_args(%args);

=cut

sub mm_args
{
  my($self, %args) = @_;
  
  if($args{DISTNAME})
  {
    $self->build->install_prop->{stage} = _path("blib/lib/auto/share/$args{DISTNAME}")->absolute->stringify;
  }
  else
  {
    Carp::croak "DISTNAME is required";
  }
  
  my $ab_version = '0.01';
  
  $args{CONFIGURE_REQUIRES} = Alien::Build::_merge(
    'Alien::Build::MM' => $ab_version,
    %{ $args{CONFIGURE_REQUIRES} || {} },
    %{ $self->build->requires('configure') || {} },
  );

  if($self->build->install_type eq 'system')
  {
    $args{BUILD_REQUIRES} = Alien::Build::_merge(
      'Alien::Build::MM' => $ab_version,
      %{ $args{BUILD_REQUIRES} || {} },
      %{ $self->build->requires('system') || {} },
    );
  }
  else # share
  {
    $args{BUILD_REQUIRES} = Alien::Build::_merge(
      'Alien::Build::MM' => $ab_version,
      %{ $args{BUILD_REQUIRES} || {} },
      %{ $self->build->requires('share') || {} },
    );
  }
  
  $args{PREREQ_PM} = Alien::Build::_merge(
    'Alien::Build' => $ab_version,
    %{ $args{PREREQ_PM} || {} },
  );
 
  #$args{META_MERGE}->{'meta-spec'}->{version} = 2;
  $args{META_MERGE}->{dynamic_config} = 1;
  
  %args;
}

=head2 mm_postamble

 my %args = $mm->mm_args(%args);

=cut

sub mm_postamble
{
  my($self) = @_;
  
  my $postamble = '';
  
  # remove the _alien directory on a make realclean:
  $postamble .= "distclean :: alien_distclean\n" .
                "\n" .
                "alien_distclean:\n" .
                "\t\$(RM_RF) _alien\n\n";

  # set prefix
  $postamble .= "alien_prefix : _alien/mm/prefix\n\n" .
                "_alien/mm/prefix :\n" .
                "\t\$(FULLPERL) -MAlien::Build::MM=cmd -e set_prefix \$(INSTALLDIRS) \$(INSTALLARCHLIB) \$(INSTALLSITEARCH) \$(INSTALLVENDORARCH)\n\n";

  # download
  $postamble .= "alien_download : _alien/mm/download\n\n" .
                "_alien/mm/download : _alien/mm/prefix\n" .
                "\t\$(FULLPERL) -MAlien::Build::MM=cmd -e download\n\n";

  # build
  $postamble .= "alien_build : _alien/mm/build\n\n" .
                "_alien/mm/build : _alien/mm/download\n" .
                "\t\$(FULLPERL) -MAlien::Build::MM=cmd -e build\n\n";
  
  # append to all
  $postamble .= "pure_all :: _alien/mm/build\n\n";
  
  $postamble;
}

sub import
{
  my(undef, @args) = @_;
  foreach my $arg (@args)
  {
    if($arg eq 'cmd')
    {
      package main;
      
      *_args = sub
      {
        (Alien::Build->resume('alienfile', '_alien'), @ARGV)
      };
      
      *_touch = sub {
        my($name) = @_;
        require Path::Tiny;
        my $path = Path::Tiny->new("_alien/mm/$name");
        $path->parent->mkpath;
        $path->touch;
      };
      
      *set_prefix = sub
      {
        my($build, $type, $perl, $site, $vendor) = _args();
        $DB::single = 1;
        my $prefix = $type eq 'perl'
          ? $perl
          : $type eq 'site'
            ? $site
            : $type eq 'vendor'
              ? $vendor
              : die "unknown INSTALLDIRS ($type)";
        $prefix = Path::Tiny->new($prefix)->absolute->stringify;
        $build->set_prefix($prefix);
        $build->checkpoint;
        _touch('prefix');
      };
      
      *download = sub
      {
        my($build) = _args();
        $build->load_requires('configure');
        if($build->install_type eq 'share')
        {
          $build->load_requires($build->install_type);
          $build->download;
        }
        _touch('download');
      };
      
      *build = sub
      {
        my($build) = _args();
        
        $build->load_requires('configure');
        $build->load_requires($build->install_type);
        $build->build;
        _touch('build');
      };
    }
  }
}

1;
