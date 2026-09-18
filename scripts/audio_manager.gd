extends Node

const MUSIC: AudioStream = preload("res://audio/music.mp3")

const SFX_COMPLETE: AudioStream = preload("res://audio/complete.wav")
const SFX_COUNTDOWN: AudioStream = preload("res://audio/countdown.wav")
const SFX_DEATH: AudioStream = preload("res://audio/death.wav")
const SFX_MOVE_HEAVY: AudioStream = preload("res://audio/move_heavy.wav")
const SFX_MOVE: AudioStream = preload("res://audio/move.wav")
const SFX_SELECT: AudioStream = preload("res://audio/select.wav")

var music_player: AudioStreamPlayer
var movement_player: AudioStreamPlayer
var movement_is_heavy := false

func _ready() -> void:
	music_player = AudioStreamPlayer.new()
	music_player.name = "Music"
	music_player.stream = MUSIC
	music_player.bus = "Music"
	add_child(music_player)

	movement_player = AudioStreamPlayer.new()
	movement_player.name = "Movement"
	movement_player.bus = "SFX"
	add_child(movement_player)
	
	play_music()

func play_music() -> void:
	if music_player.playing:
		return

	music_player.play()

func stop_music() -> void:
	music_player.stop()

func play_complete() -> void:
	play_sfx(SFX_COMPLETE)

func play_countdown() -> void:
	play_sfx(SFX_COUNTDOWN)

func play_death() -> void:
	play_sfx(SFX_DEATH)

func start_move(heavy: bool = false) -> void:
	var wanted_stream: AudioStream

	if heavy: wanted_stream = SFX_MOVE_HEAVY
	else: wanted_stream = SFX_MOVE

	if movement_player.playing and movement_is_heavy == heavy:
		return

	movement_is_heavy = heavy
	movement_player.stream = wanted_stream
	movement_player.play()

func stop_move() -> void:
	if movement_player.playing:
		movement_player.stop()

func update_move(heavy: bool) -> void:
	if not movement_player.playing: return
	if movement_is_heavy == heavy: return
	start_move(heavy)

func play_select() -> void:
	play_sfx(SFX_SELECT)

func play_sfx(stream: AudioStream) -> void:
	var player := AudioStreamPlayer.new()

	player.stream = stream
	player.bus = "SFX"

	add_child(player)

	player.finished.connect(player.queue_free)
	player.play()
