extends Control

@onready var tunelist = $TunesList
@onready var tunepage = $Tunepage
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass

func showpage():
	update_list()
	self.visible = true


func hidepage():
	self.visible = false
	
func update_list():
	tunelist.clear_list()
	var data = sqlite.user_tunes
	for i in range(0,data.size()):
		tunelist.add_item(data[i])

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_tunepage_returned() -> void:
	update_list()
