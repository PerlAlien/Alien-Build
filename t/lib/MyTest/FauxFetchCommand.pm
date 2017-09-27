package MyTest::FauxFetchCommand;

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

my($test_name) = $0 =~ m{/(.*)\.t$};
my $command_name = $test_name =~ /curlcommand/ ? 'curl' : 'wget';

my %record = %{ decode_json path("corpus/$test_name/record/old.json")->slurp };

sub real_cmd
{
  my(@args) = @_;
  
  my %old = map { $_->basename => 1 } path('.')->children;
  
  my($stdout, $stderr, $exit) = tee {
    CORE::system $command_name, @args;
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

sub faux_cmd
{
  my(@args) = @_;
  
  my $key = "@args";
  
  unless($record{$key})
  {
    my $ctx = context();
    $ctx->bail("do not have a record for $command_name $key");
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
    
    $guard->add($command_name        => \&real_cmd);
    $guard->add("/bin/$command_name" => \&real_cmd);
    
    $config->{url} =~ s{dist/?$}{$test_name/dir};
    $config->{guard} = $guard;

    my $ctx = context();
    $ctx->note("testing against real $command_name and real $name @{[ $config->{url} ]}");
    $ctx->release;
    
    return $config;
  }
  eles
  {
    my %config;
    my $guard = system_fake;
    
    $guard->add($command_name        => \&faux_cmd);
    $guard->add("/bin/$command_name" => \&faux_cmd);
    
    $config{guard} = $guard;
    $config{url}   = $name eq 'httpd'
      ? "http://localhost/corpus/$test_name/dir"
      : "ftp://localhost/corpus/$test_name/dir";
    
    return \%config;
  }
}

delete $ENV{CURL};
delete $ENV{WGET};

END {
  path("corpus/$test_name/record/new.json")->spew(encode_json( \%record ));
  if(eval { require YAML; 1 })
  {
    YAML::DumpFile(path("corpus/$test_name/record/new.yml")->stringify, \%record );
  }
}

1;
