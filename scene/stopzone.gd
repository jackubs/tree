extends Area2D

@export var dialogue_resource : DialogueResource
@export var dialogue_start : String = "start"

@export var bot1_name: String = "bot"
@export var bot2_name: String = "bot2"
@export var bot1_anim_name: String = "anami1"
@export var bot2_anim_name: String = "anami2"
@export var player_anim_name: String = "AnimatedSprite2D"
@onready var animation = $"../AnimationPlayer"

func _on_body_entered(body: Node) -> void:
	var actionable = $".".get_overlapping_areas()
	if actionable.size() > 0:
		actionable[0].action()
		return
	if body.is_in_group("Player"):
		action()  # Call action() instead to show dialogue first

func action():
	# Get the player and start cutscene immediately
	var player = get_tree().get_first_node_in_group("Player")
	if player:
		start_cutscene(player)

func start_cutscene(player):
	# Freeze player AND disable any scripts that might interfere
	if player.has_method("freeze_player"):
		player.freeze_player(true)
	if "velocity" in player:
		player.velocity = Vector2.ZERO
	
	# DISABLE ALL SCRIPTS that might override animations
	player.set_process(false)
	player.set_physics_process(false)
	
	# Get sprites
	var player_sprite = player.get_node(player_anim_name)
	var bot1 = player.get_node(bot1_name)
	var bot2 = player.get_node(bot2_name)
	var bot1_sprite = bot1.get_node(bot1_anim_name)
	var bot2_sprite = bot2.get_node(bot2_anim_name)
	
	# DISABLE BOT SCRIPTS TOO
	bot1.set_process(false)
	bot1.set_physics_process(false)
	bot2.set_process(false)
	bot2.set_physics_process(false)
	
	# Get camera for shake effect
	var camera = get_viewport().get_camera_2d()
	var original_camera_pos = camera.global_position if camera else Vector2.ZERO
	
	print("=== CUTSCENE START ===")
	
	# STEP 1: Everyone idle + Show dialogue
	force_animation(player_sprite, "idle")
	force_animation(bot1_sprite, "idle") 
	force_animation(bot2_sprite, "idle")
	print("Step 1: All idle + dialogue starting")
	
	# Show dialogue and wait for it to finish
	DialogueManager.show_example_dialogue_balloon(dialogue_resource, dialogue_start)
	await DialogueManager.dialogue_ended
	
	# Add a brief pause after dialogue ends
	await get_tree().create_timer(0.5).timeout
	print("Dialogue finished, continuing cutscene...")
	
	# STEP 2: Bots walk to positions (bot1 left, bot2 right)
	force_animation(bot1_sprite, "walk")
	force_animation(bot2_sprite, "walk")
	
	# Bot1 faces right initially, Bot2 faces left to walk to positions
	bot1_sprite.flip_h = false  # Face right to walk right to player's left
	bot2_sprite.flip_h = true   # Face left to walk left to player's right
	
	print("Step 2: Bots walking to positions - player stays in place")
	
	# Player position stays fixed - bots move to flank the player
	var player_x = player.global_position.x  # Player's current position (stays here)
	
	# Move only the bots to flank the player
	var move_tween = create_tween()
	move_tween.set_parallel(true)
	move_tween.tween_property(bot1, "global_position:x", player_x + 80, 2.5)  # Bot1 to left of player
	move_tween.tween_property(bot2, "global_position:x", player_x + 300, 1.5)  # Bot2 to right of player

	await move_tween.finished
	await get_tree().create_timer(0.3).timeout
	
	# STEP 3: Bots turn to face player and attack
	bot1_sprite.flip_h = false  # Bot1 faces right toward player
	bot2_sprite.flip_h = true   # Bot2 faces left toward player
	
	force_animation(bot1_sprite, "attack")
	force_animation(bot2_sprite, "attack")
	print("Step 3: Bots attack with camera shake!")
	
	# CAMERA SHAKE during attack
	if camera:
		shake_camera(camera, 2.0, 10.0)  # 2 seconds, intensity 10
	
	await get_tree().create_timer(2.0).timeout
	
	# STEP 4: Player dies
	force_animation(player_sprite, "dead")
	print("Step 4: Player dies")
	await get_tree().create_timer(1.5).timeout
	
	# STEP 5: BOTH bots run to the left together at a far distance
	force_animation(bot1_sprite, "run")
	force_animation(bot2_sprite, "run")
	
	# Both bots face left to run left together
	bot1_sprite.flip_h = true   # Bot1 faces left to run left
	bot2_sprite.flip_h = true   # Bot2 also faces left to run left
	
	print("Step 5: Both bots run to the left together")
	
	# Move both bots far to the left together
	var run_tween = create_tween()
	run_tween.set_parallel(true)
	run_tween.tween_property(bot1, "global_position:x", bot1.global_position.x - 600, 2.5)  # Run much farther left
	run_tween.tween_property(bot2, "global_position:x", bot2.global_position.x - 600, 2.5)  # Run much farther left too
	
	await run_tween.finished
	
	# Restore camera position
	if camera:
		var restore_tween = create_tween()
		restore_tween.tween_property(camera, "global_position", original_camera_pos, 0.5)
	
	print("=== CUTSCENE END ===")

func force_animation(sprite: AnimatedSprite2D, anim_name: String):
	# AGGRESSIVELY force the animation
	sprite.stop()
	await get_tree().process_frame
	sprite.animation = anim_name
	sprite.frame = 0
	await get_tree().process_frame
	sprite.play(anim_name)
	
	# Make sure it's not being overridden immediately
	await get_tree().create_timer(0.1).timeout
	if sprite.animation != anim_name:
		print("    WARNING: Animation was overridden! Setting again...")
		sprite.animation = anim_name
		sprite.play(anim_name)
	
	# Print what's happening
	print("  Setting ", sprite.name, " to: ", anim_name)
	print("    Current animation: ", sprite.animation)
	print("    Is playing: ", sprite.is_playing())

func shake_camera(camera: Camera2D, duration: float, intensity: float):
	var original_pos = camera.global_position
	var elapsed_time = 0.0
	
	while elapsed_time < duration:
		var shake_offset = Vector2(
			randf_range(-intensity, intensity),
			randf_range(-intensity, intensity)
		)
		
		# Create a new tween for each shake
		var shake_tween = create_tween()
		shake_tween.tween_property(camera, "global_position", original_pos + shake_offset, 0.05)
		await shake_tween.finished
		
		elapsed_time += 0.05
		
		# Reduce intensity over time for smoother effect
		intensity *= 0.95
	
	# Return camera to original position
	var final_tween = create_tween()
	final_tween.tween_property(camera, "global_position", original_pos, 0.1)
	await get_tree().create_timer(6.0).timeout
	animation.play("cut_scene")
