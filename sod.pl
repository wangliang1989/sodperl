#!/usr/bin/env perl
use strict;
use warnings;
use List::Util qw(min);
use List::Util qw(max);
use Time::Local;
use XML::LibXML;
use FindBin;
use lib $FindBin::Bin;
use LWP::Simple qw(get);
require eventArm;
require networkArm;
require waveformArm;

@ARGV >= 1 or die "Usage: perl $0 xmlfile";
my @xmls = @ARGV;
foreach my $xmlfile (@xmls){
    die "no $xmlfile" unless (-e $xmlfile);
    my $dom = XML::LibXML->load_xml(location => $xmlfile);
    my @events = &eventArm($dom);
    my @stations = &networkArm($dom);
    my @out = &waveformArm($dom, \@events, \@stations);
}

sub explain () {
    my ($dom, $in) = @_;
    my ($title) = $dom -> findnodes("/sod/$in");
    my $variable = " ";
    $variable = $title -> to_literal() if (defined($title));
    return ($variable);
}
sub trim { my $s = shift; $s =~ s/^\s+|\s+$//g; return $s };
