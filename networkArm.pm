#!/usr/bin/env perl
use strict;
use warnings;

sub networkArm () {
    my ($dom) = @_;
    my @stationinfo = &fdsnStation($dom);
    my $url = shift @stationinfo;
    my $printlineStaProcess = &explain($dom, "networkArm/printlineStaProcess");
    unless ($printlineStaProcess eq " ") {
        foreach (@stationinfo) {
            print "$_\n";
        }
    }
    my $filename = &explain($dom, "networkArm/CSVStaPrinter/filename");
    unless ($filename eq " ") {
        open (OUT, "> $filename") or die;
        print OUT "# $url\n";
        foreach (@stationinfo) {
            print OUT "$_\n";
        }
        close(OUT);
    }
    return (@stationinfo);
}
sub fdsnStation () {
    my ($dom) = @_;
    my $url = 'http://service.iris.edu/fdsnws/station/1/query?';
    $url = "${url}net=*\&sta=*\&loc=*\&cha=*";
    my $time = &rangeTime_network($dom, 'networkArm/fdsnStation/runTimeRange/');
    my $rad = &rangeRad_network($dom, 'networkArm/fdsnStation/stationPointDistance/');
    $url = "$url\&$time\&level=station&format=text" unless ($time eq " ");
    $url = "$url\&$rad" unless ($rad eq " ");
    $url ="$url\&includecomments=true&nodata=404";
    my $html = get $url;
    my @info = split m/\n/, $html;
    return ($url, @info);
}
sub rangeTime_network () {
    my ($dom, $in) = @_;
    my $startTime = &explain($dom, "$in/startTime");
    my $endTime = &explain($dom, "$in/endTime");
    my $time = " ";
    unless (($startTime eq " ") and ($endTime eq " ")){
        $time = "starttime=$startTime" unless ($startTime eq " ");
        $time = "${time}\&endtime=$endTime" unless ($endTime eq " ");
        $time = trim($time);
    }
    return ($time);
}
sub rangeRad_network () {
    my ($dom, $in) = @_;
    my $latitude = &explain($dom, "$in/latitude");
    my $longitude = &explain($dom, "$in/longitude");
    my $unit = &explain($dom, "$in/unit");
    my $min = &explain($dom, "$in/min");
    my $max = &explain($dom, "$in/max");
    my $rad = " ";
    if ((defined($latitude)) and (defined($longitude)) and (defined($unit)) and (defined($min)) and (defined($max))) {
        $min = $min / 111.195 if ($unit eq "KILOMETER");
        $max = $max / 111.195 if ($unit eq "KILOMETER");
        $rad = "lat=$latitude\&lon=$longitude\&minradius=$min\&maxradius=$max" if (defined($latitude));
    }
    return ($rad);
}

1;