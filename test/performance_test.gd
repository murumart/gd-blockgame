extends Node2D

const V000 := Vector3(0, 0, 0)
const V100 := Vector3(1, 0, 0)
const V110 := Vector3(1, 1, 0)
const V111 := Vector3(1, 1, 1)


func _ready() -> void:
	_perf_test()


func _perf_test() -> void:
	pass


## 1000*16*16*16 loops, no consts: 17336, with consts: 17370.
## this means that there's no difference whether you use constant vecs or not,
## probably because in the end you still have to use +, which creates new vectors.
func _vector3_speed_test() -> void:
	const LOOPS := 1000
	var arr1 := PackedVector3Array()
	var arr2 := PackedVector3Array()
	const BOX_SIZE := 16
	var time_1 := 0
	var time_2 := 0
	var time := 0

	time = Time.get_ticks_msec()
	for _l in LOOPS:
		for n in BOX_SIZE:
			for y in BOX_SIZE: for x in BOX_SIZE: for z in BOX_SIZE:
				var vec := Vector3(x, y, z)
				arr1.append_array([
					Vector3(0, 0, 0) + vec,
					Vector3(1, 0, 0) + vec,
					Vector3(1, 1, 0) + vec,
					Vector3(1, 1, 1) + vec,
				])
	time_1 = Time.get_ticks_msec() - time
	time = Time.get_ticks_msec()
	for _l in LOOPS:
		for n in BOX_SIZE:
			for y in BOX_SIZE: for x in BOX_SIZE: for z in BOX_SIZE:
				var vec := Vector3(x, y, z)
				arr1.append_array([
					V000 + vec,
					V100 + vec,
					V110 + vec,
					V111 + vec,
				])
	time_2 = Time.get_ticks_msec() - time
	print("no consts: ", time_1, ", with consts: ", time_2)


## apped_array in this case is about twice as slow as just appending one at a time.
## setting indices is faster than appending, but not by much.
func _appending_vs_array_vs_positions() -> void:
	const LOOPS := 100
	var arr1 := PackedVector3Array()
	var arr2 := PackedVector3Array()
	var arr3 := PackedVector3Array()
	const BOX_SIZE := 16
	var time_1 := 0
	var time_2 := 0
	var time_3 := 0
	var time := 0

	time = Time.get_ticks_msec()
	for _l in LOOPS:
		for n in BOX_SIZE:
			for y in BOX_SIZE: for x in BOX_SIZE: for z in BOX_SIZE:
				var vec := Vector3(x, y, z)
				arr1.append(Vector3(0, 0, 0) + vec)
				arr1.append(Vector3(1, 0, 0) + vec)
				arr1.append(Vector3(1, 1, 0) + vec)
				arr1.append(Vector3(1, 1, 1) + vec)
	time_1 = Time.get_ticks_msec() - time
	time = Time.get_ticks_msec()
	for _l in LOOPS:
		for n in BOX_SIZE:
			for y in BOX_SIZE: for x in BOX_SIZE: for z in BOX_SIZE:
				var vec := Vector3(x, y, z)
				arr2.append_array([
					Vector3(0, 0, 0) + vec,
					Vector3(1, 0, 0) + vec,
					Vector3(1, 1, 0) + vec,
					Vector3(1, 1, 1) + vec,
				])
	time_2 = Time.get_ticks_msec() - time

	const BIG_NR := BOX_SIZE * BOX_SIZE * BOX_SIZE
	arr3.resize(BIG_NR * 4)
	time = Time.get_ticks_msec()
	for _l in LOOPS:
		for n in BOX_SIZE:
			for y in BOX_SIZE: for x in BOX_SIZE: for z in BOX_SIZE:
				var vec := Vector3(x, y, z)
				var pos := y + x * BOX_SIZE + z * BOX_SIZE * BOX_SIZE
				arr3[pos] = Vector3(0, 0, 0) + vec
				arr3[pos + 1] = Vector3(1, 0, 0) + vec
				arr3[pos + 2] = Vector3(1, 1, 0) + vec
				arr3[pos + 3] = Vector3(1, 1, 1) + vec
	time_3 = Time.get_ticks_msec() - time

	print("app one at a time: ", time_1, "; append_array: ", time_2,
			"; presized array: ", time_3)


## vec: 13072; parray: 13777 when packedbytearray is used; vec: 13066; parray: 13821
## when int32array is used. creating new vecs is faster on the whole it seems
func _new_vec3s_or_packedarray_speed_test() -> void:
	const LOOPS := 1000
	var arr1 := PackedVector3Array()
	var arr2 := PackedVector3Array()
	const BOX_SIZE := 16
	var time_1 := 0
	var time_2 := 0
	var time := 0

	time = Time.get_ticks_msec()
	for _l in LOOPS:
		for n in BOX_SIZE:
			for y in BOX_SIZE: for x in BOX_SIZE: for z in BOX_SIZE:
				var vec := Vector3(x, y, z)
				_other_method_vec3(vec)
	time_1 = Time.get_ticks_msec() - time
	time = Time.get_ticks_msec()
	var parray := PackedInt32Array()
	parray.resize(3)
	for _l in LOOPS:
		for n in BOX_SIZE:
			for y in BOX_SIZE: for x in BOX_SIZE: for z in BOX_SIZE:
				parray[0] = x
				parray[1] = y
				parray[2] = z
				_other_method_packedarray(parray)
	time_2 = Time.get_ticks_msec() - time
	print("vec: ", time_1, "; parray: ", time_2)


func _other_method_vec3(pos: Vector3) -> void:
	var blaab := pos.x + pos.y * pos.y + pos.y + pos.z + pos.z * pos.x * pos.y
	blaab *= 1212


func _other_method_packedarray(pos: PackedInt32Array) -> void:
	var blaab := pos[0] + pos[1] * pos[1] + pos[1] + pos[2] + pos[2] * pos[0] * pos[1]
	blaab *= 1212


func _static_or_copy() -> void:
	const LOOPS := 100
	var arr1 := PackedInt32Array()
	var arr2 := PackedInt32Array()
	const BOX_SIZE := 16
	var time_1 := 0
	var time_2 := 0
	var time := 0

	time = Time.get_ticks_msec()
	for _l in LOOPS:
		for n in BOX_SIZE:
			for y in BOX_SIZE: for x in BOX_SIZE: for z in BOX_SIZE:
				var vec := Vector3(x, y, z)
				arr1.append(ChunkData.pos_to_index(vec))
	time_1 = Time.get_ticks_msec() - time
	time = Time.get_ticks_msec()
	for _l in LOOPS:
		for n in BOX_SIZE:
			for y in BOX_SIZE: for x in BOX_SIZE: for z in BOX_SIZE:
				var vec := Vector3(x, y, z)
				arr2.append(pos_to_index(vec))
	time_2 = Time.get_ticks_msec() - time
	print("static: ", time_1, "; local: ", time_2)


func pos_to_index(pos: Vector3) -> int:
	return int(
			pos.y
			+ pos.z * Chunk.SIZE.y
			+ pos.x * Chunk.SIZE.z * Chunk.SIZE.y)
