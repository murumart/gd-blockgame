class_name BlockCollisionMaker extends Node3D

const BLOCK_SHAPE := preload("res://world/blocks/collision/shapes/block_shape.tres")

const HALF := Vector3(0.5, 0.5, 0.5)

@export var size := Vector3i.ONE
@export_flags_3d_physics var collision_layer: int = 0b1
@export var world: World

var _collision_shapes: Array[CollisionShape3D]
var _last_position: Vector3
var _body := StaticBody3D.new()


func _ready() -> void:
	_recalculate_collision_shapes()
	add_child(_body)


func _recalculate_collision_shapes() -> void:
	_body.collision_mask = 0
	_body.collision_layer = collision_layer

	for collider in _collision_shapes:
		collider.disabled = true
		collider.queue_free()
	_collision_shapes.clear()

	var add_colliders_here: Array[Vector3] = []
	var xrange := range(-1, size.x + 1)
	var yrange := range(-1, size.y + 1)
	var zrange := range(-1, size.z + 1)
	for x: int in xrange:
		for y: int in yrange:
			for z: int in zrange:
				var pos := Vector3(x, y, z)
				add_colliders_here.append(pos)
	for x in range(0, size.x):
		for y in range(0, size.y):
			for z in range(0, size.z):
				add_colliders_here.erase(Vector3(x, y, z))

	for pos in add_colliders_here:
		var shape := CollisionShape3D.new()
		_collision_shapes.append(shape)
		shape.shape = BLOCK_SHAPE
		shape.position = pos
		_body.add_child(shape)
		shape.disabled = true

		#var mi := MeshInstance3D.new()
		#mi.mesh = BoxMesh.new()
		#var mat := StandardMaterial3D.new()
		#mi.mesh.surface_set_material(0, mat)
		#mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		#mat.albedo_color = Color(0.5, 0.5, 0.0, 0.76)
		#shape.add_child(mi)
#
		#var mi2 := MeshInstance3D.new()
		#mi2.mesh = BoxMesh.new()
		#(mi2.mesh as BoxMesh).size = Vector3(0.05, 0.05, 0.05)
		#shape.add_child(mi2)


func _physics_process(_delta: float) -> void:
	var current_position := global_position.floor()
	_body.global_position = current_position + HALF

	_calculate_block_collisions()

	_last_position = current_position


func _calculate_block_collisions() -> void:
	for shape in _collision_shapes:
		var block := world.get_block(shape.global_position.floor())
		shape.disabled = false
		#print(block, shape.global_position.floor())
		if block == BlockTypes.INVALID_BLOCK_ID:
			continue
		var btype := BlockTypes.get_block(block)
		if btype.mesh_type == BlockType.MeshType.NONE:
			shape.disabled = true


func recalculate_block_collisions() -> void:
	_calculate_block_collisions()
