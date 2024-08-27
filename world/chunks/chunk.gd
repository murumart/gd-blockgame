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

const SIZE := Vector3i(16, 32, 16) ## The size of a chunk.

var data := ChunkData.new() ## Stores the chunk's block data.

var neighbors: Array[Chunk] = [null, null, null, null, null, null]
var load_step: LoadSteps

var world: World

@export var mesh: ChunkMesh
@export var fog: Node3D

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
	block_gen_requested.emit(self)


func _generation_thread_finished() -> void:
	load_step = LoadSteps.BLOCKS_GENNED
	_history[Engine.get_process_frames()] = "block generation finished"
	#print("generation of ", name, " finished. ")


func make_mesh(_world: World = null) -> void:
	#mesh.call_deferred("create_mesh", data)
	if data.block_data.is_empty():
		return
	#mesh.create_mesh(data, world)
	if mesh.create_mesh_thread(data, _world):
		load_step = LoadSteps.MESH_GENNING


func get_block_local(internal_pos: Vector3) -> int:
	return data.get_block_at(ChunkData.pos_to_index(internal_pos))
