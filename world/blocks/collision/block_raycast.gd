class_name BlockRaycast extends RefCounted

var position: Vector3
var xyz_axis: int
var failure := false
var steps_traversed: PackedVector3Array = []
var found_block: int = -1


func get_collision_point() -> Vector3:
	if steps_traversed.is_empty():
		return Vector3.ONE * -1
	return steps_traversed[steps_traversed.size() - 1]


static func vec_sign(vec: Vector3) -> Vector3:
	var signx := signf(vec.x)
	var signy := signf(vec.y)
	var signz := signf(vec.z)
	return Vector3(
			signx if signx != 0.0 else 1.0,
			signy if signy != 0.0 else 1.0,
			signz if signz != 0.0 else 1.0,
	)


static func vec_argmin(vec: Vector3) -> int:
	var minimal := vec.x
	var index := 0
	if vec.y < minimal:
		minimal = vec.y
		index = 1
	if vec.z < minimal:
		minimal = vec.z
		index = 2
	return index


# https://gamedev.stackexchange.com/a/203825
# ignore the grid variable after the start. it is not representative of the
# raycast's position after the prep phase.
# current impl goes through block edges. groaning in pain and crying.
static func cast_ray_fast(
		start_position: Vector3,
		step: Vector3,
		steps_count: int,
		world: World) -> BlockRaycast:
	if Input.is_action_just_released("ui_left"):
		breakpoint

	var rc := BlockRaycast.new()
	var steps_storage: PackedVector3Array = []

	var signv := vec_sign(step)
	var reciprocal := Vector3.ONE / step.abs()
	var grid := start_position.floor()
	var steps := (signv + Vector3.ONE) * 0.5 - (start_position - grid) / step

	for i in steps_count:
		var axis: int = vec_argmin(steps)
		#grid[axis] += signv[axis] this isnät needed anywhere
		var traversed := start_position + step * steps[axis]
		var t_floor := traversed.floor()
		steps_storage.append(t_floor)
		var block := _get_block(t_floor, world)
		if block != BlockTypes.AIR:
			rc.failure = false
			rc.steps_traversed = steps_storage
			rc.xyz_axis = axis
			rc.found_block = block
			rc.position = traversed
			return rc
		steps[axis] += reciprocal[axis]

	rc.failure = true
	rc.steps_traversed = steps_storage
	return rc


# uses actual nodes and godot collision detection
# slow and doesn't work either.
static func cast_ray_stupid(
		start_position: Vector3,
		direction: Vector3,
		steps: int,
		world: World) -> BlockRaycast:

	var rc := BlockRaycast.new()
	rc.failure = true
	direction = direction.normalized()

	var collision_raycast := RayCast3D.new()
	var block_collisions := BlockCollisionMaker.new()
	block_collisions.world = world
	block_collisions.collision_layer = 0b00001
	world.add_child(collision_raycast)
	world.add_child(block_collisions)

	collision_raycast.global_position = start_position
	collision_raycast.target_position = Vector3.ZERO
	collision_raycast.collision_mask = 0b00001

	for i in steps:
		block_collisions.recalculate_block_collisions()
		collision_raycast.force_raycast_update()

		var grid_position := (collision_raycast.global_position
				+ collision_raycast.target_position).floor()
		rc.steps_traversed.append(grid_position)

		var collider := collision_raycast.get_collider()
		if is_instance_valid(collider):
			collider = collider as CollisionShape3D
			var block := world.get_block(grid_position)
			rc.failure = false
			rc.found_block = block
			break

		block_collisions.global_position = (collision_raycast.global_position
				+ collision_raycast.target_position)
		collision_raycast.target_position += direction

	collision_raycast.queue_free()
	block_collisions.queue_free()

	return rc


static func _get_block(grid: Vector3, world: World) -> int:
	var block_position := grid# + world.world_position
	var result := world.get_block(block_position)
	return result


func _to_string() -> String:
	return ("BlockRaycast[ "
			+ "failure: " + str(failure)
			+ ", xyz_axis: " + str(xyz_axis)
			+ ", position: " + str(position)
			+ ", found_block: " + str(found_block)
			+ ", steps_traversed: " + str(steps_traversed)
			+ " ]")
