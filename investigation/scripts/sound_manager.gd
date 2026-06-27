class_name _SoundManager extends Node

@onready var poly_player: AudioStreamPlayer = $PolyAudioStreamPlayer
@onready var letter_player: AudioStreamPlayer = $LetterAudioStreamPlayer
@onready var music_stream_player: AudioStreamPlayer = $MusicStreamPlayer

var letter_stream: AudioStreamRandomizer
var letter_playback: AudioStreamPlayback
var poly_playback: AudioStreamPlaybackPolyphonic

var DEFAULT_LETTER_SOUND = preload("uid://ccwxj47tohlth")

func _ready() -> void:
	letter_player.play()
	poly_player.play()
	letter_stream = letter_player.stream
	
	#play_soundtrack(preload("uid://cv1ok2itg5os8"))

func load_letter_sounds(sounds: Array) -> void:
	while letter_stream.streams_count:
		letter_stream.remove_stream(0)
	if sounds:
		for i in sounds.size():
			# print("LOAD LETTER SOUND ", i)
			letter_stream.add_stream(i, sounds[i])
	else:
		letter_stream.add_stream(0, DEFAULT_LETTER_SOUND)

func play_poly_sound(sound: AudioStream) -> void:
	# print("SOUND: ", sound)
	poly_player.stream = sound
	poly_player.play()

func play_letter_sound() -> void:
	letter_player.play()

func play_soundtrack(sound: AudioStream) -> void:
	music_stream_player.stream = sound
	music_stream_player.bus = "Music"
	music_stream_player.play()

func stop_soundtrack() -> void:
	music_stream_player.stop()
