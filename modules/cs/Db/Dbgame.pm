package Db::Dbgame;

use strict;
use FindBin qw($Bin);
use DBI;

sub new {
  my $class = shift;
  my $dbh;

  if( @_ < 4) {
    die( "Can't create new bDb instance: not enough parameters");
  }

  my $self = {};
  $self->{'host'} = shift;
  $self->{'db'} = shift;
  $self->{'user'} = shift;
  $self->{'pass'} = shift;

  bless( $self, $class);
  return( 0) if( not $dbh = $self->getconn());

  return ($self,$dbh);
}


sub getconn
{
  my $self = shift;

  if( $self->{'dbh'})
  {
    if( $self->{'dbh'}->ping())
    {
      return $self->{'dbh'};
    }
  }

  my $dbname = $self->{'db'};
  my $dbhost = $self->{'host'};
  my $dbuser = $self->{'user'};
  my $dbpass = $self->{'pass'};

  my $dsn = "DBI:mysql:$dbname:$dbhost";
  my $dbh = DBI->connect( $dsn, $dbuser, $dbpass, { PrintError => 0 });

  if( not $dbh)
  {
    die("Can't connect to database: $DBI::errstr");
  }

  $self->{'dbh'} = $dbh;
  return( $dbh);
}


sub getdbconfig
{
    my $self = shift;
    my $sth;
    my $dbh = shift;

    if( not $sth = $dbh->prepare( "select ckey,cvalue from config" ))
    {
        die( "Can't prepare search : $DBI::errstr");
    }

    if( not $sth->execute())
    {
        die( 1, 1, "Can't search : $DBI::errstr");
    }

    my $res;
    while( my @row = $sth->fetchrow_array())
    {
        my $key=$row[0];
        $res->{$key}=$row[1];
    }

    return $res;
}

sub getpagestruct
{
    my $self = shift;
    my $page = shift;
    my $dbh = shift;
    my $sth;
    #    my $dbh = $self->getconn();
    #    return( 0) if( not $dbh);
    die("Page if not defined") if (not defined ($page));

    if( not $sth = $dbh->prepare( "select tt.name,pt.ttnumber
                    from ptemplates as pt,templates as tt,page as p
                    where p.pttid=pt.pttid and pt.ttid=tt.ttid and p.name = ?
                    order by pt.ttnumber asc;"
                    ))
    {
        die( "Can't prepare search : $DBI::errstr");
    }

    if( not $sth->execute($page))
    {
        die( 1, 1, "Can't search : $DBI::errstr");
    }

    my @res;
    while( my @row = $sth->fetchrow_array())
    {
        my $n=$row[1];
        $res[$n]=$row[0];
    }

    return \@res;
}

sub getpageheader
{
    my $self = shift;
    my $page = shift;
    my $sth;
    my $dbh = shift;

    die("Page is not defined") if (not defined ($page));

    if( not $sth = $dbh->prepare( "select name,description,cheader,ftemplate,pttid,pageid,value from page"))
    {
        die( "Can't prepare search : $DBI::errstr");
    }

    if( not $sth->execute())
    {
        die( 1, 1, "Can't search : $DBI::errstr");
    }

    my $res;
    while( my @row = $sth->fetchrow_array())
    {
        my $key=$row[0];
        $res->{$key}->{name}=$row[0];
        $res->{$key}->{description}=$row[1];
        $res->{$key}->{cheader}=$row[2];
        $res->{$key}->{file}=$row[3];
        $res->{$key}->{pttid}=$row[4];
        $res->{$key}->{pageid}=$row[5];
        $res->{$key}->{value}=$row[6];
    }
    return $res;
}

sub updateftemplatedata
{
    my $self = shift;
    my $line = shift;
    my $ftemplate = shift;
    my $q = shift;
    my $sth;
    my $dbh = $self->getconn();
    return( 0) if( not $dbh);
    die("Template is not defined") if (not defined ($ftemplate));

    if( not $sth = $dbh->prepare($q))
    {
        die( "Can't prepare search : $DBI::errstr");
    }

    if( not $sth->execute($line,$ftemplate))
    {
        die( 1, 1, "Can't search : $DBI::errstr");
    }



    return;


}

sub insertftemplatedata
{
    my $self = shift;
    my $line = shift;
    my $ftemplate = shift;
    my $q = shift;
    my $sth;
    my $dbh = $self->getconn();
    return( 0) if( not $dbh);
    die("Template if not defined") if (not defined ($ftemplate));

    if( not $sth = $dbh->prepare($q))
    {
        die( "Can't prepare search : $DBI::errstr");
    }

    if( not $sth->execute($ftemplate,$line))
    {
        die( 1, 1, "Can't search : $DBI::errstr");
    }
    
    return;
}

sub insertuser
{
    my $self = shift;
    my $login = shift;
    my $pass = shift;
    my $salt = shift;
    my $email = shift;
    my $fgid = shift;

    my $sth;
    my $dbh = $self->getconn();
    return( 0) if( not $dbh);
    die("login if not defined") if (not defined ($login));
    die("pass if not defined") if (not defined ($pass));
    die("salt if not defined") if (not defined ($salt));

    if( not $sth = $dbh->prepare( "insert into user(login, passwd, salt, email, gid, ObjectClass, enabled, locked) values (?, ?, ?, ?, ?, ?, ?, ?);" ))
    {
        die( "Can't prepare search : $DBI::errstr");
    }

    if( not $sth->execute($login,$pass,$salt, $email, $fgid, 'user', '1', '0' ))
    {
        die( 1, 1, "Can't search : $DBI::errstr");
    }

    return;
}

sub insertsrv
{
    my $self = shift;
    my $userid = shift;
    my $stypeid = shift;
    my $tarifid = shift;
    my $ostypeid = shift;
    my $periodid = shift;
    my $locationid = shift;
    my $gameid = shift;
    my $slots = shift;
    my $srvname = 'Counter Strike 1.6 for user $userid';
    my $sth;
    my $dbh = $self->getconn();
    return( 0) if( not $dbh);
    die("Parameters are not defined") if (not defined ($userid) or not defined($stypeid) or not defined($tarifid));

    if( not $sth = $dbh->prepare( "insert into srv(userid,stypeid,tarifid,ostypeid,periodid,locationid,gameid,numslots,mapid,name) values (?, ?, ?, ?, ?, ?, ?, ?,1,?) "))
    {
        die( "Can't prepare search : $DBI::errstr");
    }

    if( not $sth->execute($userid, $stypeid, $tarifid, $ostypeid, $periodid, $locationid, $gameid, $slots, $srvname))
    {
        die( 1, 1, "Can't search : $DBI::errstr");
    }

    return;
}

sub getftemplatedata
{
    my $self = shift;
    my $ftemplate = shift;
    my $query = shift;
    my ($sth, $res);
    my $dbh = $self->getconn();
    die("Not connected to database") if( not $dbh);
    die("Template is not defined") if (not defined ($ftemplate));

    die("Can't prepare search : $DBI::errstr") if( not $sth = $dbh->prepare($query));
    die("Can't search : $DBI::errstr") if( not $sth->execute($ftemplate));

    while( my @row = $sth->fetchrow_array())
    {
        $res=$row[0];
    }
    return $res;
}

sub getusernamestr
{
    my $self = shift;
    my $login = shift;
    my $sth;
    my $res = '.';
    my $dbh = $self->getconn();
    return( 0) if( not $dbh);
    my $query = "select login from user";

    die("Can't prepare search : $DBI::errstr") if( not $sth = $dbh->prepare($query));
    die("Can't search : $DBI::errstr") if( not $sth->execute());

    while( my @row = $sth->fetchrow_array())
    {
        $res .= $row[0];
        $res .= '.';
    }
    return $res;
}

sub getuserid
{
    my $self = shift;
    my $login = shift;
    my $sth;
    my $res;
    my $dbh = $self->getconn();
    return( 0) if( not $dbh);
    my $query = "select userid from user where login = ?";

    die("Can't prepare search : $DBI::errstr") if( not $sth = $dbh->prepare($query));
    die("Can't search : $DBI::errstr") if( not $sth->execute($login));

    while( my @row = $sth->fetchrow_array())
    {
        $res = $row[0];
    }
    return $res;
}


sub gettemplates
{
    my $self = shift;
    my $dbh = shift;
    my ($sth, $res);
    my $query = "select name from templates";
    my $sth = $self->getdbdata($dbh,$query);

    while( my @row = $sth->fetchrow_array())
    {
        my $key = $row[0];
        $res->{$key}=$row[0];
    }
    return $res;
}

sub getsimplequery
{
    my $self = shift;
    my $query = shift;
    my ($sth, $res,$n);
    my $dbh = $self->getconn();
    return( 0) if( not $dbh);

    my $sth = $self->getdbdata($dbh,$query);

    while( my @row = $sth->fetchrow_array())
    {
        $n++;
        $res->{$n}=\@row;
    }
    return $res;
}

sub getlog
{
    my $self = shift;
    my $query = shift;
    my ($sth, $res,$n, $line);
    my $dbh = $self->getconn();
    return( 0) if( not $dbh);
    my $sth = $self->getdbdata($dbh,$query);
    while( my @row = $sth->fetchrow_array())
    {
        $line .= "@row";
        $line .= "<br/>"
    }
    return $line;
}

sub getsimplequeryhash
{
    my $self = shift;
    my $query = shift;
    my ($sth, $res,$n);
    my $dbh = $self->getconn();
    return( 0 ) if( not $dbh);
    my $sth = $self->getdbdata($dbh,$query);
    $res = $sth->fetchrow_hashref();
    return $res;
}

sub getqueryhash
{
    my $self = shift;
    my $query = shift;
    my ($sth, $res,$n);
    my $dbh = $self->getconn();
    return( 0) if( not $dbh);
    my $sth = $self->getdbdata($dbh,$query);
    while( my $rh = $sth->fetchrow_hashref())
    {
        $n++;
        $res->{$n} = $rh;
    }
    return $res;
}
sub getarrqueryhash
{
    my $self = shift;
    my $query = shift;
    my ($sth, $res,$n);
    my $dbh = $self->getconn();
    return( 0) if( not $dbh);
    my $sth = $self->getdbdata($dbh,$query);
    while( my $rh = $sth->fetchrow_hashref())
    {
        push @{$res}, $rh;
    }
    return $res;
}

sub insertsimplequery
{
    my $self = shift;
    my $dbh = shift;
    my $query = shift;
    my ($sth, $res,$n);

    die("query is not defined") if (not defined ($query));

    if( not $sth = $dbh->prepare($query))
    {
        die( "Can't prepare search : $DBI::errstr");
    }

    if( not $sth->execute())
    {
        die( 1, 1, "Can't search : $DBI::errstr");
    }

    return;
}

sub insert1linequery
{
    my $self = shift;
    my $dbh = shift;
    my $query = shift;
    my $line = shift;
    my ($sth, $res,$n);
    die("query is not defined") if (not defined ($query));

    if( not $sth = $dbh->prepare($query))
    {
        die( "Can't prepare search : $DBI::errstr");
    }

    if( not $sth->execute($line))
    {
        die( 1, 1, "Can't search : $DBI::errstr");
    }

    return;

}
sub insert2linequery
{
    my $self = shift;
    my $dbh = shift;
    my $query = shift;
    my $line1 = shift;
    my $line2 = shift;
    my ($sth, $res,$n);
    die("query is not defined") if (not defined ($query));

    if( not $sth = $dbh->prepare($query))
    {
        die( "Can't prepare search : $DBI::errstr");
    }

    if( not $sth->execute($line1,$line2))
    {
        die( 1, 1, "Can't search : $DBI::errstr");
    }
    return;
}

sub getdbdata
{
    my $self = shift;
    my $dbh = shift;
    my $query = shift;
    my $n = shift;
    my $sth;

    if( not $sth = $dbh->prepare($query))
    {
        die( "Can't prepare search : $DBI::errstr");
    }

    $sth->execute($n) if(defined($n));
    $sth->execute() if(not defined($n));
    return($sth);
}


1;
