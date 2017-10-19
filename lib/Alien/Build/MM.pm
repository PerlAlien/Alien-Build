package Alien::Build::MM;

use strict;
use warnings;
use Alien::Build;
use Path::Tiny ();
use Capture::Tiny qw( capture );
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
   DISTNAME     => 'Alien-Libfoo',
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
  my($class, %prop) = @_;

  my $self = bless {}, $class;

  my %meta = map { $_ => $prop{$_} } grep /^my_/, keys %prop;

  my $build = $self->{build} =
    Alien::Build->load('alienfile',
      root     => "_alien",
      (-d 'patch' ? (patch => 'patch') : ()),
      meta_prop => \%meta,
    )
  ;

  if(%meta)
  {
    $build->meta->add_requires(configure => 'Alien::Build::MM' => '1.20');
    $build->meta->add_requires(configure => 'Alien::Build' => '1.20');
  }

  if(defined $prop{alienfile_meta})
  {
    $self->{alienfile_meta} = $prop{alienfile_meta};
  }
  else
  {
    $self->{alienfile_meta} = 1;
  }

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

=head2 alienfile_meta

 my $bool = $abmm->alienfile_meta

Set to a false value, in order to turn off the x_alienfile meta

=cut

sub alienfile_meta
{
  shift->{alienfile_meta};
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
    my $module = $args{DISTNAME};
    $module =~ s/-/::/g;
    # See if there is an existing version installed, without pulling it into this process
    my($old_prefix, $err, $ret) = capture { system $^X, "-M$module", -e => "print $module->dist_dir"; $? };
    if($ret == 0)
    {
      chomp $old_prefix;
      my $file = Path::Tiny->new($old_prefix, qw( _alien alien.json ));
      if(-r $file)
      {
        my $old_runtime = eval {
          require JSON::PP;
          JSON::PP::decode_json($file->slurp);
        };
        unless($@)
        {
          $self->build->install_prop->{old}->{runtime} = $old_runtime;
          $self->build->install_prop->{old}->{preifx}  = $old_prefix;
        }
      }
    }
  }
  else
  {
    Carp::croak "DISTNAME is required";
  }

  my $ab_version = '0.25';

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

  if($self->alienfile_meta)
  {
    $args{META_MERGE}->{x_alienfile} = {
      generated_by => "@{[ __PACKAGE__ ]} version @{[ __PACKAGE__->VERSION || 'dev' ]}",
      requires => {
        map {
          my %reqs = %{ $self->build->requires($_) };
          $reqs{$_} = "$reqs{$_}" for keys %reqs;
          $_ => \%reqs;
        } qw( share system )
      },
    };
  }

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

Determines the final install prefix (C<%{.install.prefix}>).

=item alien_version

Determine the perl_module_version (C<%{.runtime.perl_module_version}>)

=item alien_download

Downloads the source from the internet.  Does nothing for a system install.

=item alien_build

Build from source (if a share install).  Gather configuration (for either
system or share install).

=item alien_prop

Prints the meta, install and runtime properties for the Alien.

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

  # set verson
  $postamble .= "alien_version : _alien/mm/version\n\n" .
                "_alien/mm/version : _alien/mm/prefix\n" .
                "\t\$(FULLPERL) -MAlien::Build::MM=cmd -e version \$(VERSION)\n\n";

  # download
  $postamble .= "alien_download : _alien/mm/download\n\n" .
                "_alien/mm/download : _alien/mm/prefix _alien/mm/version\n" .
                "\t\$(FULLPERL) -MAlien::Build::MM=cmd -e download\n\n";

  # build
  $postamble .= "alien_build : _alien/mm/build\n\n" .
                "_alien/mm/build : _alien/mm/download\n" .
                "\t\$(FULLPERL) -MAlien::Build::MM=cmd -e build\n\n";

  # append to all
  $postamble .= "pure_all :: _alien/mm/build\n\n";

  $postamble .= "subdirs-test_dynamic :: alien_test\n\n";
  $postamble .= "alien_test :\n" .
                "\t\$(FULLPERL) -MAlien::Build::MM=cmd -e test\n\n";

  # prop
  $postamble .= "alien_prop :\n" .
                "\t\$(FULLPERL) -MAlien::Build::MM=cmd -e dumpprop\n\n";
  $postamble .= "alien_prop_meta :\n" .
                "\t\$(FULLPERL) -MAlien::Build::MM=cmd -e dumpprop meta\n\n";
  $postamble .= "alien_prop_install :\n" .
                "\t\$(FULLPERL) -MAlien::Build::MM=cmd -e dumpprop install\n\n";
  $postamble .= "alien_prop_runtime :\n" .
                "\t\$(FULLPERL) -MAlien::Build::MM=cmd -e dumpprop install\n\n";

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

      *version = sub
      {
        my($build, $version) = _args();

        $build->runtime_prop->{perl_module_version} = $version;
        $build->checkpoint;
        _touch('version');
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

        my $distname = $build->install_prop->{mm}->{distname};

        if($build->meta_prop->{arch})
        {
          my $archdir = Path::Tiny->new("blib/arch/auto/@{[ join '/', split /-/, $distname ]}");
          $archdir->mkpath;
          my $archfile = $archdir->child($archdir->basename . '.txt');
          $archfile->spew('Alien based distribution with architecture specific file in share');
        }

        my $cflags = $build->runtime_prop->{cflags};
        my $libs   = $build->runtime_prop->{libs};

        if(($cflags && $cflags !~ /^\s*$/)
        || ($libs   && $libs   !~ /^\s*$/))
        {
          my $mod = join '::', split /-/, $distname;
          my $install_files_pm = Path::Tiny->new("blib/lib/@{[ join '/', split /-/, $distname ]}/Install/Files.pm");
          $install_files_pm->parent->mkpath;
          $install_files_pm->spew(
            "package ${mod}::Install::Files;\n",
            "require ${mod};\n",
            "sub Inline { shift; ${mod}->Inline(\@_) }\n",
            "1;\n",
            "\n",
            "=begin Pod::Coverage\n",
            "\n",
            "  Inline\n",
            "\n",
            "=cut\n",
          );
        }

        $build->checkpoint;
        _touch('build');
      };

      *test = sub
      {
        my($build) = _args();
        $build->test;
        $build->checkpoint;
      };

      *dumpprop = sub
      {
        my($build, $type) = _args();

        my %h = (
          meta    => $build->meta_prop,
          install => $build->install_prop,
          runtime => $build->runtime_prop,
        );

        require Alien::Build::Util;
        print Alien::Build::Util::_dump($type ? $h{$type} : \%h);
      }
    }
  }
}

1;

=head1 SEE ALSO

L<Alien::Build>, L<Alien::Base>, L<Alien>

=cut
