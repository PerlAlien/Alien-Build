package Alien::Build::Plugin::Core::Setup;

use strict;
use warnings;
use 5.008004;
use Alien::Build::Plugin;
use Config;
use File::Which qw( which );

# ABSTRACT: Core setup plugin
# VERSION

=head1 SYNOPSIS

 use alienfile;
 # already loaded

=head1 DESCRIPTION

This plugin does some core setup for you.

=head1 SEE ALSO

L<Alien::Build>, L<Alien::Base::ModuleBuild>

=cut

sub init
{
  my($self, $meta) = @_;
  $meta->prop->{platform} ||= {};
  $self->_platform($meta->prop->{platform});
}

sub _platform
{
  my(undef, $hash) = @_;

  if($^O eq 'MSWin32' && $Config{ccname} eq 'cl')
  {
    $hash->{compiler_type} = 'microsoft';
  }
  else
  {
    $hash->{compiler_type} = 'unix';
  }

  if($^O eq 'MSWin32')
  {
    $hash->{system_type} = 'windows-unknown';

    if(defined &Win32::BuildNumber)
    {
      $hash->{system_type} = 'windows-activestate';
    }
    elsif($Config{myuname} =~ /strawberry-perl/)
    {
      $hash->{system_type} = 'windows-strawberry';
    }
    elsif($hash->{compiler_type} eq 'microsoft')
    {
      $hash->{system_type} = 'windows-microsoft';
    }
    else
    {
      my $uname_exe = which('uname');
      if($uname_exe)
      {
        my $uname = `$uname_exe`;
        if($uname =~ /^(MINGW)(32|64)_NT/)
        {
          $hash->{system_type} = 'windows-' . lc $1;
        }
      }
    }
  }
  elsif($^O =~ /^(VMS)$/)
  {
    # others probably belong in here...
    $hash->{system_type} = lc $^O;
  }
  else
  {
    $hash->{system_type} = 'unix';
  }

  $hash->{cpu}{count} =
    exists $ENV{ALIEN_CPU_COUNT} && $ENV{ALIEN_CPU_COUNT} > 0
    ? $ENV{ALIEN_CPU_COUNT}
    : _cpu_count();
}

# Retrieve number of available CPU cores. Adopted from
# <https://metacpan.org/release/MARIOROY/MCE-1.879/source/lib/MCE/Util.pm#L49>
# which is in turn adopted from Test::Smoke::Util with improvements.
sub _cpu_count {
  local $ENV{PATH} = $ENV{PATH};
  if( $^O ne 'MSWin32' ) {
    $ENV{PATH} = "/usr/sbin:/sbin:/usr/bin:/bin:$ENV{PATH}";
  }
  $ENV{PATH} =~ /(.*)/; $ENV{PATH} = $1;   ## Remove tainted'ness

  my $ncpu = 1;

  OS_CHECK: {
    local $_ = lc $^O;

    /linux/ && do {
      my ( $count, $fh );
      if ( open $fh, '<', '/proc/stat' ) {
        $count = grep { /^cpu\d/ } <$fh>;
        close $fh;
      }
      $ncpu = $count if $count;
      last OS_CHECK;
    };

    /bsd|darwin|dragonfly/ && do {
      chomp( my @output = `sysctl -n hw.ncpu 2>/dev/null` );
      $ncpu = $output[0] if @output;
      last OS_CHECK;
    };

    /aix/ && do {
      my @output = `lparstat -i 2>/dev/null | grep "^Online Virtual CPUs"`;
      if ( @output ) {
        $output[0] =~ /(\d+)\n$/;
        $ncpu = $1 if $1;
      }
      if ( !$ncpu ) {
        @output = `pmcycles -m 2>/dev/null`;
        if ( @output ) {
          $ncpu = scalar @output;
        } else {
          @output = `lsdev -Cc processor -S Available 2>/dev/null`;
          $ncpu = scalar @output if @output;
        }
      }
      last OS_CHECK;
    };

    /gnu/ && do {
      chomp( my @output = `nproc 2>/dev/null` );
      $ncpu = $output[0] if @output;
      last OS_CHECK;
    };

    /haiku/ && do {
      my @output = `sysinfo -cpu 2>/dev/null | grep "^CPU #"`;
      $ncpu = scalar @output if @output;
      last OS_CHECK;
    };

    /hp-?ux/ && do {
      my $count = grep { /^processor/ } `ioscan -fkC processor 2>/dev/null`;
      $ncpu = $count if $count;
      last OS_CHECK;
    };

    /irix/ && do {
      my @out = grep { /\s+processors?$/i } `hinv -c processor 2>/dev/null`;
      $ncpu = (split ' ', $out[0])[0] if @out;
      last OS_CHECK;
    };

    /osf|solaris|sunos|svr5|sco/ && do {
      if (-x '/usr/sbin/psrinfo') {
        my $count = grep { /on-?line/ } `psrinfo 2>/dev/null`;
        $ncpu = $count if $count;
      }
      else {
        my @output = grep { /^NumCPU = \d+/ } `uname -X 2>/dev/null`;
        $ncpu = (split ' ', $output[0])[2] if @output;
      }
      last OS_CHECK;
    };

    /mswin|mingw|msys|cygwin/ && do {
      if (exists $ENV{NUMBER_OF_PROCESSORS}) {
        $ncpu = $ENV{NUMBER_OF_PROCESSORS};
      }
      last OS_CHECK;
    };

    warn "CPU count: unknown operating system";
  }

  $ncpu = 1 if (!$ncpu || $ncpu < 1);

  $ncpu;
}

1;
