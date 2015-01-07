# wxt
# set terminal wxt size 410,250 enhanced font 'Verdana,9' persist
# png
set terminal pngcairo size 600,370 enhanced font 'Verdana,9'
set output 'OUTPUTFILE.png'
# svg
#set terminal svg size 410,250 fname 'Verdana, Helvetica, Arial, sans-serif' \
#fsize '9' rounded dashed
#set output 'nice_web_plot.svg'

# define the border on the left and bottom
set style line 11 lc rgb '#808080' lt 1
set border 3 back ls 11
set tics nomirror
# define the grid
set style line 12 lc rgb '#808080' lt 0 lw 1
set grid back ls 12

# color definitions
# set style line 1 lc rgb '#8b1a0e' pt 1 ps 1 linetype 1 linewidth 2 # --- red
set style line 1 linecolor rgb '#8b1a0e' linetype 1 linewidth 3 # --- red
set style line 2 linecolor rgb '#8b1a0e' linetype 1 linewidth 1 # --- red
# set style line 2 lc rgb '#5e9c36' pt 6 ps 1 linetype 1 linewidth 2 # --- green
set style line 3 linecolor rgb '#5e9c36' linetype 1 linewidth 3 # --- green
set style line 4 linecolor rgb '#5e9c36' linetype 1 linewidth 1 # --- green

# legend
set key top right

set xlabel 'function evaluations'
set ylabel 'y'
# set xrange [0:1]
# set yrange [0:1]

set logscale y

plot 'DATAFILE' using 1:2 title 'Data' w lines linestyle 1, \
     '' using 1:3 notitle w lines linestyle 2, \
     '' using 1:4 notitle w lines linestyle 2, \
     '' using 1:5 title 'CMA-ES' w lines linestyle 3, \
     '' using 1:6 notitle w lines linestyle 4, \
     '' using 1:7 notitle w lines linestyle 4
