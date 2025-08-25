extends CharacterBody2D

@export var walk_speed: float = 80.0
@export var run_speed: float = 140.0
@export var jump_force: float = -350.0
@export var gravity: float = 800.0
@export var player: NodePath       # assign your Player node here
@export var side_offset: float = 60.0  # distance to stay left/right of player
@export var is_left_bot: bool = true  # true for left bot, false for right bot

var sprite: AnimatedSprite2D
var is_dead: bool = false

func _ready() -> void:
	sprite = $anami2

func _physics_process(delta: float) -> void:
	if is_dead:
		velocity = Vector2.ZERO
		sprite.play("dead")
		return
	
	# Apply gravity
	if not is_on_floor():
		velocity.y += gravity * delta
	
	var target = get_node_or_null(player)
	if target == null:
		return
	
	# Calculate target position (left or right of player)
	var target_x = target.global_position.x
	if is_left_bot:
		target_x -= side_offset  # Left side of player
	else:
		target_x += side_offset  # Right side of player
	
	# Horizontal direction to target position
	var dir_x = target_x - position.x
	var distance = abs(dir_x)
	var dir = sign(dir_x)
	
	# Get player horizontal speed
	var player_velocity_x = 0.0
	if "velocity" in target:
		player_velocity_x = target.velocity.x
	
	# --- Follow logic (same as original) ---
	if distance > 40.0:  # stop_distance
		if player_velocity_x != 0:
			# Move in the same direction as player
			var speed = walk_speed if abs(player_velocity_x) <= walk_speed else run_speed
			velocity.x = dir * speed
		else:
			# Player stopped, bot stops too
			velocity.x = 0
	else:
		# Close to target position, stop
		velocity.x = 0
	
	# Jump only if obstacle ahead
	if is_on_floor() and is_obstacle_ahead(dir):
		velocity.y = jump_force
	
	# --- Flip bot sprite to match player (same as original) ---
	if target.has_node("AnimatedSprite2D"):
		var player_sprite = target.get_node("AnimatedSprite2D")
		sprite.flip_h = player_sprite.flip_h
	
	# --- Animations (same as original) ---
	if not is_on_floor():
		sprite.play("jump")
	elif velocity.x == 0:
		sprite.play("idle")
	elif abs(velocity.x) == walk_speed:
		sprite.play("walk")
	else:
		sprite.play("run")
	
	move_and_slide()

func kill():
	is_dead = true

func is_obstacle_ahead(dir: int) -> bool:
	var space_state = get_world_2d().direct_space_state
	var from_pos = global_position
	var to_pos = from_pos + Vector2(dir * 16, 2)
	var query = PhysicsRayQueryParameters2D.create(from_pos, to_pos)
	query.exclude = [self]
	var result = space_state.intersect_ray(query)
	return result.size() > 0
