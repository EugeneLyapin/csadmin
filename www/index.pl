#!/usr/bin/perl

use strict;
use FindBin qw($Bin);
use Tt::Genpage;
use Tt::Config;
use Db::Dbgame;
use Tt::Genpost;
use Tt::Pgen;
use Tt::Cookies;
use Tt::Auth;
use Template;
use Cp::SrvInfo;


my ($p,$config,$main);

die("Sorry ... no data") if( not $config = Tt::Config->new('file'));
die("Sorry ... no data") if( not $p = Tt::Genpage->new('file'));
my $main = $config->getconfig('post');
my $ud = checkcookies($main);
my $hline = $p->header();
gendata($main);
my ($cline,$pflag) = $p->getpostvalue($main);
$cline = genpost($main,$cline) if($cline and $pflag);
$cline = showarticles($main) if not $cline;
$cline = showindex($main) if ($main->{id} eq 'index');
my $line = $p->getpagevalue($main);
$line = $p->genpage($main,$line,'<content>',undef,undef);
$line = $p->gencontent($line,'<content>',$cline);
$line = gendbtemplate($main, undef, $line);
$line = formatline($line);
print $hline;
print $line;

sub gendata
{
    my $main = shift;
    my $user = $main->{user} ;
    my $userid = useridbyuser($main, $user);
    my $acc = $main->{dbcon}->getsimplequeryhash("select p.summ,c.name
                                                    from PersonalAccounts as p, currency as c
                                                        where c.CurrId=p.CurrId
                                                        and p.enabled=1
                                                        and p.userid='$userid'") unless $user eq 'everyone';
    $main->{userinfo}->{summ} = $acc->{summ} || 0;
    $main->{userinfo}->{CurrName} = $acc->{name} || 'WME';
    $main->{userinfo}->{id} = $main->{id};
    return $main;
}

