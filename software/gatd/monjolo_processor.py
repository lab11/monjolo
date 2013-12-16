
import MonjoloData

####
# The thread that does all of the real work.
####
def processor ():
	global md
	md.register_ids(['c0:98:e5:43:4f:f3:36:09'])
	while True:
		d = md.next_data()
		if not d:
			continue

		print(d)


md = MonjoloData.MonjoloData()
md.start(processor)
