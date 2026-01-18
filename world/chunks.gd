class_name Chunks

signal chunk_created(pos: Vector3i)

const C_CHUNK_SIZE := Vector3i(32, 32, 32)
const C_BLOCKS_PER_CHUNK := C_CHUNK_SIZE.x * C_CHUNK_SIZE.y * C_CHUNK_SIZE.z

static var CHUNK_SIZE := C_CHUNK_SIZE
static var BLOCKS_PER_CHUNK := C_BLOCKS_PER_CHUNK

enum {
	FLAG_META_DIRTY = 0b1,
}

var blocks: Dictionary[Vector3i, PackedByteArray]
var flags: Dictionary[Vector3i, int]
var occupancy_maps: Dictionary[Vector3i, Array]
var adjacency_maps: Dictionary[Vector3i, Array]


func _init() -> void:
	print("Chunks::_init : created chunks manager")


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
	#var starttime := Time.get_ticks_msec()
	_generate_occupancy_maps(bd, occ)
	_generate_adjacency_maps(bd, occ, adj)
	#print("Chunks::create_chunk : generating maps took ", Time.get_ticks_msec() - starttime, " ms")
	blocks[position] = bd
	flags[position] = FLAG_META_DIRTY
	occupancy_maps[position] = occ
	adjacency_maps[position] = adj

	chunk_created.emit(position)


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
		for a in ab.x: for b in ab.y:
			occ[a + b * ab.x] = 0 # create the line
		occupancy.append(occ)

	var bix := 0
	for z in CHUNK_SIZE.z: \
	for y in CHUNK_SIZE.y: \
	for x in CHUNK_SIZE.x:
		var solid := cblocks[bix] != 0
		if solid:
			# xy axis, blocks along +z
			occupancy[ADJ_AXIS_XY][x + y * CHUNK_SIZE.x] |= 1 << z
			# xz axis, blocks along +y
			occupancy[ADJ_AXIS_XZ][x + z * CHUNK_SIZE.x] |= 1 << y
			# yz axis, blocks along +x
			occupancy[ADJ_AXIS_YZ][y + z * CHUNK_SIZE.y] |= 1 << x
		bix += 1

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
