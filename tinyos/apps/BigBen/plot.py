import sys

with open('lights.gnuplot') as f:
	main_gnuplot = f.read()

with open('lights_multiplot.gnuplot') as f:
	subplot = f.read()

with open('lights_multiplot_last.gnuplot') as f:
	subplot_last = f.read()

last_date = ''
plots = []
with open(sys.argv[1]) as f:
	for l in f:
		if l[0:10] != last_date:
			plots.append(l[0:10])
		last_date = l[0:10]

num = len(plots)

extra_space = 0.019
height = 1.0 - extra_space
subplot_height = height/num

for i,plot in zip(range(len(plots)), plots):

	size_x = 1
	size_y = height/num
	origin_x = 0
	origin_y = (height - (subplot_height*(i+1))) + extra_space
	x_start = plot + '-00:00:00'
	x_end   = plot + '-23:59:59'
	y_label = plot
	filename = sys.argv[1]

	if i+1 == len(plots):
		text = subplot_last
		origin_y = 0
		size_y += extra_space
	else:
		text = subplot

	splot = text.replace('@SIZE_X@', str(size_x))
	splot = splot.replace('@SIZE_Y@', str(size_y))
	splot = splot.replace('@ORIGIN_X@', str(origin_x))
	splot = splot.replace('@ORIGIN_Y@', str(origin_y))
	splot = splot.replace('@X_START@', str(x_start))
	splot = splot.replace('@X_END@', str(x_end))
	splot = splot.replace('@FILENAME@', str(filename))
	splot = splot.replace('@Y_LABEL@', str(y_label))

	main_gnuplot += splot


with open('lights_' + sys.argv[1] + '.gnuplot', 'w') as f:
	f.write(main_gnuplot)

