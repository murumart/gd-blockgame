class_name ChunkMeshThread

static var thread := Thread.new()
static var _over := false
static var _queue: Array = []


static func make_meshes(_chunks: Array[Chunk]) -> void:
	if thread.is_alive():
		_queue.append(_chunks)
		return
	else:
		thread.wait_to_finish()
	thread.start(_make_meshes_thread.bind(_chunks))


static func _make_meshes_thread(_chunks: Array[Chunk]) -> void:
	for chunk: Chunk in _chunks:
		var mesh := ArrayMesh.new()
		chunk.mesh.create_mesh_threadsafer(chunk.data, chunk.world, mesh)
		chunk.mesh.set_deferred("mesh", mesh)
		chunk.set_deferred("load_step", Chunk.LoadSteps.MESH_GENNED)
	_thread_finished.call_deferred()


static func _thread_finished() -> void:
	if _queue.is_empty():
		return
	var chunks: Array[Chunk] = _queue.pop_front()
	thread.start(_make_meshes_thread.bind(chunks))


static func destroy_forever() -> void:
	_over = true
	thread.wait_to_finish()
	thread = null
