extends CharacterBody3D

const SPEED = 5.0
const JUMP_VELOCITY = 8.0
const GRAV_MULT := 2.5
const MAX_FALL_SPEED := 60.0

@onready var camera_pivot: Node3D = $CameraPivot
@onready var camera: Camera3D = $CameraPivot/Camera3D


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


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


func _physics_process(delta: float) -> void:
	var on_floor := is_on_floor()
	var friction := SPEED * int(on_floor)
	# Add the gravity.
	if not on_floor:
		velocity += get_gravity() * delta * GRAV_MULT
		velocity.y = maxf(minf(velocity.y, MAX_FALL_SPEED), -MAX_FALL_SPEED)

	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	input_dir = input_dir.rotated(-camera_pivot.rotation.y)
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = move_toward(velocity.x, direction.x * SPEED, SPEED * delta * (friction + 0.5))
		velocity.z = move_toward(velocity.z, direction.z * SPEED, SPEED * delta * (friction + 0.5))
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED * delta * friction)
		velocity.z = move_toward(velocity.z, 0, SPEED * delta * friction)

	if Input.is_action_pressed("ui_accept") and on_floor:
		velocity.y = JUMP_VELOCITY
		if direction:
			velocity.x *= 1.5
			velocity.z *= 1.5

	move_and_slide()
