extends Node2D

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D


func _ready():
	
	sprite.play("DeerAttack")
	
	await sprite.animation_finished
	queue_free()
