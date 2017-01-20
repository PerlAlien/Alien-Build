package MyTest::File;

use strict;
use warnings;
use Path::Tiny qw( path );
use JSON::PP qw( decode_json );
use base qw( Exporter );

our @EXPORT = qw( file_url file_error );

my $file_error;

sub file_error
{
  $file_error;
}

sub file_url
{
  if(eval { require URI::file })
  {
    return URI::file->new(path("corpus/dist")->absolute . "/");
  }
  else
  {
    $file_error = 'test requires URI::file';
    return;
  }
}

1;
