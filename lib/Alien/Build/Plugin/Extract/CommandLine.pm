package Alien::Build::Plugin::Extract::CommandLine;

use strict;
use warnings;
use Alien::Build::Plugin;
use Path::Tiny ();
use File::Which ();

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
  File::Which::which('gzip') ? 'gzip' : undef;
};

=head2 bzip2_cmd

The C<bzip2> command, if available.  C<undef> if not available.

=cut

# TODO: use Alien::Libbz2 if available
has bzip2_cmd => sub {
  File::Which::which('bzip2') ? 'bzip2' : undef;
};

=head2 xz_cmd

The C<xz> command, if available.  C<undef> if not available.

=cut

# TODO: use Alien::xz if available
has xz_cmd => sub {
  File::Which::which('xz') ? 'xz' : undef;
};

=head2 tar_cmd

The C<tar> command, if available.  C<undef> if not available.

=cut

has tar_cmd => sub {
  File::Which::which('bsdtar')
    ? 'bsdtar'
    # TODO: GNU tar can be iffy on windows, where absolute
    # paths get confused with remote tars.  *sigh* fix later
    # if we can, for now just assume that 'tar.exe' is borked
    # on windows to be on the safe side.  The Fetch::ArchiveTar
    # is probably a better plugin to use on windows anyway.
    : File::Which::which('tar') && $^O ne 'MSWin32'
      ? 'tar'
      : undef;
};

=head2 unzip_cmd

The C<unzip> command, if available.  C<undef> if not available.

=cut

has unzip_cmd => sub {
  File::Which::which('unzip') ? 'unzip' : undef;
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
          $self->_cp($build, $src, $src_tmp);
          $self->_run($build, $dcon_cmd, "-d", $src_tmp);
          $self->_mv($build, $dcon_tmp, $dcon_name);
        }
        $src = $dcon_name;
      }
      
      if($src =~ /\.tar$/i)
      {
        $self->_run($build, $self->tar_cmd, 'xf', $src);
      }
      elsif($src =~ /\.zip$/i)
      {
        $self->_run($build, $self->unzip_cmd, $src);
      }
      else
      {
        die "not sure of archive type from extension";
      }
    }
  );
}

1;

=head1 SEE ALSO

L<Alien::Build::Plugin::Extract::Negotiate>, L<Alien::Build>, L<alienfile>, L<Alien::Build::MM>, L<Alien>

=cut
