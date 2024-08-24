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
	#_chunk_loader_timer.timeout.connect(_update_loaded_chunks)
	start_generation()


func _process(delta: float) -> void:
	_update_loaded_chunks()


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
	var chunk: Chunk = chunks[chunk_pos]
	chunk.load_step = Chunk.LoadSteps.DELETING
	chunks.erase(chunk_pos)
	chunk.queue_free()


func _update_loaded_chunks() -> void:
	var poses_to_load := _get_chunk_poses_to_load()
	# generating meshes
	for pos in poses_to_load:
		var chunk := chunks.get(pos, null) as Chunk
		if not is_instance_valid(chunk):
			continue
		if chunk.load_step != Chunk.LoadSteps.BLOCKS_GENNED:
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

	# adding new chunks to be loaded.
	for pos in poses_to_load:
		#await get_tree().process_frame
		load_chunk(pos)

	# unload chunks that don't are loaded should
	return
	const MAX_DELETIONS := 2
	var i := 0
	for pos: Vector3 in chunks.keys():
		if pos not in poses_to_load:
			unload_chunk(pos)
			i += 1
			if i >= MAX_DELETIONS:
				break


func _get_chunk_poses_to_load() -> PackedVector3Array:
	var toreturn: PackedVector3Array = []
	for loader in chunk_loaders:
		var chunk_pos := World.global_pos_to_chunk_pos(loader.global_position)
		#var vertical_distance := maxi(loader.load_distance / 3, 1)
		#var LOADER_Y := range(
				#chunk_pos.y + vertical_distance,
				#chunk_pos.y - vertical_distance - 1,
				#-1)
		#for y: int in LOADER_Y:
			#var dist := absf(chunk_pos.y - y)
			#toreturn.append_array(
					#WorldGenerator.get_diamond(Vector3(chunk_pos.x, y, chunk_pos.z),
					#loader.load_distance - dist))
		toreturn.append_array(WorldGenerator.get_diamond(chunk_pos, loader.load_distance))
		toreturn.append_array(WorldGenerator.get_diamond(chunk_pos + Vector3.UP, loader.load_distance - 3))
		toreturn.append_array(WorldGenerator.get_diamond(chunk_pos + Vector3.DOWN, loader.load_distance - 3))
	return toreturn


func _get_chunk_poses_to_load_sorted() -> Array[Vector3]:
	var time := Time.get_ticks_msec()
	var toreturn: Array[Vector3] = []
	var chunk_pos: Vector3
	for loader in chunk_loaders:
		chunk_pos = World.global_pos_to_chunk_pos(loader.global_position)
		var LOADER_Y := range(
				chunk_pos.y - loader.load_distance / 2,
				chunk_pos.y + loader.load_distance / 2)
		for y: int in LOADER_Y:
			var dist := absf(chunk_pos.y - y)
			toreturn.append_array(
					WorldGenerator.get_diamond(Vector3(chunk_pos.x, y, chunk_pos.z),
					loader.load_distance - dist))
		#toreturn.append_array(WorldGenerator.get_diamond(chunk_pos, loader.load_distance))
	toreturn.sort_custom(_sort_poses_by_distance_from_loader.bind(chunk_pos))
	print("getting loadable chnks took ", Time.get_ticks_msec() - time, " ms")
	return toreturn


func _sort_poses_by_distance_from_loader(pos1: Vector3, pos2: Vector3, centerpos: Vector3) -> bool:
	var dis1 := pos1.distance_squared_to(centerpos)
	var dis2 := pos1.distance_squared_to(centerpos)
	return dis1 > dis2


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
