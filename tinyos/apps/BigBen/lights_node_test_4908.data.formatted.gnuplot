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

set size   1, 0.02725
set origin 0, 0.97275

set ylabel "2014-05-20" offset -3 rotate by 0

set xrange ["2014-05-20-00:00:00":"2014-05-20-23:59:59"]

plot "node_test_4908.data.formatted" u 1:2 w lines ls 1

set size   1, 0.02725
set origin 0, 0.9455

set ylabel "2014-05-21" offset -3 rotate by 0

set xrange ["2014-05-21-00:00:00":"2014-05-21-23:59:59"]

plot "node_test_4908.data.formatted" u 1:2 w lines ls 1

set size   1, 0.02725
set origin 0, 0.91825

set ylabel "2014-05-22" offset -3 rotate by 0

set xrange ["2014-05-22-00:00:00":"2014-05-22-23:59:59"]

plot "node_test_4908.data.formatted" u 1:2 w lines ls 1

set size   1, 0.02725
set origin 0, 0.891

set ylabel "2014-05-23" offset -3 rotate by 0

set xrange ["2014-05-23-00:00:00":"2014-05-23-23:59:59"]

plot "node_test_4908.data.formatted" u 1:2 w lines ls 1

set size   1, 0.02725
set origin 0, 0.86375

set ylabel "2014-05-24" offset -3 rotate by 0

set xrange ["2014-05-24-00:00:00":"2014-05-24-23:59:59"]

plot "node_test_4908.data.formatted" u 1:2 w lines ls 1

set size   1, 0.02725
set origin 0, 0.8365

set ylabel "2014-05-25" offset -3 rotate by 0

set xrange ["2014-05-25-00:00:00":"2014-05-25-23:59:59"]

plot "node_test_4908.data.formatted" u 1:2 w lines ls 1

set size   1, 0.02725
set origin 0, 0.80925

set ylabel "2014-05-26" offset -3 rotate by 0

set xrange ["2014-05-26-00:00:00":"2014-05-26-23:59:59"]

plot "node_test_4908.data.formatted" u 1:2 w lines ls 1

set size   1, 0.02725
set origin 0, 0.782

set ylabel "2014-05-27" offset -3 rotate by 0

set xrange ["2014-05-27-00:00:00":"2014-05-27-23:59:59"]

plot "node_test_4908.data.formatted" u 1:2 w lines ls 1

set size   1, 0.02725
set origin 0, 0.75475

set ylabel "2014-05-28" offset -3 rotate by 0

set xrange ["2014-05-28-00:00:00":"2014-05-28-23:59:59"]

plot "node_test_4908.data.formatted" u 1:2 w lines ls 1

set size   1, 0.02725
set origin 0, 0.7274999999999999

set ylabel "2014-05-29" offset -3 rotate by 0

set xrange ["2014-05-29-00:00:00":"2014-05-29-23:59:59"]

plot "node_test_4908.data.formatted" u 1:2 w lines ls 1

set size   1, 0.02725
set origin 0, 0.7002499999999999

set ylabel "2014-05-30" offset -3 rotate by 0

set xrange ["2014-05-30-00:00:00":"2014-05-30-23:59:59"]

plot "node_test_4908.data.formatted" u 1:2 w lines ls 1

set size   1, 0.02725
set origin 0, 0.6729999999999999

set ylabel "2014-05-31" offset -3 rotate by 0

set xrange ["2014-05-31-00:00:00":"2014-05-31-23:59:59"]

plot "node_test_4908.data.formatted" u 1:2 w lines ls 1

set size   1, 0.02725
set origin 0, 0.6457499999999999

set ylabel "2014-06-01" offset -3 rotate by 0

set xrange ["2014-06-01-00:00:00":"2014-06-01-23:59:59"]

plot "node_test_4908.data.formatted" u 1:2 w lines ls 1

set size   1, 0.02725
set origin 0, 0.6184999999999999

set ylabel "2014-06-02" offset -3 rotate by 0

set xrange ["2014-06-02-00:00:00":"2014-06-02-23:59:59"]

plot "node_test_4908.data.formatted" u 1:2 w lines ls 1

set size   1, 0.02725
set origin 0, 0.5912499999999999

set ylabel "2014-06-03" offset -3 rotate by 0

set xrange ["2014-06-03-00:00:00":"2014-06-03-23:59:59"]

plot "node_test_4908.data.formatted" u 1:2 w lines ls 1

set size   1, 0.02725
set origin 0, 0.564

set ylabel "2014-06-04" offset -3 rotate by 0

set xrange ["2014-06-04-00:00:00":"2014-06-04-23:59:59"]

plot "node_test_4908.data.formatted" u 1:2 w lines ls 1

set size   1, 0.02725
set origin 0, 0.53675

set ylabel "2014-06-05" offset -3 rotate by 0

set xrange ["2014-06-05-00:00:00":"2014-06-05-23:59:59"]

plot "node_test_4908.data.formatted" u 1:2 w lines ls 1

set size   1, 0.02725
set origin 0, 0.5095

set ylabel "2014-06-06" offset -3 rotate by 0

set xrange ["2014-06-06-00:00:00":"2014-06-06-23:59:59"]

plot "node_test_4908.data.formatted" u 1:2 w lines ls 1

set size   1, 0.02725
set origin 0, 0.48224999999999996

set ylabel "2014-06-07" offset -3 rotate by 0

set xrange ["2014-06-07-00:00:00":"2014-06-07-23:59:59"]

plot "node_test_4908.data.formatted" u 1:2 w lines ls 1

set size   1, 0.02725
set origin 0, 0.45499999999999996

set ylabel "2014-06-08" offset -3 rotate by 0

set xrange ["2014-06-08-00:00:00":"2014-06-08-23:59:59"]

plot "node_test_4908.data.formatted" u 1:2 w lines ls 1

set size   1, 0.02725
set origin 0, 0.42774999999999996

set ylabel "2014-06-09" offset -3 rotate by 0

set xrange ["2014-06-09-00:00:00":"2014-06-09-23:59:59"]

plot "node_test_4908.data.formatted" u 1:2 w lines ls 1

set size   1, 0.02725
set origin 0, 0.40049999999999997

set ylabel "2014-06-10" offset -3 rotate by 0

set xrange ["2014-06-10-00:00:00":"2014-06-10-23:59:59"]

plot "node_test_4908.data.formatted" u 1:2 w lines ls 1

set size   1, 0.02725
set origin 0, 0.37324999999999997

set ylabel "2014-06-11" offset -3 rotate by 0

set xrange ["2014-06-11-00:00:00":"2014-06-11-23:59:59"]

plot "node_test_4908.data.formatted" u 1:2 w lines ls 1

set size   1, 0.02725
set origin 0, 0.346

set ylabel "2014-06-12" offset -3 rotate by 0

set xrange ["2014-06-12-00:00:00":"2014-06-12-23:59:59"]

plot "node_test_4908.data.formatted" u 1:2 w lines ls 1

set size   1, 0.02725
set origin 0, 0.31875

set ylabel "2014-06-13" offset -3 rotate by 0

set xrange ["2014-06-13-00:00:00":"2014-06-13-23:59:59"]

plot "node_test_4908.data.formatted" u 1:2 w lines ls 1

set size   1, 0.02725
set origin 0, 0.2915

set ylabel "2014-06-14" offset -3 rotate by 0

set xrange ["2014-06-14-00:00:00":"2014-06-14-23:59:59"]

plot "node_test_4908.data.formatted" u 1:2 w lines ls 1

set size   1, 0.02725
set origin 0, 0.26425

set ylabel "2014-06-15" offset -3 rotate by 0

set xrange ["2014-06-15-00:00:00":"2014-06-15-23:59:59"]

plot "node_test_4908.data.formatted" u 1:2 w lines ls 1

set size   1, 0.02725
set origin 0, 0.23699999999999996

set ylabel "2014-06-16" offset -3 rotate by 0

set xrange ["2014-06-16-00:00:00":"2014-06-16-23:59:59"]

plot "node_test_4908.data.formatted" u 1:2 w lines ls 1

set size   1, 0.02725
set origin 0, 0.20974999999999996

set ylabel "2014-06-17" offset -3 rotate by 0

set xrange ["2014-06-17-00:00:00":"2014-06-17-23:59:59"]

plot "node_test_4908.data.formatted" u 1:2 w lines ls 1

set size   1, 0.02725
set origin 0, 0.18249999999999997

set ylabel "2014-06-18" offset -3 rotate by 0

set xrange ["2014-06-18-00:00:00":"2014-06-18-23:59:59"]

plot "node_test_4908.data.formatted" u 1:2 w lines ls 1

set size   1, 0.02725
set origin 0, 0.15524999999999997

set ylabel "2014-06-19" offset -3 rotate by 0

set xrange ["2014-06-19-00:00:00":"2014-06-19-23:59:59"]

plot "node_test_4908.data.formatted" u 1:2 w lines ls 1

set size   1, 0.02725
set origin 0, 0.12799999999999997

set ylabel "2014-06-20" offset -3 rotate by 0

set xrange ["2014-06-20-00:00:00":"2014-06-20-23:59:59"]

plot "node_test_4908.data.formatted" u 1:2 w lines ls 1

set size   1, 0.02725
set origin 0, 0.10074999999999999

set ylabel "2014-06-21" offset -3 rotate by 0

set xrange ["2014-06-21-00:00:00":"2014-06-21-23:59:59"]

plot "node_test_4908.data.formatted" u 1:2 w lines ls 1

set size   1, 0.02725
set origin 0, 0.0735

set ylabel "2014-06-22" offset -3 rotate by 0

set xrange ["2014-06-22-00:00:00":"2014-06-22-23:59:59"]

plot "node_test_4908.data.formatted" u 1:2 w lines ls 1

set size   1, 0.02725
set origin 0, 0.04625

set ylabel "2014-06-23" offset -3 rotate by 0

set xrange ["2014-06-23-00:00:00":"2014-06-23-23:59:59"]

plot "node_test_4908.data.formatted" u 1:2 w lines ls 1

set size   1, 0.04625
set origin 0, 0

set xtics 3600
set format x "%H"
set xlabel "Hour of Day"

set bmargin 4

set ylabel "2014-06-24" offset -3 rotate by 0

set xrange ["2014-06-24-00:00:00":"2014-06-24-23:59:59"]

plot "node_test_4908.data.formatted" u 1:2 w lines ls 1

