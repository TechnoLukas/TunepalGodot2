extends Control

@onready var record_button = $VBoxContainer/bottom_part/record_button
@onready var timer = $Timer

var countdown_time=2
var recording_time=9
var default_lable_value
var action = "" # countdown & recording
var record : AudioEffectRecord
var record_bus_index

var tunepal = Tunepal.new()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	tunepal_test()
	default_lable_value = record_button.get_node("label").text
	
	record_bus_index = AudioServer.get_bus_index("Record")
	record = AudioServer.get_bus_effect(record_bus_index, 0)
	
	#AudioServer.get_bus_effect(record_bus_index, 0).set_buffer_length(.1)
	#AudioServer.get_bus_effect(record_bus_index, 0).tap_back_pos = .05
	#spectrum = AudioServer.get_bus_effect_instance(record_bus_index, 0)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if action == "countdown":
		button_lable_set(str(round(timer.time_left)))
	elif action == "recording":
		button_lable_set("Recording...")
	# button_lable_set("..." + str(countdown_time-i) + "...")

func button_lable_set(text):
	record_button.get_node("label").text=text

func _on_record_button_pressed() -> void:
	record_button.disabled=true
	action = "countdown"
	timer.start(countdown_time)
	
func start_recording():
	#audio_stream_recorder.play()
	record.set_recording_active(true)
	
	button_lable_set("Recording ...")
	action = "recording"
	timer.start(recording_time)
	
func stop_recording():
	#audio_stream_recorder.stop()
	record.set_recording_active(false)
	var recording = record.get_recording()
	
	var audio_data = recording.get_data()
	print(sqlite.query_result[0].keys())
	print(sqlite.query_result[0]["midi_sequence"])
	# print("Audio buffer as array of floats:", audio_data)
			
			
	# Testing with output !!
	# var data = recording.get_data()
	# print(data.size())
	
	var s = tunepal.transcribe(audio_data, 0)
	
	print("Transcription: " + s)
	
	$AudioStreamPlayer.stream = recording
	$AudioStreamPlayer.play()
	
	record_button.disabled=false
	action = ""
	button_lable_set(default_lable_value)
	
func tunepal_test():
	var pattern = "BREXDDDDD"
	var text = "THERE IS NO BREAD"
	tunepal.say_hello()
	print(tunepal.edSubstring(pattern, text, 0))
	pass

func _on_timer_timeout() -> void:
	if action == "countdown":
		start_recording()
	elif action == "recording":
		stop_recording()
