extends MeshInstance3D

var blocks := PackedInt32Array()
var vertex_counter := 0

var verts := PackedVector3Array()
var indices := PackedInt32Array()
var uvs := PackedVector2Array()
var normals := PackedVector3Array()

var surface_array := []

var chunk_position := Vector3i()

var am := ArrayMesh.new()
var th := Thread.new()


func build_mesh(blx: PackedInt32Array) -> void:
	blocks = blx
	if blocks.size() < 1:
		mesh = null
		return
	
	call_deferred("_build_mesh", blx)


func _exit_tree() -> void:
	th.wait_to_finish()


func _build_mesh(blx: PackedInt32Array) -> void:
	surface_array.clear()
	verts.clear()
	indices.clear()
	uvs.clear()
	normals.clear()
	vertex_counter = 0
	
	for x in Chunk.WIDTH:
		for z in Chunk.WIDTH:
			for y in Chunk.HEIGHT:
				var index := x + Chunk.WIDTH * z + Chunk.AREA * y
				if blocks[index] != 0:
					_add_block_mesh(Vector3i(x, y, z))
	surface_array.resize(Mesh.ARRAY_MAX)
	surface_array[Mesh.ARRAY_VERTEX] = verts
	surface_array[Mesh.ARRAY_INDEX] = indices
	surface_array[Mesh.ARRAY_TEX_UV] = uvs
	surface_array[Mesh.ARRAY_NORMAL] = normals
	if verts.size() < 1: return
	
	am.clear_surfaces()
	am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, surface_array)
	mesh = am
	mesh.surface_set_material(0, preload("res://scenes/test/testmat.tres"))


func _add_block_mesh(xyz: Vector3i) -> void:
	var x := xyz.x
	var y := xyz.y
	var z := xyz.z
	var vc := 0
	
	# bottom
	vc = vertex_counter
	if not _is_solid(x, y - 1, z):
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
	if not _is_solid(x, y + 1, z):
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
	if not _is_solid(x - 1, y, z):
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
	if not _is_solid(x + 1, y, z):
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
	if not _is_solid(x, y, z - 1):
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
	if not _is_solid(x, y, z + 1):
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
	if (x >= Chunk.WIDTH or x < 0) or (y >= Chunk.HEIGHT or y < 0) or (z >= Chunk.WIDTH or z < 0):
		return _get_neighbor_chunk_block(x, y, z) > 0
	#return blocks[x + z * Chunk.WIDTH + y * Chunk.AREA] != 0
	return blocks[x + Chunk.WIDTH * z + Chunk.AREA * y] > 0


func _get_neighbor_chunk_block(x: int, y: int, z: int) -> int:
	var cx := chunk_position.x; var cy := chunk_position.y; var cz := chunk_position.z
	if x >= Chunk.WIDTH:
		return ChunksLoader.get_chunk(cx + 1, cy, cz).get_block(x - Chunk.WIDTH, y, z)
	if x < 0:
		return ChunksLoader.get_chunk(cx - 1, cy, cz).get_block(x + Chunk.WIDTH, y, z)
	if y >= Chunk.HEIGHT:
		return ChunksLoader.get_chunk(cx, cy + 1, cz).get_block(x, y - Chunk.HEIGHT, z)
	if y < 0:
		return ChunksLoader.get_chunk(cx, cy - 1, cz).get_block(x, y + Chunk.HEIGHT, z)
	if z >= Chunk.WIDTH:
		return ChunksLoader.get_chunk(cx, cy, cz + 1).get_block(x, y, z - Chunk.WIDTH)
	if z < 0:
		return ChunksLoader.get_chunk(cx, cy, cz - 1).get_block(x, y, z + Chunk.WIDTH)
	return 0
