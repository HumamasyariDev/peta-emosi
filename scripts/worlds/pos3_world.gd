extends Node3D

const DialogPos3Script := preload("res://scripts/ui/dialog_pos3.gd")
const EmotionBalancePos3Script := preload("res://scripts/ui/emotion_balance_pos3.gd")

@onready var _player: NaraController = $NaraPlayer
@onready var _camera: FollowCamera = $FollowCamera
@onready var _props: Pos3Props = $Pos3Props
@onready var _hud: GameHUD = $HUD

var _dialog: CanvasLayer
var _balance_game: CanvasLayer
var _near_bell: bool = false
var _near_board: bool = false
var _bell_balanced: bool = false
var _pos3_done: bool = false
var _transitioning: bool = false
var _ambience_timer: float = 0.0


func _ready() -> void:
	Game.current_zone = "Pos 3"
	Game.progress_changed.emit()
	_camera.set_target(_player)
	_props.near_bell_changed.connect(_on_near_bell_changed)
	_props.near_board_changed.connect(_on_near_board_changed)
	_props.next_route_entered.connect(_on_enter_pos4)

	_dialog = DialogPos3Script.new()
	add_child(_dialog)
	_dialog.connect("pos3_solved", _on_pos3_solved)

	_balance_game = EmotionBalancePos3Script.new()
	add_child(_balance_game)
	_balance_game.connect("balanced", _on_bell_balanced)

	_hud.set_story_button_visible(false)
	_hud.set_emotion_stamps_visible(false)
	_hud.set_walk_caption("Jalan ke Lonceng Emas")
	_hud.set_mission_text("Misi Pos 3: Bunyikan Lonceng & Seimbangkan Emosi (0/2)")

	_hud.walk_to_pos1_pressed.connect(func() -> void:
		if not Game.modal_open:
			var target := _props.get_next_target_pos(_bell_balanced, _pos3_done)
			_player.walk_to(target)
			if _pos3_done:
				Game.notify("Nara berjalan menuju Gerbang Pos 4...", "info")
			elif not _bell_balanced:
				Game.notify("Nara berjalan menuju Lonceng Eling di sisi kiri plaza...", "info")
			else:
				Game.notify("Nara berjalan menuju Papan Aturan Emosi di sisi kanan...", "info")
	)

	_hud.open_pos1_pressed.connect(func() -> void:
		if not Game.modal_open:
			_trigger_context_interaction()
	)

	Audio.play_music("bgm_garden", true)
	if Game.is_station_done(3):
		_bell_balanced = true
		_pos3_done = true
		_props.calm_plaza()
		_props.mark_board_solved()
		_props.unlock_exit_gate()
		_hud.set_mission_text("Misi Pos 3 Selesai! Gerbang Pos 4 Terbuka!")
		_hud.set_walk_caption("Jalan ke Gerbang Pos 4")
	else:
		Audio.play_voice("pos3_intro", true, "NARA • POS 3: ATURAN EMOSI")
		Game.notify("Selamat datang di Pos 3: Bukit Lonceng Emas! Bunyikan Lonceng Eling dulu ya.", "info")


func _process(delta: float) -> void:
	if not Game.modal_open:
		_props.update_guide_arrow(_player.global_position, _props.get_next_target_pos(_bell_balanced, _pos3_done))
	_ambience_timer += delta
	if _ambience_timer >= 15.0:
		_ambience_timer = 0.0
		if randf() < 0.6:
			Audio.play_sfx("bird")


func _get_nearest_target() -> String:
	if _near_bell and _near_board:
		var d_bell := _player.global_position.distance_squared_to(_props.bell_position)
		var d_board := _player.global_position.distance_squared_to(_props.board_position)
		return "bell" if d_bell <= d_board else "board"
	if _near_bell:
		return "bell"
	if _near_board:
		return "board"
	return ""


func _on_near_bell_changed(is_near: bool) -> void:
	_near_bell = is_near
	_refresh_interact_prompt()


func _on_near_board_changed(is_near: bool) -> void:
	_near_board = is_near
	_refresh_interact_prompt()


func _refresh_interact_prompt() -> void:
	var target := _get_nearest_target()
	if target == "bell":
		_hud.set_interact_prompt("Bunyikan Lonceng & Timbangan (E)", true)
	elif target == "board":
		_hud.set_interact_prompt("Buka Papan Aturan Emosi (E)", true)
	else:
		_hud.set_interact_prompt("", false)


func _trigger_context_interaction() -> void:
	var target := _get_nearest_target()
	if target == "bell":
		_ring_golden_bell()
	elif target == "board":
		_dialog.call("open_dialog", _pos3_done)


func _ring_golden_bell() -> void:
	_player.face_toward(_props.bell_position)
	_player.play_emote("ring_bell", 1.1)
	_props.ring_bell()
	Audio.play_sfx("bell")
	if not _bell_balanced:
		_props.show_nara_bubble(_player.global_position, "Tenggg! Ayo seimbangkan emosinya!", 2.2)
		Audio.play_voice("pos3_bell")
		# Brief beat so the player enjoys the 3D bell swing & golden shockwave before opening the scale
		await get_tree().create_timer(0.65).timeout
		if not Game.modal_open:
			_balance_game.call("open_balance", false)
	else:
		_props.show_nara_bubble(_player.global_position, "Tenggg! Hati tetap tenang & seimbang!", 2.4)
		Audio.play_sfx("sparkle")
		Game.notify("TENGGG! Emosimu sudah seimbang. Baca Papan Aturan di kanan!", "info")


func _on_bell_balanced() -> void:
	if _bell_balanced:
		return
	_bell_balanced = true
	_props.calm_plaza()
	_props.show_nara_bubble(_player.global_position, "Hore! Botol & Petasan ikut tenang!", 2.8)
	_hud.set_mission_text("Misi Pos 3: Buka Papan Aturan Emosi (1/2)")
	_hud.set_walk_caption("Jalan ke Papan Aturan")
	Game.notify("Keren! Timbangan Emosi seimbang! Sekarang baca Papan Aturan di kanan!", "success")


func _on_pos3_solved() -> void:
	if _pos3_done:
		return
	_pos3_done = true
	_bell_balanced = true
	_props.calm_plaza()
	_props.mark_board_solved()
	_props.unlock_exit_gate()
	Game.complete_station(3, 20, 1)
	_hud.set_mission_text("Misi Pos 3 Selesai! Gerbang Pos 4 Terbuka!")
	_hud.set_walk_caption("Jalan ke Gerbang Pos 4")
	Audio.play_sfx("star")
	Audio.play_music("bgm_victory", false)
	Audio.play_voice("pos3_win")
	Game.notify("Hebat! Lencana Sahabat Tenang diraih & Gerbang Pos 4 terbuka!", "success")


func _on_enter_pos4() -> void:
	if _transitioning:
		return
	_transitioning = true
	Audio.stop_voice()
	Audio.play_sfx("confirm")
	Game.notify("Memasuki Pos 4: 6 Langkah Menenangkan Diri...", "success")
	Router.go_to("res://scenes/worlds/Pos4_6LangkahTenang.tscn")


func _unhandled_input(event: InputEvent) -> void:
	if (_near_bell or _near_board) and not Game.modal_open and event.is_action_pressed("interact"):
		_trigger_context_interaction()
		get_viewport().set_input_as_handled()
