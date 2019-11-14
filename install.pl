#!/usr/bin/perl

use strict;
use FindBin qw($Bin);
use File::Basename;
use DBI;

my $main;
use constant { DBFILE => 'linuxdb.sql' };
$main->{basedir} = dirname($0);
$main = checkversion($main);

$main->{modules} = checkval('password',"Enter MODULES path [example, /opt/www/modules/ppc/]:",q/^[A-z0-9\.\_\/\-]+$/, '/opt/www/modules/ppc');

#system ( "mkdir -p $main->{modules}");
#system("cp -Rpvf $main->{basedir}/modules/* $main->{modules}");

$main->{dbuser} = &checkval('root','Mysql root username [root]:', q/^[A-z][A-z0-9\.\-\_]+$/, 'root');
$main->{db} = 'mysql';
$main->{pass} = checkval('password',"Enter $main->{dbuser} password:",q/.*/);
$main->{host} = checkval('host','Enter hostname [localhost]:', 'ipaddr' ,'localhost');
$main->{port} = checkval('port','Mysql port [3306]:',q/^[0-9]+$/ ,'3306');

my $dbh = getconn($main);

$main->{db} = checkval('db','Site database [ppcdb]:',q/^[A-z][A-z0-9\.\-\_]+$/, 'ppcdb');
$main->{siteuser} = checkval('siteuser','Site database user [admin]:',q/^[A-z][A-z0-9\.\-\_]+$/,'admin');
$main->{siteuserpass} = checkval('siteuserpass',"Enter $main->{siteuser} passwd [123ppcdb123123]:",q/.*/, '123ppcdb123123');
$main->{dbfile} = checkval('dbfile',"Enter db $main->{db} filename:",q/.*/, 'db.sql');
$main->{useftp} = checkval('useftp','Do you want to create FTP access? [Y/n]:', q/(^[Yy]$)|(^[Nn]$)/ ,'Y');

if($main->{userftp} =~ /^[Yy]$/)
{
    $main->{ftphost} = checkval('ftphost','Enter FTP hostname [localhost]:', 'ipaddr' ,'localhost');
    $main->{ftpuser} = checkval('ftpuser',"Enter FTP username [$main->{siteuser}]:", q/^[A-z][A-z0-9\.\-\_]+$/ ,'ftpadmin');
    $main->{ftppass} = checkval('ftppass',"Enter $main->{ftpuser} passwd [10101ppcdb10101]:",q/.*/, '10101ppcdb10101');
}

print "args: mysql version = $main->{version}, root = $main->{dbuser}, db = $main->{db}, host = $main->{host}:$main->{port}, user = $main->{dbuser}\n";
#my $str = putconfig($main);

my $s = insertsimplequery($dbh, "drop database if exists $main->{db};");
my $s = insertsimplequery($dbh, "create database $main->{db};");

if($main->{version} eq '5')
{
    $main->{query} = "create user '$main->{siteuser}'\@'$main->{host}' identified by '$main->{siteuserpass}';";
    my $s = insertsimplequery($dbh, $main->{query});
    $main->{query} = "update mysql.user set password=PASSWORD('$main->{siteuserpass}') where user='$main->{siteuser}';";
    my $s = insertsimplequery($dbh, $main->{query});
    $main->{query} = "GRANT SELECT,INSERT,UPDATE,DELETE,CREATE,DROP on $main->{db}.* to '$main->{siteuser}'\@'$main->{host}';";
    my $s = insertsimplequery($dbh, $main->{query});
    $main->{query} = "flush privileges;";
    my $s = insertsimplequery($dbh, $main->{query});
}
elsif($main->{version} eq '4')
{
    $main->{query} = "GRANT SELECT, INSERT, UPDATE, DELETE, CREATE, DROP, alter
                        ON $main->{db}.* to '$main->{siteuser}'\@'$main->{host}'
                        identified by '$main->{siteuserpass}' with grant option; ";
    my $s = insertsimplequery($dbh, $main->{query});
    $main->{query} = "flush privileges;";
    my $s = insertsimplequery($dbh, $main->{query});
}

createstruct($main);

$dbh->disconnect;
$dbh = getconn($main);

$main->{sitename} = checkval('sitename','Site name [www.domain.com]:',q/^[A-z][A-z0-9\.\-\_]+[\.][a-z]{1,4}$/,'www.domain.com');
$main->{superuser} = checkval('superuser','Site superuser name [admin]:',q/^[A-z][A-z0-9\.\-\_]+$/,'admin');

#insertsimplequery($dbh, "update config set cvalue='$main->{superuser}' where ckey='superuser';");
#insertsimplequery($dbh, "update config set cvalue='$main->{sitename}' where ckey='sitename';");
#insertsimplequery($dbh, "update config set cvalue='http://$main->{sitename}' where ckey='urlsite';");
#insertsimplequery($dbh, "update config set cvalue='$main->{modules}' where ckey='modules';");
#insertsimplequery($dbh, "update config set cvalue='users' where ckey='RegisteredUsersGroup';");
#
print "=============> Installation successfull!! \n";

sub putconfig
{
    my $main = shift;
    my $str;

    my $dbfile = 'Db/DbAuth.pm';

    $main->{configname} = "$main->{basedir}/modules/$dbfile";
    open( f, $main->{configname}) or die "Can't write: $!\n";
    while(<f>)
    {
        s/\"DBUSERPASS\"/\"$main->{siteuserpass}\"/g;
        s/\"DBUSER\"/\"$main->{siteuser}\"/g;
        s/\"DB\"/\"$main->{db}\"/g;
        s/\"HOST\"/\"$main->{host}\"/g;
        s/\"PORT\"/\"$main->{port}\"/g;
        s/\"FTPHOST\"/\"$main->{ftphost}\"/g;
        s/\"FTPUSER\"/\"$main->{ftpuser}\"/g;
        s/\"FTPPASS\"/\"$main->{ftppass}\"/g;
        $str .= $_;
    }
    close( f);

    open( f, ">","$main->{modules}/$dbfile") or die "Can't write $main->{modules}/$dbfile: $!\n";
    print f $str;
    close( f);
    return $str;
}

sub checkversion
{
    my $main = shift;
    $main->{cmd} = "mysql --version";
    $main->{version} = chomp($main->{version});

    open (CMD, "$main->{cmd}|") or die "Cant open connection: $!";

    while(my $s=<CMD>)
    {
        $main->{version} = $s;
        $main->{version} = 4 if($main->{version} =~ /Distrib\s4/);
        $main->{version} = 5 if($main->{version} =~ /Distrib\s5/);
    }

    return $main;
}

sub checkval
{
    my $val = shift;
    my $question = shift;
    my $regxp = shift;
    my $default = shift;

    my $opts;
    print "$question ";
    $opts->{$val} = <STDIN>;
    chomp ($opts->{$val});
    return $default if ( $opts->{$val} eq '' and $default );

    my %tmpl = (
        $val => $regxp,
    );

    my $rtmpl = \%tmpl;
    my $line .= &checkoptions (options => $opts, templates => $rtmpl);

    return $opts->{$val} if not($line);
    if($line)
    {
        print "$line \n";
        $val = checkval($val,$question,$regxp);
    }
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
        my $str = &errline(0,"[Debug] $o -> $options->{$o}");
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
                            $line .= &errline(1,"Incorrect format of IPaddress in option $o");
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
                            $line .= &errline(1,"Incorrect format of STRING in option $o");
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
                    # last;
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

sub errline
{
    my ($error,$line) = @_;

    if($error eq '1')
    {
        $line = "[ОШИБКА]: $line";
    }
    return($line);
}

sub getconn
{
    my $main = shift;

    my $dbname = $main->{'db'};
    my $dbhost = $main->{'host'};
    my $dbuser = $main->{'dbuser'};
    my $dbpass = $main->{'pass'};
    my $dbport = $main->{'port'};

    my $dsn = "DBI:mysql:$dbname:$dbhost:$dbport";
    print "Connect->$dsn \n";
    #my $dbh = DBI->connect("DBI:mysql:$dbname", $dbuser, $dbpass);
    my $dbh = DBI->connect( $dsn, $dbuser, $dbpass, { PrintError => 0 });

    if( not $dbh)
    {
        die("Can't connect to database: $DBI::errstr");
    }

    return( $dbh);
}

sub insertsimplequery
{
    my $dbh = shift;
    my $query = shift;
    my ($sth, $res,$n);

    die("query is not defined") if (not defined ($query));
    print "$query .. \n";

    if( not $sth = $dbh->prepare($query))
    {
        die( "Can't prepare search : $DBI::errstr");
    }

    #die( 1, 1, "Can't search : $DBI::errstr") if( not $sth->execute()) ;

    $sth->finish;
    return;
}

sub createstruct
{
    my $main = shift;
    my $dbfile = "$main->{dbfile}";

    $main->{dbfile} = "$dbfile";
    print "create database structure for site \n";
    system("cat $main->{dbfile} |mysql -u $main->{dbuser} --password='$main->{pass}' $main->{db}");
    return $main;
}
