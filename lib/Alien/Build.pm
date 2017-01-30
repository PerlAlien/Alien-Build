package Alien::Build;

use strict;
use warnings;
use Alien::Build::Util;
use Path::Tiny ();
use Carp ();
use File::chdir;
use JSON::PP;
use Env qw( @PATH @PKG_CONFIG_PATH );

# ABSTRACT: Build external dependencies for use in CPAN
# VERSION

=head1 SYNOPSIS

TODO

=head1 DESCRIPTION

This module provides tools for building external (non-CPAN) dependencies 
for CPAN.  It is mainly designed to be used at install time of a CPAN 
client, and work closely with L<Alien::Base> which is used at runtime.

=cut

sub _path { goto \&Path::Tiny::path }

=head1 CONSTRUCTOR

=head2 new

 my $build = Alien::Build->new;

=cut

sub new
{
  my($class, %args) = @_;
  my $self = bless {
    install_prop => {
      root => _path($args{root} || "_alien")->absolute->stringify,
    },
    runtime_prop => {
    },
  }, $class;
  
  $self->meta->filename(
    $args{filename} || do {
      my(undef, $filename) = caller;
      _path($filename)->absolute->stringify;
    }
  );
  
  $self->{autosave} = $args{autosave};
  $self;
}

sub DESTROY
{
  my($self) = @_;
  if($self->{autosave} && -d $self->install_prop->{root})
  {
    $self->checkpoint;
  }
}

my $count = 0;

=head1 PROPERTIES

=head2 meta_prop

 my $href = $build->meta_prop;
 my $href = Alien::Build->meta_prop;

Hash of class properties.

=over

=item destdir

Use the C<DESTDIR> environment variable to stage your install before
copying the files into C<blib>.  This is the preferred method of
installing libraries because it improves reliability.  This technique
is supported by C<autoconf> and others.

=back

=cut

sub meta_prop
{
  my($class) = @_;
  $class->meta->prop;
}

=head2 install_prop

 my $href = $build->install_prop;

Hash of properties used during the install phase, for either a
C<system> or C<share> install.  For most things you will want to
use C<runtime_prop> below.  Only use C<install_prop> for properties
that are needed ONLY during the install phase.  Standard properties:

=over

=item root

The build root directory.  This will be an absolute path.  It is the
absolute form of C<./_alien> by default.

=item prefix

The install time prefix.  This may or may not be the same as the 
runtime prefix.  It may or may not be the same as stage.

=item stage

The stage directory where files will be copied.  This is usually the
root of the blib share directory.

=back

B<NOTE>: These properties should not include any blessed objects or code
references, because they will be serialized using a method that does
not preserve those capabilities.

=cut

sub install_prop
{
  shift->{install_prop};
}

=head2 runtime_prop

 my $href = $build->runtime_prop;

Hash of properties used during the runtime phase.  This can include
anything needed by your L<Alien::Base> based module, but these are
frequently useful:

=over 4

=item cflags

The compiler flags

=item libs

The library flags

=item version

The version of the library or tool

=item prefix

The final install root.

=item install_type

The install type.  Is one of:

=over

=item system

For when the library or tool is provided by the operating system, can be
detected by L<Alien::Build>, and is considered satisfactory by the
C<alienfile> recipe.

=item share

For when a system install is not possible, the library source will be
downloaded from the internet or retrieved in another appropriate fashion
and built.

=back

=back

B<NOTE>: These properties should not include any blessed objects or code
references, because they will be serialized using a method that does
not preserve those capabilities.

=cut

sub runtime_prop
{
  shift->{runtime_prop};
}

=head2 root

 my $dir = $build->root;

This is just a shortcut for:

 my $root = $build->install_prop->{root};

Except that it will be created if it does not already exist.  

=cut

sub root
{
  my($self) = @_;
  my $root = $self->install_prop->{root};
  _path($root)->mkpath unless -d $root;
  $root;
}

=head2 install_type

 my $type = $build->install_type;

This is just a shortcut for:

 my $type = $build->runtime_prop->{install_type};
 
=cut

sub install_type
{
  my($self) = @_;
  $self->{runtime_prop}->{install_type} ||= $self->probe;
}

=head1 METHODS

=head2 set_prefix

 $build->set_prefix($prefix);

=cut

sub set_prefix
{
  my($self, $prefix) = @_;
  
  if($self->meta_prop->{destdir})
  {
    $self->runtime_prop->{prefix} = 
    $self->install_prop->{prefix} = $prefix;
  }
  else
  {
    $self->runtime_prop->{prefix} = $prefix;
    $self->install_prop->{prefix} = $self->install_prop->{stage};
  }
}

=head2 load

 my $build = Alien::Build->load($alienfile);

=cut

sub load
{
  my(undef, $alienfile, @args) = @_;

  unless(-r $alienfile)
  {
    require Carp;
    Carp::croak "Unable to read alienfile: $alienfile";
  }

  my $file = _path $alienfile;
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
    
  my $self = $class->new(
    filename => $file->absolute->stringify,
    @args,
  );

  eval '# line '. __LINE__ . ' "' . __FILE__ . qq("\n) . qq{
    package ${class}::Alienfile;
    do '@{[ $file->absolute->stringify ]}';
    die \$\@ if \$\@;
  };
  die $@ if $@;

  $self->{args} = \@args;

  return $self;
}

=head2 checkpoint

 $build->checkpoint;

Save any install or runtime properties so that they can be reloaded on
a subsequent run.

=cut

sub checkpoint
{
  my($self) = @_;
  my $root = $self->root;
  _path("$root/alien.json")->spew(
    JSON::PP::encode_json({
      install => $self->install_prop,
      runtime => $self->runtime_prop,
      args    => $self->{args},
    })
  );
  $self;
}

=head2 resume

 Alien::Build->resume($alienfile, $root);

=cut

sub resume
{
  my(undef, $alienfile, $root) = @_;
  my $h = JSON::PP::decode_json(_path("$root/alien.json")->slurp);
  my $self = Alien::Build->load("$alienfile", @{ $h->{args} });
  $self->{install_prop} = $h->{install};
  $self->{runtime_prop} = $h->{runtime};
  $self;
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
  my $self = shift;
  my $config = ref($_[0]) eq 'HASH' ? shift : {};
  my($name, @args) = @_;
  $self->meta->call_hook( $config, $name => $self, @args );
}

=head2 probe

 my $install_type = $build->probe;

Attempts to determine if the operating system has the library or
tool already installed.  If so, then the string C<system> will
be returned and a system install will be performed.  If not,
then the string C<share> will be installed and the tool or
library will be downloaded and built from source.

If the environment variable C<ALIEN_INSTALL_TYPE> is set, then that
will be used instead of the detection logic.

=cut

sub probe
{
  my($self) = @_;
  local $CWD = $self->root;
  my $dir;
  
  my $env = $ENV{ALIEN_INSTALL_TYPE} || '';
  my $type;
  my $error;
  
  if($env eq 'share')
  {
    $type = 'share';
  }
  else
  {
    $type = eval {
      $self->_call_hook(
        {
          before => sub {
            $dir = Alien::Build::TempDir->new($self, "probe");
            $CWD = "$dir";
          },
          after  => sub {
            $CWD = $self->root;
          },
          ok     => 'system',
        },
        'probe',
      );
    };
    $error = $@;
  }
  
  if($error)
  {
    if($env eq 'system')
    {
      die $error;
    }
    warn "error in probe (will do a share install): $@";
    $type = 'share';
  }
  
  if($env && $env ne $type)
  {
    die "requested $env install not available";
  }
  
  if($type !~ /^(system|share)$/)
  {
    Carp::croak "probe hook returned something other than system or share: $type";
  }
  
  $self->runtime_prop->{install_type} = $type;
  
  $type;
}

=head2 gather_system

 $build->gather_system

This method gathers the necessary properties from the system for using
the library or tool under a system install type.
 
=cut

sub gather_system
{
  my($self) = @_;
  
  return $self if $self->install_prop->{complete}->{gather_system};
  
  local $CWD = $self->root;
  my $dir;
  
  if($self->meta->has_hook('gather_system'))
  {
    $self->_call_hook(
      {
        before => sub {
          $dir = Alien::Build::TempDir->new($self, "gather");
          $CWD = "$dir";
        },
        after  => sub {
          $CWD = $self->root;
        },
      },
      'gather_system',
    );
  }
  
  $self->install_prop->{finished} = 1;
  $self->install_prop->{complete}->{gather_system} = 1;
  
  $self;
}

=head2 download

 $build->download;

=cut

sub download
{
  my($self) = @_;
  
  return $self if $self->install_prop->{complete}->{download};
  
  if($self->meta->has_hook('download'))
  {
    my $tmp;
    local $CWD;
    my $valid = 0;
    
    $self->_call_hook(
      {
        before => sub {
          $tmp = Alien::Build::TempDir->new($self, "download");
          $CWD = "$tmp";
        },
        verify => sub {
          my @list = grep { $_->basename !~ /^\./, } _path('.')->children;
    
          my $count = scalar @list;
    
          if($count == 0)
          {
            die "no files downloaded";
          }
          elsif($count == 1)
          {
            my($archive) = $list[0];
            if(-d $archive)
            {
              print "Alien::Build> single dir, assuming directory\n";
            }
            else
            {
              print "Alien::Build> single file, assuming archive\n";
            }
            $self->install_prop->{download} = $archive->absolute->stringify;
            $self->install_prop->{complete}->{download} = 1;
            $valid = 1;
          }
          else
          {
            print "Alien::Build> multiple files, assuming directoryn";
            $self->install_prop->{complete}->{download} = 1;
            $self->install_prop->{download} = _path('.')->absolute->stringify;
            $valid = 1;
          }   
        },
        after  => sub {
          $CWD = $self->root;
        },
      },
      'download',
    );
    
    return $self if $valid;
  }
  else
  {
    my $res = $self->fetch;

    if($res->{type} =~ /^(?:html|dir_listing)$/)
    {
      my $type = $res->{type};
      $type =~ s/_/ /;
      print "Alien::Build> decoding $type\n";
      $res = $self->decode($res);
    }
    
    if($res->{type} eq 'list')
    {
      $res = $self->prefer($res);
      die "no matching files in listing" if @{ $res->{list} } == 0;
      my($pick, @other) = map { $_->{url} } @{ $res->{list} };
      if(@other > 8)
      {
        splice @other, 7;
        push @other, '...';
      }
      print "Alien::Build> candidate *$pick\n";
      print "Alien::Build> candidate  $_\n" for @other;
      $res = $self->fetch($pick);
    }

    my $tmp = Alien::Build::TempDir->new($self, "download");
    
    if($res->{type} eq 'file')
    {
      my $alienfile = $res->{filename};
      print "Alien::Build> downloaded $alienfile\n";
      if($res->{content})
      {
        my $path = _path("$tmp/$alienfile");
        $path->spew_raw($res->{content});
        $self->install_prop->{download} = $path->stringify;
        $self->install_prop->{complete}->{download} = 1;
        return $self;
      }
      elsif($res->{path})
      {
        require File::Copy;
        my $from = _path $res->{path};
        my $to   = _path("$tmp/@{[ $from->basename ]}");
        File::Copy::copy(
          "$from" => "$to",
        ) || die "copy $from => $to failed: $!";
        $self->install_prop->{download} = $to->stringify;
        $self->install_prop->{complete}->{download} = 1;
        return $self;
      }
      die "file without content or path";
    }
    
    die "unknown fetch response type: @{[ $res->{type} ]}";
  }
  
  die "download failed";
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

=head2 prefer

 my $sorted_res = $build->prefer($res);

Filter and sort candidates.  The preferred candidate will be returned first in the list.
The worst candidate will be returned last.

=cut

sub prefer
{
  my($self, $res) = @_;
  $self->_call_hook( prefer => $res );
}

=head2 extract

 my $dir = $build->extract;
 my $dir = $build->extract($archive);

=cut

sub extract
{
  my($self, $archive) = @_;
  
  $archive ||= $self->install_prop->{download};
  
  unless(defined $archive)
  {
    die "tried to call extract before download";
  }
  
  my $tmp;
  local $CWD;
  my $ret;

  $self->_call_hook({
  
    before => sub {
      # called build instead of extract, because this 
      # will be used for the build step, and technically
      # extract is a substage of build anyway.
      $tmp = Alien::Build::TempDir->new($self, "build");
      $CWD = "$tmp";
    },
    verify => sub {
      my @list = grep { $_->basename !~ /^\./, } _path('.')->children;
      
      my $count = scalar @list;
      
      if($count == 0)
      {
        die "no files extracted";
      }
      elsif($count == 1 && -d $list[0])
      {
        $ret = $list[0]->absolute->stringify;
      }
      else
      {
        $ret = "$tmp";
      }
    
    },
    after => sub {
      $CWD = $self->root;
    },
  
  }, 'extract', $archive);
  
  $ret ? $ret : ();
}

=head2 build

 $build->build;

=cut

sub build
{
  my($self) = @_;

  # save the evironment, in case some plugins decide
  # to alter it.  Or us!  See just a few lines below.
  local %ENV = %ENV;
  
  my $stage = _path($self->install_prop->{stage});
  $stage->mkpath;
  
  if($self->install_type eq 'share')
  {
    local $CWD;
  
    unless($self->meta_prop->{destdir})
    {
      delete $ENV{DESTDIR};
    }
  
    my $destdir;
  
    %ENV = (%ENV, %{ $self->meta_prop->{env} || {} });
    %ENV = (%ENV, %{ $self->install_prop->{env} || {} });
  
    $self->_call_hook(
    {
      before => sub {
        $CWD = $self->extract;
        if($self->meta_prop->{destdir})
        {
          $destdir = Alien::Build::TempDir->new($self, 'destdir');
          $ENV{DESTDIR} = "$destdir";
        }
      },
      after => sub {
        $destdir = "$destdir" if $destdir;
      },
    }, 'build');
  
    my $gather = sub {
      local $ENV{PATH} = $ENV{PATH};
      local $ENV{PKG_CONFIG_PATH} = $ENV{PKG_CONFIG_PATH};
      unshift @PATH, _path('bin')->absolute->stringify
        if -d 'bin';
      unshift @PKG_CONFIG_PATH, _path('lib/pkgconfig')->absolute->stringify
        if -d 'lib/pkgconfig';
      $self->_call_hook('gather_share');
    };
  
    if($destdir)
    {
      die "nothing was installed into destdir" unless -d $destdir;
      my $prefix = $self->install_prop->{prefix};
      $prefix =~ s!^([a-z]):!$1!i;
      my $src = _path("$ENV{DESTDIR}/$prefix"); 
      my $dst = $stage;
    
      if($self->meta->has_hook('gather_share'))
      {
        local $CWD = "$src";
        $gather->();
      }
    
      $dst->mkpath;
      Alien::Build::Util::_mirror("$src", "$dst", { verbose => 1 });
    }
    else
    {
      if($self->meta->has_hook('gather_share'))
      {
        local $CWD = $self->install_prop->{stage};
        $gather->();
      }
    }
  }
  
  elsif($self->install_type eq 'system')
  {
    $self->gather_system;
  }
  
  $stage->child('_alien')->mkpath;
  $stage->child('_alien/alien.json')->spew(JSON::PP::encode_json($self->runtime_prop));
  if($self->meta->filename && -r $self->meta->filename && $self->meta->filename !~ /\.(pm|pl)$/)
  {
    _path($self->meta->filename)->copy(_path($stage->child('_alien/alienfile')));
  }
  
  $self;
}

=head1 HOOKS

=head2 probe hook

 $meta->register_hook( probe => sub {
   my($build) = @_;
   return 'system' if ...; # system install
   return 'share';         # otherwise
 });
 
 $meta->register_hook( probe => [ $command ] );

This hook should return the string C<system> if the operating
system provides the library or tool.  It should return C<share>
otherwise.

You can also use a command that returns true when the tool
or library is available.  For example for use with C<pkg-config>:

 $meta->register_hook( probe =>
   [ '%{pkgconf} --exists libfoo' ] );

Or if you needed a minimum version:

 $meta->register_hook( probe =>
   [ '%{pkgconf} --atleast-version=1.00 libfoo' ] );

Note that this hook SHOULD NOT gather system properties, such as
cflags, libs, versions, etc, because the probe hook will be skipped
in the even the environment variable C<ALIEN_INSTALL_TYPE> is set.
The detection of these properties should instead be done by the
C<gather_system> hook, below.

=head2 gather_system hook

 $meta->register_hook( gather_system => sub {
   my($build) = @_;
   $build->runtime_prop->{cflags}  = ...;
   $build->runtime_prop->{libs}    = ...;
   $build->runtime_prop->{version} = ...;
 });

This hook is called for a system install to determine the properties
necessary for using the library or tool.  These properties should be
stored in the C<runtime_prop> hash as shown above.  Typical properties
that are needed for libraries are cflags and libs.  If at all possible
you should also try to determine the version of the library or tool.

=head2 download hook

 $meta->register_hook( download => sub {
   my($build) = @_;
 });

This hook is used to download from the internet the source.  Either as
an archive (like tar, zip, etc), or as a directory of files (git clone,
etc).  When the hook is called, the current working directory will be a
new empty directory, so you can save the download to the current
directory.  If you store a single file in the directory, L<Alien::Build>
will assume that it is an archive, which will be processed by the 
extract hook below.  If you store multiple files, L<Alien::Build> will
assume the current directory is the source root.  If no files are stored
at all, an exception with an appropriate diagnostic will be thrown.

B<Note>: If you register this hook, then the fetch, decode and prefer 
hooks will NOT be called.

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

=head2 decode hook

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
and links that can be used by the prefer hook to choose the correct file to
download.  See C<fetch> for the specification of the input and response
hash references.

=head2 prefer hook

 sub init
 {
   my($self, $meta) = @_;
   
   $meta->register_hook( prefer => sub {
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

=head2 extract hook

 $meta->register_hook( extract => sub {
   my($build, $archive) = @_;
   ...
 });

=head2 build hook

 $meta->register_hook( build => sub {
   my($build) = @_;
   ...
 });

=head2 gather_share hook

 $meta->register_hook( register_hook => sub {
   my($build) = @_;
   ... 
 });

=cut

package Alien::Build::Meta;

our @CARP_NOT = qw( alienfile );

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
    around => {},
    prop => {},
    %args,
  }, $class;
  $self;
}

=head1 META METHODS

=head2 prop

 my $href = $build->meta->prop;
 my $href = Alien::Build->meta->prop;

Meta properties.  This is the same as calling C<meta_prop> on
the class or L<Alien::Build> instance.

=cut

sub prop
{
  shift->{prop};
}

=head2 filename

 my $filename = $build->meta->filename;
 my $filename = Alien::Build->meta->filename;

=cut

sub filename
{
  my($self, $new) = @_;
  $self->{filename} = $new if defined $new;
  $self->{filename};
}

=head2 add_requires

 $build->meta->add_requires($phase, $module => $version, ...);
 Alien::Build->meta->add_requires($phase, $module => $version, ...);

=cut

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

=head2 interpolator

 my $interpolator = $build->meta->interpolator;
 my $interpolator = Alien::Build->interpolator;

=cut

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

=head2 has_hook

 my $bool = $build->meta->has_hook($name);
 my $bool = Alien::Build->has_hook($name);

=cut

sub has_hook
{
  my($self, $name) = @_;
  defined $self->{hook}->{$name};
}

=head2 register_hook

 $build->meta->register_hook($name, $instructions);
 Alien::Build->meta->register_hook($name, $instructions);

=cut

sub _instr
{
  my($self, $name, $instr) = @_;
  if(ref($instr) eq 'CODE')
  {
    return $instr;
  }
  elsif(ref($instr) eq 'ARRAY')
  {
    my %phase = (
      download      => 'share',
      fetch         => 'share',
      decode        => 'share',
      prefer        => 'share',
      extract       => 'share',
      build         => 'share',
      stage         => 'share',
      gather_share  => 'share',
      gather_system => 'system',
    );
    require Alien::Build::CommandSequence;
    my $seq = Alien::Build::CommandSequence->new(@$instr);
    $seq->apply_requirements($self, $phase{$name} || 'any');
    return $seq;
  }
  else
  {
    Carp::croak "type not supported as a hook";
  }
}

sub register_hook
{
  my($self, $name, $instr) = @_;
  push @{ $self->{hook}->{$name} }, _instr $self, $name, $instr;
  $self;
}

=head2 default_hook

 $build->meta->default_hook($name, $instructions);
 Alien::Build->meta->default_hook($name, $instructions);

=cut

sub default_hook
{
  my($self, $name, $instr) = @_;
  $self->{default_hook}->{$name} = _instr $self, $name, $instr;
  $self;
}

=head2 around_hook

 $build->meta->around_hook($hook, $code);
 Alien::Build->meta->around_hook($name, $code);

=cut

sub around_hook
{
  my($self, $name, $code) = @_;
  if(my $old = $self->{around}->{$name})
  {
    # this is the craziest shit I have ever
    # come up with.
    $self->{around}->{$name} = sub {
      my $orig = shift;
      $code->(sub { $old->($orig, @_) }, @_);
    };
  }
  else
  {
    $self->{around}->{$name} = $code;
  }
}

sub call_hook
{
  my $self = shift;
  my %args = ref $_[0] ? %{ shift() } : ();
  my($name, @args) = @_;
  my $error;
  
  my @hooks = @{ $self->{hook}->{$name} || []};
  
  if(@hooks == 0 && defined $self->{default_hook}->{$name})
  {
    @hooks = ($self->{default_hook}->{$name})
  }
    
  foreach my $hook (@hooks)
  {
    my $wrapper = $self->{around}->{$name} || sub { my $code = shift; $code->(@_) };
    my $value;
    $args{before}->() if $args{before};
    if(ref($hook) eq 'CODE')
    {
      $value = eval {
        my $value = $wrapper->(sub { $hook->(@_) }, @args);
        $args{verify}->('code') if $args{verify};
        $value;
      };
    }
    else
    {
      $value = $wrapper->(sub {
        eval {
          $hook->execute(@_);
          $args{verify}->('command') if $args{verify};
        };
        defined $args{ok} ? $args{ok} : 1;
      }, @args);
    }
    $error = $@;
    $args{after}->() if $args{after};
    next if $error;
    return $value;
  }
  die $error if $error;
  Carp::croak "No hooks registered for $name";
}

sub _dump
{
  my($self) = @_;
  require Alien::Build::Util;
  Alien::Build::Util::_dump($self);
}

package Alien::Build::TempDir;

use Path::Tiny qw( path );
use overload '""' => sub { shift->as_string };
use File::Temp qw( tempdir );

sub new
{
  my($class, $build, $name) = @_;
  my $root = $build->install_prop->{root};
  path($root)->mkpath unless -d $root;
  bless {
    dir => path(tempdir( "${name}_XXXX", DIR => $root)),
  }, $class;
}

sub as_string
{
  shift->{dir}->stringify;
}

sub DESTROY
{
  my($self) = @_;
  if(-d $self->{dir} && $self->{dir}->children == 0)
  {
    rmdir($self->{dir}) || warn "unable to remove @{[ $self->{dir} ]} $!";
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
