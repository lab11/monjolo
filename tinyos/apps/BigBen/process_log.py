import datetime
import dateutil.tz
import sys

from_zone = dateutil.tz.tzutc()
to_zone = dateutil.tz.tzlocal()


if len(sys.argv) < 2:
	print('usage: {} <data filename>'.format(sys.argv[0]))
	sys.exit(1)


filename = sys.argv[1]

events = []

with open(filename) as f:
	for l in f:

		try:
			utc = datetime.datetime.strptime(l[0:19], '%Y-%m-%d %H:%M:%S')
		except:
			continue

		# Tell the datetime object that it's in UTC time zone since
		# datetime objects are 'naive' by default
		utc = utc.replace(tzinfo=from_zone)

		# Convert time zone
		event_time = utc.astimezone(to_zone)

		wakes = int(l.split(':')[-1].strip())


		events.append((event_time, wakes))



start_time = events[0][0].replace(hour=0, minute=0, second=0, microsecond=0)
end_time = events[-1][0].replace(hour=0, minute=0, second=0, microsecond=0)

num_days = (end_time-start_time).days + 1

days = []
for i in range(num_days):
	days.append([])

# initial condition
days[0].append((start_time, 0))

for event in events:

	day_index = (event[0].replace(hour=0, minute=0, second=0, microsecond=0) - start_time).days

	if event[1] > 10:
		days[day_index].append((event[0], 1))
	else:
		days[day_index].append((event[0], 0))

for i,d in zip(range(len(days)), days):
	last = d[-1][0].replace(hour=23, minute=59, second=59)
	d.append((last, d[-1][1]))

	beginning = last.replace(hour=0, minute=0, second=0) + datetime.timedelta(days=1)
	if i+1 < len(days):
		days[i+1].insert(0, (beginning, d[-1][1]))

corrected_days = []

# add dummy points so a plot line would look correct (steps instead of ramps)
for d in days:
	corrected_days.append([])
	last = -1
	for i,e in zip(range(len(d)), d):
		print(e)
		if last > -1:
			if last != e[1]:
				corrected_days[-1].append((e[0], last))
		corrected_days[-1].append(e)
		last = e[1]




with open(filename + '.formatted', 'w') as f:
	for d in corrected_days:
		for e in d:
			t = e[0].astimezone(to_zone)
			f.write('{:04}-{:02}-{:02}-{:02}:{:02}:{:02} {}\n'.format(t.year, t.month,
				t.day, t.hour, t.minute, t.second, e[1]))
