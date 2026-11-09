extends Control

@onready var fish_name_label: Label = $Panel/Content/FishNameLabel
@onready var fish_rarity_label: Label = $Panel/Content/FishRarityLabel
@onready var fish_scene: Node3D = $Panel/Content/FishPreview/SubViewport/FishScene
@onready var fish_catch_sound: AudioStreamPlayer = $FishCatchSound
@onready var close_instruction_label: Label = $Panel/CloseInstructionLabel
@onready var fish_aura: TextureRect = $Panel/Content/AuraLayer/FishAura


var catch_display_open: bool = false
var current_preview: Node3D = null
var preview_rotation_speed: float = 0.8

func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	
func _process(delta: float) -> void:
	if catch_display_open and current_preview != null:
		current_preview.rotate_y(preview_rotation_speed * delta)

func blink_close_instruction() -> void:
	close_instruction_label.modulate.a = 1.0

	var tween = create_tween()
	tween.set_loops()
	tween.tween_property(close_instruction_label, "modulate:a", 0.3, 1.0)
	tween.tween_property(close_instruction_label, "modulate:a", 1.0, 1.0)

func show_caught_fish(fish: FishData) -> void:
	var fish_journal = get_tree().get_first_node_in_group("fish_journal")
	if fish_journal != null:
		fish_journal.register_caught_fish(fish)
		
	var inventory = get_tree().get_first_node_in_group("player_inventory")
	if inventory != null:
		inventory.add_fish(fish)
		
	get_tree().paused = true
	fish_name_label.text = "You caught a " + fish.fish_name + "!"
	fish_rarity_label.text = FishData.FishRarity.keys()[fish.rarity]
	
	match fish.rarity:
		FishData.FishRarity.COMMON:
			fish_rarity_label.add_theme_color_override("font_color", Color("#A8D5A2"))
			fish_aura.modulate = Color("#A8D5A2")
		
		FishData.FishRarity.UNCOMMON:
			fish_rarity_label.add_theme_color_override("font_color", Color("#83CDE8"))
			fish_aura.modulate = Color("#83CDE8")
		
		FishData.FishRarity.RARE:
			fish_rarity_label.add_theme_color_override("font_color", Color("#C5A3F5"))
			fish_aura.modulate = Color("#C5A3F5")
		
		FishData.FishRarity.EPIC:
			fish_rarity_label.add_theme_color_override("font_color", Color("#F2A1D5"))
			fish_aura.modulate = Color("#F2A1D5")
		
		FishData.FishRarity.LEGENDARY:
			fish_rarity_label.add_theme_color_override("font_color", Color("#FFD580"))
			fish_aura.modulate = Color("#FFD580")
	
	# Remove the previous fish preview
	if current_preview != null:
		current_preview.queue_free()
		current_preview = null
	
	# Display the fish that was caught
	if fish.fish_scene != null:
		current_preview = fish.fish_scene.instantiate() as Node3D
		fish_scene.add_child(current_preview)
	else:
		print("No fish scene assigned to: ", fish.fish_name)
	
	# Show the catch display
	visible = true
	catch_display_open = true
	close_instruction_label.text = "Click left mouse to close"
	close_instruction_label.show()
	blink_close_instruction()
	fish_catch_sound.play()
	
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	print("Catch display shown! Visible: ", visible)

func _input(event: InputEvent) -> void:
	if not catch_display_open:
		return
	
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			close_catch_display()
			
func close_catch_display() -> void:
	catch_display_open = false
	visible = false
	
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	get_tree().paused = false
	print("Catch display closed!")
