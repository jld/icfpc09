#!/usr/bin/env zsh
set -e

make -f Makefile.tmpl Makefile
make sim icomp
team=39
scen=$1

./icomp <<EOF | ./sim specs/bin1.obf | tee test.out | while read t a v
h $team $scen
f 0 1
 16000 $scen
f 1 0
EOF
do
    case $t.$a in
	0.2) x0=$[- $v] ;;
	0.3) y0=$[- $v] ;;
	0.4) r2=$v ;;
	1.2) x1=$[- $v] ;;
	1.3) y1=$[- $v] ;;
    esac
done
: ${x1=$x0} ${y1=$y0}
float x0 y0 x1 y1 r2

r1=$[(($x0 * $x0) + ($y0 * $y0)) ** .5]
v1=$[(($x1 - $x0) ** 2 + ($y1 - $y0) ** 2) ** .5]
nx=$[($x1 - $x0) / $v1]
ny=$[($y1 - $y0) / $v1]
pi=3.1415926535897931
mu=4004568.0e8
dv1=$[($mu / $r1) ** .5 * ((2 * $r2 / ($r1 + $r2)) ** .5 - 1)]
dv2=$[($mu / $r2) ** .5 * (1 - (2 * $r1 / ($r1 + $r2)) ** .5)]
th=$[$pi * (($r1 + $r2) ** 3 / (8 * $mu)) ** .5]

fudge=1.00001
bx1=$[$dv1 * $nx * $fudge]
by1=$[$dv1 * $ny * $fudge]
bx2=$[$dv2 * - $nx * $fudge]
by2=$[$dv2 * - $ny * $fudge]

integer thi
thi=$[$th + .5]

./icomp <<EOF | tee $scen.osf | ./sim specs/bin1.obf | grep ' 0 '
h $team $scen
f 0 3
 16000 $scen
 2 $bx1
 3 $by1
f 1 2
 2 0
 3 0
f $thi 2
 2 $bx2
 3 $by2
f $[$thi + 1] 2
 2 0
 3 0
f $[$thi + 2000] 0
EOF
