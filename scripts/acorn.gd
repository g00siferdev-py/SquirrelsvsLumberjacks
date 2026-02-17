extends RigidBody2D

@export var lifetime_seconds: float = 5.0
@export var despawn_y: float = 1200.0  # keep cleanup close to visible play space

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
var _age: float = 0.0

func _ready() -> void:
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)

	if sprite != null and sprite.sprite_frames != null:
		# If you have an animation name like "spin" or "idle", set it here.
		# Otherwise AnimatedSprite2D may already autoplay based on your editor settings.
		# Safe default: just play the current animation if one exists.
		if sprite.animation != "":
			sprite.play(sprite.animation)


func _on_body_entered(body: Node) -> void:
	if body != null and body.is_in_group("lumberjacks") and _is_hit_from_above(body):
		if body.has_method("play_hit_reaction"):
			body.play_hit_reaction()
		queue_free()
		return

	if body != null and body.is_in_group("ground"):
		queue_free()


func _is_hit_from_above(body: Node) -> bool:
	if not (body is Node2D):
		return false

	var hit_body := body as Node2D
	return linear_velocity.y > 0.0 and global_position.y < (hit_body.global_position.y - 8.0)

func _physics_process(delta: float) -> void:
	_age += delta

	# Time-based cleanup
	if lifetime_seconds > 0.0 and _age >= lifetime_seconds:
		queue_free()
		return

	# Off-screen cleanup (falls too far)
	if global_position.y > despawn_y:
		queue_free()
