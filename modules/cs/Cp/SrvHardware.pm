package Cp::SrvHardware;

use strict;
use Exporter;
use FindBin qw($Bin);
use base qw( Exporter );
use CGI qw/:standard/;
use Tt::Pgen;

our @EXPORT = qw(
            getsrvhw
            linksrvhw
            );

sub getmhid
{
    my $main = shift;
    my $mhid = $main->{dbcon}->getsimplequery("
                select
                    h.hid ,
                    h.name,
                    l.description,
                    o.description,
                    ip.ipaddr,
                    h.mcpu,
                    h.cpuslots,
                    h.ftpport,
                    h.sshport,
                    h.price,
                    h.enabled
                 from
                    hw as h,
                    location as l,
                    iplist as ip,
                    ostype as o
                where
                    ip.role = 'main'
                    and o.ostypeid = h.ostype
                    and h.locationid = l.locationid
                    and h.hid = ip.hid;
                ");
    return $mhid;
}

sub getsrvhw
{
    my $main = shift;
    my $url = shift;
    my $line;
    my $mhid = getmhid($main);
    my $msid;
    $line .= sprintf <<A;
    <br>
        <table class=wrapper>
        <tr>
        <th>ID</th>
        <th>Название</th>

        <th>Локация</th>
        <th>IP-адрес</th>
        <th>Слотов</th>
        <th>Статус</th>
        <th>Ping</th>
        <th colspan=2>Свойства</th>
        </tr>

A
    for my  $ss (sort keys %{$mhid})
    {

        if($ss)
        {
            $msid->{hid} = $mhid->{$ss}->[0];
            $msid->{name} = $mhid->{$ss}->[1];
            $msid->{location} = $mhid->{$ss}->[2];
            $msid->{ostype} = $mhid->{$ss}->[3];
            $msid->{ipaddr} = $mhid->{$ss}->[4];
            $msid->{mcpu} = $mhid->{$ss}->[5];
            $msid->{cpuslots} = $mhid->{$ss}->[6];
            $msid->{enabled} = $mhid->{$ss}->[10];

            if($msid->{enabled})
            {
                $msid->{enabled} = 'Да';
                $msid->{'action-enabled'} = 'disable';
                $msid->{'pic-enabled'} = 'i-agree.gif';
            }
            else
            {
                $msid->{enabled} = 'Нет';
                $msid->{'action-enabled'} = 'enable';
                $msid->{'pic-enabled'} = 'i-stop.gif';
            }


            $line .= sprintf <<A;
            <form action=$url name="msid" method=POST>
            <input type="hidden" name=hid value=$msid->{hid}>
            <tr>
            <td>$msid->{hid}</a></td>
            <td><a href=$url?hid=$msid->{hid}&action=details>$msid->{name}</a></td>
            <td>$msid->{location}</td>
            <td>$msid->{ipaddr}</td>
            <td align=center>$msid->{cpuslots}</td>
            <td align=center><a href=$url?hid=$msid->{hid}&action=$msid->{'action-enabled'}><img src=/img/$msid->{'pic-enabled'} style="background-color:transparent;border:0px;" ></a></td>
            <td>$msid->{ping}</td>
            <td>
            <select name=action-$msid->{hid} id=action STYLE="width: 120px">
            <option value=empty >----------------</option>
            <option value=stats >Статистика</option>
            <option value=details >Подробнее</option>
            <option value=addsrv>Добавить сервер</option>
            <option value=delsrv>Удалить сервер</option>
            </option>
            </td>
            <td align=center>
            &nbsp;&nbsp;<input name=submitaction-$msid->{hid} value='Go' style="background-color:transparent;border:0px;" type=image border=0 src=/img/bullet9.gif>
            &nbsp;<input name=deletehid-$msid->{hid} value=delsrv style="background-color:transparent;border:0px;" type=image border=0 src=/img/i-delete.gif>
            </td>

            </tr>
            </form>
A
        }
    }

    $line .= sprintf <<A;
        </TABLE>
        <br>
            <form action=$url name="msid" method=POST>
            <input type="submit" name=addsrv value ='Добавить'>
            </form>
A

    return $line;
}

sub linksrvhw
{
    my $main = shift;
    my $chids = shift;
    my $url = shift;
    my $line;
    my $mhid = getmhid($main);
    my $msid;
    $line .= sprintf <<A;
    <br>
        <table class=wrapper>
        <tr>
        <th>ID</th>
        <th>Название</th>

        <th>Локация</th>
        <th>IP-адрес</th>
        <th>Слотов</th>
        <th>Платформа</th>
        <th>Статус</th>
        <th>Привязка</th>
        </tr>

A
    for my  $ss (sort keys %{$mhid})
    {
        if($ss)
        {
            $msid->{hid} = $mhid->{$ss}->[0];
            $msid->{name} = $mhid->{$ss}->[1];
            $msid->{location} = $mhid->{$ss}->[2];
            $msid->{ostype} = $mhid->{$ss}->[3];
            $msid->{ipaddr} = $mhid->{$ss}->[4];
            $msid->{mcpu} = $mhid->{$ss}->[5];
            $msid->{cpuslots} = $mhid->{$ss}->[6];

            my $hid = $msid->{hid};
            my $cstatus = 'checked' if($chids->{$hid});

            $line .= sprintf <<A;
            <tr>
            <td>$msid->{hid}</a></td>
            <td><a href=$url?hid=$msid->{hid}&action=details>$msid->{name}</a></td>
            <td align=center>$msid->{location}</td>
            <td align=center>$msid->{ipaddr}</td>
            <td align=center>$msid->{cpuslots}</td>
            <td>$msid->{ostype}</td>
            <td align=center>$msid->{status}</td>
            <td align=center>
            <input type=checkbox name="chbox-$msid->{hid}" value="$msid->{hid}" $cstatus >
            </td>

            </tr>
A
        }
    }

    $line .= sprintf <<A;
        </TABLE>
A

    return $line;
}

1;
