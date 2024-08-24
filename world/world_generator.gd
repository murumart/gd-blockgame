class_name WorldGenerator extends Node

var _thread := Thread.new()
var _semaph := Semaphore.new()
var _queue: Array[Chunk]
var active := false

var _generating_chunk: Chunk
var _generating_chunk_position: Vector3
var _generating_chunk_data: ChunkData


func _init() -> void:
	_thread.start(_threaded_generation)


func start_generating(_chunk: Chunk) -> void:
	if active:
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
			_generating_chunk.load_step = Chunk.LoadSteps.MESH_GENNED
			_generating_chunk._generation_thread_finished.call_deferred()
		_generating_chunk = null
		_generating_chunk_data = null
		_generating_chunk_position = Vector3(0, 1, 0)
		set_deferred("active", false)


func _process(delta: float) -> void:
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
	if (global_position.y
		< (sin(global_position.x * 0.1) * cos(global_position.z * 0.1) * 16.0
		+ cos(global_position.x * 0.001) * sin(global_position.z * 0.001) * 500)
	):
		return randi_range(1, 3)
	if (cos(global_position.x * 0.001) * 100 + sin(global_position.z * 0.001) * 100 < 69):
		return 2
	return 0


func _exit_tree() -> void:
	_semaph.post()
	_thread.wait_to_finish()
