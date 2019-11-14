package Cp::AddUser;

use strict;
use Exporter;
use FindBin qw($Bin);
use base qw( Exporter );
use CGI qw/:standard/;
use Tt::Pgen;
use Cp::SrvCfg;
use Cp::CreateProfile;
use Tt::CryptPass;

our @EXPORT = qw(
        pageform
        checkdata
        adduser
        );


sub pageform
{
    my ($main,$users,$groups,$url,$fstatus, $dstatus, $p) = @_;
    my $line;
    my $g;

    if($dstatus eq 'success')
    {
        $line = &pageformdone($main);
        return $line;
    }

    my $lline = errline(1,"Пользователь существует!") if($fstatus eq 0 );

    $line = sprintf <<A;
    <br>
        <center>
        $lline
        $main->{errline}
        <div class="popup" id="mess"></div>
        <table>
        <form action=$url name=frmValidate method="POST" onsubmit="return checkField()">
            <input type="hidden" name="action" value="adduser">
            <input type="hidden" name="srvname" value="Counter strike 1.6 server">
            <td>login</td><td><input type="text"
            name="login"
            onchange="this.value=this.value.replace(/([^0-9a-zA-z])/g,''); chlogin(); checkdblogin()"
            onkeyup="var n=this.value.replace(/([^0-9A-z])/g,'');
            if(n!=this.value) this.value=n;"
            onmousedown="this.value=this.value.replace(/([^0-9a-zA-z])/g,'');"
            onmouseover="tooltip(this,'Длина логина не более 50 символов')" onmouseout="hide_info(this)"
            value=""></td></tr>
            <tr><td>Пароль:</td><td><input type="password" name="pass1" value="" onchange="chpass()"
            onmouseover="tooltip(this,'Длина пароля не менее 8 символов и не более 50 символов')" onmouseout="hide_info(this)"
            ></td></tr>
            <tr><td>Повторите пароль:</td><td><input type="password" name="pass2" value=""  onchange="chpass()"></td></tr>
            <tr><td>e-mail</td><td><input type="text" name="email" value=""></td></tr>

A
    $line .= &geninbox("Группа", 'gid', $groups, $g, 0, 100);
    my $sbutton = &getsavebutton('submit');

    $line .= sprintf <<AA;
    <tr><td>
    $sbutton
    </td></tr>
    </form>
    </table>
    </center>
AA

    return($line);

}


sub checkdata
{
    my $main = shift;
    my $line;
    my $opts=();
    my $status = 1;
    return if(!($main->{form}->{submit}));
    $opts->{login} = $main->{form}->{login};
    $opts->{email} = $main->{form}->{email};

    my %tmpl = (
        'login' => q/^[A-z][A-z0-9\.]+$/,
        'email' => q/^[A-z0-9\.]+\@[A-z0-9\.]+$/,
    );
    my $rtmpl = \%tmpl;

    $line .= &checkoptions (options => $opts, templates => $rtmpl);

    $line .= &errline(1,"Пароли не совпадают ...") if(!($main->{form}->{pass1} eq $main->{form}->{pass2}));
    $line .= &errline(1,"Длина пароли должна быть не менее 8 символов ... ") if(length($main->{form}->{pass1})>=1 and length($main->{form}->{pass1})<=8);
    $line .= &errline(1, "Выберите группу") if not ($main->{form}->{gid});

    $status = 0 if($line);
    return ($status,$line)
}



sub adduser
{
    my $main = shift;
    my $url = shift;
    my $users = $main->{dbcon}->getusernamestr($main->{form}->{login});

    $users .= '.';

    return(0) if($users =~ /\.$main->{form}->{login}\./);

    my ($pwd,$salt) = cryptpass($main->{form}->{pass1});
    $main->{dbcon}->insertuser($main->{form}->{login},$pwd, $salt, $main->{form}->{email}, $main->{form}->{gid});
    my $userid = $main->{dbcon}->getuserid($main->{form}->{login});

    print "Location: $url?proc=success\n\n";

    return(1);
}


1;



