class_name ChunkMesh extends MeshInstance3D

## Generates the mesh of a chunk.

signal meshing_finished

const VERTS_PER_FACE := 4
const INDEX_APPENDAGE: PackedByteArray = [0, 1, 2, 2, 3, 0]

const BLOCK_MATERIAL := preload("res://world/blocks/block_material.tres")
const BLOCK_TEXTURE_SIZE := 16.0
const BLOCK_ATLAS_SIZE := 16 * 16 ## The size of the block atlas texture, in pixels.
const BLOCK_TEXTURE_UV_SIZE := 1 / BLOCK_TEXTURE_SIZE
const NORMAL_TO_DIRECTION := {
	Vector3.FORWARD: 0,
	Vector3.BACK: 1,
	Vector3.LEFT: 2,
	Vector3.RIGHT: 3,
	Vector3.DOWN: 4,
	Vector3.UP: 5,
}

static var chunk_mesh_threads: Array[ChunkMeshThread] = [
	ChunkMeshThread.new(),
	ChunkMeshThread.new(),

]
var worldless_mesh := true


func create_mesh(chunk_data: ChunkData, world: World) -> void:
	mesh = ArrayMesh.new()
	assert(not chunk_data.block_data.is_empty())
	_create_mesh(chunk_data, world)


func create_mesh_thread(chunk_data: ChunkData, world: World) -> bool:
	#return chunk_mesh_threads[0].generate_mesh(self, world, chunk_data)
	for thread in chunk_mesh_threads:
		if thread.generate_mesh(self, world, chunk_data):
			return true
	return false


func _mesh_thread_finished(new_mesh: ArrayMesh) -> void:
	mesh = new_mesh
	meshing_finished.emit()


func _create_mesh(chunk_data: ChunkData, world: World) -> void:
	var time := Time.get_ticks_msec()

	if chunk_data.block_data.size() == ChunkData.BYTES_PER_BLOCK:
		return

	var mesh_array := _create_mesh_data_array(chunk_data, world)

	if mesh_array[Mesh.ARRAY_VERTEX].is_empty():
		return
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, mesh_array)
	mesh.surface_set_material(0, BLOCK_MATERIAL)
	print("meshgen took ", Time.get_ticks_msec() - time)


func _create_mesh_data_array(chunk_data: ChunkData, world: World) -> Array:
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
				_add_block_mesh(bpos, mesh_array, vertex_count, chunk_data, world)

	return mesh_array


func _is_side_visible(
		data: ChunkData,
		block_position: Vector3,
		side: Vector3,
		world: World) -> bool:
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


func _add_block_mesh(block_position: Vector3,
		mesh_array: Array,
		vertex_count: PackedInt32Array,
		chunk_data: ChunkData,
		world: World) -> void:
	var verts: PackedVector3Array = mesh_array[Mesh.ARRAY_VERTEX]
	var block_type := chunk_data.get_block_type_from_pos(block_position)
	if block_type.mesh_type == BlockType.MeshType.NONE:
		return

	# NORTH (-Z)
	if _is_side_visible(chunk_data, block_position, Vector3.FORWARD, world):
		verts.append(Vector3(0, 0, 0) + block_position)
		verts.append(Vector3(1, 0, 0) + block_position)
		verts.append(Vector3(1, 1, 0) + block_position)
		verts.append(Vector3(0, 1, 0) + block_position)
		_add_face_data(Vector3.FORWARD, vertex_count, mesh_array, block_type)

	# SOUTH (+Z)
	if _is_side_visible(chunk_data, block_position, Vector3.BACK, world):
		verts.append(Vector3(1, 0, 1) + block_position)
		verts.append(Vector3(0, 0, 1) + block_position)
		verts.append(Vector3(0, 1, 1) + block_position)
		verts.append(Vector3(1, 1, 1) + block_position)
		_add_face_data(Vector3.BACK, vertex_count, mesh_array, block_type)

	# WEST (-X)
	if _is_side_visible(chunk_data, block_position, Vector3.LEFT, world):
		verts.append(Vector3(0, 0, 1) + block_position)
		verts.append(Vector3(0, 0, 0) + block_position)
		verts.append(Vector3(0, 1, 0) + block_position)
		verts.append(Vector3(0, 1, 1) + block_position)
		_add_face_data(Vector3.LEFT, vertex_count, mesh_array, block_type)

	# EAST (+X)
	if _is_side_visible(chunk_data, block_position, Vector3.RIGHT, world):
		verts.append(Vector3(1, 0, 0) + block_position)
		verts.append(Vector3(1, 0, 1) + block_position)
		verts.append(Vector3(1, 1, 1) + block_position)
		verts.append(Vector3(1, 1, 0) + block_position)
		_add_face_data(Vector3.RIGHT, vertex_count, mesh_array, block_type)

	# BOTTOM (-Y)
	if _is_side_visible(chunk_data, block_position, Vector3.DOWN, world):
		verts.append(Vector3(1, 0, 0) + block_position)
		verts.append(Vector3(0, 0, 0) + block_position)
		verts.append(Vector3(0, 0, 1) + block_position)
		verts.append(Vector3(1, 0, 1) + block_position)
		_add_face_data(Vector3.DOWN, vertex_count, mesh_array, block_type)

	# TOP (+Y)
	if _is_side_visible(chunk_data, block_position, Vector3.UP, world):
		verts.append(Vector3(0, 1, 0) + block_position)
		verts.append(Vector3(1, 1, 0) + block_position)
		verts.append(Vector3(1, 1, 1) + block_position)
		verts.append(Vector3(0, 1, 1) + block_position)
		_add_face_data(Vector3.UP, vertex_count, mesh_array, block_type)


func _add_face_data(
		normal_direction: Vector3,
		vertex_count: PackedInt32Array,
		mesh_array: Array,
		block_type: BlockType) -> void:
	var normals: PackedVector3Array = mesh_array[Mesh.ARRAY_NORMAL]
	var uvs: PackedVector2Array = mesh_array[Mesh.ARRAY_TEX_UV]
	var indices: PackedInt32Array = mesh_array[Mesh.ARRAY_INDEX]
	var cvs := vertex_count[0]
	for ix in INDEX_APPENDAGE:
		indices.append(ix + cvs)
	normals.append(normal_direction)
	normals.append(normal_direction)
	normals.append(normal_direction)
	normals.append(normal_direction)
	var block_atlas_coord: Vector2
	if block_type.mesh_type == BlockType.MeshType.ALL_ONE:
		block_atlas_coord = block_type.atlas_coordinates[0]
	elif block_type.mesh_type == BlockType.MeshType.SIX_SIDES:
		block_atlas_coord = block_type.atlas_coordinates[NORMAL_TO_DIRECTION[normal_direction]]
	block_atlas_coord *= BLOCK_TEXTURE_UV_SIZE
	uvs.append(Vector2(
			BLOCK_TEXTURE_UV_SIZE + block_atlas_coord.x,
			BLOCK_TEXTURE_UV_SIZE + block_atlas_coord.y))
	uvs.append(Vector2(
			block_atlas_coord.x,
			BLOCK_TEXTURE_UV_SIZE + block_atlas_coord.y))
	uvs.append(block_atlas_coord)
	uvs.append(Vector2(
			BLOCK_TEXTURE_UV_SIZE + block_atlas_coord.x,
			block_atlas_coord.y))
	#uvs.append(Vector2(BLOCK_TEXTURE_UV_SIZE, BLOCK_TEXTURE_UV_SIZE))
	#uvs.append(Vector2(0.0, BLOCK_TEXTURE_UV_SIZE))
	#uvs.append(Vector2(0.0, 0.0))
	#uvs.append(Vector2(BLOCK_TEXTURE_UV_SIZE, 0.0))
	vertex_count[0] += 4
