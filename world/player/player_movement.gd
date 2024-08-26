extends CharacterBody3D

const SPEED = 5.0
const JUMP_VELOCITY = 4.5

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
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	input_dir = input_dir.rotated(-camera_pivot.rotation.y)
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()
