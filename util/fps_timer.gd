class_name Debug_FpsTimer extends Timer


func _ready() -> void:
	one_shot = false
	wait_time = 1.0
	timeout.connect(_print_fps)
	start()


func _print_fps() -> void:
	print("FPS : ", Engine.get_frames_per_second())
