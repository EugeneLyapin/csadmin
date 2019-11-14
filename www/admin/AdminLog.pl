#!/usr/bin/perl

use strict;
use FindBin qw($Bin);
use Tt::Genpage;
use Tt::Pgen;
use Tt::Config;
use Tt::Cookies;
use Tt::Auth;
use Tt::CheckDate;

my $id="AdminLog";
my ($p,$config);

die("Sorry ... no data") if( not $config = Tt::Config->new('file'));
die("Sorry ... no data") if( not $p = Tt::Genpage->new('file'));

my $main = $config->getconfig('post',$id);
my $ud = checkcookies($main);
my $s = CheckValidUser($main,$main->{user},$id);
$main->{id} =$id;
gendata($main);
my $line = genfpagedata($main, $p);
print $line;
#showgetpostdata($main, 0);

sub gendata
{
    my $main = shift;
    my $action = getval($main, 'action');
    $action = $action || 'search';
    $main->{pay}->{f_year} = getval($main, 'f_year');
    $main->{pay}->{f_month} = getval($main, 'f_month');
    $main->{pay}->{f_day} = getval($main, 'f_day');
    $main->{pay}->{t_year} = getval($main, 't_year');
    $main->{pay}->{t_month} = getval($main, 't_month');
    $main->{pay}->{t_day} = getval($main, 't_day');
    $main->{search}->{error} = getval($main, 'checkbox_error');
    $main->{search}->{debug} = getval($main, 'checkbox_debug');
    $main->{search}->{regexp} = getval($main, 'regexp');
    $main->{action} = $action;
    my $ureg = "and event like '[E]%'";
    $ureg = "and event like '[D]%'" if $main->{search}->{debug};
    $ureg = " and event like '[E]%' or event like '[D]%'" if $main->{search}->{debug} and $main->{search}->{error};
    $ureg .= "and event like '%$main->{search}->{regexp}%'" if $main->{search}->{regexp};
    $main->{eventhash} = {
        showall => 'r',
        search => 'r',
        details => 'r',
        'delete' => 'del',
    };

    $main = AuthUserActionHash( $main, 'log', 'ObjectClass', $action );
    $main = checkcurdate($main);
    if($action eq 'search')
    {
        $main->{logdata} = $main->{dbcon}->getlog("
                            select
                                lid,
                                time,
                                event
                            from
                                log
                            where
                                ( cast(time as date)
                            between
                                '$main->{pdates}->{from}'
                                and '$main->{pdates}->{to}' )
                                $ureg order by time desc;
                            ");
        return;
    }
    return;
}

