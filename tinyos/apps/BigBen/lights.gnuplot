set terminal postscript enhanced eps solid color font "Helvetica,14" size 6in,20in

set style line 4 lt 1  ps 0.2 pt 7 lw 3 lc rgb "#d7191c"
set style line 2 lt 1  ps 1.2 pt 2 lw 5 lc rgb "#fdae61"
set style line 3 lt 9  ps 1.2 pt 3 lw 5 lc rgb "#abdda4"
set style line 1 lt 1  ps 0.2 pt 7 lw 3 lc rgb "#2b83ba"
set style line 5 lt 17 ps 1.2 pt 7 lw 5 lc rgb "#FF1493"

set border 1

set xdata time
set xtics 3600 format " " nomirror
unset mxtics
unset xlabel
#set format x "%H:%M"


unset ylabel
unset ytics
set yrange [-0.2:1.2]

set tmargin 0
set bmargin 0
set lmargin 10


unset grid

unset key

set timefmt "%Y-%m-%d-%H:%M:%S"

set output "lights.eps"

set multiplot

