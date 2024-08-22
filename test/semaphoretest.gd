extends Node

var counter := 0
var mutex := Mutex.new()
var semaphore := Semaphore.new()
var thread := Thread.new()
var exit_thread := false


# The thread will start here.
func _ready() -> void:
	thread.start(_thread_function)


func _physics_process(delta: float) -> void:
	if Input.is_key_pressed(KEY_1):
		print(get_counter())
	if Input.is_key_pressed(KEY_2):
		increment_counter()
	if Input.is_key_pressed(KEY_3):
		get_tree().change_scene_to_file("res://test/chunk_3d_test.tscn")


func _thread_function() -> void:
	while true:
		print("before wait")
		semaphore.wait() # Wait until posted.
		print("not wait")

		mutex.lock()
		var should_exit := exit_thread # Protect with Mutex.
		mutex.unlock()

		if should_exit:
			break

		mutex.lock()
		counter += 1 # Increment counter, protect with Mutex.
		mutex.unlock()


func increment_counter() -> void:
	semaphore.post() # Make the thread process.


func get_counter() -> int:
	mutex.lock()
	# Copy counter, protect with Mutex.
	var counter_value := counter
	mutex.unlock()
	return counter_value


# Thread must be disposed (or "joined"), for portability.
func _exit_tree() -> void:
	# Set exit condition to true.
	mutex.lock()
	exit_thread = true # Protect with Mutex.
	mutex.unlock()

	# Unblock by posting.
	semaphore.post()

	# Wait until it exits.
	thread.wait_to_finish()

	# Print the counter.
	print("Counter is: ", counter)
