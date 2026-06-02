extends CharacterBody2D

signal item_changed(new_index: int)
var current_item_index: int = 0

enum MovementStatus {
	IDLE,
	RUNNING
}

enum ActionStatus {
	IDLE,
	HOLDING_GUN,
	HOLDING_KNIFE,
	SHOOTING,
	SLICING
}

var current_movement_state: MovementStatus = MovementStatus.IDLE
var current_action_state: ActionStatus = ActionStatus.IDLE

# endregion

# region Configuration & Properties

const SPEED: float = 300.0

@export var bullet_scene: PackedScene
@export var dialogue_resource: DialogueResource
@export var dialogue_start: String = "start"

# Node References
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var muzzle: Marker2D = $AnimatedSprite2D/Muzzle
@onready var legs_sprite: AnimatedSprite2D = $LegsSprite

# Tracking Variables
var last_direction: Vector2 = Vector2.RIGHT
var input_direction: Vector2 = Vector2.ZERO
var is_in_dialogue: bool = false

# endregion


# region Built-in Lifecycle Methods

func _ready() -> void:
	# Connect dialogue system
	if DialogueManager:
		DialogueManager.dialogue_ended.connect(_on_dialogue_ended)
	
	# Connect animation finished signal to handle attack loops and locks
	animated_sprite.animation_finished.connect(_on_action_animation_finished)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept") and not is_in_dialogue:
		trigger_dialogue()


func _physics_process(_delta: float) -> void:
	handle_input()
	update_states()
	update_movement()
	update_rotation()
	update_animation()
	move_and_slide()

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
	if current_action_state != ActionStatus.SHOOTING and current_action_state != ActionStatus.SLICING:
		if Input.is_key_pressed(KEY_1): # Map to "1" key
			current_action_state = ActionStatus.HOLDING_GUN
			current_item_index = 0
			item_changed.emit(current_item_index)
		elif Input.is_key_pressed(KEY_2): # Map to "2" key
			current_action_state = ActionStatus.HOLDING_KNIFE
			current_item_index = 1
			item_changed.emit(current_item_index)
		elif Input.is_key_pressed(KEY_3): # Map to "3" key
			current_action_state = ActionStatus.IDLE
			current_item_index = 2
			item_changed.emit(current_item_index)

	# 3. Handle Combat/Attack Inputs
	if Input.is_action_just_pressed("shoot"):
		match current_action_state:
			ActionStatus.HOLDING_GUN:
				current_action_state = ActionStatus.SHOOTING
				shoot_bullet() # Handle projectile spawning instantly
			ActionStatus.HOLDING_KNIFE:
				current_action_state = ActionStatus.SLICING


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
		return
		
	var bullet = bullet_scene.instantiate()
	bullet.global_position = muzzle.global_position
	bullet.global_rotation = muzzle.global_rotation
	get_tree().current_scene.add_child(bullet)

# endregion


# region Dialogue Setup

func trigger_dialogue() -> void:
	is_in_dialogue = true
	velocity = Vector2.ZERO
	
	# Clean up movement visual assets instantly
	legs_sprite.visible = false
	legs_sprite.stop()
	legs_sprite.frame = 0
	
	animated_sprite.play("idle")
	DialogueManager.show_dialogue_balloon(dialogue_resource, dialogue_start)

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
		ActionStatus.SLICING:
			animated_sprite.play("slicing")

# endregion


# region Signal Connections

func _on_action_animation_finished() -> void:
	# Evaluates the active animation name when an animation finishes playing
	match animated_sprite.animation:
		"shooting":
			animated_sprite.frame = 0
			animated_sprite.stop()
			current_action_state = ActionStatus.HOLDING_GUN
			
		"slicing":
			animated_sprite.frame = 1
			animated_sprite.stop()
			current_action_state = ActionStatus.HOLDING_KNIFE


func _on_dialogue_ended(_resource: DialogueResource) -> void:
	is_in_dialogue = false
	current_movement_state = MovementStatus.IDLE

# endregion
