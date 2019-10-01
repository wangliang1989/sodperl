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
    my @events = eventArm($dom);
    my @stations = &networkArm($dom);
    my @out = &waveformArm($dom, \@events, \@stations);
}

sub explain {
    my ($dom, $in) = @_;
    my ($title) = $dom -> findnodes("/sod/$in");
    my $variable = " ";
    $variable = $title -> to_literal() if (defined($title));
    return ($variable);
}
sub time2dir {
    my ($origin) = @_;
    my ($year, $mon, $day, $hour, $min, $sec) = extractime($origin);
    $sec = int $sec;
    return ("${year}${mon}${day}${hour}${min}${sec}");
}
sub extractime {
    my ($origin) = @_;
    my ($date, $time) = split "T", $origin;
    my ($year, $mon, $day) = split "-", $date;
    my ($hour, $min, $sec) = split ":", $time;
    return ($year, $mon, $day, $hour, $min, $sec);
}
sub time_add {
    my ($origin, $timespan) = @_;
    my ($year, $mon, $day, $hour, $min, $sec) = extractime($origin);
    my ($wday, $yday, $isdast);
    # 函数的月份范围为0-11
    $mon -= 1;
    # 计算该时刻与1970年1月1日午夜的秒数差
    my $time = timegm($sec, $min, $hour, $day, $mon, $year);
    # 将该秒数加上一个时间差
    $time += $timespan;
    my ($out) = gettime($time);
    return ($out);
}
sub gettime {
    my @in = @_;
    my @out;
    foreach my $time (@in) {
        my ($sec, $min, $hour, $day, $mon, $year, $wday, $yday, $isdast) = gmtime($time);
        # 对年份和月份特殊处理
        $year += 1900;
        $mon += 1;
        # 返回
        ($mon, $day, $hour, $min, $sec) = add_zero($mon, $day, $hour, $min, $sec);
        push @out, "${year}-${mon}-${day}T${hour}:${min}:${sec}";
    }
    return (@out);
}
sub gettimegm {
    my @in = @_;
    my @out;
    foreach my $origin (@in) {
        my ($year, $mon, $day, $hour, $min, $sec) = extractime($origin);
        # 函数的月份范围为0-11
        $mon -= 1;
        # 计算该时刻与1970年1月1日午夜的秒数差
        my $time = timegm($sec, $min, $hour, $day, $mon, $year);
        push @out, $time;
    }
    return (@out);
}
sub add_zero {
    my @in = @_;
    my @out;
    foreach (@in) {
        if (length($_) < 2) {
            push @out, "0$_";
        }else{
            push @out, "$_";
        }
    }
    return @out;
}
sub trim { my $s = shift; $s =~ s/^\s+|\s+$//g; return $s };
