#!/usr/bin/perl

use strict;
use FindBin qw($Bin);
use Tt::Genpage;
use Tt::Pgen;
use Tt::Config;
use Cp::CreateProfile;
use Tt::Cookies;
use Tt::Auth;
use Template;

my $debug=1;
my $id="AdminCreateProfile";
my ($p,$config);
die("Sorry ... no data") if( not $config = Tt::Config->new('file'));
die("Sorry ... no data") if( not $p = Tt::Genpage->new('file'));

my $main = $config->getconfig('post',$id);
my $ud = checkcookies($main);
my $s = CheckValidUser($main,$main->{user},$id);
my $user = $main->{user};
$main->{eventhash} = { create => 'c' };
$main = AuthUserActionHash( $main, 'user', 'ObjectClass', 'create' );
$main = UserProfileForm($main, 1);
my $line = genfpagedata($main, $p, 'CreateProfile');
print $line;
