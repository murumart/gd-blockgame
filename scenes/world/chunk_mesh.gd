extends MeshInstance3D

signal mesh_build_finished(first: bool)

var mesh_built_previously := false

var blocks := PackedInt32Array()
var vertex_counter := 0

var verts := PackedVector3Array()
var indices := PackedInt32Array()
var uvs := PackedVector2Array()
var normals := PackedVector3Array()

var surface_array := []

var chunk_position := Vector3i()

var am := ArrayMesh.new()


func build_mesh(blx: PackedInt32Array) -> void:
	blocks = blx
	if blocks.size() < 1:
		mesh = null
		return
	
	call_deferred("_build_mesh")


func _build_mesh() -> void:
	surface_array.clear()
	verts.clear()
	indices.clear()
	uvs.clear()
	normals.clear()
	vertex_counter = 0
	
	for x in Chunk.WIDTH:
		# """multithreading"""
		if x % 2 == 0: await get_tree().process_frame
		for z in Chunk.WIDTH:
			for y in Chunk.HEIGHT:
				var index := x + Chunk.WIDTH * z + Chunk.AREA * y
				if blocks[index] != 0:
					#call_deferred("_add_block_mesh", Vector3i(x, y, z))
					_add_block_mesh(Vector3i(x, y, z))
	surface_array.resize(Mesh.ARRAY_MAX)
	surface_array[Mesh.ARRAY_VERTEX] = verts
	surface_array[Mesh.ARRAY_INDEX] = indices
	surface_array[Mesh.ARRAY_TEX_UV] = uvs
	surface_array[Mesh.ARRAY_NORMAL] = normals
	if verts.size() < 1: return
	
	am.clear_surfaces()
	am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, surface_array)
	call_deferred(
		"emit_signal", "mesh_build_finished",
		not mesh_built_previously)
	mesh = am
	mesh.surface_set_material(0,
		preload("res://scenes/test/testmat.tres"))
	mesh_built_previously = true


func _add_block_mesh(xyz: Vector3i) -> void:
	var x := xyz.x
	var y := xyz.y
	var z := xyz.z
	var gx := chunk_position.x * Chunk.WIDTH + x
	var gy := chunk_position.y * Chunk.HEIGHT + y
	var gz := chunk_position.z * Chunk.WIDTH + z
	var vc := 0
	
	# bottom
	vc = vertex_counter
	if not _is_solid(gx, gy - 1, gz):
		verts.append_array([
			Vector3(0 + x, 0 + y, 0 + z), # 0
			Vector3(1 + x, 0 + y, 0 + z), # 1
			Vector3(1 + x, 0 + y, 1 + z), # 2
			Vector3(0 + x, 0 + y, 1 + z), # 3
		])
		indices.append_array([0 + vc, 3 + vc, 2 + vc, 2 + vc, 1 + vc, 0 + vc])
		vertex_counter += 4
		uvs.append_array([Vector2(0, 1), Vector2(1, 1), Vector2(1, 0), Vector2(0, 0)])
		normals.append_array([
			Vector3(0, -1, 0),
			Vector3(0, -1, 0),
			Vector3(0, -1, 0),
			Vector3(0, -1, 0),
		])
	
	# top
	vc = vertex_counter
	if not _is_solid(gx, gy + 1, gz):
		verts.append_array([
			Vector3(0 + x, 1 + y, 0 + z), # 0
			Vector3(1 + x, 1 + y, 0 + z), # 1
			Vector3(1 + x, 1 + y, 1 + z), # 2 
			Vector3(0 + x, 1 + y, 1 + z), # 3
		])
		indices.append_array([0 + vc, 1 + vc, 2 + vc, 2 + vc, 3 + vc, 0 + vc])
		vertex_counter += 4
		uvs.append_array([Vector2(0, 0), Vector2(1, 0), Vector2(1, 1),Vector2(0, 1)])
		normals.append_array([
			Vector3(0, 1, 0),
			Vector3(0, 1, 0),
			Vector3(0, 1, 0),
			Vector3(0, 1, 0),
		])
	
	# left
	vc = vertex_counter
	if not _is_solid(gx - 1, gy, gz):
		verts.append_array([
			Vector3(0 + x, 0 + y, 0 + z), # 0
			Vector3(0 + x, 1 + y, 0 + z), # 1
			Vector3(0 + x, 1 + y, 1 + z), # 2
			Vector3(0 + x, 0 + y, 1 + z), # 3
		])
		indices.append_array([0 + vc, 1 + vc, 2 + vc, 2 + vc, 3 + vc, 0 + vc])
		vertex_counter += 4
		uvs.append_array([Vector2(1, 1), Vector2(1, 0), Vector2(0, 0),Vector2(0, 1)])
		normals.append_array([
			Vector3(-1, 0, 0),
			Vector3(-1, 0, 0),
			Vector3(-1, 0, 0),
			Vector3(-1, 0, 0),
		])
	
	# right
	vc = vertex_counter
	if not _is_solid(gx + 1, gy, gz):
		verts.append_array([
			Vector3(1 + x, 0 + y, 0 + z), # 0
			Vector3(1 + x, 0 + y, 1 + z), # 1
			Vector3(1 + x, 1 + y, 1 + z), # 2
			Vector3(1 + x, 1 + y, 0 + z), # 3
		])
		indices.append_array([0 + vc, 1 + vc, 2 + vc, 2 + vc, 3 + vc, 0 + vc])
		vertex_counter += 4
		uvs.append_array([Vector2(1, 1), Vector2(0, 1), Vector2(0, 0), Vector2(1, 0)])
		normals.append_array([
			Vector3(1, 0, 0),
			Vector3(1, 0, 0),
			Vector3(1, 0, 0),
			Vector3(1, 0, 0),
		])
	
	# back
	vc = vertex_counter
	if not _is_solid(gx, gy, gz - 1):
		verts.append_array([
			Vector3(0 + x, 0 + y, 0 + z), # 0
			Vector3(1 + x, 0 + y, 0 + z), # 1
			Vector3(1 + x, 1 + y, 0 + z), # 2
			Vector3(0 + x, 1 + y, 0 + z), # 3
		])
		indices.append_array([0 + vc, 1 + vc, 2 + vc, 2 + vc, 3 + vc, 0 + vc])
		vertex_counter += 4
		uvs.append_array([Vector2(1, 1), Vector2(0, 1), Vector2(0, 0),Vector2(1, 0)])
		normals.append_array([
			Vector3(0, 0, -1),
			Vector3(0, 0, -1),
			Vector3(0, 0, -1),
			Vector3(0, 0, -1),
		])
	
	# front
	vc = vertex_counter
	if not _is_solid(gx, gy, gz + 1):
		verts.append_array([
			Vector3(0 + x, 0 + y, 1 + z), # 0
			Vector3(0 + x, 1 + y, 1 + z), # 1
			Vector3(1 + x, 1 + y, 1 + z), # 2
			Vector3(1 + x, 0 + y, 1 + z), # 3
		])
		indices.append_array([0 + vc, 1 + vc, 2 + vc, 2 + vc, 3 + vc, 0 + vc])
		vertex_counter += 4
		uvs.append_array([Vector2(0, 1), Vector2(0, 0), Vector2(1, 0), Vector2(1, 1)])
		normals.append_array([
			Vector3(0, 0, 1),
			Vector3(0, 0, 1),
			Vector3(0, 0, 1),
			Vector3(0, 0, 1),
		])


func _is_solid(x: int, y: int, z: int) -> bool:
	#var pos := Vector3i(x, y, z)
	#var cpos := WorldBlocks.is_in_which_chunk(pos)
	#return WorldBlocks._get_block(cpos,
	#		WorldBlocks.to_in_chunk_position(pos, cpos)) > 0
	return WorldBlocks.get_block(x, y, z) > 0

