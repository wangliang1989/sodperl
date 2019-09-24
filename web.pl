#!/usr/bin/env perl
use strict;
use warnings;
use Time::Local;
use XML::LibXML;
use FindBin;
use lib $FindBin::Bin;
require eventArm;
require networkArm;

@ARGV >= 1 or die "Usage: perl $0 xmlfile";
my @xmls = @ARGV;
foreach my $xmlfile (@xmls){
    my @events = &eventArm($xmlfile);
    my @stations = &networkArm($xmlfile);
}

sub explain () {
    my ($xmlfile, $in) = @_;
    my $dom = XML::LibXML->load_xml(location => $xmlfile);
    my ($title) = $dom -> findnodes("/sod/$in");
    my $variable = " ";
    $variable = $title -> to_literal() if (defined($title));
    return ($variable);
}
sub getminmax () {
    my ($xmlfile, $in) = @_;
    my $min = &explain($xmlfile, "$in/min");
    my $max = &explain($xmlfile, "$in/max");
    my $out = "$min:$max";
    $out = " " if ($out eq " : ");
    return ($out);
}
sub trim { my $s = shift; $s =~ s/^\s+|\s+$//g; return $s };
