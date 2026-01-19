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

var world: World

var blocks: Dictionary[Vector3i, PackedByteArray] = {}
var flags: Dictionary[Vector3i, int]
var occupancy_maps: Dictionary[Vector3i, Array]
var adjacency_maps: Dictionary[Vector3i, Array]
var chunk_load_radius := 6

const MAX_QUEUED_FOR_LOADING := 1500
var _chunks_to_load_queue: Array[Vector3i]
var _chunk_loader_thread := Thread.new()
var _chunk_loader_semaph := Semaphore.new()
var _chunk_loader_mutex := Mutex.new()
var _THREADACCESS_enough_with_the_chunk_loading := false
var _THREADACCESS_chunk_to_load := Vector3i()
var loading_chunk := false


func _init(w: World) -> void:
	world = w
	print("Chunks::_init : created chunks manager")
	_chunk_loader_thread.start(_threaded_loading)


func cleanup() -> void:
	_THREADACCESS_enough_with_the_chunk_loading = true
	_chunk_loader_semaph.post()
	_chunk_loader_thread.wait_to_finish()


var _last_center := Vector3i.MIN
func process(center: Vector3i, load_radius: int = chunk_load_radius) -> void:
	_chunks_to_load_queue.sort_custom(_sort_chunks_by_center_dist.bind(center))
	if _last_center != center:
		_last_center = center
	if _chunks_to_load_queue.is_empty() or loading_chunk: return
	_chunk_loader_mutex.lock()
	_THREADACCESS_chunk_to_load = _chunks_to_load_queue[-1]
	var dist := _THREADACCESS_chunk_to_load.distance_squared_to(center)
	while _chunks_to_load_queue.size() > 0 and dist > load_radius * load_radius:
		_chunks_to_load_queue.remove_at(-1)
		_THREADACCESS_chunk_to_load = _chunks_to_load_queue[-1]
		dist = _THREADACCESS_chunk_to_load.distance_squared_to(center)
	assert(_THREADACCESS_chunk_to_load not in blocks)
	_chunk_loader_mutex.unlock()
	#print("Chunks::process : posted semaphore")
	loading_chunk = true
	_chunk_loader_semaph.post()


func load_chunks(cpos: Vector3i, load_radius: int = chunk_load_radius) -> void:
	var checkpos := cpos + Vector3i(-load_radius, -load_radius, -load_radius)
	while checkpos.z - cpos.z <= load_radius:
		checkpos.y = cpos.y - load_radius
		while checkpos.y - cpos.y <= load_radius:
			checkpos.x = cpos.x - load_radius
			while checkpos.x - cpos.x <= load_radius:
				var dist := (checkpos).distance_squared_to(cpos)
				#print("Chunks::load_chunks : distance from center at %s: %s" % [checkpos, dist])
				if dist <= load_radius * load_radius:
					_queue_chunk_load(checkpos, cpos)
				checkpos.x += 1
			checkpos.y += 1
		checkpos.z += 1


func unload_chunks(center: Vector3i, load_radius: int = chunk_load_radius) -> void:
	for cpos: Vector3i in blocks.keys():
		var dist := center.distance_squared_to(cpos)
		if dist > load_radius * load_radius:
			destroy_chunk(cpos)


func _queue_chunk_load(cpos: Vector3i, _center: Vector3i) -> void:
	if _chunks_to_load_queue.size() > MAX_QUEUED_FOR_LOADING:
		return
	if cpos in blocks or cpos in _chunks_to_load_queue:
		return
	_chunks_to_load_queue.append(cpos)


func _chunk_created(
	pos: Vector3i,
	b: PackedByteArray,
	occ: Array[PackedInt64Array],
	adj: Array[PackedInt64Array],
	f: int,
) -> void:
	assert(not blocks.has(pos))
	assert(pos not in flags)
	assert(pos not in adjacency_maps)
	loading_chunk = false
	_chunks_to_load_queue.erase(pos)
	if (pos.distance_squared_to(world.get_center_chunk()) > chunk_load_radius * chunk_load_radius):
		return # forget everything you know
	blocks[pos] = b
	occupancy_maps[pos] = occ
	adjacency_maps[pos] = adj
	flags[pos] = f
	chunk_created.emit(pos)
	(func() -> void:
		var n := Sprite3D.new()
		n.texture = preload("res://carcinous_scope_incomprehensible.png")
		n.position = Vector3(pos * CHUNK_SIZE) + CHUNK_SIZE * 0.5
		n.set_meta("pos", pos)
		world.add_child(n)
	).call_deferred()


func _threaded_loading() -> void:
	while true:
		#print("Chunks::_threaded_loading : waiting for post")
		_chunk_loader_semaph.wait()
		_chunk_loader_mutex.lock()
		if _THREADACCESS_enough_with_the_chunk_loading: break
		var pos := _THREADACCESS_chunk_to_load
		_chunk_loader_mutex.unlock()
		#print("Chunks::_threaded_loading : starting with position ", pos)
		var b: PackedByteArray
		var occ: Array[PackedInt64Array]
		var adj: Array[PackedInt64Array]
		var f: PackedInt64Array; f.resize(1)
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
	var ix := 0
	for z in CHUNK_SIZE.z:
		var ylvl := sin((z + wp.z) * 0.05) * 5 + CHUNK_SIZE.y * 0.5
		for y in CHUNK_SIZE.y: for x in CHUNK_SIZE.x:
			if y + wp.y < ylvl - cos((x + wp.x) * 0.035) * 5:
				bd[ix] = 1
			ix += 1

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


func _sort_chunks_by_center_dist(a: Vector3i, b: Vector3i, center: Vector3i) -> bool:
	return a.distance_squared_to(center) > b.distance_squared_to(center)
