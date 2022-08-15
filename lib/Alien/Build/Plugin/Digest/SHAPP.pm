package Alien::Build::Plugin::Digest::SHAPP;

use strict;
use warnings;
use Alien::Build::Plugin;

# ABSTRACT: Plugin to check SHA digest with Digest::SHA::PurePerl
# VERSION

=head1 SYNOPSIS

 use alienfile;
 plugin 'Digest::SHAPP';

=head1 DESCRIPTION

This plugin is experimental.

=cut

sub init
{
  my($self, $meta) = @_;

  $meta->add_requires('configure' => 'Alien::Build'          => "2.57" );
  $meta->add_requires('share'     => 'Digest::SHA::PurePerl' =>    "0" );

  $meta->register_hook( check_digest => sub {
    my($build, $file, $algo, $expected_digest) = @_;

    return 0 unless $algo =~ /^SHA[0-9]+$/;

    my $sha = Digest::SHA::PurePerl->new($algo);
    return 0 unless defined $sha;

    if(defined $file->{content})
    {
      $sha->add($file->{content});
    }
    elsif(defined $file->{path})
    {
      $sha->addfile($file->{path}, "b");
    }
    else
    {
      die "unknown file type";
    }

    my $actual_digest = $sha->hexdigest;

    return 1 if $expected_digest eq $actual_digest;
    die "@{[ $file->{filename} ]} SHA@{[ $sha->algorithm ]} digest does not match: got $actual_digest, expected $expected_digest";

  });
}

1;
