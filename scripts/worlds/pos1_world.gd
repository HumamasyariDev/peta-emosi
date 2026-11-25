extends Node3D

const StoryIntroScript := preload("res://scripts/ui/story_intro_pos1.gd")

@onready var _player: NaraController = $NaraPlayer
@onready var _camera: FollowCamera = $FollowCamera
@onready var _props: Pos1Props = $Pos1Props
@onready var _hud: GameHUD = $HUD
@onready var _quiz: DialogQuizPos1 = $DialogQuizPos1

var _story_intro: CanvasLayer
var _near_star: bool = false
var _near_star_voiced: bool = false
var _transitioning: bool = false
var _ambience_timer: float = 0.0


func _ready() -> void:
	Game.current_zone = "Pos 1"
	Game.progress_changed.emit()
	_camera.set_target(_player)
	_props.player_near_star_changed.connect(_on_near_star_changed)
	_props.next_route_entered.connect(_on_enter_pos2)

	_story_intro = StoryIntroScript.new()
	add_child(_story_intro)
	_story_intro.connect("finished", _on_story_finished)

	_hud.walk_to_pos1_pressed.connect(func() -> void:
		if not Game.modal_open:
			if Game.is_station_done(1):
				_player.walk_to(_props.gate_position + Vector3(0.0, 0.0, -1.2))
				Game.notify("Nara berjalan melewati Gerbang menuju Pos 2...", "info")
			else:
				_player.walk_to(_props.star_position)
				Game.notify("Nara berjalan menuju Papan Rahasia & Bintang Pos 1...", "info")
	)
	_hud.open_pos1_pressed.connect(func() -> void:
		if not Game.modal_open:
			_quiz.open_modal()
	)
	_hud.replay_story_pressed.connect(func() -> void:
		if not Game.modal_open:
			_story_intro.call("open_story")
	)

	# Mainkan BGM taman riang ramah anak
	Audio.play_music("bgm_garden", true)

	# Buka prolog cerita Nara secara otomatis saat pertama kali masuk Pos 1
	if not Game.pos1_intro_seen:
		call_deferred("_start_story_intro")
	else:
		Game.notify("Dekati Papan Rahasia & Bintang Pos 1 bersama Nara!", "info")


func _start_story_intro() -> void:
	_story_intro.call("open_story")


func _on_story_finished() -> void:
	_hud.set_mission_text("Misi: Dekati Papan Rahasia & Bintang Pos 1")
	Audio.show_subtitle("NARA • POS 1", "Ayo jalan ke Bintang Pos 1 di depan, lalu tekan E atau tombol Aksi!", "happy", 5.5, false)


func _process(delta: float) -> void:
	# Suara burung berkicau sesekali di taman
	_ambience_timer += delta
	if _ambience_timer >= 12.0:
		_ambience_timer = 0.0
		if randf() < 0.65:
			Audio.play_sfx("bird")


func _on_near_star_changed(is_near: bool) -> void:
	_near_star = is_near
	_hud.set_near_pos1(is_near)
	if is_near and not Game.modal_open:
		if not _near_star_voiced and not Game.is_station_done(1):
			_near_star_voiced = true
			Audio.play_voice("near_star", false, "NARA • POS 1: BINTANG EMOSI")


func _unhandled_input(event: InputEvent) -> void:
	if _near_star and not Game.modal_open and event.is_action_pressed("interact"):
		_quiz.open_modal()
		get_viewport().set_input_as_handled()


func _on_enter_pos2() -> void:
	if _transitioning:
		return
	_transitioning = true
	Audio.stop_voice()
	Audio.play_sfx("confirm")
	Game.notify("Memasuki Pos 2: Taman Bermain 6 Emosi Dasar!", "success")
	Router.go_to("res://scenes/worlds/Pos2_Taman6Emosi.tscn")
