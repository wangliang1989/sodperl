#!/usr/bin/env perl
use strict;
use warnings;

sub networkArm () {
    my ($xmlfile) = @_;
    my @stationinfo = &fdsnStation($xmlfile);
    my $cmd = shift @stationinfo;
    return (@stationinfo);
}
sub fdsnStation () {
    my ($xmlfile) = @_;
    my $cmd = 'curl http://service.iris.edu/fdsnws/station/1/query\?includecomments=true&nodata=404&level=station&format=text';
    my $time = &rangeTime_network($xmlfile, 'networkArm/fdsnStation/runTimeRange/');
    print "$time\n"
    #curl http://service.iris.edu/fdsnws/station/1/query\?includecomments=true\&nodata=404\&net=*\&sta=*\&loc=*\&cha=BH?\&starttime=1999-09-20T00:00:00\&endtime=2019-09-20T00:00:00\&level=station\&format=text\&lat=24\&lon=121\&minradius\=0\&maxradius=5
}
sub rangeTime_network () {
    my ($xmlfile, $in) = @_;
    my $startTime = &explain($xmlfile, "$in/startTime");
    my $endTime = &explain($xmlfile, "$in/endTime");
    my $time = " ";
    unless (($startTime eq " ") and ($endTime eq " ")){
        $time = "starttime=$startTime" unless ($startTime eq " ");
        $time = "${time}&endtime=$endTime" unless ($endTime eq " ");
        $time = trim($time);
    }
    return ($time);
}

1;
