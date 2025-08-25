extends Node2D

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@export var animation_name: String = "WoodSpikeAttack"
@export var lifetime: float = 1.0

func _ready() -> void:
	if sprite.sprite_frames.has_animation(animation_name):
		sprite.play(animation_name)
	else:
		push_warning("Animation '%s' not found in AnimatedSprite2D." % animation_name)

	await get_tree().create_timer(lifetime).timeout
	queue_free()
