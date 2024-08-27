extends Label3D

@export var chunk: Chunk


func _ready() -> void:
	set_process(visible)
	position = Chunk.SIZE * 0.5


func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_page_up"):
		set_process(true)
		show()
	elif event.is_action_pressed("ui_page_down"):
		set_process(false)
		hide()


func _process(_delta: float) -> void:
	do_text()


func do_text() -> void:
	text = ("pos: " + chunk.name
			+ "\nload_step: " + str(Chunk.LoadSteps.find_key(chunk.load_step))
			+ "\nblock_data size: " + str(chunk.data.block_data.size())
			+ "\nhistory: " + str(chunk._history)
	)
