extends Node

# SoundManager: High-fidelity procedural audio engine for Echo of Dread.
# Features multi-bus audio routing (Master, Music, SFX, Echoes, Ambience),
# dynamic urgency LowPassFilter muffling and pitch modulation when loop timer < 5s,
# pitch jitter (+-5%) to prevent ear fatigue, continuous subterranean harmonic drone, and 2D spatial stereo panning.

var _audio_players: Array[AudioStreamPlayer] = []
var _spatial_players: Array[AudioStreamPlayer2D] = []
const MAX_PLAYERS = 10
const MAX_SPATIAL_PLAYERS = 6

var _sounds: Dictionary = {}
var _lpf_effect: AudioEffectLowPassFilter = null
var _lpf_bus_idx: int = -1
var _lpf_effect_idx: int = -1
var _urgency_factor: float = 0.0 # 0.0 = normal, 1.0 = maximum urgency (< 5s)

var _ambient_drone_player: AudioStreamPlayer = null
var _drone_stream: AudioStreamWAV = null

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Non-spatial players
	for i in range(MAX_PLAYERS):
		var player := AudioStreamPlayer.new()
		player.bus = &"SFX" if _bus_exists("SFX") else &"Master"
		add_child(player)
		_audio_players.append(player)
		
	# Spatial 2D players for positional actions
	for i in range(MAX_SPATIAL_PLAYERS):
		var player_2d := AudioStreamPlayer2D.new()
		player_2d.bus = &"SFX" if _bus_exists("SFX") else &"Master"
		player_2d.max_distance = 2000.0
		add_child(player_2d)
		_spatial_players.append(player_2d)
		
	# Dedicated ambient drone player routed through Ambience bus
	_ambient_drone_player = AudioStreamPlayer.new()
	_ambient_drone_player.name = "AmbientDronePlayer"
	_ambient_drone_player.bus = &"Ambience" if _bus_exists("Ambience") else &"Master"
	add_child(_ambient_drone_player)
		
	_setup_urgency_filter()
	_build_sound_library()
	
	if SaveManager and not SaveManager.settings_changed.is_connected(apply_settings):
		SaveManager.settings_changed.connect(apply_settings)
	apply_settings()

func apply_settings() -> void:
	if not SaveManager:
		return
	var master_vol: float = float(SaveManager.get_setting("master_volume", 1.0))
	var sfx_vol: float = float(SaveManager.get_setting("sfx_volume", 1.0))
	var music_vol: float = float(SaveManager.get_setting("music_volume", 1.0))
	
	_set_bus_vol("Master", master_vol)
	_set_bus_vol("SFX", sfx_vol)
	_set_bus_vol("Echoes", sfx_vol)
	_set_bus_vol("Music", music_vol)
	_set_bus_vol("Ambience", music_vol)

func _set_bus_vol(bus_name: String, linear_vol: float) -> void:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx != -1:
		var db := linear_to_db(clampf(linear_vol, 0.0001, 1.0))
		if linear_vol <= 0.0001:
			db = -80.0
		AudioServer.set_bus_volume_db(idx, db)

func _bus_exists(bus_name: String) -> bool:
	return AudioServer.get_bus_index(bus_name) != -1

func _setup_urgency_filter() -> void:
	var target_bus := "SFX"
	if not _bus_exists(target_bus):
		target_bus = "Master"
		
	_lpf_bus_idx = AudioServer.get_bus_index(target_bus)
	if _lpf_bus_idx != -1:
		# Search if LowPassFilter already exists in bus layout
		for effect_idx in range(AudioServer.get_bus_effect_count(_lpf_bus_idx)):
			var eff := AudioServer.get_bus_effect(_lpf_bus_idx, effect_idx)
			if eff is AudioEffectLowPassFilter:
				_lpf_effect = eff
				_lpf_effect_idx = effect_idx
				break
				
		# If not found, add one dynamically
		if _lpf_effect == null:
			_lpf_effect = AudioEffectLowPassFilter.new()
			_lpf_effect.cutoff_hz = 20000.0
			AudioServer.add_bus_effect(_lpf_bus_idx, _lpf_effect)
			_lpf_effect_idx = AudioServer.get_bus_effect_count(_lpf_bus_idx) - 1

func set_urgency(time_remaining: float, _max_duration: float = 30.0) -> void:
	if time_remaining <= 5.0 and time_remaining >= 0.0:
		# Normalize urgency from 0.0 (at 5s) to 1.0 (at 0s)
		_urgency_factor = clampf((5.0 - time_remaining) / 5.0, 0.0, 1.0)
		# Muffle SFX frequencies dynamically from 20kHz down to 900Hz
		var cutoff := lerpf(20000.0, 900.0, _urgency_factor)
		if _lpf_effect:
			_lpf_effect.cutoff_hz = cutoff
	else:
		reset_urgency()

func reset_urgency() -> void:
	_urgency_factor = 0.0
	if _lpf_effect:
		_lpf_effect.cutoff_hz = 20000.0

func _get_available_player() -> AudioStreamPlayer:
	for player in _audio_players:
		if not player.playing:
			return player
	return _audio_players[0]

func _get_available_spatial_player() -> AudioStreamPlayer2D:
	for p in _spatial_players:
		if not p.playing:
			return p
	return _spatial_players[0]

func stop_all() -> void:
	for player in _audio_players:
		player.stop()
		player.stream = null
	for p2 in _spatial_players:
		p2.stop()
		p2.stream = null
	stop_ambient_drone()
	reset_urgency()

func play_ambient_drone(volume_db: float = -6.0) -> void:
	if _ambient_drone_player == null:
		_ambient_drone_player = AudioStreamPlayer.new()
		_ambient_drone_player.name = "AmbientDronePlayer"
		_ambient_drone_player.bus = &"Ambience" if _bus_exists("Ambience") else &"Master"
		add_child(_ambient_drone_player)
		
	if _drone_stream == null:
		_drone_stream = _generate_ambient_drone()
		
	_ambient_drone_player.stream = _drone_stream
	_ambient_drone_player.volume_db = volume_db
	if not _ambient_drone_player.playing:
		_ambient_drone_player.play()

func stop_ambient_drone() -> void:
	if _ambient_drone_player and _ambient_drone_player.playing:
		_ambient_drone_player.stop()

func is_ambient_drone_playing() -> bool:
	return _ambient_drone_player != null and _ambient_drone_player.playing

func get_ambient_drone_player() -> AudioStreamPlayer:
	return _ambient_drone_player

func _generate_ambient_drone() -> AudioStreamWAV:
	var sample_rate := 22050
	var duration := 4.0
	var total_samples := int(sample_rate * duration)
	var byte_array := PackedByteArray()
	byte_array.resize(total_samples)
	
	for i in range(total_samples):
		var t := float(i) / float(sample_rate)
		# Subterranean harmonic stack - all frequencies complete integer cycles over 4.0s (no loop pop)
		var s1 := sin(40.0 * TAU * t) * 0.35
		var s2 := sin(80.0 * TAU * t) * 0.30
		var s3 := sin(80.5 * TAU * t) * 0.15 # 0.5 Hz gentle binaural-style beating
		var s4 := sin(160.0 * TAU * t) * 0.10
		var s5 := sin(240.0 * TAU * t) * 0.05
		var combined := s1 + s2 + s3 + s4 + s5
		combined = clampf(combined, -1.0, 1.0)
		var sample_byte := clampi(int((combined + 1.0) * 127.5), 0, 255)
		byte_array[i] = sample_byte
		
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_8_BITS
	wav.mix_rate = sample_rate
	wav.stereo = false
	wav.data = byte_array
	wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
	wav.loop_begin = 0
	wav.loop_end = total_samples
	return wav

func cleanup() -> void:
	stop_all()
	_sounds.clear()

func play_sfx(sound_name: String, pitch_scale: float = 1.0, volume_db: float = 0.0, bus_name: String = "SFX", pitch_variance: float = 0.05) -> void:
	if not _sounds.has(sound_name):
		return
	var stream: AudioStreamWAV = _sounds[sound_name]
	var player := _get_available_player()
	player.stream = stream
	
	# Apply pitch jitter (+-5% by default) to avoid ear fatigue
	var jitter := 1.0
	if pitch_variance > 0.0:
		jitter += randf_range(-pitch_variance, pitch_variance)
		
	# Apply urgency pitch modulation if near loop deadline
	var urgency_pitch_offset := _urgency_factor * 0.12
	player.pitch_scale = maxf(0.1, (pitch_scale + urgency_pitch_offset) * jitter)
	player.volume_db = volume_db
	
	if _bus_exists(bus_name):
		player.bus = StringName(bus_name)
	else:
		player.bus = &"SFX" if _bus_exists("SFX") else &"Master"
	player.play()

func play_sfx_at_position(sound_name: String, world_pos: Vector2, pitch_scale: float = 1.0, volume_db: float = 0.0, bus_name: String = "SFX", pitch_variance: float = 0.05) -> void:
	if not _sounds.has(sound_name):
		return
	var stream: AudioStreamWAV = _sounds[sound_name]
	var player_2d := _get_available_spatial_player()
	player_2d.stream = stream
	player_2d.global_position = world_pos
	
	var jitter := 1.0
	if pitch_variance > 0.0:
		jitter += randf_range(-pitch_variance, pitch_variance)
		
	var urgency_pitch_offset := _urgency_factor * 0.12
	player_2d.pitch_scale = maxf(0.1, (pitch_scale + urgency_pitch_offset) * jitter)
	player_2d.volume_db = volume_db
	
	if _bus_exists(bus_name):
		player_2d.bus = StringName(bus_name)
	else:
		player_2d.bus = &"SFX" if _bus_exists("SFX") else &"Master"
	player_2d.play()

func _build_sound_library() -> void:
	_sounds["click"] = _generate_tone(880.0, 0.06, "square", 0.3)
	_sounds["switch_on"] = _generate_tone(660.0, 0.09, "sine", 0.4, 880.0)
	_sounds["switch_off"] = _generate_tone(880.0, 0.09, "sine", 0.4, 440.0)
	_sounds["plate_press"] = _generate_tone(150.0, 0.14, "triangle", 0.5, 90.0)
	_sounds["plate_release"] = _generate_tone(110.0, 0.10, "triangle", 0.3, 160.0)
	_sounds["door_open"] = _generate_sweep(200.0, 600.0, 0.4, "sine", 0.4)
	_sounds["door_close"] = _generate_sweep(500.0, 180.0, 0.35, "sine", 0.4)
	_sounds["loop_rewind"] = _generate_sweep(120.0, 1200.0, 0.65, "saw", 0.5)
	_sounds["level_win"] = _generate_melody([523.25, 659.25, 783.99, 1046.5], 0.12, 0.4)
	_sounds["terminal_beep"] = _generate_tone(1200.0, 0.05, "sine", 0.25)
	_sounds["tick"] = _generate_tone(1000.0, 0.03, "sine", 0.2)
	_sounds["alarm"] = _generate_tone(750.0, 0.18, "saw", 0.35, 600.0)

func _generate_tone(start_freq: float, duration: float, wave_type: String, amplitude: float = 0.5, end_freq: float = -1.0) -> AudioStreamWAV:
	var sample_rate := 22050
	var total_samples := int(sample_rate * duration)
	var byte_array := PackedByteArray()
	byte_array.resize(total_samples)
	
	if end_freq < 0:
		end_freq = start_freq
		
	var phase := 0.0
	for i in range(total_samples):
		var progress := float(i) / float(total_samples)
		var freq := lerpf(start_freq, end_freq, progress)
		phase += (freq * TAU) / float(sample_rate)
		if phase > TAU:
			phase -= TAU
			
		var val := 0.0
		match wave_type:
			"sine":
				val = sin(phase)
			"square":
				val = 1.0 if sin(phase) >= 0 else -1.0
			"saw":
				val = (phase / PI) - 1.0
			"triangle":
				val = 2.0 * absf((phase / PI) - 1.0) - 1.0
				
		var envelope := 1.0 - progress
		val *= envelope * amplitude
		var sample_byte := clampi(int((val + 1.0) * 127.5), 0, 255)
		byte_array[i] = sample_byte
		
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_8_BITS
	wav.mix_rate = sample_rate
	wav.stereo = false
	wav.data = byte_array
	return wav

func _generate_sweep(start_f: float, end_f: float, dur: float, wave: String, amp: float) -> AudioStreamWAV:
	return _generate_tone(start_f, dur, wave, amp, end_f)

func _generate_melody(notes: Array, note_duration: float, amplitude: float) -> AudioStreamWAV:
	var sample_rate := 22050
	var samples_per_note := int(sample_rate * note_duration)
	var total_samples := samples_per_note * notes.size()
	var byte_array := PackedByteArray()
	byte_array.resize(total_samples)
	
	var cursor := 0
	for note in notes:
		var freq: float = float(note)
		var phase := 0.0
		for i in range(samples_per_note):
			var progress := float(i) / float(samples_per_note)
			phase += (freq * TAU) / float(sample_rate)
			if phase > TAU:
				phase -= TAU
			var val := sin(phase) * (1.0 - progress * 0.7) * amplitude
			var sample_byte := clampi(int((val + 1.0) * 127.5), 0, 255)
			byte_array[cursor] = sample_byte
			cursor += 1
			
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_8_BITS
	wav.mix_rate = sample_rate
	wav.stereo = false
	wav.data = byte_array
	return wav
