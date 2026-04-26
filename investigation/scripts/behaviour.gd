extends Node

const behaviour_name : String = "behaviour"

func _init():
	pass

func _physics_process(delta: float) -> void:
	alive_signal()

func alive_signal() -> void:
	print("ISSO EH UM BEHAVIOUR")
