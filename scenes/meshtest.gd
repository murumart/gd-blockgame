@tool
extends MeshInstance3D

@export var reload_mesh: bool:
	set(_to):
		_mesh_gen()


func _ready() -> void:
	pass


func _physics_process(_delta: float) -> void:
	var bpos := Vector3i($"../Camera3D".global_position)
	var cpos := WorldBlocks.is_in_which_chunk(bpos)
	var w_cpos := World._player_chunk_position()
	$Control/Label.text = str(
		"fps: ", Engine.get_frames_per_second(),
		"\nposition: ", bpos,
		"\nfullpos: ", $"../Camera3D".global_position.round(),
		"\nchunk: ", cpos,
		"\nchunk_world: ", w_cpos,
		)


func _mesh_gen():
	var am := ArrayMesh.new()
	
	var surface_array := []
	surface_array.resize(Mesh.ARRAY_MAX)
	
	var verts := PackedVector3Array()
	var uvs := PackedVector2Array()
	var normals := PackedVector3Array()
	var indices := PackedInt32Array()
	
	verts.append_array([
		# bottom
		Vector3(0, 0, 0), # 0
		Vector3(1, 0, 0), # 1
		Vector3(1, 0, 1), # 2
		Vector3(0, 0, 1), # 3
		# top
		Vector3(0, 1, 0), # 4
		Vector3(1, 1, 0), # 5
		Vector3(1, 1, 1), # 6
		Vector3(0, 1, 1), # 7
		# left
		Vector3(0, 0, 0), # 8
		Vector3(0, 1, 0), # 9
		Vector3(0, 1, 1), # 10
		Vector3(0, 0, 1), # 11
		# right
		Vector3(1, 0, 0), # 12
		Vector3(1, 0, 1), # 13
		Vector3(1, 1, 1), # 14
		Vector3(1, 1, 0), # 15
		# back
		Vector3(0, 0, 0), # 16
		Vector3(1, 0, 0), # 17
		Vector3(1, 1, 0), # 18
		Vector3(0, 1, 0), # 19
		# front
		Vector3(0, 0, 1), # 20
		Vector3(0, 1, 1), # 21
		Vector3(1, 1, 1), # 22
		Vector3(1, 0, 1), # 23
	])
	
	indices.append_array([
		# bottom
		0, 3, 2, 2, 1, 0,
		# top
		4, 5, 6, 6, 7, 4,
		# left
		8, 9, 10, 10, 11, 8,
		# right
		12, 13, 14, 14, 15, 12,
		# back
		16, 17, 18, 18, 19, 16,
		# front
		20, 21, 22, 22, 23, 20
	])
	
	uvs.append_array([
		# bottom
		Vector2(0, 1),
		Vector2(1, 1),
		Vector2(1, 0),
		Vector2(0, 0),
		# top
		Vector2(0, 0),
		Vector2(1, 0),
		Vector2(1, 1),
		Vector2(0, 1),
		# left
		Vector2(1, 1),
		Vector2(1, 0),
		Vector2(0, 0),
		Vector2(0, 1),
		# right
		Vector2(1, 1),
		Vector2(0, 1),
		Vector2(0, 0),
		Vector2(1, 0),
		# back
		Vector2(1, 1),
		Vector2(0, 1),
		Vector2(0, 0),
		Vector2(1, 0),
		# front
		Vector2(0, 1),
		Vector2(0, 0),
		Vector2(1, 0),
		Vector2(1, 1)
	])
	
	normals.append_array([
		# bottom
		Vector3(0, -1, 0),
		Vector3(0, -1, 0),
		Vector3(0, -1, 0),
		Vector3(0, -1, 0),
		# top
		Vector3(0, 1, 0),
		Vector3(0, 1, 0),
		Vector3(0, 1, 0),
		Vector3(0, 1, 0),
		# left
		Vector3(-1, 0, 0),
		Vector3(-1, 0, 0),
		Vector3(-1, 0, 0),
		Vector3(-1, 0, 0),
		# right
		Vector3(1, 0, 0),
		Vector3(1, 0, 0),
		Vector3(1, 0, 0),
		Vector3(1, 0, 0),
		# back
		Vector3(0, 0, -1),
		Vector3(0, 0, -1),
		Vector3(0, 0, -1),
		Vector3(0, 0, -1),
		# front
		Vector3(0, 0, 1),
		Vector3(0, 0, 1),
		Vector3(0, 0, 1),
		Vector3(0, 0, 1),
	])
	
	surface_array[Mesh.ARRAY_VERTEX] = verts
	surface_array[Mesh.ARRAY_INDEX] = indices
	surface_array[Mesh.ARRAY_TEX_UV] = uvs
	surface_array[Mesh.ARRAY_NORMAL] = normals
	
	am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, surface_array)
	self.mesh = am
	self.mesh.set("surface_0/material", preload("res://scenes/test/testmat.tres"))


