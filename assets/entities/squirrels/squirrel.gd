extends Node2D

@onready var squirrel: AnimatedSprite2D = $squirrel

@export var speed: float = 200.0
@export var acorn_scene: PackedScene   # drag Acorn.tscn here

func _ready() -> void:
	squirrel.play("idle")

func _process(delta: float) -> void:
	var direction := 0

	if Input.is_action_pressed("left"):
		direction -= 1
	if Input.is_action_pressed("right"):
		direction += 1

	if direction != 0:
		squirrel.position.x += direction * speed * delta
		squirrel.flip_h = direction < 0

		if squirrel.animation != "run_east":
			squirrel.play("run_east")
	else:
		if squirrel.animation != "idle":
			squirrel.play("idle")

	# Drop acorn when S is pressed
	if Input.is_action_just_pressed("drop"):
		drop_acorn()

func drop_acorn() -> void:
	if acorn_scene == null:
		push_warning("Acorn scene not assigned in Inspector")
		return

	var acorn := acorn_scene.instantiate()
	add_child(acorn)

	# Drop slightly in front of squirrel
	var offset := Vector2(16, 0)
	if squirrel.flip_h:
		offset.x = -16

	acorn.position = squirrel.position + offset
