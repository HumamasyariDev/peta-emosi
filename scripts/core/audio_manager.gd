extends Node

const SubtitleBarScript := preload("res://scripts/ui/subtitle_bar.gd")

const VOICE_SUBTITLES := {
	"near_star": "Wah, itu Bintang Pos 1! Tekan tombol Aksi untuk membaca Papan Rahasia Emosi.",
	"pos2_intro": "Selamat datang di Taman 6 Emosi! Dekati 6 patung emosi lalu tekan Aksi untuk mengenalnya.",
	"pos2_balloon": "Hore! Balon emas muncul! Ayo temui 6 emosi dasar di taman ini.",
	"pos2_win": "Keren sekali! Keenam emosi dasar sudah kamu kenali! Gerbang Pos 3 kini terbuka!",
	"pos3_intro": "Di Pos 3, bunyikan Lonceng Eling lalu atur keseimbangan emosi negatif di Papan Aturan!",
	"pos3_bell": "Ting! Lonceng Eling berbunyi! Yuk belajar menyeimbangkan emosi negatif.",
	"pos3_win": "Mantap! Kamu tahu emosi negatif tidak boleh dipendam maupun diledakkan. Lanjut ke Pos 4!",
	"pos4_guide1": "Langkah 1: Berhenti dulu di depan tanda STOP sebelum bertindak saat marah.",
	"pos4_guide2": "Langkah 2: Tahan tangan untuk tidak memukul! Ubah bola amarah jadi kupu-kupu.",
	"pos4_guide3": "Langkah 3: Tarik napas dalam lalu tiup kincir angin pelan-pelan biar hati sejuk.",
	"pos4_guide4": "Langkah 4: Hitung 1 sampai 10 pelan-pelan sambil melangkahi batu sungai.",
	"pos4_guide5": "Langkah 5: Cari tempat yang nyaman di gazebo dan elus kucing oranye.",
	"pos4_guide6": "Langkah 6: Menjauh sejenak dari sumber marah sampai hatimu tenang.",
	"pos4_win": "Hebat! Enam langkah menenangkan diri selesai! Gerbang Pos 5 sudah terbuka!",
	"pos5_intro": "Di Pos 5, salurkan amarah dengan aman! Dekati bantal awan lalu pukul lembut 4 kali.",
	"pos5_step2": "Lega kan? Sekarang sobek 3 lembar kertas bekas lalu masukkan ke keranjang daur ulang.",
	"pos5_step3": "Hebat! Sekarang dekati Papan Pilihan Aman dan pilih cara sehat saat marah.",
	"pos5_win": "Keren! Kamu pintar menyalurkan marah tanpa menyakiti siapa pun! Lanjut ke Pos 6!",
	"pos6_intro": "Lihat, menara Bima roboh dan ia marah! Tanyakan kebutuhannya dari jarak aman dulu ya.",
	"pos6_blocks": "Bima mau ditemani main bareng! Susun 3 balok dari Merah, Kuning, lalu Biru.",
	"pos6_step2": "Menara Bima berdiri lagi! Sekarang temui Sinta di bangku kanan dan tanyakan kebutuhannya.",
	"pos6_sinta": "Sinta butuh waktu sendiri. Ambil botol air sejuk lalu taruh perlahan di mejanya.",
	"pos6_win": "Hebat sekali! Kamu menghargai kebutuhan Bima dan Sinta. Gerbang Pos 7 terbuka!",
	"pos7_intro": "Prinsip 1: Jangan sakiti diri sendiri! Tenangkan Doni dulu, lalu pilih pintu yang aman.",
	"pos7_p1": "Prinsip 2: Jangan sakiti orang lain! Lompati kayu, lerai Raka dan Dodi, lalu pilih pintu aman.",
	"pos7_p2": "Prinsip 3: Jangan merusak barang! Lompati kayu, selamatkan vas mainan, lalu pilih pintu aman.",
	"pos7_win": "Luar biasa! Kamu menguasai 3 Prinsip Saat Marah! Lompati jembatan terakhir menuju Finish Pos 8!",
	"pos8_intro": "Hore, sampai di Garis Finish! Nyalakan 3 Lentera Kenangan dulu sebelum angkat Piala Emas!",
	"pos8_trophy_ready": "Semua lentera menyala! Naik ke podium lalu tekan Aksi untuk mengangkat Piala Emas!",
	"pos8_win": "Horeee! Piala Emas berhasil diangkat! Selamat, kamu resmi jadi Penjelajah Taman Emosi!",
	"goleman_quote": "Menurut Daniel Goleman, emosi adalah perasaan dan pikiran khas, keadaan biologis, dan kecenderungan bertindak.",
	"goleman_correct": "Hebat! Ketiga unsur emosi menurut Goleman berhasil kamu temukan!",
	"goleman_wrong": "Ups, coba periksa lagi 3 unsur emosi yang ada di Papan Rahasia ya!",
	"emo_sedih": "Ini emosi Sedih! Saat kecewa atau kehilangan, menangis itu wajar kok.",
	"emo_marah": "Ini emosi Marah! Saat kesal, kita boleh merasa marah tapi tetap harus tenang.",
	"emo_takut": "Ini emosi Takut! Rasa takut membantu kita lebih berhati-hati.",
	"emo_bahagia": "Ini emosi Bahagia! Saat senang, wajah kita berseri dan hati terasa hangat.",
	"emo_jijik": "Ini emosi Jijik! Perasaan ini melindungi kita dari hal yang kotor atau tidak aman.",
	"emo_terkejut": "Ini emosi Terkejut! Muncul tiba-tiba saat ada kejadian yang tak terduga.",
	"emo_ok": "Tepat sekali! Kamu mengenali emosi ini dengan baik!",
	"emo_wrong": "Coba lagi ya, perhatikan ekspresi dan ceritanya!",
	"pos3_rule": "Emosi negatif tidak boleh dipendam terlalu lama dan tidak boleh diledakkan.",
	"pos3_wrong": "Hati-hati, emosi negatif perlu diatur dengan seimbang ya!",
}

var _sfx_players: Array[AudioStreamPlayer] = []
var _next_sfx_idx: int = 0
const SFX_POOL_SIZE := 8

var _music_player: AudioStreamPlayer
var _voice_player: AudioStreamPlayer
var _subtitle_bar: CanvasLayer
var _last_voice_key: String = ""
var _last_speaker: String = "NARA"
var _last_subtitle: String = ""
var _last_mood: String = "happy"
var _current_bgm_track: String = ""
var _bgm_normal_db: float = -7.5
var _bgm_ducked_db: float = -16.5
var _bgm_tween: Tween

var _audio_cache: Dictionary = {}
var _voice_cache: Dictionary = {}


func _ready() -> void:
	_music_player = AudioStreamPlayer.new()
	_music_player.bus = "Master"
	_music_player.volume_db = _bgm_normal_db
	add_child(_music_player)

	_voice_player = AudioStreamPlayer.new()
	_voice_player.bus = "Master"
	_voice_player.volume_db = 1.5
	_voice_player.finished.connect(_on_voice_finished)
	add_child(_voice_player)

	for i in range(SFX_POOL_SIZE):
		var p := AudioStreamPlayer.new()
		p.bus = "Master"
		add_child(p)
		_sfx_players.append(p)

	_subtitle_bar = SubtitleBarScript.new()
	add_child(_subtitle_bar)
	_subtitle_bar.replay_requested.connect(_on_replay_voice)
	_subtitle_bar.briefing_skipped.connect(_on_skip_briefing)

	_load_sound_assets()


const STREAM_PATHS := {
	"bgm_story": "res://assets/audio/music/title_storybook_overture.ogg",
	"bgm_garden": "res://assets/audio/music/hub_lively.ogg",
	"bgm_victory": "res://assets/audio/music/victory.ogg",
	"star_get": "res://assets/audio/sfx/star_get.ogg",
	"coin_collect": "res://assets/audio/sfx/coin_collect.ogg",
	"ui_confirm": "res://assets/audio/sfx/ui_confirm.ogg",
	"ui_select": "res://assets/audio/sfx/ui_select.ogg",
	"ui_error": "res://assets/audio/sfx/ui_error.ogg",
	"step_grass_1": "res://assets/audio/sfx/footstep_grass_1.ogg",
	"step_grass_2": "res://assets/audio/sfx/footstep_grass_2.ogg",
	"amb_bird": "res://assets/audio/sfx/amb_bird.ogg",
	"thunder": "res://assets/audio/sfx/thunder_boom.wav",
	"sparkle": "res://assets/audio/sfx/sparkle_appear.ogg",
	"golden_bell": "res://assets/audio/sfx/golden_bell.wav",
}


func _load_sound_assets() -> void:
	# Only preload Title Screen music & tiny UI click SFX on boot so first-load is instant!
	# All other music tracks (bgm_garden, bgm_victory) & SFX lazy-load on first use.
	_ensure_stream("bgm_story")
	_ensure_stream("ui_select")
	_ensure_stream("ui_confirm")


func _ensure_stream(key: String) -> bool:
	if _audio_cache.has(key):
		return true
	if STREAM_PATHS.has(key):
		var path: String = str(STREAM_PATHS[key])
		if ResourceLoader.exists(path):
			var stream := load(path)
			if stream:
				_audio_cache[key] = stream
				return true
	return false


func _register_voice(key: String, path: String) -> void:
	if FileAccess.file_exists(path):
		var bytes := FileAccess.get_file_as_bytes(path)
		if bytes.size() > 0:
			var mp3 := AudioStreamMP3.new()
			mp3.data = bytes
			_voice_cache[key] = mp3
			return
	if ResourceLoader.exists(path):
		var stream := load(path)
		if stream:
			_voice_cache[key] = stream


func play_music(track_key: String, loop: bool = true) -> void:
	if not Game.music_enabled:
		return
	if _current_bgm_track == track_key and _music_player.playing:
		return
	if _ensure_stream(track_key):
		var stream: AudioStream = _audio_cache[track_key]
		if stream is AudioStreamOggVorbis:
			(stream as AudioStreamOggVorbis).loop = loop
		_music_player.stream = stream
		_current_bgm_track = track_key
		var target_db := _bgm_ducked_db if _voice_player.playing else _bgm_normal_db
		_music_player.volume_db = -14.0
		_music_player.play()
		_tween_bgm_volume(target_db, 0.18)


func stop_music() -> void:
	_music_player.stop()
	_current_bgm_track = ""


func show_subtitle(speaker: String, text: String, expr: String = "happy", dur: float = 5.5, lock_briefing: bool = false) -> void:
	_last_speaker = speaker
	_last_subtitle = text
	_last_mood = expr
	if lock_briefing:
		Game.voice_briefing_active = true
	if _subtitle_bar != null:
		_subtitle_bar.call("show_subtitle", speaker, text, expr, lock_briefing, dur, not _last_voice_key.is_empty())


func is_voice_playing() -> bool:
	return _voice_player != null and _voice_player.playing


func get_voice_progress() -> float:
	if _voice_player == null or not _voice_player.playing or _voice_player.stream == null:
		return 1.0
	var total := _voice_player.stream.get_length()
	if total <= 0.05:
		return 1.0
	return clampf(_voice_player.get_playback_position() / total, 0.0, 1.0)


func play_voice(voice_key: String, lock_briefing: bool = false, custom_speaker: String = "", custom_subtitle: String = "", expr: String = "happy") -> void:
	_last_voice_key = voice_key
	var sub_txt := custom_subtitle if not custom_subtitle.is_empty() else str(VOICE_SUBTITLES.get(voice_key, ""))
	var spk := custom_speaker if not custom_speaker.is_empty() else _last_speaker
	if spk.is_empty():
		spk = "NARA"

	if not _voice_cache.has(voice_key):
		_register_voice(voice_key, "res://assets/audio/voice/%s.mp3" % voice_key)

	var can_play := Game.sound_enabled and _voice_cache.has(voice_key)
	if can_play:
		_voice_player.stop()
		_voice_player.stream = _voice_cache[voice_key]
		_voice_player.play()
		if _music_player.playing:
			_tween_bgm_volume(_bgm_ducked_db, 0.20)

	# Auto-show synced subtitle whenever a voice plays outside full-screen modals!
	if not sub_txt.is_empty() and not Game.modal_open and _subtitle_bar != null:
		_last_speaker = spk
		_last_subtitle = sub_txt
		_last_mood = expr
		var should_lock := lock_briefing and can_play
		if should_lock:
			Game.voice_briefing_active = true
		var est_dur := 4.5
		if _voice_cache.has(voice_key) and _voice_cache[voice_key] is AudioStream:
			est_dur = maxf(2.5, (_voice_cache[voice_key] as AudioStream).get_length() + 1.0)
		_subtitle_bar.call("show_subtitle", spk, sub_txt, expr, should_lock, est_dur, true)


func stop_voice() -> void:
	Game.voice_briefing_active = false
	if _voice_player.playing:
		_voice_player.stop()
	if _subtitle_bar != null:
		_subtitle_bar.call("hide_subtitle")
	_on_voice_finished()


func _on_replay_voice() -> void:
	if not _last_voice_key.is_empty():
		play_voice(_last_voice_key, false, _last_speaker, _last_subtitle, _last_mood)


func _on_skip_briefing() -> void:
	Game.voice_briefing_active = false
	if _voice_player.playing:
		_voice_player.stop()
	if _subtitle_bar != null:
		_subtitle_bar.call("mark_voice_finished")
	if _music_player.playing:
		_tween_bgm_volume(_bgm_normal_db, 0.30)


func _on_voice_finished() -> void:
	Game.voice_briefing_active = false
	if _subtitle_bar != null:
		_subtitle_bar.call("mark_voice_finished")
	if _music_player.playing:
		_tween_bgm_volume(_bgm_normal_db, 0.40)


func _tween_bgm_volume(target_db: float, dur: float) -> void:
	if _bgm_tween != null and _bgm_tween.is_running():
		_bgm_tween.kill()
	_bgm_tween = create_tween()
	_bgm_tween.tween_property(_music_player, "volume_db", target_db, dur)


func play_sfx(kind: String) -> void:
	if not Game.sound_enabled:
		return

	match kind:
		"pop", "select":
			_play_from_cache_or_tone("ui_select", 587.33, 0.08, 0.16, -3.0)
		"confirm":
			_play_from_cache_or_tone("ui_confirm", 659.25, 0.15, 0.20, -2.0)
		"step":
			var step_key := "step_grass_1" if randi() % 2 == 0 else "step_grass_2"
			_play_from_cache_or_tone(step_key, 190.0, 0.045, 0.04, -14.0)
		"coin":
			_play_from_cache_or_tone("coin_collect", 784.0, 0.12, 0.18, -3.0)
		"wrong", "error":
			_play_from_cache_or_tone("ui_error", 185.0, 0.18, 0.18, -2.0)
		"success":
			_play_from_cache_or_chord("ui_confirm", [523.25, 659.25, 783.99], 0.22, 0.16)
		"complete", "star":
			_play_from_cache_or_chord("star_get", [523.25, 659.25, 783.99, 1046.5], 0.35, 0.22)
		"thunder":
			if _ensure_stream("thunder"):
				_play_stream(_audio_cache["thunder"], 3.5)
				if _music_player.playing:
					_tween_bgm_volume(-20.0, 0.08)
					get_tree().create_timer(1.8).timeout.connect(func() -> void:
						if _music_player != null and _music_player.playing:
							_tween_bgm_volume(_bgm_ducked_db if _voice_player.playing else _bgm_normal_db, 0.5)
					)
		"sparkle":
			if _ensure_stream("sparkle"):
				_play_stream(_audio_cache["sparkle"], -5.0)
		"blip":
			if _ensure_stream("blip"):
				_play_stream(_audio_cache["blip"], -10.0)
		"bird":
			if _ensure_stream("amb_bird"):
				_play_stream(_audio_cache["amb_bird"], -10.0)
		"bell":
			_play_from_cache_or_chord("golden_bell", [523.25, 1046.5, 1318.51, 1567.98], 1.4, 0.25)
		"splash":
			_play_splash_sfx()
		"meow":
			_play_meow_sfx()
		"thump":
			_play_pillow_thump_sfx()
		"rip":
			_play_paper_rip_sfx()
		_:
			_play_tone(440.0, 0.08, 0.1)


func _play_pillow_thump_sfx() -> void:
	# Soft puffy cartoon pillow "POOF / BUK!" thump
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = 22050
	stream.stereo = false
	var dur := 0.22
	var n := int(22050.0 * dur)
	var data := PackedByteArray()
	data.resize(n * 2)
	var phase := 0.0
	var lp := 0.0
	for i in range(n):
		var t := float(i) / 22050.0
		var freq := 145.0 * exp(-t * 10.0) + 52.0
		phase += TAU * freq / 22050.0
		lp = lp * 0.78 + randf_range(-1.0, 1.0) * 0.22
		var env := clampf(t / 0.008, 0.0, 1.0) * exp(-t * 14.0)
		var s := clampf((sin(phase) * 0.75 + lp * 0.45) * env * 0.72, -1.0, 1.0)
		var v := int(s * 32767.0)
		data[i * 2] = v & 0xFF
		data[i * 2 + 1] = (v >> 8) & 0xFF
	stream.data = data
	_play_stream(stream, -1.5)


func _play_paper_rip_sfx() -> void:
	# Crisp paper tearing "KREK-SREEK!" filtered noise burst
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = 22050
	stream.stereo = false
	var dur := 0.30
	var n := int(22050.0 * dur)
	var data := PackedByteArray()
	data.resize(n * 2)
	var prev := 0.0
	for i in range(n):
		var t := float(i) / 22050.0
		var w := randf_range(-1.0, 1.0)
		# High-pass crunch for realistic paper tear
		var hp := w - prev * 0.82
		prev = w
		var flutter := 0.55 + 0.45 * sin(t * 95.0)
		var env := clampf(t / 0.015, 0.0, 1.0) * clampf((dur - t) / 0.06, 0.0, 1.0)
		var s := clampf(hp * flutter * env * 0.48, -1.0, 1.0)
		var v := int(s * 32767.0)
		data[i * 2] = v & 0xFF
		data[i * 2 + 1] = (v >> 8) & 0xFF
	stream.data = data
	_play_stream(stream, -2.5)


func _play_meow_sfx() -> void:
	# Cute soft rising-then-falling cartoon cat "Meow~" chime
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = 22050
	stream.stereo = false
	var dur := 0.42
	var n := int(22050.0 * dur)
	var data := PackedByteArray()
	data.resize(n * 2)
	var phase := 0.0
	for i in range(n):
		var t := float(i) / 22050.0
		var p := t / dur
		var freq := 560.0 + sin(p * PI) * 290.0 - p * 120.0
		phase += TAU * freq / 22050.0
		var env := clampf(t / 0.04, 0.0, 1.0) * clampf((dur - t) / 0.10, 0.0, 1.0)
		var s := (sin(phase) * 0.65 + sin(phase * 2.0) * 0.25 + sin(phase * 3.0) * 0.10) * env * 0.28
		var v := int(clampf(s, -1.0, 1.0) * 32767.0)
		data[i * 2] = v & 0xFF
		data[i * 2 + 1] = (v >> 8) & 0xFF
	stream.data = data
	_play_stream(stream, -2.0)


func _play_splash_sfx() -> void:
	# Synthesize a crisp bubbly "BYURR!" water splash sound (filtered noise burst + rising water bloop)
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = 22050
	stream.stereo = false
	var dur := 0.55
	var n := int(22050.0 * dur)
	var data := PackedByteArray()
	data.resize(n * 2)
	var prev := 0.0
	for i in range(n):
		var t := float(i) / 22050.0
		var env := clampf(t / 0.015, 0.0, 1.0) * pow(1.0 - float(i) / float(n), 1.8)
		var white := randf_range(-1.0, 1.0)
		prev = prev * 0.65 + white * 0.35
		# Bubbly water bloop overtone
		var bloop_freq := 240.0 + t * 520.0
		var bloop := sin(TAU * bloop_freq * t) * 0.35 * exp(-t * 6.5)
		var s := clampf((prev * 0.72 + bloop) * env * 0.55, -1.0, 1.0)
		var v := int(s * 32767.0)
		data[i * 2] = v & 0xFF
		data[i * 2 + 1] = (v >> 8) & 0xFF
	stream.data = data
	_play_stream(stream, -1.0)


func play_note(step_1_to_10: int) -> void:
	if not Game.sound_enabled:
		return
	# Ascending major xylophone scale C5..E6 for Pos 4 counting stones 1..10
	var freqs := [523.25, 587.33, 659.25, 698.46, 783.99, 880.00, 987.77, 1046.50, 1174.66, 1318.51]
	var idx := clampi(step_1_to_10 - 1, 0, freqs.size() - 1)
	_play_tone(freqs[idx], 0.28, 0.24)


func _play_from_cache_or_tone(cache_key: String, fallback_freq: float, dur: float, amp: float, vol_db: float = 0.0) -> void:
	if _ensure_stream(cache_key):
		_play_stream(_audio_cache[cache_key], vol_db)
	else:
		_play_tone(fallback_freq, dur, amp)


func _play_from_cache_or_chord(cache_key: String, freqs: Array, dur: float, amp: float) -> void:
	if _ensure_stream(cache_key):
		_play_stream(_audio_cache[cache_key])
	else:
		_play_chord(freqs, dur, amp)


func _play_stream(stream: AudioStream, vol_db: float = 0.0) -> void:
	var p := _sfx_players[_next_sfx_idx]
	_next_sfx_idx = (_next_sfx_idx + 1) % SFX_POOL_SIZE
	p.stream = stream
	p.volume_db = vol_db
	p.play()


func _play_chord(freqs: Array, duration: float, amp: float) -> void:
	for f_raw in freqs:
		_play_tone(float(f_raw), duration, amp / maxf(1.0, float(freqs.size()) * 0.65))


func _play_tone(freq: float, duration: float, amp: float) -> void:
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = 22050
	stream.stereo = false

	var sample_count := int(22050.0 * duration)
	var data := PackedByteArray()
	data.resize(sample_count * 2)

	for i in range(sample_count):
		var t := float(i) / 22050.0
		var env := clampf(t / 0.012, 0.0, 1.0) * pow(1.0 - float(i) / float(sample_count), 1.6)
		var s := (sin(TAU * freq * t) * 0.72 + sin(TAU * freq * 2.0 * t) * 0.18) * env * amp
		var v := int(clampf(s, -1.0, 1.0) * 32767.0)
		data[i * 2] = v & 0xFF
		data[i * 2 + 1] = (v >> 8) & 0xFF

	stream.data = data
	_play_stream(stream)
