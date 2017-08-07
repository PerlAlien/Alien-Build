package Alien::Build::Plugin::Extract::CommandLine;

use strict;
use warnings;
use Alien::Build::Plugin;
use Path::Tiny ();
use File::Which ();
use File::chdir;
use File::Temp qw( tempdir );
use Capture::Tiny qw( capture_merged );

# ABSTRACT: Plugin to extract an archive using command line tools
# VERSION

=head1 SYNOPSIS

 use alienfile;
 plugin 'Extract::CommandLine' => (
   format => 'tar.gz',
 );

=head1 DESCRIPTION

Note: in most case you will want to use L<Alien::Build::Plugin::Extract::Negotiate>
instead.  It picks the appropriate Extract plugin based on your platform and environment.
In some cases you may need to use this plugin directly instead.

This plugin extracts from an archive in various formats using command line tools.

=head1 PROPERTIES

=head2 format

Gives a hint as to the expected format.

=cut

has '+format' => 'tar';

=head2 gzip_cmd

The C<gzip> command, if available.  C<undef> if not available.

=cut

has gzip_cmd => sub {
  _which('gzip') ? 'gzip' : undef;
};

=head2 bzip2_cmd

The C<bzip2> command, if available.  C<undef> if not available.

=cut

sub _which { File::Which::which(@_) }

has bzip2_cmd => sub {
  _which('bzip2') ? 'bzip2' : undef;
};

=head2 xz_cmd

The C<xz> command, if available.  C<undef> if not available.

=cut

has xz_cmd => sub {
  _which('xz') ? 'xz' : undef;
};

=head2 tar_cmd

The C<tar> command, if available.  C<undef> if not available.

=cut

has tar_cmd => sub {
  _which('bsdtar')
    ? 'bsdtar'
    # TODO: GNU tar can be iffy on windows, where absolute
    # paths get confused with remote tars.  *sigh* fix later
    # if we can, for now just assume that 'tar.exe' is borked
    # on windows to be on the safe side.  The Fetch::ArchiveTar
    # is probably a better plugin to use on windows anyway.
    : _which('tar') && $^O ne 'MSWin32'
      ? 'tar'
      : _which('ptar')
        ? 'ptar'
        : undef;
};

=head2 unzip_cmd

The C<unzip> command, if available.  C<undef> if not available.

=cut

has unzip_cmd => sub {
  _which('unzip') ? 'unzip' : undef;
};

sub _run
{
  my(undef, $build, @cmd) = @_;
  $build->log("+ @cmd");
  system @cmd;
  die "execute failed" if $?;
}

sub _cp
{
  my(undef, $build, $from, $to) = @_;
  require File::Copy;
  $build->log("copy $from => $to");
  File::Copy::cp($from, $to) || die "unable to copy: $!";
}

sub _mv
{
  my(undef, $build, $from, $to) = @_;
  $build->log("move $from => $to");
  rename($from, $to) || die "unable to rename: $!";
}

sub _dcon
{
  my($self, $src) = @_;

  my $name;
  my $cmd;

  if($src =~ /\.(gz|tgz|Z|taz)$/)
  {
    $self->gzip_cmd(_which('gzip')) unless defined $self->gzip_cmd;
    if($src =~ /\.(gz|tgz)$/)
    {
      $cmd = $self->gzip_cmd unless $self->_tar_can('tar.gz');
    }
    elsif($src =~ /\.(Z|taz)$/)
    {
      $cmd = $self->gzip_cmd unless $self->_tar_can('tar.Z');
    }
  }
  elsif($src =~ /\.(bz2|tbz)$/)
  {
    $self->bzip2_cmd(_which('bzip2')) unless defined $self->bzip2_cmd;
    $cmd = $self->bzip2_cmd unless $self->_tar_can('tar.bz2');
  }
  elsif($src =~ /\.(xz|txz)$/)
  {
    $self->xz_cmd(_which('xz')) unless defined $self->xz_cmd;
    $cmd = $self->xz_cmd unless $self->_tar_can('tar.xz');
  }
  
  if($cmd && $src =~ /\.(gz|bz2|xz|Z)$/)
  {
    $name = $src;
    $name =~ s/\.(gz|bz2|xz|Z)$//g;
  }
  elsif($cmd && $src =~ /\.(tgz|tbz|txz|taz)$/)
  {
    $name = $src;
    $name =~ s/\.(tgz|tbz|txz|taz)$/.tar/;
  }
  
  ($name,$cmd);
}

=head1 METHODS

=head2 handles

 Alien::Build::Plugin::Extract::CommandLine->handles($ext);
 $plugin->handles($ext);

Returns true if the plugin is able to handle the archive of the
given format.

=cut

sub handles
{
  my($class, $ext) = @_;
  
  my $self = ref $class
  ? $class
  : __PACKAGE__->new;

  $ext = 'tar.Z'   if $ext eq 'taz';
  $ext = 'tar.gz'  if $ext eq 'tgz';
  $ext = 'tar.bz2' if $ext eq 'tbz';
  $ext = 'tar.xz'  if $ext eq 'txz';

  return 1 if $ext eq 'tar.gz' && $self->_tar_can('tar.gz');
  return 1 if $ext eq 'tar.Z' && $self->_tar_can('tar.Z');
  return 1 if $ext eq 'tar.bz2' && $self->_tar_can('tar.bz2');
  return 1 if $ext eq 'tar.xz' && $self->_tar_can('tar.xz');
  
  return if $ext =~ s/\.(gz|Z)$// && (!$self->gzip_cmd);
  return if $ext =~ s/\.bz2$//    && (!$self->bzip2_cmd);
  return if $ext =~ s/\.xz$//     && (!$self->xz_cmd);
  
  return 1 if $ext eq 'tar' && $self->tar_cmd;
  return 1 if $ext eq 'zip' && $self->unzip_cmd;
  
  return;
}

sub init
{
  my($self, $meta) = @_;
  
  if($self->format eq 'tar.xz' && !$self->handles('tar.xz'))
  {
    $meta->add_requires('share' => 'Alien::xz' => '0.06');
  }
  elsif($self->format eq 'tar.bz2' && !$self->handles('tar.bz2'))
  {
    $meta->add_requires('share' => 'Alien::Libbz2' => '0.22');
  }
  elsif($self->format =~ /^tar\.(gz|Z)$/ && !$self->handles($self->format))
  {
    $meta->add_requires('share' => 'Alien::gzip' => '0.03');
  }
  
  $meta->register_hook(
    extract => sub {
      my($build, $src) = @_;
      
      my($dcon_name, $dcon_cmd) = _dcon($self, $src);
      
      if($dcon_name)
      {
        unless($dcon_cmd)
        {
          die "unable to decompress $src";
        }
        # if we have already decompressed, then keep it.
        unless(-f $dcon_name)
        {
          # we don't use pipes, because that may not work on Windows.
          # keep the original archive, in case another extract
          # plugin needs it.  keep the decompressed archive
          # in case WE need it again.
          my $src_tmp = Path::Tiny::path($src)
            ->parent
            ->child('x'.Path::Tiny::path($src)->basename);
          my $dcon_tmp = Path::Tiny::path($dcon_name)
            ->parent
            ->child('x'.Path::Tiny::path($dcon_name)->basename);
          $self->_cp($build, $src, $src_tmp);
          $self->_run($build, $dcon_cmd, "-d", $src_tmp);
          $self->_mv($build, $dcon_tmp, $dcon_name);
        }
        $src = $dcon_name;
      }
      
      if($src =~ /\.zip$/i)
      {
        $self->_run($build, $self->unzip_cmd, $src);
      }
      elsif($src =~ /\.tar/ || $src =~ /(\.tgz|\.tbz|\.txz|\.taz)$/i)
      {
        $self->_run($build, $self->tar_cmd, '-xf', $src);
      }
      else
      {
        die "not sure of archive type from extension";
      }
    }
  );
}

my %tars;

sub _tar_can
{
  my($self, $ext) = @_;

  my $tar = $self->tar_cmd;

  return 1 if $ext eq 'tar';
  
  unless(%tars)
  {
    my $name = '';
    while(<DATA>)
    {
      if(/^\[ (.*) \]$/)
      {
        $name = $1;
      }
      else
      {
        $tars{$name} .= $_;
      }
    }
    
    foreach my $key (keys %tars)
    {
      $tars{$key} = unpack "u", $tars{$key};
    }
  }

  my $name = "xx.$ext";

  return 0 unless $tars{$name};

  local $CWD = tempdir( CLEANUP => 1 );
  
  my $cleanup = sub {
    my $save = $CWD;
    unlink $name;
    unlink 'xx.txt';
    $CWD = '..';
    rmdir $save;
  };
  
  Path::Tiny->new($name)->spew_raw($tars{$name});

  my(undef, $exit) = capture_merged {
    system($self->tar_cmd, 'xf', $name);
    $?;
  };
  
  if($exit)
  {
    $cleanup->();
    return 0;
  }
  
  my $content = eval { Path::Tiny->new('xx.txt')->slurp };
  $cleanup->();
  
  return defined $content && $content eq "xx\n";
}

1;

=head1 SEE ALSO

L<Alien::Build::Plugin::Extract::Negotiate>, L<Alien::Build>, L<alienfile>, L<Alien::Build::MM>, L<Alien>

=cut

__DATA__
[ xx.tar.xz ]
M_3=Z6%H```3FUK1&`@`A`18```!T+^6CX`?_`&!=`#Q@M.AX.4O&N38V648.
M[J6L\\<_[3M*R;CASOTX?P=AC_+TG]8[KH(8/FH'K8A88=^>]Y`\*#,F=7,6
MMB.:40OP*L85<<5!.@M$*(&TH(*TAWN"E)(+1>_I$^W5V^4=``!FY,=\7,&)
9IP`!?(`0````:OY*7K'$9_L"``````196@``

[ xx.tar.bz2 ]
M0EIH.3%!62936=+(]$0``$A[D-$0`8!``7^``!!AI)Y`!```""``=!JGIH-(
MT#0]0/2!**---&F@;4#0&:D;X?(6@JH(2<%'N$%3VHC-9E>S/N@"6&I*1@GN
JNHCC2>$I5(<0BKR.=XBZ""HVZ;T,CV\LJ!K&*?9`#\7<D4X4)#2R/1$`

[ xx.tar.gz ]
M'XL(`(;*<%D``ZNHT"NI*&&@*3`P,#`S,5$`T>9FIF#:P`C"AP)C!4-C0V,3
M0Q-30W-S!0-#(W-#0P8%`]HZ"P)*BTL2BX!.R<_)R2Q.QZT.J"PM#8\Y$(\H
>P.DA`BHJN`;:":-@%(R"43`*!@```)9R\&H`"```

[ xx.tar.Z]
M'YV0>/"XH(.'#H"#"!,J7,BPH<.'$"-*1`BCH@T:-$``J`CCAHT:&CG"D)%Q
MH\B3,T#$F+&21@P:-6+<N`$"1@P9-V+$`%!SHL^?0(,*!5!G#ITP<DR^8<,F
MS9PS0Q<:#6/&3-2%)V&$/*GQJM>O8,.*'1I0P=BS:-.J7<NVK=NW<./*G4NW
7KMV[>//JW<NWK]^_@`,+'DRXL.'#0P$`

