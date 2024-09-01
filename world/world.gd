class_name World extends Node3D

## The game's play area. Creates chunks procedurally.

## Stores the [PackedScene] of [Chunk].
const ChunkScene := preload("res://world/chunks/chunk.tscn")
## Neighbors of an integer coordinate, in order.
const NEIGHBOUR_ADDS: PackedVector3Array = [
	Vector3.FORWARD,
	Vector3.BACK,
	Vector3.LEFT,
	Vector3.RIGHT,
	Vector3.DOWN,
	Vector3.UP,
]

@onready var _chunks_parent: Node3D = $ChunksParent
## All loaded chunks are stored here. The keys are chunk positions.
var chunks := {}
## Stores the "global" position offset.
var world_position := Vector3.ZERO

## Array of [ChunkLoader] nodes, the positions of which chunks are loaded around.
@export var chunk_loaders: Array[ChunkLoader] = []
## The [WorldGenerator] instance that generates the world.
@export var world_generator: WorldGenerator
## Settings for the [member world_generator].
@export var generator_settings: GeneratorSettings
## The world recenters around this target when it goes a certain distance away.
## See [Recenterer].
@export var recenter_target: Node3D
## Whether chunks can be unloaded.
@export var unloading_enalbed := true


func _ready() -> void:
	#_chunk_loader_timer.timeout.connect(_update_loaded_chunks)
	_start_generation()
	for loader in chunk_loaders:
		loader.changed_chunk.connect(world_generator.recalculate_visible_chunk_positions.unbind(1))
	world_generator.recalculate_visible_chunk_positions()


func _process(_delta: float) -> void:
	_update_loaded_chunks()


func _start_generation() -> void:
	world_generator._settings = generator_settings


## Loads a [Chunk] at [param chunk_pos] and returns it. If a chunk already exists at [param chunk_pos],
## then returns the pre-existing one.
func load_chunk(chunk_pos: Vector3) -> Chunk:
	if is_instance_valid(chunks.get(chunk_pos)):
		return chunks.get(chunk_pos)
	var chunk := ChunkScene.instantiate()
	chunk.world = self
	chunks[chunk_pos] = chunk
	_chunks_parent.add_child(chunk)
	chunk.name = str(chunk_pos)
	chunk.position = chunk_pos * Vector3(Chunk.SIZE)
	chunk.block_gen_requested.connect(world_generator._on_chunk_gen_requested)
	return chunk


## Unloads a chunk at [param chunk_pos].
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
			chunk.make_mesh(null)
			continue
		#await get_tree().process_frame
		chunk.make_mesh(self)

	# creating new chunks in WorldGenerator

	if not unloading_enalbed:
		return
	# unload chunks that don't are loaded should
	const MAX_DELETIONS := 8
	var i := 0
	for pos: Vector3 in chunks.keys():
		if pos not in poses_to_load:
			unload_chunk(pos)
			i += 1
			if i >= MAX_DELETIONS:
				break


## Returns the block at [param global_block_pos].
func get_block(global_block_pos: Vector3) -> int:
	var cpos := World.world_pos_to_chunk_pos(global_block_pos + world_position)
	var chunk: Chunk = chunks.get(cpos, null)
	if not is_instance_valid(chunk) or chunk.load_step < 1:
		return BlockTypes.INVALID_BLOCK_ID
	var chunk_block_pos := global_block_pos - cpos * Vector3(Chunk.SIZE) + world_position
	assert(chunk_block_pos.x < Chunk.SIZE.x and chunk_block_pos.y < Chunk.SIZE.y and chunk_block_pos.z < Chunk.SIZE.z)
	assert(chunk_block_pos.x > -1 and chunk_block_pos.y > -1 and chunk_block_pos.z > -1)
	return chunk.get_block_local(chunk_block_pos)


## Sets the block at [param global_block_pos] to [param block].
## See [member ChunkData.block_data] for the format [param block] should be in.
func set_block(global_block_pos: Vector3, block: int) -> bool:
	var cpos := World.world_pos_to_chunk_pos(global_block_pos + world_position)
	var chunk: Chunk = chunks.get(cpos, null)
	if not is_instance_valid(chunk) or chunk.load_step < 1:
		return false
	var chunk_block_pos := global_block_pos - cpos * Vector3(Chunk.SIZE) + world_position
	assert(chunk_block_pos.x < Chunk.SIZE.x and chunk_block_pos.y < Chunk.SIZE.y and chunk_block_pos.z < Chunk.SIZE.z)
	assert(chunk_block_pos.x > -1 and chunk_block_pos.y > -1 and chunk_block_pos.z > -1)
	chunk.set_block_local(chunk_block_pos, block)
	return true


## Sets the block at [param global_block_pos] to [param block], and remeshes the chunk
## that the block was in on the main thread.
func place_block(global_block_pos: Vector3, block: int) -> bool:
	if not set_block(global_block_pos, block):
		return false
	var cpos := World.world_pos_to_chunk_pos(global_block_pos + world_position)
	var chunk: Chunk = chunks.get(cpos, null)
	chunk.make_mesh(self, true)
	return true


## Returns the [param chunk_pos] that the [param world_pos] was in.
static func world_pos_to_chunk_pos(world_pos: Vector3) -> Vector3:
	return (world_pos / Vector3(Chunk.SIZE)).floor()
