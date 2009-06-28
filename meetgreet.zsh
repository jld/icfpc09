#!/usr/bin/env zsh
set -e

#make sim icomp
team=39
scen=$1

./icomp <<EOF | ./sim specs/bin2.obf | tee test.out | while read t a v
h $team $scen
f 0 1
 16000 $scen
f 1 0
EOF
do
    case $t.$a in
	0.2) x0=$v ;;
	0.3) y0=$v ;;
	0.4) tx0=$v ;;
	0.5) ty0=$v ;;
	1.2) x1=$v ;;
	1.3) y1=$v ;;
	1.4) tx1=$v ;;
	1.5) ty1=$v ;;
    esac
done
: ${x1=$x0} ${y1=$y0} ${tx1=$tx0} ${ty1=$ty0}
float x0 y0 x1 y1 tx0 ty0 tx1 ty1

x0=$[- $x0] y0=$[- $y0] x1=$[- $x1] y1=$[- $y1] 
tx0=$[$x0+$tx0] ty0=$[$y0+$ty0] tx1=$[$x1+$tx1] ty1=$[$y1+$ty1] 

r1=$[(($x0 * $x0) + ($y0 * $y0)) ** .5]
r2=$[(($tx0 * $tx0) + ($ty0 * $ty0)) ** .5]
v1=$[(($x1 - $x0) ** 2 + ($y1 - $y0) ** 2) ** .5]
v2=$[(($tx1 - $tx0) ** 2 + ($ty1 - $ty0) ** 2) ** .5]
nx1=$[$x0 / $r1]
ny1=$[$y0 / $r1]
nx2=$[$tx0 / $r2]
ny2=$[$ty0 / $r2]

pi=3.1415926535897931
mu=4004568.0e8
dv1=$[($mu / $r1) ** .5 * ((2 * $r2 / ($r1 + $r2)) ** .5 - 1)]
dv2=$[($mu / $r2) ** .5 * (1 - (2 * $r1 / ($r1 + $r2)) ** .5)]
th=$[$pi * (($r1 + $r2) ** 3 / (8 * $mu)) ** .5]

zmodload zsh/mathfunc
a1=$[atan($y0, $x0)]
a2=$[atan($ty0, $tx0)]
av1=$[($x1 - $x0) * - $ny1 + ($y1 - $y0) * $nx1]
av2=$[($tx1 - $tx0) * - $ny2 + ($ty1 - $ty0) * $nx2]
da1=$[$av1 / $r1]
da2=$[$av2 / $r2]
# a2 + da2 * (tbeg + th) ~= a1 + da1 * tbeg + pi
tbeg=$[($pi + $a1 - $a2 - $da2 * $th) / ($da2 - $da1)]
cyc=$[2 * $pi / abs($da2 - $da1)]

while [[ $tbeg < 0 ]]
do echo "$tbeg < 0"
   tbeg=$[$tbeg + $cyc]
done

aburn=$[$a1 + $da1 * $tbeg]
if [[ $da1 < 0 ]]; then
    abx=$[sin($aburn)]
    aby=$[- cos($aburn)]
else
    abx=$[- sin($aburn)]
    aby=$[cos($aburn)]
fi

fudge=0.9999
bx1=$[$dv1 * $abx * $fudge]
by1=$[$dv1 * $aby * $fudge]
bx2=$[$dv2 * - $abx * $fudge]
by2=$[$dv2 * - $aby * $fudge]

tfudge=1
echo $tbeg $th
integer tbi tei
tbi=$[$tfudge * $tbeg + .5]
tei=$[$tfudge * $tbeg + $th + .5]

./icomp <<EOF | tee $scen.osf | ./sim specs/bin2.obf | grep ' 0 '
h $team $scen
f 0 1
 16000 $scen
f $tbi 2
 2 $bx1
 3 $by1
f $[tbi + 1] 2
 2 0
 3 0
f $tei 2
 2 $bx2
 3 $by2
f $[$tei + 1] 2
 2 0
 3 0
f $[$tei + 2000] 0
EOF
