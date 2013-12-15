
import MonjoloData

####
# The thread that does all of the real work.
####
def processor ():
	global md
	md.register_ids(['00:12:6d:43:4f:e1:b2:64', '00:12:6d:43:4f:e1:b5:ba'])
	while True:
		d = md.next_data()
		if not d:
			continue

		print(d)


md = MonjoloData.MonjoloData()
md.start(processor)
