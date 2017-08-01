package Test::Alien::Build;

use strict;
use warnings;
use 5.008001;
use base qw( Exporter);
use Path::Tiny qw( path );
use Carp qw( croak );
use File::Temp qw( tempdir );
use Test2::API qw( context );
use Capture::Tiny qw( capture_merged );
use Alien::Build::Util qw( _mirror );

our @EXPORT = qw( alienfile alienfile_ok alien_build_ok alien_install_type_is );

# ABSTRACT: Tools for testing Alien::Build + alienfile
# VERSION

=head1 SYNOPSIS

 use Test2::V0;
 use Test::Alien::Build;
 
 # returns an instance of Alien::Build.
 my $build = alienfile_ok q{
   use alienfile;
   
   plugin 'My::Plugin' => (
     foo => 1,
     bar => 'string',
     ...
   );
 };
 
 alien_build_ok 'builds okay.';
 
 done_testing;

=head1 DESCRIPTION

This module provides some tools for testing L<Alien::Build> and L<alienfile>.  Outside of L<Alien::Build>
core development, It is probably most useful for L<Alien::Build::Plugin> developers.

This module also unsets a number of L<Alien::Build> specific environment variables, in order to make tests
reproducible even when overrides are set in different environments.  So if you want to test those variables in
various states you should explicitly set them in your test script.  These variables are unset if they defined:
C<ALIEN_BUILD_PRELOAD> C<ALIEN_BUILD_POSTLOAD> C<ALIEN_INSTALL_TYPE>.

=head1 FUNCTIONS

=head2 alienfile

 my $build = alienfile;
 my $build = alienfile q{ use alienfile ... };
 my $build = alienfile filename => 'alienfile';

Create a Alien::Build instance from the given L<alienfile>.  The first two forms are abbreviations.

 my $build = alienfile;
 # is the same as
 my $build = alienfile filename => 'alienfile';

and

 my $build = alienfile q{ use alienfile ... };
 # is the same as
 my $build = alienfile source => q{ use alienfile ... };

Except for the second abbreviated form sets the line number before feeding the source into L<Alien::Build>
so that you will get diagnostics with the correct line numbers.

=over 4

=item source

The source for the alienfile as a string.  You must specify one of C<source> or C<filename>.

=item filename

The filename for the alienfile.  You must specify one of C<source> or C<filename>.

=item root

The build root.

=item stage

The staging area for the build.

=item prefix

The install prefix for the build.

=back

=cut

my $build;

sub alienfile
{
  my($package, $filename, $line) = caller;
  ($package, $filename, $line) = caller(2) if $package eq __PACKAGE__;
  $filename = path($filename)->absolute;
  my %args = @_ == 0 ? (filename => 'alienfile') : @_ % 2 ? ( source => do { '# line '. $line . ' "' . path($filename)->absolute . qq("\n) . $_[0] }) : @_;

  my $get_temp_root = do{
    my $root; # may be undef;
    sub {
      $root ||= Path::Tiny->new(tempdir( CLEANUP => 1 ));
      
      if(@_)
      {
        my $path = $root->child(@_);
        $path->mkpath;
        $path;
      }
      else
      {
        return $root;
      }
    };
  };
  
  if($args{source})
  {
    my $file = $get_temp_root->()->child('alienfile');
    $file->spew($args{source});
    $args{filename} = $file->stringify;
  }
  else
  {
    unless(defined $args{filename})
    {
      croak "You must specify at least one of filename or source";
    }
    $args{filename} = path($args{filename})->absolute->stringify;
  }
  
  $args{stage}  ||= $get_temp_root->('stage')->stringify;
  $args{prefix} ||= $get_temp_root->('prefix')->stringify;
  $args{root}   ||= $get_temp_root->('root')->stringify;

  require Alien::Build;
  
  undef $build;
  my $out = capture_merged {
    $build = Alien::Build->load($args{filename}, root => $args{root});
    $build->set_stage($args{stage});
    $build->set_prefix($args{prefix});
  };

  my $ctx = context();
  $ctx->note($out) if $out;
  $ctx->release;
  
  $build
}

=head2 alienfile_ok

 my $build = alienfile_ok;
 my $build = alienfile_ok q{ use alienfile ... };
 my $build = alienfile_ok filename => 'alienfile';

Same as C<alienfile> above, except that it runs as a test, and will not throw an exception
on failure (it will return undef instead).

=cut

sub alienfile_ok
{
  my $build = eval { alienfile(@_) };
  my $error = $@;
  my $ok = !! $build;
  
  my $ctx = context();
  $ctx->ok($ok, 'alienfile compiles');
  $ctx->diag("error: $error") if $error;
  $ctx->release;
  
  $build;
}

=head2 alien_install_type_is

 alien_install_type_is $type;
 alien_install_type_is $type, $name;

Simple test to see if the install type is what you expect.
C<$type> should be one of C<system> or C<share>.

=cut

sub alien_install_type_is
{
  my($type, $name) = @_;

  croak "invalid install type" unless defined $type && $type =~ /^(system|share)$/;  
  $name ||= "alien install type is $type";
  
  my $ok = 0;
  my @diag;
  
  if($build)
  {
    my($out, $actual) = capture_merged {
      $build->load_requires('configure');
      $build->install_type;
    };
    if($type eq $actual)
    {
      $ok = 1;
    }
    else
    {
      push @diag, "expected install type of $type, but got $actual";
    }
  }
  else
  {
    push @diag, 'no alienfile'
  }
  
  my $ctx = context();
  $ctx->ok($ok, $name);
  $ctx->diag($_) for @diag;
  $ctx->release;

  $ok;
}

=head2 alien_build_ok

 my $alien = alien_build_ok;
 my $alien = alien_build_ok $name;
 my $alien = alien_build_ok { class => $class };
 my $alien = alien_build_ok { class => $class }, $name;

Runs the download and build stages.  Passes if the build succeeds.  Returns an instance
of L<Alien::Base> which can be passed into C<alien_ok> from L<Test::Alien>.  Returns
C<undef> if the test fails.

Options

=over 4

=item class

The base class to use for your alien.  This is L<Alien::Base> by default.  Should
be a subclass of L<Alien::Base>, or at least adhere to its API.

=back

=cut

my $count = 1;

sub alien_build_ok
{
  my $opt = defined $_[0] && ref($_[0]) eq 'HASH'
    ? shift : { class => 'Alien::Base' };

  my($name) = @_;

  $name ||= 'alien builds okay';
  my $ok;
  my @diag;
  my @note;
  my $alien;
  
  if($build)
  {
    my($out,$error) = capture_merged {
      eval {
        $build->load_requires('configure');
        $build->load_requires($build->install_type);
        $build->download;
        $build->build;
      };
      $@;
    };
    if($error)
    {
      $ok = 0;
      push @diag, $out if defined $out;
      push @diag, "build threw exception: $error";
    }
    else
    {
      $ok = 1;
      
      push @note, $out if defined $out;
      
      require Alien::Base;
      
      my $prefix = $build->runtime_prop->{prefix};
      my $stage  = $build->install_prop->{stage};
      my %prop   = %{ $build->runtime_prop };
      
      $prop{distdir} = $prefix;
      
      _mirror $stage, $prefix;
      
      my $dist_dir = sub {
        $prefix;
      };
      
      my $runtime_prop = sub {
        \%prop;
      };
      
      $alien = sprintf 'Test::Alien::Build::Faux%04d', $count++;
      {
        no strict 'refs';
        @{ "${alien}::ISA" }          = $opt->{class};
        *{ "${alien}::dist_dir" }     = $dist_dir;
        *{ "${alien}::runtime_prop" } = $runtime_prop;
      }
    }
  }
  else
  {
    $ok = 0;
    push @diag, 'no alienfile';
  }
  
  my $ctx = context();
  $ctx->ok($ok, $name);
  $ctx->diag($_) for @diag;
  $ctx->note($_) for @note;
  $ctx->release;
  
  $alien;
}

delete $ENV{$_} for qw( ALIEN_BUILD_PRELOAD ALIEN_BUILD_POSTLOAD ALIEN_INSTALL_TYPE );
$ENV{ALIEN_BUILD_RC} = '-';

1;

=head1 SEE ALSO

=over 4

=item L<Alien>

=item L<alienfile>

=item L<Alien::Build>

=item L<Test::Alien>

=back

=cut
