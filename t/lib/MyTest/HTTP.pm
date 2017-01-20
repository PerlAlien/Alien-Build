package MyTest::HTTP;

use strict;
use warnings;
use Path::Tiny qw( path );
use JSON::PP qw( decode_json );
use base qw( Exporter );

our @EXPORT = qw( http_url http_error );

my $http_error;

sub http_error
{
  my($new) = @_;
  if($new)
  {
    $http_error = $new;
    return;
  }
  else
  {
    return $http_error;
  }
}

sub http_url
{
  my $file = path('t/bin/httpd.json');
  return http_error('no httpd.json') unless -r $file;

  my $config = eval { decode_json($file->slurp) };
  return http_error("error loading httpd.json $@") if $@;

  my $url = $config->{url};
  return http_error("no url in httpd.json") unless $url;

  require HTTP::Tiny;
  my $res = HTTP::Tiny->new->get("${url}about.json");
  my $about = decode_json( $res->{content} );
  return http_error("not a AB TEST HTTPd")
    unless $about->{ident} eq 'AB Test HTTPd';

  return $url;
}

1;
