#!/usr/bin/perl

use strict;
use FindBin qw($Bin);
use Tt::Genpage;
use Tt::Pgen;
use Tt::Config;

my $debug=1;
my $id="test";
my ($p,$config,$main, $sc, $col, $cvol, $fstatus);


die("Sorry ... no data") if( not $config = Tt::Config->new('file'));
die("Sorry ... no data") if( not $p = Tt::Genpage->new('file'));
$main->{user} = 'everyone';
my $main = $config->getconfig('post',$id, 1);

my $hline = $p->pheader();
print $hline;
$main = gendata($main);
#$main->{global}->{debug} = 3;
#showhash($main, $main->{srvtimes}, 'formatted');
print $main->{stoplist};

sub gendata
{
    my $main = shift;
    my $srv = shift;
    my $srvtimes = $main->{dbcon}->getsimplequery("select periodid,ename from period;");
    $main->{srvtimes} = $srvtimes;
    my $str = 'Got it!';
    $str = "<option value=1>dweew</option>";
    return $str;
}
