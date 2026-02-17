extends CharacterBody2D

@export var speed: float = 120.0
@export var gravity: float = 1200.0
@export var despawn_margin: float = 200.0

# 1 = moving right, -1 = moving left
@export var direction: int = 1 : set = set_direction

# If walk frames face LEFT by default, set true. If RIGHT, set false.
@export var faces_left_by_default: bool = true

# How close (in pixels on X axis) to a trunk center before stopping.
@export var trunk_stop_offset_x: float = 8.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

var _is_stopped_at_trunk: bool = false
var _target_trunk_x: float = INF


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
