extends Node3D

const DialogPos4Script := preload("res://scripts/ui/dialog_pos4.gd")
const CommsBannerScript := preload("res://scripts/ui/comms_banner.gd")

@onready var _sun: DirectionalLight3D = $SunLight
@onready var _player: NaraController = $NaraPlayer
@onready var _camera: FollowCamera = $FollowCamera
@onready var _props: Pos4Props = $Pos4Props
@onready var _hud: GameHUD = $HUD

var _summary_dialog: CanvasLayer
var _comms: CanvasLayer
var _current_step: int = 1 # 1..6, 7 = all done!
var _in_zones: Dictionary = {}

# Per-step physical timers
var _stop_still_t: float = 0.0
var _blowing_pinwheel: bool = false
var _splashing: bool = false
var _next_stone: int = 1
var _ambience_timer: float = 0.0
var _bump_cooldown: float = 0.0
var _transitioning: bool = false


func _ready() -> void:
	Game.current_zone = "Pos 4"
	Game.progress_changed.emit()
	_camera.set_target(_player)
	_props.attach_angry_cloud(_player)
	_props.set_anger_ratio(1.0, _sun)
	_props.set_active_step(1)

	_props.zone_changed.connect(_on_zone_changed)
	_props.orb_bumped.connect(_on_orb_bumped)
	_props.stone_stepped.connect(_on_stone_stepped)
	_props.next_route_entered.connect(_on_enter_pos5)

	_summary_dialog = DialogPos4Script.new()
	add_child(_summary_dialog)

	_comms = CommsBannerScript.new()
	add_child(_comms)

	_hud.set_story_button_visible(false)
	_hud.set_emotion_stamps_visible(false)
	_hud.set_pos4_tracker_visible(true)
	_sync_pos4_hud()

	_hud.walk_to_pos1_pressed.connect(func() -> void:
		if not Game.modal_open:
			var target: Vector3 = _props.get_next_target_pos(_current_step)
			if _current_step == 2:
				target = (_props.step_positions[2] as Vector3) + Vector3(0.0, 0.0, 2.15)
			_player.walk_to(target)
	)

	_hud.open_pos1_pressed.connect(func() -> void:
		if not Game.modal_open:
			_trigger_button_action()
	)

	Audio.play_music("bgm_garden", true)
	if Game.is_station_done(4):
		_current_step = 7
		_props.set_anger_ratio(0.0, _sun)
		_props.set_active_step(7)
		_props.unlock_exit_gate()
		_sync_pos4_hud()
	else:
		# Spider-Man-style proactive guidance RIGHT AT THE START while player begins moving!
		_guide_step(
			"NARA • LANGKAH 1 / 6 (BERHENTI DULU)",
			"Yah, menara balokku roboh! Yuk jalan ke lingkaran rambu STOP merah di depan, lalu berhenti diam sebentar ya!",
			"pos4_guide1",
			"upset",
			7.5
		)


func _guide_step(tag: String, subtitle: String, voice_key: String, expr: String, dur: float = 6.8) -> void:
	if not voice_key.is_empty():
		Audio.play_voice(voice_key, voice_key == "pos4_guide1", tag, subtitle, expr)
	else:
		Audio.show_subtitle(tag, subtitle, expr, dur, false)


func _process(delta: float) -> void:
	if Game.modal_open:
		return
	if _bump_cooldown > 0.0:
		_bump_cooldown -= delta

	var target: Vector3 = _props.get_next_target_pos(_current_step)
	if _current_step == 2:
		target = (_props.step_positions[2] as Vector3) + Vector3(0.0, 0.0, 2.0)
	_props.update_guide_arrow(_player.global_position, target)

	# Real River Kecemplung Check! If Nara steps off the stones into the blue stream -> BYURR!
	if not _splashing and _props.is_in_river_water(_player.global_position):
		_trigger_river_splash()
		return

	# STEP 1: Freeze / Stand still inside STOP ring for 1.35 seconds (Nara raises STOP hand!)
	if _current_step == 1 and _in_zones.get("step1", false):
		var horiz_speed := Vector2(_player.velocity.x, _player.velocity.z).length()
		if horiz_speed < 0.35:
			_player.play_emote("stop", 0.35)
			_stop_still_t = minf(1.35, _stop_still_t + delta)
			_props.update_stop_progress(_stop_still_t / 1.35)
			if _stop_still_t >= 1.35:
				_complete_step(1)
		else:
			_stop_still_t = maxf(0.0, _stop_still_t - delta * 1.2)
			_props.update_stop_progress(_stop_still_t / 1.35)

	_ambience_timer += delta
	if _ambience_timer >= 15.0:
		_ambience_timer = 0.0
		if randf() < 0.6:
			Audio.play_sfx("bird")


func _on_zone_changed(zone_id: String, entered: bool) -> void:
	_in_zones[zone_id] = entered
	if entered and zone_id == "step6" and _current_step == 6:
		_complete_step(6)
	_refresh_prompt()


func _on_orb_bumped() -> void:
	if _current_step != 2 or _bump_cooldown > 0.0:
		return
	_bump_cooldown = 0.9
	_player.cancel_auto_walk()
	var orb_pos: Vector3 = _props.step_positions[2] as Vector3
	var push_dir: Vector3 = _player.global_position - orb_pos
	push_dir.y = 0.0
	if push_dir.length_squared() < 0.01:
		push_dir = Vector3(0.0, 0.0, 1.0)
	_player.velocity = push_dir.normalized() * 6.5 + Vector3(0.0, 2.5, 0.0)
	Audio.play_sfx("error")
	_props.show_nara_bubble(_player.global_position, "Ups! Tahan tangan, tekan [E / Aksi] dari luar!", 2.2)


func _on_stone_stepped(num: int) -> void:
	if _current_step != 4:
		return
	if num == _next_stone:
		_props.mark_stone_hit(num)
		Audio.play_note(num)
		_props.show_nara_bubble(_player.global_position, "%d!" % num if num < 10 else "10! Hore!", 1.1)
		_next_stone += 1
		var partial_anger := lerpf(0.50, 0.32, float(num) / 10.0)
		_props.set_anger_ratio(partial_anger, _sun)
		_hud.update_pos4_tracker(_current_step - 1, int(partial_anger * 100.0))
		if _next_stone > 10:
			_complete_step(4)
	elif num > _next_stone:
		Audio.play_sfx("select")
		_props.show_nara_bubble(_player.global_position, "Injak batu %d dulu ya!" % _next_stone, 1.4)


func _trigger_river_splash() -> void:
	_splashing = true
	_player.set_control_locked(true)
	_player.play_emote("splash", 1.0)
	_props.spawn_water_splash(_player.global_position)
	Audio.play_sfx("splash")
	_props.show_nara_bubble(_player.global_position, "BYURR! Dingin! Lompat ke batu ya!", 1.8)
	Game.notify("BYURR! Nara kecemplung sungai! Ayo injak batu angka dengan hati-hati!", "info")
	await get_tree().create_timer(0.92).timeout
	if is_instance_valid(_player):
		var safe_pos: Vector3 = _props.get_safe_stone_pos(_next_stone - 1)
		var tw := create_tween()
		tw.tween_property(_player, "global_position", safe_pos + Vector3(0.0, 1.1, 0.0), 0.22).set_ease(Tween.EASE_OUT)
		tw.tween_property(_player, "global_position", safe_pos, 0.20).set_ease(Tween.EASE_IN)
		await tw.finished
		_player.set_control_locked(false)
	_splashing = false


func _perform_windmill_breath() -> void:
	if _blowing_pinwheel:
		return
	_blowing_pinwheel = true
	_player.set_control_locked(true)
	_player.face_toward(_props.step_positions[3] as Vector3)
	_player.play_emote("inhale", 0.85)
	_props.update_pinwheel_charge(0.55)
	_props.show_nara_bubble(_player.global_position, "Tarik nafas dalam... Hmmm...", 0.9)
	Audio.play_sfx("select")
	await get_tree().create_timer(0.80).timeout
	if is_instance_valid(_player):
		_player.play_emote("blow", 1.05)
		_props.trigger_pinwheel_gust(_player.global_position)
		_props.show_nara_bubble(_player.global_position, "Huffff! Kincirnya berputar!", 1.6)
		Audio.play_sfx("sparkle")
		_complete_step(3)
	await get_tree().create_timer(0.65).timeout
	if is_instance_valid(_player):
		_player.set_control_locked(false)
	_blowing_pinwheel = false


func _refresh_prompt() -> void:
	if _current_step == 1 and _in_zones.get("step1", false):
		_hud.set_interact_prompt("Berhenti Diam 1,5 Detik!", true)
	elif _current_step == 2 and _in_zones.get("step2", false):
		_hud.set_interact_prompt("Tahan Tangan & Tenangkan (E)", true)
	elif _current_step == 3 and _in_zones.get("step3", false):
		_hud.set_interact_prompt("Tarik Nafas & Tiup Kincir (E)", true)
	elif _in_zones.get("step5", false):
		_hud.set_interact_prompt("Elus Kucing & Istirahat (E)", true)
	else:
		_hud.set_interact_prompt("", false)


func _trigger_button_action() -> void:
	if _current_step == 2 and _in_zones.get("step2", false):
		_player.face_toward(_props.step_positions[2] as Vector3)
		_player.play_emote("hold_back", 1.3)
		_props.calm_anger_orb(_player.global_position)
		_complete_step(2)
	elif _current_step == 3 and _in_zones.get("step3", false):
		_perform_windmill_breath()
	elif _in_zones.get("step5", false):
		_perform_pet_cat()


func _perform_pet_cat() -> void:
	if _blowing_pinwheel or _splashing:
		return
	_blowing_pinwheel = true
	_player.set_control_locked(true)
	# Smoothly glide Nara right to the cozy cushion beside the Orange Cat so she actually pets its head!
	var pet_spot: Vector3 = _props.get_cat_pet_spot()
	var tw := create_tween()
	tw.tween_property(_player, "global_position", pet_spot, 0.32).set_ease(Tween.EASE_OUT)
	await tw.finished
	if is_instance_valid(_player):
		_player.face_toward(_props.get_cat_world_pos())
		_player.play_emote("pet_cat", 2.2)
		_props.pet_orange_cat(_player.global_position)
		Audio.play_sfx("meow")
		Audio.play_sfx("sparkle")
		if _current_step == 5:
			_complete_step(5)
		else:
			_props.show_nara_bubble(_player.global_position, "Lucunya si kucing oranye~ ♥", 2.0)
	await get_tree().create_timer(1.15).timeout
	if is_instance_valid(_player):
		_player.set_control_locked(false)
	_blowing_pinwheel = false


func _complete_step(step_num: int) -> void:
	if step_num != _current_step:
		return
	_current_step += 1
	_props.set_active_step(_current_step)
	Game.add_coins(5)
	Audio.play_sfx("coin")

	match step_num:
		1:
			_props.set_anger_ratio(0.84, _sun)
			_props.show_nara_bubble(_player.global_position, "Berhenti dulu ✓", 1.8)
			_guide_step(
				"NARA • LANGKAH 2 / 6 (TAHAN MEMUKUL)",
				"Bagus! Sekarang lihat bola merah di depan. Jangan ditabrak ya! Berdiri di lingkaran oranye lalu tekan E atau tombol Aksi untuk menahan tangan!",
				"pos4_guide2",
				"thinking",
				7.6
			)
		2:
			_props.set_anger_ratio(0.68, _sun)
			Audio.play_sfx("sparkle")
			_props.show_nara_bubble(_player.global_position, "Bola kesal jadi kupu-kupu! ✓", 2.0)
			_guide_step(
				"NARA • LANGKAH 3 / 6 (TARIK NAFAS)",
				"Keren, bola kesalnya jadi kupu-kupu! Sekarang coba kamu ke arah kiri menuju Kincir Angin, lalu tekan E atau tombol Aksi untuk meniupnya!",
				"pos4_guide3",
				"happy",
				7.8
			)
		3:
			_props.set_anger_ratio(0.50, _sun)
			Audio.play_sfx("sparkle")
			_props.show_nara_bubble(_player.global_position, "Anginnya segar! ✓", 1.8)
			_guide_step(
				"NARA • LANGKAH 4 / 6 (HITUNG SAMPAI 10)",
				"Segarnya! Sekarang yuk menyeberangi sungai biru di depan! Injak batu angka satu sampai sepuluh pelan-pelan ya!",
				"pos4_guide4",
				"excited",
				7.0
			)
		4:
			_props.set_anger_ratio(0.30, _sun)
			Audio.play_sfx("sparkle")
			_props.show_nara_bubble(_player.global_position, "1 sampai 10 selesai! ✓", 1.8)
			_guide_step(
				"NARA • LANGKAH 5 / 6 (CARI TEMPAT NYAMAN)",
				"Asyik, sudah sampai sepuluh! Coba kamu ke arah kanan menuju Gazebo! Ada kucing oranye di sana, tekan E atau tombol Aksi untuk istirahat sebentar!",
				"pos4_guide5",
				"happy",
				7.8
			)
		5:
			_props.set_anger_ratio(0.14, _sun)
			Audio.play_sfx("bird")
			_props.show_nara_bubble(_player.global_position, "Nyaman sekali! ✓", 1.8)
			_guide_step(
				"NARA • LANGKAH 6 / 6 (MENJAUH DARI SUMBER MARAH)",
				"Nyaman sekali bersama si kucing oranye! Langkah terakhir, ayo jalan lurus melewati Lengkungan Bunga menuju Bintang Pos 4!",
				"pos4_guide6",
				"excited",
				7.0
			)
		6:
			_player.play_emote("celebrate", 2.2)
			_props.set_anger_ratio(0.0, _sun)
			_props.unlock_exit_gate()
			Game.complete_station(4, 25, 1)
			Audio.play_sfx("star")
			Audio.play_music("bgm_victory", false)
			_props.show_nara_bubble(_player.global_position, "Hore! Langit cerah & hatiku sejuk!", 2.8)
			_guide_step(
				"NARA • POS 4 SELESAI!",
				"Hore! Semua enam langkah berhasil! Langit kembali cerah dan Gerbang Pos 5 sudah terbuka!",
				"pos4_win",
				"excited",
				6.5
			)
			await get_tree().create_timer(1.2).timeout
			_summary_dialog.call("open_summary")

	_sync_pos4_hud()
	_refresh_prompt()


func _sync_pos4_hud() -> void:
	var done_count := _current_step - 1
	var anger_pct_table := [100, 84, 68, 50, 30, 14, 0]
	var anger_pct: int = anger_pct_table[clampi(done_count, 0, 6)]
	_hud.update_pos4_tracker(done_count, anger_pct)

	var captions := [
		"Misi Pos 4: 1. Masuk Lingkaran STOP & Diam",
		"Misi Pos 4: 2. Tahan Tangan & Tekan E / Aksi di Luar Bola Merah",
		"Misi Pos 4: 3. Ke Kiri & Tahan E Tiup Kincir Angin",
		"Misi Pos 4: 4. Injak Batu 1 -> 10 di Sungai",
		"Misi Pos 4: 5. Ke Kanan Istirahat di Gazebo Nyaman",
		"Misi Pos 4: 6. Jalan Lewati Lengkungan Bunga",
		"Misi Pos 4 Selesai (6/6)! Gerbang Pos 5 Terbuka!",
	]
	var walk_caps := [
		"Jalan ke Langkah 1 (STOP)",
		"Jalan ke Langkah 2 (Tahan)",
		"Jalan ke Langkah 3 (Kincir)",
		"Jalan ke Batu Hitung",
		"Jalan ke Gazebo Nyaman",
		"Jalan ke Lengkungan Damai",
		"Jalan ke Gerbang Pos 5",
	]
	_hud.set_mission_text(captions[clampi(done_count, 0, 6)])
	_hud.set_walk_caption(walk_caps[clampi(done_count, 0, 6)])


func _on_enter_pos5() -> void:
	if _transitioning:
		return
	_transitioning = true
	Audio.stop_voice()
	Audio.play_sfx("confirm")
	Router.go_to("res://scenes/worlds/Pos5_PukulBantalSobekKertas.tscn")


func _unhandled_input(event: InputEvent) -> void:
	if not Game.modal_open and not _splashing and not _blowing_pinwheel and event.is_action_pressed("interact"):
		if (_current_step == 2 and _in_zones.get("step2", false)) or (_current_step == 3 and _in_zones.get("step3", false)) or _in_zones.get("step5", false):
			_trigger_button_action()
			get_viewport().set_input_as_handled()
