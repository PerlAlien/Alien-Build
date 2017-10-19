package Alien::Build::Plugin::Extract::Negotiate;

use strict;
use warnings;
use Alien::Build::Plugin;
use Alien::Build::Plugin::Extract::ArchiveTar;
use Alien::Build::Plugin::Extract::ArchiveZip;
use Alien::Build::Plugin::Extract::CommandLine;
use Alien::Build::Plugin::Extract::Directory;

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

  my $plugin = $self->pick($format);
  $meta->apply_plugin($plugin, format => $format);
  $self;
}

=head1 METHODS

=head2 pick

 my $name = Alien::Build::Plugin::Extract::Negotiate->pick($format);

Returns the name of the best plugin for the given format.

=cut

sub pick
{
  my(undef, $format) = @_;

  if($format =~ /^tar(\.(gz|bz2))?$/)
  {
    if(Alien::Build::Plugin::Extract::ArchiveTar->available($format))
    {
      return 'Extract::ArchiveTar';
    }
    else
    {
      return 'Extract::CommandLine';
    }
  }
  elsif($format eq 'zip')
  {
    # Archive::Zip is not that reliable.  But if it is already installed it is probably working
    if(Alien::Build::Plugin::Extract::ArchiveZip->available($format))
    {
      return 'Extract::ArchiveZip';
    }

    # if we don't have Archive::Zip, check if we have the unzip command
    elsif(Alien::Build::Plugin::Extract::CommandLine->available($format))
    {
      return 'Extract::CommandLine';
    }

    # okay fine.  I will try to install Archive::Zip :(
    # if this becomes a problem in the future we can
    # create Alien::unzip and fallback on CommandLine instead.
    else
    {
      return 'Extract::ArchiveZip';
    }
  }
  elsif($format eq 'tar.xz' || $format eq 'tar.Z')
  {
    return 'Extract::CommandLine';
  }
  elsif($format eq 'd')
  {
    return 'Extract::Directory';
  }
  else
  {
    die "do not know how to handle format: $format";
  }
}

1;

=head1 SEE ALSO

L<Alien::Build>, L<alienfile>, L<Alien::Build::MM>, L<Alien>

=cut
