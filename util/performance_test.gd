class_name Debug_PerformanceTest extends Node


func _ready() -> void:
	decodes()


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


static func decodes() -> void:
	var pba := PackedByteArray()
	pba.resize(8)
	const RANGEM := 1.0
	var pos1 := Vector3(0, 0, 1)
	var f1 := (
		int((pos1.x + 1.0) * RANGEM)
		| (int((pos1.y + 1.0) * RANGEM) << 8)
		| (int((pos1.z + 1.0) * RANGEM) << 16)
		| (0 << 24)
		| (1 << 26)
		| (1 << 32)
		| (1 << 62) # hack to get the shader to recognise values in front of this
	)
	pba.encode_u64(0, f1)
	print("\tX1000000000000000000txtxtxtxtxtx000nnnUVzzzzzzzzyyyyyyyyxxxxxxxx")
	print("\t%s x:%s y:%s z:%s uv:%s n:%s tx:%s; pos1:%s" % [String.num_uint64(f1, 2).pad_zeros(64), pba.decode_u8(0), pba.decode_u8(1), pba.decode_u8(2), pba.decode_u8(3) & 0b11, (pba.decode_u8(3) & 0b11100) >> 2, pba.decode_u16(4) & 0b111111111111, pos1])
	print("\t%s" % String.num_uint64(f1, 2).pad_zeros(64))
