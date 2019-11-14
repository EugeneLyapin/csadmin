package Tt::Error;

use strict;
use Exporter;
use FindBin qw($Bin);
use base qw( Exporter );
use Tt::Genpost;


our @EXPORT = qw( goError );


sub goError
{
    my $msg = shift;
    #    print "Location: /index.pl?id=error&post=$msg\n\n";
    print "Location: /errors/error.pl\n\n" if $msg eq 'denied';
    print "Location: /errors/notfound.html\n\n" if $msg eq 'notfound';
    print "Location: /errors/error.pl\n\n" if $msg eq 'disabled';
    print "Location: /errors/unknown.html\n\n";
    exit;
}
1;
