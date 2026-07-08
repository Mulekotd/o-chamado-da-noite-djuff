class_name _Enemy extends CharacterBody2D

@export var bullet_scene: PackedScene
@export var fire_rate: float = 1.0 ## Time in seconds between shots
@export var accuracy_variance: float = 15.0 ## Maximum shooting angle deviation in degrees
@export var dialogue_resource: DialogueResource = preload("res://night_time/dialogues/dialogue.dialogue")
@export var dialogue_start: String = "start_enemy"
@export var move_speed: float = 150.0 ## Movement speed in pixels/second
@export var shoot_range: float = 700.0 ## Max distance to start shooting
@export var stop_distance: float = 300.0 ## Distance at which enemy stops closing in (optional, keeps it from hugging the player)
@export var shoot_flash_duration: float = 0.1 ## How long the "frame 1" muzzle flash frame is shown

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var muzzle: Marker2D = $AnimatedSprite2D/Muzzle
@onready var child_animated_sprite: AnimatedSprite2D = $AnimatedSprite2D/AnimatedSprite2D

signal gunshot
signal hit

var player: Node2D = null
var time_since_last_shot: float = 0.0
var _is_engaged: bool = false
var _is_flashing: bool = false
## Tracks whether the nested (running) animation has started playing.
var _is_running: bool = false
var is_dead: bool = false
func _ready() -> void:
	# Make sure the parent sprite starts on its "default" animation.
	if animated_sprite.sprite_frames.has_animation("default"):
		animated_sprite.play("default")
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0] as Node2D

func _physics_process(delta: float) -> void:
	time_since_last_shot += delta
	if player and is_instance_valid(player):
		if not _is_engaged:
			if player.current_action_state != player.ActionStatus.IDLE:
				_is_engaged = true
				_start_shooting_animation()
		if not _is_engaged:
			velocity = Vector2.ZERO
			move_and_slide()
			return
		var distance: float = global_position.distance_to(player.global_position)
		look_at(player.global_position)

		const STOP_MARGIN := 20.0  # buffer zone in pixels
		if distance > stop_distance:
			var direction: Vector2 = (player.global_position - global_position).normalized()
			velocity = direction * move_speed
			if not _is_running:
				_is_running = true
				_start_running_animation()
		elif distance < stop_distance - STOP_MARGIN:
			velocity = Vector2.ZERO
			if _is_running:
				_is_running = false
				_stop_running_animation()
		else:
			velocity = Vector2.ZERO if not _is_running else velocity
			if _is_running:
				_is_running = false
				_stop_running_animation()
		move_and_slide()
		if distance <= shoot_range and time_since_last_shot >= fire_rate:
			shoot()
			time_since_last_shot = 0.0
	else:
		velocity = Vector2.ZERO
		if _is_running:
			_is_running = false
			_stop_running_animation()
		move_and_slide()
		
## Stops the nested AnimatedSprite2D's animation once the enemy is no longer moving.
func _stop_running_animation() -> void:
	child_animated_sprite.stop()
	child_animated_sprite.frame = 0
	
	
## Starts the nested AnimatedSprite2D's animation once the enemy begins running.
func _start_running_animation() -> void:
	if not child_animated_sprite.sprite_frames.has_animation("running"):
		return
	child_animated_sprite.play("running")

## Switches the sprite to the "shooting" animation and locks it on frame 0.
func _start_shooting_animation() -> void:
	if not animated_sprite.sprite_frames.has_animation("shooting"):
		return
	animated_sprite.animation = "shooting"
	animated_sprite.frame = 0
	animated_sprite.stop()



func shoot() -> void:
	if not bullet_scene:
		return
	var bullet = bullet_scene.instantiate()
	get_tree().root.add_child(bullet)
	bullet.global_position = muzzle.global_position
	var random_offset = randf_range(-accuracy_variance, accuracy_variance)
	var random_offset_radians = deg_to_rad(random_offset)
	bullet.global_rotation = muzzle.global_rotation + random_offset_radians
	if "collision_mask" in bullet:
		bullet.collision_mask = 7
	_flash_shoot_frame()
	gunshot.emit()

## Briefly shows frame 1 of the "shooting" animation, then returns to frame 0.
func _flash_shoot_frame() -> void:
	if _is_flashing:
		return
	_is_flashing = true
	animated_sprite.animation = "shooting"
	animated_sprite.frame = 1
	await get_tree().create_timer(shoot_flash_duration).timeout
	if is_instance_valid(animated_sprite):
		animated_sprite.frame = 0
	_is_flashing = false

func interact(player: CharacterBody2D) -> void:
	if not dialogue_resource:
		return
	DialogueManager.show_dialogue_balloon(dialogue_resource, dialogue_start)
	await DialogueManager.dialogue_ended
	player.end_dialogue()

func take_damage(amount: int = 0) -> void:
	hit.emit()
	is_dead = true
	set_physics_process(false)
	set_process(false)
	if has_node("CollisionShape2D"):
		$CollisionShape2D.set_deferred("disabled", true)
	
	child_animated_sprite.visible = false
	animated_sprite.play("die")
	await animated_sprite.animation_finished
