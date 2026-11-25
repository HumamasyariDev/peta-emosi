class_name SubtitleBar
extends CanvasLayer

## Global Synced Subtitle & Voice-Briefing Bar.
## - Uses PRESET_FULL_RECT + VBoxContainer(ALIGNMENT_END) so it ALWAYS renders cleanly INSIDE
##   the viewport right above the bottom HUD button row (NEVER off-screen and NEVER overlapping HUD/Nara!).
## - Automatically lifts higher on mobile when Touch Controls are active.
## - Automatically hides whenever a full-screen modal dialog (StoryIntro, Quiz, Piagam) is open.
## - Displays Nara portrait, exact synced subtitle text, live audio progress bar,
##   Replay ("Ulangi") button, and "Siap!" skip button during voice briefing.

signal replay_requested
signal briefing_skipped

const NaraPortraitScript := preload("res://scripts/ui/nara_portrait.gd")

var _font_ui: Font
var _font_display: Font
var _margin: MarginContainer
var _panel: PanelContainer
var _tag_panel: PanelContainer
var _portrait: Control
var _header_lbl: Label
var _text_lbl: Label
var _progress_bar: ProgressBar
var _replay_btn: Button
var _skip_btn: Button
var _wave_bars: Array[ColorRect] = []

var _active: bool = false
var _is_briefing: bool = false
var _auto_hide_timer: float = 0.0
var _t: float = 0.0
var _tween: Tween


func _ready() -> void:
	layer = 16
	_font_ui = StorybookUI.font_body(600)
	_font_display = StorybookUI.font_display()
	_build_ui()
	_panel.visible = false


func show_subtitle(speaker: String, text: String, expr: String = "happy", is_briefing: bool = false, fallback_dur: float = 5.5, show_replay: bool = true) -> void:
	if text.strip_edges().is_empty():
		return
	var accent := StorybookUI.pos_accent(Game.current_zone)
	if _tag_panel != null:
		_tag_panel.add_theme_stylebox_override("panel", StorybookUI.make_panel_box(
			accent["bg"], accent["dark"], 7, 2, 2, 9, 2, false
		))
	_header_lbl.text = speaker if not speaker.is_empty() else "NARA"
	_text_lbl.text = text
	if _portrait != null and _portrait.has_method("set_expression"):
		_portrait.call("set_expression", expr)

	_is_briefing = is_briefing
	_skip_btn.visible = is_briefing
	_replay_btn.visible = show_replay
	_auto_hide_timer = maxf(2.5, fallback_dur)
	_active = true
	_update_bottom_margin()
	_panel.visible = not Game.modal_open
	set_progress(0.0)

	if _tween != null and _tween.is_running():
		_tween.kill()
	_panel.modulate.a = 0.0
	_tween = create_tween()
	_tween.tween_property(_panel, "modulate:a", 1.0, 0.16)


func set_progress(ratio: float) -> void:
	if _progress_bar == null:
		return
	_progress_bar.value = clampf(ratio, 0.0, 1.0) * 100.0


func mark_voice_finished() -> void:
	_is_briefing = false
	if _skip_btn != null:
		_skip_btn.visible = false
	set_progress(1.0)
	_auto_hide_timer = minf(_auto_hide_timer, 1.4)


func hide_subtitle() -> void:
	_active = false
	_is_briefing = false
	if _skip_btn != null:
		_skip_btn.visible = false
	if _panel == null or not _panel.visible:
		return
	if _tween != null and _tween.is_running():
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(_panel, "modulate:a", 0.0, 0.18)
	await _tween.finished
	if not _active and is_instance_valid(_panel):
		_panel.visible = false


func _unhandled_input(event: InputEvent) -> void:
	if not _active or not _is_briefing or Game.modal_open:
		return
	if event.is_action_pressed("jump") or event.is_action_pressed("ui_accept"):
		briefing_skipped.emit()
		get_viewport().set_input_as_handled()


func _process(delta: float) -> void:
	if not _active:
		return
	_t += delta
	_update_bottom_margin()
	_panel.visible = not Game.modal_open

	var speaking := Audio.is_voice_playing()
	for i in range(_wave_bars.size()):
		var b := _wave_bars[i]
		var h := (4.0 + absf(sin(_t * 9.5 + float(i) * 1.2)) * 10.0) if speaking else 3.0
		b.custom_minimum_size.y = h

	if speaking:
		set_progress(Audio.get_voice_progress())
	else:
		_auto_hide_timer -= delta
		if _auto_hide_timer <= 0.0:
			hide_subtitle()


func _update_bottom_margin() -> void:
	if _margin == null:
		return
	# 74px clears the entire bottom HUD button row cleanly; 112px clears mobile touch controls!
	var target_mb := 112 if Game.touch_controls_enabled else 74
	if _margin.get_theme_constant("margin_bottom") != target_mb:
		_margin.add_theme_constant_override("margin_bottom", target_mb)


func _build_ui() -> void:
	# CRITICAL: PRESET_FULL_RECT + VBoxContainer(ALIGNMENT_END) anchors INSIDE viewport!
	_margin = MarginContainer.new()
	_margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_margin.add_theme_constant_override("margin_bottom", 74)
	_margin.add_theme_constant_override("margin_left", 24)
	_margin.add_theme_constant_override("margin_right", 24)
	_margin.add_theme_constant_override("margin_top", 20)
	add_child(_margin)

	var v_bottom := VBoxContainer.new()
	v_bottom.alignment = BoxContainer.ALIGNMENT_END
	v_bottom.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_margin.add_child(v_bottom)

	var center := HBoxContainer.new()
	center.alignment = BoxContainer.ALIGNMENT_CENTER
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v_bottom.add_child(center)

	_panel = PanelContainer.new()
	_panel.custom_minimum_size = Vector2(580, 76)
	_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_panel.add_theme_stylebox_override("panel", StorybookUI.make_panel_box(
		StorybookUI.PAPER, StorybookUI.WALNUT, 18, 3, 6, 12, 8, true
	))
	center.add_child(_panel)

	var outer_v := VBoxContainer.new()
	outer_v.add_theme_constant_override("separation", 6)
	_panel.add_child(outer_v)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 10)
	outer_v.add_child(hbox)

	var avatar_ring := PanelContainer.new()
	avatar_ring.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	avatar_ring.add_theme_stylebox_override("panel", StorybookUI.make_panel_box(
		StorybookUI.PAPER_WARM, StorybookUI.HONEY, 30, 2, 3, 2, 2, false
	))
	hbox.add_child(avatar_ring)

	_portrait = NaraPortraitScript.new()
	_portrait.custom_minimum_size = Vector2(50, 50)
	avatar_ring.add_child(_portrait)

	var text_col := VBoxContainer.new()
	text_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_col.alignment = BoxContainer.ALIGNMENT_CENTER
	text_col.add_theme_constant_override("separation", 3)
	hbox.add_child(text_col)

	var top_row := HBoxContainer.new()
	top_row.add_theme_constant_override("separation", 6)
	text_col.add_child(top_row)

	_tag_panel = PanelContainer.new()
	_tag_panel.add_theme_stylebox_override("panel", StorybookUI.make_panel_box(
		StorybookUI.BERRY, StorybookUI.BERRY_DARK, 7, 2, 2, 9, 2, false
	))
	top_row.add_child(_tag_panel)

	_header_lbl = Label.new()
	_header_lbl.text = "NARA"
	_header_lbl.add_theme_font_override("font", _font_display)
	_header_lbl.add_theme_font_size_override("font_size", 11)
	_header_lbl.add_theme_color_override("font_color", StorybookUI.CREAM)
	_tag_panel.add_child(_header_lbl)

	var wave_box := HBoxContainer.new()
	wave_box.alignment = BoxContainer.ALIGNMENT_CENTER
	wave_box.add_theme_constant_override("separation", 2)
	top_row.add_child(wave_box)
	for _i in range(4):
		var bar := ColorRect.new()
		bar.color = StorybookUI.EMERALD
		bar.custom_minimum_size = Vector2(3, 6)
		bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		wave_box.add_child(bar)
		_wave_bars.append(bar)

	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_row.add_child(sp)

	# Compact Replay Audio mini-button
	_replay_btn = Button.new()
	_replay_btn.text = ""
	_replay_btn.custom_minimum_size = Vector2(82, 26)
	StorybookUI.style_tactile_button(_replay_btn, StorybookUI.PAPER_WARM, StorybookUI.WALNUT, StorybookUI.INK, _font_display, 11, 8, 6, 2)
	var rhb := HBoxContainer.new()
	rhb.set_anchors_preset(Control.PRESET_FULL_RECT)
	rhb.alignment = BoxContainer.ALIGNMENT_CENTER
	rhb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rhb.add_theme_constant_override("separation", 4)
	rhb.add_child(StorybookUI.make_icon("sound_on", 13.0, StorybookUI.INK, StorybookUI.WALNUT))
	var rlbl := Label.new()
	rlbl.text = "Ulangi"
	rlbl.add_theme_font_override("font", _font_display)
	rlbl.add_theme_font_size_override("font_size", 11)
	rlbl.add_theme_color_override("font_color", StorybookUI.INK)
	rhb.add_child(rlbl)
	_replay_btn.add_child(rhb)
	_replay_btn.pressed.connect(func() -> void: replay_requested.emit())
	top_row.add_child(_replay_btn)

	# "Siap!" skip-briefing button (visible only while briefing pause is active!)
	_skip_btn = Button.new()
	_skip_btn.text = ""
	_skip_btn.custom_minimum_size = Vector2(86, 26)
	_skip_btn.visible = false
	StorybookUI.style_tactile_button(_skip_btn, StorybookUI.EMERALD, StorybookUI.EMERALD_DARK, StorybookUI.CREAM, _font_display, 11, 8, 6, 2)
	var shb := HBoxContainer.new()
	shb.set_anchors_preset(Control.PRESET_FULL_RECT)
	shb.alignment = BoxContainer.ALIGNMENT_CENTER
	shb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shb.add_theme_constant_override("separation", 4)
	var slbl := Label.new()
	slbl.text = "Siap!"
	slbl.add_theme_font_override("font", _font_display)
	slbl.add_theme_font_size_override("font_size", 11)
	slbl.add_theme_color_override("font_color", StorybookUI.CREAM)
	shb.add_child(slbl)
	shb.add_child(StorybookUI.make_icon("play_right", 11.0, StorybookUI.CREAM, StorybookUI.EMERALD_DARK))
	_skip_btn.add_child(shb)
	_skip_btn.pressed.connect(func() -> void: briefing_skipped.emit())
	top_row.add_child(_skip_btn)

	_text_lbl = Label.new()
	_text_lbl.text = ""
	_text_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text_lbl.custom_minimum_size = Vector2(480, 0)
	_text_lbl.add_theme_font_override("font", _font_ui)
	_text_lbl.add_theme_font_size_override("font_size", 15)
	_text_lbl.add_theme_color_override("font_color", StorybookUI.INK)
	text_col.add_child(_text_lbl)

	# Slim synced rounded voice progress bar along the bottom edge
	_progress_bar = ProgressBar.new()
	_progress_bar.min_value = 0.0
	_progress_bar.max_value = 100.0
	_progress_bar.value = 0.0
	_progress_bar.show_percentage = false
	_progress_bar.custom_minimum_size = Vector2(0, 6)
	var pbg := StyleBoxFlat.new()
	pbg.bg_color = StorybookUI.PAPER_DEEP
	pbg.set_corner_radius_all(3)
	var pfg := StyleBoxFlat.new()
	pfg.bg_color = StorybookUI.HONEY
	pfg.set_corner_radius_all(3)
	_progress_bar.add_theme_stylebox_override("background", pbg)
	_progress_bar.add_theme_stylebox_override("fill", pfg)
	outer_v.add_child(_progress_bar)
