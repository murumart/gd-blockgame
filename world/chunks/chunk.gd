@tool
class_name Chunk extends Node3D

const SIZE := Vector3i(16, 16, 16)

@export var _debug_generate: bool:
	set(to):
		_debug_generate_chunk()

var data := ChunkData.new()
@export var mesh: ChunkMesh


func _debug_generate_chunk() -> void:
	_generate()
	make_mesh()


func _generate() -> void:
	for y in SIZE.y:
		for x in SIZE.x:
			for z in SIZE.z:
				var bpos := Vector3(x, y, z)
				var idx := ChunkData.pos_to_index(bpos)
				if y < 8:
					data.set_block_at(idx, 1)


func make_mesh() -> void:
	mesh.call_deferred("create_mesh", data)
	#mesh.create_mesh(data)
