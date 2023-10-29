class_name CameraController extends Camera3D
## 3D camera controller for testing
##
## adapted from https://github.com/adamviola/simple-free-look-camera/blob/master/camera.gd
##

var _mouse_position := Vector2()
var _total_pitch := 0.0

var _direction := Vector3()

## mouse sensitivity
@export var sensitivity := 0.2

## camera move speed in the world
@export var move_speed := 8.0


func _ready() -> void:
	pass


func _ready_signal() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		_mouse_position = event.relative
	if event is InputEventKey and event.is_action_pressed("ui_home"):
		if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		else:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _physics_process(delta: float) -> void:
	
	_mouse_position *= sensitivity
	var yaw := _mouse_position.x
	var pitch := _mouse_position.y
	_mouse_position = Vector2()
	pitch = clampf(pitch, -90 - _total_pitch, 90 - _total_pitch)
	_total_pitch += pitch
	
	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(deg_to_rad(-yaw))
		rotate_object_local(Vector3(1, 0, 0), deg_to_rad(-pitch))
	
	var input := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	
	_direction = Vector3(input.x, (Input.get_axis("move_down", "move_up")), input.y)
	var mspd := move_speed
	if Input.is_action_pressed("control"):
		mspd *= 8
	translate(_direction * mspd * delta)
	
	World.player_position = global_position
