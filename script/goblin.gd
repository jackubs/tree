extends CharacterBody2D

# === Tuning ===
@export var max_health: int = 3
@export var speed: float = 250.0
@export var aggro_radius: float = 500.0
@export var stop_radius: float = 24.0

# Attack params
@export var attack_radius: float = 64.0
@export var attack_damage: int = 1
@export var attack_cooldown: float = 1.2
@export var attack_windup: float = 0.25  # time from swing start to damage frame

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

var health: int
var target: Node2D

# Simple state flags
var can_attack := true
var is_attacking := false
var is_hitstun := false
var is_dead := false

@onready var attack_zone: Area2D = $AttackZone
var player_in_zone: bool = false



func _ready() -> void:
	health = max_health
	add_to_group("enemy")
	target = get_tree().get_first_node_in_group("player")




func _physics_process(delta: float) -> void:
	if is_dead:
		return

	if is_hitstun or is_attacking:
		# freeze movement while hit/attacking
		velocity = velocity.move_toward(Vector2.ZERO, speed * 4.0 * delta)
		move_and_slide()
		return
	

	if target:
		var to_target := target.global_position - global_position
		var dist := to_target.length()

		# Face the player
		if sprite:
			sprite.flip_h = to_target.x < 0.0

		# If close enough → attack (respect cooldown)
		if (dist <= attack_radius or player_in_zone) and can_attack:
			_start_attack(to_target)
			return


		# Else chase/idle
		if dist < aggro_radius and dist > stop_radius:
			velocity = to_target.normalized() * speed
			if sprite and sprite.sprite_frames.has_animation("GoblinWalk"):
				if sprite.animation != "GoblinWalk":
					sprite.play("GoblinWalk")
		else:
			velocity = velocity.move_toward(Vector2.ZERO, speed * delta)
			if sprite and sprite.sprite_frames.has_animation("GoblinIdle"):
				if sprite.animation != "GoblinIdle":
					sprite.play("GoblinIdle")
	else:
		velocity = Vector2.ZERO

	move_and_slide()

# --- Attack flow ---
func _start_attack(to_target: Vector2) -> void:
	if is_dead: return
	is_attacking = true
	can_attack = false
	velocity = Vector2.ZERO

	var played := false
	if sprite and sprite.sprite_frames.has_animation("GoblinAttack"):
		sprite.play("GoblinAttack")
		played = true

	await get_tree().create_timer(attack_windup).timeout

	if not is_dead:
		# robust: check who is actually inside the AttackZone right now
		var bodies := attack_zone.get_overlapping_bodies()
		for b in bodies:
			if b.is_in_group("player") and b.has_method("apply_damage"):
				var kb: Vector2 = (b.global_position - global_position).normalized() * 120.0
				b.apply_damage(attack_damage, kb)
				break   # hit once




	# Don’t wait forever if no anim played
	if played:
		await sprite.animation_finished
	else:
		await get_tree().create_timer(0.2).timeout

	is_attacking = false
	await get_tree().create_timer(attack_cooldown).timeout
	can_attack = true

# --- Taking damage from your projectile ---
func apply_damage(amount: int, knockback: Vector2 = Vector2.ZERO) -> void:
	if is_dead: return
	health -= amount

	# Interrupt attack if hit
	is_attacking = false

	# Knockback (light)
	if knockback != Vector2.ZERO:
		velocity += knockback

	# Hit reaction
	await _enter_hitstun()

	if health <= 0:
		_die()

func _enter_hitstun() -> void:
	if is_dead: return
	is_hitstun = true
	velocity = Vector2.ZERO

	# Play hit anim + flash
	if sprite and sprite.sprite_frames.has_animation("GoblinTakeHit"):
		sprite.play("GoblinTakeHit")
	_flash_hit()

	# Short stun; if you prefer exact anim length, await animation_finished instead
	await get_tree().create_timer(0.15).timeout
	is_hitstun = false

func _flash_hit() -> void:
	if sprite:
		sprite.modulate = Color(1, 0.6, 0.6)
		await get_tree().create_timer(0.08).timeout
		sprite.modulate = Color(1, 1, 1)

# --- Death ---
func _die() -> void:
	if is_dead: return
	is_dead = true
	is_attacking = false
	is_hitstun = false
	velocity = Vector2.ZERO
	if sprite and sprite.sprite_frames.has_animation("GoblinDeath"):
		sprite.play("GoblinDeath")
		await sprite.animation_finished
	queue_free()


func _on_attack_zone_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_zone = true
		print("[Enemy] player_in_zone = TRUE (entered)")



func _on_attack_zone_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_zone = false
		print("[Enemy] player_in_zone = FALSE (exited)")
