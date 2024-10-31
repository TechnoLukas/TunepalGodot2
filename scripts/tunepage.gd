extends Control

@onready var tune_label = $Container/container/label
@onready var abc_field = $MiddleSection/SectionWithMargin/ScrollContainer/abc_field

@onready var add_button = $BottomSection/SectionWithMargin/HBoxContainer/add_buttton
@onready var play_and_pause_button = $BottomSection/SectionWithMargin/HBoxContainer/play_and_pause_button

var symbols = ["",""]
var symbols_idx = 0


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass


func _on_tunes_list_show_tune_page(data: Variant) -> void:
	self.visible=true
	tune_label.text = data["accented_title"]
	abc_field.text=data["notation"]

func _on_return_button_pressed() -> void:
	self.visible=false

	
func _on_play_and_pause_button_pressed():
	if symbols_idx == 0: play(); 
	else: pause();
		
	symbols_idx = 1 - symbols_idx
	play_and_pause_button.get_node("label").text=symbols[symbols_idx]

func play():
	print("to play")

func pause():
	print("to pause")
