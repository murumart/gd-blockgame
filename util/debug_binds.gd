class_name Debug_Binds extends Node

@export var world: World

const DEBUG_MODES := [
	RenderingServer.VIEWPORT_DEBUG_DRAW_DISABLED,
	RenderingServer.VIEWPORT_DEBUG_DRAW_WIREFRAME,
]
var _current_mode := 0
var _vp: Viewport


func _ready() -> void:
	_vp = get_viewport()
	print("Debug_Binds::_ready : viewport is ", _vp)


func _unhandled_key_input(event: InputEvent) -> void:
	var e := event as InputEventKey
	if e.pressed: match e.keycode:
		KEY_Z:
			_current_mode = posmod(_current_mode + 1, DEBUG_MODES.size())
			RenderingServer.viewport_set_debug_draw(
				_vp.get_viewport_rid(), DEBUG_MODES[_current_mode])
		KEY_F7:
			var mesh := world.chunk_renderer.meshes[Vector3i(world.chunk_load_center.global_position / Chunks.C_CHUNK_SIZEF)]
			var am := ArrayMesh.new()
			var arrays := RenderingServer.mesh_surface_get_arrays(mesh, 0)
			am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
			am.surface_set_material(0, preload("res://world/rendering/chunk_material.tres"))
			am.custom_aabb = AABB(Vector3.ZERO, Chunks.C_CHUNK_SIZEF)
			ResourceSaver.save(am, "res://world/rendering/meshtest.tres",ResourceSaver.FLAG_COMPRESS)
