extends Node

const behaviour_name : String = "behaviour"

func _init():
	pass

func _physics_process(delta: float) -> void:
	# Default behaviour stub to show the node is alive.
	alive_signal()

func alive_signal() -> void:
	print("ISSO EH UM BEHAVIOUR")
