use Test2::Bundle::Extended;
use Alien::Base2 ();
use lib 'corpus/lib';
use Path::Tiny qw( path );

{
  package FFI::CheckLib;
  $INC{'FFI/CheckLib.pm'} = __FILE__;
  sub find_lib {
    my %args = @_;
    if($args{libpath})
    {
    }
    else
    {
      if($args{lib} eq 'foo')
      {
        return ('/usr/lib/libfoo.so', '/usr/lib/libfoo.so.1');
      }
      else
      {
        return;
      } 
    }
  }
}

subtest 'system' => sub {

  require Alien::libfoo1;
  
  is( -f path(Alien::libfoo1->dist_dir)->child('_alien/for_libfoo1'), T(), 'dist_dir');
  is( Alien::libfoo1->cflags, '-DFOO=1', 'cflags' );
  is( Alien::libfoo1->cflags_static, '-DFOO=1 -DFOO_STATIC=1', 'cflags_static');
  is( Alien::libfoo1->libs, '-lfoo', 'libs' );
  is( Alien::libfoo1->libs_static, '-lfoo -lbar -lbaz', 'libs_static' );
  is( Alien::libfoo1->version, '1.2.3', 'version');
  
  subtest 'install type' => sub {
    is( Alien::libfoo1->install_type, 'system' );
    is( Alien::libfoo1->install_type('system'), T() );
    is( Alien::libfoo1->install_type('share'), F() );
  };
  
  is( Alien::libfoo1->config('name'), 'foo', 'config.name' );
  is( Alien::libfoo1->config('finished_installing'), T(), 'config.finished_installing' );

  is( [Alien::libfoo1->dynamic_libs], ['/usr/lib/libfoo.so','/usr/lib/libfoo.so.1'], 'dynamic_libs' );
  
  is( [Alien::libfoo1->bin_dir], [], 'bin_dir' );
};

done_testing;
