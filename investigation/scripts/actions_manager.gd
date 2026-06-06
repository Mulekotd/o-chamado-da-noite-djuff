@tool
class_name ActionsManager extends VBoxContainer
@export var clock_size : Vector2 = Vector2(16,24) :
	set(x):
		clock_size = x
		_repopulate_clocks()
@export var actions : int = 0 :
	set(x):
		actions = min(x, max_actions)
		actions = max(actions, 0)
		print(x)
@export var max_actions : int = 5 :
	set(x):
		max_actions = max(x, 0)
		actions = min(actions, max_actions)
		_repopulate_clocks()

## speed in which clocks fade in and out
@export var modulate_speed : float = 0.1
## clock side bob speed
@export var bob_speed : float = 0.1
@export var bob_amplitude : float = 30
## empty circle spin speed
@export var spin_speed : float = 0.1
var rnd_number : float

const CLOCK = preload("uid://fj1b2filxono")
const EMPTY_CLOCK_CIRCLE = preload("uid://dxy5eor5rqd4y")
const CLOCK_CONTAINER = preload("uid://b7fn23a6vcsgi")

func _ready() -> void:
	update_variables()
	_repopulate_clocks()
	rnd_number = randf_range(3932, 393932)

func _process(delta: float) -> void:
	_update_clocks(delta)

func update_variables() -> void:
	max_actions = InvestigationVars.get_max_actions()
	actions = InvestigationVars.get_actions()

## adds empty clocks for i in max_actions; removes exceeding clocks if exists.
func _repopulate_clocks() -> void:
	for c in get_children():
		c.queue_free()
	for i in max_actions:
		var clock_container := CLOCK_CONTAINER.instantiate()
		clock_container.position.x = (int(rnd_number * i)) % 10
		clock_container.get_child(0).custom_minimum_size = clock_size
		clock_container.get_child(0).pivot_offset_ratio = Vector2(0.5,0.5)
		clock_container.get_child(1).custom_minimum_size = clock_size
		clock_container.get_child(1).pivot_offset_ratio = Vector2(0.5,0.5)
		add_child(clock_container)

func _update_clocks(delta: float) -> void:
	var i : int = actions
	var clock_containers := get_children()
	var time_sec := Time.get_ticks_msec() / 1000.0
	for clock_container in clock_containers:
		var clock : TextureRect = clock_container.get_child(1)
		if i: # available
			clock.modulate = lerp(clock.modulate, Color(1,1,1,1), modulate_speed * delta)
			clock.rotation = lerp(clock.rotation, 
			sin(rnd_number * i + time_sec * bob_speed) * bob_amplitude,
			modulate_speed * delta)
			i -= 1
		else: # exceeding
			clock.modulate = lerp(clock.modulate, Color(0,0,1,0), modulate_speed * delta)
			clock.rotation = lerp(clock.rotation, PI*2 * 2, modulate_speed * delta)
		clock_container.get_child(0).rotation = clock_container.get_child(0).rotation + spin_speed * delta
