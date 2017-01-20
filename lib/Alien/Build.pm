package Alien::Build;

use strict;
use warnings;
use Path::Tiny ();

# ABSTRACT: Build external dependencies for use in CPAN
# VERSION

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

=head2 fetch

 my $res = $build->fetch;
 my $res = $build->fetch($url);

Fetch a resource using the fetch hook.  Returns the same hash structure
described below in the hook documentation.

=cut

sub fetch
{
  my($self, $url) = @_;
  $self->meta->call_hook( 'fetch' => $url );
}

=head2 decode

 my $decoded_res = $build->decode($res);

Decode the HTML or file listing returned by C<fetch>.

=cut

sub decode
{
  my($self, $res) = @_;
  my $hook_name = "decode_" . $res->{type};
  $self->meta->call_hook( $hook_name => $res );
}

=head2 sort

 my $sorted_res = $build->sort($res);

Filter and sort candidates.  The best candidate will be returned first in the list.
The worst candidate will be returned last.

=cut

sub sort
{
  my($self, $res) = @_;
  $self->meta->call_hook( sort => $res );
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
     my($url) = @_;
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

=head2 decode_html hook

 sub init
 {
   my($self, $meta) = @_;
   
   $meta->register_hook( decode_html => sub {
     my($res) = @_;
     ...
   }
 }

This hook takes a response hash reference from the C<fetch> hook above
with a type of C<html> and converts it into a response hash reference
of type C<list>.  In short it takes an HTML response from a fetch hook
and converts it into a list of filenames and links that can be used
by the sort hook to choose the correct file to download.  See C<fetch>
for the specification of the input and response hash references.

=head2 decode_dir_listing

 sub init
 {
   my($self, $meta) = @_;
   
   $meta->register_hook( decode_html => sub {
     my($res) = @_;
     ...
   }
 }

This is the same as the C<decode_html> hook above, but it decodes hash
reference with type C<dir_listing>.

=head2 sort

 sub init
 {
   my($self, $meta) = @_;
   
   $meta->register_hook( sort => sub {
     my($res) = @_;
     return {
       type => 'list',
       list => [sort @{ $res->{list} }],
     };
   }
 }

This hook sorts candidates from a listing generated from either the C<fetch>
or one of the C<decode> hooks.  It should return a new list hash reference
with the candidates sorted from best to worst.  It may also remove candidates
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
      require Carp;
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
  $self->{hook}->{$name} = $instr;
  $self;
}

sub call_hook
{
  my($self, $name, @args) = @_;
  my $hook = $self->{hook}->{$name};
  if(ref($hook) eq 'CODE')
  {
    return $hook->(@args);
  }
  else
  {
    die "fixme";
  }
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
