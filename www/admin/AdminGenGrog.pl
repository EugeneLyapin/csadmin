#!/usr/bin/perl

use strict;
use FindBin qw($Bin);
use Tt::Genpage;
use Tt::Pgen;
use Tt::Error;
use Cp::SrvCfg;
use Tt::Config;
use Db::Dbgame;
use File::Basename qw(basename);
use Tt::Cookies;
use Tt::Auth;
use Template;
use Data::Dumper;
use XML::Simple;

my $id="AdminGenGrog";
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
    my $action = &getval($main,'action') || 'showall';
    my $oid = &getval($main,'oid');
    $main->{global}->{debug} = getval($main, 'debug');
    $action = 'new' if getval($main, 'new');
    $action = 'save' if getval($main, 'change');
    $action = 'save' if getval($main, 'save');
    $action = 'saveprop' if getval($main, 'saveprop');
    $action = 'lock' if getval($main, 'lock');
    $action = 'unlock' if getval($main, 'unlock');
    $action = 'enable' if getval($main, 'enable');
    $action = 'disable' if getval($main, 'disable');
    $action = 'show' if getval($main, 'show');
    $action = 'delete' if getval($main, 'delete');
    $action = 'showall' if getval($main, 'view');
    $action = 'newprop' if getval($main, 'newprop');
    $action = 'editprop' if getval($main, 'editprop');
    $action = 'deleteprop' if getval($main, 'deleteprop');

    $main->{form}->{oid} = $oid;
    $main->{form}->{raction} = $action;
    $main->{form}->{grogform} = getval($main, 'grogform') || 1;
    $main->{form}->{pname} = getval($main, 'pname');
    $main->{form}->{newpname} = getval($main, 'newpname');
    $main->{form}->{newpdescription} = getval($main, 'newpdescription');
    $main->{form}->{firstcreated} = getval($main, 'firstcreated');

    $main->{eventhash} = {
        show => 'r',
        showall => 'r',
        new => 'w',
        save => 'w',
        saveprop => 'w',
        lock => 'w',
        unlock => 'w',
        enable => 'w',
        disable => 'w',
        delete => 'w',
        editprop => 'w',
        deleteprop => 'w',
        newprop => 'w'
    };
    $main = AuthUserActionHash( $main, 'grog', 'ObjectClass', $action );
    if($action eq 'save' || $action eq 'saveprop')
    {
        $main = checkformdata($main);
        $main = grogform($main, $oid) if $oid > 0;
        changegroginfo($main, $oid) unless $main->{errline};
        $main = grogform($main, $oid);
    }
    if($action eq 'new')
    {
        undef $main->{form}->{name};
        $main = grogform($main);
    }
    if($action eq 'delete')
    {
        $s = $main->{dbcon}->insertsimplequery($main->{dbhlr}, "delete
                from
                    GROG
                where oid='$oid' and locked=0;");
        $main = grogform($main, 'fake');
    }
    if($action eq 'deleteprop')
    {
        $main = grogform($main, $oid);
        my $pname = 'p_'.$main->{form}->{pname};
        delete $main->{groginfo}->{rhash}->{$pname} ;
        changegroginfo($main, $oid);
        $main = grogform($main, $oid);
    }
    if($action eq 'show' or $action eq 'newprop')
    {
        $main = grogform($main, $oid);
    }
    if($action eq 'showall')
    {
        $main = grogform($main, 'fake');
    }
    if($action eq 'lock' or $action eq 'unlock')
    {
        lockgrog($main, $action, $oid);
        $main = grogform($main, $oid);
    }
    if($action eq 'enable' or $action eq 'disable')
    {
        enablegrog($main, $action, $oid);
        $main = grogform($main, $oid);
    }
    return $main;

}


sub enablegrog
{
    my $main = shift;
    my $action = shift;
    my $oid = shift;
    my $status = 1;
    $status = 0 if($action eq 'disable');
    return $main unless $oid;

    my $s = $main->{dbcon}->insertsimplequery($main->{dbhlr}, "update
            GROG
        set
            enabled = '$status'
        where oid='$oid' and locked=0;");
    return $main;
}


sub lockgrog
{
    my $main = shift;
    my $action = shift;
    my $oid = shift;
    my $status = 1;
    $status = 0 if($action eq 'unlock');

    return if(!($oid ));

    my $s = $main->{dbcon}->insertsimplequery($main->{dbhlr}, "update
            GROG
        set
            locked = '$status'
        where oid='$oid';");
    return $s;
}


sub grogform
{

    my $main = shift;
    my $oid = shift;
    my $groginfo;

    my $moid = $main->{dbcon}->getsimplequery("select oid,name from GROG; ") ;
    for my $ss (sort keys %{$moid})
    {
        $oid = $moid->{$ss}->[0] if $oid eq 'fake';
        last if $oid > 0;
    }
    my $raid = $main->{dbcon}->getsimplequeryhash("select oid from
                        GROG
                    where
                        name='$main->{form}->{name}';") unless $oid;
    $oid = $oid || $raid->{oid};
    $main->{form}->{oid} = $oid;
    $main->{form}->{raction} = 'new' unless $oid;

    my $rgrog = $main->{dbcon}->getsimplequery("select oid,name,description,enabled, locked, rhash
                        from
                            GROG
                        where
                            oid='$oid'") if($oid);

    for my $s (sort keys %{$rgrog})
    {
        if($s)
        {
            $groginfo->{oid} = $rgrog->{$s}->[0];
            $groginfo->{name} = $rgrog->{$s}->[1];
            $groginfo->{description} = $rgrog->{$s}->[2];
            $groginfo->{enabled} = $rgrog->{$s}->[3];
            $groginfo->{locked} = $rgrog->{$s}->[4];
            $groginfo->{xml} = $rgrog->{$s}->[5];
            $groginfo->{lchecked} = 'checked' if($groginfo->{locked});
            $groginfo->{echecked} = 'checked' if($groginfo->{enabled});
            my $xml = XML::Simple->new();
            $groginfo->{rhash} = $xml->XMLin($groginfo->{xml});
            $groginfo->{dump_hash} = Dumper($groginfo->{rhash}) || undef;
            $groginfo->{outhash} = $groginfo->{rhash};
            delete $groginfo->{outhash}->{ObjectName};
            $groginfo->{nohash} = 0;
            $groginfo->{nohash} = 1 if $groginfo->{outhash}->{status};
            delete $groginfo->{outhash}->{status};
        }
    }

    $main->{moid} = $moid;
    $main->{groginfo} = $groginfo;
    return $main;

}

sub checkformdata
{
    my $main = shift;
    my $errline = '';

    $errline .= checkval('object name',$main->{form}->{name}, q/^[A-z0-9\.\-\_]+$/);
    my $raid = $main->{dbcon}->getsimplequeryhash("select oid from
                        GROG where name='$main->{form}->{name}';") if $main->{form}->{firstcreated};
    $errline .= errline(1,"Object $main->{form}->{name} already exists!") if $raid->{oid};
    $errline .= checkval('object description',$main->{form}->{description}, q/[\S]/);

    if($main->{form}->{firstcreated})
    {
        $errline .= checkval('property name',$main->{form}->{newpname}, q/^[A-z0-9\.\-\_]+$/);
        $errline .= checkval('property description',$main->{form}->{newpdescription}, q/[\S]/);
    }

    $main->{errline} .= $errline;

    return $main;
}



sub changegroginfo
{
    my $main = shift;
    my $oid = shift;
    my ($status,$s, $enabled);
    $main = createroothash($main) unless ( ishash $main->{groginfo}->{rhash});
    my $rhash = $main->{groginfo}->{rhash} || undef;
    delete $rhash->{status};
    $rhash->{ObjectName}->{status} = '1';

    my $k = 'p_'.$main->{form}->{newpname};
    $rhash->{$k} = {
        pname => $main->{form}->{newpname},
        description => $main->{form}->{newpdescription},
    } if $main->{form}->{raction} eq 'saveprop';

    my $xml = XML::Simple->new();
    my @arr = $xml->XMLout($rhash,
                KeepRoot   => 1,
                NoSort => 1,RootName => 'rhash' );
    foreach (@arr)
    {
        $main->{form}->{rhash} .=  $_;
    }
    if($main->{form}->{raction} eq 'deleteprop')
    {
        $s = $main->{dbcon}->insert1linequery($main->{dbhlr}, "update GROG set rhash = ?
                where oid='$oid' and locked=0;", $main->{form}->{rhash});
        return $main;
    }
    return $main unless $main->{form}->{name};
    return $main unless $main->{form}->{rhash};

    if($oid > 0)
    {
        $s = $main->{dbcon}->insert1linequery($main->{dbhlr}, "update GROG
                set
                    name = '$main->{form}->{name}',
                    description = '$main->{form}->{description}',
                    rhash = ?
                where
                    oid='$oid' and locked=0;", $main->{form}->{rhash}) ;
    }
    else
    {
        $s = $main->{dbcon}->insert1linequery($main->{dbhlr}, "insert into GROG
                set
                    name='$main->{form}->{name}',
                description='$main->{form}->{description}',
                enabled='1',
                locked='0',
                rhash = ? ;",$main->{form}->{rhash});
    }
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
    } if $main->{form}->{raction} eq 'save';
    my $xml = XML::Simple->new();

    my @arr = $xml->XMLout($rhash,
                KeepRoot   => 1,
                NoSort => 1,RootName => 'rhash' );
    $rhash = undef;
    foreach (@arr)
    {
        $rhash .=  $_;
    }
    $main->{groginfo}->{rhash} = $xml->XMLin($rhash);
    return $main;
}

sub getGROG
{
    my $main = shift;
    my $maid;
    my $aid = $main->{dbcon}->getsimplequery("select
                    a.id as oid,
                    p.name as pname,
                    a.name as name,
                    a.description as description,
                    a.pflag as pflag,
                    a.locked as locked
                from
                    GROG as a, page as p
                where
                    p.pageid=a.pageid
                ;");

    for my  $ss (sort keys %{$aid})
    {
        if($ss)
        {
            $maid->{$ss}->{oid} = $aid->{$ss}->[0];
            $maid->{$ss}->{pname} = $aid->{$ss}->[1];
            $maid->{$ss}->{name} = $aid->{$ss}->[2];
            $maid->{$ss}->{pflag} = $aid->{$ss}->[4];
            $maid->{$ss}->{locked} = $aid->{$ss}->[5];
            $maid->{$ss}->{description} = substr($aid->{$ss}->[3],0,50);
            $maid->{$ss}->{description} = join(' ',$maid->{$ss}->{description}, '...') if(length($maid->{$ss}->{description}) == 50);

            if($maid->{$ss}->{pflag})
            {
                $maid->{$ss}->{action} = 'disable';
                $maid->{$ss}->{pic} = 'i-agree.gif';
            }
            else
            {
                $maid->{$ss}->{action} = 'enable';
                $maid->{$ss}->{pic} = 'i-stop.gif';
            }
        }
    }

    $main->{maid} = $maid;

    return $main;
}
