extends CharacterBody2D

@export var speed: float = 230.0
@export var gravity: float = 1200.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	sprite.play("idle")

func _physics_process(delta: float) -> void:
	# --- Horizontal input (supports either naming scheme) ---
	var axis := 0.0
	if Input.is_action_pressed("ui_left") or Input.is_action_pressed("left"):
		axis -= 1.0
	if Input.is_action_pressed("ui_right") or Input.is_action_pressed("right"):
		axis += 1.0

	velocity.x = axis * speed

	# --- Gravity so floors matter ---
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		# Optional: keep a tiny downward force to help stick to slopes
		velocity.y = 0.0

	move_and_slide()

	# --- Animation ---
	if axis != 0.0:
		sprite.flip_h = axis < 0.0
		if sprite.animation != "run_east":
			sprite.play("run_east")
	else:
		if sprite.animation != "idle":
			sprite.play("idle")
