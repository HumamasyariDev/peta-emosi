extends Node3D

## Pos 6 (Konsep C): 2 Teman Berbeda Kebutuhan (Bima & Sinta) — Tanpa Papan Kuis!
## - Friend 1 (Bima): Needs play-together -> carry & stack 3 blocks in order (1. MERAH -> 2. KUNING -> 3. BIRU)
## - Friend 2 (Sinta): Needs alone-time -> respect her space & place cool water on her side table
## - Both calm -> Pos 6 Star + Confetti + Pos 7 Gate opens immediately!

const CommsBannerScript := preload("res://scripts/ui/comms_banner.gd")

@onready var _player: NaraController = $NaraPlayer
@onready var _camera: FollowCamera = $FollowCamera
@onready var _props: Pos6Props = $Pos6Props
@onready var _hud: GameHUD = $HUD

var _comms: CanvasLayer
var _offer_layer: CanvasLayer

# 1=Greet Bima (Offer Play vs Alone), 35=Stack Bima's 3 Blocks in Order,
# 2=Greet Sinta (Offer Play vs Alone), 3=Take Water, 4=Place Water for Sinta, 5=Done!
var _step: int = 1
var _in_zones: Dictionary = {}
var _busy: bool = false
var _danger_cd: float = 0.0
var _wrong_block_cd: float = 0.0
var _transitioning: bool = false


func _ready() -> void:
	Game.current_zone = "Pos 6"
	_camera.set_target(_player)

	_comms = CommsBannerScript.new()
	add_child(_comms)

	_props.zone_changed.connect(_on_zone_changed)
	_props.block_touched.connect(_on_block_touched)
	_props.tower_zone_touched.connect(_on_tower_zone_touched)
	_props.next_route_entered.connect(_on_next_route_entered)

	_hud.set_story_button_visible(false)
	_hud.walk_to_pos1_pressed.connect(_on_walk_pressed)
	_hud.open_pos1_pressed.connect(_trigger_action)

	Audio.play_music("bgm_garden", true)
	_refresh_mission()

	if Game.is_station_done(6):
		_step = 5
		_props.calm_bima_completely()
		_props.calm_sinta_completely()
		_props.set_active_step(5)
		_props.unlock_exit_gate()
		_refresh_mission()
	else:
		_run_opening_cutscene()


func _run_opening_cutscene() -> void:
	_busy = true
	_player.set_control_locked(true)
	_props.prepare_intro_cutscene()
	_hud.set_mission_text("Lihat apa yang terjadi pada menara balok Bima...")
	var bima_node := _props.get_bima_node()
	if bima_node != null:
		_camera.set_target(bima_node)
	await get_tree().create_timer(0.65).timeout
	await _props.play_tower_collapse_cutscene()
	_camera.set_target(_player)
	await get_tree().create_timer(0.45).timeout
	_player.set_control_locked(false)
	_busy = false
	_step = 1
	_props.set_active_step(1)
	_refresh_mission()
	_refresh_prompt()
	_guide(
		"NARA • POS 6 (BANTU BIMA & SINTA)",
		"Menara balok Bima roboh! Di kanan juga ada Sinta yang sedang kesal. Setiap teman punya kebutuhan berbeda. Dekati ruang aman Bima dulu lalu tekan E atau tombol Aksi!",
		"pos6_intro",
		"thinking",
		8.8
	)


func _guide(speaker: String, text: String, voice_key: String, mood: String, dur: float) -> void:
	if not voice_key.is_empty():
		Audio.play_voice(voice_key, voice_key.ends_with("_intro"), speaker, text, mood)
	else:
		Audio.show_subtitle(speaker, text, mood, dur, false)


func _physics_process(delta: float) -> void:
	if _danger_cd > 0.0:
		_danger_cd -= delta
	if _wrong_block_cd > 0.0:
		_wrong_block_cd -= delta
	# Solid horizontal bumper around angry Bima (Step 1) and angry Sinta (Step 1, 35, 2)
	if not _busy and not Game.modal_open:
		if _step == 1:
			var d_bima := _player.global_position - _props.bima_position
			d_bima.y = 0.0
			if d_bima.length() < 2.75:
				_repel_from(_props.bima_position, d_bima, 2.95, "Hush! Aku lagi kesal, beri jarak dulu!")
		if _step in [1, 35, 2]:
			var d_sinta := _player.global_position - _props.sinta_position
			d_sinta.y = 0.0
			if d_sinta.length() < 2.35:
				_repel_from(_props.sinta_position, d_sinta, 2.55, "Jangan dekat-dekat dulu, aku lagi kesal!")
	_props.update_guide_arrow(_player.global_position, _props.get_step_target(_step))


func _repel_from(origin: Vector3, delta_xz: Vector3, push_r: float, msg: String) -> void:
	var dir := delta_xz.normalized() if delta_xz.length_squared() > 0.001 else Vector3(0.0, 0.0, 1.0)
	_player.cancel_auto_walk()
	_player.global_position.x = origin.x + dir.x * push_r
	_player.global_position.z = origin.z + dir.z * push_r
	var hop_y := 2.4 if (_player.is_on_floor() and _danger_cd <= 0.0) else minf(_player.velocity.y, 0.0)
	_player.velocity = Vector3(dir.x * 5.2, hop_y, dir.z * 5.2)
	_player.face_toward(origin)
	if _danger_cd <= 0.0:
		_danger_cd = 1.1
		_player.play_emote("surprised", 0.55)
		Audio.play_sfx("wrong")
		_props.trigger_danger_repel_fx(origin)
		_props.show_nara_bubble(origin, msg, 1.8)


func _on_zone_changed(zone_id: String, entered: bool) -> void:
	_in_zones[zone_id] = entered
	if (zone_id == "step1" and _step == 1) or (zone_id == "step2" and _step == 2) or (zone_id == "step3" and _step == 3) or (zone_id == "step4" and _step == 4):
		_props.trigger_zone_hover_fx(zone_id, entered)
	_refresh_prompt()


func _refresh_prompt() -> void:
	if _step == 1 and _in_zones.get("step1", false):
		_hud.set_interact_prompt("Tanya Kebutuhan Bima", true)
	elif _step == 2 and _in_zones.get("step2", false):
		_hud.set_interact_prompt("Tanya Kebutuhan Sinta", true)
	elif _step == 3 and _in_zones.get("step3", false):
		_hud.set_interact_prompt("Ambil Botol Air Sejuk", true)
	elif _step == 4 and _in_zones.get("step4", false):
		_hud.set_interact_prompt("Taruh Air di Meja Sinta", true)
	else:
		_hud.set_interact_prompt("", false)


func _on_walk_pressed() -> void:
	_player.walk_to(_props.get_step_target(_step))


func _trigger_action() -> void:
	if Game.modal_open or _busy:
		return
	if _step == 1 and _in_zones.get("step1", false):
		_open_friend_choice("bima")
	elif _step == 2 and _in_zones.get("step2", false):
		_open_friend_choice("sinta")
	elif _step == 3 and _in_zones.get("step3", false):
		_do_step3_take_water()
	elif _step == 4 and _in_zones.get("step4", false):
		_do_step4_place_water()


func _open_friend_choice(friend_id: String) -> void:
	_busy = true
	_player.face_toward(_props.bima_position if friend_id == "bima" else _props.sinta_position)
	_player.play_emote("hold_back", 0.7)
	Audio.play_sfx("select")

	if _offer_layer != null and is_instance_valid(_offer_layer):
		_offer_layer.queue_free()
	Game.modal_open = true
	_offer_layer = CanvasLayer.new()
	_offer_layer.layer = 24
	add_child(_offer_layer)

	var font_ui: Font = StorybookUI.font_body(580)
	var font_disp: Font = StorybookUI.font_display()

	var bg := ColorRect.new()
	bg.color = Color(0.04, 0.08, 0.07, 0.62)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	_offer_layer.add_child(bg)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.add_child(center)

	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(700, 0)
	card.add_theme_stylebox_override("panel", StorybookUI.make_panel_box(
		Color("f2faf8"), StorybookUI.SAGE_DARK, 22, 4, 10, 24, 20, true
	))
	center.add_child(card)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 14)
	card.add_child(v)

	var title := Label.new()
	title.text = ("Teman 1: Bima (Menaranya Roboh)" if friend_id == "bima" else "Teman 2: Sinta (Sedang Kesal & Cemberut)")
	title.add_theme_font_override("font", font_disp)
	title.add_theme_font_size_override("font_size", 21)
	title.add_theme_color_override("font_color", StorybookUI.INK)
	v.add_child(title)

	var quote := Label.new()
	quote.text = (
		"Bima berkata: \"Huuuh, menara balokku roboh semua! Susah banget nyusunnya sendirian...\"\nTawarkan pilihan yang paling pas untuk Bima:"
		if friend_id == "bima" else
		"Sinta berkata: \"Lagi bete banget... aku lagi nggak mau diganggu atau diajak main rame-rame dulu...\"\nTawarkan pilihan yang paling menghargai Sinta:"
	)
	quote.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	quote.add_theme_font_override("font", font_ui)
	quote.add_theme_font_size_override("font_size", 15)
	quote.add_theme_color_override("font_color", StorybookUI.INK_SOFT)
	v.add_child(quote)

	var feedback := Label.new()
	feedback.text = "Dengarkan apa yang temanmu butuhkan lalu pilih salah satu!"
	feedback.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	feedback.add_theme_font_override("font", font_ui)
	feedback.add_theme_font_size_override("font_size", 14)
	feedback.add_theme_color_override("font_color", StorybookUI.SAGE_DARK)

	var choices := [
		{"id": "play", "label": "Ajak Main Bareng!\n(Bantu Susun Menara Balok)", "bg": StorybookUI.HONEY, "bd": StorybookUI.WALNUT, "fg": StorybookUI.INK},
		{"id": "alone", "label": "Beri Waktu Sendiri Dulu\n(Hargai Ruang Tenang + Siapkan Air)", "bg": StorybookUI.SAGE, "bd": StorybookUI.SAGE_DARK, "fg": StorybookUI.CREAM},
	]
	choices.shuffle()

	var btn_row := HBoxContainer.new()
	btn_row.add_theme_constant_override("separation", 14)
	v.add_child(btn_row)

	for ch: Dictionary in choices:
		var btn := Button.new()
		btn.text = ch["label"]
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.custom_minimum_size = Vector2(0, 76)
		StorybookUI.style_tactile_button(btn, ch["bg"], ch["bd"], ch["fg"], font_disp, 15, 14, 14, 10)
		var cid: String = ch["id"]
		btn.pressed.connect(func() -> void:
			_on_friend_choice_picked(friend_id, cid, feedback)
		)
		btn_row.add_child(btn)

	v.add_child(feedback)


func _on_friend_choice_picked(friend_id: String, choice_id: String, feedback: Label) -> void:
	var right_choice := ("play" if friend_id == "bima" else "alone")
	if choice_id != right_choice:
		Audio.play_sfx("wrong")
		if friend_id == "bima":
			feedback.text = "Dengarkan Bima lagi! Bima sedih karena kesulitan menyusun sendirian, jadi ia ingin ditemani main bareng!"
		else:
			feedback.text = "Dengarkan Sinta lagi! Sinta sedang tidak mau diajak main dulu, ia butuh waktu sendiri sampai tenang!"
		feedback.add_theme_color_override("font_color", StorybookUI.BERRY)
		return

	if _offer_layer != null and is_instance_valid(_offer_layer):
		_offer_layer.queue_free()
		_offer_layer = null
	Game.modal_open = false
	Audio.play_sfx("sparkle")

	if friend_id == "bima":
		_props.set_bima_cooling()
		_props.show_nara_bubble(_props.bima_position, "Iya! Ayo bantu susun balok 1. MERAH dulu!", 2.4)
		Game.add_coins(5)
		Audio.play_sfx("coin")
		_busy = false
		_step = 35
		_props.set_active_step(35)
		_refresh_mission()
		_refresh_prompt()
		_guide(
			"NARA • BANTU BIMA MAIN BARENG (0/3)",
			"Tepat! Bima mau ditemani bermain! Angkat 3 balok satu per satu sesuai urutan (1. MERAH, 2. KUNING, 3. BIRU) lalu taruh ke menara Bima!",
			"pos6_blocks",
			"excited",
			8.2
		)
	else:
		_props.set_sinta_cooling()
		_props.show_nara_bubble(_props.sinta_position, "Makasih sudah mengerti... boleh taruh air di meja dekatku?", 2.5)
		Game.add_coins(5)
		Audio.play_sfx("coin")
		_busy = false
		_step = 3
		_props.set_active_step(3)
		_refresh_mission()
		_refresh_prompt()
		_guide(
			"NARA • HARGAI RUANG TENANG SINTA",
			"Bagus! Sinta butuh waktu sendiri. Ambilkan botol air sejuk di bawah payung taman lalu taruh di meja kecil dekat Sinta tanpa mengganggunya!",
			"pos6_step2",
			"happy",
			8.0
		)


func _on_block_touched(block_idx: int) -> void:
	if _step != 35 or _props.is_carrying_block():
		return
	var expected := _props.get_expected_block_idx()
	if block_idx != expected:
		if _wrong_block_cd <= 0.0:
			_wrong_block_cd = 1.2
			Audio.play_sfx("wrong")
			_props.shake_wrong_block(block_idx)
			var need_name := _props.get_block_name(expected)
			_props.show_nara_bubble(_player.global_position, "Ambil Balok %d (%s) dulu biar kokoh!" % [expected + 1, need_name], 1.9)
		return
	if _props.pickup_block_to_hands(block_idx, _player):
		Audio.play_sfx("select")
		var bname := _props.get_block_name(block_idx)
		_props.show_nara_bubble(_player.global_position, "Balok %d (%s) diangkat! Taruh di menara →" % [block_idx + 1, bname], 1.8)
		_refresh_mission()


func _on_tower_zone_touched() -> void:
	if _step != 35 or not _props.is_carrying_block():
		return
	var count := _props.place_carried_block_on_tower(_player)
	Audio.play_sfx("coin")
	Game.add_coins(2)
	_props.show_nara_bubble(_props.tower_position, "Balok %d / 3 tersusun! ✓" % count, 1.5)
	_refresh_mission()
	if count >= 3:
		_props.calm_bima_completely()
		Audio.play_sfx("star")
		_props.show_nara_bubble(_props.bima_position, "Yey!! Menaraku berdiri lagi! Makasih Nara ♥", 2.5)
		_step = 2
		_props.set_active_step(2)
		_refresh_mission()
		_refresh_prompt()
		_guide(
			"NARA • BIMA TENANG! SEKARANG TEMUI SINTA",
			"Hore! Bima sudah tersenyum senang! Sekarang lihat Sinta di sebelah kanan yang masih kesal, tanyakan apakah ia mau main atau mau sendiri dulu!",
			"pos6_sinta",
			"happy",
			8.0
		)


func _do_step3_take_water() -> void:
	_busy = true
	_player.face_toward(_props.step_positions[3] as Vector3)
	_player.play_emote("pet_cat", 0.55)
	_props.take_water_bottle(_player)
	Audio.play_sfx("confirm")
	_props.show_nara_bubble(_player.global_position, "Air sejuk dipegang! Taruh di meja Sinta →", 1.7)
	await get_tree().create_timer(0.5).timeout
	_busy = false
	_step = 4
	_props.set_active_step(4)
	_refresh_mission()
	_refresh_prompt()


func _do_step4_place_water() -> void:
	_busy = true
	_player.face_toward(_props.sinta_table_pos)
	_player.play_emote("celebrate", 1.5)
	_props.place_water_for_sinta(_player)
	_props.calm_sinta_completely()
	Audio.play_sfx("star")
	Audio.play_voice("pos6_win")
	_props.show_nara_bubble(_props.sinta_position, "Makasih Nara! Karena dikasih waktu tenang, aku lega sekarang ♥", 3.0)
	await get_tree().create_timer(1.1).timeout
	_busy = false
	_step = 5
	_props.set_active_step(5)
	_props.unlock_exit_gate()
	Game.complete_station(6, 15, 1)
	_refresh_mission()
	_refresh_prompt()
	_guide(
		"NARA • POS 6 SELESAI!",
		"Hebat! Bima tenang karena ditemani main, dan Sinta tenang karena diberi waktu sendiri. Setiap teman punya cara tenang berbeda! Gerbang Pos 7 terbuka!",
		"",
		"excited",
		8.5
	)


func _refresh_mission() -> void:
	match _step:
		1:
			_hud.set_mission_text("Pos 6 (Teman 1/2): Tawarkan Bima Main Bareng atau Sendiri Dulu")
			_hud.set_walk_caption("Jalan ke Ruang Aman Bima")
		35:
			var cnt := _props.get_collected_block_count()
			var next_idx := _props.get_expected_block_idx()
			var next_name := _props.get_block_name(next_idx)
			if _props.is_carrying_block():
				_hud.set_mission_text("Pos 6 (Bima): Taruh Balok ke Alas Menara (%d/3)" % cnt)
				_hud.set_walk_caption("Antar Balok ke Menara")
			else:
				_hud.set_mission_text("Pos 6 (Bima): Angkat Balok %d (%s) dulu! (%d/3)" % [next_idx + 1, next_name, cnt])
				_hud.set_walk_caption("Ambil Balok %d (%s)" % [next_idx + 1, next_name])
		2:
			_hud.set_mission_text("Pos 6 (Teman 2/2): Temui Sinta di Kanan & Tanyakan Kebutuhannya")
			_hud.set_walk_caption("Jalan ke Ruang Aman Sinta")
		3:
			_hud.set_mission_text("Pos 6 (Sinta): Ambil Botol Air Sejuk di Payung Taman")
			_hud.set_walk_caption("Jalan ke Payung Air Minum")
		4:
			_hud.set_mission_text("Pos 6 (Sinta): Taruh Air di Meja Kecil dekat Sinta")
			_hud.set_walk_caption("Taruh Air di Meja Sinta")
		_:
			_hud.set_mission_text("Pos 6 Selesai! Bima & Sinta Sudah Tenang! Gerbang Pos 7 Terbuka")
			_hud.set_walk_caption("Jalan ke Gerbang Pos 7")


func _on_next_route_entered() -> void:
	if _transitioning:
		return
	_transitioning = true
	Audio.play_sfx("confirm")
	Router.go_to("res://scenes/worlds/Pos7_PrinsipSaatMarah.tscn")


func _unhandled_input(event: InputEvent) -> void:
	if Game.modal_open:
		return
	if event.is_action_pressed("interact"):
		_trigger_action()
		get_viewport().set_input_as_handled()
