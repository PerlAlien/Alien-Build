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

our @EXPORT = qw( alienfile alienfile_ok );

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
  
  my $build;
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
