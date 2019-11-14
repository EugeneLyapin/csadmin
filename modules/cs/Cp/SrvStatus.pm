package Cp::SrvStatus;

use strict;
use Exporter;
use FindBin qw($Bin);
use base qw( Exporter );
use CGI qw/:standard/;
use Tt::Pgen;
use Tt::Ftp;
use Cp::SrvCfg;
use Cp::SrvInfo;
use Cp::CreateProfile;
use HTTP::Request::Common qw(POST);
use POSIX qw(strftime);
use LWP::UserAgent;

our @EXPORT = qw(
            genareasrvstatus
            genhldsconfig
            srvaction
            setsrvstatus
        );

sub genareasrvstatus
{
    my $main = shift;
    my ($srvs,$srvid) = getservers($main,$main->{user}, $main->{admin}->{sid});
    $main->{sflag} = 1 unless $srvid >0;
    return $main  unless $srvid >0;
    $main->{srvs} = $srvs;
    $main->{srvid} = getval($main, 'srvid') || $srvid;
    my $prmap = getsrvcfg($main,$srvid,'mapcycle_txt');
    $main->{rmap} = parsecfg($prmap);

    my $action = getval($main, 'action');
    my $sid = getval($main, 'sid');
    my $changesrvname = getval($main, 'changesrvname');
    my $submitname = getval($main, 'submitname');
    my $submitmap = getval($main, 'submitmap');
    my $mapname = getval($main, 'mapname');

    my ($m, $mapid);
    my $map = $main->{dbcon}->getsimplequery("select mapid,name,pic,description from map");
    my $acc = $main->{dbcon}->getsimplequery("select mapid,name,pic,description from map");
    changesrvname($main,$main->{getform}->{fsrvname},$sid) if $submitname;
    changemapid($main,$mapname,$sid) if $submitmap;
    $main = changeaction($main, $action, $sid) if $action;

    my $srv = getsrvinfo($main,$srvid);

        foreach my $s (sort keys %{$srv})
        {
            $m = &createarrsrv($main,$srv,$s,$map);
            $mapid = $m->{'srv.mapid'};
        }

    $main->{srvinfo} = $m;
    my $acc = $main->{dbcon}->getsimplequeryhash("
                select
                    p.summ,c.name
                from
                    PersonalAccounts as p, currency as c
                where
                    c.CurrId=p.CurrId
                    and p.enabled=1
                    and p.userid='$main->{srvinfo}->{userid}'
                ");
    $main->{srvinfo}->{summ} = $acc->{summ};
    $main->{srvinfo}->{CurrName} = $acc->{name};
    return $main;
}

sub createarrsrv
{
    my $main = shift;
    my $srv = shift;
    my $s = shift;
    my $map = shift;
    my $m;

    my $acheat = $main->{dbcon}->getsimplequery("select acheatid,name from anticheat");
    my $addons = $main->{dbcon}->getsimplequery("select aid,name from addons");

    $acheat = transform($acheat);
    $addons = transform($addons);

    $m->{'srv_sid'} = $srv->{$s}->[0];
    $m->{'stype_description'} = $srv->{$s}->[1];
    $m->{'status'} = $srv->{$s}->[2];
    $m->{'enabled'} = $srv->{$s}->[3];
    $m->{'ipaddr'} = $srv->{$s}->[4];
    $m->{'ostype_description'} = $srv->{$s}->[5];
    $m->{'u_login'} = $srv->{$s}->[6];
    $m->{'tarif_description'} = $srv->{$s}->[7];
    $m->{'game_description'} = $srv->{$s}->[8];
    $m->{'period_description'} = $srv->{$s}->[9];
    $m->{'l_description'} = $srv->{$s}->[10];
    $m->{'map_name'} = $srv->{$s}->[11];
    $m->{'map_pic'} = $srv->{$s}->[12];
    $m->{'srv_name'} = $srv->{$s}->[13];
    $m->{'srv_numslots'} = $srv->{$s}->[14];
    $m->{'srv_numgamers'} = $srv->{$s}->[15];
    $m->{'srv_anticheat'} = $srv->{$s}->[16];
    $m->{'srv_addons'} = $srv->{$s}->[17];
    $m->{'srv_mapid'} = $srv->{$s}->[18];
    $m->{'srv_ftpstatus'} = $srv->{$s}->[19];
    $m->{'srv_HLTVport'} = $srv->{$s}->[20];
    $m->{'srv_HLDSport'} = $srv->{$s}->[21];
    $m->{'start_time'} = $srv->{$s}->[22];
    $m->{'stop_time'} = $srv->{$s}->[23];
    $m->{'ltime'} = $srv->{$s}->[24];
    $m->{hours} = $srv->{$s}->[25];
    $m->{gameid} = $srv->{$s}->[26];
    $m->{tarifid} = $srv->{$s}->[27];
    $m->{locationid} = $srv->{$s}->[28];
    $m->{periodid} = $srv->{$s}->[29];
    $m->{ostypeid} = $srv->{$s}->[30];
    $m->{userid} = $srv->{$s}->[31];

    my $srvtimes = $main->{dbcon}->getsimplequeryhash("
                        select
                            sid,
                            etime
                        from
                            srvtimes
                        where
                            sid='$m->{srv_sid}'
                        ");
    $m->{etime} = sprintf( "%.0f",  $m->{hours}*3600 - ( $srvtimes->{etime} + $m->{ltime} )) if $m->{'enabled'};
    $m->{etime_hours} = sprintf( "%.0f", $m->{etime}/3600 )  if $m->{'enabled'};
    $m->{etime_days} = sprintf( "%.0f", $m->{etime_hours}/24 ) if $m->{'enabled'};
    $m->{etime_months} = sprintf( "%.0f", $m->{etime_days}/31 ) if $m->{'enabled'};
    $m->{gtime} = strftime "%s", gmtime;
    $m->{payed_till} = $m->{gtime}+$m->{etime};
    $m->{payed_till} = strftime "%Y-%m-%d %H:%M:%S", localtime ($m->{payed_till});

    unless ($m->{enabled})
    {
        $m->{enabled}="Disabled";
    }
    else
    {
        $m->{enabled}="Enabled";
    }

    if($m->{'status'})
    {
        $m->{statuspic}="i-agree.gif";
        $m->{altaction}="Выключить";
        $m->{action}="stop";
        $m->{'srv_status'}="Включен";
    }
    else
    {
        $m->{statuspic}="i-stop.gif";
        $m->{altaction}="Включить";
        $m->{action}="start";
        $m->{'srv_status'}="Выключен";
    }

    if(not $m->{'srv_numgamers'})
    {
        $m->{'srv_numgamers'}=0;
    }
    my @adarr = split(/;/,$m->{'srv_addons'});

    my $addline;
    foreach (@adarr)
    {
        $addline .= $addons->{$_};
        $addline .= '; ';
    }
    $m->{addline} = $addline;

    my $achid = $m->{'srv_anticheat'};
    $m->{'srv_anticheat'} = "$acheat->{$achid}";


    foreach my $s (keys %{$map})
    {
        if($s)
        {
            if($map->{$s}->[0] eq $m->{'srv_mapid'})
            {
                $m->{mapname} = $map->{$s}->[1];
                $m->{mappic} = $map->{$s}->[2];
            }
        }
    }

    return($m);


}

sub transform
{
    my $arr = shift;
    foreach my $s (sort keys %{$arr})
    {
        my $k = $arr->{$s}->[0];
        $arr->{$k} = $arr->{$s}->[1];
    }

    return($arr);
}

sub changesrvname
{
    my $main = shift;
    my $srvname = shift;
    my $sid = shift;

    return(0) if(not defined($srvname) or not defined($sid));
    my $s = $main->{dbcon}->insertsimplequery($main->{dbhlr}, "
                update
                    srv
                set
                    name='$srvname'
                where
                    sid=$sid
                ");
    return($s);
}

sub changemapid
{
    my $main = shift;
    my $mapname = shift;
    my $sid = shift;
    return(0) if(not defined($mapname) or not defined($sid));
    my $s = $main->{dbcon}->insertsimplequery($main->{dbhlr}, "
                update
                    srv as s, map as m set s.mapid=m.mapid
                where
                    m.name='$mapname'
                    and sid=$sid
                ");
    return($s);

}
sub changeaction
{
    my $main = shift;
    my $action = shift;
    my $sid = shift;
    my $status;

    return $main if(not defined($action) or not defined($sid));

    return $main if $action eq 'genpayment';

    $status = 0 if($action eq "stop");
    $status = 1 if($action eq "start");
    $main->{userid} = useridbyuser($main, $main->{user});
    $main->{sid} = $sid;
    $main->{action} = $action;
    $main->{errline} = genhldsconfig($main);
    ### may be it would be usefull
    return $main if $main->{errline} =~ /FTP/ and $action eq 'start';
    $main->{errline} .= srvaction($main,$action);
    my $s = $main->{dbcon}->insertsimplequery($main->{dbhlr}, "
                update
                    srv
                set
                    start_time = CURRENT_TIMESTAMP,
                    stop_time = NULL,
                    status=$status
                where
                    sid=$sid
                ") if $status eq 1;

    if ( $status eq 0 )
    {
        $s = $main->{dbcon}->insertsimplequery($main->{dbhlr}, "
                update
                    srv
                set
                    stop_time = CURRENT_TIMESTAMP,
                    status=$status
                where
                    sid=$sid
                ");
        $s = $main->{dbcon}->getsimplequeryhash("
                select
                    ( UNIX_TIMESTAMP(stop_time)-UNIX_TIMESTAMP(start_time) ) as etime
                from
                    srv
                where
                    sid=$sid;
                ");

        return $main if $s->{etime} < 0;
        my $se = $main->{dbcon}->getsimplequeryhash("
                    select
                        etime
                    from
                        srvtimes
                    where
                        sid=$sid
                    ");
        my $n = $main->{dbcon}->insertsimplequery($main->{dbhlr}, "
                    update
                        srvtimes
                    set
                        etime=etime+$s->{etime}
                    where
                        sid=$sid
                    ") if $se->{etime};
        my $n = $main->{dbcon}->insertsimplequery($main->{dbhlr}, "
                    insert into
                        srvtimes
                    set
                        sid=$sid,
                        etime=$s->{etime}
                    ") unless $se->{etime};
    }
    
    logdb($main, "changeaction sid: $sid, action: $action, status: $status .. done");

    return $main;
}

sub genhldsconfig
{
    my $main = shift;
    my $DIR = $main->{ftpc}->{dir};
    my $userid = $main->{userid};
    my $sid = $main->{sid};
    my $srv = $main->{dbcon}->getsimplequeryhash("
                select
                    srv.sid,
                    srv.name,
                    srv.numslots,
                    map.name as mapname,
                    srv.HLDSport,
                    srv.HLTVport,
                    i.ipaddr
                from map as map,
                     srv as srv, iplist as i
                where
                    i.ipid=srv.ipid
                    and map.mapid=srv.mapid
                    and srv.sid=$sid
                ");

    $DIR .= "\\u$userid\\s$sid\\";
    my $fpath = "u$userid/s$sid";

    my $line = sprintf <<A;
<?xml version="1.0" encoding="ISO-8859-1" standalone="no" ?>
<Service>
 <Program>
  <Name>s$sid</Name>
  <DisplayName>$srv->{name} $sid for user u$userid</DisplayName>
  <DisplayNamePrefix></DisplayNamePrefix>
  <Description>$srv->{name} $sid for user u$userid</Description>
<WorkingDir>$DIR</WorkingDir>
<Executable>$DIR\hlds.exe</Executable>
<Parameters>-console -game cstrike +port $srv->{HLDSport} +ip $srv->{ipaddr} +map $srv->{mapname} +maxplayers $srv->{numslots} -noipx +sv_lan 1 -nomaster</Parameters>
  <Delay>0</Delay>
  <StartUpMode>0</StartUpMode>
  <ConsoleApp>false</ConsoleApp>
  <ForceReplace>true</ForceReplace>
 </Program>
 <Options>
  <AffinityMask>1</AffinityMask>
  <Priority>0</Priority>
  <AppendLogs>true</AppendLogs>
  <EventLogging>true</EventLogging>
  <InteractWithDesktop>false</InteractWithDesktop>
  <PreLaunchDelay>0</PreLaunchDelay>
  <StartUpMode>1</StartUpMode>
  <UponExit>1</UponExit>
  <UponFlap>0</UponFlap>
  <FlapCount>10</FlapCount>
  <ShutdownDelay>5000</ShutdownDelay>
  <ShowWindow>0</ShowWindow>
  <JobType>0</JobType>
  <IgnoreFlags>3</IgnoreFlags>
 </Options>
<RedirectIO>
<Stdout>$DIR\hlds.log</Stdout>
<Stderr>$DIR\hlds.log</Stderr>
</RedirectIO>
<Debug>
<DebugEnabled>true</DebugEnabled>
<DebugLocation>$DIR\hlds-debug.log</DebugLocation>
</Debug>
</Service>
A
    my $errline = uploadconfig($main->{ftpc}->{host},
                        $main->{ftpc}->{user},
                        $main->{ftpc}->{pass},
                        $fpath,
                        'hlds.xml',
                        $line);
    return $errline;
}

sub srvaction
{
    my $main = shift;
    my $action = shift;

    my $ua = LWP::UserAgent->new;
    my $url = $main->{ftpc}->{hlds_url};
    # http://192.168.10.2/cgi-bin/hlds.pl?userid=u41&sid=s49&action=stop&debug=3
    my $req = POST $url,
        [
            userid => "u$main->{userid}",
            sid => "s$main->{sid}",
            action => $action,
            debug => 3,
        ];
    my $res = $ua->request($req);

    return $res->content;


}

sub setsrvstatus
{
    my $main = shift;
    my $action = shift;
    my $sid = shift;
    my $col = shift;
    my $s;
    my $status = 1;
    $status = 0 if($action eq 'disable');
    my $line;
    if($col eq 'status')
    {
        $main->{sid} = $sid;
        $main->{action} = $action;
        $main->{userid} = useridbysid($main,$sid);
        $line = genhldsconfig($main);
        $main->{errline} .= $line;
        return $main if $line =~ /FTP/ and $action eq 'start';
        my $ac = 'stop';
        $ac = 'start' if $status;
        srvaction($main,$ac);
        $s = $main->{dbcon}->insertsimplequery($main->{dbhlr}, "
                update
                    srv
                set
                    status=1,
                    start_time=CURRENT_TIMESTAMP,
                    stop_time = NULL
                where
                    sid=$sid
                    and enabled=1
                ") if $status;

        if ( $status eq 0 )
        {
            $s = $main->{dbcon}->insertsimplequery($main->{dbhlr}, "
                    update
                        srv
                    set
                        stop_time = CURRENT_TIMESTAMP,
                        status=$status
                    where
                        sid=$sid
                    ");
            $s = $main->{dbcon}->getsimplequeryhash("
                    select
                        ( UNIX_TIMESTAMP(stop_time)-UNIX_TIMESTAMP(start_time) ) as etime
                    from
                        srv
                    where
                        sid=$sid;
                    ");
            return $main if $s->{etime} < 0;
            my $se = $main->{dbcon}->getsimplequeryhash("
                        select
                            etime
                        from
                            srvtimes
                        where
                            sid=$sid
                        ");
            my $n = $main->{dbcon}->insertsimplequery($main->{dbhlr}, "
                        update
                            srvtimes
                        set
                            etime=etime+$s->{etime}
                        where
                            sid=$sid
                        ") if $se->{etime};
            my $n = $main->{dbcon}->insertsimplequery($main->{dbhlr}, "
                        insert into
                            srvtimes
                        set
                            sid=$sid,
                            etime=$s->{etime}
                        ") unless $se->{etime};
        }

        return $main;
    }

    $s = $main->{dbcon}->insertsimplequery($main->{dbhlr}, "
            update
                srv
            set
                $col = '$status'
            where
                sid='$sid'
            ") if $col eq 'enabled';
    $s = $main->{dbcon}->insertsimplequery($main->{dbhlr}, "
            delete from
                srvtimes
            where
                sid='$sid'
            ") if $action eq 'disable';
    $s = $main->{dbcon}->insertsimplequery($main->{dbhlr}, "
            insert into
                srvtimes
            set
                sid='$sid',
                etime=0
            ") if $action eq 'enable';
    $main->{status_flag} = 'ok';
    logdb($main, "setsrvstatus sid: $sid, action: $action, status: $status .. done");
    return $main;
}

1;
