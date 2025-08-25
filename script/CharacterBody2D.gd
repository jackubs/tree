extends CharacterBody2D

const SPEED = 300.0
const JUMP_VELOCITY = -400.0

@export var cooldown_time := 0.8  # seconds
var can_throw := true
var can_summon_spike := true
@export var spike_cooldown_time := 1.0  # seconds



var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

@onready var sprite: AnimatedSprite2D = $Flip/AnimatedSprite2D

@export var woodspike_scene = preload("res://scene/wood_spike_attack.tscn")
@export var spike_offset_y: float = -100.0  # Adjust vertical position (e.g., -10 to place it slightly in the ground)

@export var deer_head_scene = preload("res://scene/dear_attack.tscn")
@export var deer_offset_y: float = -50.0
var can_summon_deer := true
@export var deer_cooldown_time := 1.5



@export var branch_scene = preload("res://scene/pro_brunch.tscn")  # Drag your BranchProjectile.tscn here
@export var throw_offset: float = 100.0  # Distance in front of player to spawn branch
func _ready():
	
	
	pass
	
	
	
	
	
	
func _physics_process(delta):
	# Add gravity
	if not is_on_floor():
		velocity.y += gravity * delta

	# Handle jump
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Handle horizontal movement
	var direction = Input.get_axis("ui_left", "ui_right")
	if direction:
		velocity.x = direction * SPEED
		sprite.play("walk")
		sprite.flip_h = direction < 0
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		sprite.play("Idle")

	move_and_slide()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		throw_branch()
	elif event.is_action_pressed("WoodSpikeAttack"):
		summon_woodspike()
	elif event.is_action_pressed("WoodDeerAttack"):
		summon_deer_head()


func summon_woodspike() -> void:
	if woodspike_scene == null:
		return

	var spike = woodspike_scene.instantiate()

	# Get mouse X position, but keep a fixed Y level relative to player
	var mouse_x = get_global_mouse_position().x
	var spike_position = Vector2(mouse_x, global_position.y + spike_offset_y)
	spike.global_position = spike_position

	get_tree().current_scene.add_child(spike)
	
	start_cooldown()
	
	
func summon_deer_head() -> void:
	if not can_summon_deer or deer_head_scene == null:
		return

	can_summon_deer = false

	var deer = deer_head_scene.instantiate()

	# Position at mouse X, ground Y
	var mouse_x = get_global_mouse_position().x
	var deer_position = Vector2(mouse_x, global_position.y + deer_offset_y)
	deer.global_position = deer_position

	get_tree().current_scene.add_child(deer)

	start_deer_cooldown()

	




func throw_branch():
	if not can_throw or branch_scene == null:
		return

	can_throw = false  # Disable throwing
	var mouse_pos = get_global_mouse_position()
	var dir = (mouse_pos - global_position).normalized()

	var branch = branch_scene.instantiate()
	branch.global_position = global_position + dir * throw_offset
	branch.direction = dir

	get_tree().current_scene.add_child(branch)

	# Start cooldown
	start_cooldown()
	
	
func start_deer_cooldown() -> void:
	await get_tree().create_timer(deer_cooldown_time).timeout
	can_summon_deer = true



func start_cooldown() -> void:
	await get_tree().create_timer(cooldown_time).timeout
	can_throw = true
	can_summon_spike = true
