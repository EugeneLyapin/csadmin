#!/usr/bin/perl

use strict;
use FindBin qw($Bin);
use Tt::Genpage;
use Tt::Pgen;
use Cp::SrvCfg;
use Cp::Profile;
use Tt::Config;
use Db::Dbgame;
use File::Basename qw(basename);
use Tt::Cookies;
use Tt::CryptPass;
use Tt::Auth;
use Template;

my $debug=1;
my $id="AdminGetProfile";
my ($user, $p,$config,$main, $sc, $col, $cvol);
my $url = basename($0);

die("Sorry ... no data") if( not $config = Tt::Config->new('file'));
die("Sorry ... no data") if( not $p = Tt::Genpage->new('file'));

my $main = $config->getconfig('post',$id);
my $ud = checkcookies($main);
my $s = CheckValidUser($main,$main->{user},$id);
#$main->{user} = 'admin';
my $user = $main->{user};
maskuser($main);
redir_location($main, 'addsrv', 'AdminSrvCreate.pl');
redir_location($main, 'viewsrv', 'AdminSrvControl.pl');
redir_location($main, 'payments', 'AdminPayment.pl');

my $hline = $p->header();
$main = gendata($main);
my $dline = undef;
$dline = gen_file_data($main, 'AdminGetProfile') unless $main->{action} eq 'editprofile';
$dline = gen_file_data($main, 'EditProfile') if $main->{action} eq 'editprofile';
my $line = $p->getpagevalue($main);
$line = $p->genpage($main,$line,$dline);
$line = gendbtemplate($main, undef, $line);
$line = formatline($line);
print $hline.$line;

sub gendata
{
    my $main = shift;
    my $url = shift;
    my $line;
    my ($userid,$action);
    $action = getval($main,'action') || 'showall';
    $userid = getval($main,'userid');
    $action = 'deluserbyuserid' if $main->{form}->{"deleteuser-$userid"};

    $main->{eventhash} = {
        editprofile => 'w',
        deluser => 'del',
        deluserbyuserid => 'del',
        lock => 'l',
        unlock => 'unlock',
        enable => 'en',
        disable => 'disable',
        showall => 'r',
        delete => 'del',
        editprofile => 'w',
    };
    $main = AuthUserActionHash( $main, 'user', 'ObjectClass', $action );
    if($main->{form}->{"submitaction"})
    {
        my $a = "action-$main->{form}->{userid}";
        $action = $main->{form}->{$a};
        $main = checkusergroupweight($main, $userid) if $action eq 'editprofile';
        $main = edituserprofile($main) if($action eq 'editprofile');
        $main = getusers($main) if($action eq 'showall');

        if($action eq 'deluser')
        {
            $main = checkusergroupweight($main, $userid);
            $main->{errline} .= DelUser($main, $userid);
            $main = getusers($main);
        }
        return $main;
    }

    if($main->{form}->{"deleteuser-$userid"})
    {
        $main = checkusergroupweight($main, $userid);
        $main->{errline} .= DelUser($main, $userid);
        $main = getusers($main);
        return $main;
    }

    if($action eq 'editprofile' or $main->{form}->{submit})
    {
        $main = checkusergroupweight($main, $userid);
        $main = edituserprofile($main,$url);
        return $main;
    }

    if($action eq 'disable' or $action eq 'enable')
    {
        $main = checkusergroupweight($main, $userid);
        $main->{errline} .= enableuser($main,$action,$userid);
        $main = getusers($main);
        return $main;
    }
    else
    {
        $main = getusers($main) if $action eq 'showall';
    }
    return $main;
}

sub maskuser
{
    my $main = shift;
    my $location;
    my $s;

    return if not ($main->{form}->{"submitaction"});

    my $userid = &getval($main,'userid');
    my $a = "action-$userid";
    my $action = $main->{form}->{$a};

    if($action eq 'mask')
    {
        $location = '/CP/';
    }
    else
    {
        return;
    }

    $s = $main->{dbcon}->insertsimplequery($main->{dbhlr}, "
            update
                session as s, user as u
            set
                s.userid = '$userid'
            where
                u.userid = s.userid
                and u.login = 'admin'
            ");
    print "Location: $location\n\n";
    return $s;
}

sub redir_location
{
    my $main = shift;
    my $o_action = shift;
    my $o_location = shift;
    my $location;
    my $s;

    return if not ($main->{form}->{"submitaction"});

    my $userid = &getval($main,'userid');
    my $a = "action-$userid";
    my $action = $main->{form}->{$a};

    if($action eq $o_action)
    {
        $location = $o_location;
    }
    else
    {
        return;
    }

    print "Location: $location?userid=$userid\n\n";

    return $s;
}

sub enableuser
{
    my $main = shift;
    my $action = shift;
    my $userid = shift;
    my $status = 1;
    $status = 0 if($action eq 'disable');
    my $s = $main->{dbcon}->insertsimplequery($main->{dbhlr}, "
                update
                    user
                set
                    enabled = '$status'
                where
                    userid='$userid'
                    and login != '$main->{global}->{superuser}'
                ");
    return $s;
}

sub getusers
{
    my $main = shift;
    $main->{muser} = $main->{dbcon}->getsimplequery("
                        select
                            u.userid as userid,
                            u.login,
                            u.sname,
                            u.fname,
                            u.name,
                            u.email,
                            u.enabled,
                            (select count(sid) from srv where userid=u.userid) as count
                        from
                            user as u;
                        ");
    $main->{details} = 1;
    return $main;
}
