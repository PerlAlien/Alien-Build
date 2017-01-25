package Alien::Build::Plugin::Extract::CommandLine;

use strict;
use warnings;
use Alien::Build::Plugin;
use Path::Tiny ();
use IPC::Cmd ();

# ABSTRACT: Plugin to extract an archive using command line tools
# VERSION

has gzip_cmd => sub {
  IPC::Cmd::can_run('gzip') ? 'gzip' : undef;
};

# TODO: use Alien::Libbz2 if available
has bzip2_cmd => sub {
  IPC::Cmd::can_run('bzip2') ? 'bzip2' : undef;
};

# TODO: use Alien::xz if available
has xz_cmd => sub {
  IPC::Cmd::can_run('xz') ? 'xz' : undef;
};

has tar_cmd => sub {
  IPC::Cmd::can_run('bsdtar')
    ? 'bsdtar'
    : IPC::Cmd::can_run('tar')
      ? 'tar'
      : undef;
};

has unzip_cmd => sub {
  IPC::Cmd::can_run('unzip') ? 'unzip' : undef;
};

sub _run
{
  my(@cmd) = @_;
  print "+@cmd\n";
  system @cmd;
  die "execute failed" if $?;
}

sub _cp
{
  my($from, $to) = @_;
  require File::Copy;
  print "+cp $from $to\n";
  File::Copy::cp($from, $to) || die "unable to copy: $!";
}

sub _mv
{
  my($from, $to) = @_;
  print "+mv $from $to\n";
  rename($from, $to) || die "unable to rename: $!";
}

# Most modern tars can handle compressed archives on the
# fly, but until we have a way to probe for that (TODO)
# we will copy, decompress in a separate process.
sub _dcon
{
  my($self, $src) = @_;

  my $name;
  my $cmd;
  
  $cmd = $self->gzip_cmd if $src =~ /\.(gz|tgz|Z|taz)$/;
  $cmd = $self->bzip2_cmd if $src =~ /\.(bz2|tbz)$/;
  $cmd = $self->xz_cmd if $src =~ /\.(xz|txz)$/;
  
  if($src =~ /\.(gz|bz2|xz|Z)$/)
  {
    $name = $src;
    $name =~ s/\.(gz|bz2|xz|Z)$//g;
  }
  elsif($src =~ /\.(tgz|tbz|txz|taz)$/)
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
  
  return if $ext =~ s/\.(gz|Z)$// && !$self->gzip_cmd;
  return if $ext =~ s/\.bz2$// && !$self->bzip2_cmd;
  return if $ext =~ s/\.xz$// && !$self->xz_cmd;
  
  return 1 if $ext eq 'tar' && $self->tar_cmd;
  return 1 if $ext eq 'zip' && $self->unzip_cmd;
  
  return;
}

sub init
{
  my($self, $meta) = @_;
  
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
          _cp($src, $src_tmp);
          _run($dcon_cmd, "-d", $src_tmp);
          _mv($dcon_tmp, $dcon_name);
        }
        $src = $dcon_name;
      }
      
      if($src =~ /\.tar$/i)
      {
        _run $self->tar_cmd, 'xf', $src;
      }
      elsif($src =~ /\.zip$/i)
      {
        _run $self->unzip_cmd, $src;
      }
      else
      {
        die "not sure of archive type from extension";
      }
    }
  );
}

1;
