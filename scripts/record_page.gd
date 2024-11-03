extends Control

@onready var record_button = $VBoxContainer/bottom_part/record_button
@onready var timer = $Timer

var countdown_time=0
var recording_time=10
var default_lable_value
var action = "" # countdown & recording
var record : AudioEffectRecord
var record_bus_index

var tunepal = Tunepal.new()

var thread: Thread
var transcription:String

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	tunepal_test()
	default_lable_value = record_button.get_node("label").text
	
	record_bus_index = AudioServer.get_bus_index("Record")
	record = AudioServer.get_bus_effect(record_bus_index, 0)
	
	#AudioServer.get_bus_effect(record_bus_index, 0).set_buffer_length(.1)
	#AudioServer.get_bus_effect(record_bus_index, 0).tap_back_pos = .05
	#spectrum = AudioServer.get_bus_effect_instance(record_bus_index, 0)
	tunepal.search_completed.connect(finished_searching)
	add_child(tunepal)
	
	# print(tunepal.edSubstring("BDEE", "DGGGDGBDEFGAB", 0))
	print("Substring test")
	print()
	

	

	var needle = "GACEEEFGEDBBAGBAAACEEFGEDBGGGGEDEGAAAEGEDBBAGBAAACEEFGEDBGBDDAGACEEFG"
	var search_key = "ADDDCBAAFGABAFEEEFGAFFEDBADEFGEDDDDDEFGFDEDCBABCDDDEFEEEAGFGADFEDDEFGEDDDD"

	
	print(tunepal.edSubstring(needle, search_key, 0))
	print(tunepal.edSubstringOld(needle, search_key, 0))

	
	
	var tune = sqlite.tunes[0]
	var notation:String = tune["notation"]
	var file_name:String = tune["file_name"]
	var midi_file_name = "temp_tune.mid"
	tunepal.create_midi_file(notation, file_name, midi_file_name, 0 , 0, 0, 0)

	
	thread = Thread.new()
	transcription = "GACEEEFGEDBBAGBAAACEEFGEDBGGGGEDEGAAAEGEDBBAGBAAACEEFGEDBGBDDAGACEEFG"
	thread.start(tunepal.findClosest.bind(transcription, sqlite.tunes))
	##
	
func showpage():
	self.visible = true
	
func hidepage():
	self.visible = false

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
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
	timer.wait_time = countdown_time
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
	#recording.set_mix_rate(22050)
	#recording.set_format(1)
	#recording.set_stereo(false)
	var audio_data = recording.get_data()
	# print(sqlite.query_result[0].keys())
	
	print("Format ", recording.format)
	print("Mix rate ", recording.mix_rate)
	print("Stereo ", recording.stereo)
	
	print(sqlite.query_result[0]["midi_sequence"])
	# print("Audio buffer as array of floats:", audio_data)
			
			
	# Testing with output !!
	# var data = recording.get_data()
	# print(data.size())
	
	transcription = tunepal.transcribe(audio_data, 3)
	
	print("Transcription: " + transcription)
	
	thread = Thread.new()
	thread.start(tunepal.findClosest.bind(transcription, sqlite.query_result))
	# 
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
	
func finished_searching(results:Array):
	
	# print("Results" + str(results))
	
	for i in range(results.size()):
		# print(results[i])
		
		
		var confidence = 1.0 - (results[i]["edit_distance"] / transcription.length())
		print(str(results[i]["title"])
		 + "\t" + str(results[i]["alt_title"])
# 		 + "\t" + str(results[i]["search_key"])
		 + "\t" + str(results[i]["edit_distance"])
		 )
	
	

func _on_timer_timeout() -> void:
	if action == "countdown":
		start_recording()
	elif action == "recording":
		stop_recording()
