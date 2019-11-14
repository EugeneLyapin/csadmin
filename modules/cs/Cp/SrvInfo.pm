package Cp::SrvInfo;

use strict;
use Exporter;
use FindBin qw($Bin);
use base qw( Exporter );
use Net::FTP;
use CGI qw/:standard/;
use File::Path qw(rmtree);
use Tt::Pgen;

our @EXPORT = qw(
            getsidbyip
            userbyuserid
            useridbyuser
            userbysid
            useridbysid
            );


sub getsidbyip
{
    my $main = shift;
    my $ipid = shift;
    my $HLTVport = shift;
    my $HLDSport = shift;
    my $val;

    my $arr = $main->{dbcon}->getsimplequery("
                select
                    sid
                FROM
                    srv
                where
                    ipid = '$ipid'
                    and HLTVport = '$HLTVport'
                    and HLDSport = '$HLDSport'
                ");
    foreach my $s (keys %{$arr})
    {
        next unless $s;
        $val = $arr->{$s}->[0];
    }
    return($val);
}


sub userbyuserid
{
    my $main = shift;
    my $userid = shift;
    return unless $userid;
    my $m = $main->{dbcon}->getsimplequeryhash("
                select
                    login
                from
                    user
                where
                    userid = '$userid';
                ");
    return $m->{login};
}

sub useridbyuser
{
    my $main = shift;
    my $user = shift;
    return unless $user;
    my $m = $main->{dbcon}->getsimplequeryhash("
                select
                    userid
                from
                    user
                where
                    login = '$user';
                ");
    return $m->{userid};
}

sub useridbysid
{
    my $main = shift;
    my $sid = shift;
    return unless $sid;
    my $m = $main->{dbcon}->getsimplequeryhash("
                select
                    userid
                from
                    srv
                where
                    sid = '$sid';
                ");
    return $m->{userid};
}

sub userbysid
{
    my $main = shift;
    my $sid = shift;
    return unless $sid;
    my $m = $main->{dbcon}->getsimplequeryhash("
            select
                u.login as login
            from
                user as u,
                srv as s
            where
                u.userid=s.userid
                and s.sid = '$sid';
            ");
    return $m->{login};
}

1;
