extends NullChunk


func _ready() -> void:
	mesh = $ChunkMesh
	mesh.chunk_position = chunk_position
	mesh.mesh_build_finished.connect(_on_mesh_build_finished)


func _build() -> void:
	_build_mesh()


func _build_mesh() -> void:
	#Util.measure_time(mesh.build_mesh.bind(blocks))
	mesh.build_mesh(WorldBlocks.get_chunk_blocks(chunk_position))


func _on_mesh_build_finished(first: bool) -> void:
	mesh_build_finished.emit()
	if first:
		pass


