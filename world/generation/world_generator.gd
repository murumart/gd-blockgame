class_name WorldGenerator extends Node

## Generates the [World].

var _thread := Thread.new()
var _semaph := Semaphore.new()
## Whether the world generation thread is active at this time.
var active := false

var _generating_chunk: Chunk
var _generating_chunk_position: Vector3
var _generating_chunk_data: ChunkData

## What chunks should be currently loaded.
var visible_chunk_positions: PackedVector3Array

var _settings: GeneratorSettings
@export var _world: World


func _init() -> void:
	_thread.start(_threaded_generation, Thread.PRIORITY_HIGH)


## Starts generation of a [Chunk] if not currently generating.
func start_generating(_chunk: Chunk) -> void:
	if active:
		return
	_generating_chunk = _chunk
	_chunk._history[Engine.get_process_frames()] = "posting for block gen"
	_generating_chunk_position = _chunk.global_position + _world.world_position
	_generating_chunk_data = _chunk.data
	#print("-- qgue: post chunk " + _chunk.name)
	active = true
	_semaph.post()


func _on_chunk_gen_requested(chunk: Chunk) -> void:
	if chunk.load_step > Chunk.LoadSteps.UNLOADED:
		return
	start_generating(chunk)


func _threaded_generation() -> void:
	while true:
		#print("--- GEN waiting")
		_semaph.wait()
		#print("--- GEN starting with chunk at ",
				#World.world_pos_to_chunk_pos(_generating_chunk_position))
		assert(is_instance_valid(_generating_chunk))

		for y in Chunk.SIZE.y:
			for x in Chunk.SIZE.x:
				for z in Chunk.SIZE.z:
					var in_chunk_pos := Vector3(x, y, z)
					var block_pos := _generating_chunk_position + in_chunk_pos
					var block := get_block_at(block_pos)
					var index := ChunkData.pos_to_index(in_chunk_pos)
					#_generating_chunk_data.set_block_at(index, block)
					_generating_chunk_data.block_data.encode_u16(
							index * ChunkData.BYTES_PER_BLOCK, block)

		if is_instance_valid(_generating_chunk):
			_generating_chunk._generation_thread_finished.call_deferred()
		_generating_chunk = null
		_generating_chunk_data = null
		_generating_chunk_position = Vector3(0, 1, 0)
		set_deferred("active", false)


func _process(_delta: float) -> void:
	_process_chunks()


func _process_chunks() -> void:
	for i in visible_chunk_positions.size():
		var pos := visible_chunk_positions[i]
		var chunk := _world.load_chunk(pos)
		if not is_instance_valid(chunk):
			continue
		if chunk.load_step == Chunk.LoadSteps.UNLOADED and not active:
			chunk.generate()


## Gets the block using the parent [World]'s [GeneratorSettings] instance.
func get_block_at(global_position: Vector3) -> int:
	return _settings.get_block_at(global_position)


func _get_chunk_poses_to_load() -> Array[Vector3]:
	var toreturn: Array[Vector3] = []
	for loader in _world.chunk_loaders:
		if not loader.enabled:
			continue
		var chunk_pos := World.world_pos_to_chunk_pos(loader.global_position + _world.world_position)
		for y in range(-6, 6):
			chunk_pos.y = y
			toreturn.append_array(WorldGenerator.get_diamond(chunk_pos, loader.load_distance))
		#var yrange := roundi(loader.load_distance / 8.0)
		#for y in range(-yrange, yrange + 1):
			#if y == 0:
				#continue
			#toreturn.append_array(WorldGenerator.get_diamond(
					#Vector3(chunk_pos.x, chunk_pos.y + y, chunk_pos.z),
					#maxi(loader.load_distance - absi(y) * 6, 1)))
		
	return toreturn


## Returns a list of chunk positions to load, sorted around the last [member World.chunk_loaders].
func get_chunk_poses_to_load_sorted() -> PackedVector3Array:
	#var time := Time.get_ticks_msec()
	var toreturn: Array[Vector3] = _get_chunk_poses_to_load()
	var chunk_pos: Vector3
	for loader in _world.chunk_loaders:
		if not loader.enabled:
			continue
		chunk_pos = World.world_pos_to_chunk_pos(loader.global_position + _world.world_position)
	toreturn.sort_custom(_compare_distances_from_center.bind(chunk_pos))
	#print("getting loadable chnks took ", Time.get_ticks_msec() - time, " ms")
	return toreturn


func _compare_distances_from_center(pos1: Vector3, pos2: Vector3, centerpos: Vector3) -> bool:
	var dis1 := pos1.distance_squared_to(centerpos)
	var dis2 := pos2.distance_squared_to(centerpos)
	#print("comparing ", dis1, " ", dis2, " ", pos1, " ", pos2, " against ", centerpos)
	return dis1 < dis2


func _exit_tree() -> void:
	_semaph.post()
	_thread.wait_to_finish()


## Resets [member visible_chunk_positions].
func recalculate_visible_chunk_positions() -> void:
	visible_chunk_positions = get_chunk_poses_to_load_sorted()


## Grows a diamond selection around a start position on the x and z axes.
## Returns all selected coordinates.
static func get_diamond(start: Vector3, side_len: int) -> PackedVector3Array:
	var toreturn: PackedVector3Array = [start]
	var start_positions: PackedVector3Array = []
	start_positions.resize(side_len)
	for i in side_len:
		start_positions[i] = start + Vector3.LEFT * (i + 1)

	var addition := Vector3(1, 0, 1)
	var cursor := start + Vector3.LEFT

	toreturn.append(cursor)
	for i in 200:
		var added := cursor + addition
		if added in start_positions:
			if added == start_positions[side_len - 1]:
				break
			cursor.x -= 1
		cursor += addition
		toreturn.append(cursor)
		if cursor.z == start.z:
			addition.x *= -1
		if cursor.x == start.x:
			addition.z *= -1
	return toreturn
