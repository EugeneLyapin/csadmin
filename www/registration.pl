#!/usr/bin/perl

use strict;
use FindBin qw($Bin);
use Tt::Genpage;
use Tt::Pgen;
use Tt::Config;
use Db::Dbgame;
use Cp::CreateProfile;
use Tt::Cookies;
use Tt::Auth;
use Template;

my $debug=1;
my $id="registration";
my ($p,$config);

die("Sorry ... no data") if( not $config = Tt::Config->new('file'));
die("Sorry ... no data") if( not $p = Tt::Genpage->new('file'));
my $main = $config->getconfig('post',$id, 1);
my $s = CheckValidUser($main,$main->{user},$id);

my $hline = $p->header();
$main->{addlogin} = 1;
$main->{id} = $id;
$main = UserProfileForm($main, $main->{addlogin});
my $line = genfpagedata($main, $p, 'CreateProfile');
print $line;
# showgetpostdata($main);

