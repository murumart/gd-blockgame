extends Node3D

const BLOCK_MAX_LENGTH := 1.73205


@export var camera: Camera3D
@export var _world: World
@export var debug_ui: DebugUI


func time(tmie: float) -> void:
	await get_tree().create_timer(tmie).timeout
