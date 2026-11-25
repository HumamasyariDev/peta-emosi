extends Node3D

const CommsBannerScript := preload("res://scripts/ui/comms_banner.gd")
const DialogPos5Script := preload("res://scripts/ui/dialog_pos5.gd")

@onready var _player: NaraController = $NaraPlayer
@onready var _camera: FollowCamera = $FollowCamera
@onready var _props: Pos5Props = $Pos5Props
@onready var _hud: GameHUD = $HUD

var _comms: CanvasLayer
var _dialog: DialogPos5

var _step: int = 1 # 1=Pillow, 2=Paper, 3=Safe Board, 4=Done
var _pillow_hits: int = 0
const PILLOW_MAX := 4
var _paper_rips: int = 0
const PAPER_MAX := 3
var _in_zones: Dictionary = {}
var _action_busy: bool = false
var _transitioning: bool = false


func _ready() -> void:
	Game.current_zone = "Pos 5"
	_camera.set_target(_player)

	_comms = CommsBannerScript.new()
	add_child(_comms)

	_dialog = DialogPos5Script.new()
	add_child(_dialog)
	_dialog.completed.connect(_on_pos5_completed)

	_props.zone_changed.connect(_on_zone_changed)
	_props.next_route_entered.connect(_on_next_route_entered)

	_hud.set_story_button_visible(false)
	_hud.walk_to_pos1_pressed.connect(_on_walk_pressed)
	_hud.open_pos1_pressed.connect(_trigger_action)

	Audio.play_music("bgm_garden", true)
	_refresh_mission()

	if Game.is_station_done(5):
		_step = 4
		_props.set_active_step(4)
		_props.unlock_exit_gate()
		_refresh_mission()
	else:
		_guide(
			"NARA • POS 5 (PUKUL BANTAL EMPUK)",
			"Kalau hati masih penuh energi kesal, yuk salurkan ke benda yang aman! Jalan ke bantal awan empuk di depan, lalu tekan E atau tombol Aksi!",
			"pos5_intro",
			"excited",
			8.0
		)


func _guide(speaker: String, text: String, voice_key: String, mood: String, dur: float) -> void:
	if not voice_key.is_empty():
		Audio.play_voice(voice_key, voice_key.ends_with("_intro"), speaker, text, mood)
	else:
		Audio.show_subtitle(speaker, text, mood, dur, false)


func _physics_process(_delta: float) -> void:
	_props.update_guide_arrow(_player.global_position, _props.get_step_target(_step))


func _on_zone_changed(zone_id: String, entered: bool) -> void:
	_in_zones[zone_id] = entered
	_refresh_prompt()


func _refresh_prompt() -> void:
	if _step == 1 and _in_zones.get("step1", false):
		_hud.set_interact_prompt("Pukul Bantal Empuk (%d/%d)" % [_pillow_hits, PILLOW_MAX], true)
	elif _step == 2 and _in_zones.get("step2", false):
		_hud.set_interact_prompt("Sobek Kertas Bekas (%d/%d)" % [_paper_rips, PAPER_MAX], true)
	elif _step == 3 and _in_zones.get("step3", false):
		_hud.set_interact_prompt("Buka Papan Pilihan Aman", true)
	else:
		_hud.set_interact_prompt("", false)


func _on_walk_pressed() -> void:
	_player.walk_to(_props.get_step_target(_step))


func _trigger_action() -> void:
	if Game.modal_open or _action_busy:
		return
	if _step == 1 and _in_zones.get("step1", false):
		_do_punch_pillow()
	elif _step == 2 and _in_zones.get("step2", false):
		_do_rip_paper()
	elif _step == 3 and _in_zones.get("step3", false):
		_dialog.open_modal()


func _do_punch_pillow() -> void:
	_action_busy = true
	_pillow_hits += 1
	_player.face_toward(_props.step_positions[1] as Vector3)
	_player.play_emote("punch_pillow", 0.42)
	_props.punch_pillow(_pillow_hits, PILLOW_MAX)
	Audio.play_sfx("thump")
	var words := ["BUK!", "POOF!", "LEGA!", "PLONG! ✓"]
	_props.show_nara_bubble(_player.global_position, words[mini(_pillow_hits - 1, words.size() - 1)], 1.2)
	_refresh_prompt()
	await get_tree().create_timer(0.36).timeout
	_action_busy = false
	if _pillow_hits >= PILLOW_MAX and _step == 1:
		_step = 2
		_props.set_active_step(2)
		Game.add_coins(5)
		Audio.play_sfx("coin")
		_refresh_mission()
		_refresh_prompt()
		_guide(
			"NARA • LANGKAH 2 / 3 (SOBEK KERTAS)",
			"Mantap! Bantal empuknya membal dan bikin lega! Sekarang jalan ke meja kertas bekas di kanan, lalu tekan E atau tombol Aksi untuk merobeknya!",
			"pos5_step2",
			"happy",
			8.0
		)


func _do_rip_paper() -> void:
	_action_busy = true
	_paper_rips += 1
	_player.face_toward(_props.step_positions[2] as Vector3)
	_player.play_emote("rip_paper", 0.55)
	_props.rip_paper_sheet(_paper_rips, PAPER_MAX)
	Audio.play_sfx("rip")
	var words := ["KREK!", "SREEK!", "PLOP! Daur Ulang ✓"]
	_props.show_nara_bubble(_player.global_position, words[mini(_paper_rips - 1, words.size() - 1)], 1.3)
	_refresh_prompt()
	await get_tree().create_timer(0.48).timeout
	_action_busy = false
	if _paper_rips >= PAPER_MAX and _step == 2:
		_step = 3
		_props.set_active_step(3)
		Game.add_coins(5)
		Audio.play_sfx("coin")
		_refresh_mission()
		_refresh_prompt()
		_guide(
			"NARA • LANGKAH 3 / 3 (PILIHAN AMAN)",
			"Keren, semua kertasnya masuk keranjang daur ulang! Terakhir, yuk dekati papan pilihan aman di depan gerbang, lalu tekan E atau tombol Aksi!",
			"pos5_step3",
			"excited",
			8.0
		)


func _on_pos5_completed() -> void:
	_step = 4
	_props.mark_board_done()
	_props.set_active_step(4)
	_props.unlock_exit_gate()
	Game.complete_station(5, 15, 1)
	_player.play_emote("celebrate", 2.0)
	_refresh_mission()
	_refresh_prompt()


func _refresh_mission() -> void:
	match _step:
		1:
			_hud.set_mission_text("Misi Pos 5: 1. Pukul Bantal Awan Empuk (%d/%d)" % [_pillow_hits, PILLOW_MAX])
			_hud.set_walk_caption("Jalan ke Bantal Empuk")
		2:
			_hud.set_mission_text("Misi Pos 5: 2. Sobek & Remas Kertas Bekas (%d/%d)" % [_paper_rips, PAPER_MAX])
			_hud.set_walk_caption("Jalan ke Meja Kertas")
		3:
			_hud.set_mission_text("Misi Pos 5: 3. Pilih 3 Cara Penyaluran Aman")
			_hud.set_walk_caption("Jalan ke Papan Pilihan")
		_:
			_hud.set_mission_text("Pos 5 Selesai! Gerbang Pos 6 Sudah Terbuka!")
			_hud.set_walk_caption("Jalan ke Gerbang Pos 6")


func _on_next_route_entered() -> void:
	if _transitioning:
		return
	_transitioning = true
	Audio.stop_voice()
	Audio.play_sfx("confirm")
	Router.go_to("res://scenes/worlds/Pos6_MelihatTemanMarah.tscn")


func _unhandled_input(event: InputEvent) -> void:
	if Game.modal_open:
		return
	if event.is_action_pressed("interact"):
		_trigger_action()
		get_viewport().set_input_as_handled()
