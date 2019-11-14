package Cp::Payment;

use strict;
use Exporter;
use FindBin qw($Bin);
use base qw( Exporter );
use Tt::Pgen;
use Tt::CheckDate;
use Tt::Error;
use Cp::CreateProfile;
use Cp::SrvInfo;
use Tt::Auth;
use HTTP::Request::Common qw(POST);

our @EXPORT = qw(
        genpaydata
        );

sub genpaydata
{
    my $main = shift;
    my $object = shift;
    my $action;
    $main->{pay}->{userid} = getval($main, 'userid');
    my $InvId = getval($main, 'InvId');
    $main->{pay}->{userid} = $main->{ud}->{userid} if $object eq 'myacc';
    $main->{pay}->{userpayment} = 1 if $object eq 'myacc';
    $main->{pay}->{InvId} = $InvId;
    $action = getval($main, "action-$InvId");
    $action = $action || getval($main, 'action');
    $main->{pay}->{action} = $action || 'showall';
    $main->{pay}->{action} = 'search' if getval($main, 'search');
    $main->{pay}->{f_year} = getval($main, 'f_year');
    $main->{pay}->{f_month} = getval($main, 'f_month');
    $main->{pay}->{f_day} = getval($main, 'f_day');
    $main->{pay}->{t_year} = getval($main, 't_year');
    $main->{pay}->{t_month} = getval($main, 't_month');
    $main->{pay}->{t_day} = getval($main, 't_day');
    $main->{pay}->{dopayment} = getval($main, 'dopayment');
    $main->{pay}->{dopaccpayment} = getval($main, 'dopaccpayment');
    $main->{pay}->{addmoneytopacc} = getval($main, 'addmoneytopacc');
    $main->{pay}->{paccsumm} = getval($main, 'paccsumm');
    $main->{pay}->{submitaction} = getval($main, "submitaction-$InvId");
    $main->{pay}->{delpayment} = getval($main, "delpayment-$InvId");
    $main->{pay}->{object} = $object;
    $action = $main->{pay}->{action};
    $action = 'dopayment' if $main->{pay}->{dopayment};
    $action = 'addmoneytoacc' if $main->{pay}->{addmoneytoacc};
    $action = 'delpayment' if $main->{pay}->{delpayment};

    $main->{eventhash} = {
        search => 'r',
        showall => 'r',
        dopayment => 'w',
        dopaccpayment => 'w',
        addmoneytopacc => 'w',
        delpayment => 'del',
        details => 'r',
        paccdetails => 'r'
    };
    $main = AuthUserActionHash($main, $object, 'ObjectClass', $action);
    $main = checkcurdate($main);

    if($main->{pay}->{action} eq 'delpayment' or $main->{pay}->{delpayment})
    {
        checkInvId($main);
        delpayment($main);
    }
    if($main->{pay}->{addmoneytopacc})
    {
        checkInvId($main);
        $main->{pay}->{summa} = $main->{pay}->{paccsumm};
        $main->{profile} = $main->{pay};
        $main->{profile}->{paccflag} = 1;
        $main->{profile}->{description} = 'New payment for userid ' . $main->{pay}->{userid};
        genpayment($main);
        showpayments($main);
        return $main;
    }

    if($main->{pay}->{action} eq 'dopayment' or $main->{pay}->{dopayment})
    {
        checkInvId($main);
        $main->{pay}->{regstr} = "and payments.InvId=$InvId" if $InvId ;
        showpayments($main);
        $main = tryuseraccount($main);
        dopayment($main) if $main->{status_flag} eq 'fail';
        return $main;
    }

    if($main->{pay}->{action} eq 'dopaccpayment' or $main->{pay}->{dopaccpayment})
    {
        checkInvId($main);
        $main->{pay}->{regstr} = "and payments.InvId=$InvId" if $InvId ;
        showpayments($main);
        $main->{rpay} = $main->{rpaccpay};
        dopayment($main);
        return $main;
    }

    if($main->{pay}->{action} eq 'details'
        || $main->{pay}->{action} eq 'paccdetails')
    {
        checkInvId($main);
        $main->{pay}->{regstr} = "and payments.InvId=$InvId" if $InvId ;
        showpayments($main);
        return $main;
    }

    showpayments($main);
    return $main;
}

sub checkInvId
{
    my $main = shift;
    return if $main->{pay}->{object} eq 'pacc';
    logdb($main, "[E] IP:$main->{remote_ip} prog:$main->{program} f:checkInvId No userid found") unless $main->{pay}->{userid};
    goError('denied') unless $main->{pay}->{userid};
    my $p = $main->{dbcon}->getsimplequeryhash("select pid as InvId from PersonalAccounts where userid='$main->{pay}->{userid}'");
    logdb($main, "[E] IP:$main->{remote_ip} prog:$main->{program} f:checkInvId No InvId found") unless $p->{InvId};
    goError('denied') unless $p->{InvId};
    return;
}

sub delpayment
{
    my $main = shift;
    my $ureg = "and userid='$main->{pay}->{userid}'" if $main->{pay}->{userid} > 0;
    my $s = $main->{dbcon}->insertsimplequery($main->{dbhlr}, "
                        delete from payments
                        where
                        payments.InvId=$main->{pay}->{InvId}
                        $ureg and pflag=1") if $main->{pay}->{InvId};
    return;
}

sub showdetails
{
    my $main = shift;
    my $InvId = $main->{pay}->{InvId};
}

sub showpayments
{
    my $main = shift;
    my $InvId = $main->{pay}->{InvId};
    my $regstr = $main->{pay}->{regstr};
    my $ureg = "and payments.userid='$main->{pay}->{userid}'" if $main->{pay}->{userid} > 0;
    $main->{pay}->{action} = 'empty' unless ( $main->{pay}->{action} eq 'details'
                        || $main->{pay}->{action} eq 'paccdetails');
    $main->{rcurr} = $main->{dbcon}->getsimplequery("select * from currency;");
    $main->{pacc} = $main->{dbcon}->getsimplequeryhash("select
            *, (select name from currency where CurrId=p.CurrId) as currname
        from
            PersonalAccounts as p
            where userid='$main->{pay}->{userid}';");

    $main->{rpay} = $main->{dbcon}->getsimplequery("select payments.InvId,
                                        stype.description,
                                        ostype.description,
                                        u.login,
                                        t.description,
                                        g.description,
                                        p.description,
                                        l.description,
                                        payments.description as pdescription,
                                        payments.numslots,
                                        payments.summ,
                                        payments.ctime,
                                        payments.ptime,
                                        payments.pflag,
                                        payments.sid,
                                        curr.name as currname,
                                        t.tarifid,
                                        g.gameid,
                                        l.locationid,
                                        p.periodid,
                                        stype.stypeid,
                                        ostype.ostypeid
                                FROM
                                    tarif as t,
                                    period as p,
                                    location as l,
                                    game as g,
                                    payments as payments,
                                    ostype as ostype,
                                    srvtype as stype,
                                    user as u,
                                    currency as curr
                                where
                                    curr.CurrId=payments.CurrId
                                    and stype.stypeid=payments.stypeid
                                    and ostype.ostypeid=payments.ostypeid
                                    and payments.userid=u.userid
                                    and t.tarifid=payments.tarifid
                                    and g.gameid=payments.gameid
                                    and l.locationid=payments.locationid
                                    and p.periodid=payments.periodid
                                    and payments.pflag=1
                                    $ureg
                                    $regstr
                                    ");

    $main->{rpaccpay} = $main->{dbcon}->getsimplequery("select
                    payments.InvId, u.userid, u.userid,
                                        u.login, u.userid, u.userid, u.userid, u.userid,
                                        payments.description as pdescription, u.userid,
                                        payments.summ,
                                        payments.ctime,
                                        payments.ptime,
                                        payments.pflag, u.userid,
                                        curr.name as currname, u.userid, u.userid,
                                        u.userid, u.userid,u.userid, u.userid
                                FROM
                                    payments as payments,
                                    user as u,
                                    currency as curr
                                where
                                    curr.CurrId=payments.CurrId
                                    and payments.userid=u.userid
                                    and payments.paccflag=1
                                    $ureg
                                    and payments.pflag=1
                                    $regstr
                                    ");

    return $main if $main->{pay}->{action} eq 'details';
    return $main if $main->{pay}->{action} eq 'paccdetails';

    $ureg = undef;
    $ureg = "and p.userid='$main->{pay}->{userid}'" if $main->{pay}->{userid} > 0;

    $main->{rpaylog} =  $main->{dbcon}->getsimplequery("select
            p.time, p.event,p.summ,p.dkflag, u.login, curr.name as curname
            from paylog as p, currency as curr, user as u
            where
            curr.CurrId=p.CurrId $ureg
            and u.userid=p.userid
            and  ( cast(p.time as date) between '$main->{pdates}->{from}' and '$main->{pdates}->{to}' )
            order by p.time desc; ");
    $main->{log_visible} = 0;
    $main->{log_visible} = 1 if $main->{rpaylog} >0;
    $main->{paid} = 0;
    $main->{paid} = 1 unless ( $main->{rpaccpay} > 0 or $main->{rpay} > 0);
    $main->{paidmsg} = errline(0, "Неоплаченных счетов: 0") if $main->{paid};
    $main->{paidmsg} = errline(0, "Неоплаченные счета") unless $main->{paid};
    $main->{phistorymsg} = errline(0, "История платежей (прибытие, выбытие денежных средств)");
    return $main;
}

sub dopayment
{
    my $main = shift;
    $main->{pay}->{action} = 'dopayment';
    $main->{errline} =  "Заказ обрабатывается";
    $main->{linecolor} =  "green";

    foreach my $s (keys %{$main->{rpay}})
    {
        next if not $main->{rpay}->{$s};
        my $m = $main->{rpay}->{$s};
        $main->{res}->{OutSum} = $m->[10];
        $main->{res}->{login} = $m->[3];
        $main->{res}->{InvId} = $m->[0];
        $main->{res}->{Desc} = $m->[8];
        $main->{res}->{IncCurrLabel} = getval($main, 'currency') || 'WME';
        $main->{res}->{Culture} = 'ru';
        my $str = "$main->{res}->{MrchLogin}:$main->{res}->{OutSum}:$main->{res}->{InvId}:$main->{res}->{MrchPass1}";
        my $ctx = Digest::MD5->new;
        $ctx->add($str);
        $main->{res}->{SignatureValue} = $ctx->hexdigest;
        $main = genrequest($main);

        my $rcurr = $main->{dbcon}->getsimplequeryhash("select CurrId from currency where name='$main->{res}->{IncCurrLabel}';");
        my $s = $main->{dbcon}->insertsimplequery($main->{dbhlr}, "
                        update payments set
                        CurrId='$rcurr->{CurrId}'
                        where InvId=$main->{res}->{InvId}
                    ");
        last;
    }


    if ( $main->{res}->{error} )
    {
        $main->{linecolor} =  "red";
        $main->{errline} = "Error from $main->{res}->{URL}: $main->{res}->{status}";
        $main->{pay}->{regstr} = '' ;
        showpayments($main);
    }
    else
    {
        my $url =  "$main->{res}->{URL}?MrchLogin=$main->{res}->{MrchLogin}";
        $url .= "&Desc=$main->{res}->{Desc}";
        $url .= "Culture=$main->{res}->{Culture}";
        $url .= "&IncCurrLabel=$main->{res}->{IncCurrLabel}";
        $url .= "&InvId=$main->{res}->{InvId}";
        $url .= "&OutSum=$main->{res}->{OutSum}";
        $url .= "&SignatureValue=$main->{res}->{SignatureValue}";
        print "Location: $url\n\n";
    }
    return $main;
}

sub tryuseraccount
{
    my $main = shift;
    $main->{pay}->{action} = 'dopayment';
    $main->{errline} =  "Заказ оплачен";
    $main->{linecolor} =  "green";


    foreach my $s (keys %{$main->{rpay}})
    {
        next if not $main->{rpay}->{$s};
        my $m = $main->{rpay}->{$s};
        $main->{res}->{InvId} = $m->[0];
        $main->{res}->{srvtype} = $m->[1];
        $main->{res}->{ostype} = $m->[2];
        $main->{res}->{login} = $m->[3];
        $main->{res}->{period} = $m->[6];
        $main->{res}->{location} = $m->[7];
        $main->{res}->{slots} = $m->[9];
        $main->{res}->{summa} = $m->[10];
        $main->{res}->{tarif} = $m->[16];
        $main->{res}->{game} = $m->[17];
        $main->{res}->{OutSum} = $m->[10];
        $main->{res}->{Desc} = $m->[8];
        $main->{res}->{IncCurrLabel} = getval($main, 'currency') || 'WME';
        $main->{res}->{Culture} = 'ru';
        $main->{res}->{userid} = useridbyuser($main,$main->{res}->{login});
        $main->{profile} = $main->{res};
        $main->{profile}->{location} = $m->[18];
        $main->{profile}->{period} = $m->[19];
        $main->{profile}->{srvtype} = $m->[20];
        $main->{profile}->{ostype} = $m->[21];
        $main->{profile}->{srvname} = "New server for user $main->{profile}->{login}";
        $main->{form} = $main->{profile};

        $main = try_user_account($main);
        last unless $main->{status_flag} eq 'ok';
        my $rcurr = $main->{dbcon}->getsimplequeryhash("select CurrId from currency where name='$main->{res}->{IncCurrLabel}';");
        my $s = $main->{dbcon}->insertsimplequery($main->{dbhlr}, "
                                                update payments
                                            set
                                                pflag=0,
                                                CurrId='$rcurr->{CurrId}',
                                                ptime = CURRENT_TIMESTAMP
                                            where
                                                InvId=$main->{res}->{InvId}
                                                and summ='$main->{res}->{OutSum}'
                                                and pflag=1") if $main->{res}->{InvId};

        my $p = $main->{dbcon}->getsimplequeryhash("select pflag from payments where InvId=$main->{res}->{InvId};");
        $main->{errline} .= " Error when update payments ... " if $p->{pflag};
        $main->{success} .= "Done... Updated payments" unless $p->{pflag};
        $main->{status_flag} = 'ok' unless $p->{pflag};
        last;
    }

    return $main;

}

sub genrequest
{
    my $main = shift;

    my $ua = LWP::UserAgent->new;
    $ua->timeout(3);
    my $url = $main->{res}->{URL};
    my $req = POST $url,
    [
        MrchLogin => $main->{res}->{MrchLogin},
        OutSum => $main->{res}->{OutSum},
        InvId => $main->{res}->{InvId},
        Desc => $main->{res}->{Desc},
        IncCurrLabel => $main->{res}->{IncCurrLabel},
        Culture => $main->{res}->{Culture},
        SignatureValue => $main->{res}->{SignatureValue}
    ];

    my $res = $ua->request($req);
    $main->{res}->{error} = 1 if($res->is_error);
    $main->{res}->{status} = $res->status_line;
    $main->{res}->{result} = $res->as_string;
    return $main;
}


1;
