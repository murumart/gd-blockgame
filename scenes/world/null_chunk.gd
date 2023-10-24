class_name NullChunk extends Node3D

signal mesh_build_finished

const WIDTH := 32 # x
const HEIGHT := 32 # y
static var AREA := WIDTH * WIDTH
static var VOLUME := AREA * HEIGHT

var mesh : MeshInstance3D = null

var chunk_position := Vector3i()


func _ready() -> void:
	queue_free()


func _build() -> void:
	queue_free()


func _build_mesh() -> void:
	queue_free()


