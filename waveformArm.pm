#!/usr/bin/env perl
use strict;
use warnings;

sub waveformArm () {
    my ($dom, $events, $stations) = @_;
    foreach my $eve (@{$events}) {
        # 20190418050106 2019-04-18T05:01:06.418  121.6934  23.9888   20   6.1 Mww
        my ($id, $origin, $evlo, $evla, $evdp, $mag, $magtype) = split m/\s+/, $eve;
        print "$id\n";
        my $dir = &time2dir($origin);
        mkdir $dir;
        chdir $dir or die;
        open (OUT, "> fetchdata.sh") or die;
        print OUT "# $eve\n";
        foreach my $st (@{$stations}) {
            next if ($st =~ "#");
            # 1F|N103|24.55238|121.47229|407.0|N. Central Range - N103|2008-02-19T00:00:00|2008-03-21T23:59:59
            my ($net, $sta, $stla, $stlo, $stel, undef, $start, $end) = split m/\|/, $st;

            # 检查震中距
            my ($distmin, $distmax) = minmax_waveform($dom, 'waveformArm/distanceRange');
            my ($dist) = split m/\s+/, `distaz $evla $evlo $stla $stlo`;
            unless (($dist <= $distmax) and ($dist >= $distmin)) {
                print OUT "# ${net}_${sta} $dist DISTRANGE: $distmin $distmax\n";
                next;
            }

            # 检查运行时间
            my ($start_gm, $end_gm, $origin_gm) = gettimegm($start, $end, $origin);
            unless ($origin_gm <= $end_gm) {
                print OUT "# ${net}_${sta} origin $origin RUNTIMERANGE $start $end\n";
                next;
            }
            my ($b) = phasetime_begin($origin, $dist, $evdp, $stel, $dom);# 获取phase时间范围
            my ($b_gm) = gettimegm($b);
            unless (($b_gm <= $end_gm) and ($b_gm >= $start_gm)) {
                print OUT "# ${net}_${sta} start $b RUNTIMERANGE $start $end\n";
                next;
            }
            my ($e) = phasetime_end($origin, $dist, $evdp, $stel, $dom);
            my ($e_gm) = gettimegm($e);
            unless (($e_gm <= $end_gm) and ($e_gm >= $start_gm)) {
                print OUT "# ${net}_${sta} end $e RUNTIMERANGE $start $end\n";
                next;
            }

            # 获取通道名
            my ($cha) = &explain($dom, "networkArm/fdsnStation/channelCode");

            my $fetch = "FetchData -F -N $net -S $sta -C $cha -s $b -e $e -o ${net}_${sta}.mseed -m ${net}_${sta}.meta -rd .";
            print OUT "$fetch\n";
            system $fetch;
        }
        close(OUT);
        chdir ".." or die;
    }
}
sub time2dir () {
    my ($origin) = @_;
    my ($year, $mon, $day, $hour, $min, $sec) = &extractime($origin);
    $sec = int $sec;
    return ("${year}${mon}${day}${hour}${min}${sec}");
}
sub phasetime_begin () {
    my ($origin, $gcarc, $evdp, $stel, $dom) = @_;
    my $model = &explain($dom, "waveformArm/phaseRequest/model");
    my $beginPhase = &explain($dom, "waveformArm/phaseRequest/beginPhase");
    my $beginOffset = &explain($dom, "waveformArm/phaseRequest/beginOffset/value");
    my @time = split m/\s+/, `taup_time -mod $model -ph $beginPhase -h $evdp -deg $gcarc --time`;
    my $b = min @time;
    ($b) = time_add ($origin, $b);
    return ($b);
}
sub phasetime_end () {
    my ($origin, $gcarc, $evdp, $stel, $dom) = @_;
    my $model = &explain($dom, "waveformArm/phaseRequest/model");
    my $endPhase = &explain($dom, "waveformArm/phaseRequest/endPhase");
    my $endOffset = &explain($dom, "waveformArm/phaseRequest/endOffset/value");
    my @time = split m/\s+/, `taup_time -mod $model -ph $endPhase -h $evdp -deg $gcarc --time`;
    my $e = min @time;
    ($e) = time_add ($origin, $e);
    return ($e);
}
sub extractime () {
    my ($origin) = @_;
    my ($date, $time) = split "T", $origin;
    my ($year, $mon, $day) = split "-", $date;
    my ($hour, $min, $sec) = split ":", $time;
    return ($year, $mon, $day, $hour, $min, $sec);
}
sub time_add(){
    my ($origin, $timespan) = @_;
    my ($year, $mon, $day, $hour, $min, $sec) = &extractime($origin);
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
    return ("${year}-${mon}-${day}T${hour}:${min}:${sec}");
}
sub gettimegm () {
    my @in = @_;
    my @out;
    foreach my $origin (@in) {
        my ($year, $mon, $day, $hour, $min, $sec) = &extractime($origin);
        # 函数的月份范围为0-11
        $mon -= 1;
        # 计算该时刻与1970年1月1日午夜的秒数差
        my $time = timegm($sec, $min, $hour, $day, $mon, $year);
        push @out, $time;
    }
    return (@out);
}
sub minmax_waveform () {
    my ($dom, $in) = @_;
    my $min = &explain($dom, "$in/min");
    my $max = &explain($dom, "$in/max");
    $min = 0 if ($min eq " ");
    $max = 180 if ($max eq " ");
    return ($min, $max);
}
1;