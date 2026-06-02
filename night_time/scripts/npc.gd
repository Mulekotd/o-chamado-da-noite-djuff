extends CharacterBody2D

## Handles incoming damage to the character.
## By default, this will immediately destroy the node.
func take_damage(amount: int = 0) -> void:
	queue_free()
