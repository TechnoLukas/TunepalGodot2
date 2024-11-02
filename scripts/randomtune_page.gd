extends Control

@onready var tunepage = $Tunepage

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	tunepage.return_button.visible=false

func showpage():
	self.visible=true
	var idx = randi_range(0, sqlite.query_result.size()-1)
	var data = sqlite.query_result[idx]
	tunepage.show_tune_page(data)
	
	
func hidepage():
	self.visible=false

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
