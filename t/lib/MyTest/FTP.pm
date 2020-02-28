package MyTest::FTP;

use strict;
use warnings;
use Path::Tiny qw( path );
use JSON::PP qw( decode_json );
use base qw( Exporter );

our @EXPORT = qw( ftp_url ftp_error );

my $ftp_error;

sub ftp_error
{
  my($new) = @_;
  if($new)
  {
    $ftp_error = $new;
    return undef;
  }
  else
  {
    return $ftp_error;
  }
}

sub ftp_url
{
  my $file = path('t/bin/ftpd.json');
  return ftp_error('no ftpd.json') unless -r $file;

  my $config = eval { decode_json($file->slurp_raw) };
  return ftp_error("error loading ftpd.json $@") if $@;

  my $url = $config->{url};
  return ftp_error("no url in ftpd.json") unless $url;

  require Net::FTP;
  require URI;

  $url = URI->new($url);

  my $ftp = Net::FTP->new($url->host, Port =>  $url->port) or do {
    return ftp_error("Connot connect to @{[ $url->host ]}");
  };

  eval {
    $ftp->login($url->user, $url->password) or die;
    $ftp->binary;
    $ftp->cwd($url->path) or die;
    my $path = Path::Tiny->tempfile;
    $ftp->get('foo-1.00.tar.xz', $path->stringify) or die;
    -e $path || die;
    $ftp->quit;
  };

  return ftp_error($ftp->message) if $@;

  $url->path($url->path . '/')
    unless $url->path =~ m!/$!;

  return $url;
}

1;
