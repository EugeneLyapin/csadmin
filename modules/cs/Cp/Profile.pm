package Cp::Profile;

use strict;
use Exporter;
use FindBin qw($Bin);
use base qw( Exporter );
use CGI qw/:standard/;
use Tt::Pgen;
use Tt::CryptPass;

our @EXPORT = qw(
            checkform
            changeuserinfo
            changemapid
            changeaction
            edituserprofile
        );

sub getstrlen
{
    my $val = shift;
    my $strlen = length($val)*10;
    $strlen = 100 if(length($val)<=1);
    $strlen .= 'px';
    return($strlen);
}

sub checkform
{
    my $main = shift;
    my $errline;
    my $form = $main->{form};
    return if($main->{form}->{submit} eq '' );

    $errline .= &errline(1,"Пароли не совпадают ...") if(!($form->{pass1} eq $form->{pass2}));
    $errline .= &errline(1,"Длина пароли должна быть не менее 8 символов ... ") if(length($form->{pass1})>=1 and length($form->{pass1})<=8);
    $errline .= &errline(1,"Введите правильный email ... ") if($form->{email}!~/^[A-z0-9\.]+\@[A-z0-9\.]+$/);
    $errline .= &errline(1,"Введите правильный icq ... ") if($form->{icq}!~/^[0-9\-\s]+$/);
    $errline .= &errline(1,"Введите правильный мобильный телефон ... ") if($form->{cellphone}!~/^[0-9\+\s\(\)\-]+$/);
    $errline .= &errline(1,"Введите правильный домашний телефон ... ") if($form->{homephone}!~/^[0-9\+\s\(\)\-]+$/);
    $errline .= &errline(1,"Введите правильную дату рождения ... ") if($form->{birthdate}!~/^[0-9\-\/\.]+$/);
    $errline .= &errline(1,"Введите правильное имя ... ") if($form->{name}=~/[0-9]/);
    $errline .= &errline(1,"Введите правильную фамилию ... ") if($form->{sname}=~/[0-9]/);
    $errline .= &errline(1,"Введите правильное отчество ... ") if($form->{fname}=~/[0-9]/);
    $errline .= &errline(1,"Введите правильную страну ... ") if($form->{country}=~/[0-9]/);
    $errline .= &errline(1,"Введите правильный город ... ") if($form->{city}=~/[0-9]/);
    return($errline);
}

sub changeuserinfo
{
    my $main = shift;
    my $form = $main->{form};
    return if(not defined($form->{userid}));
    return if(not defined($form->{submit}));

    my ($pwd,$salt) = cryptpass($form->{pass1}) if defined($form->{pass1});
    my $s = $main->{dbcon}->insertsimplequery($main->{dbhlr}, "update user set
        name='$form->{name}',
        sname='$form->{sname}',
        fname='$form->{fname}',
        addon='$form->{addon}',
        icq='$form->{icq}',
        vkontakte='$form->{vkontakte}',
        skype='$form->{skype}',
        cellphone='$form->{cellphone}',
        homephone='$form->{homephone}',
        country='$form->{country}',
        city='$form->{city}',
        clan='$form->{clan}',
        site='$form->{site}',
        email='$form->{email}',
        address='$form->{address}',
        birthdate='$form->{birthdate}'
        where userid=$form->{userid} and locked=0");

    my $s = $main->{dbcon}->insertsimplequery($main->{dbhlr}, "update user set
        passwd='$pwd',
        salt='$salt'
        where userid=$form->{userid} and locked=0") if defined($form->{pass1});

    return($s);

}


sub edituserprofile
{
    my $main = shift;
    my $url = shift;

    my ($line,$userinfo,$strlen,$userid);
    $userid = &getval($main,'userid');
    $main->{errline} = &checkform($main) if($main->{form}->{userid});
    changeuserinfo($main) unless $main->{errline};
    my $muser = $main->{dbcon}->getsimplequery("select userid,login,passwd,name,fname,sname,addon,clan,site,birthdate,
                                                    email,icq,skype,vkontakte,country,city,address,homephone,cellphone
                                                from
                                                    user as u
                                                where
                                                    u.userid='$userid'");

    foreach my $s (sort keys %{$muser})
    {
        next unless $s;
        $userinfo->{userid}->{value} = $muser->{$s}->[0];
        $userinfo->{login}->{value} = $muser->{$s}->[1];
        $userinfo->{passwd}->{value} = getval($main, 'pass1') || $muser->{$s}->[2];
        $userinfo->{name}->{value} = getval($main, 'name') || $muser->{$s}->[3];
        $userinfo->{fname}->{value} = getval($main, 'fname') || $muser->{$s}->[4];
        $userinfo->{sname}->{value} = getval($main, 'sname') || $muser->{$s}->[5];
        $userinfo->{addon}->{value} = getval($main, 'addon') || $muser->{$s}->[6];
        $userinfo->{clan}->{value} = getval($main, 'clan') || $muser->{$s}->[7];
        $userinfo->{site}->{value} = getval($main, 'site') || $muser->{$s}->[8];
        $userinfo->{birthdate}->{value} = getval($main, 'birthdate') || $muser->{$s}->[9];
        $userinfo->{email}->{value} = getval($main, 'email') || $muser->{$s}->[10];
        $userinfo->{icq}->{value} = getval($main, 'icq') || $muser->{$s}->[11];
        $userinfo->{skype}->{value} = getval($main, 'skype') || $muser->{$s}->[12];
        $userinfo->{vkontakte}->{value} = getval($main, 'vkontakte') || $muser->{$s}->[13];
        $userinfo->{country}->{value} = getval($main, 'country') || $muser->{$s}->[14];
        $userinfo->{city}->{value} = getval($main, 'city') || $muser->{$s}->[15];
        $userinfo->{address}->{value} = getval($main, 'address') || $muser->{$s}->[16];
        $userinfo->{homephone}->{value} = getval($main, 'homephone') || $muser->{$s}->[17];
        $userinfo->{cellphone}->{value} = getval($main, 'cellphone') || $muser->{$s}->[18];
    }

    foreach my $s (keys %{$userinfo})
    {
        $userinfo->{$s}->{strlen} = &getstrlen($userinfo->{$s}->{value});
    }

    $main->{userinfo} = $userinfo;
    $main->{action} = 'editprofile';
    return $main ;

}

1;

