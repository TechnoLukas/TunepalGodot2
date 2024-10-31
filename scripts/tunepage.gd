extends Control

@onready var tune_label = $Container/container/label
@onready var abc_field = $MiddleSection/SectionWithMargin/ScrollContainer/abc_field
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_tunes_list_show_tune_page(data: Variant) -> void:
	self.visible=true
	tune_label.text = data["accented_title"]
	abc_field.text=data["notation"]


func _on_reuturn_button_pressed() -> void:
	self.visible=false
