package Alien::Build::Plugin::Extract::Negotiate;

use strict;
use warnings;
use Alien::Build::Plugin;

# ABSTRACT: Extraction negotiation plugin
# VERSION

=head1 SYNOPSIS

 use alienfile;
 plugin 'Extract' => (
   format => 'tar.gz',
 );

=head1 DESCRIPTION

This is a negotiator plugin for extracting packages downloaded from the internet. 
This plugin picks the best Extract plugin to do the actual work.  Which plugins are
picked depend on the properties you specify, your platform and environment.  It is
usually preferable to use a negotiator plugin rather than using a specific Extract
Plugin from your L<alienfile>.

=head1 PROPERTIES

=head2 format

The expected format for the download.  Possible values include:
C<tar>, C<tar.gz>, C<tar.bz2>, C<tar.xz>, C<zip>, C<d>.

=cut

has '+format' => 'tar';

sub init
{
  my($self, $meta) = @_;
  
  my $format = $self->format;
  $format = 'tar.gz'  if $format eq 'tgz';
  $format = 'tar.bz2' if $format eq 'tbz';
  $format = 'tar.xz'  if $format eq 'txz';
  
  my $extract = $self->_pick($format);
  
  $self->_plugin($meta, 'Extract', $extract, format => $format);
}

sub _pick
{
  my(undef, $format) = @_;
  
  if($format eq 'tar')
  {
    return 'ArchiveTar';
  }
  elsif($format eq 'tar.gz')
  {
    if(eval q{ require Archive::Tar; Archive::Tar->has_zlib_support })
    {
      return 'ArchiveTar';
    }
    else
    {
      return 'CommandLine';
    }
  }
  elsif($format eq 'tar.bz2')
  {
    if(eval q{ require Alien::Build::Plugin::Extract::ArchiveTar; Alien::Build::Plugin::Extract::ArchiveTar->_can_bz2 })
    {
      return 'ArchiveTar';
    }
    else
    {
      return 'CommandLine';
    }
  }
  elsif($format eq 'zip')
  {
    # Archive::Zip is not that reliable.  But if it is already installed it is probably working
    if(eval q{ require Archive::Zip; 1 })
    {
      return 'ArchiveZip';
    }
    
    # if we don't have Archive::Zip, check if we have the unzip command
    elsif(eval { require Alien::Build::Plugin::Extract::CommandLine; Alien::Build::Plugin::Extract::CommandLine->new->unzip_cmd })
    {
      return 'Extract::CommandLine';
    }
    
    # okay fine.  I will try to install Archive::Zip :(
    else
    {
      return 'ArchiveZip';
    }
  }
  elsif($format eq 'tar.xz' || $format eq 'tar.Z')
  {
    return 'CommandLine';
  }
  elsif($format eq 'd')
  {
    return 'Directory';
  }
  else
  {
    die "do not know how to handle format: $format";
  }
}

sub _plugin
{
  my($self, $meta, $type, $name, @args) = @_;
  my $class = "Alien::Build::Plugin::${type}::$name";
  my $pm    = "Alien/Build/Plugin/$type/$name.pm";
  require $pm;
  my $plugin = $class->new(@args);
  $plugin->init($meta); 
}

1;

=head1 SEE ALSO

L<Alien::Build>, L<alienfile>, L<Alien::Build::MM>, L<Alien>

=cut
