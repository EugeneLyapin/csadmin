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
use Data::Dumper;
use XML::Simple;

my $id="AdminSetObjectClass";
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
    $action = 'save' if getval($main, 'change');
    $action = 'save' if getval($main, 'save');
    $main->{form}->{table} = getval($main, 'table');
    $main->{form}->{field} = getval($main, 'field');
    $main->{form}->{object} = getval($main, 'object');
    $main->{form}->{OC} = getval($main, 'OC');
    $main->{form}->{owner} = getval($main, 'owner');
    $main->{form}->{oclass} = getval($main, 'oclass');
    $main->{form}->{raction} = $action;

    $main->{eventhash} = {
        showall => 'r',
        desctable => 'r',
        save => 'w',
        showfield => 'r',
        showobject => 'r'
    };

    $main = AuthUserActionHash( $main, 'grog', 'ObjectClass', $action ) ;

    if($action eq 'desctable')
    {
        $main = showtable($main);
        return $main;
    }
    if($action eq 'save')
    {
        $main = saveOC($main);
        $main = showobject($main);
        return $main;
    }
    if($action eq 'showfield')
    {
        $main = showfield($main);
        return $main;
    }
    if($action eq 'showobject')
    {
        $main = showobject($main);
        return $main;
    }

    $main = showtables($main) if $action eq 'showall';
    return $main;
}

sub showtables
{
    my $main = shift;
    my $mt = $main->{dbcon}->getsimplequery("show tables;");
    $main->{mtables} = $mt;
    return $main;
}

sub showtable
{
    my $main = shift;
    my $mtable;my $status;
    my $mt = $main->{dbcon}->getsimplequery("desc $main->{form}->{table};");
    foreach my $ss (keys %{$mt})
    {
        $status = 1 if $mt->{$ss}->[0] eq 'ObjectClass';
        last if $status;
    }
    my $errline = errline(1, "No ObjectClass in table $main->{form}->{table}") unless $status;
    $main->{errline} .= $errline unless $status;
    return $main unless $status;
    $main->{objexists} = 1;
    $main->{table} = $mt;
    $main->{info}->{table} = $main->{form}->{table};
    $main->{form}->{raction} = 'desctable';
    return $main;
}

sub showfield
{
    my $main = shift;
    my $mt = $main->{dbcon}->getsimplequery("select $main->{form}->{field},ObjectClass from $main->{form}->{table};");
    $main->{table} = $mt;
    $main->{errline} = errline(1,'No ObjectClass for '.$main->{form}->{table}) unless ishash $mt;
    $main->{objexists} = 1 if ishash $mt;
    $main->{info}->{table} = $main->{form}->{table};
    $main->{info}->{field} = $main->{form}->{field};
    $main->{info}->{object} = $main->{form}->{object};
    $main->{form}->{raction} = 'showfield';
    return $main;
}

sub showobject
{
    my $main = shift;
    my $mt = $main->{dbcon}->getsimplequeryhash("select ObjectClass from $main->{form}->{table}
                where $main->{form}->{field}='$main->{form}->{object}' ;");
    my $mo = $main->{dbcon}->getsimplequeryhash("select owner from $main->{form}->{table}
                where $main->{form}->{field}='$main->{form}->{object}' ;");
    my $moid = $main->{dbcon}->getsimplequery("select name from GROG;");
    my $mown = $main->{dbcon}->getsimplequery("select userid,login from user;");
    $main->{mt} = $mt;
    $main->{mo} = $mo;
    $main->{mown} = $mown;
    $main->{groginfo} = $moid;
    $main->{errline} = errline(1,'No ObjectClass for '.$main->{form}->{table}) unless ishash $mt;
    $main->{objexists} = 1 if ishash $mt;
    $main->{info}->{table} = $main->{form}->{table};
    $main->{info}->{field} = $main->{form}->{field};
    $main->{info}->{object} = $main->{form}->{object};
    $main->{form}->{raction} = 'showobject';
    $main->{info}->{path} = errline(0, "$main->{info}->{table} -> $main->{info}->{field} -> $main->{info}->{object}");
    return $main;
}

sub saveOC
{
    my $main = shift;
    my $errline;
    $errline .= checkval('Table',$main->{form}->{table}, q/^[A-z0-9\.\-\_]+$/);
    $errline .= checkval('Field',$main->{form}->{field}, q/^[A-z0-9\.\-\_]+$/);
    $errline .= checkval('Object',$main->{form}->{object}, q/^[A-z0-9\.\-\_]+$/);
    $errline .= checkval('owner',$main->{form}->{owner}, q/^\d+$/) if $main->{form}->{owner};

    # abandon changes from users!

    if ( $main->{form}->{oclass} != $main->{form}->{OC}
    && $main->{user} != $main->{global}->{superuser})
    {
    $errline .= errline(1, "Permission denied");
    }
    $main->{errline} .= $errline;
    return $main if $errline;
    $s = $main->{dbcon}->insertsimplequery($main->{dbhlr}, "update $main->{form}->{table}
            set
                ObjectClass='$main->{form}->{OC}'
            where $main->{form}->{field}='$main->{form}->{object}'");
    $s = $main->{dbcon}->insertsimplequery($main->{dbhlr}, "update $main->{form}->{table}
            set
                owner='$main->{form}->{owner}'
            where $main->{form}->{field}='$main->{form}->{object}'") if $main->{form}->{owner};
    $main->{form}->{raction} = 'showobject';
    return $main;
}
