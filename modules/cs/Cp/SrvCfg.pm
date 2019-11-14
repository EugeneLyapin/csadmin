package Cp::SrvCfg;

use strict;
use Exporter;
use Cp::CreateProfile;
use FindBin qw($Bin);
use base qw( Exporter );
use Net::FTP;
use CGI qw/:standard/;
use File::Path qw(rmtree);
use Tt::Pgen;
use Cp::SrvInfo;

our @EXPORT = qw(
            getsrvcfg
            getservers
            parsecfg
            getsrvinfo
            getsrvinfohash
            addserver
            DelUser
            DelSrvConfigs
            );

sub getsrvcfg
{
    my $main = shift;
    my $srvid = shift;
    my $configfile = shift;
    return if(not defined ($configfile));
    my $srv = $main->{dbcon}->getsimplequery("
                select
                    srv.sid,
                    i.ipaddr,
                    c.value,
                    srv.HLDSport
                FROM
                    srv as srv,
                    iplist as i,
                    $configfile as c
                where
                    c.sid=srv.sid
                    and i.ipid=srv.ipid
                    and srv.sid='$srvid'
                ");
    return($srv);
}

sub getservers
{
    my $main = shift;
    my $user = shift;
    my $srvid1 = shift;

    my $reg = "and srv.sid=$srvid1" if($srvid1);
    my $srvid = $main->{dbcon}->getsimplequery("
                select
                    srv.sid,
                    i.ipaddr,
                    srv.status,
                    srv.enabled,
                    srv.name,
                    srv.numslots,
                    srv.numgamers,
                    srv.HLTVport,
                    u.login,
                    u.userid,
                    srv.HLDSport
                from
                    srv as srv,
                    user as u,
                    iplist as i
                    where u.userid=srv.userid
                    and srv.ipid=i.ipid
                    and u.login like '$user' $reg ;
                ");

    foreach my $m (keys %{$srvid})
    {
        $srvid->{$m}->[1] = "$srvid->{$m}->[0] | IP: $srvid->{$m}->[1]";
    }

    $srvid1 = &getval($main,'sid') if not($srvid1);
    $srvid1 = &getval($main,'srvid') if not($srvid1);
    $srvid1 = param('sid') if not($srvid1);
    $srvid1 = $srvid->{1}->[0] if not($srvid1);

    return($srvid,$srvid1);
}

sub parsecfg
{
    my $arr = shift;
    my( $value,$arr1,$l);
    foreach my $s (keys %{$arr})
    {
        if($s)
        {
            $l = $arr->{$s}->[2];
        }
    }

    my @lines = split(/[\r\n]/,$l);
    foreach my $p1 (@lines)
    {
        if($p1 and $p1 !~/^[\;\/]+/)
        {
            $arr1->{$p1}->[0] = $p1;
            $arr1->{$p1}->[1] = $p1;
            $arr1->{$p1}->[2] = $p1;
        }

    }

    return($arr1);
}


sub getsrvinfo
{
    my $main = shift;
    my $srvid = shift;
    my $srv = $main->{dbcon}->getsimplequery("
                select
                    srv.sid,
                    stype.description,
                    srv.status,
                    srv.enabled,
                    i.ipaddr,
                    ostype.description,
                    u.login,
                    t.description,
                    g.description,
                    p.description,
                    l.description,
                    m.name,
                    m.pic,
                    srv.name,
                    srv.numslots,
                    srv.numgamers,
                    srv.anticheat,
                    srv.addons,
                    srv.mapid,
                    srv.ftpstatus,
                    srv.HLTVport,
                    srv.HLDSport,
                    srv.start_time,
                    srv.stop_time,
                    ( UNIX_TIMESTAMP(CURRENT_TIMESTAMP) - UNIX_TIMESTAMP(srv.start_time)) as ltime,
                    p.hours,
                    g.gameid,
                    t.tarifid,
                    l.locationid,
                    p.periodid,
                    ostype.ostypeid,
                    srv.userid,
                    srv.rtime as rtime
                FROM
                    tarif as t,
                    map as m,
                    period as p,
                    location as l,
                    game as g,
                    srv as srv,
                    ostype as ostype,
                    srvtype as stype,
                    user as u,
                    iplist as i
                where
                    stype.stypeid=srv.stypeid
                    and (srv.mapid=m.mapid)
                    and ostype.ostypeid=srv.ostypeid
                    and srv.userid=u.userid
                    and i.ipid=srv.ipid
                    and srv.sid='$srvid'
                    and t.tarifid=srv.tarifid
                    and g.gameid=srv.gameid
                    and l.locationid=srv.locationid
                    and p.periodid=srv.periodid
                ");
        return($srv);
}


sub getsrvinfohash
{
    my $main = shift;
    my $srvid = shift;
    my $srv = $main->{dbcon}->getsimplequeryhash("
                select
                    srv.sid,
                    stype.description as stype,
                    srv.status as status,
                    srv.enabled as enabled,
                    i.ipaddr as ipaddr,
                    ostype.description as ostype,
                    u.login as login,
                    t.description as tarif,
                    g.description as game,
                    p.description as period,
                    l.description as location,
                    m.name as mapname,
                    m.pic as mappic,
                    srv.name as srvname,
                    srv.numslots as numslots,
                    srv.numgamers as numgamers,
                    srv.anticheat as anticheat,
                    srv.addons as addons,
                    srv.mapid as mapid,
                    srv.ftpstatus as ftpstatus,
                    srv.HLTVport as HLTVport,
                    srv.HLDSport as HLDSport,
                    srv.start_time as start_time,
                    srv.stop_time as stop_time,
                    ( UNIX_TIMESTAMP(CURRENT_TIMESTAMP) - UNIX_TIMESTAMP(srv.start_time)) as ltime,
                    p.hours as hours,
                    g.gameid as gameid,
                    t.tarifid as  tarifid,
                    l.locationid as locationid,
                    p.periodid as periodid,
                    ostype.ostypeid as ostypeid,
                    stype.stypeid as stypeid,
                    srv.userid as userid,
                    p.ename as periodname,
                    srv.rtime as rtime
                FROM
                    tarif as t,
                    map as m,
                    period as p,
                    location as l,
                    game as g,
                    srv as srv,
                    ostype as ostype,
                    srvtype as stype,
                    user as u,
                    iplist as i
                where
                    stype.stypeid=srv.stypeid
                    and (srv.mapid=m.mapid)
                    and ostype.ostypeid=srv.ostypeid
                    and srv.userid=u.userid
                    and i.ipid=srv.ipid
                    and srv.sid='$srvid'
                    and t.tarifid=srv.tarifid
                    and g.gameid=srv.gameid
                    and l.locationid=srv.locationid
                    and p.periodid=srv.periodid
                ");
        return($srv);
}

sub DelSrvConfigs
{
    my $main = shift;
    my $sid = shift;
    my ($line,$val);
    my $arr = $main->{dbcon}->getsimplequery("
                select
                    ctable
                FROM
                    srvconfigs
                ");
    foreach my $s (keys %{$arr})
    {
        if($s)
        {
            my $table = $arr->{$s}->[0];
            $line .= &errline(0,"Конфиг $table для SrvID:$sid успешно удален");
            my $sss = $main->{dbcon}->insertsimplequery($main->{dbhlr}, "delete from $table where sid=$sid");
        }
    }

    return($line);

}

sub DelUser
{

    my $main = shift;
    my $userid = shift;
    my ($line,$val);
    my $user2delete = userbyuserid($main,$userid);
    $line  = &errline(1,"Имя пользователя отсутствует!!") if not defined($userid);
    $line  = &errline(1,"Недопустимая операция: Can't delete superuser: $main->{global}->{superuser}") if($user2delete eq $main->{global}->{superuser});
    return $line if($line);

    my $arr = $main->{dbcon}->getsimplequery("
                select
                    sid
                FROM
                    srv
                where
                    userid = '$userid'
                ");
    foreach my $s (keys %{$arr})
    {
        if($s)
        {
            my $sid = $arr->{$s}->[0];
            $line = &DelSrvConfigs($main,$sid);
        }
    }

    my $sss = $main->{dbcon}->insertsimplequery($main->{dbhlr}, "delete from srv where userid = '$userid'");
    $line .= &errline(0,"Удалены сервера для пользователя $userid");
    my $u = $main->{dbcon}->getsimplequeryhash("select userid from user where userid='$userid' and locked=0");
    if($u->{userid} > 0)
    {
        $sss = $main->{dbcon}->insertsimplequery($main->{dbhlr}, "delete from user where userid = '$userid' and locked=0");
        $main->{ftpuser}->{userid} = $userid;
        delftpuser($main);
        $line .= &errline(0,"Пользователь $userid успешно удален");
    }
    else
    {
        $line .= errline(1, "User $userid is locked.");
    }

    return($line);

}


1;
