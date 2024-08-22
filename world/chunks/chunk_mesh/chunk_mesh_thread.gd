class_name ChunkMeshThread

var _thread := Thread.new()
var _semaph := Semaphore.new()
var _mutex := Mutex.new()
var active := false

var _current_mesh_instance: ChunkMesh
var _current_chunk_data: ChunkData
var _current_world: World
var _current_global_position: Vector3


func _init() -> void:
	_thread.start(_threaded_meshing)


func generate_mesh(mi: ChunkMesh, w: World, cd: ChunkData) -> bool:
	if active:
		return false
	_current_mesh_instance = mi
	_current_chunk_data = cd
	_current_world = w
	_current_global_position = mi.global_position
	active = true
	_semaph.post()
	return true


func _threaded_meshing() -> void:
	while true:
		print("-- MESH waiting")
		_semaph.wait()
		print("-- MESH genning")

		var mesh := ArrayMesh.new()
		ChunkMeshThread.create_mesh(
				mesh, _current_chunk_data, _current_world, _current_global_position)
		_current_mesh_instance._mesh_thread_finished.call_deferred(mesh)
		_current_chunk_data = null
		_current_global_position = Vector3.ZERO
		_current_mesh_instance = null
		_current_world = null
		active = false


static func create_mesh(
		mesh: ArrayMesh,
		chunk_data: ChunkData,
		world: World,
		global_position: Vector3) -> void:
	var time := Time.get_ticks_msec()

	if chunk_data.block_data.size() == ChunkData.BYTES_PER_BLOCK:
		return

	var mesh_array := _create_mesh_data_array(chunk_data, world, global_position)

	if mesh_array[Mesh.ARRAY_VERTEX].is_empty():
		return
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, mesh_array)
	mesh.surface_set_material(0, ChunkMesh.BLOCK_MATERIAL)
	print("meshgen took ", Time.get_ticks_msec() - time)


static func _create_mesh_data_array(
		chunk_data: ChunkData,
		world: World,
		global_position: Vector3) -> Array:
	# store how many vertices have been appended in total
	var vertex_count := PackedInt32Array()
	vertex_count.append(0)

	var mesh_array := Array()
	mesh_array.resize(Mesh.ARRAY_MAX)

	mesh_array[Mesh.ARRAY_VERTEX] = PackedVector3Array()
	mesh_array[Mesh.ARRAY_NORMAL] = PackedVector3Array()
	mesh_array[Mesh.ARRAY_INDEX] = PackedInt32Array()
	mesh_array[Mesh.ARRAY_TEX_UV] = PackedVector2Array()

	for y in Chunk.SIZE.y:
		for x in Chunk.SIZE.x:
			for z in Chunk.SIZE.z:
				var bpos := Vector3(x, y, z)
				_add_block_mesh(bpos, mesh_array, vertex_count, chunk_data, world, global_position)

	return mesh_array


static func _add_block_mesh(block_position: Vector3,
		mesh_array: Array,
		vertex_count: PackedInt32Array,
		chunk_data: ChunkData,
		world: World,
		global_position: Vector3) -> void:
	var verts: PackedVector3Array = mesh_array[Mesh.ARRAY_VERTEX]
	var block_type := chunk_data.get_block_type_from_pos(block_position)
	if block_type.mesh_type == BlockType.MeshType.NONE:
		return

	# NORTH (-Z)
	if _is_side_visible(chunk_data, block_position, Vector3.FORWARD, world, global_position):
		verts.append(Vector3(0, 0, 0) + block_position)
		verts.append(Vector3(1, 0, 0) + block_position)
		verts.append(Vector3(1, 1, 0) + block_position)
		verts.append(Vector3(0, 1, 0) + block_position)
		_add_face_data(Vector3.FORWARD, vertex_count, mesh_array, block_type)

	# SOUTH (+Z)
	if _is_side_visible(chunk_data, block_position, Vector3.BACK, world, global_position):
		verts.append(Vector3(1, 0, 1) + block_position)
		verts.append(Vector3(0, 0, 1) + block_position)
		verts.append(Vector3(0, 1, 1) + block_position)
		verts.append(Vector3(1, 1, 1) + block_position)
		_add_face_data(Vector3.BACK, vertex_count, mesh_array, block_type)

	# WEST (-X)
	if _is_side_visible(chunk_data, block_position, Vector3.LEFT, world, global_position):
		verts.append(Vector3(0, 0, 1) + block_position)
		verts.append(Vector3(0, 0, 0) + block_position)
		verts.append(Vector3(0, 1, 0) + block_position)
		verts.append(Vector3(0, 1, 1) + block_position)
		_add_face_data(Vector3.LEFT, vertex_count, mesh_array, block_type)

	# EAST (+X)
	if _is_side_visible(chunk_data, block_position, Vector3.RIGHT, world, global_position):
		verts.append(Vector3(1, 0, 0) + block_position)
		verts.append(Vector3(1, 0, 1) + block_position)
		verts.append(Vector3(1, 1, 1) + block_position)
		verts.append(Vector3(1, 1, 0) + block_position)
		_add_face_data(Vector3.RIGHT, vertex_count, mesh_array, block_type)

	# BOTTOM (-Y)
	if _is_side_visible(chunk_data, block_position, Vector3.DOWN, world, global_position):
		verts.append(Vector3(1, 0, 0) + block_position)
		verts.append(Vector3(0, 0, 0) + block_position)
		verts.append(Vector3(0, 0, 1) + block_position)
		verts.append(Vector3(1, 0, 1) + block_position)
		_add_face_data(Vector3.DOWN, vertex_count, mesh_array, block_type)

	# TOP (+Y)
	if _is_side_visible(chunk_data, block_position, Vector3.UP, world, global_position):
		verts.append(Vector3(0, 1, 0) + block_position)
		verts.append(Vector3(1, 1, 0) + block_position)
		verts.append(Vector3(1, 1, 1) + block_position)
		verts.append(Vector3(0, 1, 1) + block_position)
		_add_face_data(Vector3.UP, vertex_count, mesh_array, block_type)


static func _is_side_visible(
		data: ChunkData,
		block_position: Vector3,
		side: Vector3,
		world: World,
		global_position: Vector3) -> bool:
	var check_position := block_position + side
	var check_block_id: int
	var check_block_type: BlockType
	if (check_position.x >= Chunk.SIZE.x or check_position.x < 0
			or check_position.y >= Chunk.SIZE.y or check_position.y < 0
			or check_position.z >= Chunk.SIZE.z or check_position.z < 0):
		if not is_instance_valid(world):
			return true
		check_block_id = world.get_block(check_position + global_position)
		if check_block_id == BlockTypes.INVALID_BLOCK_ID:
			return true
		check_block_type = BlockTypes.get_block(check_block_id)
	else:
		check_block_type = data.get_block_type_from_pos(check_position)
	if check_block_type.mesh_type != BlockType.MeshType.NONE:
		return false
	return true


static func _add_face_data(
		normal_direction: Vector3,
		vertex_count: PackedInt32Array,
		mesh_array: Array,
		block_type: BlockType) -> void:
	var normals: PackedVector3Array = mesh_array[Mesh.ARRAY_NORMAL]
	var uvs: PackedVector2Array = mesh_array[Mesh.ARRAY_TEX_UV]
	var indices: PackedInt32Array = mesh_array[Mesh.ARRAY_INDEX]
	var cvs := vertex_count[0]
	for ix in ChunkMesh.INDEX_APPENDAGE:
		indices.append(ix + cvs)
	normals.append(normal_direction)
	normals.append(normal_direction)
	normals.append(normal_direction)
	normals.append(normal_direction)
	var block_atlas_coord: Vector2
	if block_type.mesh_type == BlockType.MeshType.ALL_ONE:
		block_atlas_coord = block_type.atlas_coordinates[0]
	elif block_type.mesh_type == BlockType.MeshType.SIX_SIDES:
		block_atlas_coord = block_type.atlas_coordinates[ChunkMesh.NORMAL_TO_DIRECTION[normal_direction]]
	block_atlas_coord *= ChunkMesh.BLOCK_TEXTURE_UV_SIZE
	uvs.append(Vector2(
			ChunkMesh.BLOCK_TEXTURE_UV_SIZE + block_atlas_coord.x,
			ChunkMesh.BLOCK_TEXTURE_UV_SIZE + block_atlas_coord.y))
	uvs.append(Vector2(
			block_atlas_coord.x,
			ChunkMesh.BLOCK_TEXTURE_UV_SIZE + block_atlas_coord.y))
	uvs.append(block_atlas_coord)
	uvs.append(Vector2(
			ChunkMesh.BLOCK_TEXTURE_UV_SIZE + block_atlas_coord.x,
			block_atlas_coord.y))
	#uvs.append(Vector2(BLOCK_TEXTURE_UV_SIZE, BLOCK_TEXTURE_UV_SIZE))
	#uvs.append(Vector2(0.0, BLOCK_TEXTURE_UV_SIZE))
	#uvs.append(Vector2(0.0, 0.0))
	#uvs.append(Vector2(BLOCK_TEXTURE_UV_SIZE, 0.0))
	vertex_count[0] += 4
