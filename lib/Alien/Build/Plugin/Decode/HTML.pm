package Alien::Build::Plugin::Decode::HTML;

use strict;
use warnings;
use Alien::Build::Plugin;
use File::Basename ();

# ABSTRACT: Plugin to extract links from HTML
# VERSION

=head1 SYNOPSIS

 use alienfile;
 plugin 'Decode::HTML' => ();

=head1 DESCRIPTION

Note: in most case you will want to use L<Alien::Build::Plugin::Download::Negotiate>
instead.  It picks the appropriate decode plugin based on your platform and environment.
In some cases you may need to use this plugin directly instead.

This plugin decodes an HTML file listing into a list of candidates for your Prefer plugin.

=cut

sub init
{
  my($self, $meta) = @_;

  $meta->add_requires('share' => 'HTML::LinkExtor' => 0);
  $meta->add_requires('share' => 'URI' => 0);
  
  $meta->register_hook( decode => sub {
    my(undef, $res) = @_;
    
    die "do not know how to decode @{[ $res->{type} ]}"
      unless $res->{type} eq 'html';
    
    my $base = URI->new($res->{base});
    
    my @list;
    
    my $p = HTML::LinkExtor->new(sub {
      my($tag, %links) = @_;
      if($tag eq 'base' && $links{href})
      {
        $base = URI->new($links{href});
      }
      elsif($tag eq 'a' && $links{href})
      {
        my $href = $links{href};
        return if $href =~ m!^\.\.?/?$!;
        my $url = URI->new_abs($href, $base);
        my $path = $url->path;
        $path =~ s{/$}{}; # work around for Perl 5.8.7- gh#8
        push @list, {
          filename => File::Basename::basename($path),
          url      => $url->as_string,
        };
      }
    });
    
    $p->parse($res->{content});
    
    return {
      type => 'list',
      list => \@list,
    };
  });

  $self;
}

1;

=head1 SEE ALSO

L<Alien::Build::Plugin::Download::Negotiate>, L<Alien::Build>, L<alienfile>, L<Alien::Build::MM>, L<Alien>

=cut
