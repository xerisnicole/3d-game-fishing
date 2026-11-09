extends HBoxContainer

var selected_slot = 1
var fishing_rod_equipped : bool = false

@onready var slot1 = $Slot1
@onready var slot2 = $Slot2
@onready var proto_controller: CharacterBody3D = $"../../../ProtoController"


func _ready():
	update_selected_slot()


func _unhandled_key_input(event):
	if event.pressed:
		if event.keycode == KEY_1:
			selected_slot = 1
			update_selected_slot()
			update_equipped_item()
		
		elif event.keycode == KEY_2:
			selected_slot = 2
			update_selected_slot()
			update_equipped_item()


func update_selected_slot():
	var slot1_style = slot1.get_theme_stylebox("panel").duplicate()
	var slot2_style = slot2.get_theme_stylebox("panel").duplicate()
	
	if selected_slot == 1:
		slot1_style.border_width_left = 4
		slot1_style.border_width_top = 4
		slot1_style.border_width_right = 4
		slot1_style.border_width_bottom = 4
		
		slot2_style.border_width_left = 2
		slot2_style.border_width_top = 2
		slot2_style.border_width_right = 2
		slot2_style.border_width_bottom = 2
	else:
		slot1_style.border_width_left = 2
		slot1_style.border_width_top = 2
		slot1_style.border_width_right = 2
		slot1_style.border_width_bottom = 2
		
		slot2_style.border_width_left = 4
		slot2_style.border_width_top = 4
		slot2_style.border_width_right = 4
		slot2_style.border_width_bottom = 4
	
	slot1.add_theme_stylebox_override("panel", slot1_style)
	slot2.add_theme_stylebox_override("panel", slot2_style)

func equip_fishing_rod():
	fishing_rod_equipped = true
	update_equipped_item()

func update_equipped_item():
	if fishing_rod_equipped and selected_slot == 1:
		proto_controller.fishing_rod.visible = true
	else:
		proto_controller.fishing_rod.visible = false
