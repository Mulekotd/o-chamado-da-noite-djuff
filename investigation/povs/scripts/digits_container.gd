class_name DigitsContainer extends Control

var puzzle_pov : PuzzlePov
var enabled : bool = false :
	set(x):
		enabled = x
		propagate_enabled()

signal combination_struck
signal digit_changed

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func load_digits(pp: PuzzlePov) -> void:
	clear_digits()
	
	puzzle_pov = pp
	
	var i : int = 0
	for digit in pp.digits.keys():
		var d_pos  : Vector2 = digit * size
		var d_size : Vector2 = pp.digits[digit] * size
		var var_to_change : String = "%s_pp_digit_%d" % [pp.name, i]
		
		var d := Digit.new()
		add_child(d)
		d.load_digit(d_pos, d_size, pp.symbols, var_to_change)
		d.value_changed.connect(check_combinations)
		d.value_changed.connect(digit_changed.emit)
		
		i += 1
	
	update_enabled()
	
	
func clear_digits() -> void:
	for c in get_children():
		c.queue_free()

func update_enabled() -> void:
	enabled = InvestigationVars.get_conditions_value(puzzle_pov.global_conditions) != -1
	
## return a combination string in the format "0 1 2 3 99"
func get_current_combination() -> String:
	var digits := get_children()
	var values : Array[String] = []
	
	for digit in digits:
		if digit is Digit:
			values.append("%d" % digit.get_value())
		
	return " ".join(values)

func check_combinations() -> void:
	var curr_comb : String = get_current_combination()
	for comb in puzzle_pov.combinations.keys():
		var var_to_change : String = puzzle_pov.combinations.get(comb)
		var curr_var_value : int = InvestigationVars.get_var_value(var_to_change)
		if comb == curr_comb: # combination struck !
			InvestigationVars.update_variables({var_to_change: 2})
			combination_struck.emit()
		elif curr_var_value == 2 or curr_var_value == 1:
			InvestigationVars.update_variables({var_to_change: 1})
		else:
			InvestigationVars.update_variables({var_to_change: 0})

func propagate_enabled() -> void:
	for c in get_children():
		if c is Digit:
			c.enabled = enabled
