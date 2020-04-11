package Alien::Build::Plugin::Prefer::SortVersions;

use strict;
use warnings;
use Alien::Build::Plugin;

# ABSTRACT: Plugin to sort candidates by most recent first
# VERSION

=head1 SYNOPSIS

 use alienfile;
 
 plugin 'Prefer::SortVersions';

=head1 DESCRIPTION

Note: in most case you will want to use L<Alien::Build::Plugin::Download::Negotiate>
instead.  It picks the appropriate fetch plugin based on your platform and environment.
In some cases you may need to use this plugin directly instead.

This Prefer plugin sorts the packages that were retrieved from a dir listing, either
directly from a Fetch plugin, or from a Decode plugin.  It Returns a listing with the
items sorted from post preferable to least, and filters out any undesirable candidates.

This plugin updates the file list to include the versions that are extracted, so they
can be used by other plugins, such as L<Alien::Build::Plugin::Prefer::BadVersion>.

=head1 PROPERTIES

=head2 filter

This is a regular expression that lets you filter out files that you do not
want to consider downloading.  For example, if the directory listing contained
tarballs and readme files like this:

 foo-1.0.0.tar.gz
 foo-1.0.0.readme

You could specify a filter of C<qr/\.tar\.gz$/> to make sure only tarballs are
considered for download.

=cut

has 'filter'   => undef;

=head2 version

Regular expression to parse out the version from a filename.  The regular expression
should store the result in C<$1>.  The default C<qr/([0-9\.]+)/> is frequently
reasonable.

=cut

has '+version' => qr/([0-9](?:[0-9\.]*[0-9])?)/;

sub init
{
  my($self, $meta) = @_;

  $meta->add_requires('share' => 'Sort::Versions' => 0);

  $meta->register_hook( prefer => sub {
    my(undef, $res) = @_;

    my $cmp = sub {
      my($A,$B) = map { ($_ =~ $self->version)[0] } @_;
      Sort::Versions::versioncmp($B,$A);
    };

    my @list = sort { $cmp->($a->{filename}, $b->{filename}) }
               map {
                 ($_->{version}) = $_->{filename} =~ $self->version;
                 $_ }
               grep { $_->{filename} =~ $self->version }
               grep { defined $self->filter ? $_->{filename} =~ $self->filter : 1 }
               @{ $res->{list} };

    return {
      type => 'list',
      list => \@list,
    };
  });
}

1;

=head1 SEE ALSO

L<Alien::Build::Plugin::Download::Negotiate>, L<Alien::Build>, L<alienfile>, L<Alien::Build::MM>, L<Alien>

=cut
