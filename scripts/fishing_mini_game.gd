extends Control

signal minigame_won
signal minigame_lost

@onready var catch_meter: ProgressBar = $CatchMeter
@onready var timer_label: Label = $TimerLabel
@onready var target_area: Control = $TargetArea
@onready var click_target: Button = $TargetArea/ClickTarget
@onready var slider_target: Button = $TargetArea/SliderTarget
@onready var slider_track: ColorRect = $TargetArea/SliderTrack
@onready var pop_sound: AudioStreamPlayer = $PopSound
@onready var slider_swipe_sound: AudioStreamPlayer = $SliderSwipeSound
@onready var success_ding_sound: AudioStreamPlayer = $SuccessDingSound



var catch_progress: float = 0.0
var progress_per_click: float = 10.0

var time_remaining: float = 10.0
var minigame_active: bool = true

var dragging_slider: bool = false
var slider_halfway_awarded: bool = false
var slider_end_awarded: bool = false

var slider_orientation: int = 0
var slider_diagonal_direction: int = 1
var slider_is_half_size: bool = false

func _ready() -> void:
	randomize()
	hide()
	minigame_active = false
	set_process(false)

	catch_meter.min_value = 0
	catch_meter.max_value = 100
	catch_meter.value = 0

	click_target.pressed.connect(_on_click_target_pressed)
	slider_target.button_down.connect(_on_slider_button_down)
	slider_target.button_up.connect(_on_slider_button_up)

	slider_target.hide()
	update_timer_label()


func _process(delta: float) -> void:
	if not minigame_active:
		return

	time_remaining = maxf(time_remaining - delta, 0.0)
	update_timer_label()

	if time_remaining <= 0.0:
		end_minigame(false)


func _input(event: InputEvent) -> void:
	if not minigame_active or not dragging_slider:
		return

	if event is InputEventMouseMotion:
		move_slider_to_mouse()


func _on_click_target_pressed() -> void:
	if not minigame_active or not click_target.visible:
		return
	
	play_pop_sound(1.0)
	add_catch_progress(10.0)

	if minigame_active:
		spawn_next_target()


func spawn_next_target() -> void:
	if not minigame_active:
		return

	dragging_slider = false
	click_target.hide()
	slider_target.hide()
	slider_track.hide()

	# Randomly choose one target at a time.
	if randf() < 0.5:
		click_target.show()
		randomize_click_position()
	else:
		reset_slider()
		slider_track.show()
		slider_target.show()


func randomize_click_position() -> void:
	var area_size = target_area.size
	var button_size = click_target.size

	var max_x = maxf(0.0, area_size.x - button_size.x)
	var max_y = maxf(0.0, area_size.y - button_size.y)

	click_target.position = Vector2(
		randf_range(0.0, max_x),
		randf_range(0.0, max_y)
	)


func reset_slider() -> void:
	slider_halfway_awarded = false
	slider_end_awarded = false
	dragging_slider = false

	# Randomly choose horizontal, vertical, or diagonal.
	slider_orientation = randi_range(0, 2)

	# Randomly choose half-length or full-length track.
	slider_is_half_size = randf() < 0.5

	# Randomize diagonal direction.
	slider_diagonal_direction = 1 if randf() < 0.5 else -1

	var padding = 60.0

	# Set the track length and rotation.
	if slider_orientation == 0:
		# Horizontal track.
		var track_length = 600.0 if not slider_is_half_size else 300.0
		slider_track.size = Vector2(track_length, 12)
		slider_track.rotation = 0.0

	elif slider_orientation == 1:
		# Vertical track.
		var track_length = 400.0 if not slider_is_half_size else 200.0
		slider_track.size = Vector2(12, track_length)
		slider_track.rotation = 0.0

	else:
		# Diagonal track.
		var track_length = 450.0 if not slider_is_half_size else 225.0
		slider_track.size = Vector2(track_length, 12)
		slider_track.rotation = deg_to_rad(
			35.0 * slider_diagonal_direction
		)

	# Keep the target's size unchanged.
	# Set the track and target rotation pivots.
	slider_track.pivot_offset = slider_track.size / 2.0
	slider_target.pivot_offset = slider_target.size / 2.0

	
	# Calculate the track's actual bounding size.
	var angle = slider_track.rotation
	var track_width = slider_track.size.x
	var track_height = slider_track.size.y

	var rotated_width = (
		absf(cos(angle)) * track_width
		+ absf(sin(angle)) * track_height
	)

	var rotated_height = (
		absf(sin(angle)) * track_width
		+ absf(cos(angle)) * track_height
	)

	# Calculate the safe center range inside TargetArea.
	var half_width = rotated_width / 2.0 + padding
	var half_height = rotated_height / 2.0 + padding

	var min_x = half_width
	var max_x = target_area.size.x - half_width
	var min_y = half_height
	var max_y = target_area.size.y - half_height

	# Pick a safe center position.
	var random_x = (
		randf_range(min_x, max_x)
		if max_x >= min_x
		else target_area.size.x / 2.0
	)

	var random_y = (
		randf_range(min_y, max_y)
		if max_y >= min_y
		else target_area.size.y / 2.0
	)

	# Convert the center position into Godot's top-left position.
	slider_track.position = (
		Vector2(random_x, random_y) - slider_track.size / 2.0
	)


	# Place the target at the start of the track.
	if slider_orientation == 0:
		slider_target.rotation = 0.0
		slider_target.position = Vector2(
			slider_track.position.x,
			slider_track.position.y
				+ (slider_track.size.y - slider_target.size.y) / 2.0
		)

	elif slider_orientation == 1:
		slider_target.rotation = 0.0
		slider_target.position = Vector2(
			slider_track.position.x
				+ (slider_track.size.x - slider_target.size.x) / 2.0,
			slider_track.position.y
		)

	else:
		slider_target.rotation = slider_track.rotation

		var track_center = (
			slider_track.position + slider_track.size / 2.0
		)
		var direction = Vector2.RIGHT.rotated(slider_track.rotation)
		var start_point = (
			track_center - direction * slider_track.size.x / 2.0
		)

		slider_target.position = (
			start_point - slider_target.size / 2.0
		)


func _on_slider_button_down() -> void:
	if not minigame_active or not slider_target.visible:
		return

	dragging_slider = true

	if not slider_swipe_sound.playing:
		slider_swipe_sound.play()


func _on_slider_button_up() -> void:
	dragging_slider = false
	slider_swipe_sound.stop()


func move_slider_to_mouse() -> void:
	if not minigame_active or not dragging_slider:
		return

	var mouse_position = target_area.get_local_mouse_position()

	# Find the track's center and its direction of travel.
	var track_center = slider_track.position + slider_track.size / 2.0
	var track_length: float
	var direction: Vector2

	if slider_orientation == 0:
		# Horizontal: left to right.
		track_length = slider_track.size.x
		direction = Vector2.RIGHT

	elif slider_orientation == 1:
		# Vertical: top to bottom.
		track_length = slider_track.size.y
		direction = Vector2.DOWN

	else:
		# Diagonal: follow the rotated track.
		track_length = slider_track.size.x
		direction = Vector2.RIGHT.rotated(slider_track.rotation)

	var start_point = track_center - direction * track_length / 2.0

	# Determine the slider's length along the track.
	var slider_length: float
	if slider_orientation == 1:
		slider_length = slider_target.size.y
	else:
		slider_length = slider_target.size.x

	var travel_distance = track_length - slider_length
	if travel_distance <= 0.0:
		return

	# Project the mouse position onto the track's direction.
	var mouse_distance = (mouse_position - start_point).dot(direction)

	# Keep the slider within the track.
	var slider_distance = clampf(
		mouse_distance - slider_length / 2.0,
		0.0,
		travel_distance
	)

	# Position the slider along the track.
	var slider_center = start_point + direction * (
		slider_distance + slider_length / 2.0
	)

	slider_target.position = slider_center - slider_target.size / 2.0

	# Calculate progress from the start to the end.
	var slider_progress = slider_distance / travel_distance

	# Full-size sliders award 10% at halfway.
	if not slider_is_half_size:
		if not slider_halfway_awarded and slider_progress >= 0.5:
			slider_halfway_awarded = true
			play_pop_sound(1.0)
			add_catch_progress(10.0)

			if not minigame_active:
				return

	# Both sizes award 10% at the end.
	if not slider_end_awarded and slider_progress >= 0.98:
		slider_end_awarded = true
		dragging_slider = false
		slider_swipe_sound.stop()
		play_pop_sound(1.3)
		add_catch_progress(10.0)

		if minigame_active:
			spawn_next_target()


func add_catch_progress(amount: float) -> void:
	if not minigame_active:
		return

	catch_progress = minf(catch_progress + amount, 100.0)
	catch_meter.value = catch_progress

	print("Catch progress: ", catch_progress, "%")

	if catch_progress >= 100.0:
		end_minigame(true)


func end_minigame(success: bool) -> void:
	minigame_active = false
	dragging_slider = false
	
	slider_swipe_sound.stop()
	
	click_target.hide()
	slider_target.hide()
	slider_track.hide()
	
	if success:
		success_ding_sound.play()
		print("SUCCESS! You caught the fish!")
		minigame_won.emit()
	else:
		print("Time's up! The fish got away!")
		minigame_lost.emit()
		
	hide()
	set_process(false)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func update_timer_label() -> void:
	timer_label.text = "Time: %.1f" % time_remaining

func play_pop_sound(pitch: float = 1.0) -> void:
	pop_sound.pitch_scale = pitch
	pop_sound.play()

func start_minigame() -> void:
	catch_progress = 0.0
	catch_meter.value = 0.0
	
	time_remaining = 10.0
	minigame_active = true
	
	dragging_slider = false
	slider_halfway_awarded = false
	slider_end_awarded = false
	
	slider_swipe_sound.stop()
	
	show()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	set_process(true)
	spawn_next_target()
	update_timer_label()
