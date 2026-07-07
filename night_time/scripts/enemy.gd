extends CharacterBody2D
@export var bullet_scene: PackedScene
@export var fire_rate: float = 1.0 ## Time in seconds between shots
@export var accuracy_variance: float = 15.0 ## Maximum shooting angle deviation in degrees
@export var dialogue_resource: DialogueResource
@export var dialogue_start: String = "start_enemy"
@export var move_speed: float = 150.0 ## Movement speed in pixels/second
@export var shoot_range: float = 700.0 ## Max distance to start shooting
@export var stop_distance: float = 300.0 ## Distance at which enemy stops closing in (optional, keeps it from hugging the player)
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var muzzle: Marker2D = $AnimatedSprite2D/Muzzle
var player: Node2D = null
var time_since_last_shot: float = 0.0
## Once engaged, the enemy keeps moving/shooting regardless of player state.
var _is_engaged: bool = false
func _ready() -> void:
	# Get the first node in the 'player' group
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0] as Node2D
func _physics_process(delta: float) -> void:
	time_since_last_shot += delta
	if player and is_instance_valid(player):
		if not _is_engaged:
			if player.current_action_state != player.ActionStatus.IDLE:
				_is_engaged = true
		if not _is_engaged:
			velocity = Vector2.ZERO
			move_and_slide()
			return
		var distance: float = global_position.distance_to(player.global_position)
		# Always look at the player
		look_at(player.global_position)
		# Move toward the player if outside stop_distance
		if distance > stop_distance:
			var direction: Vector2 = (player.global_position - global_position).normalized()
			velocity = direction * move_speed
		else:
			velocity = Vector2.ZERO
		move_and_slide()
		# Only shoot if within shoot_range and the weapon is ready
		if distance <= shoot_range and time_since_last_shot >= fire_rate:
			shoot()
			time_since_last_shot = 0.0
	else:
		velocity = Vector2.ZERO
		move_and_slide()
		
		
func shoot() -> void:
	if not bullet_scene:
		return
		
	# Instantiate the bullet
	var bullet = bullet_scene.instantiate()
	
	# Add it to the main scene tree so it moves independently of the enemy
	get_tree().root.add_child(bullet)
	
	# Position the bullet at the muzzle marker
	bullet.global_position = muzzle.global_position
	
	# Calculate a random angle offset within the variance range (converted to radians)
	var random_offset = randf_range(-accuracy_variance, accuracy_variance)
	var random_offset_radians = deg_to_rad(random_offset)
	
	# Apply the offset to the muzzle's rotation
	bullet.global_rotation = muzzle.global_rotation + random_offset_radians
	
	# Set the collision mask to only detect layer 1
	if "collision_mask" in bullet:
		bullet.collision_mask = 3
		
func interact(player: CharacterBody2D) -> void:
	if not dialogue_resource:
		return
	DialogueManager.show_dialogue_balloon(dialogue_resource, dialogue_start)
	
	# 2. Wait until the dialogue completely wraps up
	await DialogueManager.dialogue_ended
	
	# 3. Safely tell the player node to resume movement
	player.end_dialogue()
## Handles incoming damage to the character.
## By default, this will immediately destroy the node.
func take_damage(amount: int = 0) -> void:
	queue_free()
