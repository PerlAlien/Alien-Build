use 5.008004;
use Test2::V0 -no_srand => 1;
use Alien::Build::Plugin::Decode::Mojo;
use Test::Alien::Build;
use Path::Tiny qw( path );
use Data::Dumper qw( Dumper );

subtest 'updates requires' => sub {

  my $build = alienfile q{
    use alienfile;
    plugin 'Decode::Mojo';
  };

  is(
    $build->requires('share'),
    hash {
      field 'URI'         => 0;
      field 'URI::Escape' => 0;
      if($build->requires('share')->{'Mojo::DOM58'})
      {
        field 'Mojo::DOM58' => '1.00';
      }
      elsif($build->requires('share')->{'Mojo::DOM58'})
      {
        field 'Mojo::DOM'   => '0';
        field 'Mojolicious' => '0';
      }
      etc;
    },
  );

  note Dumper($build->requires('share'));

};

foreach my $class (qw( Mojo::DOM Mojo::DOM58 ))
{
  subtest "decode class = $class" => sub {

    my $build = alienfile qq{
      use alienfile;
      plugin 'Decode::Mojo' => ( _class => "$class" );
      probe sub { 'share' };
    };

    alienfile_skip_if_missing_prereqs;

    is
      $build->requires('share'),
      hash {
        field $class => D();
        field 'Mojolicious' => D() if $class eq 'Mojo::DOM';
        etc;
      }
    ;

    foreach my $file (path('corpus/dir')->children(qr/\.html$/))
    {
      subtest "parse $file" => sub {
        my $res1 = {
          type    => 'html',
          base    => "http://example.test/foo/bar/index.html",
          content => $file->slurp,
        };
        my $res2 = $build->decode($res1);
        is(
          $res2,
          hash {
            field type => 'list';
            field list => array {
              foreach my $filename (qw( foo-1.00 foo-1.00.tar foo-1.00.tar.Z foo-1.00.tar.bz2 foo-1.00.tar.gz foo-1.00.tar.xz foo-1.00.tgz foo-1.00.zip))
              {
                item hash {
                  field filename => $filename;
                  field url => match qr{\Q$filename\E};
                };
              }
            };
          },
        );
        note "filename = $_" for map { $_->{filename} } @{ $res2->{list} };
        note "url = $_" for map { $_->{url} } @{ $res2->{list} };
      };
    }

  };
}

done_testing
