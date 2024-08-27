class_name BlockRaycast extends RefCounted

var position: Vector3
var xyz_axis: int
var failure := false
var steps_traversed: PackedVector3Array = []
var found_block: int = -1


func _init(
		_position := Vector3.ZERO,
		_xyz := 0,
		_steps := PackedVector3Array(),
		_block := -1) -> void:
	position = _position
	xyz_axis = _xyz
	steps_traversed = _steps
	found_block = _block


func get_collision_point() -> Vector3:
	return steps_traversed[steps_traversed.size() - 1]


static func vec_sign(vec: Vector3) -> Vector3:
	var signx := signf(vec.x)
	var signy := signf(vec.y)
	var signz := signf(vec.z)
	return Vector3(
			signx if signx != 0 else 1,
			signy if signy != 0 else 1,
			signz if signz != 0 else 1,
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


static func cast_ray(
		start_position: Vector3,
		step: Vector3,
		world: World) -> BlockRaycast:

	var rc := BlockRaycast.new()
	var steps_storage: PackedVector3Array = []

	var sign := vec_sign(step)
	var reciprocal := Vector3.ONE / step.abs()
	var grid := start_position.floor()
	var steps := (sign + Vector3.ONE) * 0.5 - (start_position - grid) / step
	#printt("", sign, reciprocal, grid, steps, start_position, step)

	for i in 9:
		var axis: int = vec_argmin(steps)
		grid[axis] += sign[axis]
		var traversed := start_position + step * steps[axis]
		steps_storage.append(grid)
		var block := _get_block(grid, axis, world)
		if block != BlockTypes.AIR:
			return BlockRaycast.new(traversed, axis, steps_storage, block)
		steps[axis] += reciprocal[axis]
		#printt("\t", axis, grid, traversed, steps)

	rc.failure = true
	rc.steps_traversed = steps_storage
	return rc


static func _get_block(grid: Vector3, axis: int, world: World) -> int:
	var block_position := grid# + world.world_position
	var result := world.get_block(block_position)
	return result


func _to_string() -> String:
	return ("BlockRaycast[ "
			+ "xyz_axis: " + str(xyz_axis)
			+ ", position: " + str(position)
			+ ", steps_traversed: " + str(steps_traversed)
			+ ", found_block: " + str(found_block)
			+ ", failure: " + str(failure)
			+ " ]")
