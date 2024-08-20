@tool
class_name ChunkMesh extends MeshInstance3D

const VERTS_PER_FACE := 4

const INDEX_APPENDAGE: PackedByteArray = [0, 1, 2, 2, 3, 0]


func _debug_regen() -> void:
	_create_mesh(null)


func create_mesh(chunk_data: ChunkData) -> void:
	_create_mesh(chunk_data)


func _create_mesh(chunk_data: ChunkData) -> void:
	var time := Time.get_ticks_msec()

	# store how many vertices have been appended in total
	var vertex_count := PackedInt32Array()
	vertex_count.append(0)

	mesh = ArrayMesh.new()
	var mesh_array := Array()
	mesh_array.resize(Mesh.ARRAY_MAX)

	mesh_array[Mesh.ARRAY_VERTEX] = PackedVector3Array()
	mesh_array[Mesh.ARRAY_NORMAL] = PackedVector3Array()
	mesh_array[Mesh.ARRAY_INDEX] = PackedInt32Array()

	for y in Chunk.SIZE.y:
		for x in Chunk.SIZE.x:
			for z in Chunk.SIZE.z:
				var bpos := Vector3(x, y, z)
				var idx := ChunkData.pos_to_index(bpos)
				var block := chunk_data.get_block_at(idx)
				if block == 0:
					continue
				_add_block_mesh(bpos, mesh_array, vertex_count, chunk_data)

	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, mesh_array)

	print("meshgen took ", Time.get_ticks_msec() - time)


func _is_side_visible(data: ChunkData, block_position: Vector3, side: Vector3) -> bool:
	return true
	var block_index := ChunkData.pos_to_index(block_position + side)
	if data.get_block_at(block_index) != 0:
		return false
	return true


func _add_block_mesh(block_position: Vector3,
		mesh_array: Array,
		vertex_count: PackedInt32Array,
		chunk_data: ChunkData) -> void:
	var verts: PackedVector3Array = mesh_array[Mesh.ARRAY_VERTEX]
	var normals: PackedVector3Array = mesh_array[Mesh.ARRAY_NORMAL]
	var indices: PackedInt32Array = mesh_array[Mesh.ARRAY_INDEX]

	# NORTH (-Z)
	if _is_side_visible(chunk_data, block_position, Vector3.FORWARD):
		verts.append(Vector3(0, 0, 0) + block_position)
		verts.append(Vector3(1, 0, 0) + block_position)
		verts.append(Vector3(1, 1, 0) + block_position)
		verts.append(Vector3(0, 1, 0) + block_position)
		_add_face_data(Vector3.FORWARD, vertex_count, mesh_array)

	# SOUTH (+Z)
	if _is_side_visible(chunk_data, block_position, Vector3.BACK):
		verts.append(Vector3(1, 0, 1) + block_position)
		verts.append(Vector3(0, 0, 1) + block_position)
		verts.append(Vector3(0, 1, 1) + block_position)
		verts.append(Vector3(1, 1, 1) + block_position)
		_add_face_data(Vector3.BACK, vertex_count, mesh_array)

	# WEST (-X)
	if _is_side_visible(chunk_data, block_position, Vector3.LEFT):
		verts.append(Vector3(0, 0, 1) + block_position)
		verts.append(Vector3(0, 0, 0) + block_position)
		verts.append(Vector3(0, 1, 0) + block_position)
		verts.append(Vector3(0, 1, 1) + block_position)
		_add_face_data(Vector3.LEFT, vertex_count, mesh_array)

	# EAST (+X)
	if _is_side_visible(chunk_data, block_position, Vector3.RIGHT):
		verts.append(Vector3(1, 0, 0) + block_position)
		verts.append(Vector3(1, 0, 1) + block_position)
		verts.append(Vector3(1, 1, 1) + block_position)
		verts.append(Vector3(1, 1, 0) + block_position)
		_add_face_data(Vector3.RIGHT, vertex_count, mesh_array)

	# BOTTOM (-Y)
	if _is_side_visible(chunk_data, block_position, Vector3.DOWN):
		verts.append(Vector3(1, 0, 0) + block_position)
		verts.append(Vector3(0, 0, 0) + block_position)
		verts.append(Vector3(0, 0, 1) + block_position)
		verts.append(Vector3(1, 0, 1) + block_position)
		_add_face_data(Vector3.DOWN, vertex_count, mesh_array)

	# TOP (+Y)
	if _is_side_visible(chunk_data, block_position, Vector3.UP):
		verts.append(Vector3(0, 1, 0) + block_position)
		verts.append(Vector3(1, 1, 0) + block_position)
		verts.append(Vector3(1, 1, 1) + block_position)
		verts.append(Vector3(0, 1, 1) + block_position)
		_add_face_data(Vector3.UP, vertex_count, mesh_array)


func _add_face_data(
		normal_direction: Vector3,
		vertex_count: PackedInt32Array,
		mesh_array: Array
		) -> void:
	var normals: PackedVector3Array = mesh_array[Mesh.ARRAY_NORMAL]
	var indices: PackedInt32Array = mesh_array[Mesh.ARRAY_INDEX]
	var cvs := vertex_count[0]
	for ix in INDEX_APPENDAGE:
		indices.append(ix + cvs)
	normals.append(normal_direction)
	normals.append(normal_direction)
	normals.append(normal_direction)
	normals.append(normal_direction)
	vertex_count[0] += 4
