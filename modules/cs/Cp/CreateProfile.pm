package Cp::CreateProfile;

use strict;
use Exporter;
use FindBin qw($Bin);
use base qw( Exporter );
use CGI qw/:standard/;
use Tt::Pgen;
use Cp::SrvInfo;
use Cp::SrvCfg;
use Tt::Ftp;
use Cp::SrvStatus;
use Tt::CryptPass;
use HTTP::Request::Common qw(POST);
use LWP::UserAgent;
use Tt::Auth;
use Db::Dbgame;
use File::Path qw(rmtree);

our @EXPORT = qw(
        pageform
        checkdata
        checkform
        checkuser
        addnewuser
        addfakeuser
        genserver
        addftpuser
        ftpserver
        delftpuser
        UserProfileForm
        AddDefaultConfigs
        changecfg
        try_user_account
        genpayment
        ChangeServerAfterPayment
        );


sub checkdata
{
    my $main = shift;

    if($main->{profile}->{game}
        && $main->{profile}->{login}
        && $main->{profile}->{srvtype}
        && $main->{profile}->{pass1}
        && $main->{profile}->{pass2}
        && $main->{profile}->{tarif}
        && $main->{profile}->{ostype}
        && $main->{profile}->{slots}
        && $main->{profile}->{period}
        && $main->{profile}->{location})
    {
        return(1) if($main->{profile}->{pass1} eq $main->{profile}->{pass2});
    }

    return(0);
}

sub checkform
{
    my $main = shift;
    my $line;

    return if not($main->{profile}->{submit});

    $line .= "<br>Выберите правильный тип игры" if not ($main->{profile}->{game});
    $line .= "<br>Введите правильный логин" if not ($main->{profile}->{login});
    $line .= "<br>Выберите правильный тип сервера" if not ($main->{profile}->{srvtype});

    if($main->{profile}->{pass1} eq '' or $main->{profile}->{pass2} eq '' or (!($main->{profile}->{pass2} eq $main->{profile}->{pass1})))
    {
        $line .= "<br>Введите пароль и подтверждение пароля <br> Пароль не должен быть менее 8 символов";
    }
    $line .= "<br>Выберите правильный тариф" if not ($main->{profile}->{tarif});
    $line .= "<br>Выберите тип ОС" if not ($main->{profile}->{ostype});
    $line .= "<br>Выберите локацию" if not ($main->{profile}->{location});
    $line .= "<br>Выберите период" if not ($main->{profile}->{period});
    $line .= "<br>Выберите количество слотов" if not ($main->{profile}->{slots});

    return($line);
}

sub checkuser
{
    my $main = shift;
    my $line ;
    my $u = $main->{dbcon}->getsimplequeryhash("select login from user where login='$main->{profile}->{login}';");
    $line = "<br>Пользователь с таким именем уже существует" if($u->{login});
    return $line;
}

sub addPersonalAccount
{
    my $main = shift;
    my $userid = shift;
    my $pid = "100$userid";
    my $acc = $main->{dbcon}->getsimplequeryhash("select pid
                from PersonalAccounts where userid='$userid';") ;
    $main->{dbcon}->insertsimplequery($main->{dbhlr}, "insert into PersonalAccounts
                    set
                        pid = '$pid',
                        userid = '$userid',
                        enabled = 1,
                        summ = 0,
                        CurrId=(select CurrId from currency where name='WME');
                    ") unless $acc->{pid};
    return $main;
}

sub addfakeuser
{
    my $main = shift;
    my $url = $main->{url};
    my $line;
    my $g = $main->{dbcon}->getsimplequeryhash("select gid from groups where gname='users';");
    $g->{weight} =0 unless $g->{weight} > 0;
    my ($pwd,$salt) = cryptpass($main->{profile}->{pass1});
    $main->{dbcon}->insertuser($main->{profile}->{login},$pwd, $salt, $main->{profile}->{email}, $g->{gid});
    $main->{dbcon}->insertsimplequery($main->{dbhlr},"update user set
            role='<rhash><role fakerole=\"1\" users=\"1\" /></rhash>',
            weight='$g->{weight}'
        where
            login='$main->{profile}->{login}';");
    my $userid = $main->{dbcon}->getuserid($main->{profile}->{login});
    my $ipaddr;
    my $ipid = getipid($main);
    my $hltvport = &genport($main,$ipid,28015,60000);
    my $hldsport = &genport($main,$ipid,27015,60000);
    addserver($main, $main->{profile}->{login},$ipid, $hldsport ,$hltvport);
    my $sid = &getsidbyip($main,$ipid, $hltvport, $hldsport);
    my $u = $main->{dbcon}->getsimplequeryhash("select userid from user where login='$main->{profile}->{login}';");
    $main->{ftpuser}->{userid} = $u->{userid};
    $main->{ftpuser}->{sid} = $sid;
    $main->{ftpuser}->{action} = 'install';
    $main->{ftpuser}->{pass} = $main->{profile}->{pass1};
    $main->{ftpuser}->{group} = $main->{ftpc}->{group};
    addPersonalAccount($main,$userid);
    $line .= addftpuser($main);
    $line .= ftpserver($main);
    $line = AddDefaultConfigs($main,$sid) if($sid);
    logdb($main, "addnewuser: user $main->{profile}->{login} was created by $main->{user}");

    $line = "<br>$line" if $line;
    return $line;
}

sub addnewuser
{
    my $main = shift;
    my $url = $main->{url};
    my $line;
    my $g = $main->{dbcon}->getsimplequeryhash("select gid,weight from groups where gname='users';");
    $g->{weight} =0 unless $g->{weight} > 0;
    my ($pwd,$salt) = cryptpass($main->{profile}->{pass1});
    $main->{dbcon}->insertuser($main->{profile}->{login},$pwd, $salt, $main->{profile}->{email}, $g->{gid});
    $main->{dbcon}->insertsimplequery($main->{dbhlr},"update user
        set
            role='<rhash><role fakerole=\"1\" users=\"1\" /></rhash>',
            weight='$g->{weight}'
        where
            login='$main->{profile}->{login}';");
    my $userid = $main->{dbcon}->getuserid($main->{profile}->{login});
    addPersonalAccount($main, $userid);
    my $u = $main->{dbcon}->getsimplequeryhash("select userid from user where login='$main->{profile}->{login}';");
    $main->{ftpuser}->{userid} = $u->{userid};
    $main->{ftpuser}->{action} = 'install';
    $main->{ftpuser}->{pass} = $main->{profile}->{pass1};
    $main->{ftpuser}->{group} = $main->{ftpc}->{group};

    $line .= addftpuser($main);
    $line .= ftpserver($main);
    logdb($main, "addnewuser: user $main->{profile}->{login} was created by $main->{user}");

    $line = "<br>$line" if $line;
    return $line;
}

sub addftpuser
{
    my $main = shift;
    my $url = $main->{ftpc}->{change_user_url};
    my $ua = LWP::UserAgent->new;
    $ua->timeout(3);
    my $req = POST $url,
    [
        user => "u$main->{ftpuser}->{userid}",
        pass => "$main->{ftpuser}->{pass}",
        group => "$main->{ftpc}->{group}",
        userid => "u$main->{ftpuser}->{userid}",
        debug => 4,
    ];
    #    my $res = $ua->request($req);
    my $res = ua_request_with_timeout($ua, $req);
    #    print "Content-Type: text/plain\n\n";
    #    print "<br>userid = $main->{ftpuser}->{userid}<br>";
    #    print $res->content;
    return;
    return $res->content;
}


sub delftpuser
{
    my $main = shift;
    my $url = $main->{ftpc}->{delete_user_url};
    my $ua = LWP::UserAgent->new;
    $ua->timeout(3);
    my $req = POST $url,
    [
        userid => "u$main->{ftpuser}->{userid}",
        debug => 4,
    ];
    my $res = ua_request_with_timeout($ua, $req);
    return;
    return $res->content;
}

sub ftpserver
{
    my $main = shift;

    my $ua = LWP::UserAgent->new;
    my $url = $main->{ftpc}->{server_url};
    $ua->timeout(3);
    my $req = POST $url,
    [
        userid => "u$main->{ftpuser}->{userid}",
        sid => "s$main->{ftpuser}->{sid}",
        action => $main->{ftpuser}->{action},
        debug => 4,
    ];

    my $res = $ua->request($req);
    return;
    return $res->content;

}


sub ua_request_with_timeout
{
    my $ua = shift;
    my $req = shift;
    use Sys::SigAction qw( timeout_call );
    our $res = undef;
    if( timeout_call( 5, sub {$res = $ua->request($req);}) )
    {
        return HTTP::Response->new( 408 );
    }
    else
    {
        return $res;
    }
}


sub genserver
{
    my $main = shift;
    my $userid = $main->{dbcon}->getuserid($main->{profile}->{login});
    my $ipaddr;
    my $ipid = getipid($main);
    unless ($ipid)
    {
        $main->{errline} .= 'No ip-address was found... Sorry';
        return $main->{errline};
    }
    my $hltvport = &genport($main,$ipid,28015,60000);
    my $hldsport = &genport($main,$ipid,27015,60000);
    addserver($main, $main->{profile}->{login},$ipid, $hldsport ,$hltvport);
    my $sid = &getsidbyip($main,$ipid, $hltvport, $hldsport);
    my $u = $main->{dbcon}->getsimplequeryhash("select userid from user where login='$main->{profile}->{login}';");
    $main->{status_flag} = 'ok';
    $main->{profile}->{sid} = $sid;
    $main->{ftpuser}->{userid} = $u->{userid};
    $main->{ftpuser}->{sid} = $sid;
    $main->{ftpuser}->{action} = 'install';
    $main->{ftpuser}->{group} = $main->{ftpc}->{group};
    $main->{errline} .= addftpuser($main);
    $main->{errline} .= ftpserver($main);
    $main->{errline} = AddDefaultConfigs($main,$sid) if($sid);
    logdb($main, "genserver: server sid:$sid created by $main->{user} for $main->{profile}->{login}");
    return $main;
}

sub createuserprofile
{
    my $main = shift;
    $main->{errline} = checkform($main);
    $main->{errline} .= checkuser($main) if $main->{addlogin};

    return $main if ($main->{errline});

    $main->{profile}->{srvname} = "New server for user $main->{profile}->{login}";

    $main->{errline} .= addnewuser($main) if($main->{addlogin});
    $main->{profile}->{userid} = useridbyuser($main,$main->{profile}->{login});
    $main->{res} = $main->{profile};
    $main->{form} = $main->{profile};
    $main = try_user_account($main);
    $main = genpayment($main) if $main->{status_flag} eq 'fail';
    $main->{success} = errline(0,'Заказ успешно создан') if $main->{status_flag} eq 'ok';
    return $main;
}

sub UserProfileForm
{
    my $main = shift;
    $main->{addlogin} = shift;
    my $object = shift || 'myserver';
    $main->{profile}->{userpayment} = 1 if $object eq 'myserver';

    $main->{eventhash} = {  create => 'c'  };
    $main = AuthUserActionHash($main, $object, 'ObjectClass', 'create');

    $main->{profile}->{email} = $main->{addlogin} eq '1' ? getval($main, 'email') : 'fake@user.com';
    $main->{profile}->{pass1} = $main->{addlogin} eq '1' ? getval($main, 'pass1') : 'xxxxxxxxx';
    $main->{profile}->{pass2} = $main->{addlogin} eq '1' ? getval($main, 'pass2') : 'xxxxxxxxx';
    $main->{profile}->{login} = $main->{addlogin} eq '1' ? getval($main, 'login') : $main->{user};
    $main->{profile}->{game} = getval($main, 'game');
    $main->{profile}->{tarif} = getval($main, 'tarif');
    $main->{profile}->{ostype} = getval($main, 'ostype');
    $main->{profile}->{period} = getval($main, 'period');
    $main->{profile}->{srvtype} = getval($main, 'srvtype');
    $main->{profile}->{location} = getval($main, 'location');
    $main->{profile}->{slots} = getval($main, 'slots');
    $main->{profile}->{summa} = getval($main, 'summa');
    $main->{profile}->{OutSum} = $main->{profile}->{summa};
    $main->{profile}->{IncCurrLabel} = 'WME';
    $main->{profile}->{submit} = getval($main, 'submit');

    my $rperiod = $main->{dbcon}->getsimplequeryhash("select periodid,description,ename,hours from period where ename='$main->{profile}->{period}' and enabled=1");
    $main->{profile}->{period} = $rperiod->{periodid};
    $main = createuserprofile($main) if($main->{profile}->{submit});

    $main->{rsrvtype} = $main->{dbcon}->getsimplequery("select stypeid,description from srvtype");
    $main->{rgame} = $main->{dbcon}->getsimplequery("select gameid,name,hids from game");
    return $main;
}

sub extendserver
{
    my $main = shift;
    if ($main->{srvinfo}->{enabled} )
    {
        $main->{status_flag} = 'ok';
        $main->{errline} = errline(0,"Сервер $main->{profile}->{sid} включен ... ");
        return $main;
    }

    setsrvstatus($main,'enable',$main->{res}->{sid}, 'enabled') ;
    my $s = $main->{dbcon}->insertsimplequery($main->{dbhlr}, "
                                            update srv set
                                            numslots = '$main->{res}->{slots}',
                                            periodid = '$main->{res}->{period}'
                                            where sid='$main->{res}->{sid}'
    ;");

    $main->{status_flag} = 'ok';
    return $main;
}

sub try_user_account
{
    my $main = shift;
    my $rcurr;

    $rcurr = $main->{dbcon}->getsimplequeryhash("select CurrId from currency where name='$main->{res}->{IncCurrLabel}';") if $main->{res}->{IncCurrLabel};
    $rcurr->{CurrId} = $rcurr->{CurrId} || $main->{res}->{CurrId};
    my $pacc = $main->{dbcon}->getsimplequeryhash("select * from PersonalAccounts where userid=$main->{res}->{userid};");
    unless ($pacc->{CurrId} eq $rcurr->{CurrId})
    {
        $main->{errline} = errline(1,"Currency does not match!");
        $main->{status_flag} = 'fail';
        return $main;
    }
    unless ($pacc->{summ} >= $main->{res}->{OutSum} )
    {
        $main->{errline} = errline(1,"Недостаточно средств для оплаты заказа: $main->{res}->{OutSum} > $pacc->{summ} ");
        $main->{status_flag} = 'fail';
        return $main;
    }
    my $dsumm = $main->{res}->{OutSum} || $main->{profile}->{summa};
    my $newsumm = $pacc->{summ} - $dsumm;
    $main = genserver($main) unless $main->{res}->{sid};
    $main = extendserver($main) if $main->{res}->{sid};
    return $main unless $main->{status_flag} eq 'ok';
    return $main if $main->{srvinfo}->{enabled};

    my $s = $main->{dbcon}->insertsimplequery($main->{dbhlr}, "
                                            update PersonalAccounts set
                                            summ='$newsumm'
                                            where userid='$main->{res}->{userid}'
                                            and summ='$pacc->{summ}'
                                        ");
    logdb($main, "PersonalAccounts: updated summ: $pacc->{summ} - $dsumm = $newsumm for userid $main->{res}->{userid}");

    my $payrec;
    $payrec->{summ} = $dsumm;
    $payrec->{dkflag} = 0;
    $payrec->{userid} = $main->{res}->{userid};
    $payrec->{CurrId} = $pacc->{CurrId};
    $payrec->{event} = "[D] Updated summ: $pacc->{summ} -> $newsumm";
    paylog($main, $payrec);

    $main->{status_flag} = 'ok';
    $main->{errline} .= errline(0, "Сервер включен, $main->{profile}->{summa} $main->{profile}->{IncCurrLabel} списано с кошелька ");
    return $main;
}

sub genpayment
{
    my $main = shift;
    my $sid = $main->{profile}->{sid} || 'NULL';
    my $userid = $main->{profile}->{userid};
    my $u = $main->{dbcon}->getsimplequeryhash("select userid from user where login='$main->{profile}->{login}';") unless $userid;
    $userid = $u->{userid} unless $userid;
    my $description = $main->{profile}->{description};
    $description = "New game server for user $main->{profile}->{login}" unless $description;

    my $s = $main->{dbcon}->insertsimplequery($main->{dbhlr}, "insert into payments
                    set
                    userid='$userid',
                    gameid='$main->{profile}->{game}',
                    tarifid='$main->{profile}->{tarif}',
                    ostypeid='$main->{profile}->{ostype}',
                    periodid='$main->{profile}->{period}',
                    stypeid='$main->{profile}->{srvtype}',
                    locationid='$main->{profile}->{location}',
                    numslots='$main->{profile}->{slots}',
                    summ='$main->{profile}->{summa}',
                    paccflag='$main->{profile}->{paccflag}',
                    description='$description',
                    ctime = CURRENT_TIMESTAMP,
                    pflag=1,
                    CurrId=1,
                    sid=$sid
    ");
    if ($main->{profile}->{login} and $sid >0)
    {
        logdb($main, "payments: new order for login $main->{profile}->{login} summ=$main->{profile}->{summa}, sid=$sid");
    }
    else
    {
        logdb($main, "payments: new order for userid:$userid summ=$main->{profile}->{summa}");
    }
    $main->{status_flag} = 'ok';
    $main->{errline} .= errline(0, "Заказ добавлен в корзину");
    return $main;
}


sub getipid
{
    my $main = shift;
    my $ipid;

    my $rhids = $main->{dbcon}->getsimplequery("select hid from gamehw where gameid=$main->{form}->{game}; ");
    my @hids;
    foreach my $ss (keys %{$rhids})
    {
        push @hids, $rhids->{$ss}->[0];
    }
    foreach my $s (@hids)
    {
        my $rip = $main->{dbcon}->getsimplequeryhash("select ip.ipid,ip.ipaddr
                                        from
                                            iplist as ip, hw as hw
                                        where
                                            hw.locationid='$main->{form}->{location}'
                                            and hw.hid=ip.hid and hw.enabled=1
                                            and ip.hid=$s
                                            limit 1");
        $ipid = $rip->{ipid} if($rip and $rip > 0);
        last;
    }

    return($ipid);
}


sub genport
{
    my $main = shift;
    my $ipid = shift;
    my $from = shift;
    my $to = shift;
    my $ss;
    my $port;
    my $rsock = $main->{dbcon}->getsimplequery("select ipid,HLTVport, HLDSport
                                        from
                                            srv
                                        where ipid=$ipid
                                            ");

    foreach my $s (keys %{$rsock})
    {
        if($s)
        {
            my $p1 = $rsock->{$s}->[1];
            $ss->{$p1} = $p1;
            my $p2 = $rsock->{$s}->[2];
            $ss->{$p2} = $p2;
        }
    }

    for(my $i=$from; $i<=$to; $i++)
    {

        if(not defined($ss->{$i}))
        {
            $port = $i;
            last;
        }
    }

    return($port);

}

sub addserver
{
        my $main = shift;
        my $user = shift;
        my $ipid = shift;
        my $hldsport = shift;
        my $hltvport = shift;
        $ipid = '1000' unless ($ipid);

        my $userid = $main->{dbcon}->getuserid($user);
        $main->{dbcon}->insertsimplequery($main->{dbhlr}, "insert into
                                             srv(userid,
                                             stypeid,
                                             tarifid,
                                             ostypeid,
                                             periodid,
                                             locationid,
                                             gameid,
                                             ipid,
                                             numslots,
                                             mapid,
                                             name,
                                             anticheat,
                                             addons,
                                             HLTVport,
                                             HLDSport,
                                             enabled
                                             )
                                    values
                                            ('$userid',
                                             '$main->{form}->{srvtype}',
                                             '$main->{form}->{tarif}',
                                             '$main->{form}->{ostype}',
                                             '$main->{form}->{period}',
                                             '$main->{form}->{location}',
                                             '$main->{form}->{game}',
                                             '$ipid',
                                             '$main->{form}->{slots}',
                                             '1',
                                             '$main->{form}->{srvname}',
                                             '1',
                                             '1;2;',
                                             '$hltvport',
                                             '$hldsport',
                                             '1')");

    logdb($main, "srv: new server created for userid: $userid slots: $main->{form}->{slots}");
    return(0);
}

sub AddDefaultConfigs
{
    my $main = shift;
    my $sid = shift;
    my ($line,$val, $ftpstatus);
    my $arr = $main->{dbcon}->getsimplequery("select ctable
                                FROM
                                    srvconfigs
                                    ");
    my $userid = useridbysid($main, $sid);
    $line = "No userid for sid $sid" if $line;
    return $line if $line;

    foreach my $s (keys %{$arr})
    {
        if($s)
        {
            my $table = $arr->{$s}->[0];
            my $rv = $main->{dbcon}->getsimplequery("select s.value, s.name, c.path
                                FROM
                                    srvconfigs as s, configcategory as c
                                where
                                    s.ctable = '$table' and s.category=c.cid
                                    ");
            my $value = $rv->{1}->[0];
            my $cname = $rv->{1}->[1];
            my $cpath = $rv->{1}->[2];
            my $errline .= changecfg($value,$table,$sid,$main, $ftpstatus);
            $ftpstatus = 1 if($errline);
            $line .= $errline;
            $line .= &errline(0,"Конфиг $cpath/$cname ($table) для SrvID:$sid успешно создан") if $line !~ /FTP/;
        }
    }

    return($line);

}

sub changecfg
{
    my $line = shift;
    my $table = shift;
    my $sid = shift;
    my $main = shift;
    my $ftpstatus = shift;
    my ($status,$s);
    return(0) if(not $line or not defined($sid));
    my $csid = $main->{dbcon}->getsimplequery("
                    select
                        sid
                    FROM
                        $table
                    where
                        sid='$sid'
                    ");

    foreach my $s (keys %{$csid})
    {
        $status = 1 if($s);
    }
    if(defined($status))
    {
        $s = $main->{dbcon}->updateftemplatedata($line,$sid,"update $table set value=? where sid = ? ");
    }
    else
    {
        $s = $main->{dbcon}->insert1linequery($main->{dbhlr}, "
                insert into
                    $table(sid,value)
                values(
                    '$sid',
                    ?);", $line);

    }

    my $userid = useridbysid($main, $sid);
    my $rv = $main->{dbcon}->getsimplequeryhash("
                select
                    s.name, c.path
                FROM
                    srvconfigs as s, configcategory as c
                where
                    s.ctable = '$table' and s.category=c.cid
                ");
    my $cpath = $rv->{path};
    my $cname = $rv->{name};
    my $fpath = "u$userid/s$sid/$cpath";
    my $errline = uploadconfig($main->{ftpc}->{host},
                        $main->{ftpc}->{user},
                        $main->{ftpc}->{pass},
                        $fpath,
                        $cname,
                        $line) unless $ftpstatus;

    return($errline);

}

sub ChangeServerAfterPayment
{
    my $main = shift;
    my $sid = $main->{profile}->{sid};
    my $userid = $main->{profile}->{userid};
    addPersonalAccount($main,$userid);
    $main->{profile}->{login} = userbyuserid($main, $userid);
    $main->{res} = $main->{profile};
    $main->{form} = $main->{profile};

    if($main->{srvinfo}->{enabled})
    {
        $main->{errline} = errline(1, "Сервер уже включен ... ");
        $main->{status_flag} = 'ok';
        return $main;
    }
    $main = try_user_account($main);
    return $main;
}

1;
