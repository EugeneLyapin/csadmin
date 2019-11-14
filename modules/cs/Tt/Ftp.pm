package Tt::Ftp;

use strict;
use Exporter;
use FindBin qw($Bin);
use base qw( Exporter );
use Net::FTP;
use Tt::Pgen;
use File::Path qw(rmtree);
use CGI qw/:standard/;

our @EXPORT = qw(
        showmode
        uploadfile
        uploadconfig
        );

$CGI::POST_MAX = 50000000;
sub showmode
{
    my $main = shift;
    my $ftp = shift;
    my $line;
    my $file = $main->{file};
    $file =~ s/\-nnn\-/ /g;
    my $newdir = $main->{newdir};
    my $curdir = $main->{curdir};
    my $action = $main->{action};
    my $login = $main->{ftp}->{login};
    my $pass = $main->{ftp}->{pass};
    my $host = $main->{ftp}->{host};

    if($action eq 'cd')
    {
        if(!($ftp->cwd($file)))
        {
            $line .= "$@" .$ftp->message;

        }
    }
    elsif($action eq 'get')
    {
        my $ftpurl = "ftp://$login:$pass\@$host/$file";
        print "Location: $ftpurl\n\n";
    }
    elsif(($action eq 'delete') or ($action eq 'rmdir'))
    {

        my $s;
        $s = $ftp->delete($main->{getform}->{dfile}) if($action eq 'delete');
        $s = $ftp->rmdir($main->{getform}->{dfile}) if($action eq 'rmdir');
        $line .= errline(1, "$@" .$ftp->message ) unless $s;
        my $cpath = "$main->{getform}->{dfile}";
        $cpath =~ s!(.*/)(.*)!$1!g;
        $cpath =~ s/\-nnn\-/ /g;
        $line .= errline(1,"$cpath: $@" .$ftp->message) unless $ftp->cwd($cpath);
    }
    elsif( $newdir !~ /[A-z0-9\_\.|-]/ and $action eq 'mkdir')
    {
        $line .= &errline(1,"Каталог не соответствует требованиям [0-9A-z\.\-\_]<br> Воспользуйтесь стандартным FTP-клиентом");
    }
    elsif($action eq 'mkdir')
    {
        $curdir =~ s/\-nnn\-/ /g;
        my $dir = "$curdir/$newdir";
        $dir =~ s!//!/!g, $dir;
        $line .= errline(1,"$@" .$ftp->message) unless $ftp->mkdir($dir);
        $line .= errline(1,"$@" .$ftp->message) unless $ftp->cwd($curdir) ;
    }
    else
    {
        $file = $main->{file};
        $line .= errline(1,"$@" .$ftp->message) unless $ftp->cwd($file);
    }

    $ftp->binary;
    $main = ftplist($main,$ftp);
    $main->{errline} .= $line;

    return $main;
}

sub ftplist
{
    my $main = shift;
    my $ftp = shift;
    my $line;
    my $curpath;

    $curpath = $ftp->pwd();
    $main->{ftp}->{curpath} = $curpath;
    my @arr = $ftp->dir();
    $main->{errline} .= errline(1,"Failed to get current path: $@<br>") if( $@ );
    $main->{errline} .= errline(0,"path = $curpath ");
    $main->{ftp}->{list} = @arr;
    my $f;
    my $i;

    foreach my $s (@arr)
    {
        $i++;
        my ($p1,$p2,$p3,$p4,$p5,$p6,$p7,$p8,$p9) = ($s =~ /(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(.*)/);
        next if($p9 eq '.');
        next if($p9 eq '.ftpaccess');
        next if ($p9 eq '..');
        my $link;
        my $cpath = $curpath;
        $cpath = '' if($curpath eq '/');
        my $file = "$cpath/$p9";
        $file =~ s/\s/-nnn-/g;
        $f->{$i}->{file} = $file;
        $f->{$i}->{type} = $p1 =~ /^d/ ? 'dir' : 'file';
        $f->{$i}->{action} =  $p1 =~ /^d/ ? 'cd' : 'get';
        $f->{$i}->{delaction} =  ( $p1 =~ /^d/ and $p9 !~ /^\.\.$/ ) ? 'rmdir' : 'delete';
        $f->{$i}->{p1} = $p1;
        $f->{$i}->{p2} = $p2;
        $f->{$i}->{p3} = $p3;
        $f->{$i}->{p4} = $p4;
        $f->{$i}->{p5} = $p5;
        $f->{$i}->{p6} = $p6;
        $f->{$i}->{p7} = $p7;
        $f->{$i}->{p8} = $p8;
        $f->{$i}->{p9} = $p9;
    }
    $main->{f} = $f;
    return $main;
}


sub uploadfile
{
    my $main = shift;
    my $login = $main->{ftp}->{login};
    my $pass = $main->{ftp}->{pass};
    my $host = $main->{ftp}->{host};

    my $downpath = "/tmp/";

    $downpath .= "$login." .rand(10000);
    mkdir $downpath, 0700;

    my $in = $main->{datafile};
    my $ftpdir = param('file');

    my ($name) = $in =~ m#([^\\/:]+)$#;

    open(OUT,">$downpath/$name");
    binmode(OUT);

    my $total_bytes = 0;
    my $buffer;

    while (my $bytesread = read($in, $buffer, 1024))
    {
        print OUT $buffer;
        $total_bytes += $bytesread;
    }

    close $in;
    close OUT;

    my $ftp = Net::FTP->new($host, Debug => 0) or $main->{errline} .= &errline(1,"Cannot connect to $host: $@");
    my $s = $ftp->login($login,$pass) or $main->{errline} .= &errline(1,"Cannot login to ftp server: " .$ftp->message);
    $ftp->binary;
    unless ($ftp->cwd($ftpdir))
    {
        $main->{errline} .= "$name<br> $@" .$ftp->message;
        return $main;
    }
    rmtree($downpath) if $ftp->put("$downpath/$name");
    return $main;

}

sub uploadconfig
{
    my $host = shift;
    my $login = shift;
    my $pass = shift;
    my $ftpdir = shift;
    my $name = shift;
    my $strin = shift;
    return errline(1,"No ftp login") unless $login;
    my $downpath = "/tmp/";
    $downpath .= "$login." .rand(10000);
    mkdir $downpath, 0700;
    my $in;
    open(OUT,">$downpath/$name");
    binmode(OUT);
    print OUT $strin;
    close(OUT);
    my ($line,$errline);
    my $ftp = Net::FTP->new($host, Debug => 0, Timeout => 3) or  return errline(1,"Cannot connect to $host: $@ ");
    my $s = $ftp->login($login,$pass) or return errline(1,"Cannot login to ftp server: $ftp->message ");
    $ftp->binary;
    return errline(1,"$name: FTP $@" .$ftp->message) unless $ftp->cwd($ftpdir);
    rmtree($downpath) if $ftp->put("$downpath/$name");
    return ($errline);
}

1;
