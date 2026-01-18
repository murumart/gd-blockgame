class_name Chunks

signal chunk_created(pos: Vector3i)
signal chunk_destroyed(pos: Vector3i)

const C_CHUNK_SIZE := Vector3i(16, 16, 16)
const C_BLOCKS_PER_CHUNK := C_CHUNK_SIZE.x * C_CHUNK_SIZE.y * C_CHUNK_SIZE.z

static var CHUNK_SIZE := C_CHUNK_SIZE
static var BLOCKS_PER_CHUNK := C_BLOCKS_PER_CHUNK

enum {
	FLAG_META_DIRTY = 0b1,
	FLAG_NEEDS_MESHING = 0b1000,
}

var blocks: Dictionary[Vector3i, PackedByteArray]
var flags: Dictionary[Vector3i, int]
var occupancy_maps: Dictionary[Vector3i, Array]
var adjacency_maps: Dictionary[Vector3i, Array]
var chunk_load_radius := 6


func _init() -> void:
	print("Chunks::_init : created chunks manager")


func load_chunks(cpos: Vector3i, load_radius: int = chunk_load_radius) -> void:
	print("Chunks::load_chunks : loading chunks")
	var checkpos := cpos + Vector3i(-load_radius, -load_radius, -load_radius)
	var time := Time.get_ticks_msec()
	#for z in load_radius * 2 + 1: for y in load_radius * 2 + 1: for x in load_radius * 2 + 1:
	while checkpos.z - cpos.z <= load_radius:
		checkpos.y = cpos.y - load_radius
		while checkpos.y - cpos.y <= load_radius:
			checkpos.x = cpos.x - load_radius
			while checkpos.x - cpos.x <= load_radius:
				var dist := (checkpos).distance_squared_to(cpos)
				#print("Chunks::load_chunks : distance from center at %s: %s" % [checkpos, dist])
				if dist <= load_radius * load_radius:
					_load_chunk.call_deferred(checkpos)
				checkpos.x += 1
			checkpos.y += 1
		checkpos.z += 1
	print("Chunks::load_chunks : took ", Time.get_ticks_msec() - time, " ms")


func unload_chunks(center: Vector3i, load_radius: int = chunk_load_radius) -> void:
	for cpos in blocks:
		if center.distance_squared_to(cpos) > load_radius * load_radius:
			destroy_chunk(cpos)


func _load_chunk(cpos: Vector3i) -> void:
	if cpos not in blocks:
		create_chunk(cpos)


func create_chunk(position: Vector3i) -> void:
	assert(position not in blocks)
	assert(position not in flags)
	assert(position not in adjacency_maps)

	var bd: PackedByteArray = []
	bd.resize(BLOCKS_PER_CHUNK)

	# debug worldgen
	var wp := position * CHUNK_SIZE
	var ix := 0
	for z in CHUNK_SIZE.z:
		var ylvl := sin((z + wp.z) * 0.05) * 5 + CHUNK_SIZE.y * 0.5
		for y in CHUNK_SIZE.y: for x in CHUNK_SIZE.x:
			if y + wp.y < ylvl - cos((x + wp.x) * 0.035) * 5:
				bd[ix] = 1
			ix += 1

	var occ: Array[PackedInt64Array]
	var adj: Array[PackedInt64Array]
	#var starttime := Time.get_ticks_usec()
	_generate_occupancy_maps(bd, occ)
	#print("Chunks::create_chunk : generating occupancy maps took ", Time.get_ticks_usec() - starttime, " us")
	_generate_adjacency_maps(bd, occ, adj)
	blocks[position] = bd
	flags[position] = FLAG_NEEDS_MESHING
	occupancy_maps[position] = occ
	adjacency_maps[position] = adj

	chunk_created.emit(position)


func destroy_chunk(position: Vector3i) -> void:
	assert(position in blocks)
	assert(position in flags)

	blocks.erase(position)
	flags.erase(position)
	occupancy_maps.erase(position)
	adjacency_maps.erase(position)
	chunk_destroyed.emit(position)


func get_chunks_to_mesh(poses: Array[Vector3i]) -> void:
	for p in flags:
		if flags[p] & FLAG_NEEDS_MESHING and not p in poses:
			poses.append(p)


enum {
	ADJ_AXIS_XY,
	ADJ_AXIS_XZ,
	ADJ_AXIS_YZ,
}
static var _axes := [
	Vector2i(CHUNK_SIZE.x, CHUNK_SIZE.y), # xy axis, blocks along +z
	Vector2i(CHUNK_SIZE.x, CHUNK_SIZE.z), # xz axis, blocks along +y
	Vector2i(CHUNK_SIZE.y, CHUNK_SIZE.z), # yz axis, blocks along +x
]
func _generate_occupancy_maps(cblocks: PackedByteArray, occupancy: Array[PackedInt64Array]) -> void:
	assert(not cblocks.is_empty())
	assert(occupancy.is_empty())

	for ab: Vector2i in _axes:
		var occ: PackedInt64Array = []
		occ.resize(ab.x * ab.y)
		#for a in ab.x: for b in ab.y:
		#	occ[a + b * ab.x] = 0 # create the line
		occupancy.append(occ)

	var bix := 0
	for z in CHUNK_SIZE.z: \
	for y in CHUNK_SIZE.y: \
	for x in CHUNK_SIZE.x:
		var solid := cblocks[bix] != 0
		bix += 1
		if not solid: continue
		# xy axis, blocks along +z
		occupancy[ADJ_AXIS_XY][x + y * CHUNK_SIZE.x] |= 1 << z
		# xz axis, blocks along +y
		occupancy[ADJ_AXIS_XZ][x + z * CHUNK_SIZE.x] |= 1 << y
		# yz axis, blocks along +x
		occupancy[ADJ_AXIS_YZ][y + z * CHUNK_SIZE.y] |= 1 << x

	#for a: Array in [[0, "xy"], [1, "xz"], [2, "yz"]]:
	#	var b := occupancy[a[0]]
	#	print("Chunks::_generate_occupancy_maps : axis ", a[1])
	#	print("Chunks::_generate_occupancy_maps : axis ",
	#		", ".join(Array(b).map(func(c: int) -> String:
	#			return String.num_uint64(c, 2)))
	#	)



func _generate_adjacency_maps(
	cblocks: PackedByteArray,
	occupancy: Array[PackedInt64Array],
	adjacency: Array[PackedInt64Array]
) -> void:
	assert(not cblocks.is_empty())
	assert(occupancy.size() == 3)
	assert(adjacency.is_empty())

	adjacency.resize(6)
	var ai := 0
	for ab: Vector2i in _axes:
		var size := ab.x * ab.y
		var adjp: PackedInt64Array = []
		adjp.resize(size)
		var adjm: PackedInt64Array = []
		adjm.resize(size)
		adjacency[ai] = adjp
		adjacency[ai + 3] = adjm

		for x in ab.x: for y in ab.y:
			var line := occupancy[ai][x + y * ab.x]
			adjacency[ai][x + y * ab.x] = line & (~(line >> 1)) # +
			adjacency[ai + 3][x + y * ab.x] = line & (~(line << 1)) # -
			#print("Chunks::_generate_adjacency_maps : line %s of axis %s is %s" % [Vector2i(x, y), ai, String.num_int64(line, 2)])

		ai += 1

	#print("Chunks::_generate_adjacency_maps : adjacency ", adjacency)
