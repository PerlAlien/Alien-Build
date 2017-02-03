package Alien::Base2;

use strict;
use warnings;
use base qw( Alien::Base );
use File::Spec;
use JSON::PP ();
use File::ShareDir ();

# ABSTRACT: Intermediate base class for Aliens
# VERSION

# No seriously, please do not use this class, unless you coordinate
# with me on #native on irc.perl.org.  This class will live for
# no more than a number of months, hopefully just a few weeks.

=head1 SYNOPSIS

 package Alien::MyLib;
 
 use strict;
 use warnings;
 use base qw( Alien::Base2 );
 
 1;

=head1 DESCRIPTION

B<Note>: This class is going to go away!  Do not use it.

This is an I<experimental> subclass of L<Alien::Base> for use with L<Alien::Build>.  The
intention is for this class to eventually go away, and thus only of use for Alien developers
working on the bleeding edge.  If you want to use some of the advanced features of
L<Alien::Build> please make sure you hang out on the C<#native> IRC channel for Alien
developers.

=cut

sub cflags        { shift->_flags('cflags') }
sub cflags_static { shift->_flags('cflags_static') }
sub libs          { shift->_flags('libs') }
sub libs_static   { shift->_flags('libs_static') }

sub _flags
{
  my($class, $key) = @_;
  
  my $config = runtime_prop($class);
  my $flags = $config->{$key};

  my $prefix = $config->{prefix};
  $prefix =~ s{\\}{/}g if $^O =~ /^(MSWin32|msys)$/;
  my $distdir = $config->{distdir};
  $distdir =~ s{\\}{/}g if $^O =~ /^(MSWin32|msys)$/;
  
  if($prefix ne $distdir)
  {
    $flags = join ' ', map { 
      s/^(-I|-L|-LIBPATH:)?\Q$prefix\E/$1$distdir/;
      s/(\s)/\\$1/g;
      $_;
    } $class->split_flags($flags);
  }
  
  $flags;
}

sub config
{
  my($class, $key) = @_;
  my $config = runtime_prop($class);
  defined $config
    ? $config->{legacy}->{$key}
    : $class->SUPER::config($key);
}

sub import
{
  my($class) = @_;
  my $config = runtime_prop($class);
  goto \&Alien::Base::import unless $config;
}

{
  my %alien_build_config_cache;

  sub runtime_prop
  {
    my($class) = @_;
  
    $alien_build_config_cache{$class} ||= do {
      my $dist = ref $class ? ref $class : $class;
      $dist =~ s/::/-/g;
      my $dist_dir = File::ShareDir::dist_dir($dist);
      my $alien_json = File::Spec->catfile($dist_dir, '_alien', 'alien.json');
      return unless -r $alien_json;
      open my $fh, '<', $alien_json;
      my $json = do { local $/; <$fh> };
      close $fh;
      my $config = JSON::PP::decode_json($json);
      $config->{distdir} = $dist_dir;
      $config;
    };
  }
}

1;

=head1 SEE ALSO

=over 4

=item L<Alien::Base>

=item L<Alien::Build>

=back

