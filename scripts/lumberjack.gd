extends CharacterBody2D

@export var speed: float = 120.0
@export var gravity: float = 1200.0
@export var despawn_margin: float = 200.0

# 1 = moving right, -1 = moving left
@export var direction: int = 1 : set = set_direction

# IMPORTANT:
# If your lumberjack "walk" frames face LEFT by default, set this to true in the Inspector.
# If they face RIGHT by default, set it to false.
@export var faces_left_by_default: bool = true

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	if sprite == null:
		push_error("Lumberjack.gd: Missing child node 'AnimatedSprite2D' under the Lumberjack root.")
		return

	# Start walking animation
	if sprite.sprite_frames != null and sprite.sprite_frames.has_animation("walk"):
		sprite.play("walk")
	else:
		# Fallback if you named it differently
		sprite.play()

	_update_facing()

func set_direction(value: int) -> void:
	direction = 1 if value >= 0 else -1
	_update_facing()

func _update_facing() -> void:
	if sprite == null:
		return

	# We want: face RIGHT when direction == 1, face LEFT when direction == -1.
	# flip_h depends on how the art is drawn.
	if faces_left_by_default:
		# Default art faces LEFT, so flip when moving RIGHT
		sprite.flip_h = direction > 0
	else:
		# Default art faces RIGHT, so flip when moving LEFT
		sprite.flip_h = direction < 0

func _physics_process(delta: float) -> void:
	# Horizontal movement
	velocity.x = float(direction) * speed

	# Gravity so they settle onto ground collision
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		velocity.y = 0.0

	move_and_slide()

	# Despawn after leaving the screen
	var w := get_viewport_rect().size.x
	if global_position.x < -despawn_margin or global_position.x > w + despawn_margin:
		queue_free()
