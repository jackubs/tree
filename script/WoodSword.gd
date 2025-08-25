extends Node2D

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@export var attack_animation_name: String = "WoodSwordAttack"
@export var ground_y_position: float = 560.0  # Set your ground level
@export var x_min_limit: float = 100.0         # Minimum x where sword can land
@export var x_max_limit: float = 900.0         # Maximum x where sword can land

var is_attacking: bool = false

func _ready() -> void:
	sprite.visible = false

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		var click_pos = get_global_mouse_position()
		
		# Clamp x to be within the defined range
		var clamped_x = clamp(click_pos.x, x_min_limit, x_max_limit)
		var target_position = Vector2(clamped_x, ground_y_position)
		
		attack(target_position)

func attack(target_position: Vector2) -> void:
	if is_attacking or not sprite.sprite_frames.has_animation(attack_animation_name):
		return

	is_attacking = true
	global_position = target_position

	sprite.visible = true
	sprite.play(attack_animation_name)

	await sprite.animation_finished

	sprite.visible = false
	is_attacking = false
