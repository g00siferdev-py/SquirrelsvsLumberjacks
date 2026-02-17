extends CharacterBody2D

@export var speed: float = 95.0
@export var gravity: float = 1200.0
@export var despawn_margin: float = 200.0

# 1 = moving right, -1 = moving left
@export var direction: int = 1 : set = set_direction

# If walk frames face LEFT by default, set true. If RIGHT, set false.
@export var faces_left_by_default: bool = true

# How close (in pixels on X axis) to a trunk center before stopping.
@export var trunk_stop_offset_x: float = 14.0
@export var hits_to_die: int = 5

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

var _is_stopped_at_trunk: bool = false
var _target_trunk_x: float = INF
var _is_reacting_to_hit: bool = false
var _is_dying: bool = false
var _hit_last_frame: int = -1
var _hit_count: int = 0


func _ready() -> void:
	if sprite == null:
		push_error("Lumberjack.gd: Missing child node 'AnimatedSprite2D' under the Lumberjack root.")
		return

	if sprite.sprite_frames != null and sprite.sprite_frames.has_animation("walk"):
		sprite.play("walk")
	else:
		sprite.play()

	_update_facing()
	_pick_target_trunk_x()
	if not sprite.animation_finished.is_connected(_on_sprite_animation_finished):
		sprite.animation_finished.connect(_on_sprite_animation_finished)
	if not sprite.frame_changed.is_connected(_on_sprite_frame_changed):
		sprite.frame_changed.connect(_on_sprite_frame_changed)


func refresh_trunk_target() -> void:
	_pick_target_trunk_x()

func _pick_target_trunk_x() -> void:
	_target_trunk_x = INF
	var has_target := false

	for trunk in get_tree().get_nodes_in_group("tree_trunks"):
		if not (trunk is Node2D):
			continue

		var trunk_x := (trunk as Node2D).global_position.x

		if direction > 0:
			# First trunk to the right
			if trunk_x >= global_position.x and (not has_target or trunk_x < _target_trunk_x):
				_target_trunk_x = trunk_x
				has_target = true
		else:
			# First trunk to the left
			if trunk_x <= global_position.x and (not has_target or trunk_x > _target_trunk_x):
				_target_trunk_x = trunk_x
				has_target = true


func set_direction(value: int) -> void:
	direction = 1 if value >= 0 else -1
	_update_facing()


func _update_facing() -> void:
	if sprite == null:
		return

	if faces_left_by_default:
		sprite.flip_h = direction > 0
	else:
		sprite.flip_h = direction < 0


func _physics_process(delta: float) -> void:
	if _is_dying:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	if _is_reacting_to_hit:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	if _is_stopped_at_trunk:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	if _should_stop_at_target_trunk():
		_stop_at_trunk()
		velocity = Vector2.ZERO
		move_and_slide()
		return

	velocity.x = float(direction) * speed

	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		velocity.y = 0.0

	move_and_slide()

	var w := get_viewport_rect().size.x
	if global_position.x < -despawn_margin or global_position.x > w + despawn_margin:
		queue_free()


func _should_stop_at_target_trunk() -> bool:
	if _target_trunk_x == INF:
		return false

	if direction > 0:
		return global_position.x >= (_target_trunk_x - trunk_stop_offset_x)

	return global_position.x <= (_target_trunk_x + trunk_stop_offset_x)


func _stop_at_trunk() -> void:
	_is_stopped_at_trunk = true
	velocity = Vector2.ZERO

	if sprite != null and sprite.sprite_frames != null and sprite.sprite_frames.has_animation("swing"):
		sprite.play("swing")


func play_hit_reaction() -> void:
	if sprite == null or sprite.sprite_frames == null:
		return
	if _is_dying:
		return

	_hit_count += 1
	if _hit_count >= max(1, hits_to_die):
		if sprite.sprite_frames.has_animation("dies"):
			_is_dying = true
			_is_reacting_to_hit = false
			_hit_last_frame = -1
			velocity = Vector2.ZERO
			sprite.play("dies")
			sprite.frame = 0
			sprite.frame_progress = 0.0
			return
		queue_free()
		return

	if not sprite.sprite_frames.has_animation("hit"):
		return

	_is_reacting_to_hit = true
	_hit_last_frame = -1
	velocity = Vector2.ZERO
	sprite.play("hit")
	sprite.frame = 0
	sprite.frame_progress = 0.0


func _on_sprite_animation_finished() -> void:
	if sprite == null:
		return

	if _is_dying and sprite.animation == "dies":
		queue_free()
		return

	if not _is_reacting_to_hit:
		return
	if sprite.animation != "hit":
		return

	_end_hit_reaction()


func _on_sprite_frame_changed() -> void:
	if not _is_reacting_to_hit:
		return
	if sprite == null or sprite.animation != "hit":
		return

	# Handle looped "hit" animations: end reaction after one full cycle.
	if _hit_last_frame >= 0 and sprite.frame < _hit_last_frame:
		_end_hit_reaction()
		return

	_hit_last_frame = sprite.frame


func _end_hit_reaction() -> void:
	if not _is_reacting_to_hit:
		return

	_is_reacting_to_hit = false
	_hit_last_frame = -1
	if _is_stopped_at_trunk:
		if sprite.sprite_frames != null and sprite.sprite_frames.has_animation("swing"):
			sprite.play("swing")
		return

	if sprite.sprite_frames != null and sprite.sprite_frames.has_animation("walk"):
		sprite.play("walk")
