class_name Chunk extends Node3D

## Chunk of the world. Consists of blocks

const SIZE := Vector3i(16, 16, 16) ## The size of a chunk.

var data := ChunkData.new()
@export var mesh: ChunkMesh


func _debug_generate_chunk() -> void:
	_generate()
	make_mesh()


func _generate() -> void:
	data.clear_block_data()
	data.init_block_data()
	var time := Time.get_ticks_msec()
	for y in SIZE.y:
		for x in SIZE.x:
			for z in SIZE.z:
				var bpos := Vector3(x, y, z)
				var idx := ChunkData.pos_to_index(bpos)
				if y < randf() * 16:
					data.set_block_at(idx, randi_range(1, 3))
	print("chunkgen took ", Time.get_ticks_msec() - time)


func make_mesh() -> void:
	mesh.call_deferred("create_mesh", data)
	#mesh.create_mesh(data)
