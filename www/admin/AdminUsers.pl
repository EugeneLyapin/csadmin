#!/usr/bin/perl

use strict;
use FindBin qw($Bin);
use Tt::Genpage;
use Tt::Pgen;
use Cp::SrvCfg;
use Cp::Profile;
use Cp::AddUser;
use Tt::Config;
use Db::Dbgame;
use File::Basename qw(basename);
use Tt::Cookies;
use Tt::CryptPass;
use Tt::Auth;
use Tt::Error;
use Template;
use Data::Dumper;
use XML::Simple;

my $id="AdminUsers";
my ($p,$config,$main);

die("Sorry ... no data") if( not $config = Tt::Config->new('file'));
die("Sorry ... no data") if( not $p = Tt::Genpage->new('file'));

my $main = $config->getconfig('post',$id);
my $ud = checkcookies($main);
my $s = CheckValidUser($main,$main->{user},$id);
my $user = $main->{user};
$main->{id} =$id;
$main = gendata($main);
my $line = genfpagedata($main, $p);
print $line;
#showgetpostdata($main,0);

sub gendata
{
    my $main = shift;
    my $line;
    my $s;
    my $action = getval($main,'action') || 'showall';
    my $userid = getval($main,'userid') ;
    $action = 'new' if getval($main, 'new');
    $action = 'save' if getval($main, 'change');
    $action = 'save' if getval($main, 'save');
    $action = 'lock' if getval($main, 'lock');
    $action = 'unlock' if getval($main, 'unlock');
    $action = 'enable' if getval($main, 'enable');
    $action = 'disable' if getval($main, 'disable');
    $action = 'enablegroup' if getval($main, 'enablegroup');
    $action = 'disablegroup' if getval($main, 'disablegroup');
    $action = 'show' if getval($main, 'show');
    $action = 'delete' if getval($main, 'delete');
    $action = 'editprofile' if getval($main, 'editprofile');

    $main->{form}->{userid} = $userid;
    $main->{form}->{raction} = $action;
    $main->{form}->{userform} = getval($main, 'userform') || 1;
    $main->{form}->{login} = getval($main, 'login');
    $main->{form}->{gname} = getval($main, 'gname');
    $main->{form}->{pass1} = getval($main, 'pass1');
    $main->{form}->{pass2} = getval($main, 'pass2');
    $main->{xml} = XML::Simple->new();

    $main->{eventhash} = {
        new => 'c',
        change => 'w',
        save => 'w',
        lock => 'l',
        unlock => 'unlock',
        enable => 'en',
        disable => 'disable',
        enablegroup => 'w',
        disablegroup => 'w',
        show => 'r',
        showall => 'r',
        delete => 'del',
        editprofile => 'w',
        disablegroup => 'chgroup',
        enablegroup => 'chgroup'
    };

    $main = AuthUserActionHash( $main, 'user', 'ObjectClass', $action );

    if($action eq 'editprofile')
    {
        print "Location: AdminGetProfile.pl?userid=$userid&action=editprofile\n\n" if $userid;
    }

    if($action eq 'enablegroup' or $action  eq 'disablegroup')
    {
        #$main = checkusergroupweight($main, $userid);
        #$main = checkgroupweight($main);
        #$main = getaclhash($main, $userid);
        my $gname = $main->{form}->{gname};
        $main->{aclh}->{role}->{$gname} = 1 if $action eq 'enablegroup';
        delete $main->{aclh}->{role}->{$gname} if $action eq 'disablegroup';
        setmaxweight($main, $userid);
        $main = changeaclhash($main, $userid);
    }
    if($action eq 'save')
    {
        $main = checkformdata($main);
        $main = checkusergroupweight($main, $userid) if $userid;
        saveuser($main, $userid) unless $main->{errline};
    }
    if($action eq 'delete')
    {
        $main = checkusergroupweight($main, $userid);
        $main = deleteuser($main, $userid);
        $main = userform($main, 'fake');
        return $main;
    }
    if($action eq 'new')
    {
        undef $main->{form}->{login};
        undef $main->{form}->{userid};
        $main = userform($main);
        return $main;
    }
    if($action eq 'enable' or $action  eq 'disable')
    {
        $main = checkusergroupweight($main, $userid);
        enableuser($main, $action, $userid);
    }
    if($action eq 'lock' or$action eq 'unlock' )
    {
        $main = checkusergroupweight($main, $userid);
        $s = $main->{dbcon}->insertsimplequery($main->{dbhlr}, "
                update
                    user
                set
                    locked=1
                where
                    userid='$userid'
                ") if $action eq 'lock';
        $s = $main->{dbcon}->insertsimplequery($main->{dbhlr}, "
                update
                    user
                set
                    locked=0
                where
                    userid='$userid'
                ") if $action eq 'unlock';
    }
    if($action eq 'showall')
    {
        $main = userform($main, 'fake');
        return $main;
    }
    $main = userform($main, $userid);
    return $main;
}
sub setmaxweight
{
    my $main = shift;
    my $userid = shift;
    my $w = 0;
    foreach my $s (keys %{$main->{aclh}->{role}})
    {
        my $q = $main->{dbcon}->getsimplequeryhash("
                    select
                        weight
                    from
                        groups
                    where
                        gname = '$s'
                    ");
        $w = $q->{weight} if $q->{weight} > $w;
    }
    my $q = $main->{dbcon}->getsimplequeryhash("
                update
                    user
                set
                    weight='$w'
                where
                    userid='$userid'
                ");

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

sub deleteuser
{
    my $main = shift;
    my $userid = shift;
    $main->{errline} .= errline(1, "You can not delete SUPERUSER") if $main->{global}->{superuser} eq $main->{form}->{login};
    return $main if $main->{errline};
    my $s = $main->{dbcon}->insertsimplequery($main->{dbhlr}, "
                delete
                from
                    user
                where
                    userid='$userid'
                    and login != '$main->{global}->{superuser}'
                ");
    return $main;
}

sub checkformdata
{
    my $main = shift;
    my $opts=();
    my $errline;

    $opts->{login} = $main->{form}->{login};
    $opts->{email} = $main->{form}->{email};

    my $rtmpl = {
        'login' => q/^[A-z][A-z0-9\.]+$/,
        'email' => q/^[A-z0-9\.]+\@[A-z0-9\.]+$/,
    };

    $errline .= &checkoptions (options => $opts, templates => $rtmpl);
    $errline .= &errline(1,"Пароли не совпадают ...") if(!($main->{form}->{pass1} eq $main->{form}->{pass2}));
    $errline .= &errline(1,"Длина пароли должна быть не менее 8 символов ... ") if(length($main->{form}->{pass1})>=1 and length($main->{form}->{pass1})<=8);
    $main->{errline} .= $errline;
    return $main ;
}

sub saveuser
{
    my $main = shift;
    my $userid = shift;

    if ($main->{form}->{firstcreated} eq 1)
    {
        savenewuser($main);
        return $main;
    }
    return $main unless $userid;
    my $s = $main->{dbcon}->insertsimplequery($main->{dbhlr}, "
                update
                    user
                set
                    login = '$main->{form}->{login}'
                where
                    userid='$userid'
                    and login != '$main->{global}->{superuser}'
                ");
    return $main;
}


sub userform
{
    my $main = shift;
    my $userid = shift;
    my $muid = $main->{dbcon}->getsimplequery("
                select
                    userid,
                    login
                from
                    user;
                ");

    for my $ss (sort keys %{$muid})
    {
        $userid = $muid->{$ss}->[0] if $userid eq 'fake';
        last if $userid > 0;
    }
    $userid = $userid || $main->{dbcon}->getuserid($main->{form}->{login});
    $main->{form}->{userid} = $userid;
    $main->{form}->{raction} = 'new' unless $userid;
    $main = getuserinfo($main, $userid);
    $main->{muser} = $muid;
    return $main;
}

sub getuserinfo
{
    my $main = shift;
    my $userid = shift;
    my $mgid;
    return $main unless $userid;
    my $gid = $main->{dbcon}->getsimplequery("
                select
                    gid,
                    gname,
                    description
                from
                    groups
                where
                    enabled=1
                ");
    foreach my $ss (keys %{$gid})
    {
        $mgid->{$ss}->{gid} = $gid->{$ss}->[0];
        $mgid->{$ss}->{gname} = $gid->{$ss}->[1];
        $mgid->{$ss}->{description} = substr($gid->{$ss}->[2],0,50);
        $mgid->{$ss}->{description} = join(' ',$mgid->{$ss}->{description}, '...') if(length($mgid->{$ss}->{description}) == 50);
    }
    my $ruserid = $main->{dbcon}->getsimplequeryhash("
                    select
                        userid,
                        login,
                        enabled,
                        role,
                        locked
                    from
                        user
                    where
                        userid='$userid';
                    ");

    $main->{userinfo} = $ruserid;
    $main->{mgid} = $mgid;
    $main = getaclhash($main, $userid);
    return $main;

}

sub changeaclhash
{
    my $main = shift;
    my $userid = shift;

    $main->{aclh} = createroothash($main) unless ( ishash $main->{aclh});
    my $rhash = $main->{aclh} || undef;
    $main->{form}->{rhash} = genhashtoxml($main, $rhash);
    $s = $main->{dbcon}->insert1linequery($main->{dbhlr}, "
            update
                user
            set
                role = ?
            where
                userid='$userid'
                and locked=0;", $main->{form}->{rhash});
    return $main;
}

sub savenewuser
{
        my $main = shift;
        my ($pwd,$salt) = cryptpass($main->{form}->{pass1});
        $main->{dbcon}->insertuser($main->{form}->{login},$pwd, $salt, $main->{form}->{email}, '0');
        $main->{dbcon}->insertsimplequery($main->{dbhlr}, "
            update
                user
            set
                role='<rhash><role fakerole=\"1\" /></rhash>' ,
                weight=0
            where
                login='$main->{form}->{login}';
            ");
    return $main;
}
