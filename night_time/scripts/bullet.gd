extends Area2D

@export var speed: float = 3000 

func _physics_process(delta):
	position += transform.x * speed * delta

func _on_body_entered(body):
	print("ON BODY ENTERED")
	if body.has_method("take_damage"):
		body.take_damage()
	
	queue_free() # Destroy the bullet on impact
