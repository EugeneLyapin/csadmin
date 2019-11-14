#!/usr/bin/perl

use strict;
use FindBin qw($Bin);
use Tt::Genpage;
use Tt::Pgen;
use Tt::Error;
use Cp::SrvCfg;
use Tt::Config;
use Db::Dbgame;
use Tt::Cookies;
use Tt::Auth;
use Template;

my $id="AdminGentemplate";
my ($p,$config,$main, $sc, $col, $cvol, $fstatus);

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

    my $rtid = &getval($main,'regtid');
    my $rctid = &getval($main,'regcatid');
    my $action = &getval($main,'action') || 'showall';
    $action = 'Save' if (getval($main, 'savebutton'));
    $action = 'showtt' if (getval($main, 'showtt'));
    $action = 'newtt' if (getval($main, 'newtt'));
    $action = 'deltt' if (getval($main, 'deltt'));
    $action = 'changett' if (getval($main, 'changett'));
    $action = 'locktt' if (getval($main, 'locktt'));
    $action = 'unlocktt' if (getval($main, 'unlocktt'));
    $action = 'showall' if (getval($main, 'view'));
    $main->{tt}->{ttform} = &getval($main,'ttform');
    $main->{tt}->{owner} = &getval($main,'owner');
    $main->{tt}->{oldowner} = &getval($main,'oldowner');
    $main->{tt}->{raction} = $action ;
    $main->{tt}->{regtid} = $rtid;
    $main->{tt}->{regcatid} = $rctid;
    $main->{tt}->{ttform} = 0 if $action eq 'showall';
    $main->{weight} = $ud->{weight};
    $main->{eventhash} = {
        Save => 'w',
        showtt => 'r',
        newtt => 'c',
        deltt => 'del',
        showall => 'r',
        changett => 'w',
        locktt => 'l',
        unlocktt => 'unlock',
        chowner => 'chowner'
    };
    my $q = $main->{dbcon}->getsimplequeryhash("select rname from regtemplates where regtid='$rtid'") if $rtid;
    my $pname = $q->{rname} || 'ObjectClass';
    my $tname = $pname eq 'ObjectClass' ? 'template' : 'regtemplates';
    $main = AuthUserActionHash( $main, $tname, $pname, $action ) ;

    if($action eq 'deltt')
    {
        checkw($main, $rtid);
        my $dstatus = $main->{dbcon}->getsimplequery("delete
                        from
                            regtemplates
                        where
                            regtid='$rtid' and locked=0");
        $main->{tt}->{ttform} = 0;
    }

    if($action eq 'locktt' or $action eq 'unlocktt')
    {
        checkw($main, $rtid) if $rtid;
        $s = $main->{dbcon}->getsimplequery("update regtemplates set locked=1 where regtid='$rtid'") if($action eq 'locktt');
        $s = $main->{dbcon}->getsimplequery("update regtemplates set locked=0 where regtid='$rtid'") if($action eq 'unlocktt');
        if ( $main->{tt}->{ttform} eq  1)
        {
            $main = ttform($main, $rtid);
            return $main;
        }
        $main->{tt}->{ttform} = 0;
    }

    if($action eq 'changett' or $action eq 'Save')
    {
        checkw($main, $rtid) if $rtid;
        $main = checkformdata($main);
        $rtid = changettinfo($main, $rtid ) if $main->{status_flag} eq 'ok';
        chowner($main, $rtid, $tname, $pname) if $main->{status_flag} eq 'ok';
        $main = ttform($main,$rtid);
        return $main;
    }

    if($action eq 'showtt' )
    {
        $main = ttform($main,$rtid);
        return $main;
    }

    if($action eq 'newtt' )
    {
        $main = ttform($main);
        return $main;
    }

    $main = gett($main) ;
    return $main;
}


sub ttform
{
    my $main = shift;
    my $rtid = shift ;
    my $errline = shift;
    my $ttinfo;

    my $rrtid = $main->{dbcon}->getsimplequeryhash("select regtid from
                regtemplates where rname='$main->{form}->{rname}';")
                unless $main->{form}->{regtid};
    $rtid = $rtid || $rrtid->{regtid};
    $main->{tt}->{regtid} = $rtid;
    $main->{tt}->{raction} = 'newtt' unless $rtid;

    my $rtt = $main->{dbcon}->getsimplequery("select regtid,regname,value,rname,regcatid,locked,owner
                        from
                            regtemplates
                        where
                            regtid='$rtid'") if $rtid;

    my $regtid = $main->{dbcon}->getsimplequery("select regtid,rname from regtemplates; ");
    my $regcatid = $main->{dbcon}->getsimplequery("select id,name,description from regcategories; ");

    for my $s (sort keys %{$rtt})
    {
        next unless ($s) ;
        $ttinfo->{regtid} = $rtt->{$s}->[0];
        $ttinfo->{regname} = $rtt->{$s}->[1];
        $ttinfo->{value} = $rtt->{$s}->[2];
        $ttinfo->{rname} = $rtt->{$s}->[3];
        $ttinfo->{regcatid} = $rtt->{$s}->[4];
        $ttinfo->{locked} = $rtt->{$s}->[5];
        $ttinfo->{owner} = $rtt->{$s}->[6];
    }
    my $muid;
    my $p_uid = $main->{dbcon}->getsimplequery("select userid, login from user;");

    for my  $ss (sort keys %{$p_uid})
    {
        $muid->{$ss}->{userid} = $p_uid->{$ss}->[0];
        $muid->{$ss}->{login} = $p_uid->{$ss}->[1];
        $muid->{$ss}->{selected} = undef;
        $muid->{$ss}->{selected} = 'selected' if $muid->{$ss}->{userid} eq $ttinfo->{owner};
    }

    $main->{muid} = $muid;
    $main->{ttinfo} = $ttinfo;
    $main->{regcatid} = $regcatid;
    $main->{rtt} = $regtid;
    return $main;
}


sub checkformdata
{
    my $main = shift;
    my $errline = '';
    $main->{status_flag} = 'ok';

    my $mp;

    $errline .= checkval('rname',$main->{form}->{rname}, q/^[A-z0-9\.\-\_]+$/);
    $errline .= checkval('regname',$main->{form}->{regname}, q/[\S]/);
    $errline .= checkval('value',$main->{form}->{value}, q/[\S]/);
    $main->{errline} = $errline;
    $main->{status_flag} = 'fail' if $errline;
    return $main if($errline);

    my $regname = $main->{form}->{regname};
    $mp->{$regname} = $regname;
    $errline .= $p->checkpage($main,$main->{form}->{value},'main',$mp);
    $main->{errline} = $errline;
    $main->{status_flag} = 'fail' if $errline;
    return $main;

}

sub changettinfo
{
    my $main = shift;
    my $rtid = shift;
    my ($status,$s, $rtid);
    return $main unless $main->{form}->{rname};

    my $csid = $main->{dbcon}->getsimplequeryhash("select
                                    rname,regtid
                                FROM
                                    regtemplates
                                where
                                    rname='$main->{form}->{rname}'
                                    ");
    $rtid = $rtid || $csid->{regtid};
    $status = 1 if($csid->{rname});
    if($status)
    {
        $s = $main->{dbcon}->insert2linequery($main->{dbhlr}, "update regtemplates
                set
                    rname = '$main->{form}->{rname}',
                    regcatid = '$main->{form}->{regcatid}',
                    locked=0,
                    ObjectClass='template',
                    regname = ?,
                    value = ?
                where
                    rname='$main->{form}->{rname}' and locked=0;",$main->{form}->{regname}, $main->{form}->{value});
    }
    else
    {
        $s = $main->{dbcon}->insert2linequery($main->{dbhlr}, "insert into regtemplates
                (rname,regcatid,locked,ObjectClass, regname,value) values(
                '$main->{form}->{rname}',
                '$main->{form}->{regcatid}',
                '0',
                'template',
                ?,? );",$main->{form}->{regname}, $main->{form}->{value});

    my $hrtid = $main->{dbcon}->getsimplequeryhash("select regtid FROM regtemplates where
                                    rname='$main->{form}->{rname}'");
        $rtid = $hrtid->{regtid};
    }
    return $rtid;
}

sub gett
{
    my $main = shift;
    my $mrtid;
    return $main if $main->{tt}->{ttform} eq 1;
    my $rtt = $main->{dbcon}->getsimplequery("select r.regtid as regtid,r.regname as regname,r.value as value,r.rname as rname,c.name as cname,
                           r.locked as locked
                        from
                            regtemplates as r, regcategories as c
                        where
                            r.regcatid = c.id;
                        ");

    for my  $ss (sort keys %{$rtt})
    {
        next unless($ss);
        $mrtid->{$ss}->{regtid} = $rtt->{$ss}->[0];
        $mrtid->{$ss}->{rname} = $rtt->{$ss}->[3];
        $mrtid->{$ss}->{cname} = $rtt->{$ss}->[4];
        $mrtid->{$ss}->{locked} = $rtt->{$ss}->[5];
        $mrtid->{$ss}->{regname} = substr($rtt->{$ss}->[1],0,50);
        $mrtid->{$ss}->{regname} = join(' ',$mrtid->{$ss}->{regname}, '...') if(length($mrtid->{$ss}->{regname}) == 50);
        $mrtid->{$ss}->{regname} =~ s/\</&lt;/g, $mrtid->{$ss}->{regname};
        $mrtid->{$ss}->{regname} =~ s/\>/&gt;/g, $mrtid->{$ss}->{regname};
    }
    $main->{mrtid} = $mrtid;
    return $main;
}


sub chowner
{
    my $main = shift;
    my $regtid = shift;
    my $tname = shift;
    my $pname = shift;
    return $main if $main->{tt}->{owner} eq $main->{tt}->{oldowner};
    $main->{eventhash}->{chowner} = 'chowner';
    $main = AuthUserActionHash( $main, $tname, $pname, 'chowner' );
    my $s = $main->{dbcon}->insertsimplequery($main->{dbhlr}, "update
                regtemplates
            set
                owner='$main->{tt}->{owner}'
            where regtid='$regtid' and ( locked=0 or locked is NULL) ;");
    return $s;
}

sub checkw
{
    my $main = shift;
    my $rtid = shift;
    my $s = $main->{dbcon}->getsimplequeryhash("select owner as userid from regtemplates where regtid='$rtid'");
    $main = checkusergroupweight($main, $s->{userid});
    return $main;
}

