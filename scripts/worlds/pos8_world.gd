extends Node3D

## Pos 8: Finish - Alun-Alun Perayaan "Aku Tahu Emosiku!"
## Interactive 2-Stage Finale:
## 1. Nyalakan 3 Lentera Kenangan Emosi (Pos 1-2, Pos 3-5, Pos 6-7) along the royal carpet.
## 2. Naik ke Podium & Angkat Piala Emas tinggi-tinggi dengan efek kembang api, konfeti, dan sorakan teman!

const CommsBannerScript := preload("res://scripts/ui/comms_banner.gd")
const DialogFinishScript := preload("res://scripts/ui/dialog_finish_pos8.gd")

@onready var _player: NaraController = $NaraPlayer
@onready var _camera: FollowCamera = $FollowCamera
@onready var _props: Pos8Props = $Pos8Props
@onready var _hud: GameHUD = $HUD

const PILLAR_STORIES := [
	{
		"speaker": "LENTERA 1 • KENALI EMOSIKU (POS 1-2)",
		"text": "Hebat! Kamu sudah berani mengenali 6 emosi dasar: sedih, marah, takut, bahagia, jijik, dan terkejut. Semua emosi wajar dirasakan! Yuk nyalakan lentera berikutnya!",
		"mood": "happy",
	},
	{
		"speaker": "LENTERA 2 • TENANGKAN DIRI (POS 3-5)",
		"text": "Mantap! Kamu tahu 6 langkah saat marah dan cara menyalurkan emosi dengan aman lewat tarik napas, bantal awan, dan kertas bekas! Tinggal 1 lentera lagi!",
		"mood": "happy",
	},
	{
		"speaker": "LENTERA 3 • EMPATI & 3 PRINSIP (POS 6-7)",
		"text": "Semua 3 Lentera Kenangan sudah menyala! Piala Emas di Podium kini bersinar terang! Naik ke podium dan tekan E atau tombol Aksi untuk mengangkat Piala Emas!",
		"mood": "excited",
	},
]

var _comms: CanvasLayer
var _cert_dialog: DialogFinishPos8
var _active_pillar: int = -1
var _in_trophy_zone: bool = false
var _celebrated: bool = false
var _playing_ceremony: bool = false


func _ready() -> void:
	Game.current_zone = "Pos 8"
	_camera.set_target(_player)

	_comms = CommsBannerScript.new()
	add_child(_comms)

	_cert_dialog = DialogFinishScript.new()
	add_child(_cert_dialog)
	_cert_dialog.replay_trophy_pressed.connect(_replay_trophy_ceremony)

	_props.pillar_zone_changed.connect(_on_pillar_zone_changed)
	_props.trophy_zone_changed.connect(_on_trophy_zone_changed)

	_hud.set_story_button_visible(false)
	_hud.walk_to_pos1_pressed.connect(_on_walk_pressed)
	_hud.open_pos1_pressed.connect(_trigger_action)

	Audio.play_music("bgm_victory", true)

	if Game.is_station_done(8):
		_celebrated = true
		_props.unlock_all_pillars_immediately()
		_props.trigger_grand_celebration()
		_refresh_mission()
	else:
		_refresh_mission()
		_guide(
			"NARA • POS 8: ALUN-ALUN FINISH!",
			"Hore! Bima, Sinta, dan semua teman menyambutmu! Sebelum mengangkat Piala Emas di podium, nyalakan dulu 3 Lentera Kenangan Emosi di sepanjang karpet merah!",
			"pos8_intro",
			"excited",
			9.5
		)


func _guide(speaker: String, text: String, voice_key: String, mood: String, dur: float) -> void:
	if not voice_key.is_empty():
		Audio.play_voice(voice_key, voice_key.ends_with("_intro"), speaker, text, mood)
	else:
		Audio.show_subtitle(speaker, text, mood, dur, false)


func _physics_process(_delta: float) -> void:
	_props.update_guide_arrow(_player.global_position, not _celebrated and not _playing_ceremony)


func _on_walk_pressed() -> void:
	if _playing_ceremony:
		return
	_player.walk_to(_props.get_next_target_position())


func _on_pillar_zone_changed(idx: int, entered: bool) -> void:
	if entered:
		_active_pillar = idx
	elif _active_pillar == idx:
		_active_pillar = -1
	_update_prompt()


func _on_trophy_zone_changed(entered: bool) -> void:
	_in_trophy_zone = entered
	_update_prompt()


func _update_prompt() -> void:
	if _playing_ceremony:
		_hud.set_interact_prompt("", false)
		return
	if _active_pillar >= 0 and not _props.is_pillar_lit(_active_pillar):
		_hud.set_interact_prompt("Nyalakan Lentera Kenangan %d" % (_active_pillar + 1), true)
		return
	if _in_trophy_zone:
		if not _props.is_trophy_ready():
			_hud.set_interact_prompt("Nyalakan %d/3 Lentera Kenangan dulu!" % _props.get_lit_count(), true)
		elif _celebrated:
			_hud.set_interact_prompt("Angkat Piala & Buka Piagam!", true)
		else:
			_hud.set_interact_prompt("Angkat Piala Emas Juara!", true)
		return
	_hud.set_interact_prompt("", false)


func _trigger_action() -> void:
	if Game.modal_open or _playing_ceremony:
		return

	# Stage 1: Activate an unlit Memory Pillar
	if _active_pillar >= 0 and not _props.is_pillar_lit(_active_pillar):
		var idx := _active_pillar
		_props.activate_pillar(idx)
		Audio.play_sfx("confirm")
		_player.face_toward(_props.pillar_positions[idx])
		_player.play_emote("celebrate", 1.1)
		var st: Dictionary = PILLAR_STORIES[idx]
		var voice_key := "pos8_trophy_ready" if _props.is_trophy_ready() else ""
		_guide(str(st["speaker"]), str(st["text"]), voice_key, str(st["mood"]), 7.5)
		_refresh_mission()
		_update_prompt()
		return

	# Stage 2: Trophy Podium Interaction
	if _in_trophy_zone:
		if not _props.is_trophy_ready():
			Audio.play_sfx("select")
			_guide(
				"PIALA EMAS MASIH MENUNGGU!",
				"Nyalakan 3 Lentera Kenangan Emosi di sepanjang karpet merah dulu ya (%d/3 sudah menyala) supaya Piala Emas bersinar!" % _props.get_lit_count(),
				"",
				"happy",
				5.5
			)
			return
		_run_trophy_lift_ceremony(true)


func _replay_trophy_ceremony() -> void:
	if _playing_ceremony:
		return
	_run_trophy_lift_ceremony(false)


func _run_trophy_lift_ceremony(open_cert_after: bool) -> void:
	_playing_ceremony = true
	_hud.set_interact_prompt("", false)
	_player.set_control_locked(true)

	# 1. Position Nara cleanly on the front center of the celebratory dais facing the camera!
	var pos_tw := create_tween().set_parallel(true)
	pos_tw.tween_property(_player, "global_position", _props.podium_stand_pos, 0.42).set_trans(Tween.TRANS_SINE)
	pos_tw.tween_property(_player, "rotation:y", 0.0, 0.42).set_trans(Tween.TRANS_SINE)
	# Smooth hero camera framing so Nara lifting the Golden Trophy fills the screen beautifully!
	pos_tw.tween_property(_camera, "distance", 4.85, 0.65).set_trans(Tween.TRANS_SINE)
	pos_tw.tween_property(_camera, "height", 1.85, 0.65).set_trans(Tween.TRANS_SINE)
	pos_tw.tween_property(_camera, "yaw", 0.0, 0.65).set_trans(Tween.TRANS_SINE)
	await pos_tw.finished

	# 2. Lift the 3D Golden Trophy high into Nara's raised hands + fireworks + confetti!
	_player.set_carrying(false)
	_player.set_holding_trophy(true)
	_player.play_emote("lift_trophy", 3.2)
	_props.lift_trophy_to_nara(_player.get_trophy_anchor())
	_props.trigger_grand_celebration()
	Audio.play_sfx("star")

	if not _celebrated:
		_celebrated = true
		Game.complete_station(8, 25, 1)
		Audio.play_voice("pos8_win")
		_refresh_mission()
	else:
		Audio.play_voice("pos8_win")

	if _comms != null:
		_comms.call(
			"show_guidance",
			"HOREEE! NARA MENGANGKAT PIALA EMAS!",
			"Selamat! Kamu resmi menjadi Penjelajah Taman Emosi! Aku Tahu Emosiku!",
			"excited",
			4.5
		)

	# Let the player enjoy Nara lifting the trophy + fireworks + cheering friends for 3.2 seconds!
	await get_tree().create_timer(3.2).timeout

	# Smoothly lower the Golden Trophy to Nara's chest so she cradles it comfortably while exploring!
	_player.set_holding_trophy(false)
	_player.set_carrying(true)
	_props.lower_trophy_to_chest(_player.get_carry_anchor())

	# Smoothly restore regular exploration camera
	var cam_back := create_tween().set_parallel(true)
	cam_back.tween_property(_camera, "distance", 7.2, 0.55).set_trans(Tween.TRANS_SINE)
	cam_back.tween_property(_camera, "height", 2.6, 0.55).set_trans(Tween.TRANS_SINE)

	_player.set_control_locked(false)
	_playing_ceremony = false
	_update_prompt()

	if open_cert_after:
		_cert_dialog.open_certificate()


func _refresh_mission() -> void:
	if _celebrated:
		_hud.set_mission_text("FINISH! Nara Mengangkat Piala Emas! Aku Tahu Emosiku!")
		_hud.set_walk_caption("Angkat Piala & Piagam")
	elif _props.is_trophy_ready():
		_hud.set_mission_text("Pos 8 (FINISH): Semua Lentera Menyala! Naik Podium & Tekan [E] Angkat Piala Emas!")
		_hud.set_walk_caption("Jalan ke Podium Piala")
	else:
		_hud.set_mission_text("Pos 8 (FINISH): Nyalakan Lentera Kenangan Emosi (%d/3) di Sepanjang Karpet!" % _props.get_lit_count())
		_hud.set_walk_caption("Jalan ke Lentera Berikutnya")


func _unhandled_input(event: InputEvent) -> void:
	if Game.modal_open or _playing_ceremony:
		return
	if event.is_action_pressed("interact"):
		_trigger_action()
		get_viewport().set_input_as_handled()
