extends CharacterBody2D
@export var walk_speed: float = 100.0
@export var run_speed: float = 200.0
@export var jump_force: float = -350.0
@export var gravity: float = 800.0

var is_dead: bool = false
var sprite: AnimatedSprite2D

func _ready() -> void:
	sprite = $AnimatedSprite2D

func _physics_process(delta: float) -> void:
	if is_dead:
		velocity = Vector2.ZERO
		sprite.play("dead")
	if is_frozen:
		velocity = Vector2.ZERO
		$AnimatedSprite2D.play("idle")
		move_and_slide() # keeps physics stable, but no movement
		return

	# Apply gravity
	if not is_on_floor():
		velocity.y += gravity * delta

	# Movement input
	var input_dir = Input.get_axis("ui_left", "ui_right")
	var speed = walk_speed
	if Input.is_action_pressed("ui_accept"): # hold Shift/another key for run
		speed = run_speed

	velocity.x = input_dir * speed


	# Flip sprite based on direction
	if input_dir != 0:
		sprite.flip_h = input_dir < 0

	# Choose animation
	if not is_on_floor():
		sprite.play("jump")
	elif input_dir == 0:
		sprite.play("idle")
	elif speed == walk_speed:
		sprite.play("walk")
	elif speed == run_speed:
		sprite.play("run")

	move_and_slide()

func kill():
	is_dead = true


var is_frozen: bool = false

func freeze_player(value: bool) -> void:
	is_frozen = value
	if is_frozen:
		velocity = Vector2.ZERO
		$AnimatedSprite2D.play("idle")
