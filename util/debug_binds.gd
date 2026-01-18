class_name Debug_Binds extends Node

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
			RenderingServer.viewport_set_debug_draw(
				_vp.get_viewport_rid(), DEBUG_MODES[_current_mode])
			_current_mode = posmod(_current_mode + 1, DEBUG_MODES.size())
