@tool
class_name InvestigationVars extends Resource

@export_tool_button("clear global variables")
var clear_action = clear_everything
func clear_everything() -> void:
	file.vars.clear()
	file.inventory.clear()
	file.set_actions(get_max_actions())
	file.last_pov = ""
	file.add_actions(-file._actions)
	
## vars are int for utility, use 0 and 1 if you want boolean behaviour
@export var vars : Dictionary[String, int] = {
	"option": -1,
}

@export var inventory : Array[Item] = [
	preload("uid://cqpw454xu78in"),
]

## maximum amount of actions the player can have
@export var _max_actions : int = 5
## how many actions the player has
@export var _actions : int = _max_actions

## points that influence how much insight the character has about the investigation
@export var _investigation_points : int = 0

@export var last_pov : String

## value to assign to a newly created variable
static var default_value : int = 0

static var file : InvestigationVars = load("res://investigation/investigation_variables.tres")


## returns int(number-of-conditions-met / number-of-keys-given) * number-of-keys-given - 1
static func get_conditions_value(conditions: Dictionary[String, int], count_option : bool = true) -> float:
	if not count_option:
		conditions.erase("option")
	var len : int = len(conditions.keys())
	if len == 0: return 0
	var conditions_met : int = get_conditions_met(conditions)
	return floorf(conditions_met / len) * len - 1

## returns how many conditions were met
static func get_conditions_met(conditions: Dictionary[String, int]) -> int:
	if len(conditions.keys()) == 0: return 99999999
	var conditions_met: int = 0
	for k : String in conditions.keys():
		if file.vars.get_or_add(k, default_value) == conditions[k]:
			conditions_met += 1
	return conditions_met

static func meets_all_conditions(conditions: Dictionary[String, int]) -> int:
	return get_conditions_met(conditions) == conditions.size()

static func check_inventory(items: Array[Item]) -> bool:
	for i in items:
		if i not in file.inventory:
			return false
	return true

static func update_variables(vars: Dictionary[String, int]) -> void:
	for k: String in vars.keys():
		if k == "option":
			continue
		file.vars[k] = vars[k]
	ResourceSaver.save(file)

static func set_option(value: int) -> void:
	if file.vars.get_or_add("option", -1) != value:
		file.vars["option"] = value
		ResourceSaver.save(file)

static func append_item(items: Array[Item]) -> void:
	for item in items:
		file.inventory.append(item)
	ResourceSaver.save(file)

static func remove_item(items: Array[Item]) -> void:
	for item in items:
		file.inventory.erase(item)
	ResourceSaver.save(file)

static func set_last_pov(p_name: String) -> void:
	file.last_pov = p_name
	ResourceSaver.save(file)

static func get_last_pov() -> String:
	return file.last_pov

static func set_actions(amount: int) -> void:
	file._actions = clamp(amount, 0, file._max_actions)
	ResourceSaver.save(file)

static func get_actions() -> int:
	return file._actions

## add a value to actions, negative or positive
static func add_actions(amount: int) -> void:
	set_actions(get_actions() + amount)

static func set_max_actions(amount: int) -> void:
	file._max_actions = max(0, amount)
	file._actions = min(file._actions, file._max_actions)
	ResourceSaver.save(file)

static func get_var_value(key: String) -> int:
	return file.vars.get_or_add(key, default_value)

static func get_max_actions() -> int:
	return file._max_actions

static func get_inventory() -> Array[Item]:
	return file.inventory

static func get_investigation_points() -> int:
	return file._investigation_points

static func add_investigation_points(amount: int) -> void:
	file._investigation_points = max(0, file._investigation_points + amount)
	ResourceSaver.save(file)
