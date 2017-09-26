package MyTest::Curl;

use strict;
use warnings;
use lib 't/lib';
use MyTest::System;
use Test2::API qw( context );
use Path::Tiny qw( path );
use Capture::Tiny qw( tee );
use JSON::PP qw( encode_json decode_json );
use base qw( Exporter );

our @EXPORT = qw( capture_note test_config );

sub capture_note (&)
{
  my($code) = @_;
  my($out, $error, @ret) = Capture::Tiny::capture_merged(sub { my @ret = eval { $code->() }; ($@, @ret) });
  
  my $ctx = context();
  $ctx->note($out) if $out ne '';
  $ctx->release;
  
  die $error if $error;
  wantarray ? @ret : $ret[0];
}

my %record = %{ decode_json path('corpus/alien_build_plugin_fetch_curlcommand/record/old.json')->slurp };

sub real_curl
{
  my(@args) = @_;
  
  my %old = map { $_->basename => 1 } path('.')->children;
  
  my($stdout, $stderr, $exit) = tee {
    CORE::system 'curl', @args;
    $? >> 8;
  };

  my $key = "@args";  
  
  for($key, $stdout, $stderr)
  {
    s{http://localhost.*?/corpus}{http://localhost/corpus}g;
    s{ftp://[a-z]+:[a-z]+\@localhost:[0-9]+/.*?/corpus}{ftp://localhost/corpus}g;
  }

  my %files;

  if(! -d ".git")
  {
    foreach my $child (path('.')->children)
    {
      next if $old{$child->basename};
      $files{$child->basename} = $child->slurp;
    }
  }
  
  $record{$key} = {
    stdout => $stdout,
    stderr => $stderr,
    exit   => $exit,
    files  => \%files,
  };
  
  $exit;
}

sub faux_curl
{
  my(@args) = @_;
  
  my $key = "@args";
  
  unless($record{$key})
  {
    my $ctx = context();
    $ctx->bail("do not have a record for curl $key");
  }
  
  my $run = $record{$key};
  
  print STDOUT $run->{stdout};
  print STDERR $run->{stderr};

  foreach my $filename (keys %{ $run->{files} })
  {
    path($filename)->spew($run->{files}->{$filename});
  }

  $run->{exit};
}

sub test_config ($)
{
  my($name) = @_;
  my $path = path("t/bin/$name.json");
  
  if(-f $path)
  {
    my $config = JSON::PP::decode_json(scalar $path->slurp);
    
    my $guard = system_fake;
    
    $guard->add('curl' => \&real_curl);
    $guard->add('/bin/curl' => \&real_curl);
    
    $config->{url} =~ s{dist/?$}{alien_build_plugin_fetch_curlcommand/dir};
    $config->{guard} = $guard;

    my $ctx = context();
    $ctx->note("testing against real curl and real $name @{[ $config->{url} ]}");
    $ctx->release;
    
    return $config;
  }
  eles
  {
    my %config;
    my $guard = system_fake;
    
    $guard->add('curl' => \&faux_curl);
    $guard->add('/bin/curl' => \&faux_curl);
    
    $config{guard} = $guard;
    $config{url}   = $name eq 'httpd'
      ? 'http://localhost/corpus/alien_build_plugin_fetch_curlcommand/dir'
      : 'ftp://localhost/corpus/alien_build_plugin_fetch_curlcommand/dir';
    
    return \%config;
  }
}

delete $ENV{CURL};

END {
  path('corpus/alien_build_plugin_fetch_curlcommand/record/new.json')->spew(encode_json( \%record ));
  if(eval { require YAML; 1 })
  {
    YAML::DumpFile(path('corpus/alien_build_plugin_fetch_curlcommand/record/new.yml')->stringify, \%record );
  }
}

1;
