extends Node2D

@onready var squirrel: AnimatedSprite2D = $squirrel

@export var speed: float = 200.0

func _ready():
	# Start idle immediately
	squirrel.play("idle")

func _process(delta):
	var direction := 0

	if Input.is_action_pressed("ui_left"):
		direction -= 1
	if Input.is_action_pressed("ui_right"):
		direction += 1

	if direction != 0:
		# Move
		squirrel.position.x += direction * speed * delta
		
		# Flip sprite if moving left
		squirrel.flip_h = direction < 0
		
		# Play run animation if not already playing
		if squirrel.animation != "run_east":
			squirrel.play("run_east")
	else:
		# No movement → idle
		if squirrel.animation != "idle":
			squirrel.play("idle")
