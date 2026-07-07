extends CharacterBody2D
## Speed at which the NPC runs away from the player.
@export var flee_speed: float = 150.0
## Reference to the player node. Assign in the editor, or it will be
## found automatically via the "player" group.
@export var player: CharacterBody2D
@export var dialogue_resource: DialogueResource
@export var dialogue_start: String = "start"

## Once fleeing starts, it keeps running regardless of player state.
var _is_fleeing: bool = false

func _ready() -> void:
	if not player:
		player = get_tree().get_first_node_in_group("player")

func _physics_process(_delta: float) -> void:
	if not player:
		return

	if not _is_fleeing:
		if player.current_action_state != player.ActionStatus.IDLE:
			_is_fleeing = true

	if _is_fleeing:
		flee_from_player()
	else:
		velocity = Vector2.ZERO
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
## Handles incoming damage to the character.
## By default, this will immediately destroy the node.
func take_damage(amount: int = 0) -> void:
	queue_free()
