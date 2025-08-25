# DeerAttack.gd
extends Area2D

@export var damage: int = 2
@export var windup_time: float = 0.12     # delay before hitbox activates (sync to anim)
@export var active_time: float = 0.22     # how long the hitbox stays active
@export var knockback_force: float = 250.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var colshape: CollisionShape2D = $CollisionShape2D

var already_hit: Dictionary = {}   # avoid multi-hits in one activation

func _ready() -> void:
	# Ensure sprite shows and collider starts off
	if sprite: sprite.visible = true
	colshape.disabled = true

	# Connect overlap signals
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)

	# Play the pop-up animation if present
	if sprite and sprite.sprite_frames and sprite.sprite_frames.has_animation("DeerAttack"):
		sprite.play("DeerAttack")

	# Run the hit window
	_open_hit_window()

func _open_hit_window() -> void:
	await get_tree().create_timer(windup_time).timeout
	colshape.disabled = false
	await get_tree().create_timer(active_time).timeout
	colshape.disabled = true

	# Let the animation finish, then clean up (fallback if none)
	if sprite:
		await sprite.animation_finished
	else:
		await get_tree().create_timer(0.2).timeout
	queue_free()

func _on_body_entered(body: Node2D) -> void:
	if colshape.disabled: return
	if not body.is_in_group("enemy"): return
	if already_hit.has(body): return
	already_hit[body] = true

	var away: Vector2 = (body.global_position - global_position).normalized()
	var kb: Vector2 = (away + Vector2(0, -0.4)).normalized() * knockback_force

	if body.has_method("apply_damage"):
		body.apply_damage(damage, kb)

func _on_area_entered(area: Area2D) -> void:
	# Optional: if enemies expose a hurtbox Area2D in group "enemy_hurtbox"
	if colshape.disabled: return
	if not area.is_in_group("enemy_hurtbox"): return

	var enemy: Node2D = area.get_parent() as Node2D
	if enemy and enemy.has_method("apply_damage"):
		var away: Vector2 = (enemy.global_position - global_position).normalized()
		var kb: Vector2 = (away + Vector2(0, -0.4)).normalized() * knockback_force
		enemy.apply_damage(damage, kb)
