package Alien::Build::Log;

use strict;
use warnings;
use 5.008001;
use Carp ();

# ABSTRACT: Alien::Build logging
# VERSION

=head1 SYNOPSIS

Create your custom log class:

 package Alien::Build::Log::MyLog;
 
 use base qw( Alien::Build::Log );
 
 sub log
 {
   my(undef, %opt)  = @_;
   my($package, $filename, $line) = @{ $opt{caller} };
   my $message = $opt{message};

   ...;
 }

override log class:

 % env ALIEN_BUILD_LOG=Alien::Build::Log::MyLog cpanm Alien::libfoo

=head1 DESCRIPTION

=head1 CONSTRUCTORS

=head2 new

 my $log = Alien::Build::Log->new;

Create an instance of the log class.

=cut

my $log_class;
my $self;

sub new
{
  my($class) = @_;
  Carp::croak("Cannot instantiate base class") if $class eq 'Alien::Build::Log';
  return bless {}, $class;
}

=head2 default

 my $log = Alien::Build::Log->default;

Return singleton instance of log class used by L<Alien::Build>.

=cut

sub default
{
  $self || do {
    my $class = $log_class || $ENV{ALIEN_BUILD_LOG} || 'Alien::Build::Log::Default';
    unless(eval { $class->can('new') })
    {
      my $pm = "$class.pm";
      $pm =~ s/::/\//g;
      require $pm;
    }
    $self = bless {}, $class;
  }
}

=head1 METHODS

=head2 set_log_class

 Alien::Build::Log->set_log_class($class);

Set the default log class used by L<Alien::Build>.  This method will also reset the
default instance used by L<Alien::Build>.  If not specified, L<Alien::Build::Log::Default>
will be used.

=cut

sub set_log_class
{
  my(undef, $class) = @_;
  return if defined $class && ($class eq ($log_class || ''));
  $log_class = $class;
  undef $self;
}

=head2 log

 $log->log(%options);

Overridable method which does the actual work of the log class.  Options:

=over 4

=item caller

Array references containing the package, file and line number of where the
log was called.

=item message

The message to log.

=back

=cut

sub log
{
  Carp::croak("AB Log base class");
}

1;

=head1 ENVIRONMENT

=over 4

=item ALIEN_BUILD_LOG

The default log class used by L<Alien::Build>.

=back

=cut
