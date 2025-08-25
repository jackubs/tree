extends Area2D

@export var area_pcam: PhantomCamera2D

func _ready() -> void:
	connect("body_entered", _entered_area)
	connect("body_exited", _exited_area)

func _entered_area(body: Node) -> void:
	if body is CharacterBody2D:
		area_pcam.set_priority(20)

func _exited_area(body: Node) -> void:
	if body is CharacterBody2D:
		area_pcam.set_priority(0)
