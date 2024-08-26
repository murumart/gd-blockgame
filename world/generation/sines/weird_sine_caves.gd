class_name WeirdSineCave extends GeneratorSettings

@export var in_block := 0
@export var out_block := 1
@export var overall_addition := Vector3.ZERO
@export var overall_multiplier := 0.05
@export var n_z_expo := 2.0
@export var layer_y_mult := 2.0
@export var position_y_mult := 10.0
@export var position_z_mult := 10.0


func get_block_at(pos: Vector3) -> int:
	var addon := _get_addons_block(pos)
	if not should_addon_block_be_ignored(addon):
		return addon
	pos += overall_addition
	pos *= overall_multiplier
	var n1 := sin(pos.y * pos.x - pow(pos.z, n_z_expo))
	var n2 := pos.y * sin(pos.y
			* layer_y_mult) * position_y_mult + sin(pos.x) * cos(pos.z) * position_z_mult
	if n1 > n2:
		return in_block
	return out_block
