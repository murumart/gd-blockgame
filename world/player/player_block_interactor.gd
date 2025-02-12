extends Node3D

@export var world: World
@onready var outline: MeshInstance3D = $Outline


func _process(delta: float) -> void:
	outline.hide()
	var raycast := BlockRaycast.cast_ray_fast_vh(
			global_position, -global_basis.z, 6, world)
	if raycast.failure:
		return
	display_selected_block(raycast)
	
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		print(raycast)
		if not raycast.failure:
			world.place_block(raycast.get_collision_point(), 0)
			
	elif Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		if not raycast.failure:
			var add_vec := Vector3.ZERO
			add_vec[raycast.xyz_axis] = -raycast.axis_direction
			world.place_block(raycast.get_collision_point() + add_vec, 1)


func display_selected_block(raycast: BlockRaycast) -> void:
	outline.show()
	var add_vec := Vector3.ZERO
	#add_vec[raycast.xyz_axis] = 1
	outline.global_rotation = Vector3.ZERO
	outline.global_position = (raycast.get_collision_point() + add_vec + Vector3.ONE * 0.5)
	
