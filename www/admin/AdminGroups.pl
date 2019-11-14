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
use Data::Dumper;
use XML::Simple;

my $id="AdminGroups";
my ($p,$config,$main);

die("Sorry ... no data") if( not $config = Tt::Config->new('file'));
die("Sorry ... no data") if( not $p = Tt::Genpage->new('file'));

my $main = $config->getconfig('post',$id);
my $ud = checkcookies($main);
$main->{user} = $ud->{login} || 'everyone';
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
    $main->{weight} = $ud->{weight};
    my $action = getval($main,'action') || 'showall';
    my $gid = getval($main,'gid');
    $action = 'new' if getval($main, 'new');
    $action = 'save' if getval($main, 'change');
    $action = 'save' if getval($main, 'save');
    $action = 'lock' if getval($main, 'lock');
    $action = 'unlock' if getval($main, 'unlock');
    $action = 'enable' if getval($main, 'enable');
    $action = 'disable' if getval($main, 'disable');
    $action = 'defaultenable' if getval($main, 'defaultenable');
    $action = 'defaultdisable' if getval($main, 'defaultdisable');
    $action = 'show' if getval($main, 'show');
    $action = 'delete' if getval($main, 'delete');
    $action = 'showall' if getval($main, 'view');

    $main->{form}->{gid} = $gid;
    $main->{form}->{raction} = $action;
    $main->{form}->{gidform} = getval($main, 'gidform') || 1;
    $main->{form}->{name} = getval($main, 'name');
    $main->{form}->{oname} = getval($main, 'oname');
    $main->{form}->{pname} = getval($main, 'pname');
    $main->{form}->{description} = getval($main, 'description');
    $main->{form}->{name} = getval($main, 'name');
    $main->{form}->{weight} = getval($main, 'weight');
    $main->{xml} = XML::Simple->new();

    $main->{eventhash} = {
        lock => 'l',
        unlock => 'unlock',
        show => 'r',
        showall => 'r',
        disable => 'disable',
        enable => 'en',
        defaultdisable => 'disable',
        defaultenable => 'en',
        delete => 'del',
        new => 'c',
        save => 'w',
        acl_disable => 'w',
        acl_enable => 'w'
    };
    $main = AuthUserActionHash($main, 'role', 'ObjectClass', $action);

    if($action eq 'acl_enable' or $action eq 'acl_disable')
    {
        $main = getaclhash($main, $gid);
        my $oname = $main->{form}->{oname};
        my $pname = $main->{form}->{pname};
        $main->{aclh}->{$oname}->{$pname} = 1 if $action eq 'acl_enable';
        delete $main->{aclh}->{$oname}->{$pname} if $action eq 'acl_disable';
        $main = changeaclhash($main, $gid);
        $main = gidform($main,$gid);
        return $main;
    }

    if($action eq 'delete' )
    {
        $main = delgroup($main, $gid);
        $main = gidform($main, 'fake');
        return $main;
    }
    if($action eq 'save' )
    {
        $main = checkformdata($main);
        savegroup($main,$gid) unless $main->{errline};
        $main = gidform($main,$gid);
    }
    if($action eq 'lock' or$action eq 'unlock' )
    {
        $s = $main->{dbcon}->insertsimplequery($main->{dbhlr}, "update groups set locked=1 where gid='$gid'") if $action eq 'lock';
        $s = $main->{dbcon}->insertsimplequery($main->{dbhlr}, "update groups set locked=0 where gid='$gid'") if $action eq 'unlock';
        $main = gidform($main,$gid);
    }
    if($action eq 'enable' or$action eq 'disable' )
    {
        enablegroup($main, $action, $gid);
        $main = gidform($main,$gid);
    }
    if($action eq 'showall')
    {
        $main = gidform($main, 'fake');
    }
    if($action eq 'new')
    {
        undef $main->{form}->{name};
        undef $main->{form}->{gid};
        $main = gidform($main);
    }
    if($action eq 'show')
    {
        $main = gidform($main,$gid);
    }
    return $main;
}


sub savegroup
{
    my $main = shift;
    my $gid = shift;
    my $description = $main->{form}->{description};
    my $gname = $main->{form}->{name};
    my $weight = $main->{form}->{weight};

    if ($main->{form}->{firstcreated} eq 1)
    {
        savenewgroup($main);
        return;
    }

    return 0 unless $gid;

    my $s = $main->{dbcon}->insertsimplequery($main->{dbhlr}, "update
                groups
            set
                gname = '$gname',
                description = '$description',
                weight = '$weight'
                where gid='$gid';");
    return;
}

sub savenewgroup
{
    my $main = shift;
    my $description = $main->{form}->{"description"};
    my $gname = $main->{form}->{"name"};
    my $weight = $main->{weight};

    my $s = $main->{dbcon}->insertsimplequery($main->{dbhlr}, "insert into
                groups
            set
                gname = '$gname',
                description = '$description',
                enabled = 0,
                locked=0,
                weight='$weight',
                ObjectClass='group'
            ;");
    return $main;
}

sub enablegroup
{
    my $main = shift;
    my $action = shift;
    my $gid = shift;
    my $status = 1;
    $status = 0 if($action eq 'disable');
    return 0 if not $gid;

    my $g = $main->{dbcon}->getsimplequeryhash("select gid from user where login ='$main->{global}->{superuser}';");

    my $s = $main->{dbcon}->insertsimplequery($main->{dbhlr}, "update
                groups as g
            set
                g.enabled = '$status'
            where g.gid='$gid' and g.gid != '$g->{gid}' and locked=0;");
    return $s;
}


sub delgroup
{
    my $main = shift;
    my $gid = shift;
    my $line;
    return $main unless $gid;
    my $mgid = $main->{dbcon}->getsimplequeryhash("select count(gid) as count from user where gid ='$gid';");

    if($mgid->{count})
    {
        $main->{errline} .= errline(1,"Вы не можете удалить группу $gid, т.к. $mgid->{count} пользователей являются членами группы");
        return $main;
    }

    my $s = $main->{dbcon}->insertsimplequery($main->{dbhlr}, "delete from
                groups
            where gid='$gid';");
    $main->{errline} .= errline(0, "Группа $main->{form}->{name} (gid:$gid) успешно удалена");
    return $main;
}


sub gidform
{
    my $main = shift;
    my $gid = shift;
    my $gidinfo;my $mrgid;

    my $mgid = $main->{dbcon}->getsimplequery("select
                    gid, gname, description, enabled, CreateStatus
                from
                    groups where weight <= '$main->{weight}'
                ;");

    for my $ss (sort keys %{$mgid})
    {
        $gid = $mgid->{$ss}->[0] if $gid eq 'fake';
        last if $gid > 0;
    }
    my $raid = $main->{dbcon}->getsimplequeryhash("select gid from
                        groups where gname='$main->{form}->{name}';")
                        unless $gid;
    $gid = $gid || $raid->{gid};
    $main->{form}->{gid} = $gid;
    $main->{form}->{raction} = 'new' unless $gid;

    my $gidinfo = $main->{dbcon}->getsimplequeryhash("select gid,gname as name,description,enabled, locked, acl, weight
                                            from
                                                groups
                                            where
                                                gid='$gid'") if($gid);
    $gidinfo->{lchecked} = 'checked' if($gidinfo->{locked});
    $gidinfo->{echecked} = 'checked' if($gidinfo->{enabled});

    for my $ss (sort keys %{$mgid})
    {
        if($ss)
        {
            $mrgid->{$ss}->{gid} = $mgid->{$ss}->[0];
            $mrgid->{$ss}->{gname} = $mgid->{$ss}->[1];
            $mrgid->{$ss}->{description} = $mgid->{$ss}->[2];
            $mrgid->{$ss}->{enabled} = $mgid->{$ss}->[3];
        }
    }
    $main = getgroginfo($main);
    $main->{mgid} = $mrgid;
    $main->{gidinfo} = $gidinfo;
    $main = getaclhash($main, $gid);
    return $main;
}


sub getgroginfo
{
    my $main = shift;
    my $groginfo;
    my $mg = $main->{dbcon}->getsimplequery("select oid,name,rhash from GROG where enabled=1;");
    foreach my $s (keys %{$mg})
    {
        $groginfo->{oid} = $mg->{$s}->[0];
        my $oname = $mg->{$s}->[1];
        my $rhash = $mg->{$s}->[2];
        $groginfo->{$oname}->{rhash} = $main->{xml}->XMLin($rhash) if $rhash;
        delete $groginfo->{$oname}->{rhash}->{ObjectName};
        delete $groginfo->{$oname}->{rhash}->{status};
    }

    $main->{dump_hash} = Dumper($groginfo) || undef;
    $main->{groginfo} = $groginfo;
    return $main;

}

sub getaclhash
{
    my $main = shift;
    my $gid = shift;

    my $macl = $main->{dbcon}->getsimplequeryhash("select acl from groups where enabled=1 and gid='$gid';");
    my $rhash = $macl->{acl};
    $main->{aclh} = $main->{xml}->XMLin($rhash) if $rhash;
    return $main;
}

sub changeaclhash
{
    my $main = shift;
    my $gid = shift;

    $main = createroothash($main) unless ( ishash $main->{aclh});
    my $rhash = $main->{aclh} || undef;
    $main->{form}->{rhash} = genhashtoxml($main, $rhash);
    $s = $main->{dbcon}->insert1linequery($main->{dbhlr}, "update groups set acl = ?
                    where gid='$gid' and locked=0;", $main->{form}->{rhash});
    return $main;
}


sub createroothash
{
    my $main = shift;
    my $rhash;
    $main->{errline} .= errline(0,'hash created');
    $rhash->{prop} = {
            ObjectName => {
                status => 1,
            },
    };
    $rhash = genhashtoxml($main, $rhash);
    $main->{aclh} = $main->{xml}->XMLin($rhash);
    return $main;
}


sub checkformdata
{
    my $main = shift;
    my $errline = '';

    $errline .= checkval('Group name',$main->{form}->{name}, q/^[A-z0-9\.\-\_]+$/);
    my $raid = $main->{dbcon}->getsimplequeryhash("select gid from
                        groups where gname='$main->{form}->{name}';") if $main->{form}->{firstcreated};
    $errline .= errline(1,"Group $main->{form}->{name} already exists!") if $raid->{id};
    $errline .= checkval('Group description',$main->{form}->{description}, q/[\S]/);
    $errline .= errline(1, "Weight must be < 255") if $main->{form}->{weight} > 255;
    $main->{errline} .= $errline;

    return $main;
}
