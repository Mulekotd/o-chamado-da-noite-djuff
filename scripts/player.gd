extends CharacterBody2D

enum State {
	IDLE,
	RUN,
	ATTACK,
	DIALOGUE
}

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

const SPEED = 300.0

var current_state: State = State.IDLE
var last_direction: Vector2 = Vector2.RIGHT
var input_direction: Vector2 = Vector2.ZERO

# Drag your .dialogue file into this variable in the Inspector
@export var dialogue_resource: DialogueResource
@export var dialogue_start: String = "start"

func _ready() -> void:
	DialogueManager.dialogue_ended.connect(_on_dialogue_ended)

func _on_dialogue_ended(_resource: DialogueResource) -> void:
	change_state(State.IDLE)
	
func _unhandled_input(event):
	if event.is_action_pressed("ui_accept"):
		change_state(State.DIALOGUE)
		velocity = Vector2.ZERO
		DialogueManager.show_dialogue_balloon(dialogue_resource, dialogue_start)
		
		
func _physics_process(delta: float) -> void:
	handle_input()
	update_state()
	update_movement()
	update_animation()
	move_and_slide()

func handle_input() -> void:
	input_direction = Input.get_vector("left", "right", "up", "down")

func update_state() -> void:
	if current_state == State.DIALOGUE:
		return
	match current_state:
		State.IDLE:
			if input_direction != Vector2.ZERO:
				change_state(State.RUN)

		State.RUN:
			if input_direction == Vector2.ZERO:
				change_state(State.IDLE)

func change_state(new_state: State) -> void:
	if new_state == current_state:
		return
	
	current_state = new_state

func update_movement() -> void:
	match current_state:
		State.IDLE:
			velocity = Vector2.ZERO

		State.RUN:
			velocity = input_direction * SPEED
			last_direction = input_direction

func update_animation() -> void:
	match current_state:
		State.IDLE:
			play_animation("idle", last_direction)

		State.RUN:
			play_animation("run", input_direction)

func play_animation(prefix: String, direction: Vector2) -> void:
	if direction.x != 0:
		animated_sprite.flip_h = direction.x < 0
		animated_sprite.play(prefix + "_right")
	elif direction.y < 0:
		animated_sprite.play(prefix + "_up")
	elif direction.y > 0:
		animated_sprite.play(prefix + "_down")
		
