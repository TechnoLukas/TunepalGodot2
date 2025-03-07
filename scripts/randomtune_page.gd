extends Control

@onready var tunepage = $Tunepage

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	tunepage.return_button.visible=false

func showpage():
	self.visible=true
	var idx = randi_range(0, sqlite.tunes.size()-1) ## index zero wouldn't work here so changed to 1 ## it's fine, works again, could be a bug
	var data = sqlite.tunes[idx]
	tunepage.show_tune_page(data)
	
	
func hidepage():
	self.visible=false

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
