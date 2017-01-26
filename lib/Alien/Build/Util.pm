package Alien::Build::Util;

use strict;
use warnings;
use base qw( Exporter );
use Path::Tiny qw( path );

# ABSTRACT: Private utility functions for Alien::Build
# VERSION

=head1 DESCRIPTION

This module contains some private utility functions used internally by
L<Alien::Build>.  It shouldn't be used by any distribution other than
C<Alien-Build>.  That includes L<Alien::Build> plugins that are not
part of the L<Alien::Build> core.

You have been warned.  The functionality within may be removed at
any time!

=head1 SEE ALSO

L<Alien::Build>

=cut

our @EXPORT_OK = qw( _mirror _dump );

sub _mirror
{
  my($src_root, $dst_root, $opt) = @_;
  ($src_root, $dst_root) = map { path($_) } ($src_root, $dst_root);
  $opt ||= {};

  require File::Find;
  require File::Copy;
  
  File::Find::find({
    wanted => sub {
      my $src = path($File::Find::name)->relative($src_root);
      return if "$src" eq '.';
      my $dst = $dst_root->child("$src");
      $src = $src->absolute($src_root);
      if(-d "$src")
      {
        unless(-d $dst)
        {
          print "Alien::Build> mkdir $dst\n" if $opt->{verbose};
          mkdir($dst) || die "unable to create directory $dst: $!";
        }
      }
      elsif(-l "$src")
      {
        my $target = readlink "$src";
        print "Alien::Build> ln -s $target $dst\n" if $opt->{verbose};
        symlink($target, $dst) || die "unable to symlink $target => $dst";
      }
      elsif(-f "$src")
      {
        print "Alien::Build> cp $src $dst\n" if $opt->{verbose};
        File::Copy::cp("$src", "$dst") || die "copy error $src => $dst: $!";
        if($] < 5.012 && -x "$src" && $^O ne 'MSWin32')
        {
          # apparently Perl 5.8 and 5.10 do not preserver perms
          my $mode = [stat "$src"]->[2] & 0777;
          eval { chmod $mode, "$dst" };
        }
      }
    },
    no_chdir => 1,
  }, "$src_root");
    
}

sub _dump
{
  if(eval { require YAML })
  {
    return YAML::Dump(@_);
  }
  else
  {
    require Data::Dumper;
    return Data::Dumper::Dumper(@_);
  }
}

1;
