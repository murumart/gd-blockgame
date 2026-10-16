class_name Chunks

signal chunk_created(pos: Vector3i)
signal chunk_destroyed(pos: Vector3i)

const C_CHUNK_SIZE := Vector3i(16, 16, 16)
const C_CHUNK_SIZEF := Vector3(C_CHUNK_SIZE)
const C_BLOCKS_PER_CHUNK := C_CHUNK_SIZE.x * C_CHUNK_SIZE.y * C_CHUNK_SIZE.z

static var CHUNK_SIZE := C_CHUNK_SIZE
static var BLOCKS_PER_CHUNK := C_BLOCKS_PER_CHUNK

enum {
	FLAG_META_DIRTY = 0b1,
	FLAG_NEEDS_MESHING = 0b1000,
}

var world: World

var blocks: Dictionary[Vector3i, PackedByteArray] = {}
var flags: Dictionary[Vector3i, int]
var occupancy_maps: Dictionary[Vector3i, Array]
var adjacency_maps: Dictionary[Vector3i, Array]
var chunk_load_radius := 3

const MAX_QUEUED_FOR_LOADING := 25
var _chunks_to_load_queue: Array[Vector3i]
var loading_chunk := false


func _init(w: World) -> void:
	world = w
	print("Chunks::_init : created chunks manager")


func cleanup() -> void:
	if not WorkerThreadPool.is_group_task_completed(_loading_task):
		WorkerThreadPool.wait_for_group_task_completion(_loading_task)


var _last_center := Vector3i.MIN
var _loading_task: int
var _task_queue: Array[Vector3i]

func process(center: Vector3i) -> void:
	if loading_chunk:
		if WorkerThreadPool.is_group_task_completed(_loading_task):
			WorkerThreadPool.wait_for_group_task_completion(_loading_task)
			loading_chunk = false
		else:
			return
	_last_center = center
	if _chunks_to_load_queue.is_empty(): return
	_chunks_to_load_queue.sort_custom(_sort_chunks_by_center_dist)
	assert(not loading_chunk)
	_task_queue = _chunks_to_load_queue.duplicate()
	_chunks_to_load_queue.clear()
	loading_chunk = true
	_loading_task = WorkerThreadPool.add_group_task(_threaded_loading, _task_queue.size(), 2, false, "loading chunks")


func load_chunks(cpos: Vector3i, load_radius: int = chunk_load_radius) -> void:
	var checkpos := cpos + Vector3i(-load_radius, -load_radius, -load_radius)
	while checkpos.z - cpos.z <= load_radius:
		checkpos.y = cpos.y - load_radius
		while checkpos.y - cpos.y <= load_radius:
			checkpos.x = cpos.x - load_radius
			while checkpos.x - cpos.x <= load_radius:
				var dist := (checkpos).distance_squared_to(cpos)
				#print("Chunks::load_chunks : distance from center at %s: %s" % [checkpos, dist])
				if dist <= load_radius * load_radius and checkpos not in _chunks_to_load_queue and not checkpos in blocks:
					_queue_chunk_load(checkpos)
				checkpos.x += 1
			checkpos.y += 1
		checkpos.z += 1


func unload_chunks(center: Vector3i, load_radius: int = chunk_load_radius) -> void:
	for cpos: Vector3i in blocks.keys():
		var dist := center.distance_squared_to(cpos)
		if dist > load_radius * load_radius:
			destroy_chunk(cpos)


static func block_index(coord: Vector3i) -> int:
	return coord.x + coord.y * CHUNK_SIZE.x + coord.z * CHUNK_SIZE.x * CHUNK_SIZE.y


func _queue_chunk_load(cpos: Vector3i) -> void:
	assert(cpos not in blocks)
	assert(cpos not in _chunks_to_load_queue)
	if _chunks_to_load_queue.size() > MAX_QUEUED_FOR_LOADING:
		return
	var ix := _chunks_to_load_queue.bsearch_custom(cpos, _sort_chunks_by_center_dist)
	_chunks_to_load_queue.insert(ix, cpos)


func _chunk_created(
	pos: Vector3i,
	b: PackedByteArray,
	occ: Array[PackedInt64Array],
	adj: Array[PackedInt64Array],
	f: int,
) -> void:
	if not not blocks.has(pos): return
	if not pos not in flags: return
	if not pos not in adjacency_maps: return
	assert(not blocks.has(pos))
	assert(pos not in flags)
	assert(pos not in adjacency_maps)
	_chunks_to_load_queue.erase(pos)
	if (pos.distance_squared_to(world.get_center_chunk()) > chunk_load_radius * chunk_load_radius):
		return # forget everything you know
	blocks[pos] = b
	occupancy_maps[pos] = occ
	adjacency_maps[pos] = adj
	flags[pos] = f
	chunk_created.emit(pos)


func _threaded_loading(ix: int) -> void:
	var pos := _task_queue[ix]
	var b: PackedByteArray
	var occ: Array[PackedInt64Array]
	var adj: Array[PackedInt64Array]
	var f: PackedInt64Array; f.resize(1) # int as reference
	_create_chunk(pos, b, occ, adj, f)
	_chunk_created.call_deferred(pos, b, occ, adj, f[0])


func _create_chunk(
	pos: Vector3i,
	bd: PackedByteArray,
	occ: Array[PackedInt64Array],
	adj: Array[PackedInt64Array],
	f: PackedInt64Array,
) -> void:

	assert(bd.is_empty())
	bd.resize(BLOCKS_PER_CHUNK)

	# debug worldgen
	var wp := pos * CHUNK_SIZE
	if false:
		var ix := 0
		for z in CHUNK_SIZE.z:
			var ylvl := sin((z + wp.z) * 0.05) * 5 + CHUNK_SIZE.y * 0.5
			for y in CHUNK_SIZE.y:
				var yc := wp.y + y
				for x in CHUNK_SIZE.x:
					var lylvl := ylvl - cos((x + wp.x) * 0.035) * 5
					var topdist := lylvl - yc
					if yc < lylvl:
						bd[ix] = randi_range(0, 8)
					ix += 1
	else:
		bd[0] = 2

	#var starttime := Time.get_ticks_usec()
	_generate_occupancy_maps(bd, occ)
	#print("Chunks::create_chunk : generating occupancy maps took ", Time.get_ticks_usec() - starttime, " us")
	_generate_adjacency_maps(bd, occ, adj)
	f[0] = FLAG_NEEDS_MESHING


func destroy_chunk(position: Vector3i) -> void:
	assert(position in blocks)
	assert(position in flags)

	blocks.erase(position)
	flags.erase(position)
	occupancy_maps.erase(position)
	adjacency_maps.erase(position)
	chunk_destroyed.emit(position)


func get_chunks_to_mesh(poses: Array[Vector3i]) -> void:
	for p: Vector3i in flags.keys():
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


func _sort_chunks_by_center_dist(a: Vector3i, b: Vector3i) -> bool:
	return a.distance_squared_to(_last_center) < b.distance_squared_to(_last_center)
