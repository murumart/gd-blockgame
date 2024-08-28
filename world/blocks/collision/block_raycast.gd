class_name BlockRaycast extends RefCounted

var position: Vector3
var xyz_axis: int
var failure := false
var steps_traversed: PackedVector3Array = []
var found_block: int = -1
var _debug_data := {}


func get_collision_point() -> Vector3:
	if steps_traversed.is_empty():
		return Vector3.ONE * -1
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


# https://gamedev.stackexchange.com/a/203825
# fast but starts groaning in pain and crying when sign != (-1, -1, -1)
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
	var _breaks := signv != Vector3.ONE * -1
	var reciprocal := Vector3.ONE / step.abs()
	var grid := start_position.floor()
	var steps := (signv + Vector3.ONE) * 0.5 - (start_position - grid) / step
	if _breaks:
		pass
	rc._debug_data["params"] = {"start_position": start_position, "step": step}
	rc._debug_data["pre"] = {"signv": signv, "reciprocal": reciprocal, "grid": grid, "steps": steps, "_breaks": _breaks}
	rc._debug_data["steps"] = []

	for i in steps_count:
		var axis: int = vec_argmin(steps)
		grid[axis] += signv[axis]
		var traversed := start_position + step * steps[axis]
		steps_storage.append(grid)
		var block := _get_block(grid, world)
		if block != BlockTypes.AIR:
			rc.failure = false
			rc.steps_traversed = steps_storage
			rc.xyz_axis = axis
			rc.found_block = block
			rc.position = traversed
			return rc
		steps[axis] += reciprocal[axis]
		rc._debug_data["steps"].append(
				{"axis": ["x", "y", "z"][axis], "grid": grid,
				"traversed": traversed, "steps": steps})

	rc.failure = true
	rc.steps_traversed = steps_storage
	return rc


static func cast_ray(
		start_position: Vector3,
		direction: Vector3,
		steps: int,
		world: World) -> BlockRaycast:

	var rc := BlockRaycast.new()
	var steps_traversed: PackedVector3Array = []
	direction = direction.normalized()
	var position := start_position
	for i in steps:
		pass

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
