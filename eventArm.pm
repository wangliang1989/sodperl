#!/usr/bin/env perl
use strict;
use warnings;

sub eventArm () {
    my ($xmlfile) = @_;
    my @eventinfo = &fdsnEvent($xmlfile);
    my $cmd = shift @eventinfo;
    my $printlineEventProcess = &explain($xmlfile, "eventArm/printlineEventProcess");
    unless ($printlineEventProcess eq " ") {
        foreach (@eventinfo) {
            print "$_\n";
        }
    }
    my $filename = &explain($xmlfile, "eventArm/CSVEventPrinter/filename");
    unless ($filename eq " ") {
        open (OUT, "> $filename") or die;
        print OUT "# $cmd\n";
        foreach (@eventinfo) {
            print OUT "$_\n";
        }
        close(OUT);
    }
    return (@eventinfo);
}
sub fdsnEvent () {
    my ($xmlfile) = @_;
    my $cmd = 'fetchevent';
    my $time = &rangeTime_event($xmlfile, 'eventArm/fdsnEvent/originTimeRange/');
    my $box = &rangeBox_event($xmlfile, 'eventArm/fdsnEvent/boxArea/');
    my $mag = &rangeMag($xmlfile, "eventArm/fdsnEvent/magnitudeRange/");
    foreach ($time, $box, $mag) {
        $cmd = "$cmd $_" unless ($_ eq " ");
    }
    my @info = split m/\n/, `$cmd`;
    my @out;
    push @out, $cmd;
    foreach (@info) {
        #841715  |1999/09/22 00:49:44.020 | 23.696 | 121.099 |  40.3|ISC|ISC|ISC,1656276|Mw,5.8,HRVD|TAIWAN
        #20180815235908 2018-08-15T23:59:08.320 -116.7848330 33.4958330 5.06 0.61 Ml
        my ($origin, $evla, $evlo, $evdp) = (split m/\|/)[1..4];
        my ($maginfo) = (split m/\|/)[8];
        my ($magtype, $mag) = split ",", $maginfo;
        my ($date, $time) = split m/\s+/, trim($origin);
        my ($year, $mon, $day) = split m/\//, $date;
        my ($hour, $min, $sec) = split m/:/, $time;
        my ($isec) = split m/\./, $sec;
        push @out, "$year$mon$day$hour$min$isec ${year}-${mon}-${day}T${hour}:${min}:${sec} $evlo $evla $evdp $mag $magtype";
    }
    return(@out);
}
sub rangeMag () {
    my ($xmlfile, $in) = @_;
    my $mag = &getminmax($xmlfile, $in);
    $mag = "--mag $mag" unless ($mag eq " ");
    return ($mag);
}
sub rangeTime_event () {
    my ($xmlfile, $in) = @_;
    my $startTime = &explain($xmlfile, "$in/startTime");
    my $endTime = &explain($xmlfile, "$in/endTime");
    $startTime =~ s/T/,/g unless ($startTime eq " ");
    $endTime =~ s/T/,/g unless ($endTime eq " ");
    my $time = " ";
    unless (($startTime eq " ") and ($endTime eq " ")){
        $time = "-s $startTime" unless ($startTime eq " ");
        $time = "$time -e $endTime" unless ($endTime eq " ");
        $time = trim($time);
    }
    return ($time);
}
sub rangeBox_event () {
    my ($xmlfile, $in) = @_;
    my $lat = &getminmax($xmlfile, "$in/latitudeRange");
    my $lon = &getminmax($xmlfile, "$in/longitudeRange");
    my $space = " ";
    unless ($lat eq " ") {
        $space = "--lat $lat";
    }
    unless ($lon eq " ") {
        $space = "$space --lon $lon";
    }
    return ($space);
}

1;
