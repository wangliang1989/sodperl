#!/usr/bin/env perl
use strict;
use warnings;

sub waveformArm {
    my ($dom, $events, $stations) = @_;
    foreach my $eve (@{$events}) {
        # 20190418050106 2019-04-18T05:01:06.418  121.6934  23.9888   20   6.1 Mww
        my ($id, $origin, $evlo, $evla, $evdp, $mag, $magtype) = split m/\s+/, $eve;
        print "$id\n";
        my $dir = time2dir($origin);
        mkdir $dir;
        chdir $dir or die;
        open (OUT, "> fetchdata.sh") or die;
        print OUT "# $eve\n";
        foreach my $st (@{$stations}) {
            next if ($st =~ "#");
            # 1F|N103|24.55238|121.47229|407.0|N. Central Range - N103|2008-02-19T00:00:00|2008-03-21T23:59:59
            my ($net, $sta, $stla, $stlo, $stel, undef, $start, $end) = split m/\|/, $st;

            # 检查震中距
            my $dist = 0;
            my ($distmin, $distmax) = minmax_waveform($dom, 'waveformArm/distanceRange');
            unless (($distmin == 0) and ($distmax == 180)) {
                ($dist) = split m/\s+/, `distaz $evla $evlo $stla $stlo`;
                unless (($dist <= $distmax) and ($dist >= $distmin)) {
                    print OUT "# ${net}_${sta} $dist DISTRANGE: $distmin $distmax\n";
                    next;
                }
            }

            # 检查运行时间
            my ($start_gm, $end_gm, $origin_gm) = gettimegm($start, $end, $origin);
            unless ($origin_gm <= $end_gm) {# 发震时刻应该早于运行结束时刻
                print OUT "# ${net}_${sta} origin $origin RUNTIMERANGE $start $end\n";
                next;
            }
            my $b = wavetime($origin, $dist, $evdp, $stel, $dom, 'begin');# 获取波形开始时刻
            my ($b_gm) = gettimegm($b);
            unless (($b_gm <= $end_gm) and ($b_gm >= $start_gm)) {
                print OUT "# ${net}_${sta} start $b RUNTIMERANGE $start $end\n";
                next;
            }
            my $e = wavetime($origin, $dist, $evdp, $stel, $dom, 'end');# 获取波形结束时刻
            my ($e_gm) = gettimegm($e);
            unless (($e_gm <= $end_gm) and ($e_gm >= $start_gm)) {
                print OUT "# ${net}_${sta} end $e RUNTIMERANGE $start $end\n";
                next;
            }

            # 获取通道名
            my $cha = explain($dom, "networkArm/fdsnStation/channelCode");

            my $fetch = "FetchData -F -N $net -S $sta -C $cha -s $b -e $e -o ${net}_${sta}.mseed -m ${net}_${sta}.meta -rd .";
            print OUT "$fetch\n";
            system $fetch;
        }
        close(OUT);
        chdir ".." or die;
    }
}
sub wavetime {
    my ($origin, $gcarc, $evdp, $stel, $dom, $flag) = @_;
    my $moment;
    my $phaseRequest = explain ($dom, "waveformArm/phaseRequest");
    unless ($phaseRequest eq " ") {
        $moment = phasetime($origin, $gcarc, $evdp, $stel, $dom, $flag);
    }else{
        $moment = origintime($origin, $dom, $flag);
    }
    return ($moment);
}
sub origintime {
    my ($origin, $dom, $flag) = @_;
    my $Offset = explain($dom, "waveformArm/originOffsetRequest/${flag}Offset/value");
    my ($moment) = time_add ($origin, $Offset);
    return ($moment);
}
sub phasetime {
    my ($origin, $gcarc, $evdp, $stel, $dom, $flag) = @_;
    my $model = explain($dom, "waveformArm/phaseRequest/model");
    my $Phase = explain($dom, "waveformArm/phaseRequest/${flag}Phase");
    my $Offset = explain($dom, "waveformArm/phaseRequest/${flag}Offset/value");
    my @time = split m/\s+/, `taup_time -mod $model -ph $Phase -h $evdp -deg $gcarc --time`;
    my $moment = min @time;
    $moment = $moment + $Offset;
    $moment = time_add ($origin, $moment);
    return ($moment);
}
sub minmax_waveform {
    my ($dom, $in) = @_;
    my $min = explain($dom, "$in/min");
    my $max = explain($dom, "$in/max");
    $min = 0 if ($min eq " ");
    $max = 180 if ($max eq " ");
    return ($min, $max);
}
1;