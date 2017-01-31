package Alien::Build::Plugin::Prefer::SortVersions;

use strict;
use warnings;
use Alien::Build::Plugin;

# ABSTRACT: Plugin to sort candidates by most recent first
# VERSION

has 'filter'   => undef;
has '+version' => qr/([0-9\.]+)/;

sub init
{
  my($self, $meta) = @_;
  
  $meta->add_requires('share' => 'Sort::Versions' => 0);
  
  $meta->register_hook( prefer => sub {
    my(undef, $res) = @_;
    
    my $cmp = sub {
      my($A,$B) = map { $_ =~ $self->version } @_;
      Sort::Versions::versioncmp($B,$A);
    };
    
    my @list = sort { $cmp->($a->{filename}, $b->{filename}) }
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
