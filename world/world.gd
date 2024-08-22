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


func _ready() -> void:
	_chunk_loader_timer.timeout.connect(_update_loaded_chunks)
	start_generation()


func start_generation() -> void:
	pass


func load_chunk(chunk_pos: Vector3) -> void:
	if is_instance_valid(chunks.get(chunk_pos)):
		return
	var chunk := ChunkScene.instantiate()
	chunk.world = self
	chunks[chunk_pos] = chunk
	_chunks_parent.add_child(chunk)
	chunk.name = str(chunk_pos)
	chunk.global_position = chunk_pos * Vector3(Chunk.SIZE)
	chunk.block_gen_requested.connect(_on_chunk_gen_requested)
	chunk.generate()


func _on_chunk_gen_requested(chunk: Chunk) -> void:
	if chunk.load_step > 0:
		return
	world_generator.start_generating(chunk)


func unload_chunk(chunk_pos: Vector3) -> void:
	pass


func _update_loaded_chunks() -> void:
	var poses_to_load := _get_chunk_poses_to_load()
	# generating meshes
	for pos in poses_to_load:
		var chunk := chunks.get(pos, null) as Chunk
		if not is_instance_valid(chunk):
			continue
		if chunk.load_step > Chunk.LoadSteps.BLOCKS_GENNED:
			continue

		var can_gen_mesh := true
		for npos in NEIGHBOUR_ADDS:
			var chunk_at: Chunk = chunks.get(pos + npos, null)
			if not is_instance_valid(chunk_at) or chunk_at.load_step < Chunk.LoadSteps.BLOCKS_GENNED:
				can_gen_mesh = false
				#print(("chunk invalid") if not is_instance_valid(chunk_at)
						#else str("mesh gen error: neighbor ", chunk_at.load_step,
						#" / ", is_instance_valid(chunk_at)))
				break
		if not can_gen_mesh:
			continue
		#await get_tree().process_frame
		chunk.make_mesh()

	# adding new chunks to be loaded.
	for pos in poses_to_load:
		#await get_tree().process_frame
		load_chunk(pos)


func _get_chunk_poses_to_load() -> PackedVector3Array:
	var toreturn: PackedVector3Array = []
	for loader in chunk_loaders:
		var chunk_pos := World.global_pos_to_chunk_pos(loader.global_position)
		var poses_to_load: PackedVector3Array = [chunk_pos]
		for i in loader.load_distance:
			var temp: PackedVector3Array = []
			for pos in poses_to_load:
				var j := -1
				for neighbor in NEIGHBOUR_ADDS:
					j += 1
					var new := pos + neighbor
					if new in poses_to_load or new in temp:
						continue
					temp.append(new)
			poses_to_load.append_array(temp)
		toreturn.append_array(poses_to_load)
	return toreturn


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
	var x := floori(global_pos.x / Chunk.SIZE.x)
	var y := floori(global_pos.y / Chunk.SIZE.y)
	var z := floori(global_pos.z / Chunk.SIZE.z)
	return Vector3i(x, y, z)
