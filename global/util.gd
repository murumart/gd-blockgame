class_name Util extends RefCounted


static func measure_time(callable: Callable):
	var time := Time.get_ticks_msec()
	var r = callable.call()
	print(Time.get_ticks_msec() - time)
	return r
