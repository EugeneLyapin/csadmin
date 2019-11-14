#!/usr/bin/perl

use strict;
use FindBin qw($Bin);
use Tt::Genpage;
use Tt::Pgen;
use Tt::Error;
use Cp::SrvCfg;
use Cp::SrvInfo;
use Tt::Config;
use Db::Dbgame;
use File::Basename qw(basename);
use Tt::Cookies;
use Tt::Auth;
use Template;

my $id="AdminGenpage";
my ($p,$config);

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
#showgetpostdata($main, 0);

sub gendata
{
    my $main = shift;
    my $line;
    my $s;
    my $action = &getval($main,'action') || 'showall';
    my $pid = &getval($main,'pageid');
    my $owner = &getval($main,'owner');
    $main->{action} = $action;
    $action = 'deletepage' if (getval($main, 'deletepage'));
    $action = 'newpage' if (getval($main, 'newpage'));
    $action = 'savepage' if (getval($main, 'savepage'));
    $action = 'savepage' if (getval($main, 'changepage'));
    $action = 'showpage' if (getval($main, 'showpage'));
    $action = 'lockpage' if (getval($main, 'lockpage'));
    $action = 'unlockpage' if (getval($main, 'unlockpage'));
    $main->{p}->{pageform} = getval($main, 'pageform');
    $main->{p}->{raction} = $action;
    $main->{p}->{pageid} = $pid;
    $main->{p}->{owner} = $owner;
    $main->{p}->{pform} = getval($main, 'pform');
    $main->{p}->{oldowner} = getval($main, 'oldowner');
    $main->{p}->{pageform} = 0 if $action eq 'showall';

    $main->{eventhash} = {
        deletepage => 'del',
        newpage => 'c',
        savepage => 'w',
        showpage => 'w',
        lockpage => 'l',
        unlockpage => 'unlock',
        disable => 'w',
        enable => 'w',
        chowner => 'chowner',
        changegroup => 'w',
        showall => 'r'
    };
    my $q = $main->{dbcon}->getsimplequeryhash("
                select
                    name
                from
                    page
                where
                    pageid='$pid'
                ") if $pid;
    my $pname = $q->{name} || $main->{id};
    $pname = 'ObjectClass' if $action eq 'newpage';
    $main->{p}->{pname} =$pname;
    $main = AuthUserActionHash( $main, 'page', $pname, $action );
    return $main unless $main->{status_flag} eq 'ok';

    if($action eq 'disable' or $action eq 'enable')
    {
        checkw($main, $pid);
        enablepage($main,$action,$pid);
        $main->{p}->{pageform} = 0;
    }
    if($action eq 'deletepage')
    {
        checkw($main, $pid);
        deletepage($main,$pid);
        $main->{p}->{pageform} = 0;
    }

    if($action eq 'lockpage' or $action eq 'unlockpage')
    {
        checkw($main, $pid);
        $s = $main->{dbcon}->getsimplequery("
                update
                    page
                set
                    locked=1
                where
                    pageid='$pid'
                ") if($action eq 'lockpage');
        $s = $main->{dbcon}->getsimplequery("
                update
                    page
                set
                    locked=0
                where
                    pageid='$pid'
                ") if($action eq 'unlockpage');
        if ( $main->{p}->{pageform} eq  1)
        {
            $main = pageform($main, $pid);
            return $main;
        }
        $main->{p}->{pageform} = 0;
    }

    if($action eq 'savepage')
    {
        $main = checkformdata($main) ;

        if($pid)
        {
            checkw($main, $pid);
            changepageinfo($main,$pid) if($pid >0);
            chowner($main, $pid);
            $main = pageform($main,$pid);
        }
        else
        {
            addpage($main) if not($pid);
            $main = pageform($main,$pid);
        }
        return $main;
    }

    if($action eq 'showpage')
    {
        $main = pageform($main,$pid);
        return $main;
    }

    if($action eq 'newpage')
    {
        $main = pageform($main);
        return $main;
    }

    $main = getpages($main);
    return $main;

}

sub enablepage
{
    my $main = shift;
    my $action = shift;
    my $pageid = shift;
    my $status = 1;
    $status = 0 if($action eq 'disable');

    return if(!($pageid ));

    my $s = $main->{dbcon}->insertsimplequery($main->{dbhlr}, "
                update
                    page
                set
                    enabled = '$status'
                where
                    pageid='$pageid'
                    and ( locked=0 or locked is NULL);
                ");
    return $s;
}

sub deletepage
{
    my $main = shift;
    my $pageid = shift;
    my $status = 1;

    return unless $pageid;

    my $s = $main->{dbcon}->getsimplequery("
                delete
                from
                    page
                where
                    pageid='$pageid'
                    and ( locked=0 or locked is NULL );
                ");
    return $s;
}

sub chowner
{
    my $main = shift;
    my $pageid = shift;
    return $main if $main->{p}->{owner} eq $main->{p}->{oldowner};
    $main->{eventhash}->{chowner} = 'chowner';
    $main = AuthUserActionHash( $main, 'page', $main->{p}->{pname}, 'chowner' );
    my $s = $main->{dbcon}->insertsimplequery($main->{dbhlr}, "
                update
                    page
                set
                    owner='$main->{p}->{owner}'
                where
                    pageid='$pageid'
                    and ( locked=0 or locked is NULL) ;
                ");
    return $s;
}

sub pageform
{
    my $main = shift;
    my $pageid = shift;
    my $pageinfo;
    my $line;
    my $mpageid;

    my $rpid = $main->{dbcon}->getsimplequeryhash("select pageid from
                    page where name='$main->{form}->{name}';")
                            unless $main->{form}->{pageid};
    $pageid = $pageid || $rpid->{pageid};
    $main->{p}->{pageid} = $pageid;
    $main->{p}->{raction} = 'newpage' unless $pageid;
    $mpageid = $main->{dbcon}->getsimplequery("
                    select
                        pageid,
                        name,
                        description,
                        pttid,
                        cheader,
                        enabled,
                        gids,
                        locked,
                        owner
                    from
                        page;
                    ") if($pageid);
    my $rpage = $main->{dbcon}->getsimplequery("
                    select
                        pageid,
                        name,
                        description,
                        pttid,
                        cheader,
                        value,
                        ftemplate,
                        enabled,
                        gids,
                        locked,
                        owner
                    from
                        page
                    where
                        pageid='$pageid'
                    ");

    for my $s (sort keys %{$rpage})
    {
        if($s)
        {
            $pageinfo->{pageid} = $rpage->{$s}->[0];
            $pageinfo->{name} = $rpage->{$s}->[1];
            $pageinfo->{description} = $rpage->{$s}->[2];
            $pageinfo->{pttid} = $rpage->{$s}->[3];
            $pageinfo->{cheader} = $rpage->{$s}->[4];
            $pageinfo->{value} = $rpage->{$s}->[5];
            $pageinfo->{ftemplate} = $rpage->{$s}->[6];
            $pageinfo->{enabled} = $rpage->{$s}->[7];
            $pageinfo->{gids} = $rpage->{$s}->[8];
            $pageinfo->{locked} = $rpage->{$s}->[9];
            $pageinfo->{owner} = $rpage->{$s}->[10];
        }
    }

    my $muid;
    my $p_uid = $main->{dbcon}->getsimplequery("
                    select
                        userid,
                        login
                    from
                        user;
                    ");

    for my  $ss (sort keys %{$p_uid})
    {
        $muid->{$ss}->{userid} = $p_uid->{$ss}->[0];
        $muid->{$ss}->{login} = $p_uid->{$ss}->[1];
        $muid->{$ss}->{selected} = undef;
        $muid->{$ss}->{selected} = 'selected' if $muid->{$ss}->{userid} eq $pageinfo->{owner};
    }

    $main->{muid} = $muid;
    $main->{pinfo} = $pageinfo;
    $main->{mpageid} = $mpageid;
    return $main;
}


sub checkformdata
{
    my $main = shift;
    my $errline = '';
    return $main unless defined($main->{form}->{pageid});
    return $main unless defined($main->{form}->{action});

    my $mp;

    $errline .= checkval('rname',$main->{form}->{name}, q/^[A-z0-9\.\-\_]+$/);
    $errline .= checkval('regname',$main->{form}->{description}, q/[\S]/);
    $errline .= checkval('value',$main->{form}->{cheader}, q/[\S]/);
    $main->{errline} = $errline;
    return $main if($errline);

    $errline .= $p->checkpage($main,$main->{form}->{value},'main',$mp);
    $main->{errline} = $errline;
    return $main if $errline;
    return $main;

}


sub changepageinfo
{
    my $main = shift;
    my $pageid = shift;
    return $main if(not $pageid and not $main->{action});
    return $main if($main->{errline});
    foreach my $b (keys %{$main->{form}})
    {
        $main->{form}->{gids} .= "$main->{form}->{$b};" if($b =~ /^chbox/);
    }

    my $s = $main->{dbcon}->insert1linequery($main->{dbhlr}, "
                update
                    page
                set
                    name='$main->{form}->{name}',
                    pttid='$main->{form}->{pttid}',
                    cheader='$main->{form}->{cheader}',
                    description='$main->{form}->{description}',
                    ftemplate='$main->{form}->{ftemplate}',
                    gids='$main->{form}->{gids}',
                    value= ?
                where
                    pageid='$pageid'
                    and locked=0",$main->{form}->{value});
    return $main;
}


sub addpage
{
    my $main = shift;

    return $main if($main->{errline});
    my $userid = useridbyuser($main, $main->{user});
    foreach my $b (keys %{$main->{form}})
    {
        $main->{form}->{gids} .= "$main->{form}->{$b};" if($b =~ /^chbox/);
    }

    my $s = $main->{dbcon}->insert1linequery($main->{dbhlr}, "
                insert into
                    page
                set
                    name='$main->{form}->{name}',
                    pttid='$main->{form}->{pttid}',
                    cheader='$main->{form}->{cheader}',
                    description='$main->{form}->{description}',
                    ftemplate='$main->{form}->{ftemplate}',
                    enabled='1',
                    locked=0,
                    ObjectClass='page',
                    owner='$userid',
                    value=? ;",$main->{form}->{value});

    return $main;

}


sub getpages
{
    my $main = shift;
    my $line;
    my $pgid;

    my $pageid = $main->{dbcon}->getsimplequery("
                    select
                        pageid,
                        name,
                        description,
                        pttid,
                        cheader,
                        enabled,
                        gids,
                        locked,
                        owner
                    from
                        page;
                    ");
    for my  $ss (sort keys %{$pageid})
    {
        if($ss)
        {
            $pgid->{$ss}->{pageid} = $pageid->{$ss}->[0];
            $pgid->{$ss}->{name} = $pageid->{$ss}->[1];
            $pgid->{$ss}->{description} = $pageid->{$ss}->[2];
            $pgid->{$ss}->{cheader} = $pageid->{$ss}->[4];
            $pgid->{$ss}->{enabled} = $pageid->{$ss}->[5];
            $pgid->{$ss}->{gids} = $pageid->{$ss}->[6];
            $pgid->{$ss}->{locked} = $pageid->{$ss}->[7];
            $pgid->{$ss}->{owner} = $pageid->{$ss}->[8];
            $pgid->{$ss}->{'action_enabled'} = 'enable';
            $pgid->{$ss}->{'action_enabled'} = 'disable' if($pgid->{$ss}->{enabled});
        }
    }
    $main->{pgid} = $pgid;
    return $main;
}

sub checkw
{
    my $main = shift;
    my $pid = shift;
    my $s = $main->{dbcon}->getsimplequeryhash("
                select
                    owner as userid
                from
                    page
                where
                    pageid='$pid'
                ");
    $main = checkusergroupweight($main, $s->{userid});
    return $main;
}
