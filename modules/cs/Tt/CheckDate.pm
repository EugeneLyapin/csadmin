package Tt::CheckDate;

use strict;
use Exporter;
use FindBin qw($Bin);
use base qw( Exporter );
use Tt::Pgen;
use Tt::Error;

our @EXPORT = qw(
        checkcurdate
        );



sub checkcurdate
{
    my $main = shift;
    my $errline ;
    $main->{pdates}->{f}->{year}->{val} = $main->{pay}->{f_year} || $main->{curdate}->{year}->{val};
    $main->{pdates}->{f}->{month}->{val} = $main->{pay}->{f_month} || $main->{curdate}->{month}->{val};
    $main->{pdates}->{f}->{day}->{val} = $main->{pay}->{f_day} || '1';
    $main->{pdates}->{t}->{year}->{val} = $main->{pay}->{t_year} || $main->{curdate}->{year}->{val};
    $main->{pdates}->{t}->{month}->{val} = $main->{pay}->{t_month} || $main->{curdate}->{month}->{val};
    $main->{pdates}->{t}->{day}->{val} = $main->{pay}->{t_day} || $main->{curdate}->{day}->{val};
    if( $main->{pay}->{f_month} > 12 )
    {
        $errline .= errline(1, "Месяц должен быть <= 12");
        $main->{pdates}->{f}->{month}->{val} = $main->{curdate}->{month}->{val};
    }
    if( $main->{pay}->{t_month} > 12 )
    {
        $errline .= errline(1, "Месяц должен быть <= 12");
        $main->{pdates}->{t}->{month}->{val} = $main->{curdate}->{month}->{val};
        $main->{errline} .= $errline;
        return $main;
    }
    my $md = checkday($main, $main->{pay}->{f_month} - 1 );
    if ( $main->{pay}->{f_day} > $md )
    {
        $errline .= errline(1, "День должен быть <= $md");
        $main->{pdates}->{f}->{day}->{val} = '1';
    }
    $md = checkday($main, $main->{pay}->{t_month} -1 );
    if ( $main->{pay}->{t_day} > $md )
    {
        $errline .= errline(1, "День должен быть <= $md");
        $main->{pdates}->{t}->{day}->{val} = $main->{curdate}->{day}->{val};
    }
    $main->{errline} .= $errline;
    $main->{pdates}->{from} = "$main->{pdates}->{f}->{year}->{val}-$main->{pdates}->{f}->{month}->{val}-$main->{pdates}->{f}->{day}->{val}";
    $main->{pdates}->{to} = "$main->{pdates}->{t}->{year}->{val}-$main->{pdates}->{t}->{month}->{val}-$main->{pdates}->{t}->{day}->{val}";
    return $main;
}

sub checkday
{
    my $main = shift;
    my $m = shift;
    my $calendar = [ 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 ];
    my $d = $calendar->[$m];
    return $d;
}

1;
