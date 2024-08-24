class_name WorldGenerator extends Node

const MAX_QUEUE_SIZE := 512124317241

var _thread := Thread.new()
var _semaph := Semaphore.new()
var _queue: Array[Chunk]
var active := false

var _generating_chunk: Chunk
var _generating_chunk_position: Vector3
var _generating_chunk_data: ChunkData

var _settings: GeneratorSettings


func _init() -> void:
	_thread.start(_threaded_generation, Thread.PRIORITY_HIGH)


func start_generating(_chunk: Chunk) -> void:
	if active:
		if _queue.size() >= MAX_QUEUE_SIZE:
			return
		_queue.append(_chunk)
		#print("-- gque: add chunk ", _chunk.name)
		return
	_generating_chunk = _chunk
	_generating_chunk_position = _chunk.global_position
	_generating_chunk_data = _chunk.data
	#print("-- qgue: post chunk " + _chunk.name)
	active = true
	_semaph.post()


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
	for x in 30:
		_check_queue()


func _check_queue() -> void:
	if active or _queue.is_empty():
		return
	if not is_instance_valid(_queue[0]):
		_queue.remove_at(0)
		return
	var first: Chunk = _queue.pop_front()
	if not is_instance_valid(first):
		return
	#print("-- gque: ", _queue.size())
	if first.load_step > 0:
		return
	start_generating(first)


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
