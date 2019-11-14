#!/usr/bin/perl

use strict;
use FindBin qw($Bin);
use Tt::Genpage;
use Tt::Pgen;
use Tt::Config;
use Db::Dbgame;
use Cp::SrvCfg;
use Net::FTP;
use Tt::Ftp;
use LWP;
use HTTP::Request::Common;
use File::Basename qw(basename);
use CGI qw/:standard/;
use IO::File;
use Tt::Cookies;
use Tt::CryptPass;
use Tt::Auth;
use Tt::Error;
use Template;

$CGI::POST_MAX = 50000000;

my $id="AdminAddUser";
my ($p,$config);

my $debug=1 if param('datafile');
die("Sorry ... no data") if( not $config = Tt::Config->new('file'));
die("Sorry ... no data") if( not $p = Tt::Genpage->new('file'));

my $main = $config->getconfig('post',$id);
my $ud = checkcookies($main);
my $s = CheckValidUser($main,$main->{user},$id);
my $user = $main->{user};
$main = genarea($main);
my $line = genfpagedata($main, $p, 'AdminFtp');
print $line;

sub genarea
{
    my $main = shift;

    my $login = $main->{ftpc}->{siteuser};
    my $pass = $main->{ftpc}->{sitepass};
    my $host = $main->{ftpc}->{sitehost};

    $main->{ftp}->{login} = $login;
    $main->{ftp}->{pass} = $pass;
    $main->{ftp}->{host} = $host;

    $main->{datafile} = param('datafile');
    $main->{newdir} = param('newdir');
    $main->{action} = param('action');
    $main->{curdir} = param('curdir');
    $main->{file} = param('file') || '/';
    my $action = $main->{action};
    $main->{passform_enabled} = 1 if getval($main, 'changeftppass');
    $main->{form}->{ftppass1} = getval($main,'ftppass1') || 'x';
    $main->{form}->{ftppass2} = getval($main, 'ftppass2') || 'y';
    $action = 'changeftppass' if $main->{passform_enabled};
    $action = 'changeftppass' if $main->{form}->{ftppass1} eq $main->{form}->{ftppass2};
    $main->{eventhash} = {
        r => 'r',
        c => 'c',
        'rmdir' => 'del',
        'delete' => 'del',
        cd => 'r',
        get => 'r',
        changeftppass => 'w'
    };
    $main->{eventhash}->{c} = 'c' if $main->{newdir};
    $main->{eventhash}->{c} = 'c' if $main->{datafile};
    $action = 'c' if $main->{eventhash}->{c};
    $action = 'r' if $main->{eventhash}->{r};
    $action = 'c' if $main->{eventhash}->{c};
    $main = AuthUserActionHash( $main, 'ftpdata', 'ObjectClass', $action );

    $main = uploadfile($main) if ($main->{datafile});
    my $ftp = Net::FTP->new($host, Debug => 0) or $main->{errline} .= &errline(1,"Cannot connect to $host: $@");
    my $s = $ftp->login($login,$pass) or $main->{errline} .= &errline(1,"Cannot login to ftp server: <br>" .$ftp->message);
    return $main if $main->{errline};
    $main = &showmode($main, $ftp);
    return $main;
}
