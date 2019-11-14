package Tt::CryptPass;

use strict;
use Exporter;
use FindBin qw($Bin);
use base qw( Exporter );
use Crypt::PasswdMD5 qw(unix_md5_crypt);
our @EXPORT = qw( cryptpass );


sub cryptpass
{
    my $pass = shift;
    my $salt = shift;

    $salt = &gensalt(8) if not defined($salt);

    my %encrypted;
    $pass = "qwertyuiopasdfghjklzxcvbnmQWERTYUIOPASDFGHJKLZXCVBNM1234567890" if(not defined($pass));
    $pass = &randompass($pass);
    #    my $cryptpwd = crypt($t, &salt);
    $encrypted{md5} = unix_md5_crypt( $pass, $salt );
    return($encrypted{md5}, $salt);
}

sub randompass
{
    my $pass = shift;
    srand(time()+$$);
    my $t = "";
    for (1..6)
    {
        my $c = int(rand(length($pass)));
        $t =  $t . substr($pass,$c,1);
    }

    return($pass);
}


sub gensalt
{
    my $count = shift;
    my ($salt);
    my ($i, $rand);
    my (@itoa64) = ( 0 .. 9, "a" .. "z", "A" .. "Z" );

    # to64
    for ($i = 0; $i < $count; $i++) {
        srand(time + $rand + $$);
        $rand = rand(25*29*17 + $rand);
        $salt .=  $itoa64[$rand & $#itoa64];
    }

    return $salt;
}


1;

