extends Control

@onready var return_button = $Container/container/return_button

@onready var tune_label = $Container/container/label
@onready var abc_field = $MiddleSection/SectionWithMargin/ScrollContainer/abc_field

@onready var add_and_remove_button = $BottomSection/SectionWithMargin/HBoxContainer/add_and_remove_button
@onready var play_and_pause_button = $BottomSection/SectionWithMargin/HBoxContainer/play_and_pause_button

@onready var midi_player = $MidiPlayer
var midi_player_stoped_position = 0.0

var play_and_pause_symbols = ["",""]
var play_and_pause_symbols_idx = 0

var add_and_remove_symbols = ["",""]
var add_and_remove_symbols_idx = 0

var this_tune

signal returned

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
	

func show_tune_page(data: Variant) -> void:
	this_tune = data
	add_and_remove_symbols_idx = 0
	
	self.visible=true
	#print(data.keys())
	var midi_sequence = string_to_packed_byte_array(data["midi_sequence"])
	tune_label.text = data["accented_title"]
	abc_field.text=data["notation"]
	
	midi_player.file = clientside.prefix + "://assets/midi/Roscommon.mid"
	midi_player.soundfont = clientside.prefix + "://assets/soundfonts/GM.sf2"
	#midi_player.soundfont # "res://assets/Live HQ Natural SoundFont GM.sf2" is good
	
	if this_tune in sqlite.user_tunes:
		add_and_remove_symbols_idx = 1
		
	add_and_remove_button.get_node("label").text=add_and_remove_symbols[add_and_remove_symbols_idx]

func _on_return_button_pressed() -> void:
	emit_signal("returned")
	self.visible=false
	
func _on_visibility_changed() -> void:
	print(self.visible)
	if (not self.visible or not get_parent().visible) and (midi_player != null): 
		pause()
		_on_midi_player_finished()

## MIDI BUTTONS 
func update_play_and_pause_button_icon():
	play_and_pause_button.get_node("label").text=play_and_pause_symbols[play_and_pause_symbols_idx]
	
func _on_play_and_pause_button_pressed():
	if play_and_pause_symbols_idx == 0: play(); 
	else: pause();
		
	play_and_pause_symbols_idx = 1 - play_and_pause_symbols_idx
	update_play_and_pause_button_icon()

func play():
	print("to play")
	midi_player.play(midi_player_stoped_position)

func pause():
	print("to pause")
	midi_player_stoped_position = midi_player.position
	midi_player.stop()
	
func _on_midi_player_finished() -> void:
	print("finised")
	play_and_pause_symbols_idx = 0
	update_play_and_pause_button_icon()
	midi_player_stoped_position = 0.0
	

## BOOKMARKS BUTTONS 

func _on_add_and_remove_button_pressed() -> void:
	if add_and_remove_symbols_idx == 0: add(); 
	else: remove();
		
	add_and_remove_symbols_idx = 1 - add_and_remove_symbols_idx
	add_and_remove_button.get_node("label").text=add_and_remove_symbols[add_and_remove_symbols_idx]
	
func add():
	print("to add")
	#var tunes = sqlite.tunes
	#var idx = tunes.find(this_tune)
	sqlite.user_tunes.append(this_tune)
	sqlite.save_json(clientside.prefix + sqlite.default_user_tunes_path)

func remove():
	print("to remove")
	if this_tune in sqlite.user_tunes:
		sqlite.user_tunes.pop_at(sqlite.user_tunes.find(this_tune))
	sqlite.save_json(clientside.prefix + sqlite.default_user_tunes_path)
