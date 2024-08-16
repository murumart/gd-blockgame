@tool
extends MeshInstance3D

const VERTS_PER_FACE := 4

const INDEX_APPENDAGE: PackedByteArray = [0, 1, 2, 2, 3, 0]

var chunk_size := Vector3i(16, 16, 16) # DEBUG


@export var _debug_regenerate: bool:
	set(to):
		_debug_regen()


func _debug_regen() -> void:
	_create_mesh()


func _create_mesh() -> void:
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
	
	for y in chunk_size.y:
		for x in chunk_size.x:
			for z in chunk_size.z:
				var bpos := Vector3(x, y, z)
				_add_block_mesh(bpos, mesh_array, vertex_count)
	
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, mesh_array)
	
	print("meshgen took ", Time.get_ticks_msec() - time)


func _add_block_mesh(block_position: Vector3,
		mesh_array: Array,
		vertex_count: PackedInt32Array) -> void:
	var verts: PackedVector3Array = mesh_array[Mesh.ARRAY_VERTEX]
	var normals: PackedVector3Array = mesh_array[Mesh.ARRAY_NORMAL]
	var indices: PackedInt32Array = mesh_array[Mesh.ARRAY_INDEX]
	
	# NORTH (-Z)
	verts.append(Vector3(0, 0, 0) + block_position)
	verts.append(Vector3(1, 0, 0) + block_position)
	verts.append(Vector3(1, 1, 0) + block_position)
	verts.append(Vector3(0, 1, 0) + block_position)
	_add_face_data(Vector3.FORWARD, vertex_count, mesh_array)
	
	# SOUTH (+Z)
	verts.append(Vector3(1, 0, 1) + block_position)
	verts.append(Vector3(0, 0, 1) + block_position)
	verts.append(Vector3(0, 1, 1) + block_position)
	verts.append(Vector3(1, 1, 1) + block_position)
	_add_face_data(Vector3.BACK, vertex_count, mesh_array)
	
	# WEST (-X)
	verts.append(Vector3(0, 0, 1) + block_position)
	verts.append(Vector3(0, 0, 0) + block_position)
	verts.append(Vector3(0, 1, 0) + block_position)
	verts.append(Vector3(0, 1, 1) + block_position)
	_add_face_data(Vector3.LEFT, vertex_count, mesh_array)
	
	# EAST (+X)
	verts.append(Vector3(1, 0, 0) + block_position)
	verts.append(Vector3(1, 0, 1) + block_position)
	verts.append(Vector3(1, 1, 1) + block_position)
	verts.append(Vector3(1, 1, 0) + block_position)
	_add_face_data(Vector3.RIGHT, vertex_count, mesh_array)
	
	# BOTTOM (-Y)
	verts.append(Vector3(1, 0, 0) + block_position)
	verts.append(Vector3(0, 0, 0) + block_position)
	verts.append(Vector3(0, 0, 1) + block_position)
	verts.append(Vector3(1, 0, 1) + block_position)
	_add_face_data(Vector3.DOWN, vertex_count, mesh_array)
	
	# TOP (+Y)
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
	var cix := indices.size() - 1
	indices.resize(indices.size() + 6)
	indices[cix + 0] = 0 + cvs
	indices[cix + 1] = 1 + cvs
	indices[cix + 2] = 2 + cvs
	indices[cix + 3] = 2 + cvs
	indices[cix + 4] = 3 + cvs
	indices[cix + 5] = 0 + cvs
	#indices.append(0 + cvs)
	#indices.append(1 + cvs)
	#indices.append(2 + cvs)
	#indices.append(2 + cvs)
	#indices.append(3 + cvs)
	#indices.append(0 + cvs)
	#for ix in INDEX_APPENDAGE:
		#indices.append(ix + cvs)
	normals.append(normal_direction)
	normals.append(normal_direction)
	normals.append(normal_direction)
	normals.append(normal_direction)
	vertex_count[0] += 4
