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

my $id="AdminGenArticle";
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
    my $action = &getval($main,'action') || 'showall';
    my $artid = &getval($main,'artid');
    $main->{weight} = $ud->{weight};
    $action = 'saveart' if (getval($main, 'saveart'));
    $action = 'saveart' if (getval($main, 'Save'));
    $action = 'saveart' if (getval($main, 'changeart'));
    $action = 'findart' if (getval($main, 'showart'));
    $action = 'newart' if (getval($main, 'newart'));
    $action = 'deleteart' if (getval($main, 'deleteart'));
    $action = 'lock' if (getval($main, 'lock'));
    $action = 'unlock' if (getval($main, 'unlock'));
    $action = 'showall' if (getval($main, 'view'));
    $artid = undef if($action eq 'newart');

    $main->{form}->{artname} = getval($main, 'artname');
    $main->{form}->{pageid} = getval($main, 'pageid');
    $main->{form}->{description} = getval($main, 'description');
    $main->{form}->{pflag} = getval($main, 'pflag');
    $main->{form}->{value} = getval($main, 'value');
    $main->{action} = $action;
    $main->{a}->{artform} = getval($main, 'artform');
    $main->{a}->{raction} = $action;
    $main->{a}->{artid} = $artid;
    $main->{a}->{aform} = getval($main, 'aform');
    $main->{a}->{owner} = getval($main, 'owner');
    $main->{a}->{oldowner} = getval($main, 'oldowner');
    $main->{a}->{artform} = 0 if $action eq 'showall';

    $main->{eventhash} = {
        saveart => 'w',
        Save => 'w',
        findart => 'r',
        newart => 'c',
        deleteart => 'del',
        lock => 'l',
        unlock => 'unlock',
        showall => 'r',
        showart => 'r',
        chowner => 'chowner'
    };
    $main = AuthUserActionHash( $main, 'article', 'ObjectClass', $action ) ;

    if ($action eq 'deleteart')
    {
        checkw($main, $artid);
        my $dstatus = $main->{dbcon}->getsimplequery("delete from articles where id='$artid' and locked=0") ;
    }
    if($action eq 'saveart')
    {
        checkw($main, $artid) if $artid;
        $main = checkformdata($main);
        changeartinfo($main,$artid) unless $main->{errline};
        $main = artform($main,$artid);
        return $main;
    }
    elsif($action eq 'disable' or $action eq 'enable')
    {
        checkw($main, $artid);
        enableart($main,$action,$artid);
    }
    elsif($action eq 'lock' or $action eq 'unlock')
    {
        checkw($main, $artid);
        lockart($main,$action,$artid);
    }
    elsif($action eq 'newart')
    {
        $main->{form}->{artname} = '';
        $main = artform($main);
        return $main;
    }

    if($action eq 'showart' or $main->{a}->{artform} eq 1)
    {
        $main = artform($main,$artid);
        return $main;
    }
    $main->{a}->{artform} = 0;

    $main = getarticles($main);
    return $main;

}

sub checkw
{
    my $main = shift;
    my $artid = shift;
    my $s = $main->{dbcon}->getsimplequeryhash("select owner as userid from articles where id='$artid'");
    $main = checkusergroupweight($main, $s->{userid});
    return $main;
}

sub enableart
{
    my $main = shift;
    my $action = shift;
    my $artid = shift;
    my $status = 1;
    $status = 0 if($action eq 'disable');
    return $main unless $artid;
    my $s = $main->{dbcon}->insertsimplequery($main->{dbhlr}, "update
                                                                articles
                                                            set
                                                                pflag = '$status'
                                                            where
                                                                id='$artid' and locked=0;");
    return $main;
}


sub lockart
{
    my $main = shift;
    my $action = shift;
    my $artid = shift;
    my $status = 1;
    $status = 0 if($action eq 'unlock');
    return unless $artid;
    my $s = $main->{dbcon}->insertsimplequery($main->{dbhlr}, "update
                                                                articles
                                                            set
                                                                locked = '$status'
                                                            where id='$artid';");
    return $s;
}


sub artform
{

    my $main = shift;
    my $artid = shift;
    my $artinfo;

    my $raid = $main->{dbcon}->getsimplequeryhash("select
                                                    id
                                                from
                                                    articles
                                                where
                                                    name='$main->{form}->{artname}';
                                                ") unless $artid;
    $artid = $artid || $raid->{id};
    $main->{a}->{artid} = $artid;
    $main->{a}->{raction} = 'newart' unless $artid;

    my $ra = $main->{dbcon}->getsimplequery("select id,name from articles; ") if($artid);
    my $rart = $main->{dbcon}->getsimplequery("select
                                                id,
                                                pageid,
                                                name,
                                                description,
                                                value,
                                                pflag,
                                                locked,
                                                owner
                                            from
                                                articles
                                            where
                                                id='$artid'
                                            ") if($artid);

    my $rp = $main->{dbcon}->getsimplequery("select
                                                pageid,name
                                            from
                                                page
                                            ");

    for my $s (sort keys %{$rart})
    {
        if($s)
        {
            $artinfo->{artid} = $rart->{$s}->[0];
            $artinfo->{pageid} = $rart->{$s}->[1];
            $artinfo->{artname} = $rart->{$s}->[2];
            $artinfo->{description} = $rart->{$s}->[3];
            $artinfo->{value} = $rart->{$s}->[4];
            $artinfo->{pflag} = $rart->{$s}->[5];
            $artinfo->{locked} = $rart->{$s}->[6];
            $artinfo->{owner} = $rart->{$s}->[7];
            $artinfo->{checked} = 'checked' if($artinfo->{pflag});
        }
    }

    my $muid;
    my $p_uid = $main->{dbcon}->getsimplequery("select userid, login from user;");

    for my  $ss (sort keys %{$p_uid})
    {
        $muid->{$ss}->{userid} = $p_uid->{$ss}->[0];
        $muid->{$ss}->{login} = $p_uid->{$ss}->[1];
        $muid->{$ss}->{selected} = undef;
        $muid->{$ss}->{selected} = 'selected' if $muid->{$ss}->{userid} eq $artinfo->{owner};
    }

    $main->{muid} = $muid;
    $main->{martid} = $ra;
    $main->{rp} = $rp;
    $main->{artinfo} = $artinfo;
    return $main;

}


sub checkformdata
{
    my $main = shift;
    my $errline = '';

    $errline .= checkval('artname',$main->{form}->{artname}, q/^[A-z0-9\.\-\_]+$/);
    $errline .= checkval('description',$main->{form}->{description}, q/[\S]/);
    $errline .= checkval('value',$main->{form}->{value}, q/[\S]/);
    $main->{errline} .= $errline;

    return $main;
}



sub changeartinfo
{
    my $main = shift;
    my $artid = shift;
    my ($status,$s);
    $main->{c} = 1;


    if($main->{form}->{pflag} eq 'pflag')
    {
        $main->{form}->{pflag} = 1;
    }
    else
    {
        $main->{form}->{pflag} = 0;
    }

    if($artid > 0)
    {
        $s = $main->{dbcon}->insert1linequery($main->{dbhlr},
                                                    "update articles
                                                    set
                                                        name = '$main->{form}->{artname}',
                                                        pageid = '$main->{form}->{pageid}',
                                                        description = '$main->{form}->{description}',
                                                        pflag = '$main->{form}->{pflag}',
                                                        ChangedBy = '$user',
                                                        DataChanged = CURRENT_TIMESTAMP,
                                                        value = ?
                                                    where
                                                        id='$artid' and locked=0;", $main->{form}->{value});
    }
    else
    {
        $s = $main->{dbcon}->insert1linequery($main->{dbhlr}, "insert into articles
                (name,pageid,description,pflag,CreatedBy,owner,DataCreated,locked,value) values(
                '$main->{form}->{artname}',
                '$main->{form}->{pageid}',
                '$main->{form}->{description}',
                '$main->{form}->{pflag}',
                '$user',
                '$user',
                CURRENT_TIMESTAMP,
                '0',
                ? );",$main->{form}->{value});

        my $raid = $main->{dbcon}->getsimplequeryhash("select id from
                        articles where name='$main->{form}->{artname}';");
        $artid = $raid->{id};
    }

    chowner($main, $artid);
    return $main;

}


sub getarticles
{
    my $main = shift;
    my $maid;
    my $aid = $main->{dbcon}->getsimplequery("select
                                        a.id as artid, p.name as pname, a.name as name, a.description as description, a.pflag as pflag, a.locked as locked
                                    from
                                        articles as a, page as p
                                    where
                                        p.pageid=a.pageid
                                    ;");

    for my  $ss (sort keys %{$aid})
    {
        if($ss)
        {
            $maid->{$ss}->{artid} = $aid->{$ss}->[0];
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

sub chowner
{
    my $main = shift;
    my $artid = shift;
    return $main if $main->{a}->{owner} eq $main->{a}->{oldowner};
    $main->{eventhash}->{chowner} = 'chowner';
    $main = AuthUserActionHash( $main, 'article', 'ObjectClass', 'chowner' );
    my $s = $main->{dbcon}->insertsimplequery($main->{dbhlr}, "update
                    articles
                set
                    owner='$main->{a}->{owner}'
                where id='$artid' and ( locked=0 or locked is NULL) ;");
    return $s;
}


