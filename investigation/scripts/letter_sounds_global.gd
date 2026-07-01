class_name LetterSoundsGlobal extends Node

## Collection of arrays containing letter sounds.
static var sounds : Dictionary[String, Array] = {
	"brother" : [
		preload("uid://daummla660hnv"), 
		preload("uid://bwrb5yo6fhxd4"), 
		preload("uid://cosmakpxhnwbp"),
		preload("uid://cbqly6yd1bleu"), 
		preload("uid://cwl8whb5m7xpu")
	],
	"telephone" : [
		preload("uid://dyltuafgfo772"),
		preload("uid://cu3tj1jyyq1rs"),
		preload("uid://xk1ucvn8af4o"),
		preload("uid://c08u03lhtak4d"),
		preload("uid://b1pp6ge8tx5v8")
	]
}

static var default_sound = [preload("uid://4p0mgxkjb7fc")]
