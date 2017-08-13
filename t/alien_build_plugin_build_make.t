use Test2::V0 -no_srand => 1;
use Test::Alien::Build;
use Alien::Build::Plugin::Build::Make;
use Path::Tiny qw( path );

subtest 'compile' => sub {
  foreach my $type (qw( nmake dmake gmake umake ))
  {
    subtest $type => sub {
      my $build = alienfile_ok qq{
        use alienfile;
        plugin 'Build::Make' => '$type';
      };

      if($type =~ /nmake|dmake/)
      {
      
        is(
          $build->meta->interpolator->interpolate('%{make}'),
          $type,
        );
      }

    };
  }
};

subtest 'gmake' => sub {

  my $build = alienfile q{
    use alienfile;
    use Path::Tiny qw( path );
    plugin 'Build::Make' => 'gmake';
    
    probe sub { 'share' };
    
    share {
      download sub { path('file1')->touch };
      extract sub {

        # simple portable makefile that uses gmake specific
        # automatic variables
        path('Makefile')->spew(
          "%.exe:%.c\n",
          "\t$^X build.pl \$< \$@\n",
          "\n",
          "install:foo.exe\n",
          "\t$^X install.pl foo.exe \$(PREFIX)/bin/foo.exe\n",
        );
        
        path('build.pl')->spew("#!$^X\n", q{
          use strict;
          use warnings;
          use Path::Tiny qw( path );
          my($from, $to) = map { path($_) } @ARGV;
          $to->spew('[' . $from->slurp . ']');
        });
        
        path('install.pl')->spew("#!$^X\n", q{
          use strict;
          use warnings;
          use Path::Tiny qw( path );
          my($from, $to) = map { path($_) } @ARGV;
          $to->parent->mkpath;
          $from->copy($to);
          print "copy $from $to\n";
        });
        
        path('foo.c')->spew(
          "something",
        );

      };
      build [
        '%{make} foo.exe',
        '%{make} install PREFIX=%{.install.prefix}',
      ];
    };
  };
  
  eval {
    $Alien::Build::Plugin::Build::Make::VERSION = '0.01';
    $build->load_requires('configure');
    $build->load_requires($build->install_type);
  };
  skip_all 'test requires GNU Make or Alien::gmake' if $@;

  note "make = @{[ $build->meta->interpolator->interpolate('%{make}') ]}";

  my $alien = alien_build_ok;
  
  my $foo_exe = path($alien->bin_dir)->child('foo.exe');
  note "foo_exe = $foo_exe";
  note "content = ", $foo_exe->slurp;
  is($foo_exe->slurp, '[something]');

};

done_testing
