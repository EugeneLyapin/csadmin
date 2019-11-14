#!/usr/bin/perl

use strict;
use FindBin qw($Bin);
use Tt::Genpage;
use Tt::Pgen;
use Tt::Config;
use Db::Dbgame;
use Cp::CreateProfile;
use File::Basename qw(basename);
use Tt::Cookies;
use Tt::Auth;
use Template;

my $debug=1;
my $id="AdminConfig";
my $url = basename($0);
my ($p,$config);

die("Sorry ... no data") if( not $config = Tt::Config->new('file'));
die("Sorry ... no data") if( not $p = Tt::Genpage->new('file'));

my $main = $config->getconfig('post',$id);
my $ud = checkcookies($main); $main->{user} = $ud->{login} || 'everyone';
my $s = CheckValidUser($main,$main->{user},$id);
my $user = $main->{user};
$main = gendata($main);
my $line = genfpagedata($main, $p);
print $line;
# showgetpostdata($main);

sub gendata
{
    my $main = shift;
    my $action = &getval($main,'action') || 'showall';
    my $ckey = &getval($main,'ckey');
    $action = 'lock' if getval($main, 'lock');
    $action = 'unlock' if getval($main, 'unlock');
    $action = 'saveckey' if getval($main, 'saveckey');
    $action = 'saveckey-new' if getval($main, 'saveckey-new');
    $main->{action} = $action;
    $main->{ckey} = $ckey;

    $main->{errline} .= Delckey($main, $ckey) if $action eq 'delckey';
    saveckey($main,$ckey) if $action eq 'saveckey';
    savenewckey($main) if $action eq 'saveckey-new';
    lockckey($main, $ckey) if $action eq 'lock';
    unlockckey($main, $ckey) if $action eq 'unlock';

    $main->{eventhash} = {
    lock => 'l',
    unlock => 'unlock',
    saveckey => 'w',
    'saveckey-new' => 'w',
    delckey => 'del',
    showall => 'r',
    addckey => 'c',
    editckey => 'w'
    };

    $main = AuthUserActionHash( $main, 'config', 'ObjectClass', $action );
    $main->{arrckey} = $main->{dbcon}->getsimplequery("select
                                                        ckey, cvalue, locked
                                                    from
                                                        config
                                                    ;");

    return $main;
}

sub lockckey
{
    my $main = shift;
    my $ckey = shift;
    my $s = $main->{dbcon}->insertsimplequery($main->{dbhlr}, "update config set locked=1 where ckey='$ckey'");
    return;
}
sub unlockckey
{
    my $main = shift;
    my $ckey = shift;
    my $s = $main->{dbcon}->insertsimplequery($main->{dbhlr}, "update config set locked=0 where ckey='$ckey'");
    return;
}

sub saveckey
{
    my $main = shift;
    my $ckey = shift;

    $main->{form}->{eeee}= 1;

    my $ckey = $main->{form}->{ckey};

    return 0 if not($ckey);

    return if(!($ckey ));
    my $s = $main->{dbcon}->insertsimplequery($main->{dbhlr}, "update
                                                                config
                                                            set
                                                                ckey = '$main->{form}->{ckey}',
                                                                cvalue = '$main->{form}->{cvalue}'
                                                            where
                                                                ckey='$main->{form}->{ckeyold}'
                                                                and locked=0;");
    return $s;
}


sub savenewckey
{
    my $main = shift;
    my $action = 'saveckey';
    my $cvalue = $main->{form}->{"cvalue-new"};
    my $ckey = $main->{form}->{"ckey-new"};
    $main->{form}->{eeee}= 1;
    return 0 if not($ckey);

    my $s = $main->{dbcon}->insertsimplequery($main->{dbhlr}, "insert into
                                                                config
                                                            set
                                                                ckey = '$ckey',
                                                                cvalue = '$cvalue',
                                                                locked=1
                                                            ;");
    return $s;
}

sub Delckey
{
    my $main = shift;
    my $ckey = shift;
    my $line;
    return if(!($ckey ));

    my $s = $main->{dbcon}->insertsimplequery($main->{dbhlr}, "delete from
                                                                config
                                                            where
                                                                ckey='$ckey'
                                                                and locked=0;");
    return $line;
}
