extends Node2D

const V000 := Vector3(0, 0, 0)
const V100 := Vector3(1, 0, 0)
const V110 := Vector3(1, 1, 0)
const V111 := Vector3(1, 1, 1)


func _ready() -> void:
	_perf_test()
	var diamond := WorldGenerator.get_diamond(Vector3.ZERO, 18)
	print(diamond)
	draw.connect(func() -> void:
		var color := Color.RED
		const ADD := Vector2(70, 60)
		const SIZE := Vector2(6, 6)
		for pos in diamond:
			var vec2 := Vector2(pos.x, -pos.z) + ADD
			draw_rect(Rect2(vec2 * SIZE, SIZE), color)
			color.h += 0.01
	)
	#get_diamond(Vector3.ZERO, 3)
	queue_redraw()


func _perf_test() -> void:
	_chunk_pos_comparison()


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


var vectors := PackedVector3Array()
func get_diamond(start: Vector3, side_len: int) -> void:
	vectors.append(start)
	var start_positions: PackedVector3Array = []
	start_positions.resize(side_len)
	for i in side_len:
		start_positions[i] = start + Vector3.LEFT * (i + 1)

	var addition := Vector3(1, 0, 1)
	var cursor := start + Vector3.LEFT

	vectors.append(cursor)
	for i in 100:
		print("bstep: ", cursor, " ", addition)
		var added := cursor + addition
		if added in start_positions:
			if added == start_positions[side_len - 1]:
				print("done")
				break
			cursor.x -= 1
		cursor += addition
		vectors.append(cursor)
		if cursor.z == start.z:
			addition.x *= -1
		if cursor.x == start.x:
			addition.z *= -1
		print("astep: ", cursor, " ", addition, "\n")
		queue_redraw()
		await get_tree().create_timer(0.5).timeout


## time 1: 1076; time 2: 826
func _chunk_pos_comparison() -> void:
	const LOOPS := 1000
	const BOX_SIZE := 10
	var time_1 := 0
	var time_2 := 0
	var time := 0
	var arr_1 := []
	var arr_2 := []

	time = Time.get_ticks_msec()
	for i in LOOPS:
		for x in BOX_SIZE: for y in BOX_SIZE: for z in BOX_SIZE:
			var pos := Vector3(x, y, z)
			arr_1.append(global_pos_to_chunk_pos_1(pos))
	time_1 = Time.get_ticks_msec() - time
	time = Time.get_ticks_msec()
	for i in LOOPS:
		for x in BOX_SIZE: for y in BOX_SIZE: for z in BOX_SIZE:
			var pos := Vector3(x, y, z)
			arr_2.append(global_pos_to_chunk_pos_2(pos))
	time_2 = Time.get_ticks_msec() - time
	print("time 1: ", time_1, "; time 2: ", time_2)
	print("arrays equal: ", arr_1 == arr_2)


func global_pos_to_chunk_pos_1(global_pos: Vector3) -> Vector3:
	var x := floori(global_pos.x / Chunk.SIZE.x)
	var y := floori(global_pos.y / Chunk.SIZE.y)
	var z := floori(global_pos.z / Chunk.SIZE.z)
	return Vector3(x, y, z)


func global_pos_to_chunk_pos_2(global_pos: Vector3) -> Vector3:
	return (global_pos / Vector3(Chunk.SIZE)).floor()
