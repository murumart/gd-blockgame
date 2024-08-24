class_name WorldGenerator extends Node

const MAX_QUEUE_SIZE := 512124317241

var _thread := Thread.new()
var _semaph := Semaphore.new()
var active := false

var _generating_chunk: Chunk
var _generating_chunk_position: Vector3
var _generating_chunk_data: ChunkData

var _settings: GeneratorSettings
@export var _world: World


func _init() -> void:
	_thread.start(_threaded_generation, Thread.PRIORITY_HIGH)


func start_generating(_chunk: Chunk) -> void:
	if active:
		return
	_generating_chunk = _chunk
	_chunk._history[Engine.get_process_frames()] = "posting for block gen"
	_generating_chunk_position = _chunk.global_position
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
				#World.global_pos_to_chunk_pos(_generating_chunk_position))
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


func _process(delta: float) -> void:
	_visible_chunk_positions = get_chunk_poses_to_load_sorted()
	_process_chunks()


var _visible_chunk_positions: PackedVector3Array = []
var _index := 0
func _process_chunks() -> void:
	for i in 3:
		if _index < 0 or _index >= _visible_chunk_positions.size():
			_index = 0
		if _visible_chunk_positions.is_empty():
			_index = 0
			return
		var pos := _visible_chunk_positions[_index]
		_index += 1
		var chunk := _world.load_chunk(pos)
		if not is_instance_valid(chunk):
			return
		if chunk.load_step == Chunk.LoadSteps.UNLOADED:
			chunk.generate()



func get_block_at(global_position: Vector3) -> int:
	return _settings.get_block_at(global_position)
	#if (cos((global_position.x + 410) * 0.01) * 100 + sin(global_position.z * 0.01) * 100 < -110):
		#return 2
	#var ypos := int((sin(global_position.x * 0.1) * cos(global_position.z * 0.1) * 16.0
		#+ cos(global_position.x * 0.001) * sin(global_position.z * 0.001) * 500))
	#if global_position.y == ypos:
		#return 3
	#if (global_position.y < ypos - 3):
		#return 1
	#elif global_position.y < ypos:
		#return 2 if randf() < 0.5 else 1
	#return 0


func _get_chunk_poses_to_load() -> PackedVector3Array:
	var toreturn: PackedVector3Array = []
	for loader in _world.chunk_loaders:
		var chunk_pos := World.global_pos_to_chunk_pos(loader.global_position)
		#var vertical_distance := maxi(loader.load_distance / 3, 1)
		#var LOADER_Y := range(
				#chunk_pos.y + vertical_distance,
				#chunk_pos.y - vertical_distance - 1,
				#-1)
		#for y: int in LOADER_Y:
			#var dist := absf(chunk_pos.y - y)
			#toreturn.append_array(
					#WorldGenerator.get_diamond(Vector3(chunk_pos.x, y, chunk_pos.z),
					#loader.load_distance - dist))
		toreturn.append(chunk_pos)
		toreturn.append(chunk_pos + Vector3.LEFT)
		toreturn.append(chunk_pos + Vector3.FORWARD)
		toreturn.append(chunk_pos + Vector3.RIGHT)
		toreturn.append(chunk_pos + Vector3.BACK)
		toreturn.append(chunk_pos + Vector3.DOWN)
		toreturn.append(chunk_pos + Vector3.UP)
		toreturn.append_array(WorldGenerator.get_diamond(chunk_pos, loader.load_distance))
		toreturn.append_array(WorldGenerator.get_diamond(chunk_pos + Vector3.DOWN, loader.load_distance - 3))
		toreturn.append_array(WorldGenerator.get_diamond(chunk_pos + Vector3.UP, loader.load_distance - 3))
	return toreturn


func get_chunk_poses_to_load_sorted() -> PackedVector3Array:
	var time := Time.get_ticks_msec()
	var toreturn: Array[Vector3] = []
	var chunk_pos: Vector3
	for loader in _world.chunk_loaders:
		chunk_pos = World.global_pos_to_chunk_pos(loader.global_position)
		#toreturn.append(chunk_pos)
		#toreturn.append(chunk_pos + Vector3.LEFT)
		#toreturn.append(chunk_pos + Vector3.FORWARD)
		#toreturn.append(chunk_pos + Vector3.RIGHT)
		#toreturn.append(chunk_pos + Vector3.BACK)
		#toreturn.append(chunk_pos + Vector3.DOWN)
		#toreturn.append(chunk_pos + Vector3.UP)
		toreturn.append_array(WorldGenerator.get_diamond(chunk_pos, loader.load_distance))
		toreturn.append_array(WorldGenerator.get_diamond(chunk_pos + Vector3.DOWN, loader.load_distance - 3))
		toreturn.append_array(WorldGenerator.get_diamond(chunk_pos + Vector3.UP, loader.load_distance - 3))
		#toreturn.append_array(WorldGenerator.get_diamond(chunk_pos, loader.load_distance))
	toreturn.sort_custom(_sort_poses_by_distance_from_loader.bind(chunk_pos))
	#print("getting loadable chnks took ", Time.get_ticks_msec() - time, " ms")
	return toreturn


func _sort_poses_by_distance_from_loader(pos1: Vector3, pos2: Vector3, centerpos: Vector3) -> bool:
	var dis1 := pos1.distance_squared_to(centerpos)
	var dis2 := pos1.distance_squared_to(centerpos)
	#print("comparing ", dis1, " ", dis2, " ", pos1, " ", pos2, " against ", centerpos)
	return dis1 > dis2


func _exit_tree() -> void:
	_semaph.post()
	_thread.wait_to_finish()


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
