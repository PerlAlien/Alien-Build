package Alien::Build::MM;

use strict;
use warnings;
use Alien::Build;
use Path::Tiny ();
use Carp ();

# ABSTRACT: Alien::Build installer code for ExtUtils::MakeMaker
# VERSION

=head1 SYNOPSIS

In your Makefile.PL:

 use ExtUtils::MakeMaker;
 use Alien::Build::MM;
 
 my $abmm = Alien::Build::MM->new;
 
 WriteMakefile($abmm->mm_args(
   ABSTRACT     => 'Discover or download and install libfoo',
   DISTNAME     => 'ALien-Libfoo',
   NAME         => 'Alien::Libfoo',
   VERSION_FROM => 'lib/Alien/Libfoo.pm',
   ...
 ));
 
 sub MY::postamble {
   $abmm->mm_postamble;
 }

In your lib/Alien/Libfoo.pm:

 package Alien::Libfoo;
 use base qw( Alien::Base );
 1;

=head1 DESCRIPTION

This class allows you to use Alien::Build and Alien::Base with L<ExtUtils::MakeMaker>.

=head1 CONSTRUCTOR

=head2 new

 my $abmm = Alien::Build::MM->new;

Create a new instance of L<Alien::Build::MM>.

=cut

sub new
{
  my($class) = @_;
  
  my $self = bless {}, $class;
  
  my $build = $self->{build} =
    Alien::Build->load('alienfile',
      root     => "_alien",
      (-d 'patch' ? (patch => 'patch') : ()),
    )
  ;
  
  $self->build->load_requires('configure');
  $self->build->root;
  $self->build->checkpoint;

  $self;
}

=head1 PROPERTIES

=head2 build

 my $build = $abmm->build;

The L<Alien::Build> instance.

=cut

sub build
{
  shift->{build};
}

=head1 METHODS

=head2 mm_args

 my %args = $abmm->mm_args(%args);

Adjust the arguments passed into C<WriteMakefile> as needed by L<Alien::Build>.

=cut

sub mm_args
{
  my($self, %args) = @_;
  
  if($args{DISTNAME})
  {
    $self->build->set_stage(Path::Tiny->new("blib/lib/auto/share/dist/$args{DISTNAME}")->absolute->stringify);
    $self->build->install_prop->{mm}->{distname} = $args{DISTNAME};
  }
  else
  {
    Carp::croak "DISTNAME is required";
  }
  
  my $ab_version = '0.14';
  
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
  elsif($self->build->install_type eq 'share')
  {
    $args{BUILD_REQUIRES} = Alien::Build::_merge(
      'Alien::Build::MM' => $ab_version,
      %{ $args{BUILD_REQUIRES} || {} },
      %{ $self->build->requires('share') || {} },
    );
  }
  else
  {
    die "unknown install type: @{[ $self->build->install_type ]}"
  }
  
  $args{PREREQ_PM} = Alien::Build::_merge(
    'Alien::Build' => $ab_version,
    %{ $args{PREREQ_PM} || {} },
  );
 
  #$args{META_MERGE}->{'meta-spec'}->{version} = 2;
  $args{META_MERGE}->{dynamic_config} = 1;
  
  $self->build->checkpoint;
  %args;
}

=head2 mm_postamble

 my %args = $abmm->mm_args(%args);

Returns the postamble for the C<Makefile> needed for L<Alien::Build>.
This adds the following C<make> targets which are normally called when
you run C<make all>, but can be run individually if needed for debugging.

=over 4

=item alien_prefix

Determines the final install prefix (C<%{alien.install.prefix}>).

=item alien_download

Downloads the source from the internet.  Does nothing for a system install.

=item alien_build

Build from source (if a share install).  Gather configuration (for either
system or share install).

=back 

=cut

sub mm_postamble
{
  my($self) = @_;
  
  my $postamble = '';
  
  # remove the _alien directory on a make realclean:
  $postamble .= "realclean :: alien_realclean\n" .
                "\n" .
                "alien_realclean:\n" .
                "\t\$(RM_RF) _alien\n\n";

  my $dirs = $self->build->meta_prop->{arch}
    ? '$(INSTALLARCHLIB) $(INSTALLSITEARCH) $(INSTALLVENDORARCH)'
    : '$(INSTALLPRIVLIB) $(INSTALLSITELIB) $(INSTALLVENDORLIB)'
  ;

  # set prefix
  $postamble .= "alien_prefix : _alien/mm/prefix\n\n" .
                "_alien/mm/prefix :\n" .
                "\t\$(FULLPERL) -MAlien::Build::MM=cmd -e prefix \$(INSTALLDIRS) $dirs\n\n";

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
        my $build = Alien::Build->resume('alienfile', '_alien');
        $build->load_requires('configure');
        $build->load_requires($build->install_type);
        ($build, @ARGV)
      };
      
      *_touch = sub {
        my($name) = @_;
        require Path::Tiny;
        my $path = Path::Tiny->new("_alien/mm/$name");
        $path->parent->mkpath;
        $path->touch;
      };
      
      *prefix = sub
      {
        my($build, $type, $perl, $site, $vendor) = _args();

        my $distname = $build->install_prop->{mm}->{distname};

        my $prefix = $type eq 'perl'
          ? $perl
          : $type eq 'site'
            ? $site
            : $type eq 'vendor'
              ? $vendor
              : die "unknown INSTALLDIRS ($type)";
        $prefix = Path::Tiny->new($prefix)->child("auto/share/dist/$distname")->absolute->stringify;

        $build->log("prefix $prefix");
        $build->set_prefix($prefix);
        $build->checkpoint;
        _touch('prefix');
      };
      
      *download = sub
      {
        my($build) = _args();
        $build->download;
        $build->checkpoint;
       _touch('download');
      };
      
      *build = sub
      {
        my($build) = _args();
        
        $build->build;

        if($build->meta_prop->{arch})
        {
          my $distname = $build->install_prop->{mm}->{distname};
          my $archdir = Path::Tiny->new("blib/arch/auto/@{[ join '/', split /-/, $distname ]}");
          $archdir->mkpath;
          my $archfile = $archdir->child($archdir->basename . '.txt');
          $archfile->spew('Alien based distribution with architecture specific file in share');
        }
        
        $build->checkpoint;
        _touch('build');
      };
    }
  }
}

1;

=head1 SEE ALSO

L<Alien::Build>, L<Alien::Base>, L<Alien>

=cut
