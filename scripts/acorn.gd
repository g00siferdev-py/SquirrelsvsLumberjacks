extends RigidBody2D

@export var lifetime_seconds: float = 10.0
@export var despawn_y: float = 2000.0  # adjust if your world is taller/shorter

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
var _age: float = 0.0

func _ready() -> void:
	if sprite != null and sprite.sprite_frames != null:
		# If you have an animation name like "spin" or "idle", set it here.
		# Otherwise AnimatedSprite2D may already autoplay based on your editor settings.
		# Safe default: just play the current animation if one exists.
		if sprite.animation != "":
			sprite.play(sprite.animation)

func _physics_process(delta: float) -> void:
	_age += delta

	# Time-based cleanup
	if lifetime_seconds > 0.0 and _age >= lifetime_seconds:
		queue_free()
		return

	# Off-screen cleanup (falls too far)
	if global_position.y > despawn_y:
		queue_free()
