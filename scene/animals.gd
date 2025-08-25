extends AnimatedSprite2D

@export var speed: float = 50.0   # walking speed
var direction: int = 0            # -1 = left, 1 = right, 0 = idle
var state: String = "idle"
var state_timer: float = 0.0

func _ready() -> void:
	randomize()
	_choose_new_state()

func _process(delta: float) -> void:
	state_timer -= delta
	if state_timer <= 0:
		_choose_new_state()
	
	match state:
		"walk":
			position.x += direction * speed * delta
			play("walk")
			flip_h = direction < 0   # Flip sprite when going left
		"sleep":
			play("sleep")
		"eat":
			play("eat")
		"idle":
			play("idle")

func _choose_new_state() -> void:
	var states = ["walk", "sleep", "eat", "idle"]
	state = states[randi() % states.size()]
	
	# Duration 1–3 seconds
	state_timer = randf_range(1.0, 3.0)
	
	if state == "walk":
		direction = [-1, 1][randi() % 2]   # left or right
	else:
		direction = 0
