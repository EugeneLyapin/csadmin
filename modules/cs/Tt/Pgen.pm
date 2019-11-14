package Tt::Pgen;

use strict;
use Exporter;
use FindBin qw($Bin);
use File::Basename;
use base qw( Exporter );
use LWP::UserAgent;
use Tt::Error;
use Tt::Genpost;
use CGI qw/:standard/;
use Data::Dumper;
use Template;

our @EXPORT = qw( debug
        logdb
        paylog
        error
        errline
        checkoptions
        getval
        checkval
        ishash
        showhash
        isarray
        formatline
        getsavebutton
        createarrayhids
        gentemplate
        gendbtemplate
        gendbpagedata
        genfpagedata
        gendbdata
        showgetpostdata
        gen_file_data
        genhashtoxml
        createroothash
         );

my $debug=1;



sub error
{
    my $string=shift(@_);
    my $message="[ERROR] $string\n";
    print $message;
    exit(1);

}

sub debug
{
    my $debug=shift;
    my $level=shift;
    my $string=shift;
    my $message="$string \n ";
    print $message if($debug>=$level);
    return;
}

sub checkoptions
{
    my %args = @_;
    my $options = $args{options};
    my $templates = $args{templates};
    my $debug = $args{debug};
    my $line;

    foreach my $o (sort keys %{$options})
    {
        my $status;
        my $str = errline(0,"[Debug] $o -> $options->{$o}");
        print $str if($debug);
        foreach my $t (sort keys %{$templates})
        {
            if($o eq $t)
            {
                $status = 1;
                if(defined ($templates->{$t}))
                {
                    if($templates->{$t} eq 'ipaddr')
                    {
                        my ($p1,$p2,$p3,$p4) = ( $options->{$o} =~ /^([1-9][0-9]?[0-9]?)\.([0-9][0-9]?[0-9]?)\.([0-9][0-9]?[0-9]?)\.([0-9][0-9]?[0-9]?)$/ );

                        $p1 = undef if($p1 > 254 or  $p2 > 254 or $p3 > 254 or $p4 > 254);
                        if(not defined ($p1))
                        {
                            $line .= errline(1,"Incorrect format of IPaddress in option $o");
                            next;
                        }

                    }
                    elsif($templates->{$t} eq 's')
                    {
                        if($options->{$o}=~/^\S+$/)
                        {
                            next;
                        }
                        else
                        {
                            $line .= errline(1,"Incorrect format of STRING in option $o");
                            next;
                        }

                    }
                    elsif($templates->{$t} eq 'n')
                    {
                        if($options->{$o} =~ /^[\d]+$/)
                        {
                            next;
                        }
                        else
                        {
                            $line .= &errline(1,"Incorrect format of NUMERIC in option $o");
                            next;
                        }

                    }
                    elsif($options->{$o}=~/$templates->{$t}/)
                    {
                        next;
                    }
                    else
                    {
                        $line .= &errline(1,"Argument for option $o is incorrect or null");
                            next;
                    }

                }
                elsif(defined($options->{$o}))
                {
                    $line .= &errline(1,"Option $o has argument: $options->{$o}");
                }
                else
                {
                    next;
                }
            }
        }

        if($status)
        {
            next;
        }
        else
        {
            $line .= &errline(1,"Unknown argument $o");
        }
    }

    return($line);
}


sub getval
{
    my $main = shift;
    my $str = shift;
    my $v;

    $v = $main->{getform}->{$str} if($main->{form}->{$str} eq '');
    $v = $main->{form}->{$str} if($main->{getform}->{$str} eq '');
    $v = param($str) if not $v;
    return $v;
}

sub getsavebutton
{
    my $name = shift;
    my $line = sprintf <<A;
        <p align=center><input name=$name value='Save' style="background-color: transparent; border: 0px;color:transparent;" type=image border=0 src=/img/admin/document-save.png></p>
        <center>Сохранить изменения</center>
A
    return $line;
}


sub createarrayhids
{
    my $hids = shift;
    return if not($hids);

    my $chids;
    my @ahids = split(/;/,$hids);
    foreach (@ahids)
    {
        $chids->{$_} = $_;
    }

    return $chids;

}

sub StrEscaped
{
    my ($str)=@_;
    $str=~s/([^0-9A-Za-z\\?&=:;])/sprintf("%%%x", ord($1))/eg;
    return $str
}


sub checkval
{
    my $val = shift;
    my $rval = shift;
    my $regxp = shift;

    my $line;
    my $opts;
    $opts->{$val} = $rval;
    chomp ($opts->{$val});

    $line = errline(1,"Value $val not defined ... ") if not defined($rval);
    return $line if($line);

    my %tmpl = (
        $val => $regxp,
    );

    my $rtmpl = \%tmpl;
    my $line .= &checkoptions (options => $opts, templates => $rtmpl);

    return $line;

}



sub errline
{
    my ($error,$line,$main) = @_;


    if($error eq '1')
    {
        $line =~ s/\</&lt;/g, $line;
        $line =~ s/\>/&gt;/g, $line;

        $line = "<font size=3 color=#ff2b2b>[ОШИБКА]: $line</font><br>";
    }
    elsif($error eq '0')
    {
        $line = "<img src=/img/yes.gif> <font size=2 color=#36803c>$line</font><br>";
    }
    elsif($error eq '2')
    {
        $line = "<font size=3 color=#d19427>$line</font><br>";
    }
    elsif($error eq '3')
    {
        $line = genpost($main,$line) if($line);
    }
    return($line);
}


sub gentemplate
{
    my $main = shift;
    my $file = shift;

    my $line;
    my $dbs;

    my $template = $file || $main->{id};
    $main->{textarea} = 'textarea';
    my $vars = {
        main => $main,
    };

    my $tt = Template->new({
                INCLUDE_PATH => $main->{global}->{templates},
                INTERPOLATE  => 0,
                START_TAG => quotemeta('[+'),
                END_TAG   => quotemeta('+]'),
    }) || die "$Template::ERROR\n";

    $tt->process($template, $vars, \$line ) || die $tt->error(), "\n";

    return $line;

}

sub gen_file_data
{
    my $main = shift;
    my $file = shift;
    my $line;
    $file = $file || $main->{id};
    $file = $main->{global}->{templates}.'/'.$file;
    $main->{textarea} = 'textarea';
    open(f,$file);
    my @stat = stat($file);
    sysread(f,$line, $stat[7]);
    close(f);
    return $line;
}

sub gendbtemplate
{
    my $main = shift;
    my $template = shift;
    my $inline = shift;

    my $line;
    my $dbs;

    my $template = $template || $main->{id};
    $main->{textarea} = 'textarea';
    my $strin = $main->{dbcon}->getsimplequeryhash("select
                    regtid,regname,value,rname,regcatid
                from regtemplates where rname='$template'") unless $inline;
    $strin->{value} = $inline if $inline;
    my $vars = {
        main => $main,
    };

    my $tt = Template->new({
                INTERPOLATE  => 0,
                START_TAG => quotemeta('[+'),
                END_TAG   => quotemeta('+]'),
    }) || goError("$Template::ERROR");

    $tt->process(\$strin->{value}, $vars, \$line ) || die $tt->error(), "\n";
    return $line;
}

sub gendbdata
{
    my $main = shift;
    my $template = shift;
    my $line;
    my $dbs;
    my $template = $template || $main->{id};
    $main->{textarea} = 'textarea';
    my $strin = $main->{dbcon}->getsimplequeryhash("select
                    regtid,regname,value,rname,regcatid
                from
                    regtemplates
                where rname='$template'");
    return $strin->{value};
}

sub ishash
{
    my $r = shift;
    return 1 if(ref($r) eq 'HASH');
    return 0;
}

sub isarray
{
    my $r = shift;
    return 1 if(ref($r) eq 'ARRAY');
    return 0;
}


sub showhash
{
    my $main = shift;
    my $h = shift;
    my $f = shift;
    print "<pre>\n" if $f eq 'formatted';
    debug($main->{global}->{debug}, 3, Dumper($h));
    print "</pre>\n" if $f eq 'formatted';
    return ;
}

sub formatline
{
    my $line = shift;
    $line =~ s/[\r\n]*[\s]*?[\r\n]/\n/g;
    $line =~ s/[\r\n]{2,}/\n/g;
    return $line;
}

sub showgetpostdata
{
    my $main = shift;
    my $dump_enable = shift;

    if($dump_enable)
    {
        print "<pre> \n";
        showhash($main, $main->{form} );
        showhash($main, $main->{getform});
        print "</pre> \n";
        return;
    }

    print "<pre>\n";
    print "======== form \n";
    foreach my $s (sort keys %{$main->{form}})
    {
        print " $s: $main->{form}->{$s} \n";
    }
    print "======== getform \n";
    foreach my $s (sort keys %{$main->{getform}})
    {
        print " $s: $main->{getform}->{$s} \n";
    }
    print "</pre>\n";
}

sub logdb
{
    my $main = shift;
    my $event = shift;
    return $main unless $main->{global}->{debug} > 1;
    my $s = $main->{dbcon}->insertsimplequery($main->{dbhlr}, "insert
    into log set time=CURRENT_TIMESTAMP, event='$event'");
    return $main;
}

sub paylog
{
    my $main = shift;
    my $payrec = shift;

    my $s = $main->{dbcon}->insertsimplequery($main->{dbhlr}, "insert into paylog
                                            set
                                                time=CURRENT_TIMESTAMP,
                                                event='$payrec->{event}',
                                                summ='$payrec->{summ}',
                                                userid='$payrec->{userid}',
                                                dkflag='$payrec->{dkflag}',
                                                CurrId='$payrec->{CurrId}'
                                            ");
    return $main;
}

sub genhashtoxml
{
    my $main = shift;
    my $rhash = shift;
    delete $rhash->{status};
    $rhash->{ObjectName}->{status} = '1';

    my @arr = $main->{xml}->XMLout($rhash,
                            KeepRoot   => 1,
                            NoSort => 1,RootName => 'rhash' );
    undef $rhash;
    $rhash .=  $_ foreach (@arr);
    return $rhash;
}

sub createroothash
{
    my $main = shift;
    my $rhash;
    my $line .= errline(0,'hash created');
    $rhash->{prop} = {
            ObjectName => {
                status => 1,
            },
    } ;
    $rhash = genhashtoxml($main, $rhash);
    my $h = $main->{xml}->XMLin($rhash);
    return $h;
}
sub gendbpagedata
{
    my $main = shift;
    my $p = shift;
    my $page = shift || $main->{id};
    my $hline = $p->header();
    my $dline = gendbdata($main, $page);
    my $line = $p->getpagevalue($main);
    $line = $p->genpage($main,$line,$dline);
    $line = gendbtemplate($main, undef, $line);
    $line = $hline.$line;
    return $line;
}
sub genfpagedata
{
    my $main = shift;
    my $p = shift;
    my $page = shift || $main->{id};
    my $hline = $p->header();
    my $dline = gen_file_data($main, $page);
    my $line = $p->getpagevalue($main);
    $line = $p->genpage($main,$line,$dline);
    $line = gendbtemplate($main, undef, $line);
    $line = formatline($line) if $main->{formatflag};
    $line = $hline.$line;
    return $line;
}

1;
