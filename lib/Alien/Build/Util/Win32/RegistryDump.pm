package Alien::Build::Util::Win32::RegistryDump;

use strict;
use warnings;
use base qw( Exporter );

our @EXPORT_OK = qw( _read_win32_reg_dump );

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

# perl -MYAML= -MConfig::INI::Reader::Multiline -MFile::BOM -E 'use autodie; open $fh, "<:via(File::BOM)", "foo.reg"; <$fh>; say Dump(Config::INI::Reader::Multiline->read_handle($fh))'

sub _load
{
  eval {
    require Config::INI::Reader::Multiline;
    require File::BOM;
  };
  $@ ? 0 : 1;
}

sub _read_win32_reg_dump
{
  my($filename) = @_;
  
  return {} unless _load();
  
  my $fh;
  open($fh, '<:via(File::BOM)', $filename) || die "unable to open $filename $!";
  <$fh>; # remove the app version information
  my $hash = Config::INI::Reader::Multiline->read_handle($fh);
  close $fh;

  foreach my $key (keys %$hash)
  {
    my %values;
    foreach my $old (keys %{ $hash->{$key} })
    {
      my $value = $hash->{$key}->{$old};

      my $new = $old;
      $new =~ s/^"//;
      $new =~ s/"$//;

      # These conversions are almost certainly (!)
      # incomplete.  We will add to them as needed.      
      if($value =~ /^"(.*)"$/)
      {
        $value = $1;
        $value =~ s/\\(.)/$1/g;
      }
      elsif($value =~ /^hex\(2\):(.*)$/)
      {
        $value = pack "C*", map { s/^\s+//; hex($_) } split /,/, $1;
      }
      elsif($value =~ /^dword:([0-9a-fA-F]+)$/)
      {
        $value = hex $1;
      }
      
      $values{$new} = $value;
    }
    $hash->{$key} = \%values;
  }
  
  $hash;
}

1;
