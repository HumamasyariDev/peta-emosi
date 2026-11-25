class_name GameHUD
extends CanvasLayer

signal walk_to_pos1_pressed
signal open_pos1_pressed
signal replay_story_pressed

const EmotionPassportScript := preload("res://scripts/ui/emotion_passport.gd")
const PosMapModalScript := preload("res://scripts/ui/pos_map_modal.gd")
const TouchControlsScript := preload("res://scripts/ui/touch_controls.gd")

var _font_ui: Font
var _font_display: Font
var _progress_lbl: Label
var _star_pips: Array[Panel] = []
var _mission_lbl: Label
var _mission_tab: Panel
var _pos_badge_panel: PanelContainer
var _pos_badge_lbl: Label
var _coins_lbl: Label
var _sound_btn: Button
var _sound_icon_wrap: CenterContainer
var _analog_btn: Button
var _walk_btn: Button
var _open_btn: Button
var _story_btn: Button
var _toast_lbl: Label
var _toast_panel: PanelContainer
var _analog_hint_panel: PanelContainer
var _center_prompt_panel: PanelContainer
var _center_prompt_lbl: Label
var _stamps_bar: HBoxContainer
var _stamp_chips: Dictionary = {}
var _pos4_box: VBoxContainer
var _pos4_anger_bar: ProgressBar
var _pos4_anger_lbl: Label
var _pos4_step_chips: Array[Dictionary] = []
var _passport: CanvasLayer
var _pos_map: CanvasLayer
var _touch_controls: Control


func _ready() -> void:
	layer = 10
	_font_ui = StorybookUI.font_body(600)
	_font_display = StorybookUI.font_display()
	_build_hud()
	_touch_controls = TouchControlsScript.new()
	add_child(_touch_controls)
	_passport = EmotionPassportScript.new()
	add_child(_passport)
	_pos_map = PosMapModalScript.new()
	add_child(_pos_map)
	Game.progress_changed.connect(_refresh)
	Game.toast_requested.connect(_show_toast)
	_refresh()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch and not Game.is_mobile_browser:
		Game.is_mobile_browser = true
		_update_analog_hint()
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_B and _passport != null:
			_passport.call("toggle_passport")
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_M and _pos_map != null:
			_pos_map.call("toggle_map")
			get_viewport().set_input_as_handled()


func set_emotion_stamps_visible(is_vis: bool) -> void:
	if _stamps_bar != null:
		_stamps_bar.visible = is_vis
		_refresh_stamps()


func set_pos4_tracker_visible(is_vis: bool) -> void:
	if _pos4_box != null:
		_pos4_box.visible = is_vis


func update_pos4_tracker(completed_steps: int, anger_pct: int) -> void:
	if _pos4_anger_bar != null:
		_pos4_anger_bar.value = float(anger_pct)
		var fg := StyleBoxFlat.new()
		if anger_pct >= 65:
			fg.bg_color = StorybookUI.TERRACOTTA
		elif anger_pct >= 30:
			fg.bg_color = StorybookUI.HONEY
		else:
			fg.bg_color = StorybookUI.EMERALD
		fg.set_corner_radius_all(6)
		_pos4_anger_bar.add_theme_stylebox_override("fill", fg)
	if _pos4_anger_lbl != null:
		var mood := "Panas!" if anger_pct >= 65 else ("Mulai Reda" if anger_pct > 0 else "Sejuk & Damai!")
		_pos4_anger_lbl.text = "Suhu Hati: %d%% (%s)" % [anger_pct, mood]
	for i in range(_pos4_step_chips.size()):
		var info: Dictionary = _pos4_step_chips[i]
		var chip: PanelContainer = info["panel"] as PanelContainer
		var lbl: Label = info["label"] as Label
		var ic: Control = info["icon"] as Control
		var done := (i < completed_steps)
		var st := StorybookUI.make_panel_box(
			Color("e2f5e9") if done else StorybookUI.PAPER,
			StorybookUI.EMERALD if done else StorybookUI.WALNUT,
			9, 2, 3, 7, 2, false
		)
		chip.add_theme_stylebox_override("panel", st)
		lbl.text = str(info["text"])
		lbl.add_theme_color_override("font_color", StorybookUI.EMERALD_DARK if done else StorybookUI.INK_SOFT)
		if ic != null:
			ic.visible = done


func set_near_pos1(is_near: bool) -> void:
	if _open_btn != null:
		_open_btn.visible = is_near
	if _center_prompt_panel != null:
		_center_prompt_panel.visible = is_near and not Game.touch_controls_enabled
		if is_near and _center_prompt_lbl != null:
			_center_prompt_lbl.text = "[E] Buka Papan & Misi Pos 1"
	if _touch_controls != null:
		_touch_controls.call("set_interact_highlighted", is_near)


func set_interact_prompt(caption: String, show_btn: bool) -> void:
	if _open_btn != null:
		if not caption.is_empty():
			_open_btn.text = caption
		_open_btn.visible = show_btn
	if _center_prompt_panel != null:
		_center_prompt_panel.visible = show_btn and not Game.touch_controls_enabled
		if show_btn and _center_prompt_lbl != null and not caption.is_empty():
			_center_prompt_lbl.text = "[E] " + caption.replace(" (E)", "")
	if _touch_controls != null:
		_touch_controls.call("set_interact_highlighted", show_btn, caption)


func set_walk_caption(caption: String) -> void:
	if _walk_btn != null:
		_walk_btn.text = caption


func set_story_button_visible(is_vis: bool) -> void:
	if _story_btn != null:
		_story_btn.visible = is_vis


func set_mission_text(text: String) -> void:
	if _mission_lbl != null:
		_mission_lbl.text = text
	_refresh()


func _build_hud() -> void:
	var frame := Control.new()
	frame.set_anchors_preset(Control.PRESET_FULL_RECT)
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(frame)

	var root := MarginContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_theme_constant_override("margin_left", 20)
	root.add_theme_constant_override("margin_right", 20)
	root.add_theme_constant_override("margin_top", 16)
	root.add_theme_constant_override("margin_bottom", 16)
	frame.add_child(root)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(vbox)

	# === TOP ROW: Storybook Adventure Crest (Left) + Pouch & Controls (Right) ===
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 10)
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(top)

	var left_col := VBoxContainer.new()
	left_col.add_theme_constant_override("separation", 7)
	left_col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top.add_child(left_col)

	# 1. Tactile Star Progress Crest (with drawn Star + 8 visual star-pips)
	var star_plaque := PanelContainer.new()
	star_plaque.mouse_filter = Control.MOUSE_FILTER_IGNORE
	star_plaque.add_theme_stylebox_override("panel", StorybookUI.make_panel_box(
		StorybookUI.PAPER, StorybookUI.WALNUT, 14, 2, 5, 12, 7, true
	))
	left_col.add_child(star_plaque)

	var star_row := HBoxContainer.new()
	star_row.add_theme_constant_override("separation", 8)
	star_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	star_plaque.add_child(star_row)

	star_row.add_child(StorybookUI.make_icon("star", 24.0, StorybookUI.HONEY, StorybookUI.WALNUT))
	_progress_lbl = _label("0/8", 18, StorybookUI.INK, _font_display)
	star_row.add_child(_progress_lbl)

	var pips_row := HBoxContainer.new()
	pips_row.add_theme_constant_override("separation", 4)
	pips_row.alignment = BoxContainer.ALIGNMENT_CENTER
	pips_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	star_row.add_child(pips_row)
	for _i in range(8):
		var pip := Panel.new()
		pip.custom_minimum_size = Vector2(12, 12)
		pip.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		pip.mouse_filter = Control.MOUSE_FILTER_IGNORE
		pips_row.add_child(pip)
		_star_pips.append(pip)

	# 2. Bookmark Mission Strip (clean rounded accent pill inside padded card - zero sharp corner bleed!)
	var mission_card := PanelContainer.new()
	mission_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mission_card.add_theme_stylebox_override("panel", StorybookUI.make_panel_box(
		StorybookUI.PAPER_WARM, StorybookUI.WALNUT, 12, 2, 4, 10, 6, true
	))
	left_col.add_child(mission_card)

	var m_hbox := HBoxContainer.new()
	m_hbox.add_theme_constant_override("separation", 9)
	m_hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mission_card.add_child(m_hbox)

	_mission_tab = Panel.new()
	_mission_tab.custom_minimum_size = Vector2(7, 22)
	_mission_tab.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_mission_tab.mouse_filter = Control.MOUSE_FILTER_IGNORE
	m_hbox.add_child(_mission_tab)

	_mission_lbl = _label("Misi: Jalan ke Papan & Bintang Pos 1", 14, StorybookUI.INK)
	m_hbox.add_child(_mission_lbl)

	# 3. Pos 2 Compact 6-Emotion Stamp Tracker Bar
	_stamps_bar = HBoxContainer.new()
	_stamps_bar.add_theme_constant_override("separation", 5)
	_stamps_bar.visible = false
	_stamps_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	left_col.add_child(_stamps_bar)
	var emo_defs := [
		["sedih", "1.Sedih"], ["marah", "2.Marah"], ["takut", "3.Takut"],
		["bahagia", "4.Bahagia"], ["jijik", "5.Jijik"], ["terkejut", "6.Terkejut"]
	]
	for e in emo_defs:
		var chip := PanelContainer.new()
		chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var chb := HBoxContainer.new()
		chb.add_theme_constant_override("separation", 4)
		chb.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var cic := StorybookUI.make_icon("check", 12.0, StorybookUI.EMERALD_DARK, StorybookUI.EMERALD_DARK)
		cic.visible = false
		chb.add_child(cic)
		var lbl := _label(e[1], 12, StorybookUI.INK_SOFT)
		chb.add_child(lbl)
		chip.add_child(chb)
		_stamps_bar.add_child(chip)
		_stamp_chips[e[0]] = {"panel": chip, "label": lbl, "icon": cic, "text": e[1]}

	# 4. Pos 4 Anger Thermometer + 6-Step Tracker
	_pos4_box = VBoxContainer.new()
	_pos4_box.add_theme_constant_override("separation", 5)
	_pos4_box.visible = false
	_pos4_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	left_col.add_child(_pos4_box)

	var therm_pill := PanelContainer.new()
	therm_pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	therm_pill.add_theme_stylebox_override("panel", StorybookUI.make_panel_box(
		StorybookUI.PAPER, StorybookUI.LAGOON, 12, 2, 4, 12, 6, true
	))
	var tv := VBoxContainer.new()
	tv.add_theme_constant_override("separation", 4)
	tv.mouse_filter = Control.MOUSE_FILTER_IGNORE
	therm_pill.add_child(tv)
	_pos4_anger_lbl = _label("Suhu Hati: 100% (Panas!)", 13, StorybookUI.INK, _font_display)
	tv.add_child(_pos4_anger_lbl)
	_pos4_anger_bar = ProgressBar.new()
	_pos4_anger_bar.min_value = 0.0
	_pos4_anger_bar.max_value = 100.0
	_pos4_anger_bar.value = 100.0
	_pos4_anger_bar.show_percentage = false
	_pos4_anger_bar.custom_minimum_size = Vector2(215, 11)
	var tbg := StyleBoxFlat.new()
	tbg.bg_color = StorybookUI.PAPER_DEEP
	tbg.set_corner_radius_all(6)
	_pos4_anger_bar.add_theme_stylebox_override("background", tbg)
	tv.add_child(_pos4_anger_bar)
	_pos4_box.add_child(therm_pill)

	var p4_row := HBoxContainer.new()
	p4_row.add_theme_constant_override("separation", 4)
	p4_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_pos4_box.add_child(p4_row)
	for st_txt in ["1", "2", "3", "4", "5", "6"]:
		var schip := PanelContainer.new()
		schip.custom_minimum_size = Vector2(36, 24)
		schip.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var shb := HBoxContainer.new()
		shb.alignment = BoxContainer.ALIGNMENT_CENTER
		shb.add_theme_constant_override("separation", 2)
		shb.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var sic := StorybookUI.make_icon("check", 11.0, StorybookUI.EMERALD_DARK, StorybookUI.EMERALD_DARK)
		sic.visible = false
		shb.add_child(sic)
		var slbl := _label(st_txt, 12, StorybookUI.INK_SOFT, _font_display)
		slbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		shb.add_child(slbl)
		schip.add_child(shb)
		p4_row.add_child(schip)
		_pos4_step_chips.append({"panel": schip, "label": slbl, "icon": sic, "text": st_txt})

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top.add_child(spacer)

	# === TOP RIGHT: Pos Ribbon + Coin Pouch + Tactile Audio/Analog Toggles ===
	var right_row := HBoxContainer.new()
	right_row.add_theme_constant_override("separation", 8)
	right_row.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	right_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top.add_child(right_row)

	var pouch := PanelContainer.new()
	pouch.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pouch.add_theme_stylebox_override("panel", StorybookUI.make_panel_box(
		StorybookUI.PAPER, StorybookUI.WALNUT, 14, 2, 5, 8, 5, true
	))
	right_row.add_child(pouch)

	var pouch_hb := HBoxContainer.new()
	pouch_hb.add_theme_constant_override("separation", 8)
	pouch_hb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pouch.add_child(pouch_hb)

	_pos_badge_panel = PanelContainer.new()
	_pos_badge_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_pos_badge_lbl = _label("POS 1", 13, StorybookUI.CREAM, _font_display)
	_pos_badge_panel.add_child(_pos_badge_lbl)
	pouch_hb.add_child(_pos_badge_panel)

	pouch_hb.add_child(StorybookUI.make_icon("coin", 22.0, StorybookUI.HONEY, StorybookUI.WALNUT))
	_coins_lbl = _label("0", 17, StorybookUI.INK, _font_display)
	pouch_hb.add_child(_coins_lbl)

	# Analog Toggle with drawn icon
	_analog_btn = _icon_button("Analog: On" if Game.touch_controls_enabled else "Analog: Off", "gamepad",
		StorybookUI.LAGOON if Game.touch_controls_enabled else StorybookUI.PAPER_WARM,
		StorybookUI.LAGOON_DARK if Game.touch_controls_enabled else StorybookUI.WALNUT,
		StorybookUI.CREAM if Game.touch_controls_enabled else StorybookUI.INK
	)
	_analog_btn.pressed.connect(func() -> void:
		Audio.play_sfx("select")
		Game.touch_controls_enabled = not Game.touch_controls_enabled
		_style_analog_btn()
		if _touch_controls != null:
			_touch_controls.visible = Game.touch_controls_enabled and not Game.modal_open
		_update_analog_hint()
	)
	right_row.add_child(_analog_btn)

	# Sound Toggle with drawn icon
	_sound_btn = _icon_button("Suara", "sound_on", StorybookUI.HONEY, StorybookUI.WALNUT, StorybookUI.INK)
	_sound_btn.pressed.connect(func() -> void:
		var next_state := not Game.sound_enabled
		Game.sound_enabled = next_state
		Game.music_enabled = next_state
		_style_sound_btn()
		if next_state:
			Audio.play_sfx("pop")
			Audio.play_music("bgm_garden", true)
		else:
			Audio.stop_voice()
			Audio.stop_music()
	)
	right_row.add_child(_sound_btn)

	# Mobile reminder ribbon when Analog is off on Android/iOS
	_analog_hint_panel = PanelContainer.new()
	_analog_hint_panel.size_flags_horizontal = Control.SIZE_SHRINK_END
	_analog_hint_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_analog_hint_panel.add_theme_stylebox_override("panel", StorybookUI.make_panel_box(
		Color("fff3cd"), StorybookUI.HONEY, 12, 2, 4, 12, 6, true
	))
	var hint_lbl := _label("Ketuk tombol Analog di atas untuk menyalakan joystick!", 13, StorybookUI.INK)
	_analog_hint_panel.add_child(hint_lbl)
	vbox.add_child(_analog_hint_panel)
	_update_analog_hint()

	# Toast banner
	_toast_panel = PanelContainer.new()
	_toast_panel.visible = false
	_toast_panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_toast_panel.add_theme_stylebox_override("panel", StorybookUI.make_panel_box(
		StorybookUI.PAPER, StorybookUI.HONEY, 14, 3, 5, 18, 9, true
	))
	_toast_lbl = _label("", 16, StorybookUI.INK, _font_display)
	_toast_panel.add_child(_toast_lbl)
	vbox.add_child(_toast_panel)

	var mid_spacer := Control.new()
	mid_spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	mid_spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(mid_spacer)

	# Floating contextual [E] prompt right above bottom-left controls
	_center_prompt_panel = PanelContainer.new()
	_center_prompt_panel.visible = false
	_center_prompt_panel.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	_center_prompt_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_center_prompt_panel.add_theme_stylebox_override("panel", StorybookUI.make_panel_box(
		StorybookUI.EMERALD, StorybookUI.HONEY_LIGHT, 12, 2, 4, 14, 7, true
	))
	_center_prompt_lbl = _label("[E] Interaksi", 15, StorybookUI.CREAM, _font_display)
	_center_prompt_panel.add_child(_center_prompt_lbl)
	vbox.add_child(_center_prompt_panel)

	# === BOTTOM BAR: Wayfinder & Action (Left) + Adventure Map & Storybook (Right) ===
	var bottom := HBoxContainer.new()
	bottom.add_theme_constant_override("separation", 10)
	bottom.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(bottom)

	_walk_btn = Button.new()
	_walk_btn.text = "Jalan ke Bintang Pos 1"
	_walk_btn.custom_minimum_size = Vector2(0, 46)
	StorybookUI.style_tactile_button(_walk_btn, StorybookUI.BERRY, StorybookUI.BERRY_DARK, StorybookUI.CREAM, _font_display, 15, 14, 16, 8)
	_walk_btn.pressed.connect(func() -> void:
		Audio.play_sfx("select")
		walk_to_pos1_pressed.emit()
	)
	bottom.add_child(_walk_btn)

	_open_btn = Button.new()
	_open_btn.text = "Buka Papan & Misi Pos 1 (E)"
	_open_btn.custom_minimum_size = Vector2(0, 46)
	_open_btn.visible = false
	StorybookUI.style_tactile_button(_open_btn, StorybookUI.EMERALD, StorybookUI.EMERALD_DARK, StorybookUI.CREAM, _font_display, 15, 14, 16, 8)
	_open_btn.pressed.connect(func() -> void:
		Audio.play_sfx("confirm")
		open_pos1_pressed.emit()
	)
	bottom.add_child(_open_btn)

	var b_spacer := Control.new()
	b_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b_spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bottom.add_child(b_spacer)

	var map_btn := _icon_button("Peta Pos (M)", "compass", StorybookUI.LAGOON, StorybookUI.LAGOON_DARK, StorybookUI.CREAM)
	map_btn.pressed.connect(func() -> void:
		if _pos_map != null:
			_pos_map.call("toggle_map")
	)
	bottom.add_child(map_btn)

	_story_btn = _icon_button("Cerita Nara", "book", StorybookUI.PAPER, StorybookUI.WALNUT, StorybookUI.INK)
	_story_btn.pressed.connect(func() -> void:
		Audio.play_sfx("select")
		replay_story_pressed.emit()
	)
	bottom.add_child(_story_btn)


func _icon_button(text: String, icon_kind: String, bg: Color, border: Color, fg: Color) -> Button:
	var b := Button.new()
	b.text = ""
	b.custom_minimum_size = Vector2(0, 44)
	StorybookUI.style_tactile_button(b, bg, border, fg, _font_display, 14, 13, 12, 6)

	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 7)
	hb.alignment = BoxContainer.ALIGNMENT_CENTER
	hb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hb.set_anchors_preset(Control.PRESET_FULL_RECT)
	b.add_child(hb)

	var icon_wrap := CenterContainer.new()
	icon_wrap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon_wrap.add_child(StorybookUI.make_icon(icon_kind, 20.0, StorybookUI.HONEY if icon_kind != "sound_on" else StorybookUI.INK, StorybookUI.WALNUT))
	hb.add_child(icon_wrap)
	if icon_kind == "sound_on":
		_sound_icon_wrap = icon_wrap

	var lbl := _label(text, 14, fg, _font_display)
	lbl.name = "BtnCaption"
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hb.add_child(lbl)

	# Give the button enough minimum width for icon + text
	b.custom_minimum_size.x = maxf(108.0, float(text.length()) * 9.5 + 48.0)
	return b


func _style_analog_btn() -> void:
	if _analog_btn == null:
		return
	var on := Game.touch_controls_enabled
	var bg := StorybookUI.LAGOON if on else StorybookUI.PAPER_WARM
	var bd := StorybookUI.LAGOON_DARK if on else StorybookUI.WALNUT
	var fg := StorybookUI.CREAM if on else StorybookUI.INK
	StorybookUI.style_tactile_button(_analog_btn, bg, bd, fg, _font_display, 14, 13, 12, 6)
	var lbl := _analog_btn.find_child("BtnCaption", true, false) as Label
	if lbl != null:
		lbl.text = "Analog: On" if on else "Analog: Off"
		lbl.add_theme_color_override("font_color", fg)


func _style_sound_btn() -> void:
	if _sound_btn == null:
		return
	var on := Game.sound_enabled
	var bg := StorybookUI.HONEY if on else StorybookUI.PAPER_DEEP
	var bd := StorybookUI.WALNUT
	var fg := StorybookUI.INK if on else StorybookUI.INK_SOFT
	StorybookUI.style_tactile_button(_sound_btn, bg, bd, fg, _font_display, 14, 13, 12, 6)
	var lbl := _sound_btn.find_child("BtnCaption", true, false) as Label
	if lbl != null:
		lbl.text = "Suara" if on else "Bisu"
		lbl.add_theme_color_override("font_color", fg)
	if _sound_icon_wrap != null:
		for c in _sound_icon_wrap.get_children():
			c.queue_free()
		_sound_icon_wrap.add_child(StorybookUI.make_icon("sound_on" if on else "sound_off", 20.0, fg, StorybookUI.BERRY if not on else StorybookUI.WALNUT))


func _process(_delta: float) -> void:
	_update_analog_hint()


func _update_analog_hint() -> void:
	if _analog_hint_panel != null:
		_analog_hint_panel.visible = Game.is_mobile_browser and not Game.touch_controls_enabled and not Game.modal_open


func _refresh() -> void:
	var done_count := Game.get_completed_count()
	if _progress_lbl != null:
		_progress_lbl.text = "%d/8" % done_count
	for i in range(_star_pips.size()):
		var pip := _star_pips[i]
		var filled := Game.is_station_done(i + 1)
		var ps := StyleBoxFlat.new()
		ps.bg_color = StorybookUI.HONEY if filled else StorybookUI.PAPER_DEEP
		ps.border_color = StorybookUI.WALNUT if filled else Color(0.56, 0.44, 0.32, 0.65)
		ps.set_border_width_all(2)
		ps.set_corner_radius_all(6)
		pip.add_theme_stylebox_override("panel", ps)

	var accent := StorybookUI.pos_accent(Game.current_zone)
	if _mission_tab != null:
		var tab_st := StyleBoxFlat.new()
		tab_st.bg_color = accent["bg"]
		tab_st.set_corner_radius_all(4)
		_mission_tab.add_theme_stylebox_override("panel", tab_st)
	if _pos_badge_panel != null:
		_pos_badge_panel.add_theme_stylebox_override("panel", StorybookUI.make_panel_box(
			accent["bg"], accent["dark"], 9, 2, 3, 10, 3, false
		))
	if _pos_badge_lbl != null:
		_pos_badge_lbl.text = accent["tag"]
	if _coins_lbl != null:
		_coins_lbl.text = "%d" % Game.coins
	if _walk_btn != null:
		StorybookUI.style_tactile_button(_walk_btn, accent["bg"], accent["dark"], StorybookUI.CREAM, _font_display, 15, 14, 16, 8)

	if _mission_lbl != null and Game.current_zone == "Pos 1" and Game.is_station_done(1):
		_mission_lbl.text = "Misi: Pos 1 Selesai! Masuk Gerbang Pos 2"
		if _walk_btn != null:
			_walk_btn.text = "Jalan ke Gerbang Pos 2"
	_refresh_stamps()


func _refresh_stamps() -> void:
	for id: String in _stamp_chips.keys():
		var info: Dictionary = _stamp_chips[id]
		var chip: PanelContainer = info["panel"] as PanelContainer
		var lbl: Label = info["label"] as Label
		var ic: Control = info["icon"] as Control
		var done: bool = Game.collected_emotions.has(id)
		var st := StorybookUI.make_panel_box(
			Color("e2f5e9") if done else StorybookUI.PAPER,
			StorybookUI.EMERALD if done else StorybookUI.WALNUT,
			9, 2, 3, 8, 3, false
		)
		chip.add_theme_stylebox_override("panel", st)
		lbl.text = str(info["text"])
		lbl.add_theme_color_override("font_color", StorybookUI.EMERALD_DARK if done else StorybookUI.INK_SOFT)
		if ic != null:
			ic.visible = done


func _show_toast(message: String, _kind: String) -> void:
	_toast_lbl.text = message
	_toast_panel.visible = true
	var timer := get_tree().create_timer(3.2)
	timer.timeout.connect(func() -> void:
		if is_instance_valid(_toast_panel):
			_toast_panel.visible = false
	)


func _label(text: String, size: int, col: Color, custom_font: Font = null) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", custom_font if custom_font != null else _font_ui)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	return l
