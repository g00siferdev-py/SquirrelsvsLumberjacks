extends Node2D

@onready var ground_shape: CollisionShape2D = get_node_or_null("Ground/CollisionShape2D")
# Drag Acorn.tscn into this in the Inspector
@export var acorn_scene: PackedScene
# Path to the squirrel instance inside Game.tscn
@onready var squirrel: CharacterBody2D = $Squirrel
@export var lumberjack_scene: PackedScene  # Drag Lumberjack.tscn here
@export var lumberjack_spawn_interval: float = 2.5
@export var lumberjack_y: float = 0.0  # set to the ground/branch y you want
@export var spawn_margin: float = 80.0

var _spawn_timer: float = 0.0


func _ready() -> void:
	if squirrel == null:
		push_error("Game.gd: Could not find $Squirrel. Check the node name/path in Game.tscn.")
	if acorn_scene == null:
		push_warning("Game.gd: acorn_scene is not set. Drag Acorn.tscn into Game's acorn_scene export.")


func spawn_lumberjack() -> void:
	if lumberjack_scene == null:
		push_warning("lumberjack_scene not set. Drag Lumberjack.tscn into Game's lumberjack_scene field.")
		return

	var screen_w := get_viewport_rect().size.x
	var from_left := randi() % 2 == 0
	var spawn_x := -spawn_margin if from_left else screen_w + spawn_margin

	# Pick a ground Y. If you already computed ground_top_y elsewhere, use that.
	# Easiest reliable approach: use a constant you set in the Inspector:
	var ground_y := lumberjack_y

	var lj := lumberjack_scene.instantiate()

	# IMPORTANT: set direction BEFORE adding to scene tree (before _ready runs)
	lj.direction = 1 if from_left else -1

	add_child(lj)
	lj.global_position = Vector2(spawn_x, ground_y)

	
	#Default spawn height is Ground isn't found
	var ground_top_y := 600.0
	
	if ground_shape == null:
		push_warning("Ground/CollisionShape2D not found. Spawning at fallback Y = 600")
	else:
		#Try to compute top of RectangleShape2D ( recommended ground type)
		var rect := ground_shape.shape as RectangleShape2D
		if rect != null:
			ground_top_y = ground_shape.global_position.y - (rect.size.y * 0.5)
		else:
			ground_top_y = ground_shape.global_position.y
	lj.global_position = Vector2(spawn_x, ground_top_y - 2)
	#Set direction if the script supports it
	if lj.has_method("set"):
		lj.direction = 1 if from_left else -1


func _process(delta: float) -> void:
	# --- your existing acorn drop logic ---
	if Input.is_action_just_pressed("drop_acorn"):
		drop_acorn()
	
	#---lumberjack spawn timer---
	_spawn_timer += delta
	if _spawn_timer >= lumberjack_spawn_interval:
		_spawn_timer = 0.0
		spawn_lumberjack()
	
	

	
func drop_acorn() -> void:
	if acorn_scene == null:
		push_warning("Game.gd: acorn_scene is null. Assign Acorn.tscn in the Inspector.")
		return
	if squirrel == null:
		push_warning("Game.gd: squirrel is null. Cannot drop acorn.")
		return

	var acorn := acorn_scene.instantiate()
	add_child(acorn)

	# Drop straight down from under the squirrel (global coords)
	acorn.global_position = squirrel.global_position + Vector2(0, 24)

	# Ensure it starts with no sideways motion
	if acorn is RigidBody2D:
		acorn.linear_velocity = Vector2.ZERO
		acorn.angular_velocity = 0.0
