class_name SineLayersSineLayer extends Resource

enum Valem {SINE, COSINE, TANGENT}
enum Modes {ADD, MULTIPLY}
enum Components {X, Y, Z}

@export var valem: Valem
@export var frequency := 0.1
@export var amplitude := 4.0
@export var position_component := Components.X
@export var mode := Modes.ADD


func get_layer_y(pos: Vector3) -> float:
	var value := pos[position_component]
	match valem:
		Valem.SINE: return sin(value * frequency) * amplitude
		Valem.COSINE: return cos(value * frequency) * amplitude
		Valem.TANGENT: return tan(value * frequency) * amplitude
	return -1.0
