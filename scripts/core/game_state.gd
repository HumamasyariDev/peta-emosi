extends Node

signal progress_changed
signal pos1_quiz_requested
signal toast_requested(message: String, kind: String)

const SAVE_PATH := "user://peta_emosi_save.json"
const WEB_SAVE_KEY := "peta_emosi_save_v1"

const STATION_SCENES := {
	1: "res://scenes/worlds/Pos1_GerbangPengenalan.tscn",
	2: "res://scenes/worlds/Pos2_Taman6Emosi.tscn",
	3: "res://scenes/worlds/Pos3_AturanEmosi.tscn",
	4: "res://scenes/worlds/Pos4_6LangkahTenang.tscn",
	5: "res://scenes/worlds/Pos5_PukulBantalSobekKertas.tscn",
	6: "res://scenes/worlds/Pos6_MelihatTemanMarah.tscn",
	7: "res://scenes/worlds/Pos7_PrinsipSaatMarah.tscn",
	8: "res://scenes/worlds/Pos8_FinishAkuTahuEmosiku.tscn",
}

var completed_stations: Dictionary = {}
var collected_emotions: Dictionary = {}
var coins: int = 0
var hearts: int = 0
var current_zone: String = "Gerbang Start (Pos 1)"
var sound_enabled: bool = true
var music_enabled: bool = true
var modal_open: bool = false
var voice_briefing_active: bool = false
var pos1_intro_seen: bool = false
var virtual_move: Vector2 = Vector2.ZERO
var joystick_touch_index: int = -1
var is_mobile_browser: bool = false
var touch_controls_enabled: bool = false
var _symbol_font: FontFile


func _ready() -> void:
	_install_symbol_font_fallbacks()
	load_progress()
	is_mobile_browser = _detect_mobile_device()
	touch_controls_enabled = is_mobile_browser
	if OS.has_feature("web"):
		_configure_hd_viewport(get_tree().root)
		get_tree().node_added.connect(_on_web_node_added)
		call_deferred("_tune_web_tree", get_tree().root)


func _configure_hd_viewport(vp: Viewport) -> void:
	if vp == null:
		return
	vp.scaling_3d_scale = 1.0
	vp.msaa_2d = Viewport.MSAA_4X
	vp.msaa_3d = Viewport.MSAA_2X if is_mobile_browser else Viewport.MSAA_4X
	vp.anisotropic_filtering_level = Viewport.ANISOTROPY_8X if is_mobile_browser else Viewport.ANISOTROPY_16X
	vp.use_debanding = true


func _detect_mobile_device() -> bool:
	if OS.has_feature("web"):
		var js := "Boolean(/Android|iPhone|iPad|iPod|Mobile/i.test(navigator.userAgent || '') || (navigator.maxTouchPoints > 0 && window.matchMedia && window.matchMedia('(pointer: coarse)').matches))"
		var res: Variant = JavaScriptBridge.eval(js, true)
		return bool(res)
	if OS.get_name() in ["Android", "iOS"]:
		return true
	return false


func _install_symbol_font_fallbacks() -> void:
	_symbol_font = load("res://assets/fonts/symbols/Symbols.ttf") as FontFile
	if _symbol_font == null:
		return
	for path: String in [
		"res://assets/fonts/fredoka/Fredoka-Variable.ttf",
		"res://assets/fonts/lilita/LilitaOne-Regular.ttf",
		"res://assets/fonts/cherryswash/CherrySwash-Bold.ttf",
	]:
		var f := load(path) as FontFile
		if f != null:
			var fbs: Array[Font] = f.fallbacks.duplicate()
			if not fbs.has(_symbol_font):
				fbs.append(_symbol_font)
				f.fallbacks = fbs
	var def_font := ThemeDB.fallback_font
	if def_font is FontFile:
		var df := def_font as FontFile
		var dfbs: Array[Font] = df.fallbacks.duplicate()
		if not dfbs.has(_symbol_font):
			dfbs.append(_symbol_font)
			df.fallbacks = dfbs


func _on_web_node_added(node: Node) -> void:
	if node is WorldEnvironment or node is DirectionalLight3D or node is Label3D:
		call_deferred("_apply_web_visual_calibration", node)


func _tune_web_tree(root: Node) -> void:
	if root == null:
		return
	for child in root.get_children():
		if child is WorldEnvironment or child is DirectionalLight3D or child is Label3D:
			_apply_web_visual_calibration(child)
		_tune_web_tree(child)


func _apply_web_visual_calibration(node: Node) -> void:
	if not is_instance_valid(node) or node.has_meta("web_calibrated"):
		return
	node.set_meta("web_calibrated", true)
	if node is WorldEnvironment:
		var we := node as WorldEnvironment
		if we.environment != null:
			var env := we.environment.duplicate() as Environment
			env.ambient_light_energy = 0.46
			env.ambient_light_sky_contribution = 0.72
			env.tonemap_exposure = 1.0
			env.adjustment_enabled = true
			env.adjustment_brightness = 1.02
			env.adjustment_contrast = 1.06
			env.adjustment_saturation = 1.12
			we.environment = env
	elif node is DirectionalLight3D:
		var sun := node as DirectionalLight3D
		sun.shadow_enabled = true
		sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS
		sun.directional_shadow_blend_splits = true
		sun.directional_shadow_max_distance = 58.0
		sun.shadow_bias = 0.03
		sun.shadow_normal_bias = 1.2
		sun.shadow_blur = 1.4
	elif node is Label3D:
		var lbl := node as Label3D
		lbl.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC


func is_station_done(station_id: int) -> bool:
	return completed_stations.has(station_id)


func add_coins(amount: int) -> void:
	coins += amount
	save_progress()
	progress_changed.emit()


func collect_emotion(emotion_id: String) -> void:
	if not collected_emotions.has(emotion_id):
		collected_emotions[emotion_id] = true
		save_progress()
		progress_changed.emit()


func complete_station(station_id: int, reward_coins: int = 15, reward_hearts: int = 1) -> void:
	if not completed_stations.has(station_id):
		completed_stations[station_id] = true
		coins += reward_coins
		hearts += reward_hearts
		save_progress()
		progress_changed.emit()


func get_completed_count() -> int:
	return completed_stations.size()


func has_save() -> bool:
	return completed_stations.size() > 0 or coins > 0 or collected_emotions.size() > 0


func get_continue_scene() -> String:
	for i in range(1, 9):
		if not completed_stations.has(i):
			return str(STATION_SCENES[i])
	return str(STATION_SCENES[8])


func save_progress() -> void:
	var comp_list: Array = []
	for k in completed_stations.keys():
		comp_list.append(int(k))
	var emo_list: Array = []
	for k in collected_emotions.keys():
		emo_list.append(str(k))
	var payload := {
		"v": 1,
		"completed": comp_list,
		"emotions": emo_list,
		"coins": coins,
		"hearts": hearts,
		"pos1_intro_seen": pos1_intro_seen,
		"sound_enabled": sound_enabled,
		"music_enabled": music_enabled,
	}
	var json_str := JSON.stringify(payload)
	if OS.has_feature("web"):
		JavaScriptBridge.eval("try { window.localStorage.setItem('%s', %s); } catch(e) {}" % [WEB_SAVE_KEY, JSON.stringify(json_str)], true)
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f != null:
		f.store_string(json_str)
		f.close()


func load_progress() -> void:
	var raw := ""
	if OS.has_feature("web"):
		var res: Variant = JavaScriptBridge.eval("try { window.localStorage.getItem('%s') || ''; } catch(e) { '' }" % WEB_SAVE_KEY, true)
		if res is String:
			raw = res
	if raw.is_empty() and FileAccess.file_exists(SAVE_PATH):
		var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
		if f != null:
			raw = f.get_as_text()
			f.close()
	if raw.is_empty():
		return
	var parsed: Variant = JSON.parse_string(raw)
	if not (parsed is Dictionary):
		return
	var d := parsed as Dictionary
	completed_stations.clear()
	for k in d.get("completed", []):
		completed_stations[int(k)] = true
	collected_emotions.clear()
	for k in d.get("emotions", []):
		collected_emotions[str(k)] = true
	coins = int(d.get("coins", 0))
	hearts = int(d.get("hearts", 0))
	pos1_intro_seen = bool(d.get("pos1_intro_seen", false))
	sound_enabled = bool(d.get("sound_enabled", true))
	music_enabled = bool(d.get("music_enabled", true))


func reset_progress() -> void:
	completed_stations.clear()
	collected_emotions.clear()
	coins = 0
	hearts = 0
	pos1_intro_seen = false
	voice_briefing_active = false
	if OS.has_feature("web"):
		JavaScriptBridge.eval("try { window.localStorage.removeItem('%s'); } catch(e) {}" % WEB_SAVE_KEY, true)
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
	progress_changed.emit()


func request_pos1_quiz() -> void:
	pos1_quiz_requested.emit()


func notify(message: String, kind: String = "info") -> void:
	toast_requested.emit(message, kind)


func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F11:
		var mode := DisplayServer.window_get_mode()
		if mode == DisplayServer.WINDOW_MODE_FULLSCREEN or mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		else:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		get_viewport().set_input_as_handled()

