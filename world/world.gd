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


func _ready() -> void:
	_chunk_loader_timer.timeout.connect(_update_loaded_chunks)
	start_generation()


func start_generation() -> void:
	for x in 3:
		for y in 3:
			for z in 3:
				var chunk_pos := Vector3(x, y, z)
				load_chunk(chunk_pos)


func load_chunk(chunk_pos: Vector3) -> void:
	if is_instance_valid(chunks.get(chunk_pos)):
		return
	var chunk := ChunkScene.instantiate()
	chunk.world = self
	chunks[chunk_pos] = chunk
	_chunks_parent.add_child(chunk)
	chunk.name = str(chunk_pos)
	chunk.global_position = chunk_pos * Vector3(Chunk.SIZE)
	chunk.generate()


func unload_chunk(chunk_pos: Vector3) -> void:
	pass


func _update_loaded_chunks() -> void:
	# generating meshes
	var gen_time := 0.0
	for pos in chunks.keys():
		pos = pos as Vector3
		var chunk := chunks.get(pos, null) as Chunk
		if not is_instance_valid(chunk):
			continue
		if chunk.load_step > Chunk.LoadSteps.BLOCKS_GENNED:
			continue
		var can_gen_mesh := true
		for npos in NEIGHBOUR_ADDS:
			if not is_instance_valid(chunks.get(pos + npos)):
				can_gen_mesh = false
				break
		if not can_gen_mesh:
			continue
		var tw := create_tween()
		tw.tween_interval(gen_time)
		gen_time += 0.1
		tw.tween_callback(func():
			if chunk.load_step > Chunk.LoadSteps.BLOCKS_GENNED:
				return
			chunk.make_mesh()
		)

	# adding new chunks to be loaded.
	for loader in chunk_loaders:
		var chunk_pos := World.global_pos_to_chunk_pos(loader.global_position)
		var poses_to_load: PackedVector3Array = [chunk_pos]
		for i in loader.load_distance:
			var temp: PackedVector3Array = []
			for pos in poses_to_load:
				for neighbor in NEIGHBOUR_ADDS:
					var new := pos + neighbor
					if new in poses_to_load or new in temp:
						continue
					temp.append(new)
			poses_to_load.append_array(temp)
		#print(poses_to_load)
		for pos in poses_to_load:
			#await get_tree().process_frame
			load_chunk(pos)


func get_block(global_block_pos: Vector3) -> int:
	var cpos := World.global_pos_to_chunk_pos(global_block_pos)
	var chunk: Chunk = chunks.get(cpos, null)
	if not is_instance_valid(chunk):
		return BlockTypes.INVALID_BLOCK_ID
	global_block_pos -= cpos * Vector3(Chunk.SIZE)
	#assert(global_block_pos.x < 16 and global_block_pos.y < 16 and global_block_pos.z < 16)
	#assert(global_block_pos.x > -1 and global_block_pos.y > -1 and global_block_pos.z > -1)
	return chunk.get_block_local(global_block_pos)


static func global_pos_to_chunk_pos(global_pos: Vector3) -> Vector3:
	var x := floori(global_pos.x / Chunk.SIZE.x)
	var y := floori(global_pos.y / Chunk.SIZE.y)
	var z := floori(global_pos.z / Chunk.SIZE.z)
	return Vector3i(x, y, z)
