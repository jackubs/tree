extends Node2D

@export var speed: float = 400.0
@export var max_distance: float = 800.0
@export var animation_name: String = "ProBrunch"
@export var delay_before_movement: float = 1.0  # Time in seconds to wait before moving

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

var direction: Vector2
var start_position: Vector2
var is_moving: bool = false

func _ready() -> void:
	start_position = global_position

	# Play the idle/start animation if it exists
	if sprite.sprite_frames.has_animation(animation_name):
		sprite.play(animation_name)
	else:
		push_warning("Animation '%s' not found in AnimatedSprite2D." % animation_name)

	# Start movement after delay
	move_after_delay()

func move_after_delay() -> void:
	await get_tree().create_timer(delay_before_movement).timeout
	is_moving = true

func _physics_process(delta: float) -> void:
	if is_moving:
		position += direction * speed * delta
		rotation = direction.angle()  # optional rotation

		if global_position.distance_to(start_position) > max_distance:
			queue_free()
