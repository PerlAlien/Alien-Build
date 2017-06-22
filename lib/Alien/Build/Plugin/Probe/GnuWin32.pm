package Alien::Build::Plugin::Probe::GnuWin32;

use strict;
use warnings;
use Alien::Build::Plugin;
use Module::Load ();
use File::Spec;
use Carp ();
use Capture::Tiny qw( capture );
use List::Util ();

# ABSTRACT: Probe for GnuWin32 packages using the Windows registry
# VERSION

has native_only         => 0;
has registery_key_regex => undef;
has registry_key_regex  => undef;
has exe_name            => undef;
has exe_match           => undef;
has exe_version         => undef;
has exe_args            => ['--version'];

sub _short ($)
{
  $_[0] =~ /\s+/ ? Win32::GetShortPathName( $_[0] ) : $_[0];
}

sub new
{
  my $class = shift;
  
  my $self = $class->SUPER::new(@_);
  
  if($self->registery_key_regex)
  {
    require Alien::Build;
    Alien::Build->log("warning: you are using a typo'd property, 'registery_key_regex', please use 'registry_key_regex' instead");
  }
  
  $self->registry_key_regex || $self->registry_key_regex($self->registery_key_regex) || Carp::croak "register_key_regex is required";
  
  $self;  
}

sub init
{
  my($self, $meta) = @_;
  
  # we may decide to take this module out of core.
  $meta->add_requires( 'configure' => 'Alien::Build::Plugin::Probe::GnuWin32' => 0 );
  
  if($^O eq 'MSWin32')
  {
    $meta->register_hook(
      probe => sub {
        my($build) = @_;
        
        my @paths = ([]);
        
        if(eval { Module::Load::load "Win32API::Registry"; 1 })
        {
          my @uninstall_key_names = qw(
            software\microsoft\windows\currentversion\uninstall
          );
          unshift @uninstall_key_names, qw( software\wow6432node\microsoft\windows\currentversion\uninstall )
            unless $self->native_only;
          
          foreach my $uninstall_key_name (@uninstall_key_names)
          {
            my $uninstall_key;
            Win32API::Registry::RegOpenKeyEx(
              Win32API::Registry::HKEY_LOCAL_MACHINE(),
              $uninstall_key_name,
              0,
              Win32API::Registry::KEY_READ(), 
              $uninstall_key ) || next;
            
            my $pos = 0;
            my($subkey, $class, $time) = ('','','');
            my($namSiz, $clsSiz) = (1024,1024);
            while(Win32API::Registry::RegEnumKeyEx( $uninstall_key, $pos++, $subkey, $namSiz, [], $class, $clsSiz, $time))
            {
              next unless $subkey =~ $self->registery_key_regex;
              my $flex_key;
              Win32API::Registry::RegOpenKeyEx( 
                $uninstall_key, 
                $subkey, 
                0, 
                Win32API::Registry::KEY_READ(),
                $flex_key ) || next;
              
              my $data;
              if(Win32API::Registry::RegQueryValueEx($flex_key, "InstallLocation", [], Win32API::Registry::REG_SZ(), $data, [] ))
              {
                push @paths, [File::Spec->catdir(_short $data, "bin")];
              }

              if(Win32API::Registry::RegQueryValueEx($flex_key, "Inno Setup: App Path", [], Win32API::Registry::REG_SZ(), $data, [] ))
              {
                push @paths, [File::Spec->catdir(_short $data, "bin")];
              }
              
              Win32API::Registry::RegCloseKey( $flex_key );
            }
            Win32API::Registry::RegCloseKey($uninstall_key);
          }
          
        }
        
        push @paths, map { [_short $ENV{$_}, qw( GnuWin32 bin )] } grep { defined $ENV{$_} } qw[ ProgramFiles ProgramFiles(x86) ];
        push @paths, ['C:\\GnuWin32\\bin'];
        
        $build->log("try system paths:");
        
        foreach my $path (map { File::Spec->catdir(@$_) } @paths)
        {
          $build->log("  - @{[ $path eq '' ? 'PATH' : $path ]}");
          foreach my $exe_name ($self->exe_name, $self->exe_name . '.exe')
          {
            my $exe = File::Spec->catfile($path, $exe_name);
            next unless $path eq '' || -f $exe;
            my @cmd = ($exe, @{ $self->exe_args });
            my($out, $err) = capture {
              system @cmd;
            };
            if($self->exe_match)
            {
              next unless $out =~ $self->exe_match;
            }
            if($self->exe_version && $out =~ $self->exe_version)
            {
              $build->runtime_prop->{version} = $1;
            }
            $build->runtime_prop->{system_bin_dir} = File::Spec->catfile($path) unless $path eq '';
            return 'system';
          }
        }
        
        'share';
      }
    );
  
  }
  
  $self;
}

1;
