package Tt::Genpage;

use strict;
use Exporter;
use FindBin qw($Bin);
use File::Basename;
use Tt::Error;
use Tt::Pgen;
use base qw( Exporter );
our @EXPORT = qw( error );

sub new
{
    my $class = shift;

    if( @_ < 1)
    {
    die("Can't create new Parse instance: not enough parameters");
    return 0;
    }

    my $self = {};

    bless( $self, $class);

    return $self;
}


sub getpagevalue
{
    my $self = shift;
    my $main = shift;
    my ($line,$p,$parse,$page);
    my $id = $main->{id};
    $main->{mainmenu}->{$id}->{active}='active';
    my $rpage = $main->{dbcon}->getsimplequeryhash("select pageid,name,description,pttid,cheader,value,ftemplate
                                            from page where name='$id'");
    $line = $rpage->{value};
    return $line;
}

sub getpostvalue
{
    my $self = shift;
    my $main = shift;
    my $line;
    my $pflag;
    my $post = $main->{getform}->{post};
    $post = $main->{form}->{post} if($main->{form}->{post});

    my $rpage = $main->{dbcon}->getsimplequeryhash("select pageid from page where name = '$main->{id}'");
    goError('notfound') unless $rpage->{pageid} > 0;
    my $rpost = $main->{dbcon}->getsimplequeryhash("select a.name,a.description,a.pageid,a.value, a.pflag
                                            from
                                                articles as a,
                                                page as p
                                            where
                                                a.name='$post'
                                                and a.pageid = p.pageid
                                                and p.name = '$main->{id}'
                                            ") if $post;

    if($rpost > 0)
    {
         $line = "$rpost->{value}";
         $pflag = "$rpost->{pflag}";
    }
    else
    {
        ($line,$pflag) = $self->catfile($main);
    }
    return ($line,$pflag);

}

sub catfile
{
    my $self = shift;
    my $main = shift;
    my $file = "$main->{global}->{DIR}/$main->{global}->{posts}/$main->{id}/$main->{getform}->{post}";
    my $pflag = 1;
    my $line;

    open(out,"$file") or return($line, $pflag);
    while (<out>)
    {
       $line .= $_;
    }
    close(out);
    return ($line, $pflag);

}

sub gencontent
{
    my $self = shift;
    my $line = shift;
    my $fromline = shift;
    my $toline = shift;
    $line =~ s!$fromline!$toline!g;
    return $line;

}

sub genpage
{
    my ($self,$main,$line,$dline,$cat,$mp) = @_;

    $cat = 'main' if not defined $cat;
    my $id = $main->{id};
    my ($tt,$mpi, $status,$errline);
    my $rtt = $main->{dbcon}->getsimplequery("select r.regname,r.value
    from regtemplates as r,  regcategories as c where r.regcatid = c.id and c.name = '$cat';");

    for my $s (sort keys %{$rtt})
    {
        next unless ($s);
        my $st = 0;
        $tt->{regname} = $rtt->{$s}->[0];
        $tt->{value} = $rtt->{$s}->[1];
        $st = 1 if($line =~ /$tt->{regname}/);
        $status = 1 if($st);
        $line =~ s!$tt->{regname}!$tt->{value}!g;
        $line =~ s!\[PageName\]!$main->{PageName}!g;
        $line =~ s!\[PageDescription\]!$main->{PageDescription}!g;
        $line =~ s!\[PageRef\]!$id!g;
        $line =~ s!\[urlsite\]!$main->{global}->{urlsite}!g;
        $line =~ s!\[PostName\]!$main->{getform}->{post}!g;
        $line =~ s!\[ArticleName\]!$main->{ArticleName}!g;
        $line =~ s!\[ArticleDescription\]!$main->{ArticleDescription}!g;
        $line =~ s!\[ArticleChanged\]!$main->{ArticleChanged}!g;
        $line =~ s!\[ArticleChangedBy\]!$main->{ArticleChangedBy}!g;
        $line =~ s!\[ArticleCreated\]!$main->{ArticleCreated}!g;
        $line =~ s!\[ArticleCreatedBy\]!$main->{ArticleCreatedBy}!g;
        $line =~ s!\[ArticleEdit\]!$main->{ArticleEdit}!g;
        $line =~ s!\[USER\]!$main->{user}!g;
        $line =~ s!\[TIME\]!$main->{curtime}!g;
        my $regname = $tt->{regname};
        if($mp->{$regname} eq $regname and $st and $regname )
        {
            logdb($main, "Loop found in page: $tt->{regname} ... Fix your page/expression value");
            goError('unknown');
        }
        $mpi->{$regname} = $regname if($st);
    }

    foreach my $s (keys %{$mpi})
    {
        $mp->{$s} = $mpi->{$s};
    }

    $line =~ s!<CONTENT>!$dline!g;
    $line = $self->genpage($main,$line,$dline,$cat,$mp) if($status and $cat eq 'main');
    return $line;
}

sub checkpage
{
    my ($self,$main,$line,$cat,$mp,$step) = @_;

    $cat = 'main' if not defined $cat;
    my $id = $main->{id};
    my ($tt,$mpi,$status,$errline);
    my $rtt = $main->{dbcon}->getsimplequery("select r.regname,r.value
                                            from
                                            regtemplates as r,
                        regcategories as c
                        where
                        r.regcatid = c.id
                        and
                        c.name = '$cat'
                        ");
    for my $s (sort keys %{$rtt})
    {
        if($s)
        {
            my $st = 0;

            $tt->{regname} = $rtt->{$s}->[0];
            $tt->{value} = $rtt->{$s}->[1];
            $st = 1 if($line =~ /$tt->{regname}/);

            $status = 1 if($st);

            $line =~ s!$tt->{regname}!$tt->{value}!g;
            my $regname = $tt->{regname};
            $errline = errline(1,"Function checkpage: Loop found in page: $tt->{regname} ... Fix your page/expression value") if($mp->{$regname} eq $regname and $st and $regname );
            $mpi->{$regname} = $regname if($st);
        }
    }

    foreach my $s (keys %{$mpi})
    {
        $mp->{$s} = $mpi->{$s};
    }

    $step++ if($status);
    return $errline if($errline);
    $errline .= $self->checkpage($main,$line,$cat,$mp,1) if($status);
    return $errline;

}

sub header
{
    my $self = shift;
    my $line = "Content-Type: text/html\n\n";
    return($line);
}

sub pheader
{
    my $self = shift;
    my $line = "Content-Type: text/plain\n\n";
    return($line);
}

sub geninbox
{
    my $self = shift;
    my $header = shift;
    my $name = shift;
    my $res = shift;
    my $selected = shift;
    my $html = shift;
    my $width = shift;
    my $c = shift;

    my ($s,$line,$filename);

    $width = 230 if(not defined $width);
    $width .= 'px';
    if($html)
    {
        $line .= sprintf "<tr><td>$header</td>\n";
        $line .= sprintf "<td><select name=$name id=$name STYLE=\"width: $width\"  onchange=\"rechecksum()\">\n";
    }
    else
    {
        $line .= sprintf "$header \n";
        $line .= sprintf "<select name=$name id=$name STYLE=\"width: $width\"  onchange=\"hideconfig()\">\n";
    }
    foreach my $tt (sort keys %{$res})
    {
        if($tt)
        {
            if($res->{$tt}->[0] eq $selected)
            {
                if(defined ($selected))
                {
                    $s = 'selected';
                    $filename = $res->{$tt}->[1];
                }
            }
            else
            {
                $s = '';
            }
            $line .= sprintf "<option value=$res->{$tt}->[0] $s>$res->{$tt}->[1]</option>\n";
        }
    }
    $line .= "</select>";
    $line .= "<input type=hidden name=filename$c value=$filename>";
    $line .= "</td></tr>\n" if($html);

    return($line);

}


sub gendata {
    my $self = shift;
    my $main = shift;
    my $parse = shift;
    my $tt = shift;
    my $content = shift;
    my $fline = shift;
    my $line;

    if($tt=~/CONTENT/)
    {
        return ($fline) if($fline);
        $tt=$content if($content);
    }

    my $file="$main->{global}->{templates}/$tt";

    my $l = $main->{dbcon}->getftemplatedata($tt,"select value from templates where name = ?") if($tt);
    my @lines = split(/[\r\n]/,$l);

    foreach my $ll (@lines)
    {
        $line .= $ll;
        $line .= "\n";
    }
    $line =~ s/[\r\n]+/\n/g;
    return($line);
}


1;



