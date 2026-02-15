extends CharacterBody2D

@export var speed: float = 120.0
@export var gravity: float = 1200.0
@export var direction: int = 1

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	sprite.play("walk")
	sprite.flip_h = direction < 0

func _physics_process(delta: float) -> void:
	velocity.x = direction * speed

	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		velocity.y = 0.0

	move_and_slide()
