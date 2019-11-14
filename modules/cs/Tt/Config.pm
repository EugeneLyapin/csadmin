package Tt::Config;

use strict;
use Exporter;
use FindBin qw($Bin);
use File::Basename;
use Db::Dbgame;
use Tt::Pgen;
use base qw( Exporter );
use POSIX qw(strftime);
use Config::Auto;

our @EXPORT = qw( debug error );

my $debug=1;
my $b;


sub new
{
    my $class = shift;
    if( @_ < 1)
    {
        debug( $debug, 1, "Can't create new Parse instance: not enough parameters");
        return 0;
    }

    my $self = {};

    bless( $self, $class);

    return $self;
}



sub gettarif
{
    my $self = shift;
    my $main = shift;

    my $tarif = $main->{dbcon}->getdbtarif();
    $main->{tarif} = $tarif;
    return($main);

}

sub getconfig
{
    my $self = shift;
    my $method = shift;
    my $id = shift;
    my $debug = shift;
    my $dbh;
    my ($p,$config,$f,$getform);
    my $dbc = Config::Auto::parse('/opt/www/deiton/conf/db.conf',format => 'perl');
    my $ftpc = Config::Auto::parse('/opt/www/deiton/conf/ftp.conf',format => 'perl');
    my $pres = Config::Auto::parse('/opt/www/deiton/conf/payments.conf',format => 'perl');

    ($b,$dbh) = Db::Dbgame->new($dbc->{host},$dbc->{db},$dbc->{user},$dbc->{pass});

    my $g = $b->getdbconfig($dbh);
    my $url = basename($0);
    $f = $self->getpostdata($f, $debug);
    $getform = $self->getdata($getform, $debug);

    $id="index" if(not defined($id));
    $id = $getform->{id} if(defined($getform->{id}));
    $id = $f->{id} if(defined($f->{id}));

    my $twiki = $f->{tt};
    my $header = $b->getpageheader($id,$dbh);
    my $res = $b->getpagestruct($id,$dbh);
    my $templates = $b->gettemplates($dbh);
    my $sid = $b->getsimplequery("select s.sid,u.login from srv as s, user as u where u.userid=s.userid") if($id eq "wiki");
    my $mapid = $b->getsimplequery("select mapid,name from map") if($id eq "wiki");

    my $main = {
            'dbc' => $dbc,
            'url' => $url,
            'ftpc' => $ftpc,
            'res' => $pres,
            'global' => $g,
            'id' => $id,
            'header' => $header,
            'pagestruct' => $res,
            'templates' => $templates,
            'dbcon' => $b,
            'wikitemplate' => $twiki,
            'form' => $f,
            'getform' => $getform,
            'sid' => $sid,
            'mapid' => $mapid,
            'dbhlr' => $dbh,
    };

    $main->{post} = &getval($main,'post');
    $main->{program} = $url;
    $main->{user} = 'everyone';
    $main->{referer} = $ENV{'REQUEST_URI'};
    $main->{remote_ip} = $ENV{'REMOTE_ADDR'} || 'empty';
    $main->{r_url} = $ENV{'QUERY_STRING'};
    $main->{r_url} = join('','?',$main->{r_url}) if($main->{r_url});
    $main->{curtime} = strftime "%a %b %e %H:%M:%S %Y GMT", gmtime;
    my $curdate = strftime "%Y %m %d", gmtime;
    my @d = split(/\s/,$curdate);
    $main->{curdate} = {
        year => {
            val => $d[0],
            w => '30px'
        },
        month => {
            val => $d[1],
            w => '20px'
        },
        day => {
            val => $d[2],
            w => '20px'
        },
    };
    my $rpage = $b->getsimplequeryhash("select name,description from page where name='$id'");

    if($rpage > 0)
    {
        $main->{PageName} = "$rpage->{name}";
        $main->{PageDescription} = "$rpage->{description}";

    }

    my $rpost;

    if($main->{post})
    {
        $rpost = $b->getsimplequeryhash("select a.id as artid, a.name,a.description,a.pageid,a.pflag,a.locked,
                                            a.DataCreated,a.DataCreated,a.ChangedBy,a.CreatedBy,a.DataChanged
                                        from
                                            articles as a,
                                            page as p
                                        where
                                            a.name='$main->{post}'
                                            and a.pageid = p.pageid
                                            and p.name = '$id'
                                        ");

    }

    if($rpost > 0)
    {
        $main->{ArticleId} = "$rpost->{artid}";
        $main->{ArticleName} = "$rpost->{name}";
        $main->{ArticleDescription} = "$rpost->{description}";
        $main->{ArticleLocked} = "$rpost->{locked}";
        $main->{ArticleCreated} = "$rpost->{DataCreated}";
        $main->{ArticleChanged} = "$rpost->{DataChanged}";
        $main->{ArticleCreatedBy} = "$rpost->{CreatedBy}";
        $main->{ArticleChangedBy} = "$rpost->{ChangedBy}";
        $main->{ArticleEdit} =  sprintf <<A;

        <form action=/admin/AdminGenArticle.pl method="POST">
        <input type=hidden name=artid value=$rpost->{artid}>
        <input type=hidden name=action value=editarticle>
        <input type=hidden name=r_url value="/$url$main->{r_url}">
        <input name=edit value='Edit' style='border:0px' type=image border=0 src=/img/i-edit.gif>
        </form>
A
    }
    return($main);
}

sub getdata
{
    my $self = shift;
    my $f = shift;
    my $debug = shift;
    my @pairs = split(/&/, $ENV{'QUERY_STRING'});
    foreach my $pair (@pairs)
    {
        my ($name, $value) = split(/=/, $pair);
        $value =~ tr/+/ /;
        $value =~ tr/+/:/;
        $value =~ s/%([a-fA-F0-9][a-fA-F0-9])/pack("C", hex($1))/eg;
        $value =~ s/~!/ ~!/g;
        $name =~ s/\.([xy])$//g;

        $f->{$name} = $value;
    }

    return($f);
}

sub getpostdata
{
    my $self = shift;
    my $f =  shift;
    my $debug = shift;
    my ($buffer, $pair, $name, $value);
    my @pairs=();

    $ENV{'REQUEST_METHOD'} =~ tr/a-z/A-Z/;

    if ($ENV{'REQUEST_METHOD'} eq "POST")
    {
        read(STDIN, $buffer, $ENV{'CONTENT_LENGTH'});
    }
    else
    {
        $buffer = $ENV{'QUERY_STRING'};
        return;
    }
    @pairs = split(/&/, $buffer);
    foreach $pair (@pairs)
    {
        ($name, $value) = split(/=/, $pair);
        $value =~ tr/+/ /;
        $value =~ s/%(..)/pack("C", hex($1))/eg;
        $name =~ s/\.([xy])$//g;
        $f->{$name} = $value;
    }

    return($f);
}

sub wikiarea
{
    my $self = shift;
    my $tt = shift;
    my $q = shift;
    my $line = $b->getftemplatedata($tt, $q) if ($tt);
    return($line);
}

1;
