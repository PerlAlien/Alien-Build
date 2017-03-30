package Alien::Build::Plugin::PkgConfig::MakeStatic;

use strict;
use warnings;
use Alien::Build::Plugin;
use Path::Tiny ();

# ABSTRACT: Convert .pc files into static
# VERSION

=head1 SYNOPSIS

 use alienfile;
 
 plugin 'PkgConfig::MakeStatic' => (
   path => 'lib/pkgconfig/foo.pc',
 );

=head1 DESCRIPTION

Convert C<.pc> file to use static linkage by default.  This is an experimental
plugin, so use with caution.

=head1 PROPERTIES

=head2 path

The path to the C<.pc> file.  If not provided, all C<.pc> files in the stage
directory will be converted.

=cut

has path => undef;

sub _convert
{
  my($self, $build, $path) = @_;
  
  die "unable to read $path" unless -r $path;
  die "unable to write $path" unless -w $path;
  
  $build->log("converting $path to static");
  
  my %h = map {
    my($key, $value) = $_ =~ /^(.*?):(.*?)$/;
    $value =~ s{^\s+}{};
    $value =~ s{\s+$}{};
    ($key => $value);
  } grep /^(?:Libs|Cflags)(?:\.private)?:/, $path->lines;

  $h{Cflags} = '' unless defined $h{Cflags};
  $h{Libs}   = '' unless defined $h{Libs};
  
  $h{Cflags} .= ' ' . $h{"Cflags.private"} if defined $h{"Cflags.private"};
  $h{Libs}   .= ' ' . $h{"Libs.private"} if defined $h{"Libs.private"};
  
  $h{"Cflags.private"} = '';
  $h{"Libs.private"}  = '';
  
  $path->edit_lines(sub {
  
    if(/^(.*?):/)
    {
      my $key = $1;
      if(defined $h{$key})
      {
        s/^(.*?):.*$/$1: $h{$key} /;
        delete $h{$key};
      }
    }
  
  });

  $path->append("$_: $h{$_}\n") foreach keys %h;
}

sub _recurse
{
  my($self, $build, $dir) = @_;
  
  foreach my $child ($dir->children)
  {
    if(-d $child)
    {
      $self->_recurse($build, $child);
    }
    elsif($child->basename =~ /\.pc$/)
    {
      $self->_convert($build, $child);
    }
  }
}

sub init
{
  my($self, $meta) = @_;

  $meta->add_requires('configure' => 'Alien::Build::Plugin::Build::SearchDep' => '0.35');

  $meta->before_hook(
    gather_share => sub {
      my($build) = @_;
    
      if($self->path)
      {
        $self->_convert($build, Path::Tiny->new($self->path)->absolute);
      }
      else
      {
        $self->_recurse($build, Path::Tiny->new(".")->absolute);
      }
    
    },
  );
}

1;
