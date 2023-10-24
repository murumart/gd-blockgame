class_name Noises extends RefCounted

static var noise1 := FastNoiseLite.new()


static func _static_init() -> void:
	noise1.frequency = 0.005
