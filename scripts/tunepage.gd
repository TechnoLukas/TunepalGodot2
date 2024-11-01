extends Control

@onready var tune_label = $Container/container/label
@onready var abc_field = $MiddleSection/SectionWithMargin/ScrollContainer/abc_field

@onready var add_button = $BottomSection/SectionWithMargin/HBoxContainer/add_buttton
@onready var play_and_pause_button = $BottomSection/SectionWithMargin/HBoxContainer/play_and_pause_button

@onready var midi_player = $MidiPlayer
var midi_player_stoped_position = 0.0

var symbols = ["",""]
var symbols_idx = 0


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

func string_to_packed_byte_array(input_string: String) -> PackedByteArray:
	var byte_array = PackedByteArray()
	var values = input_string.split(",")  # Split the string by commas
	for value in values:
		byte_array.push_back(int(value.strip_edges()))  # Convert each item to integer and add to array
	return byte_array
	

func _on_tunes_list_show_tune_page(data: Variant) -> void:
	self.visible=true
	#print(data.keys())
	var midi_sequence = string_to_packed_byte_array(data["midi_sequence"])
	print(midi_sequence)
	tune_label.text = data["accented_title"]
	abc_field.text=data["notation"]
	
	midi_player.file = clientside.prefix + "://assets/Roscommon.mid"
	midi_player.soundfont = clientside.prefix + "://assets/soundfonts/GM.sf2"
	#midi_player.soundfont # "res://assets/Live HQ Natural SoundFont GM.sf2" is good

func _on_return_button_pressed() -> void:
	self.visible=false

	
func _on_play_and_pause_button_pressed():
	if symbols_idx == 0: play(); 
	else: pause();
		
	symbols_idx = 1 - symbols_idx
	play_and_pause_button.get_node("label").text=symbols[symbols_idx]

func play():
	print("to play")
	midi_player.play(midi_player_stoped_position)

func pause():
	print("to pause")
	midi_player_stoped_position = midi_player.position
	midi_player.stop()
	
func _on_midi_player_finished() -> void:
	print("finised")
	symbols_idx = 0
	play_and_pause_button.get_node("label").text=symbols[symbols_idx]
	midi_player_stoped_position = 0.0
