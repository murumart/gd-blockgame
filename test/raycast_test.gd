extends Node3D


@export var camera: Camera3D
@export var _world: World
@export var debug_ui: DebugUI


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_paste"):
		cast_ray_fast(camera.global_position, -camera.global_basis.z, 9)


func cast_ray_fast(
		start_position: Vector3,
		step: Vector3,
		steps_count: int,
		#world: World
) -> BlockRaycast:
	if Input.is_action_just_released("ui_left"):
		breakpoint

	var rc := BlockRaycast.new()
	var steps_storage: PackedVector3Array = []

	var signv := BlockRaycast.vec_sign(step)


	var _breaks := signv != Vector3.ONE * -1
	debug_ui.db_disp_rc(start_position, signv, Color(Color.WHITE if not _breaks else Color.RED, 0.05))
	await time(1.0)

	var reciprocal := Vector3.ONE / step.abs()
	debug_ui.db_disp_rc(start_position, reciprocal, Color(Color.GREEN, 0.08))
	await time(1.0)

	var grid := start_position.floor()
	debug_ui.db_disp_recta(grid + Vector3.ONE * 0.5, Vector3.ONE, Color(1, 1, 0, 0.2))
	await time(1.0)

	var steps := (signv + Vector3.ONE) * 0.5 - (start_position - grid) / step
	var _last_step := debug_ui.db_disp_rc(start_position, steps, Color(Color.YELLOW_GREEN, 0.1))
	await time(1.5)
	print("STARTING LOOP")


	if _breaks:
		pass

	var _traversd := start_position
	for i in steps_count:
		var axis: int = BlockRaycast.vec_argmin(steps)
		var _v := Vector3()
		_v[axis] = signv[axis]
		var _axdisp := debug_ui.db_disp_rc(start_position, _v, Color.BLUE)
		await time(1.0)
		_axdisp.queue_free()

		grid[axis] += signv[axis]
		debug_ui.db_disp_recta(grid + Vector3.ONE * 0.5, Vector3.ONE * 0.9, Color(Color.BLUE_VIOLET, 0.3))
		steps_storage.append(grid)
		await time(1.0)

		var traversed := start_position + step * steps[axis]
		debug_ui.db_disp_recta(traversed, Vector3.ONE * 0.2, Color(Color.REBECCA_PURPLE, 0.1))
		debug_ui.db_disp_rc(traversed, _traversd - traversed, Color(Color.AQUA, 0.5))
		debug_ui.db_disp_recta(traversed.floor() + Vector3.ONE * 0.5, Vector3.ONE * 0.5, Color(Color.MEDIUM_AQUAMARINE, 0.7))
		_traversd = traversed
		await time(1.0)

		var block := BlockRaycast._get_block(grid, _world)
		if block != BlockTypes.AIR:
			rc.failure = false
			rc.steps_traversed = steps_storage
			rc.xyz_axis = axis
			rc.found_block = block
			rc.position = traversed
			return rc

		steps[axis] += reciprocal[axis]
		_last_step = debug_ui.db_disp_rc(_last_step.target_position + _last_step.global_position, steps, Color(Color.YELLOW_GREEN, 0.1))
		await time(1.0)


	rc.failure = true
	rc.steps_traversed = steps_storage
	return rc


func time(tmie: float) -> void:
	await get_tree().create_timer(tmie).timeout
