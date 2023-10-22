class_name NullChunk extends Node3D

const WIDTH := 32 # x
const HEIGHT := 16 # y
static var AREA := WIDTH * WIDTH
static var VOLUME := AREA * HEIGHT

var mesh : MeshInstance3D = null

var chunk_position := Vector3i()

var blocks := PackedInt32Array()


func _ready() -> void:
	queue_free()


func _build() -> void:
	queue_free()


func _build_mesh() -> void:
	queue_free()


func _calc_blocks() -> void:
	queue_free()


func get_block(_x: int, _y: int, _z: int) -> int:
	queue_free()
	return 1


func set_block(_x: int, _y: int, _z: int, _block: int) -> bool:
	queue_free()
	return false

