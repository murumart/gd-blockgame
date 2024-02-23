class_name WorldI extends Node3D

const CHUNK_SIZE = 32

static var player_position := Vector3()
static var player_chunk_position : Vector3i: get = _player_chunk_position

@onready var label: Label = $Control/Label


func _ready() -> void:
	WorldI.add_chunk(Vector3i())
	for x in range(-1, 1):
		for y in range(-1, 1):
			for z in range(-1, 1):
				WorldI.add_chunk(Vector3i(x, y, z))
	print(WorldI.get_block(0, 1, 0))


func _physics_process(_delta: float) -> void:
	var bpos := Vector3i($Camera3D.global_position)
	var w_cpos := WorldI.player_chunk_position
	
	for x in range(-4, 4):
		for y in range(-1, 1):
			for z in range(-4, 4):
				var in_chunk := get_chunk(w_cpos + Vector3i(x, y, z))
				if in_chunk.meshGenned: continue
				in_chunk.GenMesh()
				await get_tree().process_frame

	$Control/Label.text = str(
		"fps: ", Engine.get_frames_per_second(),
		"\nposition: ", bpos,
		"\nfullpos: ", $"Camera3D".global_position.round(),
		"\nchunk_world: ", w_cpos,
		)


static func _player_chunk_position() -> Vector3i:
	return Vector3i(
		floori(player_position.x / WorldI.CHUNK_SIZE),
		floori(player_position.y / WorldI.CHUNK_SIZE),
		floori(player_position.z / WorldI.CHUNK_SIZE),
	)


static func get_block(x: int, y: int, z: int) -> int:
	return World.GetBlock(x, y, z)


static func add_chunk(pos: Vector3i) -> void:
	print("adding chunk %s" % pos)
	var t := Time.get_ticks_msec()
	World.AddChunk(pos)
	print("adding finished after %s" % (Time.get_ticks_msec() - t))
	print("genning mesh of %s" % pos)
	t = Time.get_ticks_msec()
	get_chunk(pos).GenMesh()
	print("mesh genning finished after %s" % (Time.get_ticks_msec() - t))


static func get_chunk(pos: Vector3i) -> Chunk:
	return World.GetChunk(pos)

