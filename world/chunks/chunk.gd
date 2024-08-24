class_name Chunk extends Node3D

## Chunk of the world. Consists of blocks

signal block_gen_requested(this: Chunk)

enum LoadSteps {
	UNLOADED, ## Chunk hasn't been loaded, but exists.
	BLOCKS_GENNED, ## Chunk has its blocks generated, but not mesh.
	MESH_GENNING, ## Mesh is generating on the thread.
	MESH_GENNED, ## Chunk has its mesh generated and is visible.
	DELETING, ## Chunk is queued for deletion.
}

const SIZE := Vector3i(16, 16, 16) ## The size of a chunk.

var data := ChunkData.new() ## Stores the chunk's block data.

var neighbors: Array[Chunk] = [null, null, null, null, null, null]
var load_step: LoadSteps

var world: World

@export var mesh: ChunkMesh

var _history := {}


func _ready() -> void:
	$BoundingBox.hide()
	mesh.meshing_finished.connect(func() -> void:
		load_step = LoadSteps.MESH_GENNED
		_history[Engine.get_process_frames()] = "finished mesh generation"
	)


func generate() -> void:
	data.clear_block_data()
	data.init_block_data()
	_history[Engine.get_process_frames()] = "requesting block generation"
	block_gen_requested.emit(self)


func _generation_thread_finished() -> void:
	load_step = LoadSteps.BLOCKS_GENNED
	_history[Engine.get_process_frames()] = "block generation finished"
	#print("generation of ", name, " finished. ")


func __builtin_generation() -> void:
	data.clear_block_data()
	data.init_block_data()
	var time := Time.get_ticks_msec()
	var data_empty := true
	for y in SIZE.y:
		for x in SIZE.x:
			for z in SIZE.z:
				var cpos := World.global_pos_to_chunk_pos(global_position)
				var bpos := Vector3(x, y, z)
				var world_pos := cpos * Vector3(SIZE) + bpos
				var idx := ChunkData.pos_to_index(bpos)
				if (world_pos.y
						< (sin(world_pos.x * 0.1) * cos(world_pos.z * 0.1) * 16.0
							+ cos(world_pos.x * 0.001) * sin(world_pos.z * 0.001) * 500)
						):
					data.set_block_at(idx, randi_range(1, 3))
					data_empty = false
	if data_empty:
		data.set_single_block_type(0)
	load_step = LoadSteps.BLOCKS_GENNED
	print("chunkgen took ", Time.get_ticks_msec() - time)


func make_mesh(world: World = null) -> void:
	#mesh.call_deferred("create_mesh", data)
	if data.block_data.is_empty():
		return
	#mesh.create_mesh(data, world)
	if mesh.create_mesh_thread(data, world):
		load_step = LoadSteps.MESH_GENNING


func get_block_local(internal_pos: Vector3) -> int:
	return data.get_block_at(ChunkData.pos_to_index(internal_pos))
