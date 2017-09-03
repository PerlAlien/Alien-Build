package Alien::Build::Plugin::Prefer::BadVersion;

use strict;
use warnings;
use Alien::Build::Plugin;
use Carp ();

# ABSTRACT: Filter out known bad versions
# VERSION

=head1 SYNOPSIS

 use alienfile;
 plugin 'Prefer::BadVersion' => '1.2.3';

=head1 DESCRIPTION

This plugin allows you to easily filter out known bad versions of libraries.  You need a Prefer plugin
that filters and sorts files first.  You may specify the filter in one of three ways:

=over

=item as a string

Filter out any files that match the given version.

 use alienfile;
 plugin 'Prefer::BadVersion' => '1.2.3';

=item as a array

Filter out all files that match any of the given versions.

 use alienfile;
 plugin 'Prefer::BadVersion' => [ '1.2.3', '1.2.4' ];

=item as a code reference

Filter out any files return a true value.

 use alienfile;
 plugin 'Prefer::BadVersion' => sub {
   my($file) = @_;
   $file->{version} eq '1.2.3'; # same as the string version above
 };

=back

This plugin can also be used to filter out known bad versions of a library on just one platform.
For example, if you know that version 1.2.3 if bad on windows, but okay on other platforms:

 use alienfile;
 plugin 'Prefer::BadVersion' => '1.2.3' if $^O eq 'MSWin32';

=head1 PROPERTIES

=head2 filter

Filter out entries that match the filter.

=head1 CAVEATS

If you are using the string or array mode, then you need an existing Prefer plugin that sets the
version number for each file candidate, such as L<Alien::Build::Plugin::Prefer::SortVersions>.

=head1 SEE ALSO

=over 4

=item L<alienfile>

=item L<Alien::Build>

=item L<Alien::Build::Plugin::Prefer::SortVersions>

=back

=cut

has '+filter' => sub { Carp::croak("The filter property is required for the Prefer::BadVersion plugin") };

sub init
{
  my($self, $meta) = @_;

  $meta->add_requires('configure', __PACKAGE__, '1.05');
  
  my $filter;
  
  if(ref($self->filter) eq '')
  {
    my $string = $self->filter;
    $filter = sub {
      my($file) = @_;
      $file->{version} ne $string;
    };
  }
  elsif(ref($self->filter) eq 'ARRAY')
  {
    my %filter = map { $_ => 1 } @{ $self->filter };
    $filter = sub {
      my($file) = @_;
      ! $filter{$file->{version}};
    };
  }
  elsif(ref($self->filter) eq 'CODE')
  {
    my $code = $self->filter;
    $filter = sub { ! $code->($_[0]) };
  }
  else
  {
    Carp::croak("unknown filter type for Prefer::BadVersion");
  }
  
  $meta->around_hook(
    prefer => sub {
      my($orig, $build, @therest) = @_;
      my $res1 = $orig->($build, @therest);
      return $res1 unless $res1->{type} eq 'list';
      
      return {
        type => 'list',
        list => [
          grep { $filter->($_) } @{ $res1->{list} }
        ],
      };
    },
  );
}

1;
