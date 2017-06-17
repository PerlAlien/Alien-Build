use Test2::Bundle::Extended;
use Alien::Build::Util::Win32::RegistryDump qw( _read_win32_reg_dump );

imported_ok '_read_win32_reg_dump';

skip_all => 'requires additional modules' unless Alien::Build::Util::Win32::RegistryDump::_load();

subtest basic => sub {

  my $openvpn = _read_win32_reg_dump('corpus/win32/openvpn.reg');

  use YAML ();
  note YAML::Dump($openvpn);

  is(
    $openvpn, 
    hash {
      field 'HKEY_LOCAL_MACHINE\\Software\\Microsoft\\Windows\\CurrentVersion\\Uninstall\\OpenVPN' => hash {
      
        field DisplayIcon => 'C:\\Program Files\\OpenVPN\\icon.ico';
        field DisplayName => 'OpenVPN 2.3.13-I601 ';
        field DisplayVersion => '2.3.13-I601';
        field tap => 'installed';
        field UninstallString => "C\0:\0\\\0P\0r\0o\0g\0r\0a\0m\0 \0F\0i\0l\0e\0s\0\\\0O\0p\0e\0n\0V\0P\0N\0\\\0U\0n\0i\0n\0s\0t\0a\0l\0l\0.\0e\0x\0e\0\0\0";
        field DWordTest => 0x09a07809;
      
      },
    },
  );

};

done_testing;
