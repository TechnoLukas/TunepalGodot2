extends Control

@onready var tunepage = $Tunepage

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	tunepage.return_button.visible=false

	var refresh_button = Button.new()
	refresh_button.text = "Refresh"
	refresh_button.position = Vector2(275, 535) 
	refresh_button.size = Vector2(68, 50)

	refresh_button.pressed.connect(_on_refresh_button_pressed)

	add_child(refresh_button)

func showpage():
	self.visible=true
	refresh_page()

func refresh_page():
	if sqlite.tunes.size() == 0:
		tunepage.show_empty_database_message()
		return
		
	var idx = randi_range(0, sqlite.tunes.size()-1) ## index zero wouldn't work here so changed to 1 ## it's fine, works again, could be a bug
	var data = sqlite.tunes[idx]
	tunepage.show_tune_page(data)

func _on_refresh_button_pressed():
	sqlite.tunes = sqlite.load_db(clientside.prefix + "://assets/data/tunepal.db")
	refresh_page()
	
func hidepage():
	self.visible=false

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
