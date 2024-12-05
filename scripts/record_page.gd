extends Control

@onready var record_button = $record_button
@onready var record_button_lable = $VBoxContainer/bottom_part/label
@onready var timer = $Timer
@onready var indicator = $Node2D

var countdown_time=3.0
var recording_time=9.0
var default_lable_value
var action = "" # countdown & recording
var record : AudioEffectRecord
var record_bus_index

var arc_angle = 0.0

var tunepal = Tunepal.new()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	tunepal_test()
	default_lable_value = record_button_lable.text
	
	record_bus_index = AudioServer.get_bus_index("Record")
	record = AudioServer.get_bus_effect(record_bus_index, 0)

func showpage():
	self.visible = true
	
func hidepage():
	self.visible = false

func _process(_delta: float) -> void:
	if action == "countdown":
		button_lable_set(str(int(timer.time_left)+1))
	elif action == "recording":
		arc_angle = (timer.time_left/recording_time)
		button_lable_set("Recording...")
		indicator.angle = arc_angle*360
	else:
		indicator.angle=0

func button_lable_set(text):
	record_button_lable.text=text

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
	print(sqlite.tunes[0].keys())
	print(sqlite.tunes[0]["midi_sequence"])
	print("Audio buffer as array of floats:", audio_data)
			
			
	# Testing with output !!
	var data = recording.get_data()
	print(data.size())
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
