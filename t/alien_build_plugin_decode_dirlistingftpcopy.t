use Test2::Bundle::Extended;
use Alien::Build::Plugin::Decode::DirListing;
use lib 't/lib';
use MyTest;
use Path::Tiny;

subtest 'updates requires' => sub {

  my $plugin = Alien::Build::Plugin::Decode::DirListing->new;

  my($build,$meta) = build_blank_alien_build;
  
  $plugin->init($meta);
  
  is( $build->requires('share')->{'File::Listing'}, 0 );
  is( $build->requires('share')->{'URI'}, 0 );

  note $meta->_dump;

};

subtest 'decode' => sub {

  my $plugin = Alien::Build::Plugin::Decode::DirListing->new;

  my($build,$meta) = build_blank_alien_build;
  
  $plugin->init($meta);

  eval { $build->load_requires('share') };
  skip_all 'test requires File::Listing' if $@;

  foreach my $file (path('corpus/listing')->children(qr/\.list$/))
  {
    subtest "parse $file" => sub {
      my $res1 = {
        type    => 'dir_listing',
        base    => "ftp://example.test/foo/bar/",
        content => $file->slurp,
      };
      my $res2 = $build->decode($res1);
      is(
        $res2,
        hash {
          field type => 'list';
          field list => array {
            foreach my $filename (qw( foo-1.00 foo-1.00.tar foo-1.00.tar.Z foo-1.00.tar.bz2 foo-1.00.tar.gz foo-1.00.tar.xz foo-1.00.zip))
            {
              item hash {
                field filename => $filename;
                field url => match qr{\Q$filename\E};
              };
            }
          };
        },
      );
      note "url = $_" for map { $_->{url} } @{ $res2->{list} }
    };
  }

};

done_testing;
