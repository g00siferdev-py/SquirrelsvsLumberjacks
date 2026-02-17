extends Control

@export var game_scene_path: String = "res://game.tscn"
@export var intro_duration_seconds: float = 6.0

@onready var video_player: VideoStreamPlayer = $VideoStreamPlayer
@onready var start_button: Button = $StartButton
@onready var reveal_timer: Timer = $RevealTimer

var _is_loading_game: bool = false


func _ready() -> void:
	game_scene_path = _normalize_scene_path(game_scene_path)

	# Ensure critical signals are connected even if scene-file connections were lost.
	if not start_button.pressed.is_connected(_on_start_button_pressed):
		start_button.pressed.connect(_on_start_button_pressed)
	if not reveal_timer.timeout.is_connected(_on_reveal_timer_timeout):
		reveal_timer.timeout.connect(_on_reveal_timer_timeout)
	if not video_player.finished.is_connected(_on_video_stream_player_finished):
		video_player.finished.connect(_on_video_stream_player_finished)

	start_button.visible = false
	start_button.disabled = true

	reveal_timer.wait_time = intro_duration_seconds
	reveal_timer.one_shot = true
	reveal_timer.start()

	if video_player.stream != null:
		video_player.play()


func _on_reveal_timer_timeout() -> void:
	_show_start_button()


func _on_video_stream_player_finished() -> void:
	_show_start_button()


func _on_start_button_pressed() -> void:
	if _is_loading_game:
		return

	_is_loading_game = true
	start_button.disabled = true

	var target_scene_path := _resolve_game_scene_path()
	if target_scene_path.is_empty():
		push_error("TitleScreen: Could not find a valid game scene. Checked: %s, res://game.tscn, res://scenes/game.tscn" % game_scene_path)
		start_button.disabled = false
		_is_loading_game = false
		return

	var loaded_scene := load(target_scene_path)
	if loaded_scene == null or not (loaded_scene is PackedScene):
		push_error("TitleScreen: Failed to load PackedScene at: %s" % target_scene_path)
		start_button.disabled = false
		_is_loading_game = false
		return

	var change_result := get_tree().change_scene_to_packed(loaded_scene)
	if change_result != OK:
		push_error("TitleScreen: Failed to change scene to: %s (error %d)" % [target_scene_path, change_result])
		start_button.disabled = false
		_is_loading_game = false


func _unhandled_input(event: InputEvent) -> void:
	if not start_button.visible:
		return

	if event.is_action_pressed("ui_accept"):
		_on_start_button_pressed()


func _show_start_button() -> void:
	if start_button.visible:
		return

	start_button.visible = true
	start_button.disabled = false
	start_button.grab_focus()


func _normalize_scene_path(path: String) -> String:
	var cleaned := path.strip_edges()
	if cleaned.is_empty():
		return "res://game.tscn"

	if cleaned.begins_with("res://"):
		return cleaned

	return "res://%s" % cleaned.trim_prefix("/")


func _resolve_game_scene_path() -> String:
	var candidates: Array[String] = [
		game_scene_path,
		"res://game.tscn",
		"res://scenes/game.tscn",
	]

	for candidate in candidates:
		if ResourceLoader.exists(candidate, "PackedScene"):
			return candidate

	return ""
