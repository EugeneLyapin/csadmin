#!/usr/bin/perl

use strict;
use FindBin qw($Bin);
use Tt::Genpage;
use Tt::Config;
use Tt::Genpost;
use Tt::Pgen;
use Template;

my ($p,$config,$main);
die("Sorry ... no data") if( not $config = Tt::Config->new('file'));
die("Sorry ... no data") if( not $p = Tt::Genpage->new('file'));
my $main = $config->getconfig('post');
$main->{user} = 'everyone';
my $hline = $p->header();
my $line = gen_file_data($main, 'error');
print $hline;
print $line;
