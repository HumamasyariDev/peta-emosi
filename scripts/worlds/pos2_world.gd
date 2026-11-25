extends Node3D

const DialogEmotionPos2Script := preload("res://scripts/ui/dialog_emotion_pos2.gd")

@onready var _player: NaraController = $NaraPlayer
@onready var _camera: FollowCamera = $FollowCamera
@onready var _props: Pos2Props = $Pos2Props
@onready var _hud: GameHUD = $HUD

var _emotion_dialog: CanvasLayer
var _near_friend_id: String = ""
var _solved: Dictionary = {}
var _transitioning: bool = false
var _ambience_timer: float = 0.0

const EMO_LABELS := {
	"sedih": "1. Sedih",
	"marah": "2. Marah",
	"takut": "3. Takut",
	"bahagia": "4. Bahagia",
	"jijik": "5. Jijik",
	"terkejut": "6. Terkejut",
}


func _ready() -> void:
	Game.current_zone = "Pos 2"
	Game.progress_changed.emit()
	_camera.set_target(_player)
	_props.near_friend_changed.connect(_on_near_friend_changed)
	_props.next_route_entered.connect(_on_enter_pos3)

	_emotion_dialog = DialogEmotionPos2Script.new()
	add_child(_emotion_dialog)
	_emotion_dialog.connect("emotion_solved", _on_emotion_solved)

	_hud.set_story_button_visible(false)
	_hud.set_emotion_stamps_visible(true)
	_hud.set_walk_caption("Jalan ke Teman Berikutnya")
	_hud.set_mission_text("Misi Pos 2: Kenali 6 Emosi Teman (0/6)")

	# Restore already collected emotions / completed Pos 2 state from save so gate NEVER stays stuck!
	for emo_id: String in EMO_LABELS.keys():
		if Game.collected_emotions.has(emo_id) or Game.is_station_done(2):
			_solved[emo_id] = true
			_props.mark_friend_solved(emo_id, str(EMO_LABELS[emo_id]))
	if Game.is_station_done(2) or _solved.size() >= 6:
		_props.unlock_exit_gate()
		_hud.set_mission_text("Misi Pos 2 Selesai (6/6)! Gerbang Pos 3 Terbuka!")
		_hud.set_walk_caption("Jalan ke Gerbang Pos 3")
	elif _solved.size() > 0:
		_hud.set_mission_text("Misi Pos 2: Kenali 6 Emosi Teman (%d/6)" % _solved.size())

	_hud.walk_to_pos1_pressed.connect(func() -> void:
		if not Game.modal_open:
			var target := _props.get_next_unsolved_pos()
			_player.walk_to(target)
			if _solved.size() >= 6:
				Game.notify("Nara berjalan menuju Gerbang Pos 3...", "info")
			else:
				Game.notify("Nara berjalan menghampiri teman berikutnya di taman...", "info")
	)
	_hud.open_pos1_pressed.connect(func() -> void:
		if not Game.modal_open and not _near_friend_id.is_empty():
			_emotion_dialog.call("open_friend", _near_friend_id, _solved.has(_near_friend_id))
	)

	Audio.play_music("bgm_garden", true)
	Audio.play_voice("pos2_intro", not Game.is_station_done(2), "NARA • POS 2: TAMAN 6 EMOSI")
	Game.notify("Selamat datang di Pos 2: Taman 6 Emosi Dasar! Sapa ke-6 temanmu.", "info")


func _process(delta: float) -> void:
	if not Game.modal_open:
		_props.update_guide_arrow(_player.global_position, _props.get_next_unsolved_pos())
	_ambience_timer += delta
	if _ambience_timer >= 14.0:
		_ambience_timer = 0.0
		if randf() < 0.6:
			Audio.play_sfx("bird")


func _on_near_friend_changed(friend_id: String) -> void:
	_near_friend_id = friend_id
	if not friend_id.is_empty():
		_hud.set_interact_prompt("Sapa & Kenalan Emosi (E)", true)
		if friend_id == "terkejut" and _props.pop_terkejut_balloon():
			Audio.play_sfx("thunder")
			Audio.play_voice("pos2_balloon")
			Game.notify("DOR! Balon merahnya meletus! Tekan E atau tombol Aksi untuk menyapa 6. Terkejut!", "info")
		elif not Game.modal_open:
			Game.notify("Tekan E atau tombol Aksi untuk berkenalan!", "info")
	else:
		_hud.set_interact_prompt("", false)


func _on_emotion_solved(friend_id: String, emotion_label: String) -> void:
	if _solved.has(friend_id):
		return
	_solved[friend_id] = true
	_props.mark_friend_solved(friend_id, emotion_label)

	var count := _solved.size()
	if count >= 6:
		_hud.set_mission_text("Misi Pos 2 Selesai (6/6)! Gerbang Pos 3 Terbuka!")
		_hud.set_walk_caption("Jalan ke Gerbang Pos 3")
		Game.complete_station(2, 20, 1)
		_props.unlock_exit_gate()
		Audio.play_sfx("star")
		Audio.play_music("bgm_victory", false)
		Audio.play_voice("pos2_win")
		Game.notify("Hore! Semua 6 Emosi Dasar dikenali! Bintang Pos 2 diraih & Gerbang Pos 3 terbuka!", "success")
	else:
		_hud.set_mission_text("Misi Pos 2: Kenali 6 Emosi Teman (%d/6)" % count)


func _on_enter_pos3() -> void:
	if _transitioning:
		return
	_transitioning = true
	Audio.stop_voice()
	Audio.play_sfx("confirm")
	Game.notify("Memasuki Pos 3: Bukit Lonceng Emas & Aturan Emosi...", "success")
	Router.go_to("res://scenes/worlds/Pos3_AturanEmosi.tscn")


func _unhandled_input(event: InputEvent) -> void:
	if not _near_friend_id.is_empty() and not Game.modal_open and event.is_action_pressed("interact"):
		_emotion_dialog.call("open_friend", _near_friend_id, _solved.has(_near_friend_id))
		get_viewport().set_input_as_handled()

