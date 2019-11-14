package Tt::Cookies;

use strict;
use Exporter;
use FindBin qw($Bin);
use base qw( Exporter );
use Db::Dbgame;
use CGI::Cookie;
our @EXPORT = qw( getsession
            fetchcookies
            checkenv
            checkcookies );


sub fetchcookies
{
    my $main = shift;
    my %cookies = fetch CGI::Cookie;
    my $uservar;
    # Определяем IP адрес пользователя (первые две цифры)
    $uservar->{'remote_addr'} = $ENV{'REMOTE_ADDR'} || 'empty';
    $uservar->{'remote_addr'} = 'empty' unless $uservar->{'remote_addr'};
    $uservar->{'remote_host'} = $ENV{'REMOTE_HOST'} || 'empty';
    $uservar->{'remote_host'} = quotemeta $uservar->{'remote_host'};
    $uservar->{'forwarded'} = $ENV{'HTTP_X_FORWARDED_FOR'} || 'empty';
    $uservar->{'forwarded'} = quotemeta $uservar->{'forwarded'};
    my $rc = \%cookies;
    $main->{rcookies} = $rc;
    $main->{uservar} = $uservar;
    return $main;
}



sub getsession
{
    my $main = shift;
    my $cookies = shift;
    my $loginexpr;

    $loginexpr = "and u.login = '$main->{form}->{loginname}'" if($main->{form}->{submitlogin});

    # Выбираем значение параметра session
    $cookies->{'session'} = $cookies->{'session'}->value;
    $cookies->{'session'} =~s /[\W]//g;
    $cookies->{'session'} = 'empty' unless $cookies->{'session'};

    my $period = 86400;
    # Проверяем наличие сессии
    my $query = "select u.login, u.weight, u.userid,
                    s.host, s.ip, s.forwarded, s.session,
                    s.time
                FROM
                    session as s,
                    user as u
                WHERE
                    s.session = '$cookies->{session}'
                    and s.userid=u.userid
                    $loginexpr
                    and UNIX_TIMESTAMP(CURRENT_TIMESTAMP)-UNIX_TIMESTAMP(time)<=$period

                    LIMIT 1";
        my $arr = $main->{dbcon}->getsimplequeryhash($query);
        unless ($arr->{login})
        {
            my $g = $main->{dbcon}->getsimplequeryhash("select weight from groups where group='everyone';");
            $arr = {
                login => 'everyone',
                weight => $g->{weight},
            };
        }
        $main->{user} = $arr->{login};
        return($arr);
}

sub checkenv
{
    my $arr = shift;
    my $uservar = shift;
    my $cookies = shift;
    my $status;

    $arr->{host} = quotemeta $arr->{host};
    $arr->{forwarded} = quotemeta $arr->{forwarded};
    if( $arr->{host} eq $uservar->{remote_host} and
    $arr->{ip} eq $uservar->{remote_addr} and
    $arr->{session} eq $cookies->{session} and
    $arr->{forwarded} eq $uservar->{forwarded}   )
    {
        $status = 1;
    }
    return($status);
}

sub checkcookies
{
    my $main = shift;
    my $arr;

    $arr = $main->{dbcon}->getsimplequeryhash("select ckey,cvalue from config where ckey = 'authlocation'");
    my $authlocation = $arr->{cvalue};

    $authlocation = '/' if not defined($authlocation);

    $main = fetchcookies($main);
    my $cookies = $main->{rcookies};
    my $uservar = $main->{uservar};

    if ($cookies->{'session'})
    {

        my $arr = &getsession($main,$cookies);
        if($arr and $arr > 0)
        {
            return $arr if(checkenv($arr,$uservar,$cookies));
            return $arr if($arr->{login} eq 'everyone');
        }
        else
        {
            return $arr;
        }

    }
    print "Location: $authlocation\n\n";
    return;

}

1;
