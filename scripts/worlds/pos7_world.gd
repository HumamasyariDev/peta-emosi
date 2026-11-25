extends Node3D

## Pos 7 (Opsi 3): 3D Island Rescues + Principle Doors + Jumpable Bridge Waves!

const CommsBannerScript := preload("res://scripts/ui/comms_banner.gd")

@onready var _player: NaraController = $NaraPlayer
@onready var _camera: FollowCamera = $FollowCamera
@onready var _props: Pos7Props = $Pos7Props
@onready var _hud: GameHUD = $HUD

var _comms: CanvasLayer
var _stage: int = 0 # 0=Prinsip 1, 1=Prinsip 2, 2=Prinsip 3, 3=Done
var _in_action_zone: int = -1
var _wrong_cd: float = 0.0
var _wave_cd: float = 0.0
var _transitioning: bool = false


func _ready() -> void:
	Game.current_zone = "Pos 7"
	_camera.set_target(_player)

	_comms = CommsBannerScript.new()
	add_child(_comms)

	_props.action_zone_changed.connect(_on_action_zone_changed)
	_props.gate_entered.connect(_on_gate_entered)
	_props.jump_wave_hit.connect(_on_jump_wave_hit)
	_props.next_route_entered.connect(_on_next_route_entered)

	_hud.set_story_button_visible(false)
	_hud.walk_to_pos1_pressed.connect(_on_walk_pressed)
	_hud.open_pos1_pressed.connect(_trigger_action)

	Audio.play_music("bgm_garden", true)

	if Game.is_station_done(7):
		_stage = 3
		_props.solve_all_instant()
		_props.unlock_exit_gate()
		_refresh_mission()
	else:
		_stage = 0
		_refresh_mission()
		_guide(
			"NARA • PRINSIP 1: JANGAN SAKITI DIRI SENDIRI",
			"Lihat, Doni di depan memukul kepalanya karena kesal! Dekati Doni lalu tekan E atau tombol Aksi untuk menenangkannya, baru pilih pintu yang aman!",
			"pos7_intro",
			"thinking",
			9.2
		)


func _guide(speaker: String, text: String, voice_key: String, mood: String, dur: float) -> void:
	if not voice_key.is_empty():
		Audio.play_voice(voice_key, voice_key.ends_with("_intro"), speaker, text, mood)
	else:
		Audio.show_subtitle(speaker, text, mood, dur, false)


func _physics_process(delta: float) -> void:
	if _wrong_cd > 0.0:
		_wrong_cd -= delta
	if _wave_cd > 0.0:
		_wave_cd -= delta
	_props.update_guide_arrow(_player.global_position, _props.get_stage_target(_stage))


func _on_walk_pressed() -> void:
	_player.walk_to(_props.get_stage_target(_stage))


func _on_action_zone_changed(stage_idx: int, entered: bool) -> void:
	if entered:
		_in_action_zone = stage_idx
	elif _in_action_zone == stage_idx:
		_in_action_zone = -1
	_refresh_prompt()


func _refresh_prompt() -> void:
	if _in_action_zone == _stage and not _props.is_action_done(_stage):
		match _stage:
			0:
				_hud.set_interact_prompt("Tenangkan Doni (Prinsip 1)", true)
			1:
				_hud.set_interact_prompt("Lerai Raka & Dodi (Prinsip 2)", true)
			2:
				_hud.set_interact_prompt("Selamatkan Mainan & Vas (Prinsip 3)", true)
			_:
				_hud.set_interact_prompt("", false)
	else:
		_hud.set_interact_prompt("", false)


func _trigger_action() -> void:
	if Game.modal_open or _in_action_zone != _stage or _props.is_action_done(_stage):
		return
	_props.complete_island_action(_stage)
	Audio.play_sfx("sparkle")
	Game.add_coins(5)
	Audio.play_sfx("coin")
	match _stage:
		0:
			_player.play_emote("hold_back", 0.9)
			_props.show_bubble(_player.global_position, "Jangan sakiti dirimu ya Doni, tarik napas pelan! ♥", 2.2)
		1:
			_player.play_emote("stop", 0.9)
			_props.show_bubble(_player.global_position, "STOP! Jangan saling dorong, yuk bicara baik-baik! ♥", 2.2)
		2:
			_player.play_emote("celebrate", 0.9)
			_props.show_bubble(_player.global_position, "Vas & mainan aman rapi! Jangan merusak barang ya ♥", 2.2)
	_refresh_prompt()
	_refresh_mission()


func _on_jump_wave_hit(_bridge_idx: int, wave_z: float) -> void:
	if _wave_cd > 0.0:
		return
	_wave_cd = 0.95
	# Real cartoony "TERPENTAL!" parabolic knockback strictly along the bridge + star sparks + punchy SFX!
	var dir_z := 1.0 if _player.global_position.z >= wave_z else -1.0
	_player.apply_knockback(Vector3(0.0, 5.2, dir_z * 7.2), 0.64)
	_props.spawn_hit_impact(_player.global_position)
	Audio.play_sfx("thump")
	Audio.play_sfx("wrong")
	_props.show_bubble(_player.global_position, "BOING! TERPENTAL! Lompat pakai Spasi ya!", 2.0)


func _on_gate_entered(stage_idx: int, is_correct: bool, gate_pos: Vector3) -> void:
	if stage_idx != _stage:
		return
	# Must complete the 3D rescue action on this island before opening the door!
	if not _props.is_action_done(stage_idx):
		if _wrong_cd <= 0.0:
			_wrong_cd = 1.0
			_player.cancel_auto_walk()
			_player.global_position.z = gate_pos.z + 1.65
			Audio.play_sfx("wrong")
			_props.trigger_wrong_gate_fx(gate_pos)
			var msg := "Tenangkan Doni dulu!" if stage_idx == 0 else ("Lerai Raka & Dodi dulu!" if stage_idx == 1 else "Selamatkan vas & mainan dulu!")
			_props.show_bubble(_player.global_position, msg, 2.0)
		return

	if is_correct:
		_props.solve_stage(stage_idx)
		Audio.play_sfx("sparkle")
		Game.add_coins(5)
		Audio.play_sfx("coin")
		_player.play_emote("celebrate", 0.85)
		_props.show_bubble(_player.global_position, _props.get_principle_title(stage_idx) + " ✓", 2.4)
		_stage += 1
		_refresh_prompt()
		_refresh_mission()
		if _stage == 1:
			_guide(
				"NARA • PRINSIP 2: JANGAN SAKITI ORANG LAIN",
				"Bagus! Lompati rintangan merah di jembatan! Di pulau 2, lerai Raka & Dodi yang bertengkar lalu pilih pintu yang melindungi teman!",
				"pos7_p1",
				"happy",
				9.0
			)
		elif _stage == 2:
			_guide(
				"NARA • PRINSIP 3: JANGAN MERUSAK BARANG",
				"Hebat! Lompati rintangan ke pulau 3! Selamatkan vas bunga & mainan yang bergoyang di meja lalu pilih pintu menjaga barang!",
				"pos7_p2",
				"happy",
				9.0
			)
		else:
			_props.unlock_exit_gate()
			Game.complete_station(7, 15, 1)
			Audio.play_sfx("star")
			_guide(
				"NARA • POS 7 SELESAI!",
				"Luar biasa! Kamu menguasai 3 Prinsip Saat Marah lewat aksi nyata! Lompati jembatan terakhir menuju Pesta Finish Pos 8!",
				"pos7_win",
				"excited",
				9.0
			)
	else:
		if _wrong_cd > 0.0:
			return
		_wrong_cd = 1.0
		_player.cancel_auto_walk()
		_player.global_position.z = gate_pos.z + 1.65
		var hop_y := 2.0 if _player.is_on_floor() else 0.0
		_player.velocity = Vector3(0.0, hop_y, 4.6)
		_player.play_emote("surprised", 0.55)
		Audio.play_sfx("wrong")
		_props.trigger_wrong_gate_fx(gate_pos)
		_props.show_bubble(_player.global_position, _props.get_wrong_hint(stage_idx), 2.3)


func _refresh_mission() -> void:
	match _stage:
		0:
			if not _props.is_action_done(0):
				_hud.set_mission_text("Pos 7 (1/3): Tenangkan Doni di Pulau 1 [E / Aksi]")
				_hud.set_walk_caption("Jalan ke Doni")
			else:
				_hud.set_mission_text("Pos 7 (1/3): Lewati Pintu Prinsip 1 (Jaga Diri Sendiri)")
				_hud.set_walk_caption("Jalan ke Pintu Prinsip 1")
		1:
			if not _props.is_action_done(1):
				_hud.set_mission_text("Pos 7 (2/3): Lompati Jembatan & Lerai Raka-Dodi [E / Aksi]")
				_hud.set_walk_caption("Jalan ke Raka & Dodi")
			else:
				_hud.set_mission_text("Pos 7 (2/3): Lewati Pintu Prinsip 2 (Jaga Orang Lain)")
				_hud.set_walk_caption("Jalan ke Pintu Prinsip 2")
		2:
			if not _props.is_action_done(2):
				_hud.set_mission_text("Pos 7 (3/3): Lompati Jembatan & Selamatkan Vas Mainan [E / Aksi]")
				_hud.set_walk_caption("Jalan ke Meja Mainan")
			else:
				_hud.set_mission_text("Pos 7 (3/3): Lewati Pintu Prinsip 3 (Jaga Barang)")
				_hud.set_walk_caption("Jalan ke Pintu Prinsip 3")
		_:
			_hud.set_mission_text("Pos 7 Selesai! Lompati Jembatan Terakhir ke Finish Pos 8")
			_hud.set_walk_caption("Jalan ke Gerbang Pos 8")


func _on_next_route_entered() -> void:
	if _transitioning:
		return
	_transitioning = true
	Audio.play_sfx("confirm")
	Router.go_to("res://scenes/worlds/Pos8_FinishAkuTahuEmosiku.tscn")


func _unhandled_input(event: InputEvent) -> void:
	if Game.modal_open:
		return
	if event.is_action_pressed("interact"):
		_trigger_action()
		get_viewport().set_input_as_handled()
