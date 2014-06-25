set size   @SIZE_X@, @SIZE_Y@
set origin @ORIGIN_X@, @ORIGIN_Y@

set xtics 3600
set format x "%H"
set xlabel "Hour of Day"

set bmargin 4

set ylabel "@Y_LABEL@" offset -3 rotate by 0

set xrange ["@X_START@":"@X_END@"]

plot "@FILENAME@" u 1:2 w lines ls 1

