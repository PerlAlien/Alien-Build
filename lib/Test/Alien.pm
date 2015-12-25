package Test::Alien;

use strict;
use warnings;
use 5.008001;
use Env qw( @PATH );
use File::Which 1.10 qw( which );
use Capture::Tiny qw( capture capture_merged );
use File::Temp qw( tempdir );
use File::Spec;
use Text::ParseWords qw( shellwords );
use Test::Stream::Context qw( context );
use Test::Stream::Exporter;
default_exports qw( alien_ok run_ok xs_ok );
no Test::Stream::Exporter;

# ABSTRACT: Testing tools for Alien modules
# VERSION

=head1 FUNCTIONS

=head2 alien_ok

 alien_ok $alien, $message;
 alien_ok $alien;

Load the given L<Alien> instance or class.  Checks that the instance or class conforms to the same
interface as L<Alien::Base>.  Will be used by subsequent tests.

=cut

our @aliens;

sub alien_ok ($;$)
{
  my($alien, $message) = @_;

  my $name = ref $alien ? ref($alien) . '[instance]' : $alien;
  
  my @methods = qw( dist_dir cflags libs install_type config dynamic_libs bin_dir alien_helper );
  $message ||= "$name responds to: @methods";
  my @missing = grep { ! $alien->can($_) } @methods;
  
  my $ok = !@missing;
  my $ctx = context();
  $ctx->ok($ok, $message);
  $ctx->diag("  missing method $_") for @missing;
  $ctx->release;
  
  if($ok)
  {
    push @aliens, $alien;
    unshift @PATH, $alien->bin_dir;
  }
  
  $ok;
}

=head2 run_ok

 my $run = run_ok $command;
 my $run = run_ok $command, $message;

Runs the given command, falling back on any C<Alien::Base#bin_dir> methods provided by L<Alien> modules
specified with L</alien_ok>.

C<$command> can be either a string or an array reference.

Only fails if the command cannot be found, or if it is killed by a signal!  Returns a L<Test::Alien::Run>
object, which you can use to test the exit status, output and standard error.

Always returns an instance of L<Test::Alien::Run>, even if the command could not be found.

=cut

sub run_ok
{
  my($command, $message) = @_;
  
  my(@command) = ref $command ? @$command : ($command);
  $message ||= "run @command";
  
  require Test::Alien::Run;
  my $run = bless {
    out    => '',
    err    => '',
    exit   => 0,
    sig    => 0,
    cmd    => [@command],
  }, 'Test::Alien::Run';
  
  my $ctx = context();
  my $exe = which $command[0];
  if(defined $exe)
  {
    shift @command;
    $run->{cmd} = [$exe, @command];
    my @diag;
    my $ok = 1;
    my($exit, $errno);
    ($run->{out}, $run->{err}, $exit, $errno) = capture { system $exe, @command; ($?,$!); };
  
    if($exit == -1)
    {
      $ok = 0;
      $run->{fail} = "failed to execute: $errno";
      push @diag, "  failed to execute: $errno";
    }
    elsif($exit & 127)
    {
      $ok = 0;
      push @diag, "  killed with signal: @{[ $exit & 127 ]}";
      $run->{sig} = $exit & 127;
    }
    else
    {
      $run->{exit} = $exit >> 8;
    }

    $ctx->ok($ok, $message);
    $ok 
      ? $ctx->note("  using $exe") 
      : $ctx->diag("  using $exe");
    $ctx->diag(@diag) for @diag;

  }
  else
  {
    $ctx->ok(0, $message);
    $ctx->diag("  command not found");
    $run->{fail} = 'command not found';
  }
  
  $ctx->release;
  
  $run;
}

=head2 xs_ok

 xs_ok $xs;
 xs_ok $xs, $message;

Compiles, links the given C<XS> code and attaches to Perl.

C<$xs> may be either a string containing the C<XS> code,
or a hash reference with these keys:

=over 4

=item xs

The XS code.  This is the only required element.

=item pxs

The L<ExtUtils::ParseXS> arguments passes as a hash reference.

=item verbose

Spew copious debug information via test note.

=cut

sub xs_ok
{
  my($xs, $message) = @_;
  $message ||= 'xs';
  
  $xs = { xs => $xs } unless ref $xs;
  $xs->{pxs} ||= {};
  my $verbose = $xs->{verbose};
  my $ok = 1;
  my @diag;
  my $dir = tempdir( CLEANUP => 1 );
  my $xs_filename = File::Spec->catfile($dir, 'test.xs');
  my $c_filename  = File::Spec->catfile($dir, 'test.c');
  
  my $ctx = context();
  my $module;

  # this regex copied shamefully from ExtUtils::ParseXS
  # in part because we need the module name to do the bootstrap
  # and also because if this regex doesn't match then ParseXS
  # does an exit() which we don't want.
  if($xs->{xs} =~ /^MODULE\s*=\s*([\w:])+(?:\s+PACKAGE\s*=\s*([\w:]+))?(?:\s+PREFIX\s*=\s*(\S+))?\s*$/m)
  {
    $module = $1;
  }
  else
  {
    $ok = 0;
    push @diag, '  XS does not have a module decleration that we could find';
  }

  if($ok)
  {
    open my $fh, '>', $xs_filename;
    print $fh $xs->{xs};
    close $fh;
  
    require ExtUtils::ParseXS;
    my $pxs = ExtUtils::ParseXS->new;
  
    my($out, $err) = capture_merged {
      eval {
        $pxs->process_file(
          filename     => $xs_filename,
          output       => $c_filename,
          versioncheck => 0,
          prototypes   => 0,
          %{ $xs->{pxs} },
        );
      };
      $@;
    };
    
    $ctx->note("parse xs $xs_filename => $c_filename") if $verbose;
    $ctx->note($out) if $verbose;
    $ctx->note("error: $err") if $verbose && $err;
  
    unless($pxs->report_error_count == 0)
    {
      $ok = 0;
      push @diag, '  ExtUtils::ParseXS failed:';
      push @diag, "    $err" if $err;
      push @diag, "    $_" for split /\r?\n/, $out;
    }
  }

  if($ok)
  {
    require ExtUtils::CBuilder;
    my $cb = ExtUtils::CBuilder->new;

    my($out, $obj, $err) = capture_merged {
      my $obj = eval {
        $cb->compile(
          source               => $c_filename,
          extra_compiler_flags => [shellwords map { $_->cflags } @aliens],
        );
      };
      ($obj, $@);
    };
    
    $ctx->note("compile $c_filename") if $verbose;
    $ctx->note($out) if $verbose;
    $ctx->note($err) if $verbose && $err;
    
    unless($obj)
    {
      $ok = 0;
      push @diag, '  ExtUtils::CBuilder->compile failed';
      push @diag, "    $err" if $err;
      push @diag, "    $_" for split /\r?\n/, $out;
    }
    
    if($ok)
    {
    
      my($out, $lib) = capture_merged {
        $cb->link(
          objects            => [$obj],
          extra_linker_flags => [shellwords map { $_->libs } @aliens],
        );
      };
      
      $ctx->note("link $obj") if $verbose;
      $ctx->note($out) if $verbose;
      
      if($lib)
      {
        $ctx->note("created lib $lib");
      }
      else
      {
        $ok = 0;
        push @diag, '  ExtUtils::CBuilder->link failed';
        push @diag, "    $_" for split /\r?\n/, $out;
      }
    
    }

  }

  $ctx->ok($ok, $message);
  $ctx->diag($_) for @diag;
  $ctx->release;
  
  $ok;
}

1;
