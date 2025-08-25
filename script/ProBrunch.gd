extends Area2D

@export var speed: float = 400.0
@export var max_distance: float = 800.0
@export var animation_name: String = "ProBrunch"
@export var delay_before_movement: float = 1.0
@export var damage: int = 1

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var colshape: CollisionShape2D = $CollisionShape2D

var direction: Vector2
var start_position: Vector2
var is_moving: bool = false

func _ready() -> void:
	start_position = global_position
	rotation = direction.angle()

	if sprite.sprite_frames.has_animation(animation_name):
		sprite.play(animation_name)
	else:
		push_warning("Animation '%s' not found in AnimatedSprite2D." % animation_name)

	# Disable hitbox while floating in place
	colshape.disabled = true

	# Receive overlaps with bodies/areas
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)

	# Start movement after the delay
	move_after_delay()

func move_after_delay() -> void:
	await get_tree().create_timer(delay_before_movement).timeout
	is_moving = true
	colshape.disabled = false  # now it can hit

func _physics_process(delta: float) -> void:
	if is_moving:
		position += direction * speed * delta
		# (optional) keep rotation matched to travel direction
		rotation = direction.angle()

		if global_position.distance_to(start_position) > max_distance:
			queue_free()

func _on_body_entered(body: Node2D) -> void:
	# Ignore collisions while floating
	if not is_moving:
		return

	# Enemy hit
	if body.is_in_group("enemy"):
		if body.has_method("apply_damage"):
			body.apply_damage(damage)
		queue_free()
		return

	# Hit world/tiles etc. → despawn
	if body.is_in_group("world"):
		queue_free()

func _on_area_entered(area: Area2D) -> void:
	if not is_moving:
		return
	# If enemies use Areas for their hurtboxes:
	if area.is_in_group("enemy_hurtbox"):
		if area.has_method("hit"):
			area.hit(damage)
		queue_free()
