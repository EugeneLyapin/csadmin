package Tt::Genpost;

use strict;
use Exporter;
use FindBin qw($Bin);
use File::Basename;
use base qw( Exporter );
use POSIX qw(strftime);

our @EXPORT = qw( genpost genbr showarticles showindex );

sub genbr
{
    my $line = shift;
    $line =~ s![\r\n]{4,}!<br><br>!g;
    $line =~ s![\r\n]{1,}!<br>!g;
    $line =~ s![\s]{2}!&nbsp;&nbsp;!g;
    return $line;
}

sub genpost
{
    my $main = shift;
    my $line = shift;

    $line =~ s!\&amp\;!&!g;
    $line =~ s!\&#8212\;!-!g;
    $line =~ s!\&#8211;!-!g;
    $line =~ s!\&#8217;!'!g;
    $line =~ s!\&#8216;!'!g;
    $line =~ s!\&#8220;!\"!g;
    $line =~ s!\&#8221;!\"!g;
    $line =~ s!\&#187;!\"!g;
    $line =~ s!(\&#171\;)!\"!g;
    $line =~ s!\<!&lt;!g;
    $line =~ s!\>!&gt;!g;
    $line =~ s!([\s\r\n])\*([\S\ ]+?)\*([\:\s\.\,\r\n])!$1<strong>$2</strong>$3!g;
    $line =~ s![\*][\-]{5,}!<hr>!g;
    $line =~ s![\*]([\S|\ ]+?)[\*]!<strong>$1</strong>!g;
    $line =~ s!([\r\n])([\s]+?[\=]{5,})!$1<hr>!g;
    $line =~ s!([\r\n][\s]+)(\*[\s])!$1<img style=\"border-style:none;padding: 0px;margin-left: 10px;\" src=$main->{global}->{images}/icons/menu-leaf.gif> &nbsp;!g;
    #    $line =~ s!([\r\n][\s]+)(o[\s])!$1<img style=\"border-style:none;padding: 0px;margin-left: 10px;\" src=$main->{global}->{images}/icons/menu-expanded.gif> &nbsp;!g;
    $line =~ s!\s\=([\S][\S|\ ]+?)\=([\s\:\.\,])! <font style='font-family: Courier New; font-size: 14px'>$1</font>$2!g;
    $line =~ s!\[c\]([\S|\ ]+)\[\/c\]!<font color=orange>$1</font>!g;
    $line =~ s!\(\=([\S|\ ]+?)\=\)!(<font color=red>$1</font>)!g;
    $line =~ s!\[b\]([\S|\ ]+?)\[\/b\]!<strong>$1</strong>!g;
    $line =~ s!\[\[([\S]+)\]\[([\S| ]+)\]\]!<a href=$1>$2</a>!g;
    $line =~ s!(\s)(http:\/\/[\w\d\&\?\=\-\.\/\+\=\%\:\@\#]+)!$1<a href=$2>$2</a>!g;
    $line =~ s!\[\[([\w\d\/\:\.\&\?\=\-\#\_\;\~]+)\]\[([\w\d\/\:\.\&\?\=\-\#\_\;\~]+)\]\]!<a href=$1>$2</a>!g;
    $line =~ s!([#]\s)([\S|\ ]+)([\r\n])!<font color=#c59152>$1$2</font>$3!g;
    $line =~ s!(\s)(\/\/\s)([\S|\ ]+)([\r\n])!$1<font color=#c59152>$2$3</font>$4!g;
    $line =~ s![#]([\r\n])!<font color=#c59152>#</font>$1!g;
    $line =~ s!([\$][\{\}\w\d\.\_\-\:\$\[\]\/]+)([\"\,\?\!\s\r\n\:\;\)\<\=])!<font color=blue>$1</font>$2!g;
    $line =~ s!([\=\:\(\{\s][\@][\[\]\{\}\w\d\.\_\-]+)([\"\,\?\!\s\r\n\:\;\)\<\=])!<font color=green>$1</font>$2!g;
    $line =~ s!([\>#\s\r\n])(more|less|make|[p]?[r]?[e]?[-]?install|retry|disklabel|help)([\:\;\s\r\n])!$1<font color=magenta>$2</font>$3!g;
    $line =~ s!([\>\#\s\r\n])(quit|open|sub|sleep|else|unless|exit|eq|return|close|my|use|print|strict|[Dd]o|for|ftp|in|case|while|if|[Ff]lag[s]?|[Cc][Tt][Rr][Ll][\-\w]+?)([\;\:\(\s\r\n])!$1<font color=orange>$2</font>$3!g;
    $line =~ s!([\>\#\s\r\n])([Ss]tart|[Ee]nd|[Ss]ize|[Ss]top)([\;\:\s\r\n])!$1<font color=green>$2</font>$3!g;
    $line =~ s!([\>\#\s\r\n])(alias|[Ff]rom|[Tt]o)([\;\s\r\n])!$1<font color=blue>$2</font>$3!g;
    $line =~ s!([\>\#\s\r\n])(rar|unlink|kill|STDOUT|stdout|fork|cd|mcedit|cat|sysctl|\/dev\/tty[\w\d]+|init|minicom|grep|modprobe|find|reboot|halt|syscall|chdir)([\(\:\;\s\r\n])!$1<font color=green>$2</font>$3!g;
    $line =~ s!([\>\#\s\r\n])(radeon|fglrx|bzImage|[Ss][Cc][Ss][Ii][\_\-][\w\d]+|kernel|mpt[0-9]|baud|port|irq|uart)([\;\:\s\r\n])!$1<font color=magenta>$2</font>$3!g;
    $line =~ s!([\>\#\s\r\n])(dbm|exim)([\;\:\s\r\n])!$1<font color=magenta>$2</font>$3!g;
    $line =~ s!([\>\#\s\r\n])(qw\([\!\?\,\.\:\d\w]+\))([\;\:\s\r\n])!$1<font color=red>$2</font>$3!g;
    $line =~ s!([\>\#\s\r\n])(qw\/[\,\.\?\!\:\d\w]+\/)([\;\:\s\r\n])!$1<font color=red>$2</font>$3!g;
    $line =~ s!(\"[\S]+\")!<font color=red>$1</font>!g;
    $line =~ s!(\'[\S]+\')!<font color=red>$1</font>!g;
    $line =~ s!(\&quot;[\S]+\&quot;)!<font color=red>$1</font>!g;
    $line =~ s!(\'[\w\d\*\_\$\.\@\/\-\/]+\')!<font color=red>$1</font>!g;
    $line =~ s!(\$\_)!<font color=red>$1</font>!g;
    $line =~ s!([\w\d\_\-]+[\s]?\(\))!<font color=magenta>$1</font>!g;
    $line =~ s!([\w\d]+\@[\w\d]+[\:][\~][\>])!<font color=green>$1</font>!g;
    $line =~ s!(\[[\w\d]+\@[\w\d]+\s[\w\d]+\])!<font color=green>$1</font>!g;
    $line =~ s!\&lt;verbatim\&gt;[\n\r]*!<pre class=text>!g;
    $line =~ s!\&lt;\/verbatim\&gt;!</pre>!g;
    $line =~ s!(\<[\.\w\*]+\>)!<font color=red>$1</font>!g;
    $line =~ s!(\&lt\;[\w\*]+\&gt\;)!<font color=red>$1</font>!g;
    $line =~ s!([\$][\!])!<font color=red>$1</font>!g;
    $line =~ s!\[h\]!<br><pre class=header>!g;
    $line =~ s!\[\/h\]!</pre>!g;
    $line =~ s!\[h1\]!<br><pre class=h1>!g;
    $line =~ s!\[\/h1\]!</pre>!g;
    $line =~ s!(^|\s)\-\-\-[\+]{1,2}\s+([\S\ ]+)!<br><pre class=header>$2</pre>!g;
    $line =~ s!(^|\s)\-\-\-\+[\!]+?\s+([\S\ ]+)!<br><pre class=header>$2</pre>!g;
    $line =~ s!(^|\s)\-\-\-[\+]{3,}\s+([\S\ ]+)!<br><pre class=h1>$2</pre>!g;
    $line =~ s!(^|\s)\-\-\-\-[\+]{3,}\s+([\S\ ]+)!<br><pre class=h1>$2</pre>!g;
    $line =~ s!\[html\][\n\r]*!<p align=justify>!g;
    $line =~ s!\[\/html\]!</p>!g;
    $line =~ s!\[p\]!&nbsp;&nbsp;&nbsp;&nbsp;\n\n\n\n!g;
    $line =~ s!\[br\]!&nbsp;&nbsp;&nbsp;&nbsp;\n!g;
    $line =~ s!\[pre\][\n\r]*!<br><pre class=wiki>!g;
    $line =~ s!\[text\][\n\r]*!<br><pre class=text>!g;
    $line =~ s!\[t][\n\r]*!<br><pre class=text>!g;
    $line =~ s!\[err\][\n\r]*!<br><pre class=text>!g;
    $line =~ s!\[errheader\]!<font class=errheader>!g;
    $line =~ s!\[comment\][\n\r]*!<br><pre class=comment>!g;
    $line =~ s!\[rem\][\n\r]*!<br><pre class=rem>!g;
    $line =~ s!\[courier\][\n\r]*!<br><div class=courier>!g;
    $line =~ s!\IDEA\!!<img style=\"border-style:none;padding: 0px;margin-left: 5px;\" src=$main->{global}->{images}/icons/tip.gif>!g;
    $line =~ s!\[warning\]!<img style=\"border-style:none;padding: 0px;margin-left: 5px;\" src=$main->{global}->{images}/icons/warning.gif>!g;
    $line =~ s!\[code\][\n\r]*!<pre class=code>!g;
    $line =~ s!(\s)([\d\.]{4,})(\s)!$1<b>$2</b>$3!g;
    $line =~ s!(\s)([\d\:\.\/]+)(\s)!$1<b>$2</b>$3!g;
    $line =~ s!\[\/text\][\r\n]*!</pre><br>!g;
    $line =~ s!\[center\]!<center>!g;
    $line =~ s!\[\/center\]!</center>!g;
    $line =~ s!\[\/t\][\r\n]*!</pre><br>!g;
    $line =~ s!\[\/pre\][\r\n]*!</pre><br>!g;
    $line =~ s!\[\/rem\][\r\n]*!</pre><br>!g;
    $line =~ s!\[\/errheader\][\r\n]*!</font><br>!g;
    $line =~ s!\[\/comment\][\r\n]*!</pre><br>!g;
    $line =~ s!\[\/courier\][\r\n]*!</pre><br>!g;
    $line =~ s!\[\/rem\][\r\n]*!</pre><br>!g;
    $line =~ s!\[\/code\][\r\n]*!</pre><br>!g;
    $line =~ s!\[\/err\][\r\n]*!</pre><br>!g;

    $line =~ s!([\,\"\'\s])([\d\.\/\:]+)([\,\"\'\s])!$1<b>$2</b>$3!g;
    $line =~ s!\[bg\]!\n\n<div class=entry>\n\n <img style=\"border-style:none;padding: 5px;margin-left: 5px;\" src=$main->{global}->{images}/icons/nav-leaf.gif>&nbsp;&nbsp;!g;
    $line =~ s!\[/bg\]!</div>!g;

    $line =~ s![\r\n]{4,}!<br><br>!g;
    $line =~ s![\r\n]{1,}!<br>!g;
    $line =~ s![\s]{2}!&nbsp;&nbsp;!g;

    $line =~ s!<br><pre!
            \n<br><pre!g;

    $line =~ s!<\/pre><br>!</pre><br>
            !g;

    $line =~ s!\[img src=([\S]+) size=([\d]+)x([\d]+) smallsize=([\d\.]+?)x([\d\.]+?) align=([\w]+?)\]!
            <img align=\"$6\" border=\"0\" hspace=\"3\"
            onclick=\"window.open(\'$main->{global}->{images}/$main->{id}/big/$1\', \'contacts\',
                \'toolbar=0,scrollbars=0,location=0,statusbar=0,menubar=0,resizable=1,fullscreen=0,height=$2,width=$3\');\"
                src=\"/image.pl?file=$main->{global}->{images}/$main->{id}/big/$1&size=$4\"
                style=\"color: transparent;  padding: 5px; cursor: pointer;\"/>
                !g;


    $line =~ s!\[img src=([\S]+) smallsize=([\d\.]+?)x([\d\.]+?) align=([\w]+?)\]!
            <a style=\"background: transparent; padding: 3px; margin-left: 5px\" href=\'$main->{global}->{images}/$main->{id}/big/$1\'>
            <img align=\"$4\" border=\"0\" hspace=\"3\"
                          src=\"/image.pl?file=$main->{global}->{images}/$main->{id}/big/$1&size=$2\" style=\"color: transparent;  padding: 5px; cursor: pointer;\"/></a>
                          !g;

    $line =~ s!\[img src=([\S]+) size=([\d]+)x([\d]+) smallsize=([\d\.]+?)x([\d\.]+?)\]!
        <img align=\"left\" border=\"0\" hspace=\"3\" onclick=\"window.open(\'$main->{global}->{images}/$main->{id}/big/$1\', \'contacts\',
                \'toolbar=0,scrollbars=0,location=0,statusbar=0,menubar=0,resizable=1,fullscreen=0,height=$2,width=$3\');\"
                src=\"/image.pl?file=$main->{global}->{images}/$main->{id}/big/$1&size=$4\" style=\"color: transparent;  padding: 5px; cursor: pointer;\"/>
                !g;

    $line =~ s!\[img src=([\S]+) align=([\w]+?)\]!
                <a style=\"background: transparent; padding: 5px;\" href=\'$main->{global}->{images}/$main->{id}/big/$1\'>
            <img align=\"$2\" border=\"0\" hspace=\"3\"
                      src=\"$main->{global}->{images}/$main->{id}/big/$1\"
                      style=\"color: transparent; padding: 5px; cursor: pointer;\"/></a>
                      !g;

    $line =~ s!\[img src=([\S]+)\]!
                <a style=\"background: transparent; padding: 5px;\" href=\'$main->{global}->{images}/$main->{id}/big/$1\'>
                <img align=\"top\" border=\"0\" hspace=\"3\"
                            src=\'$main->{global}->{images}/$main->{id}/big/$1\'
                            style=\"color: transparent; padding: 5px; cursor: pointer;\"/></a>
                            !g;

    $line =~ s!\[PageName\]!$main->{PageName}!g;
    $line =~ s!\[PageRef\]!$main->{id}!g;
    $line =~ s!\[ArticleName\]!$main->{ArticleName}!g;
    $line =~ s!\[ArticleDescription\]!$main->{ArticleDescription}!g;
    $line =~ s!\[ArticleChanged\]!$main->{ArticleChanged}!g;
    $line =~ s!\[ArticleChangedBy\]!$main->{ArticleChangedBy}!g;
    $line =~ s!\[ArticleCreated\]!$main->{ArticleCreated}!g;
    $line =~ s!\[ArticleCreatedBy\]!$main->{ArticleCreatedBy}!g;
    #    $line =~ s!\<br\>!<br>\n!g;

    $line = "<table><tr><td align=justify>$line</td></tr></table>";

    return $line;

}

sub showarticles
{
    my $main = shift;
    my $line;
    my $a;

    my $rart = $main->{dbcon}->getsimplequery("select a.id,a.pageid,a.name,a.value, a.CreatedBy, a.DataCreated, a.ChangedBy, a.DataChanged, a.description
                                            from
                                                articles as a,
                                                page as p
                                            where
                                                p.pageid = a.pageid
                                                and
                                                p.name = '$main->{id}';
                                            ");

    for my $s (sort keys %{$rart})
    {
        next if not($s);
        $a->{id} = $rart->{$s}->[0];
        $a->{name} = $rart->{$s}->[2];
        $a->{value} = $rart->{$s}->[3];
        $a->{CreatedBy} = $rart->{$s}->[4];
        $a->{DataCreated} = $rart->{$s}->[5];
        $a->{ChangedBy} = $rart->{$s}->[6];
        $a->{DataChanged} = $rart->{$s}->[7];
        $a->{description} = $rart->{$s}->[8];

        $a->{link} = "[[/$main->{id}/$a->{name}][$a->{description}]] ";
        $a->{fvalue} = formataval($a);

        $a->{link} = genpost($main,$a->{link});
        $line .= "$a->{link}";
        $line .= "<img src=$main->{global}->{images}/doc_html.gif> <font style='font-size: 11px'>$a->{fvalue} ...</font><br>";
        $line .= "<font style='font-size: 10px'>CreatedBy: $a->{CreatedBy} $a->{DataCreated};</font> " if($a->{CreatedBy});
        $line .= "<font style='font-size: 10px'>ChangedBy: $a->{ChangedBy} $a->{DataChanged}</font>" if($a->{ChangedBy});
        $line .= "<br><br>\n";
    }

    $line .= readpost($main);
    #    my $dline = genpost($main,"[bg]$main->{id}: Статьи[/bg]");
    $line = "<b>$main->{id} :: articles</b><br> <table width=90%><tr><td align=justify>$line</td></tr></table>";

    return $line;

}

sub formataval
{

    my $a = shift;

    $a->{fvalue} = substr($a->{value},0,300);
    $a->{fvalue} =~ s!\[[\/]?\w+\]! !g,$a->{fvalue};
    $a->{fvalue} =~ s![\r\n]+! !g,$a->{fvalue};
    $a->{fvalue} =~ s![\']+! !g,$a->{fvalue};
    $a->{fvalue} =~ s!\&lt;\?! !g,$a->{fvalue};
    $a->{fvalue} =~ s!\&lt;!<!g,$a->{fvalue};
    $a->{fvalue} =~ s!\&gt;!>!g,$a->{fvalue};
    $a->{fvalue} =~ s!\<[\w\s\"\=#%\/;:\-\,\.\_]+\>!!g,$a->{fvalue};
    $a->{fvalue} =~ s!\<[\w\s\"\=#%\/;:\-\,\.\_]+!!g,$a->{fvalue};
    $a->{fvalue} =~ s![\s]{2,}! !g,$a->{fvalue};
    $a->{fvalue} =~ s!\<img!!g,$a->{fvalue};
    $a->{fvalue} .= "\n\n\n";

    return $a->{fvalue};

}

sub readpost
{
    my $main = shift;
    my $line;
    my $dir = "$main->{global}->{DIR}/$main->{global}->{posts}/$main->{id}";
    opendir (DIR,$dir) || return ;
    my @FILES=grep(!/^\.\.?/, readdir DIR);
    closedir(DIR);

    foreach(@FILES)
    {
        my $file = "$dir/$_";
        my $a;
        my ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,
        $atime,$mtime,$ctime,$blksize,$blocks)  = stat($file);
        open(f, $file);
        read f, $a->{value}, 300;
        $a->{fvalue} = formataval($a);
        $a->{ChangedBy} = $uid;
        $a->{DataChanged} = strftime "%a %b %e %H:%M:%S %Y", localtime($ctime);
        $line .= "<img src=$main->{global}->{images}/doc_html.gif> <a href=/show.pl?id=$main->{id}&post=$_>/$main->{id}/$_</a><br> ";
        $line .= "<font style='font-size: 11px'>$a->{fvalue} ...</font><br>";
        $line .= "<font style='font-size: 10px'>Changed: $a->{DataChanged}</font>" if($a->{ChangedBy});
        $line .= "<br><br>\n";
        close($file);
    }

    return $line;
}

sub showindex
{
    my $main = shift;
    my $line;
    my $a;

    my $rpage = $main->{dbcon}->getsimplequery("select
                        pageid,name,description
                    from page
                    ");
    for my $s (sort keys %{$rpage})
    {
        next if not($s);
        $a->{id} = $rpage->{$s}->[0];
        $a->{name} = $rpage->{$s}->[1];
        $a->{description} = $rpage->{$s}->[2];
        $line .= "<a href=/$a->{name}>$a->{name}</a> :: $a->{description} <br>\n";
    }

    $line = "<table width=99%><tr><td align=justify>$line</td></tr></table>";
    return $line;
}

1;



