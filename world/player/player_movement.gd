extends CharacterBody3D

const SPEED = 5.0
const MAX_FALL_SPEED := 60.0

const JUMP_HEIGHT := 1.0

const ACCELERATION := 24.0
const FRICTION := 24.0

@onready var camera_pivot: Node3D = $CameraPivot
@onready var camera: Camera3D = $CameraPivot/Camera3D

@export var world: World

var jump_velocity := 0.0


func _ready() -> void:
	assert(is_instance_valid(world))
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

	var grav := (-2.0 * JUMP_HEIGHT * SPEED**2.0)
	jump_velocity = -grav * (1.0 / SPEED)


func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		var mouse_event := event as InputEventMouseMotion
		var motion := mouse_event.relative * 0.003
		camera_pivot.rotate_y(-motion.x)
		camera.rotate_x(-motion.y)
		camera.rotation_degrees = Vector3(
				clampf(camera.rotation_degrees.x, -89, 89),
				camera.rotation_degrees.y,
				camera.rotation_degrees.z)

	elif event is InputEventMouseButton and event.is_released() and event.button_index == MOUSE_BUTTON_RIGHT:
		Input.mouse_mode = (Input.MOUSE_MODE_VISIBLE
				if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED
				else Input.MOUSE_MODE_CAPTURED)
	elif event is InputEventMouseButton and event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT:
		var raycast := BlockRaycast.cast_ray_fast(
				camera.global_position, -camera.global_basis.z, 9, world)
		print(raycast)
		if not raycast.failure:
			#world.place_block(raycast.get_collision_point(), BlockTypes.AIR)
			var add_vec := Vector3.ZERO
			add_vec[raycast.xyz_axis] = 1
			#world.place_block(raycast.get_collision_point() + add_vec, 1)
			world.place_block(raycast.get_collision_point(), 0)
		#for pos in raycast.steps_traversed:
			#var mesh := MeshInstance3D.new()
			#mesh.mesh = BoxMesh.new()
			#world.add_child(mesh)
			#mesh.global_position = pos + Vector3.ONE * 0.5



func _physics_process(delta: float) -> void:
	_movement(delta)

	move_and_slide()

	var raycast := BlockRaycast.cast_ray_fast(
			camera.global_position, -camera.global_basis.z, 9, world)
	if raycast.failure:
		return
	var mesh := MeshInstance3D.new()
	mesh.mesh = BoxMesh.new()
	world.add_child(mesh)
	var add_vec := Vector3.ZERO
	#add_vec[raycast.xyz_axis] = 1
	mesh.global_position = (raycast.get_collision_point() + add_vec + Vector3.ONE * 0.5)
	mesh.scale = Vector3.ONE * 1.01
	var tw := mesh.create_tween()
	tw.tween_interval(0.1)
	tw.tween_callback(mesh.queue_free)


# based on a queen of squiggles youtube tutorial series.
func _movement(delta: float) -> void:
	var on_floor := is_on_floor()
	var gravity := get_gravity()
	var input := Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var target_velo := Vector3()
	var forward := camera.global_basis.z
	var right := camera.global_basis.x
	var current_speed := SPEED
	target_velo += camera.global_basis.x * input.x
	target_velo += camera.global_basis.z * input.y
	target_velo.y = 0.0
	target_velo = target_velo.normalized() * current_speed
	target_velo.y = velocity.y

	var target_accel := ACCELERATION if input else FRICTION
	velocity = velocity.move_toward(target_velo, target_accel * delta)

	if not on_floor:
		velocity += gravity * delta
		velocity.y = clampf(velocity.y, -MAX_FALL_SPEED, MAX_FALL_SPEED)
	else:
		velocity.y = 0.0

	if Input.is_action_pressed("jump") and on_floor and velocity.y <= 0.0:
		velocity.y = jump_velocity
