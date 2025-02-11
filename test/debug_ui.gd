class_name DebugUI extends Control

@export var camera: Camera3D
@export var world: World

@onready var label: Label = $Label
@onready var rc_label: Label = $RcLabel

@onready var recenterer: Node = world.get_node("Recenterer")

func _physics_process(_delta: float) -> void:
	label.text = get_text()
	rc_label.text = get_raycast_text()


func get_text() -> String:
	var wpos := camera.global_position + world.world_position
	var chunk_pos_old := World.world_pos_to_chunk_pos(camera.global_position)
	var chunk_pos := World.world_pos_to_chunk_pos(camera.global_position + world.world_position)
	return (
			"fps: " + str(Engine.get_frames_per_second())
			+ "\ngpos: " + str(camera.global_position)
			+ "\nwpos: " + str(wpos)
			+ "\nchunk_pos_old: " + str(chunk_pos_old)
			+ "\nchunk_pos: " + str(chunk_pos)
			+ "\nworld_pos: " + str(world.world_position)
			+ "\npos_in_chunk: " + str(wpos.round() - chunk_pos * Vector3(Chunk.SIZE))
			+ "\nrecenter_region: " + str(recenterer._last_region_position)
			+ "\nfacing: " + str(camera.global_basis.z)

			#+ "\ngen_queue_size: " + str(world.world_generator._queue.size())
	)


func get_raycast_text() -> String:
	var raycast := BlockRaycast.cast_ray_fast_vh(camera.global_position, -camera.global_basis.z.normalized(), 9, world)
	if Input.is_action_just_pressed("ui_focus_next"):
		db_disp_rc(camera.global_position, -camera.global_basis.z, Color.WHITE)
		db_disp_rc(camera.global_position, -camera.global_basis.z * 20, Color(1, 1, 1, 0.05))
		#db_disp_rc(camera.global_position, raycast._debug_data["pre"]["reciprocal"], Color(0.0, 1.0, 0.0, 0.05))
		#db_disp_recta(raycast._debug_data["pre"]["grid"] + Vector3.ONE * 0.5, Vector3.ONE * 0.75, Color(1.0, 0.0, 1.0, 0.3))
		#var prevstep: Vector3 = raycast._debug_data["pre"]["steps"]
		var prevtrav := camera.global_position
		for step in raycast.steps_traversed:
			db_disp_recta(step + Vector3.ONE * 0.5, Vector3.ONE * 0.8, Color(1, 1, 1, 0.1))
	if Input.is_action_just_pressed("ui_text_toggle_insert_mode"):
		rc_label.visible = not rc_label.visible
	return (
			"raycast: " + str(raycast)
	)


func db_disp_rc(gpos: Vector3, tpos: Vector3, color: Color) -> RayCast3D:
	var rc := RayCast3D.new()
	world.add_child(rc)
	rc.global_position = gpos
	rc.target_position = tpos
	rc.debug_shape_custom_color = color
	rc.collision_mask = 0
	return rc


func db_disp_recta(gpos: Vector3, skaala: Vector3, color: Color) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mi.mesh = mesh
	mesh.size = skaala
	var mat := StandardMaterial3D.new()
	mesh.material = mat
	mat.albedo_color = color
	#mat.blend_mode = BaseMaterial3D.BLEND_MODE_MUL
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	world.add_child(mi)
	mi.global_position = gpos
	return mi
