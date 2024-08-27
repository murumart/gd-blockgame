extends Node

var world: World
var recenter_target: Node3D
var _last_chunk_position: Vector3


func _ready() -> void:
	assert(owner is World)
	world = owner
	recenter_target = world.recenter_target


func _process(_delta: float) -> void:
	var chunk_position := World.world_pos_to_chunk_pos(recenter_target.global_position)

	_last_chunk_position = chunk_position
