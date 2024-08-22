class_name ChunkMeshThread

var _thread := Thread.new()
var _semaph := Semaphore.new()
var active := false
var _queue: Array = []


func _init() -> void:
	_thread.start(_threaded_meshing)


func _threaded_meshing() -> void:
	while true:
		print("-- MESH waiting")
		_semaph.wait()
		print("-- MESH genning")
