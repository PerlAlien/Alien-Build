package Alien::Build::Plugin::Decode::DirListing;

use strict;
use warnings;
use Alien::Build::Plugin;
use File::Basename ();

# ABSTRACT: Plugin to extract links from a directory listing
# VERSION

=head1 SYNOPSIS

 use alienfile;
 plugin 'Decode::DirListing' => ();

=head1 DESCRIPTION

Note: in most case you will want to use L<Alien::Build::Plugin::Download::Negotiate>
instead.  It picks the appropriate decode plugin based on your platform and environment.
In some cases you may need to use this plugin directly instead.

This plugin decodes a ftp file listing into a list of candidates for your Prefer plugin.
It is useful when fetching from an FTP server via L<Alien::Build::Plugin::Fetch::LWP>.

=cut

sub init
{
  my($self, $meta) = @_;

  $meta->add_requires('share' => 'File::Listing' => 0);
  $meta->add_requires('share' => 'URI' => 0);
  
  $meta->register_hook( decode => sub {
    my(undef, $res) = @_;
    
    die "do not know how to decode @{[ $res->{type} ]}"
      unless $res->{type} eq 'dir_listing';
    
    my $base = URI->new($res->{base});
    
    return {
      type => 'list',
      list => [
        map {
          my($name) = @$_;
          my $basename = $name;
          $basename =~ s{/$}{};
          my %h = (
            filename => File::Basename::basename($basename),
            url      => URI->new_abs($name, $base)->as_string,
          );
          \%h;
        } File::Listing::parse_dir($res->{content})
      ],
    };
  });

  $self;
}

1;

=head1 SEE ALSO

L<Alien::Build::Plugin::Download::Negotiate>, L<Alien::Build::Plugin::Decode::DirListingFtpcopy>, L<Alien::Build>, L<alienfile>, L<Alien::Build::MM>, L<Alien>

=cut

