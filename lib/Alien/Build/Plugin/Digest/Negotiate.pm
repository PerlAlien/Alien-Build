package Alien::Build::Plugin::Digest::Negotiate;

use strict;
use warnings;
use Alien::Build::Plugin;

# DESCRIPTION: Plugin negotiator for cryptographic signatures
# VERSION

=head1 SYNOPSIS

for a single file:

 use alienfile;
 plugin 'Digest' => [ SHA256 => $digest ];

or for multiple files:

 use alienfile;
 plugin 'Digest' => {
   file1 => [ SHA256 => $digest1 ],
   file2 => [ SHA256 => $digest2 ],
 };

=head1 DESCRIPTION

This plugin is experimental.

=cut

has '+sig' => sub { {} };

sub init
{
  my($self, $meta) = @_;
  $meta->add_requires('configure' => 'Alien::Build::Plugin::Digest::Negotiate' => "0" );

  $meta->prop->{check_digest} = 1;

  my $sigs = $meta->prop->{digest} ||= {};

  if(ref($self->sig) eq 'HASH') {

    foreach my $filename (keys %{ $self->sig })
    {
      my $signature = $self->sig->{$filename};
      my($algo) = @$signature;
      die "Unknown digest algorithm $algo" unless $algo =~ /^SHA(1|224|256|384|512|512224|512256)$/; # reportedly what is supported by Digest::SHA
      $sigs->{$filename} = $signature;
    }

  } elsif(ref($self->sig) eq 'ARRAY') {

    my $signature = $self->sig;
    my($algo) = @$signature;
    die "Unknown digest algorithm $algo" unless $algo =~ /^SHA(1|224|256|384|512|512224|512256)$/; # reportedly what is supported by Digest::SHA
    $sigs->{'*'} = $signature;
  }

  # In the future if this negotiator supports algorithms other
  # than SHA, we should probably ajust this to keep track of
  # which ones we actually need when we are looping through them
  # above.  Also technically you could call this plugin without
  # any sigs, and we shouldn't in theory need to apply Digest::SHA,
  # but stuff won't work that way so that is a corner case we
  # are not going to worry about.
  $meta->apply_plugin('Digest::SHA');
}

1;
