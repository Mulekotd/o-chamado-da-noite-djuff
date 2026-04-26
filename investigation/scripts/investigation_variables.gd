class_name InvestigationVars extends Resource

## vars are int for utility, use 0 and 1 if you want boolean behaviour
@export var vars : Dictionary[String, int] = {
	"test_var": 1,
	"door_unlocked": 0,
}

@export var inventory : Array[Item] = [
	preload("uid://cqpw454xu78in"),
]

@export var last_pov : String

## value to assign to a newly created variable
static var default_value : int = 0

static var file : InvestigationVars = load("res://investigation/investigation_variables.tres")

static func check_global_conditions(conditions: Dictionary[String, int]) -> bool:
	for k : String in conditions.keys():
		#print(file.vars.get(k))
		if file.vars.get_or_add(k, default_value) != conditions[k]:
			#print(conditions.keys(), "FALSE")
			return false
	#print(conditions.keys(), "FALSE")
	return true

static func check_inventory(items: Array[Item]) -> bool:
	for i in items:
		if i not in file.inventory:
			return false
	return true

static func update_variables(vars: Dictionary[String, int]) -> void:
	for k: String in vars.keys():
		file.vars[k] = vars[k]
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
	print("FILE.LAST_POV: ", file.last_pov)
	return file.last_pov
