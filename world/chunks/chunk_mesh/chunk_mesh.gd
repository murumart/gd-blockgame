@tool
extends MeshInstance3D

const VERTICES_PER_BLOCK := 8
const FACES_PER_BLOCK := 6
const INDICES_PER_FACE := 6
const INDICES_PER_BLOCK := INDICES_PER_FACE * FACES_PER_BLOCK

#		   3_______2
#		  /|	  /|
#		 / |	 / |
#		4__0____7__1
#		|  /	|  /
#		| /		| /
#		5/______6/

const VERTEX_INDICES: PackedByteArray = [
	# NORTH (-Z)
	0, 1, 2, 2, 3, 0,
	# SOUTH (+Z)
	5, 4, 7, 7, 6, 5,
	# EAST (+X)
	6, 7, 2, 2, 1, 6,
	# WEST (-X)
	0, 3, 4, 4, 5, 0, 
	# TOP (+Y)
	3, 2, 7, 7, 4, 3, 
	# BOTTOM (-Y)
	5, 6, 1, 1, 0, 5
]

const VERTEX_NORMALS: PackedVector3Array = [
	Vector3(-0.57735, -0.57735, -0.57735),
	Vector3(0.57735, -0.57735, -0.57735),
	Vector3(0.57735, 0.57735, -0.57735),
	Vector3(-0.57735, 0.57735, -0.57735),
	Vector3(0.57735, 0.57735, 0.57735),
	Vector3(-0.57735, -0.57735, 0.57735),
	Vector3(0.57735, -0.57735, 0.57735),
	Vector3(0.57735, 0.57735, 0.57735),
]

const VERTEX_POSITIONS: PackedVector3Array = [
	Vector3(0, 0, 0), # 0
	Vector3(1, 0, 0), # 1
	Vector3(1, 1, 0), # 2
	Vector3(0, 1, 0), # 3 
	Vector3(0, 1, 1), # 4
	Vector3(0, 0, 1), # 5 
	Vector3(1, 0, 1), # 6
	Vector3(1, 1, 1), # 7
]

var chunk_size := Vector3i(16, 16, 16) # DEBUG


@export var _debug_regenerate: bool:
	set(to):
		_debug_regen()


func _debug_regen() -> void:
	_create_mesh()


func _create_mesh() -> void:
	var time := Time.get_ticks_msec()
	var AM := ArrayMesh
	mesh = AM.new()
	
	var mesh_array := []
	mesh_array.resize(AM.ARRAY_MAX)
	
	var vertex_array := PackedVector3Array()
	vertex_array.resize(
			chunk_size.x * chunk_size.y * chunk_size.z * VERTICES_PER_BLOCK)
	var normal_array := PackedVector3Array()
	# one normal per vertex
	normal_array.resize(vertex_array.size())
	var uv_array := PackedVector2Array()
	var index_array := PackedInt32Array()
	index_array.resize(
			chunk_size.x * chunk_size.y * chunk_size.z
			* INDICES_PER_BLOCK)
	
	for y in chunk_size.y:
		for x in chunk_size.x:
			for z in chunk_size.z:
				var bpos := Vector3(x, y, z)
				_create_block_mesh(bpos, vertex_array, index_array, normal_array)
	
	mesh_array[AM.ARRAY_VERTEX] = vertex_array
	mesh_array[AM.ARRAY_NORMAL] = normal_array
	#mesh_array[AM.ARRAY_TEX_UV] = uv_array
	mesh_array[AM.ARRAY_INDEX] = index_array
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, mesh_array)
	print("meshgen took ", Time.get_ticks_msec() - time)


func _create_block_mesh(
		block_position: Vector3,
		vertex_array: PackedVector3Array,
		index_array: PackedInt32Array,
		normal_array: PackedVector3Array) -> void:
	
	var block_index := int(
			block_position.y
			+ block_position.z * chunk_size.y
			+ block_position.x * chunk_size.z * chunk_size.y)
	var base_vertex_index := block_index * VERTICES_PER_BLOCK
	var base_index_index := block_index * INDICES_PER_BLOCK
	#print("block ix: ", block_index)
	#print("vertex ix: ", base_vertex_index)
	#print("index ix: ", base_index_index)
	
	# add all possible vertices of block
	for ix in VERTICES_PER_BLOCK:
		vertex_array[base_vertex_index + ix] = VERTEX_POSITIONS[ix] + block_position
		normal_array[base_vertex_index + ix] = VERTEX_NORMALS[ix]
	
	# create sides of block
	for ix in INDICES_PER_BLOCK:
		index_array[base_index_index + ix] = VERTEX_INDICES[ix] + base_vertex_index
		#index_array.append(ix + base_vertex_index)
