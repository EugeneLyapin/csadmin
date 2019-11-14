#!/usr/bin/perl

use strict;
use FindBin qw($Bin);
use Tt::Genpage;
use Tt::Pgen;
use Tt::Config;
use Db::Dbgame;
use Cp::SrvInfo;
use File::Basename qw(basename);
use CGI::Cookie;
use Storable;
use Tt::CryptPass;
use Tt::Cookies;
use Template;

#my $id="AuthLogin";
my $id="AuthLogin_tPage";

my $sessiondir = '/tmp/session/';
my ($p,$config);

die("Sorry ... no data") if( not $config = Tt::Config->new('file'));
die("Sorry ... no data") if( not $p = Tt::Genpage->new('file'));

my $main = $config->getconfig('post',$id);
$main->{user} = 'everyone' if ($main->{user} eq '');
$main->{urlbase} = getbase();
$main->{debug} = 3;
$main = fetchcookies($main);
logout($main) if($main->{getform}->{action} eq 'logout');
$main = trylogin($main);
my $line .= "Content-Type: text/html \n";
$line .= $main->{set_header} if $main->{set_header};
$line .= "\n";
print $line;
my $dline = gentemplate($main, 'AuthLogin');
$line = $p->getpagevalue($main);
$line = $p->genpage($main,$line,$dline);
$line = gendbtemplate($main, undef, $line);
$line = formatline($line);
print $line;

sub getreferer
{
    my $main->{referer} = $ENV{'REQUEST_URI'};
    my $server_port = $ENV{'SERVER_PORT'};
    my $server_name = $ENV{'SERVER_NAME'};
    $main->{referer} = $main->{form}->{request_uri} if($main->{form}->{request_uri});
    return($main->{referer});
}

sub getbase
{
    my $main->{urlbase} = $ENV{'HTTP_HOST'};
    $main->{urlbase} =~ s/:[0-9]+$//g, $main->{urlbase};
    $main->{urlbase} =~ /.*\.(\w+)\.(\w+)$/;
    $main->{urlbase} = ".$1.$2";
    return($main->{urlbase});
}

sub checkvalues
{
    my $main = shift;

    if($main->{form}->{submitlogin})
    {
        if($main->{form}->{loginname} eq '')
        {
            $main->{errline} .= &errline(3, "[errheader] Enter user name [/errheader]",$main);
            $main->{status_flag} = 'fail';
            return $main;
        }
        if($main->{form}->{loginpass} eq '')
        {
            $main->{errline} .= &errline(3, "[errheader] Enter password [/errheader]", $main);
            $main->{status_flag} = 'fail';
            return $main;
        }

        my $arr = $main->{dbcon}->getsimplequeryhash("
                    select
                        userid
                    from
                        user
                    where
                        login = '$main->{form}->{loginname}'
                    ");

        if(not $arr or $arr <= 0)
        {
            $main->{errline} .= &errline(3,"[errheader] No such user $main->{form}->{loginname} \n Enter registered user name [/errheader]",$main);
            $main->{status_flag} = 'fail';
            return $main;
        }
    }

    return $main;

}

sub logout
{
    my $main = shift;
    my $session = $main->{rcookies}->{session};

    $session =~ s/;.*//g, $session;
    $session =~ s/session=//g, $session;
    delete_old_session($main,$session);
    print ("Location: /$main->{program}\n\n");
}

sub trylogin
{
    my $main = shift;
    my $cookies = $main->{rcookies};
    my $uservar = $main->{uservar};

    # Получаем Cookies пользователя
    my $line .= "\n";
    $main->{referer} = getreferer($main);
    if ($cookies->{'session'})
    {
        my $arr = &getsession($main,$cookies);

        if($arr and $arr > 0)
        {
            if(checkenv($arr,$uservar,$cookies))
            {
                # $main->{errline} .= &errline(0,"Пользователь $arr->{login} успешно вошел в систему!
                #                       В последний раз $arr->{time}");
                # $main->{errline} .= &errline(0,"  <br>session = $cookies->{session}<br> "  );
                # $main->{errline} .= &errline(0,"REFERER $main->{referer} ...");
                # $main->{errline} .= &errline(0,"Location: $main->{referer}\n\n");
                update_session($main,$cookies->{session});
                return $main;
            }
        }
    }

    $main = authlogin($main);
    return $main;

}

sub checkpass
{
    my $main = shift;
    my $query = "select
                    passwd,
                    salt,
                    login,
                    userid
                FROM
                    user
                WHERE
                    login='$main->{form}->{loginname}'
                ";
    my $arr = $main->{dbcon}->getsimplequeryhash($query);
    $main->{rpass} = $arr;
    my ($pass, $salt) = &cryptpass($main->{form}->{loginpass},$arr->{salt});

    if( $arr->{passwd} eq $pass )
    {
        $main->{referer} = '/' if not ($main->{referer} !~ /(logout)|(login)|(Auth)/);
        $main->{errline} .= &errline(0,"Пользователь $arr->{login} успешно авторизован в системе! Жми <a href=$main->{referer}>сюда</a>");
        $main->{status_flag} = 'ok';
    }
    else
    {
        $main->{errline} .= &errline(1,"Неправильный пароль для пользователя $arr->{login} ... ");
        $main->{status_flag} = 'fail';
    }
    return($main);

}

sub authlogin
{
    my $main = shift;
    my $uservar = $main->{uservar};
    my $cookies = $main->{rcookies};
    # Объявляем переменную новой сессии
    my $line = "\n";
    $main = checkvalues($main);
    return $main if $main->{status_flag} eq 'fail';
    $main = checkpass($main);
    return $main unless $main->{status_flag} eq 'ok';
    delete_old_session($main,$cookies->{session});
    $main = create_session($main);
    return $main;
}

sub create_session
{
    my $main = shift;
    my $uservar = $main->{uservar};
    my $arr = $main->{rpass};
    # Объявляем переменную новой сессии
    my $session;
    my $line;

    # Процедура создания сессии
    # Массив символов для ключа
    my @rnd_txt = ('0','1','2','3','4','5','6','7','8','9',
                 'A','a','B','b','C','c','D','d','E','e',
                 'F','f','G','g','H','h','I','i','J','j',
                 'K','k','L','l','M','m','N','n','O','o',
                 'P','p','R','r','S','s','T','t','U','u',
                 'V','v','W','w','X','x','Y','y','Z','z');
    srand;
    # Генерим ключ
    for (0..31) {
        my $s = rand(@rnd_txt);
        $session .= $rnd_txt[$s]
    }

    # Добавляем запись в таблицу сессий

    my $query = "INSERT INTO
                    session
                 SET session = '$session',
                     userid = $arr->{userid},
                     time = CURRENT_TIMESTAMP,
                     host ='$uservar->{remote_host}',
                     ip = '$uservar->{remote_addr}',
                     forwarded = '$uservar->{forwarded}'";

    $main->{dbcon}->insertsimplequery($main->{dbhlr}, "
        delete from
            session
        where
            userid = '$arr->{userid}' and
            host ='$uservar->{remote_host}' and
            ip = '$uservar->{remote_addr}' and
            forwarded = '$uservar->{forwarded}';
        ");
    $main->{dbcon}->insertsimplequery($main->{dbhlr}, $query);
    $main->{set_header} = "Set-Cookie: session=$session; expires=Friday, 25-Dec-2020 23:59:59 GMT; path=/; domain=$main->{urlbase};\n\n";
    return $main;
}

sub update_session
{
    my $main = shift;
    my $session = shift;
    my $query = "UPDATE
                    session
                SET
                    time = CURRENT_TIMESTAMP
                WHERE
                    session = '$session' ";
    $main->{dbcon}->insertsimplequery($main->{dbhlr}, $query);
    return 1;
}

sub delete_old_session
{
    my $main = shift;
    my $session = shift;


    if($session)
    {
        my $query = "delete from
                        session
                    WHERE
                        session = '$session' ";
        $main->{dbcon}->insertsimplequery($main->{dbhlr}, $query);
        return 1;
    }

    return 0;
}

sub describesession
{
    my $arr = shift;
    my $uservar = shift;
    my $cookies = shift;
    my $main->{errline};
    my $main->{referer} = getreferer($main);

    $main->{errline} .= "<center><table><tr><td>";
    $main->{errline} .= &errline(0,"Пользователь $arr->{login} успешно вошел в систему ...");
    $main->{errline} .= &errline(0,"request_uri $main->{referer}...");
    $main->{errline} .= &errline(0,"$arr->{ip} --> $uservar->{remote_addr};
            $arr->{host} --> $uservar->{remote_host};
            $arr->{session} --> $cookies->{session};
            $arr->{forwarded} --> $uservar->{forwarded}");
    $main->{errline} .= "Set-Cookie: session=$cookies->{session}; expires=Friday, 25-Dec-2020 23:59:59 GMT; path=/; domain=$main->{urlbase};\n\n";
    $main->{errline} .= "</td></tr></table></center>";

    return($main->{errline});
}

