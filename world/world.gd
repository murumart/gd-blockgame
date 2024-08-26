class_name World extends Node3D

## Creates chunks procedurally.

const ChunkScene := preload("res://world/chunks/chunk.tscn")
const NEIGHBOUR_ADDS: PackedVector3Array = [
	Vector3.FORWARD,
	Vector3.BACK,
	Vector3.LEFT,
	Vector3.RIGHT,
	Vector3.DOWN,
	Vector3.UP,
]

@onready var _chunks_parent: Node3D = $ChunksParent
@onready var _chunk_loader_timer: Timer = $ChunkLoaderTimer
## All loaded chunks are stored here. The keys are chunk positions.
var chunks := {}

@export var chunk_loaders: Array[ChunkLoader] = []
@export var world_generator: WorldGenerator
@export var generator_settings: GeneratorSettings


func _ready() -> void:
	#_chunk_loader_timer.timeout.connect(_update_loaded_chunks)
	_start_generation()
	for loader in chunk_loaders:
		loader.changed_chunk.connect(world_generator.recalculate_visible_chunk_positions.unbind(1))
	world_generator.recalculate_visible_chunk_positions()


func _process(delta: float) -> void:
	_update_loaded_chunks()


func _start_generation() -> void:
	world_generator._settings = generator_settings


func load_chunk(chunk_pos: Vector3) -> Chunk:
	if is_instance_valid(chunks.get(chunk_pos)):
		return chunks.get(chunk_pos)
	var chunk := ChunkScene.instantiate()
	chunk.world = self
	chunks[chunk_pos] = chunk
	_chunks_parent.add_child(chunk)
	chunk.name = str(chunk_pos)
	chunk.global_position = chunk_pos * Vector3(Chunk.SIZE)
	chunk.block_gen_requested.connect(world_generator._on_chunk_gen_requested)
	return chunk


func unload_chunk(chunk_pos: Vector3) -> void:
	var chunk: Chunk = chunks[chunk_pos]
	chunk.load_step = Chunk.LoadSteps.DELETING
	chunks.erase(chunk_pos)
	chunk.queue_free()


func _update_loaded_chunks() -> void:
	var poses_to_load := world_generator.visible_chunk_positions
	# generating meshes
	for pos in poses_to_load:
		var chunk := chunks.get(pos, null) as Chunk
		if not is_instance_valid(chunk):
			continue
		if chunk.load_step < Chunk.LoadSteps.BLOCKS_GENNED:
			continue
		if chunk.load_step >= Chunk.LoadSteps.MESH_GENNING:
			continue

		var has_all_edges := true
		for npos in NEIGHBOUR_ADDS:
			var chunk_at: Chunk = chunks.get(pos + npos, null)
			if not is_instance_valid(chunk_at) or chunk_at.load_step < Chunk.LoadSteps.BLOCKS_GENNED:
				has_all_edges = false
				break
		if not has_all_edges:
			#chunk.make_mesh(null)
			continue
		#await get_tree().process_frame
		chunk.make_mesh(self)

	# adding new chunks to be loaded.
	#var c := 0
	#for pos in poses_to_load:
		##await get_tree().process_frame
		#var chunk := load_chunk(pos)
		#if is_instance_valid(chunk) and chunk.load_step == Chunk.LoadSteps.UNLOADED:
			#chunk.generate()
		#c += 1
		#if c > 20:
			#break

	# unload chunks that don't are loaded should
	const MAX_DELETIONS := 8
	var i := 0
	for pos: Vector3 in chunks.keys():
		if pos not in poses_to_load:
			unload_chunk(pos)
			i += 1
			if i >= MAX_DELETIONS:
				break


func get_block(global_block_pos: Vector3) -> int:
	var cpos := World.global_pos_to_chunk_pos(global_block_pos)
	var chunk: Chunk = chunks.get(cpos, null)
	if not is_instance_valid(chunk) or chunk.load_step < 1:
		return BlockTypes.INVALID_BLOCK_ID
	var chunk_block_pos := global_block_pos - cpos * Vector3(Chunk.SIZE)
	#assert(chunk_block_pos.x < 16 and chunk_block_pos.y < 16 and chunk_block_pos.z < 16)
	#assert(chunk_block_pos.x > -1 and chunk_block_pos.y > -1 and chunk_block_pos.z > -1)
	return chunk.get_block_local(chunk_block_pos)


static func global_pos_to_chunk_pos(global_pos: Vector3) -> Vector3:
	return (global_pos / Vector3(Chunk.SIZE)).floor()
