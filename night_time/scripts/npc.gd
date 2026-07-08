extends CharacterBody2D

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var child_animated_sprite: AnimatedSprite2D = $AnimatedSprite2D/AnimatedSprite2D

@export var flee_speed: float = 150.0
@export var player: CharacterBody2D
@export var dialogue_resource: DialogueResource = preload("res://night_time/dialogues/dialogue.dialogue")
@export var dialogue_start: String = "start"

@export_group("Patrol Settings")
@export var patrol_distance: float = 50.0
@export var min_patrol_duration: float = 1.5
@export var max_patrol_duration: float = 3.0

var is_dead: bool = false

## Once fleeing starts, it keeps running regardless of player state.
var _is_fleeing: bool = false

var _patrol_tween: Tween
var _start_position: Vector2

func _ready() -> void:
	if not player:
		player = get_tree().get_first_node_in_group("player")
	_start_position = global_position
	_start_patrol()

func _physics_process(_delta: float) -> void:
	if not player:
		return
	if not _is_fleeing:
		if player.current_action_state != player.ActionStatus.IDLE:
			_is_fleeing = true
			_stop_patrol()

	if _is_fleeing:
		flee_from_player()
	else:
		move_and_slide()

func interact(player: CharacterBody2D) -> void:
	if not dialogue_resource:
		return
	DialogueManager.show_dialogue_balloon(dialogue_resource, dialogue_start)

	# 2. Wait until the dialogue completely wraps up
	await DialogueManager.dialogue_ended

	# 3. Safely tell the player node to resume movement
	player.end_dialogue()

func flee_from_player() -> void:
	var direction: Vector2 = (global_position - player.global_position).normalized()
	velocity = direction * flee_speed
	move_and_slide()
	$AnimatedSprite2D.rotation = direction.angle()

## Starts a fresh tween to a random point within a 2D radius, then loops via callback.
func _start_patrol() -> void:
	_stop_patrol()

	# Pick a random point on both X and Y axes within the patrol distance
	var random_offset: Vector2 = Vector2(
		randf_range(-patrol_distance, patrol_distance),
		randf_range(-patrol_distance, patrol_distance)
	)
	var target_point: Vector2 = _start_position + random_offset
	
	# Randomize how long it takes to get there so the pacing changes up
	var duration: float = randf_range(min_patrol_duration, max_patrol_duration)

	_patrol_tween = create_tween()
	_patrol_tween.tween_property(self, "global_position", target_point, duration)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_IN_OUT)
	
	# When this step finishes, call this exact function again to pick a new spot
	_patrol_tween.tween_callback(_start_patrol)

## Stops the patrol tween, if any, so fleeing can take over movement cleanly.
func _stop_patrol() -> void:
	if _patrol_tween and _patrol_tween.is_valid():
		_patrol_tween.kill()
	velocity = Vector2.ZERO

## Handles incoming damage to the character.
## By default, this will immediately destroy the node.
func take_damage(amount: int = 0) -> void:
	is_dead = true
	set_physics_process(false)
	set_process(false)
	if has_node("CollisionShape2D"):
		$CollisionShape2D.set_deferred("disabled", true)
	
	child_animated_sprite.visible = false
	animated_sprite.play("die")
	await animated_sprite.animation_finished
