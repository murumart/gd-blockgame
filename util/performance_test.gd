class_name Debug_PerformanceTest extends RefCounted


# Debug_PerformanceTest::_debruijin_vs_other : time1: 20233
# Debug_PerformanceTest::_debruijin_vs_other : time2: 25066
static func debruijin_vs_other() -> void:
	var nums: PackedInt64Array = [
		0b0,
		0b1,
		0b10,
		0b100,
		0b1000,
		0b10000,
		0b100000,
		0b1000000,
		0b10000000,
	]
	var results1 := []
	var results2 := []
	var test: PackedInt64Array
	for i in 1000:
		test.append_array(nums)
	var time1 := Time.get_ticks_msec()
	for i in 10000:
		for x in test:
			var tz := ChunkRenderer.ntz(x)
	time1 = Time.get_ticks_msec() - time1
	var time2 := Time.get_ticks_msec()
	for i in 10000:
		for x in test:
			var tz := _other_ntz(x)
	time2 = Time.get_ticks_msec() - time2

	print("Debug_PerformanceTest::_debruijin_vs_other : time1: ", time1)
	print("Debug_PerformanceTest::_debruijin_vs_other : time2: ", time2)

	for i in results1.size():
		assert(results1[i] == results2[i], "Mismatched result at index " + str(i))


static func _other_ntz(n: int) -> int:
	var bits := 0
	var x := n

	if x:
		if !(x & 0x0000ffff):
			bits += 16
			x >>= 16
		if !(x & 0x000000ff):
			bits += 8
			x >>= 8
		if !(x & 0x0000000f):
			bits += 4
			x >>= 4
		if !(x & 0x0000003):
			bits += 2
			x >>= 2
		bits += (x & 1) ^ 1


	return bits
