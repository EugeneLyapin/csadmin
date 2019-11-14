package Tt::Auth;

use strict;
use Exporter;
use FindBin qw($Bin);
use base qw( Exporter );
use Db::Dbgame;
use Tt::Pgen;
use Tt::Error;
use XML::Simple;
use Data::Dumper;
use Cp::SrvInfo;
our @EXPORT = qw(
        CheckValidUser
        AuthUserAction
        AuthUserActionHash
        getaclhash
        checkgroupweight
        checkusergroupweight
        );


sub AuthUserAction
{
    my $main = shift;
    my $t = shift;
    my $val = shift;
    my $action = shift;
    my $prop = $main->{eventhash}->{$action} if $action;
    my $q;
    my $userid = useridbyuser($main, $main->{user}) unless $main->{user} eq 'everyone';
    $main->{status_flag} = 'fail';
    $main->{errline} .= "No such attr for event $action" unless $prop;
    logdb($main, "[E] IP:$main->{remote_ip} p:$main->{program} f:AuthUserAction - $main->{errline}") unless $prop;
    return $main unless $prop;
    return $main unless ( $t and $val );

    $q = $main->{dbcon}->getsimplequery("select table_name,field_pointer from ttf;");
    foreach my $s (keys %{$q})
    {
        my $tname = $q->{$s}->[0];
        my $fp = $q->{$s}->[1];
        $main->{ttf}->{$tname} = $fp;
    }

    my $fp = $main->{ttf}->{$t};
    $main->{errline} .= "Sorry, No field_pointer for table $t" unless $fp;
    logdb($main, "[E] IP:$main->{remote_ip} p:$main->{program} f:AuthUserAction - $main->{errline}") unless $fp;
    return $main unless $fp;
    $q = $main->{dbcon}->getsimplequeryhash("select ObjectClass from $t where $fp = '$val' ;");
    $main->{errline} .= "Sorry, No ObjectClass for field $fp => $val" unless $q->{ObjectClass};
    logdb($main, "[E] prog: $main->{program}; AuthUserAction: $main->{errline}") unless $q->{ObjectClass};
    return $main unless $q->{ObjectClass};
    my $oname = $q->{ObjectClass};
    $q = $main->{dbcon}->getsimplequery("select oid,name from GROG where enabled=1;");

    foreach my $s (keys %{$q})
    {
        my $oid = $q->{$s}->[0];
        my $name = $q->{$s}->[1];
        $main->{groghash}->{$name} = $oid;
    }
    return $main unless $main->{groghash}->{$oname};
    $main->{status_flag} = 'ok' if $main->{uhash}->{$oname}->{$prop};
    return $main if $main->{status_flag} eq 'ok';

    $main->{xml} = XML::Simple->new();
    $main = getaclhash($main, $userid);
    my $roles = $main->{aclh}->{role};
    $main->{errline} .= "Sorry, user $main->{user} has no group" unless ishash $roles;
    logdb($main, "[E] IP:$main->{remote_ip} p:$main->{program} f:AuthUserAction - $main->{errline}") unless ishash $roles;
    goError('disabled') unless ishash $roles;
    $main->{group_waight} = 0;
    foreach my $r (keys %{$roles})
    {
        $q = $main->{dbcon}->getsimplequeryhash("select acl,weight from groups where enabled=1 and gname='$r';");
        next unless $q->{acl};
        my $rhash = $q->{acl};
        $main->{group_weight} = $q->{weight} if $q->{weight} > $main->{group_weight};
        my $ghash = $main->{xml}->XMLin($rhash) if $rhash;
        $main->{status_flag} = 'ok' if $ghash->{$oname}->{$prop};
        $main = mergeuhash($main, $ghash);
        $main->{dump_hash} = Dumper($main->{uhash});
    }
    my $line .= "[W] IP:$main->{remote_ip} p:$main->{program} f:AuthUserAction - prop:$prop in obj:$oname for action:$action ... ";
    $line .= "val:$main->{uhash}->{$oname}->{$prop}, ";
    $line .= "status_flag $main->{status_flag}, user:$main->{user}";
    logdb($main, $line) unless $main->{status_flag} eq 'ok';
    goError('denied') if $main->{status_flag} eq 'fail';
    return $main;
}


sub AuthUserActionHash
{
    my $main = shift;
    my $t = shift;
    my $val = shift;
    my $action = shift;
    my $q;
    my $prop = $main->{eventhash}->{$action} if $action;
    $main->{status_flag} = 'fail';
    $main->{user} = $main->{user} || 'everyone';

    logdb($main, "[D] IP:$main->{remote_ip} p:$main->{program} f:AuthUserActionHash - table:$t, val:$val, action: $action, prop: $prop, user:$main->{user}");
    goError('denied') unless $prop;
    goError('denied') unless ( $t and $val );
    my $fp = $val eq 'ObjectClass' ? $t : $main->{ttf}->{$t};
    unless ($fp)
    {
        $main->{errline} .= "Sorry, No field_pointer for table $t";
        logdb($main, "[E] IP:$main->{remote_ip} p:$main->{program} f:AuthUserActionHash - $main->{errline}");
        goError('denied');
    }
    $q->{ObjectClass} = $t if $val eq 'ObjectClass';
    $q = $main->{dbcon}->getsimplequeryhash("select ObjectClass from $t where $fp = '$val' ;") unless $q->{ObjectClass};
    unless ($q->{ObjectClass})
    {
        $main->{errline} .= "Sorry, No ObjectClass for field $fp => $val";
        logdb($main, "[E] IP:$main->{remote_ip} p:$main->{program} f:AuthUserActionHash - $main->{errline}");
        goError('denied');
    }
    my $oname = $q->{ObjectClass};
    logdb($main, "[E] IP:$main->{remote_ip} p:$main->{program} f:AuthUserActionHash - No such obj:$oname in groghash") unless $main->{groghash}->{$oname};
    goError('denied') unless $main->{groghash}->{$oname};
    $main->{status_flag} = 'ok' if $main->{uhash}->{$oname}->{$prop};
    my $line .= "[W] IP:$main->{remote_ip} p:$main->{program} f:AuthUserActionHash - prop:$prop in obj:$oname for action:$action ... ";
    $line .= "val:$main->{uhash}->{$oname}->{$prop} ";
    $line .= "status_flag:$main->{status_flag}, user:$main->{user}";
    logdb($main, $line) if $main->{status_flag} eq 'fail';
    goError('denied') if $main->{status_flag} eq 'fail';
    return $main;
}

sub mergeuhash
{
    my $main = shift;
    my $ghash = shift;

    foreach my $s (keys %{$ghash})
    {
        foreach my $p (keys %{$ghash->{$s}})
        {
            $main->{uhash}->{$s}->{$p} = 1 if $ghash->{$s}->{$p};
        }
    }
    return $main;
}

sub CheckValidUser
{
    my $main = shift;
    my $user = shift;
    my $page = shift;
    my $group;
    my $status = 0;
    $main->{user} = $user || 'everyone';
    $main->{eventhash} = { showall => 'r' };
    $main = AuthUserAction( $main, 'page', $page, 'showall' );
    return;
}

sub getaclhash
{
    my $main = shift;
    my $userid = shift;
    my $macl;
    if($userid)
    {
        $macl = $main->{dbcon}->getsimplequeryhash("select role from user where enabled=1 and userid='$userid';");
        my $rhash = $macl->{role};
        $main->{aclh} = $main->{xml}->XMLin($rhash) if $rhash;
    }
    else
    {
        $main->{aclh}->{role}->{everyone} = 1;
    }

    return $main;
}

sub checkgroupweight
{
    my $main = shift;
    $main->{status_flag} = 'fail';
    my $q = $main->{dbcon}->getsimplequeryhash("select weight from groups
                            where
                            gname='$main->{form}->{gname}'
                            and ( weight <= $main->{group_weight} or weight is NULL )") if $main->{group_weight} >0;
    $main->{status_flag} = 'ok' if $q->{weight} >= 0 ;
    $main->{status_flag} = 'fail' if $q->{weight} eq '' ;
    my $line .= "[W] IP:$main->{remote_ip} p:$main->{program} f:checkgroupweight operation:check IF weight<=$main->{group_weight} for group $main->{form}->{gname} ";
    $line .= "status_flag:$main->{status_flag} user:$main->{user}";
    logdb($main, $line) unless $main->{status_flag} eq 'ok';
    goError('denied') unless $main->{status_flag} eq 'ok';
    return $main;
}

sub checkusergroupweight
{
    my $main = shift;
    my $userid = shift;
    $main->{status_flag} = 'fail';
    my $q = $main->{dbcon}->getsimplequeryhash("select
                                userid
                                from user
                                where
                                userid='$userid'
                                and ( weight<='$main->{group_weight}' or weight is NULL) ;");
    $main->{status_flag} = 'ok' if $q->{userid} > 0;
    unless ($main->{status_flag} eq 'ok')
    {
        logdb($main, "[W] IP:$main->{remote_ip} p:$main->{program} f:checkusergroupweight Permission denied to change userid:$userid, user:$main->{user}") ;
        goError('denied') ;
    }
    return $main;
}

1;
