class_name _Player extends CharacterBody2D

signal item_changed(new_index: int)
signal health_changed(current_health: int, max_health: int)
signal died
signal gunshot
signal empty_gun
signal reloading
signal ammo_changed(current_ammo: int, max_ammo: int)
signal reserve_ammo_changed(current_reserve: int)
signal hit
signal knife


@export var max_health: int = 100
var current_health: int = max_health

@export var magazine_size: int = 6
var current_ammo: int = magazine_size
@export var reserve_ammo: int = 30

var current_item_index: int = 0

enum MovementStatus {
	IDLE,
	RUNNING
}

enum ActionStatus {
	IDLE,
	HOLDING_GUN,
	RELOADING,
	HOLDING_KNIFE,
	SHOOTING,
	SLICING
}

var current_movement_state: MovementStatus = MovementStatus.IDLE
var current_action_state: ActionStatus = ActionStatus.IDLE
var weapon_drawn: bool : get = _is_weapon_drawn

func _is_weapon_drawn() -> bool:
	return current_action_state != ActionStatus.IDLE

# endregion

# region Configuration & Properties

const SPEED: float = 300.0

@export var bullet_scene: PackedScene

# Node References
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var muzzle: Marker2D = $AnimatedSprite2D/Muzzle
@onready var legs_sprite: AnimatedSprite2D = $LegsSprite
@onready var slice_hitbox: Area2D = $AnimatedSprite2D/SliceHitbox
@onready var interaction_zone: Area2D = $InteractionZone # Add this Area2D to your Player scene
@onready var health_bar: ProgressBar = $HealthBar # update path as needed
@onready var chat_label: Label = $ChatLabel

# Tracking Variables
var last_direction: Vector2 = Vector2.RIGHT
var input_direction: Vector2 = Vector2.ZERO
var is_in_dialogue: bool = false
var slice_has_hit: bool = false  # guards against re-triggering on repeated frame_changed calls
var interactables_in_range: Array[Node2D] = []

# endregion


# region Built-in Lifecycle Methods

func _ready() -> void:
	animated_sprite.animation_finished.connect(_on_action_animation_finished)
	animated_sprite.frame_changed.connect(_on_animated_sprite_frame_changed)
	slice_hitbox.monitoring = false

	if interaction_zone:
		interaction_zone.body_entered.connect(_on_interaction_zone_body_entered)
		interaction_zone.body_exited.connect(_on_interaction_zone_body_exited)

	# Health setup
	current_health = max_health
	health_bar.max_value = max_health
	health_bar.value = current_health

func start_slice() -> void:
	slice_has_hit = false
	slice_hitbox.monitoring = true

func _on_animated_sprite_frame_changed() -> void:
	if animated_sprite.animation != "slicing":
		return
	if animated_sprite.frame == 3 and not slice_has_hit:  # 4th frame, 0-indexed
		slice_has_hit = true
		_apply_slice_damage()


func _apply_slice_damage() -> void:
	for body in slice_hitbox.get_overlapping_bodies():
		if body.has_method("take_damage"):
			body.take_damage()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact") and not is_in_dialogue:
		try_interaction()


func _physics_process(_delta: float) -> void:
	handle_input()
	update_states()
	update_movement()
	update_rotation()
	update_animation()
	move_and_slide()
	
	print(weapon_drawn)
	if interactables_in_range and not weapon_drawn:
		chat_label.visible = true
	else:
		chat_label.visible = false
	
# endregion


# region Input & State Handling

func handle_input() -> void:
	# Block all movement and action inputs while talking
	if is_in_dialogue:
		input_direction = Vector2.ZERO
		return
		
	# 1. Gather Movement Direction
	input_direction = Input.get_vector("left", "right", "up", "down")
	
	# 2. Handle Weapon Selection (Only allowed if not actively attacking)
	if current_action_state != ActionStatus.SHOOTING and current_action_state != ActionStatus.SLICING and current_action_state != ActionStatus.RELOADING:
		if Input.is_key_pressed(KEY_1): # Map to "1" key
			current_action_state = ActionStatus.HOLDING_GUN
			current_item_index = 0
			item_changed.emit(current_item_index)
		elif Input.is_key_pressed(KEY_2): # Map to "2" key
			weapon_drawn = true
			current_action_state = ActionStatus.HOLDING_KNIFE
			current_item_index = 1
			item_changed.emit(current_item_index)
		elif Input.is_key_pressed(KEY_3): # Map to "3" key
			weapon_drawn = true
			current_action_state = ActionStatus.IDLE
			current_item_index = 2
			item_changed.emit(current_item_index)

	# 3. Handle Reload
	if Input.is_action_just_pressed("reload") and current_action_state == ActionStatus.HOLDING_GUN:
		reload()

	# 4. Handle Combat/Attack Inputs
	if Input.is_action_just_pressed("shoot"):
		match current_action_state:
			ActionStatus.HOLDING_GUN:
				if current_ammo <= 0:
					empty_gun.emit()
					return
				current_action_state = ActionStatus.SHOOTING
				shoot_bullet()
			ActionStatus.HOLDING_KNIFE:
				current_action_state = ActionStatus.SLICING
				start_slice()



func update_states() -> void:
	if is_in_dialogue:
		return
		
	# Evaluate movement state independently of combat state
	if input_direction != Vector2.ZERO:
		current_movement_state = MovementStatus.RUNNING
	else:
		current_movement_state = MovementStatus.IDLE

# endregion


# region Movement & Rotation

func update_movement() -> void:
	if is_in_dialogue:
		velocity = Vector2.ZERO
		return

	velocity = input_direction * SPEED
	
	if input_direction != Vector2.ZERO:
		last_direction = input_direction


func update_rotation() -> void:
	if is_in_dialogue:
		return

	# Upper body tracks the tactical pointer (mouse)
	var mouse_pos = get_global_mouse_position()
	animated_sprite.look_at(mouse_pos)
	
	# Legs turn dynamically towards actual walking velocity vector
	if input_direction != Vector2.ZERO:
		legs_sprite.rotation = input_direction.angle()
	else:
		legs_sprite.rotation = last_direction.angle()

# endregion


# region Combat Actions

func shoot_bullet() -> void:
	if not bullet_scene:
		print("no bullet")
		return
	if current_ammo <= 0:
		return

	current_ammo -= 1
	ammo_changed.emit(current_ammo, magazine_size)

	var bullet = bullet_scene.instantiate()
	bullet.global_position = muzzle.global_position
	bullet.global_rotation = muzzle.global_rotation
	get_tree().current_scene.add_child(bullet)
	gunshot.emit()

# endregion


# region Interaction & Dialogue Setup

func try_interaction() -> void:
	if interactables_in_range.is_empty():
		return
		
	# Find the closest target in range
	var target = interactables_in_range[0]
	if interactables_in_range.size() > 1:
		for body in interactables_in_range:
			if global_position.distance_to(body.global_position) < global_position.distance_to(target.global_position):
				target = body

	# Duck typing: Check if the target has an interact method
	if target.has_method("interact"):
		if "is_scared" in target and target.is_scared:
			return
		is_in_dialogue = true
		velocity = Vector2.ZERO
		
		# Clean up movement visual assets instantly
		legs_sprite.visible = false
		legs_sprite.stop()
		legs_sprite.frame = 0
		animated_sprite.play("idle")
		
		# Call interact on the target, passing the player reference so it can connect dialog signals back
		target.interact(self)


func end_dialogue() -> void:
	is_in_dialogue = false
	current_movement_state = MovementStatus.IDLE

# endregion


# region Animation Management

func update_animation() -> void:
	if is_in_dialogue:
		return

	# --- 1. Lower Body (Movement Status) ---
	match current_movement_state:
		MovementStatus.IDLE:
			legs_sprite.visible = false
			legs_sprite.stop()
			legs_sprite.frame = 0
		MovementStatus.RUNNING:
			legs_sprite.visible = true
			# Ensures we don't restart the animation if it's already playing
			legs_sprite.play("running")

	match current_action_state:
		ActionStatus.IDLE:
			animated_sprite.play("idle")
		ActionStatus.HOLDING_GUN:
			animated_sprite.play("holding_gun")
		ActionStatus.HOLDING_KNIFE:
			animated_sprite.play("holding_knife")
		ActionStatus.SHOOTING:
			animated_sprite.play("shooting")
		ActionStatus.RELOADING:
			animated_sprite.play("reloading")
		ActionStatus.SLICING:
			animated_sprite.play("slicing")

# endregion


# region Signal Connections

func reload() -> void:
	if current_ammo >= magazine_size or reserve_ammo <= 0:
		return
	var needed = magazine_size - current_ammo
	var taken = mini(needed, reserve_ammo)
	current_ammo += taken
	reserve_ammo -= taken
	current_action_state = ActionStatus.RELOADING
	reloading.emit()
	ammo_changed.emit(current_ammo, magazine_size)
	reserve_ammo_changed.emit(reserve_ammo)

func _on_action_animation_finished() -> void:
	# Evaluates the active animation name when an animation finishes playing
	match animated_sprite.animation:
		"shooting":
			animated_sprite.frame = 0
			animated_sprite.stop()
			current_action_state = ActionStatus.HOLDING_GUN
		
		"reloading":
			animated_sprite.frame = 1
			animated_sprite.stop()
			current_action_state = ActionStatus.HOLDING_GUN
			
		"slicing":
			animated_sprite.frame = 1
			animated_sprite.stop()
			current_action_state = ActionStatus.HOLDING_KNIFE
			slice_hitbox.monitoring = false


func _on_interaction_zone_body_entered(body: Node2D) -> void:
	if body.has_method("interact") and not interactables_in_range.has(body):
		interactables_in_range.append(body)


func _on_interaction_zone_body_exited(body: Node2D) -> void:
	if interactables_in_range.has(body):
		interactables_in_range.erase(body)

# endregion

# region Health

func take_damage(amount: int = 25) -> void:
	if current_health <= 0:
		return # already dead, ignore further hits

	current_health = clampi(current_health - amount, 0, max_health)
	health_changed.emit(current_health, max_health)
	_update_health_bar()

	if current_health == 0:
		die()


func heal(amount: int) -> void:
	current_health = clampi(current_health + amount, 0, max_health)
	health_changed.emit(current_health, max_health)
	_update_health_bar()


func _update_health_bar() -> void:
	if health_bar:
		health_bar.value = current_health


func die() -> void:
	died.emit()
	animated_sprite.play("dead")
	legs_sprite.visible = false
	set_physics_process(false)

# endregion
