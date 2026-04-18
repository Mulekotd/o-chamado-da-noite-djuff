class_name InvestigationVars extends Resource

## vars are int for utility, use 0 and 1 if you want boolean behaviour
@export var vars : Dictionary[String, int] = {
	"test_var": 1,
	"door_unlocked": 0,
}

@export var inventory : Array[Item] = [
	preload("uid://cqpw454xu78in"),
]

static var file := load("res://resources/investigation_variables.tres")

static func check_global_conditions(conditions: Dictionary[String, int]) -> bool:
	for k in conditions.keys():
		if file.vars[k] != conditions[k]:
			return false
	return true

static func check_inventory(items: Array[Item]) -> bool:
	for i in items:
		if i not in file.inventory:
			return false
	return true

static func update_variables(vars: Dictionary[String, int]) -> void:
	for k in vars.keys():
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
