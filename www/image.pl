#!/usr/bin/perl

use strict;
use FindBin qw($Bin);
use GD;
use Tt::Config;
use Tt::Pgen;
my ($config,$p);
my $newwidth = 180;
my $newheight = 136;

die("Sorry ... no data") if( not $config = Tt::Config->new('file'));

my $f = $config->getdata();

my $image_file = $f->{file};
my $size = $f->{size};

#print $line;
die("Sorry ... no data") if(not defined($image_file) or not defined($size));
#my $image_file = q|../static/img/maps/6200cs.jpg|;
$image_file = "../static/$image_file";
my $im = GD::Image->newFromJpeg($image_file);
my ($width, $height) = $im->getBounds();

if($width < 200 or $height < 160)
{
    $size = 1;
}
else
{
    $newwidth = $width/$size;
    $newheight = $height/$size;
}

my $outim = new GD::Image($newwidth, $newheight);
$outim->copyResized($im, 0, 0, 0, 0, $newwidth, $newheight, $width, $height);
binmode STDOUT;

print "Content-type: image/jpeg\n\n";
#print "Content-type: text/html\n\n";
print $outim->jpeg();
#print "<h>$width,$height</h>";
