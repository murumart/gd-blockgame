extends Node3D

var rs := RenderingServer

var mesh: RID
var instance: RID

@onready var world := get_world_3d()


func _ready() -> void:

	mesh = rs.mesh_create()
	instance = rs.instance_create()

	rs.instance_set_scenario(instance, world.scenario)
	rs.instance_set_base(instance, mesh)

	var vertices: PackedVector3Array = [
		Vector3(1, 0, 0),
		Vector3(-1, 0, 0),
		Vector3(0, 1, 0),
	]
	var indices: PackedInt32Array = [
		0, 1, 2
	]

	var arrays := []
	arrays.resize(ArrayMesh.ARRAY_MAX)
	arrays[ArrayMesh.ARRAY_VERTEX] = vertices
	arrays[ArrayMesh.ARRAY_INDEX] = indices

	rs.mesh_add_surface_from_arrays(
		mesh,
		rs.PRIMITIVE_TRIANGLES,
		arrays,
	)


func _exit_tree() -> void:
	rs.free_rid(mesh)
	rs.free_rid(instance)
