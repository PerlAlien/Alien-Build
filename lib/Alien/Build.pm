package Alien::Build;

use strict;
use warnings;
use Path::Tiny ();
use Carp ();

# ABSTRACT: Build external dependencies for use in CPAN
# VERSION

=head1 SYNOPSIS

TODO

=head1 DESCRIPTION

This module provides tools for building external (non-CPAN) dependencies 
for CPAN.  It is mainly designed to be used at install time of a CPAN 
client, and work closely with L<Alien::Base> which is used at runtime.

=cut

sub _path { Path::Tiny::path(@_) }

=head1 CONSTRUCTOR

=head2 new

 my $build = Alien::Build->new;

=cut

sub new
{
  my($class) = @_;
  my $self = bless {}, $class;
  my(undef, $filename) = caller;
  $self->meta->filename(_path($filename)->absolute->stringify);
  $self;
}

my $count = 0;

=head1 METHODS

=head2 load

 my $build = Alien::Build->load($filename);

=cut

sub load
{
  my(undef, $filename) = @_;

  unless(-r $filename)
  {
    require Carp;
    Carp::croak "Unable to read alienfile: $filename";
  }

  my $file = _path $filename;
  my $name = $file->parent->basename;
  $name =~ s/^alien-//i;
  $name =~ s/[^a-z]//g;
  $name = 'x' if $name eq '';
  $name = ucfirst $name;

  my $class = "Alien::Build::Auto::$name@{[ $count++ ]}";

  { no strict 'refs';  
  @{ "${class}::ISA" } = ('Alien::Build');
  *{ "${class}::Alienfile::meta" } = sub {
    my($class) = @_;
    $class =~ s{::Alienfile$}{};
    $class->meta;
  }};
  
  $class->meta->filename($file->absolute->stringify);
  
  my $self = bless {}, $class;

  eval '# line '. __LINE__ . ' "' . __FILE__ . qq("\n) . qq{
    package ${class}::Alienfile;
    do '@{[ $file->absolute->stringify ]}';
    die \$\@ if \$\@;
  };
  die $@ if $@;

  return $self;
}

sub _merge
{
  my %h;
  while(@_)
  {
    my $mod = shift;
    my $ver = shift;
    if((!defined $h{$mod}) || $ver > $h{$mod})
    { $h{$mod} = $ver }
  }
  \%h;
}

=head2 requires

 my $hash = $build->requires($phase);

=cut

sub requires
{
  my($class, $phase) = @_;
  $phase ||= 'any';
  my $meta = $class->meta;
  $phase =~ /^(?:any|configure)$/
  ? $meta->{require}->{$phase}
  : _merge %{ $meta->{require}->{any} }, %{ $meta->{require}->{$phase} };
}

=head2 load_requires

 $build->load_requires;

=cut

sub load_requires
{
  my($class, $phase) = @_;
  my $reqs = $class->requires($phase);
  foreach my $mod (keys %$reqs)
  {
    my $ver = $reqs->{$mod};
    eval qq{ use $mod $ver () };
    die if $@;
  }
  1;
}

my %meta;

=head2 meta

 my $meta = Alien::Build->meta;
 my $meta = $build->meta;

=cut

sub meta
{
  my($class) = @_;
  $class = ref $class if ref $class;
  $meta{$class} ||= Alien::Build::Meta->new( class => $class );
}

sub _call_hook
{
  my($self, $name, @args) = @_;
  $self->meta->call_hook( $name => $self, @args );
}

=head2 fetch

 my $res = $build->fetch;
 my $res = $build->fetch($url);

Fetch a resource using the fetch hook.  Returns the same hash structure
described below in the hook documentation.

=cut

sub fetch
{
  my($self, $url) = @_;
  $self->_call_hook( 'fetch' => $url );
}

=head2 decode

 my $decoded_res = $build->decode($res);

Decode the HTML or file listing returned by C<fetch>.

=cut

sub decode
{
  my($self, $res) = @_;
  $self->_call_hook( decode => $res );
}

=head2 sort

 my $sorted_res = $build->sort($res);

Filter and sort candidates.  The best candidate will be returned first in the list.
The worst candidate will be returned last.

=cut

sub sort
{
  my($self, $res) = @_;
  $self->_call_hook( sort => $res );
}

=head1 HOOKS

=head2 fetch hook

 package Alien::Build::Plugin::MyPlugin;
 
 use strict;
 use warnings;
 use Alien::Build::Plugin;
 use Carp ();
 
 has '+url' => sub { Carp::croak "url is required property" };

 sub init
 {
   my($self, $meta) = @_;
   
   $meta->register_hook( fetch => sub {
     my($build, $url) = @_;
     ...
   }
 }
 
 1;

Used to fetch a resource.  The first time it will be called without an
argument, so the configuration used to find the resource should be
specified by the plugin's properties.  On subsequent calls the first
argument will be a URL.

Normally the first fetch will be to either a file or a directory listing.
If it is a file then the content should be returned as a hash reference
with the following keys:

 # content of file stored in Perl
 return {
   type     => 'file',
   filename => $filename,
   content  => $content,
 };
 
 # content of file stored in the filesystem
 return {
   type     => 'file',
   filename => $filename,
   path     => $path,    # full file system path to file
 };

If the URL points to a directory listing you should return it as either
a hash reference containing a list of files:

 return {
   type => 'list',
   list => [
     # filename: each filename should be just the
     #   filename portion, no path or url.
     # url: each url should be the complete url
     #   needed to fetch the file.
     { filename => $filename1, url => $url1 },
     { filename => $filename2, url => $url2 },
   ]
 };

or if the listing is in HTML format as a hash reference containing the
HTML information:

 return {
   type => 'html',
   charset => $charset, # optional
   base    => $base,    # the base URL: used for computing relative URLs
   content => $content, # the HTML content
 };

or a directory listing (usually produced by ftp servers) as a hash
reference:

 return {
   type    => 'dir_listing',
   base    => $base,
   content => $content,
 };

=head2 decode

 sub init
 {
   my($self, $meta) = @_;
   
   $meta->register_hook( decode => sub {
     my($build, $res) = @_;
     ...
   }
 }

This hook takes a response hash reference from the C<fetch> hook above
with a type of C<html> or C<dir_listing> and converts it into a response
hash reference of type C<list>.  In short it takes an HTML or FTP file
listing response from a fetch hook and converts it into a list of filenames
and links that can be used by the sort hook to choose the correct file to
download.  See C<fetch> for the specification of the input and response
hash references.

=head2 sort

 sub init
 {
   my($self, $meta) = @_;
   
   $meta->register_hook( sort => sub {
     my($build, $res) = @_;
     return {
       type => 'list',
       list => [sort @{ $res->{list} }],
     };
   }
 }

This hook sorts candidates from a listing generated from either the C<fetch>
or C<decode> hooks.  It should return a new list hash reference with the
candidates sorted from best to worst.  It may also remove candidates
that are totally unacceptable.

=cut

package Alien::Build::Meta;

sub new
{
  my($class, %args) = @_;
  my $self = bless {
    phase => 'any',
    require => {
      any    => {},
      share  => {},
      system => {},
    },
    %args,
  }, $class;
  $self;
}

sub filename
{
  my($self, $new) = @_;
  $self->{filename} = $new if defined $new;
  $self->{filename};
}

sub add_requires
{
  my $self = shift;
  my $phase = shift;
  while(@_)
  {
    my $module = shift;
    my $version = shift;
    my $old = $self->{require}->{$phase}->{$module};
    if((!defined $old) || $version > $old)
    { $self->{require}->{$phase}->{$module} = $version }
  }
  $self;
}

sub interpolator
{
  my($self, $new) = @_;
  if(defined $new)
  {
    if(defined $self->{intr})
    {
      Carp::croak "tried to set interpolator twice";
    }
    if(ref $new)
    {
      $self->{intr} = $new;
    }
    else
    {
      $self->{intr} = $new->new;
    }
  }
  elsif(!defined $self->{intr})
  {
    require Alien::Build::Interpolate::Default;
    $self->{intr} = Alien::Build::Interpolate::Default->new;
  }
  $self->{intr};
}

sub register_hook
{
  my($self, $name, $instr) = @_;
  push @{ $self->{hook}->{$name} }, $instr;
  $self;
}

sub call_hook
{
  my($self, $name, @args) = @_;
  
  my $error;
  
  foreach my $hook (@{ $self->{hook}->{$name} })
  {
    if(ref($hook) eq 'CODE')
    {
      my $value = eval { $hook->(@args) };
      next if $error = $@;
      return $value;
    }
    else
    {
      die "fixme";
    }
  }
  die $error if $error;
  Carp::croak "No hooks registered for $name";
}

sub _dump
{
  my($self) = @_;
  if(eval { require YAML })
  {
    return YAML::Dump($self);
  }
  else
  {
    require Data::Dumper;
    return Data::Dumper::Dumper($self);
  }
}

1;

=head1 CONTRIBUTING

Thank you for considering to contribute to my open source project!  If 
you have a small patch please consider just submitting it.  Doing so 
through the project GitHub is probably the best way:

L<https://github.com/plicease/Alien-Build/issues>

If you have a more invasive enhancement or bugfix to contribute, please 
take the time to review these guidelines.  In general it is good idea to 
work closely with the L<Alien::Build> developers, and the best way to 
contact them is on the C<#native> IRC channel on irc.perl.org.

=head2 History

Joel Berger wrote the original L<Alien::Base>.  This distribution 
included the runtime code L<Alien::Base> and an installer class 
L<Alien::Base::ModuleBuild>.  The significant thing about L<Alien::Base> 
was that it provided tools to make it relatively easy for people to roll 
their own L<Alien> distributions.  Over time, the Perl5-Alien (github 
organization) or "Alien::Base team" has taken over development of 
L<Alien::Base> with myself (Graham Ollis) being responsible for 
integration and releases.  Joel Berger is still involved in the project.

Since the original development of L<Alien::Base>, L<Module::Build>, on 
which L<Alien::Base::ModuleBuild> is based, has been removed from the 
core of Perl.  It seemed worthwhile to write a replacement installer 
that works with L<ExtUtils::MakeMaker> which IS still bundled with the 
Perl core.  Because this is a significant undertaking it is my intention 
to integrate the many lessons learned by Joel Berger, myself and the 
"Alien::Base team" as possible.  If the interface seems good then it is 
because I've stolen the ideas from some pretty good places.

=head2 Philosophy

=head3 avoid dependencies

One of the challenges with L<Alien> development is that you are by the 
nature of the problem, trying to make everyone happy.  Developers 
working out of CPAN just want stuff to work, and some build environments 
can be hostile in terms of tool availability, so for reliability you end 
up pulling a lot of dependencies.  On the other hand, operating system 
vendors who are building Perl modules usually want to use the system 
version of a library so that they do not have to patch libraries in 
multiple places.  Such vendors have to package any extra dependencies 
and having to do so for packages that the don't even use makes them 
understandably unhappy.

As general policy the L<Alien::Build> core should have as few 
dependencies as possible, and should only pull extra dependencies if 
they are needed.  Where dependencies cannot be avoidable, popular and 
reliable CPAN modules, which are already available as packages in the 
major Linux vendors (Debian, Red Hat) should be preferred.

As such L<Alien::Build> is hyper aggressive at using dynamic 
prerequisites.

=head3 interface agnostic

One of the challenges with L<Alien::Buil::ModuleBuild> was that 
L<Module::Build> was pulled from the core.  In addition, there is a 
degree of hostility toward L<Module::Build> in some corners of the Perl 
community.  I agree with Joel Berger's rationale for choosing 
L<Module::Build> at the time, as I believe its interface more easily 
lends itself to building L<Alien> distributions.

That said, an important feature of L<Alien::Build> is that it is 
installer agnostic.  Although it is initially designed to work with 
L<ExtUtils::MakeMaker>, it has been designed from the ground up to work 
with any installer (Perl, or otherwise).

As an extension of this, although L<Alien::Build> may have external CPAN 
dependencies, they should not be exposed to developers USING 
L<Alien::Build>.  As an example, L<Path::Tiny> is used heavily 
internally because it does what L<File::Spec> does, plus the things that 
it doesn't, and uses forward slashes on Windows (backslashes are the 
"correct separator on windows, but actually using them tends to break 
everything).  However, there aren't any interfaces in L<Alien::Build> 
that will return a L<Path::Tiny> object (or if there are, then this is a 
bug).

This means that if we ever need to port L<Alien::Build> to a platform 
that doesn't support L<Path::Tiny> (such as VMS), then it may require 
some work to L<Alien::Build> itself, modules that USE L<Alien::Build> 
shouldn't need to be modified.

=head3 plugable

The actual logic that probes the system, downloads source and builds it 
should be as pluggable as possible.  One of the challenges with 
L<Alien::Build::ModuleBuild> was that it was designed to work well with 
software that works with C<autoconf> and C<pkg-config>.  While you can 
build with other tools, you have to know a bit of how the installer 
logic works, and which hooks need to be tweaked.

L<Alien::Build> has plugins for C<autoconf>, C<pkgconf> (successor of 
C<pkg-config>), vanilla Makefiles, and CMake.  If your build system 
doesn't have a plugin, then all you have to do is write one!  Plugins 
that prove their worth may be merged into the L<Alien::Build> core.  
Plugins that after a while feel like maybe not such a good idea may be 
removed from the core, or even from CPAN itself.

In addition, L<Alien::Build> has a special type of plugin, called a 
negotiator which picks the best plugin for the particular environment 
that it is running in.  This way, as development of the negotiator and 
plugins develop over time modules that use L<Alien::Build> will benefit, 
without having to change the way they interface with L<Alien::Build>

=head1 ACKNOWLEDGEMENT

I would like to that Joel Berger for getting things running in the first 
place.  Also important to thank other members of the "Alien::Base team":

Zaki Mughal (SIVOAIS)

Ed J (ETJ, mohawk)

Also kind thanks to all of the developers who have contributed to 
L<Alien::Base> over the years:

L<https://metacpan.org/pod/Alien::Base#CONTRIBUTORS>

=cut
