extends Node

const MENU_TRACK := "res://Audio/Music/a_welcome_haunting.ogg"
const GRAVEYARD_TRACK := "res://Audio/Music/haunted_hollow.ogg"
const CHASE_TRACK := "res://Audio/Music/pumpkin_patch_chase.ogg"
const MUSIC_BUS := &"Music"
const FULL_GAIN := 1.0

var _players: Dictionary = {}
var _fade: Tween
var _target: AudioStreamPlayer


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func play_menu(fade_seconds: float = 1.0) -> void:
	_play_track(MENU_TRACK, fade_seconds)


func play_graveyard(fade_seconds: float = 1.5) -> void:
	_play_track(GRAVEYARD_TRACK, fade_seconds)


func play_chase(fade_seconds: float = 0.5) -> void:
	_play_track(CHASE_TRACK, fade_seconds)


func stop_music(fade_seconds: float = 1.0) -> void:
	_crossfade(null, fade_seconds)


func _play_track(path: String, fade_seconds: float) -> void:
	var player: AudioStreamPlayer = _players.get(path)
	if player == null:
		var stream := load(path) as AudioStreamOggVorbis
		if stream == null:
			push_warning("MusicManager: Could not load OGG track at %s" % path)
			return

		stream = stream.duplicate() as AudioStreamOggVorbis
		stream.loop = true
		player = AudioStreamPlayer.new()
		player.stream = stream
		player.bus = MUSIC_BUS
		add_child(player)
		_players[path] = player

	if player == _target and player.playing:
		return

	if not player.playing:
		player.volume_linear = 0.0
		player.play()

	_crossfade(player, fade_seconds)


func _crossfade(target: AudioStreamPlayer, fade_seconds: float) -> void:
	if _fade != null:
		_fade.kill()
		_fade = null

	_target = target
	if fade_seconds <= 0.0:
		if target != null:
			target.volume_linear = FULL_GAIN
		_stop_inactive_players()
		return

	_fade = create_tween().set_parallel(true)
	_fade.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	for player: AudioStreamPlayer in _players.values():
		if player.playing:
			var gain := FULL_GAIN if player == target else 0.0
			_fade.tween_property(player, "volume_linear", gain, fade_seconds)

	# Keep the tween valid even if stop_music() is called before any track plays.
	_fade.tween_interval(fade_seconds)
	_fade.chain().tween_callback(_stop_inactive_players)


func _stop_inactive_players() -> void:
	for player: AudioStreamPlayer in _players.values():
		if player != _target:
			player.stop()
