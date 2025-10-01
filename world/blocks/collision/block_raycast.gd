class_name BlockRaycast extends RefCounted

## Class that represents a raycast through the block world and provides static methods
## for instancing itself.

## The axis of the last traversal.
var xyz_axis: int
## Whether the last traversal increased or decreased the last [member xyz_axis] axis coordinate.
var axis_direction: int = 0
## True if the raycast didn't find a block.
var failure := false
## Array of all traversed block world coordinates.
var steps_traversed: PackedVector3Array = []
## The block the raycast ended on. -1 if [member failure] is true.
var found_block: int = -1


## Returns the last traversed block, or what the raycast collided with.
func get_collision_point() -> Vector3:
	if steps_traversed.is_empty():
		return Vector3.ONE * -1
	return steps_traversed[steps_traversed.size() - 1]


static func fraction(x: float) -> float:
	return x - floorf(x)


## Casts a fast ray through the world and returns a [BlockRaycast] instance of the
## results.
## Based on the algoritm found [url=https://github.com/StanislavPetrovV/Minecraft/blob/main/voxel_handler.py]here[/url].
static func cast_ray_fast_vh(
		start_position: Vector3,
		direction: Vector3,
		max_distance: int,
		world: World,
) -> BlockRaycast:
	const BIGNUM = 999999999.0

	var rc := BlockRaycast.new()

	var v1 := start_position
	var v2 := start_position + direction * max_distance

	var current_bpos := v1.floor()
	var bid := 0
	var bnormal := Vector3i()
	var step_dir := 0
	var step_sign := 0

	var vd := Vector3(
		signf(v2.x - v1.x),
		signf(v2.y - v1.y),
		signf(v2.z - v1.z),
	)
	var vdelta := Vector3(
		minf(vd.x / (v2.x - v1.x), BIGNUM) if vd.x != 0 else BIGNUM,
		minf(vd.y / (v2.y - v1.y), BIGNUM) if vd.y != 0 else BIGNUM,
		minf(vd.z / (v2.z - v1.z), BIGNUM) if vd.z != 0 else BIGNUM,
	)
	var vmax := Vector3(
		vdelta.x * (1.0 - fraction(v1.x)) if vd.x > 0 else vdelta.x * fraction(v1.x),
		vdelta.y * (1.0 - fraction(v1.y)) if vd.y > 0 else vdelta.y * fraction(v1.y),
		vdelta.z * (1.0 - fraction(v1.z)) if vd.z > 0 else vdelta.z * fraction(v1.z),
	)

	while not (vmax.x > 1 and vmax.y > 1 and vmax.z > 1):
		var resbid := world.get_block(current_bpos)
		rc.steps_traversed.append(current_bpos)
		if resbid != BlockTypes.INVALID_BLOCK_ID and resbid != BlockTypes.AIR:
			rc.found_block = resbid
			rc.xyz_axis = step_dir
			rc.axis_direction = step_sign
			return rc

		if vmax.x < vmax.y:
			if vmax.x < vmax.z:
				current_bpos.x += vd.x
				vmax.x += vdelta.x
				step_dir = 0
				step_sign = signi(vd.x)
			else:
				current_bpos.z += vd.z
				vmax.z += vdelta.z
				step_dir = 2
				step_sign = signi(vd.z)
		else:
			if vmax.y < vmax.z:
				current_bpos.y += vd.y
				vmax.y += vdelta.y
				step_dir = 1
				step_sign = signi(vd.y)
			else:
				current_bpos.z += vd.z
				vmax.z += vdelta.z
				step_dir = 2
				step_sign = signi(vd.z)

	rc.failure = true
	return rc


static func _get_block(grid: Vector3, world: World) -> int:
	var block_position := grid# + world.world_position
	var result := world.get_block(block_position)
	return result


func _to_string() -> String:
	return ("BlockRaycast[ "
			+ "failure: " + str(failure)
			+ ", xyz_axis: " + str(xyz_axis)
			+ ", axis_direction: " + str(axis_direction)
			#+ ", position: " + str(position)
			+ ", found_block: " + str(found_block)
			+ ", steps_traversed: " + str(steps_traversed)
			+ " ]")
