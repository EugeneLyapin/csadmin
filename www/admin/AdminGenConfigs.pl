#!/usr/bin/perl

use strict;
use FindBin qw($Bin);
use Tt::Genpage;
use Tt::Pgen;
use Cp::SrvCfg;
use Tt::Config;
use Db::Dbgame;
use File::Basename qw(basename);
use Tt::Cookies;
use Tt::Auth;

my $debug=1;
my $id="AdminGenconfig";
my ($user, $p,$config,$main, $sc, $col, $cvol);

my $url = basename($0);


die("Sorry ... no data") if( not $config = Tt::Config->new('file'));
die("Sorry ... no data") if( not $p = Tt::Genpage->new('file'));

my $main = $config->getconfig('post',$id);
my $ud = checkcookies($main); $main->{user} = $ud->{login} || 'everyone';
my $s = CheckValidUser($main,$main->{user},$id);
my $user = $main->{user};


my $line = $p->header();
print $line;
undef $line;

my $dline = &genarea($main);

$line = $p->getpagevalue($main);
$line = $p->genpage($main,$line,'<content>');
$line = $p->gencontent($line,'<content>',$dline);
print $line;

sub genarea
{
    my $main = shift;
    my $line;

    my $pcid = &getval($main,'cid');
    my $action = &getval($main,'action');

    $pcid = '' if($action eq "New");



    if($action eq "Delete")
    {
        my $dstatus = $main->{dbcon}->getsimplequery("delete
                        from
                            srvconfigs
                        where
                            cid='$pcid'");

    }

    if($action eq 'Save')
    {
        $main->{errline} = checkformdata($main->{form});
        changeconfiginfo($main->{form},$pcid) if not ($main->{errline}) ;
        addconfig($main->{form},$pcid) if not ($main->{errline}) ;
        $line .= configform($main,$pcid) if($pcid or $main->{errline});
        $line .= getcfg($main) if not($pcid or $main->{errline});
        return $line;
    }
    if($action eq 'New')
    {
        $line .= configform($main,$pcid);
        return $line;
    }
    if($action eq 'Find')
    {
        $line .= configform($main,$pcid) if($pcid);
        return $line;
    }

    $line .= getcfg($main);
    return $line;
}

sub configform
{
    my $main = shift;
    my $pcid = shift;
    my $line;

    my $cid = $main->{dbcon}->getsimplequery("
                select
                    cid,
                    name
                from
                    srvconfigs;
                ");
    my $catid = $main->{dbcon}->getsimplequery("
                    select
                        cid,
                        name
                    from
                        configcategory;
                    ");

    my $rconfig = $main->{dbcon}->getsimplequeryhash("
                    select
                        cid,
                        name,
                        category,
                        description,
                        value,
                        ctable
                    from
                        srvconfigs
                    where
                        cid='$pcid'
                    LIMIT 1
                    ");

    my $configinfo = $rconfig;

    my $sbutton = &getsavebutton('action');
    $line .= sprintf <<A;
            <form action=$url method="POST">
            <p>
            $main->{errline}
A

    my $fline .= sprintf <<A;
                <table width=400>
                <tr><td>
                <fieldset>
                <legend>Выбрать конфиг</legend>
                <table><tr><td>
                Имя &nbsp;

A
    $fline .= $p->geninbox('', 'cid', $cid, $pcid,0,200);

    $fline .= sprintf <<A;
            </td>
                <td valign=center><input name=action value='Find' style='border:0px' type=image border=0 src=/img/admin/old-edit-find.png></td>
                <td valign=center><input name=action value='New' style='border:0px' type=image border=0 src=/img/admin/document-new.png></td>
                <td valign=center><input name=action value='Delete' style='border:0px' type=image border=0 src=/img/admin/dialog-close.png></td>
                <td valign=center><input name=action value='Save' style='border:0px' type=image border=0 src=/img/admin/stock_save.png></td>
                </tr>

            </table>
            </fieldset>
            </td></tr>
            </table>
A

    $line .= $fline if($pcid);
    $line .= sprintf <<A;
            <table width=400>

            <tr><td>
            <fieldset><legend>Параметры файла $configinfo->{name}:</legend>
            <table valign=top><tr valign=top><td border=0 width=80 valign=top>
            <tr><td>Название:</td><td><input type="text" style='width:200px' name="name" value="$configinfo->{name}"></td></tr>
                <tr><td>Имя таблицы:</td><td><input type="text" name="ctable" style='width:200px' value="$configinfo->{ctable}"></td></tr>
                <tr><td>Описание:</td><td><input type="text" name="description" style='width:300px' value="$configinfo->{description}"></td></tr>
                <tr><td>Категория</td>
            <td>
A

    $line .= $p->geninbox('', 'category', $catid, $configinfo->{category},0,200);
    $line .= sprintf <<A;
            </td>
            </tr>
            </table>
            </fieldset>
            </td></tr>
            </table>

        <table width=600>
        <tr><td>
        <textarea name=value rows=20 cols=12 style='width:600px'>$configinfo->{value}</textarea>
        </td></tr>
                <tr><td>
                <p align=center>
                $sbutton
                </p>
                </td></tr>
        </table>

        </form>
A
    return $line;


}

sub checkformdata
{
    my $form = shift;
    my $errline;

    if(not defined($form->{name}))
    {
        $errline .=  errline(1,"Name is not defined ... ");
    }

    if($form->{name}!~/^[A-z0-9\.]+$/)
    {
        $errline .= errline(1,"Incorrect name. Example: server.cfg ... ");
    }

    if($form->{name}!~/^[A-z0-9]+$/)
    {
        $errline .= errline(1,"Incorrect table. Example: servercfg ... ");
    }

    $errline .= errline(1,"Category is not defined ...") if(not defined($form->{category}));
    return $errline;

}

####################################################
sub changeconfiginfo
{
    my $form = shift;
    my $pcid = shift;

    return if not($pcid);
    my $s = $main->{dbcon}->insert1linequery($main->{dbhlr}, "
                update
                    srvconfigs
                set
                    name='$form->{name}',
                    category='$form->{category}',
                    description='$form->{description}',
                    ctable='$form->{ctable}',
                    value= ?
                where
                    cid=$form->{cid}", $form->{value});

    return($s);
}

sub addconfig
{
    my $form = shift;
    my $pcid = shift;

    return if($pcid);

    my $s = $main->{dbcon}->insert1linequery($main->{dbhlr}, "
            insert into
                srvconfigs
                (name,category,description,ctable,value)
            values(
                '$form->{name}',
                '$form->{category}',
                '$form->{description}',
                '$form->{ctable}',
                ?);",$form->{value});

    return($s);

}

sub getcfg
{
    my $main = shift;

    my $rcfg = $main->{dbcon}->getsimplequery("
                    select
                        s.cid as cid,
                        s.name as name,
                        c.name as category,
                        s.description as description,
                        s.ctable as ctable
                    from
                        srvconfigs as s, configcategory as c
                    where
                        c.cid = s.category;
                    ");

    my ($line,$mrcfg);

    $line .= sprintf <<A;
    <br>
    $main->{errline}
        <table class=wrapper>
        <tr>
        <th>ID</th>
        <th>Имя</th>
        <th>Описание</th>
        <th>Категория</th>
        <th>Таблица</th>
        <th>Действие</th>
        </tr>

A
    for my  $ss (sort keys %{$rcfg})
    {
        if($ss)
        {
            $mrcfg->{cid} = $rcfg->{$ss}->[0];
            $mrcfg->{name} = $rcfg->{$ss}->[1];
            $mrcfg->{category} = $rcfg->{$ss}->[2];
            $mrcfg->{ctable} = $rcfg->{$ss}->[4];
            $mrcfg->{description} = substr($rcfg->{$ss}->[3],0,50);
            $mrcfg->{description} = join(' ',$mrcfg->{description}, '...') if(length($mrcfg->{description}) == 50);

            $line .= sprintf <<A;
            <tr>
            <td><a href=$url?cid=$mrcfg->{cid}&action=Find >$mrcfg->{cid}</a></td>
            <td><a href=$url?cid=$mrcfg->{cid}&action=Find >$mrcfg->{name}</a></td>
            <td width=300>$mrcfg->{description}</td>
            <td align=center>$mrcfg->{category}</td>
            <td>$mrcfg->{ctable}</td>
            <td align=center><a href=$url?cid=$mrcfg->{cid}&action=Delete><img src=/img/i-delete.gif></td>
            </td>
            </tr>
A
        }
    }

    $line .= sprintf <<A;
        </TABLE>
       <br>
        <a href=$url?action=New><img style="background-color:transparent; border: 0px;" border=0 src=/img/admin/document-new.png></a>
A

    return $line;
}

