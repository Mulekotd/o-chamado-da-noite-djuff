class_name PuzzlePov extends Pov

"""
This is a special type of Pov, meant for combination puzzles.

When this Pov is interacted with by the first time, dedicaded global
variables will be created. Those variables will store the index of
each symbol in this Pov, so that when the player leaves and returns to
this Pov, the changes are saved.
The developer will input global variables that will be set to 1 when
the player inputs certain combinations at least one time,
and set to 2 if the combination is currently selected.

Every time the player inputs a combination, this Pov's prompt chain will
be displayed, with the developer using the previously given global variables
to employ the logic.

After inputing at least one symbol, the developer will be able to choose
the position of each digit on the pov image, using the first symbol image
as the reference for the positioning.

Puzzle Povs can also check for a global condition to decide if the player
can actually interact with any digit.

The symbols go in a positive cyclic manner. Meaning the index is += 1 every
interaction and comes back to the beginning when it reaches the end.
"""

## name of the pov behind this one; Where the player came from
@export var behind_pov : String = ""
## array of images representing the symbols of this pov; order matters.
@export var symbols : Array[Texture2D] = []
## array of positions of each digit in the pov; also used to get the quantity of digits (len)
@export var positions : Array[Vector2] = [] 
## combinations and their respective var-to-change; Combination should be of format "0 1 2 3"
@export var combinations : Dictionary[String, String] = {}
# "prompt_chain" will be displayed every time a combination is struck.
# "global_conditions" will be used for the "can i interact" logic.

## Editor-only coordinates for the Puzzle POV widget.
@export var coords : Vector2 = Vector2.ZERO
