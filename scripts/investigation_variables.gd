class_name InvestigationVars extends Resource

## vars are int for utility, use 0 and 1 if you want boolean behaviour
static var vars : Dictionary[String, int] = {
	"test_var": 1,
	"door_unlocked": 0,
}

static var inventory : Array[Item] = [
	preload("uid://cqpw454xu78in"),
]

static func check_global_conditions(conditions: Array[String]) -> bool:
	for v in conditions:
		if vars[v] == 0:
			return false
	return true

static func check_inventory(items: Array[Item]) -> bool:
	for i in items:
		if i not in inventory:
			return false
	return true
