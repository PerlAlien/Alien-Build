package Alien::Build::Plugin::Test::Mock;

use strict;
use warnings;
use Alien::Build::Plugin;
use Carp ();
use File::chdir;

=head1 SYNOPSIS

 use alienfile;
 plugin 'Test::Mock';

=head1 DESCRIPTION

This plugin is used for testing L<Alien::Build> plugins.  Usually you only want to test
one or two phases in an L<alienfile> for your plugin, but you still have to have a fully
formed L<alienfile> that contains all required phases.  This plugin lets you fill in the
other phases with the appropriate hooks.  This is usually better than using real plugins
which may pull in additional dynamic requirements that you do not want to rely on at
test time.

=head1 PROPERTIES

=head2 probe

 plugin 'Test::Mock' => (
   probe => $probe,
 );

Override the probe behavior by one of the following:

=over

=item share

For a C<share> build.

=item system

For a C<system> build.

=item die

To throw an exception in the probe hook.  This will usually cause L<Alien::Build>
to try the next probe hook, if available, or to assume a C<share> install.

=back

=cut

has 'probe';

=head2 download

 plugin 'Test::Mock' => (
   download => %fs_spec,
 );
 
 plugin 'Test::Mock' => (
   download => 1, 
 );

Mock out a download.  The C<%fs_spec> is a hash where the hash values are directories
and the string values are files.  This a spec like this:

 plugin 'Test::Mock' => (
   download => {
     'foo-1.00' => { 
       'README.txt' => "something to read",
       'foo.c' => "#include <stdio.h>\n",
                  "int main() {\n",
                  "  printf(\"hello world\\n\");\n",
                  "}\n",
     }
   },
 );

Would generate two files in the directory 'foo-1.00', a C<README.txt> and a C file named C<foo.c>.
The default, if you provide a true non-hash value is to generate a single tarball with the name
C<foo-1.00.tar.gz>.

=cut

has 'download';

sub init
{
  my($self, $meta) = @_;
  
  if(my $probe = $self->probe)
  {
    if($probe =~ /^(share|system)$/)
    {
      $meta->register_hook(
        probe => sub {
          $probe;
        },
      );
    }
    elsif($probe eq 'die')
    {
      $meta->register_hook(
        probe => sub {
          die "fail";
        },
      );
    }
    else
    {
      Carp::croak("usage: plugin 'Test::Mock' => ( probe => $probe ); where $probe is one of share, system or die");
    }
  }
  
  if(my $download = $self->download)
  {
    $download = { 'foo-1.00.tar.gz' => _tarball() } unless ref $download eq 'HASH';
    $meta->register_hook(
      download => sub {
        _fs($download);
      },
    );
  }
}

sub _fs
{
  my($hash) = @_;
  
  foreach my $key (sort keys %$hash)
  {
    my $val = $hash->{$key};
    if(ref $val eq 'HASH')
    {
      mkdir $key;
      local $CWD = $key;
      _fs($val);
    }
    elsif(defined $val)
    {
      Path::Tiny->new($key)->spew($val);
    }
  }
}

sub _tarball
{
  return unpack 'u', <<'EOF';
M'XL(`+DM@5@``^V4P4K$,!"&>YZGF-V]J*SM9#=)#RN^B'BHV;0)U`32U(OX
M[D;0*LJREZVRF.\R?TA@)OS\TWI_S4JBJI@/(JJ%P%19+>AKG4"V)4Z;C922
M(;T=6(%BQIDFQB$V(8WB^]X.W>%WQ^[?_S'5,Z']\%]YU]IN#/KT/8[ZO^6?
M_B=-C-=<%$BG'^4G_]S_U:)ZL*X:#(!6QN/26(Q&![W<P5_/EIF?*?])E&J>
M'BD/DO/#^6<DON__6O*<_]]@99WJQ[W&FR'NK2_-+8!U$1X;ZRZ2P"9T:HW*
D-`&ODGZZN[^$9T`,.H[!(>W@)2^*3":3.3]>`:%LBYL`#@``
`
EOF
}

1;
