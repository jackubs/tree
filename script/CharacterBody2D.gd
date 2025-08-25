extends CharacterBody2D

const SPEED := 300.0
const JUMP_VELOCITY := -400.0

@export var cooldown_time: float = 0.8
var can_throw: bool = true
var can_summon_spike: bool = true
@export var spike_cooldown_time: float = 1.0

# ⬇ explicit float (get_setting returns Variant)
var gravity: float = float(ProjectSettings.get_setting("physics/2d/default_gravity"))

@onready var sprite: AnimatedSprite2D = $Flip/AnimatedSprite2D

# ⬇ explicit PackedScene types
@export var woodspike_scene: PackedScene = preload("res://scene/wood_spike_attack.tscn")
@export var spike_offset_y: float = -100.0

@export var deer_head_scene: PackedScene = preload("res://scene/dear_attack.tscn")
@export var deer_offset_y: float = -50.0
var can_summon_deer: bool = true
@export var deer_cooldown_time: float = 1.5

# --- Player health & hit reactions ---
@export var player_max_health: int = 5
@export var invuln_time: float = 0.6
@export var hitstun_time: float = 0.12

var player_health: int
var invuln: bool = false
var stunned: bool = false

@export var branch_scene: PackedScene = preload("res://scene/pro_brunch.tscn")
@export var throw_offset: float = 100.0

func _ready() -> void:
	add_to_group("player")
	player_health = player_max_health
	invuln = false 

func _physics_process(delta: float) -> void:
	if stunned:
		velocity = velocity.move_toward(Vector2.ZERO, 1600.0 * delta)
		move_and_slide()
		return

	if not is_on_floor():
		velocity.y += gravity * delta

	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# ⬇ explicit float
	var direction: float = Input.get_axis("ui_left", "ui_right")
	if direction != 0.0:
		velocity.x = direction * SPEED
		sprite.play("walk")
		sprite.flip_h = direction < 0.0
	else:
		velocity.x = move_toward(velocity.x, 0.0, SPEED)
		sprite.play("Idle")

	move_and_slide()

func _unhandled_input(event: InputEvent) -> void:
	if stunned:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		throw_branch()
	elif event.is_action_pressed("WoodSpikeAttack"):
		summon_woodspike()
	elif event.is_action_pressed("WoodDeerAttack"):
		summon_deer_head()

func summon_woodspike() -> void:
	if woodspike_scene == null:
		return
	var spike: Node2D = woodspike_scene.instantiate() as Node2D
	var mouse_x: float = get_global_mouse_position().x
	var spike_position: Vector2 = Vector2(mouse_x, global_position.y + spike_offset_y)
	spike.global_position = spike_position
	get_tree().current_scene.add_child(spike)
	start_cooldown()

func summon_deer_head() -> void:
	if not can_summon_deer or deer_head_scene == null:
		return
	can_summon_deer = false
	var deer: Node2D = deer_head_scene.instantiate() as Node2D
	var mouse_x: float = get_global_mouse_position().x
	deer.global_position = Vector2(mouse_x, global_position.y + deer_offset_y)
	get_parent().add_child(deer)
	deer.z_index = z_index + 1
	start_deer_cooldown()

func apply_damage(amount: int, knockback: Vector2 = Vector2.ZERO) -> void:
	if invuln:
		return
	player_health -= amount
	if player_health <= 0:
		_die()
		return
	invuln = true
	stunned = true
	if knockback != Vector2.ZERO:
		velocity += knockback
	if sprite and sprite.sprite_frames.has_animation("hit"):
		sprite.play("hit")
	_flash()
	await get_tree().create_timer(hitstun_time).timeout
	stunned = false
	# ⬇ explicit float + cast (max returns Variant)
	var remain: float = float(max(invuln_time - hitstun_time, 0.0))
	if remain > 0.0:
		await get_tree().create_timer(remain).timeout
	invuln = false

func _flash() -> void:
	if not sprite:
		return
	sprite.modulate = Color(1, 0.7, 0.7)
	await get_tree().create_timer(0.08).timeout
	sprite.modulate = Color(1, 1, 1)

func _die() -> void:
	print("player attacked!")
	stunned = true
	invuln = true
	velocity = Vector2.ZERO
	#if sprite and sprite.sprite_frames.has_animation("death"):
		#sprite.play("death")
		#await sprite.animation_finished
	queue_free()

func throw_branch() -> void:
	if not can_throw or branch_scene == null:
		return
	can_throw = false
	var mouse_pos: Vector2 = get_global_mouse_position()
	var dir: Vector2 = (mouse_pos - global_position).normalized()
	var branch: Node2D = branch_scene.instantiate() as Node2D
	branch.global_position = global_position + dir * throw_offset
	# If your projectile script expects .direction, keep this:
	branch.set("direction", dir)
	get_tree().current_scene.add_child(branch)
	start_cooldown()

func start_deer_cooldown() -> void:
	await get_tree().create_timer(deer_cooldown_time).timeout
	can_summon_deer = true

func start_cooldown() -> void:
	await get_tree().create_timer(cooldown_time).timeout
	can_throw = true
	can_summon_spike = true
