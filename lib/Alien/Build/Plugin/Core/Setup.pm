package Alien::Build::Plugin::Core::Setup;

use strict;
use warnings;
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
}

1;
