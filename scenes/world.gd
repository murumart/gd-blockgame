class_name World extends Node3D

static var player_position := Vector3()
static var player_chunk_pos : Vector3i: get = _player_chunk_position


static func _player_chunk_position() -> Vector3i:
	return Vector3i(
		floori(player_position.x / Chunk.WIDTH),
		floori(player_position.y / Chunk.HEIGHT),
		floori(player_position.z / Chunk.WIDTH),
	)
