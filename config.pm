#!/usr/bin/env perl
use strict;
use warnings;

sub eventarm () {
    my ($conf_file) = @_;
    my %pars;
    %pars = config_parser($conf_file, %pars);
    if (defined($pars{'fakeorigin'})) {
        &fakeevent("web.conf");
    }else{
        &realevent("web.conf");
    }
}
sub fakeevent () {
    my ($conf_file) = @_;
    my %pars;
    %pars = config_parser($conf_file, %pars);
    print "$pars{'fakeorigin'}\n";
    my ($year_start, $month_start, $day_start, $hour_start, $min_start, $sec_start, $unit, $seed, $lon, $lat, $dep) = split m/\s+/, $pars{'fakeorigin'};
    open (OUT, "> event.txt") or die;
    for (my $i = 1; $i <= $seed; $i++) {
        my $step = $unit * ($i - 1);
        my ($year, $mon, $day, $hour, $min, $sec) = &time_add ($year_start, $month_start, $day_start, $hour_start, $min_start, $sec_start, $step);
        my ($isec) = split m/\./, $sec;
        print OUT "$year$mon$day$hour$min$isec ${year}-${mon}-${day}T${hour}:${min}:${sec} $lon $lat $dep 5 MW\n";
    }
    close(OUT);
}
sub wavearm () {
    my ($conf_file) = @_;
    my %pars;
    %pars = config_parser($conf_file, %pars);
    if (defined($pars{'fakeorigin'})) {
        &fakeevent("web.conf");
    }else{
        &realevent("web.conf");
    }
}
sub realevent () {
    my ($conf_file) = @_;
    my %pars;
    %pars = config_parser($conf_file, %pars);
    die "undefined starttime" unless (defined($pars{'starttime'}));
    die "undefined endtime" unless (defined($pars{'endtime'}));
    if (defined($pars{'eventrangerad'})) {
        my ($lon, $lat, $minradius, $maxradius) = split m/\s+/, $pars{'eventrangerad'};
        $pars{'eventrange'} = "--radius $lat:$lon:$maxradius:$minradius";
    }
    if (defined($pars{'eventrangebox'})) {
        my ($min_lon, $max_lon, $min_lat, $max_lat) = split m/\s+/, $pars{'eventrangebox'};
        $pars{'eventrange'} = "--lon $min_lon:$max_lon --lat $min_lat:$max_lat";
    }
    die "undefined eventrange" unless (defined($pars{'eventrange'}));
    die "undefined mag" unless (defined($pars{'mag'}));
    my ($min_mag, $max_mag) = split m/\s+/, $pars{'mag'};
    my $cmd = "fetchevent -s $pars{'starttime'} -e $pars{'endtime'} $pars{'eventrange'} --mag $min_mag:$max_mag";
    if (defined($pars{'depth'})) {
        my ($min_depth, $max_depth) = split m/\s+/, $pars{'depth'};
        $cmd = "$cmd --depth $min_depth:$max_depth";
    }
    my @info = split m/\n/, `$cmd`;
    open (OUT, "> event.txt") or die;
    print OUT "# $cmd\n";
    foreach (@info) {
        #841715  |1999/09/22 00:49:44.020 | 23.696 | 121.099 |  40.3|ISC|ISC|ISC,1656276|Mw,5.8,HRVD|TAIWAN
        #20180815235908 2018-08-15T23:59:08.320 -116.7848330 33.4958330 5.06 0.61 Ml
        my ($origin, $evla, $evlo, $evdp) = (split m/\|/)[1..4];
        my ($maginfo) = (split m/\|/)[8];
        my ($magtype, $mag) = split ",", $maginfo;

        # 对发震时刻做解析
        my ($date, $time) = split m/\s+/, trim($origin);
        my ($year, $mon, $day) = split m/\//, $date;
        my ($hour, $min, $sec) = split m/:/, $time;
        my ($isec) = split m/\./, $sec;
        print OUT "$year$mon$day$hour$min$isec ${year}-${mon}-${day}T${hour}:${min}:${sec} $evlo $evla $evdp $mag $magtype\n";
    }
    close(OUT);
}
sub read_config() {
    my ($conf_file) = @_;

    my %pars;
    $conf_file = "$conf_file";
    %pars = config_parser($conf_file, %pars);

    return %pars;
}

sub setup_values() {
    my @out;
    foreach (@_) {
        if ($_ =~ m/\//g) {
            my ($start, $end, $delta) = split m/\//;
            for (my $value = $start; $value <= $end; $value = $value + $delta) {
                push @out, $value;
            }
        } else {
            push @out, $_;
        }
    }
    @out = sort { $a <=> $b } @out;

    return @out;
}

sub config_parser() {
    my ($config_file, %pars) = @_;
    open(IN," < $config_file") or die "can not open configure file $config_file\n";
    my @lines = <IN>;
    close(IN);

    foreach my $line (@lines) {
        $line = substr $line, 0, (pos $line) - 1 if ($line =~ m/#/g);
        chomp($line);
        if ($line =~ m/:/g) {
            my ($key, $value) = split ":", $line;
            next unless (defined($key) and defined($value));
            $key = trim($key);
            $value = trim($value);
            $pars{$key} = $value;
        }
    }
    return %pars;
}

sub time_add(){
    my ($year, $mon, $day, $hour, $min, $sec, $timespan) = @_;
    my ($wday, $yday, $isdast);
    # 函数的月份范围为0-11
    $mon -= 1;
    # 计算该时刻与1970年1月1日午夜的秒数差
    my $time = timegm($sec, $min, $hour, $day, $mon, $year);
    # 将该秒数加上一个时间差
    $time += $timespan;
    # 将时间差转换为具体的时刻
    ($sec, $min, $hour, $day, $mon, $year, $wday, $yday, $isdast) = gmtime($time);
    # 对年份和月份特殊处理
    $year += 1900;
    $mon += 1;
    # 返回
    return ($year, $mon, $day, $hour, $min, $sec);
}

sub trim { my $s = shift; $s =~ s/^\s+|\s+$//g; return $s };

1;
