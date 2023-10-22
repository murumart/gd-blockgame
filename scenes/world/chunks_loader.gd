class_name ChunksLoader extends Node3D

static var CL_INSTANCES := 0
const CHUNK_SCENE := preload("res://scenes/world/chunk.tscn")

static var chunks := {}


func _init() -> void:
	if CL_INSTANCES > 0:
		queue_free()
		return
	CL_INSTANCES += 1


func _ready() -> void:
	pass


func _process(_delta: float) -> void:
	_update()


func _update() -> void:
	var p_c_pos := World.player_chunk_pos
	if not p_c_pos in chunks.keys():
		_add_chunk(p_c_pos.x, p_c_pos.y, p_c_pos.z)


func _add_chunk(x: int, y: int, z: int) -> void:
	var v3pos := Vector3i(x, y, z)
	if v3pos in chunks: return
	var chunk := CHUNK_SCENE.instantiate()
	chunk.chunk_position = v3pos
	chunks[v3pos] = chunk
	add_child(chunk)
	chunk.global_position = Vector3i(
		x * Chunk.WIDTH, y * Chunk.HEIGHT, z * Chunk.WIDTH)
	chunk.call_deferred("_build_mesh")
	#chunk._build_mesh()
	_update_neighbour_chunks(x, y, z)


func _update_neighbour_chunks(x: int, y: int, z: int) -> void:
	var ar := PackedVector3Array([
		Vector3(1, 0, 0),
		Vector3(-1, 0, 0),
		Vector3(0, 1, 0),
		Vector3(0, -1, 0),
		Vector3(0, 0, 1),
		Vector3(0, 0, -1),
	])
	var v3pos := Vector3i(x, y, z)
	for vec in ar:
		var key := (v3pos + Vector3i(vec))
		if key in chunks.keys():
			chunks[key].call_deferred("_build_mesh")


static func get_chunk(x: int, y: int, z: int) -> NullChunk:
	var key := Vector3i(x, y, z)
	if not key in chunks.keys(): return NullChunk.new()
	return chunks[key]
