class_name StoryIntroPos1
extends CanvasLayer

signal finished

const NaraPortraitScript := preload("res://scripts/ui/nara_portrait.gd")

var _font: Font
var _font_display: Font
var _backdrop: ColorRect
var _flash_rect: ColorRect
var _dialog_card: PanelContainer
var _portrait: Control
var _name_tag: Label
var _step_badge: Label
var _chapter_title: Label
var _story_lbl: Label
var _dots_box: HBoxContainer
var _back_btn: Button
var _next_btn: Button
var _next_lbl: Label
var _next_icon_holder: CenterContainer
var _skip_btn: Button

var _slide_idx: int = 0
var _slides: Array[Dictionary] = []
var _typing_tween: Tween


func _ready() -> void:
	layer = 25
	_font = StorybookUI.font_body(580)
	_font_display = StorybookUI.font_display()
	_init_slides()
	_build_ui()
	visible = false


func _init_slides() -> void:
	_slides = [
		{
			"badge": "CERITA 1 / 4",
			"title": "Pagi yang Penuh Rasa di Taman",
			"expr": "happy",
			"voice": "story_1",
			"sfx": "",
			"text": "Halo teman-teman! Namaku Nara.\nHari ini aku mau menjelajahi Taman Peta Emosi. Tapi... tadi pagi hatiku rasanya campur aduk sekali!"
		},
		{
			"badge": "CERITA 2 / 4",
			"title": "Kejutan Manis Pensil Warna",
			"expr": "excited",
			"voice": "story_2",
			"sfx": "sparkle",
			"text": "Pertama, Ibu memberiku kotak pensil warna baru!\nRasanya hangat di dada dan senang sekali, sampai aku ingin melompat kegirangan!"
		},
		{
			"badge": "CERITA 3 / 4",
			"title": "Suara Petir DUAR & Balok Jatuh",
			"expr": "surprised",
			"voice": "story_3",
			"sfx": "thunder",
			"text": "Tiba-tiba ada suara petir keras: DUAR!\nJantungku langsung deg-degan kaget. Balok mainanku tersenggol jatuh... mukaku jadi cemberut dan kesal."
		},
		{
			"badge": "CERITA 4 / 4",
			"title": "Misi Rahasia di Bintang Pos 1",
			"expr": "curious",
			"voice": "story_4",
			"sfx": "sparkle",
			"text": "Kenapa ya pikiran, dada, dan tubuhku bisa berubah-ubah seperti itu?\nLihat, di depan ada Papan Rahasia dan Bintang Pos 1! Ayo kita cari jawabannya bersama!"
		}
	]


func open_story() -> void:
	Game.modal_open = true
	_slide_idx = 0
	visible = true
	Audio.play_music("bgm_story", true)
	_render_slide()

	_backdrop.modulate.a = 0.0
	_dialog_card.modulate.a = 0.0
	_dialog_card.position.y += 24.0
	var tw := create_tween().set_parallel(true)
	tw.tween_property(_backdrop, "modulate:a", 1.0, 0.2)
	tw.tween_property(_dialog_card, "modulate:a", 1.0, 0.22)
	tw.tween_property(_dialog_card, "position:y", _dialog_card.position.y - 24.0, 0.26).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func close_story() -> void:
	if _typing_tween != null and _typing_tween.is_running():
		_typing_tween.kill()
	Audio.stop_voice()
	Audio.play_music("bgm_garden", true)
	visible = false
	Game.modal_open = false
	Game.pos1_intro_seen = true
	Game.save_progress()
	finished.emit()


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel"):
		Audio.play_sfx("select")
		close_story()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_accept"):
		_on_next()
		get_viewport().set_input_as_handled()


func _build_ui() -> void:
	# 1. Dim Backdrop
	_backdrop = ColorRect.new()
	_backdrop.color = Color(0.05, 0.07, 0.12, 0.48)
	_backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_backdrop)

	# Dramatic lightning flash layer (for Slide 3 thunder strike!)
	_flash_rect = ColorRect.new()
	_flash_rect.color = Color(0.96, 0.98, 1.0, 0.0)
	_flash_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_flash_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_flash_rect)

	# 2. Outer Layout Container pinned to bottom-center (Storybook VN Dialog Style)
	var screen_margin := MarginContainer.new()
	screen_margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	screen_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	screen_margin.add_theme_constant_override("margin_left", 36)
	screen_margin.add_theme_constant_override("margin_right", 36)
	screen_margin.add_theme_constant_override("margin_bottom", 28)
	screen_margin.add_theme_constant_override("margin_top", 20)
	_backdrop.add_child(screen_margin)

	var v_box_align := VBoxContainer.new()
	v_box_align.alignment = BoxContainer.ALIGNMENT_END
	v_box_align.mouse_filter = Control.MOUSE_FILTER_IGNORE
	screen_margin.add_child(v_box_align)

	# Skip Story button on top-right floating neatly
	var top_float := HBoxContainer.new()
	top_float.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v_box_align.add_child(top_float)

	var top_spacer := Control.new()
	top_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top_float.add_child(top_spacer)

	_skip_btn = _button("", Color(0.18, 0.20, 0.26, 0.90), Color(0.35, 0.38, 0.46), Color.WHITE, 14)
	_skip_btn.custom_minimum_size = Vector2(146, 38)
	var skip_hb := HBoxContainer.new()
	skip_hb.set_anchors_preset(Control.PRESET_FULL_RECT)
	skip_hb.alignment = BoxContainer.ALIGNMENT_CENTER
	skip_hb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	skip_hb.add_theme_constant_override("separation", 7)
	skip_hb.add_child(_label("Lewati Cerita", 14, Color.WHITE))
	skip_hb.add_child(StorybookUI.make_icon("close_x", 14.0, Color.WHITE, Color.WHITE))
	_skip_btn.add_child(skip_hb)
	_skip_btn.pressed.connect(func() -> void:
		Audio.play_sfx("select")
		close_story()
	)
	top_float.add_child(_skip_btn)

	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, 10)
	gap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v_box_align.add_child(gap)

	# 3. Main Storybook Dialog Card (Horizontal layout: Portrait column | Text & Actions column)
	var card_center := HBoxContainer.new()
	card_center.alignment = BoxContainer.ALIGNMENT_CENTER
	card_center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v_box_align.add_child(card_center)

	_dialog_card = PanelContainer.new()
	_dialog_card.custom_minimum_size = Vector2(860, 220)
	var st := StyleBoxFlat.new()
	st.bg_color = Color(1.0, 0.992, 0.965)
	st.border_color = Color(0.92, 0.60, 0.08)
	st.set_border_width_all(3)
	st.border_width_bottom = 6
	st.set_corner_radius_all(24)
	st.shadow_color = Color(0.06, 0.04, 0.01, 0.22)
	st.shadow_size = 18
	st.shadow_offset = Vector2(0, 6)
	st.content_margin_left = 24
	st.content_margin_right = 26
	st.content_margin_top = 20
	st.content_margin_bottom = 20
	_dialog_card.add_theme_stylebox_override("panel", st)
	card_center.add_child(_dialog_card)

	var h_main := HBoxContainer.new()
	h_main.add_theme_constant_override("separation", 24)
	_dialog_card.add_child(h_main)

	# Left Column: Big Avatar + Name Tag
	var left_col := VBoxContainer.new()
	left_col.alignment = BoxContainer.ALIGNMENT_CENTER
	left_col.add_theme_constant_override("separation", 8)
	h_main.add_child(left_col)

	_portrait = NaraPortraitScript.new()
	_portrait.custom_minimum_size = Vector2(118, 118)
	left_col.add_child(_portrait)

	_name_tag = _label("NARA", 15, Color.WHITE, _font_display)
	_name_tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var name_st := StyleBoxFlat.new()
	name_st.bg_color = Color(0.85, 0.35, 0.58)
	name_st.set_corner_radius_all(8)
	name_st.content_margin_left = 14
	name_st.content_margin_right = 14
	name_st.content_margin_top = 3
	name_st.content_margin_bottom = 3
	_name_tag.add_theme_stylebox_override("normal", name_st)
	left_col.add_child(_name_tag)

	# Right Column: Header Badges, Dialogue Text, and Footer Controls
	var right_col := VBoxContainer.new()
	right_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_col.add_theme_constant_override("separation", 10)
	h_main.add_child(right_col)

	# Header inside Right Column
	var row_header := HBoxContainer.new()
	row_header.add_theme_constant_override("separation", 10)
	right_col.add_child(row_header)

	_step_badge = _label("CERITA 1 / 4", 13, Color.WHITE, _font_display)
	var badge_st := StyleBoxFlat.new()
	badge_st.bg_color = Color(0.92, 0.55, 0.08)
	badge_st.set_corner_radius_all(8)
	badge_st.content_margin_left = 10
	badge_st.content_margin_right = 10
	badge_st.content_margin_top = 4
	badge_st.content_margin_bottom = 4
	_step_badge.add_theme_stylebox_override("normal", badge_st)
	row_header.add_child(_step_badge)

	_chapter_title = _label("", 20, Color(0.20, 0.14, 0.08), _font_display)
	_chapter_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row_header.add_child(_chapter_title)

	# Story Text Area
	_story_lbl = _label("", 18, Color(0.22, 0.18, 0.15))
	_story_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_story_lbl.custom_minimum_size = Vector2(0, 68)
	_story_lbl.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right_col.add_child(_story_lbl)

	# Footer Controls Row: Progress dots + Navigation buttons
	var row_footer := HBoxContainer.new()
	row_footer.add_theme_constant_override("separation", 12)
	right_col.add_child(row_footer)

	_dots_box = HBoxContainer.new()
	_dots_box.add_theme_constant_override("separation", 6)
	_dots_box.alignment = BoxContainer.ALIGNMENT_CENTER
	_dots_box.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row_footer.add_child(_dots_box)

	var foot_spacer := Control.new()
	foot_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row_footer.add_child(foot_spacer)

	_back_btn = _button("", Color(0.96, 0.93, 0.88), Color(0.78, 0.72, 0.62), Color(0.28, 0.22, 0.16), 16)
	_back_btn.custom_minimum_size = Vector2(118, 44)
	var back_hb := HBoxContainer.new()
	back_hb.set_anchors_preset(Control.PRESET_FULL_RECT)
	back_hb.alignment = BoxContainer.ALIGNMENT_CENTER
	back_hb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	back_hb.add_theme_constant_override("separation", 6)
	back_hb.add_child(StorybookUI.make_icon("play_left", 14.0, Color(0.36, 0.26, 0.18), Color(0.36, 0.26, 0.18)))
	back_hb.add_child(_label("Kembali", 15, Color(0.28, 0.22, 0.16)))
	_back_btn.add_child(back_hb)
	_back_btn.pressed.connect(_on_back)
	row_footer.add_child(_back_btn)

	_next_btn = _button("", Color(0.784, 0.118, 0.408), Color(0.58, 0.08, 0.28), Color.WHITE, 17)
	_next_btn.custom_minimum_size = Vector2(210, 46)
	var next_hb := HBoxContainer.new()
	next_hb.set_anchors_preset(Control.PRESET_FULL_RECT)
	next_hb.alignment = BoxContainer.ALIGNMENT_CENTER
	next_hb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	next_hb.add_theme_constant_override("separation", 8)
	_next_lbl = _label("Lanjut Cerita", 17, Color.WHITE, _font_display)
	_next_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	next_hb.add_child(_next_lbl)
	_next_icon_holder = CenterContainer.new()
	_next_icon_holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	next_hb.add_child(_next_icon_holder)
	_next_btn.add_child(next_hb)
	_next_btn.pressed.connect(_on_next)
	row_footer.add_child(_next_btn)


func _render_slide() -> void:
	var s: Dictionary = _slides[_slide_idx]
	_step_badge.text = str(s["badge"])
	_chapter_title.text = str(s["title"])
	_portrait.call("set_expression", str(s["expr"]))

	# Typewriter text reveal
	_story_lbl.text = str(s["text"])
	_story_lbl.visible_ratio = 0.0
	if _typing_tween != null and _typing_tween.is_running():
		_typing_tween.kill()
	_typing_tween = create_tween()
	_typing_tween.tween_property(_story_lbl, "visible_ratio", 1.0, 0.45)

	# Play SFX and upbeat Indonesian voice clip
	var sfx_key: String = str(s.get("sfx", ""))
	var voice_key: String = str(s.get("voice", ""))
	if sfx_key == "thunder":
		Audio.stop_voice()
		Audio.play_sfx("thunder")
		_play_lightning_fx()
		var expected_idx := _slide_idx
		if not voice_key.is_empty():
			get_tree().create_timer(0.42).timeout.connect(func() -> void:
				if visible and _slide_idx == expected_idx:
					Audio.play_voice(voice_key)
			)
	else:
		if not sfx_key.is_empty():
			Audio.play_sfx(sfx_key)
		if not voice_key.is_empty():
			Audio.play_voice(voice_key)

	_back_btn.visible = _slide_idx > 0
	for ic in _next_icon_holder.get_children():
		ic.queue_free()
	if _slide_idx == _slides.size() - 1:
		_next_lbl.text = "Ayo Mulai Petualangan!"
		_next_btn.custom_minimum_size = Vector2(265, 46)
		_next_icon_holder.add_child(StorybookUI.make_icon("star", 18.0, StorybookUI.HONEY_LIGHT, StorybookUI.WALNUT_DARK))
		_style_btn(_next_btn, Color(0.082, 0.502, 0.239), Color(0.055, 0.35, 0.16), Color.WHITE)
	else:
		_next_lbl.text = "Lanjut Cerita"
		_next_btn.custom_minimum_size = Vector2(200, 46)
		_next_icon_holder.add_child(StorybookUI.make_icon("play_right", 16.0, Color.WHITE, Color(0.45, 0.06, 0.22)))
		_style_btn(_next_btn, Color(0.784, 0.118, 0.408), Color(0.58, 0.08, 0.28), Color.WHITE)

	_rebuild_dots()
	_next_btn.grab_focus()


func _play_lightning_fx() -> void:
	# Double lightning flash + subtle dramatic card shake synced to thunder_boom.wav (0.00s & 0.16s)
	if _flash_rect != null:
		var ftw := create_tween()
		ftw.tween_property(_flash_rect, "color:a", 0.72, 0.03)
		ftw.tween_property(_flash_rect, "color:a", 0.08, 0.11)
		ftw.tween_property(_flash_rect, "color:a", 0.56, 0.03)
		ftw.tween_property(_flash_rect, "color:a", 0.0, 0.34)
	if _dialog_card != null:
		var base_x := _dialog_card.position.x
		var stw := create_tween()
		stw.tween_property(_dialog_card, "position:x", base_x - 10.0, 0.04)
		stw.tween_property(_dialog_card, "position:x", base_x + 10.0, 0.04)
		stw.tween_property(_dialog_card, "position:x", base_x - 7.0, 0.04)
		stw.tween_property(_dialog_card, "position:x", base_x + 7.0, 0.04)
		stw.tween_property(_dialog_card, "position:x", base_x - 3.0, 0.04)
		stw.tween_property(_dialog_card, "position:x", base_x, 0.05)


func _rebuild_dots() -> void:
	for c in _dots_box.get_children():
		c.queue_free()
	for i in range(_slides.size()):
		var dot := Panel.new()
		var is_cur := i == _slide_idx
		dot.custom_minimum_size = Vector2(28 if is_cur else 10, 10)
		var ds := StyleBoxFlat.new()
		ds.bg_color = Color(0.784, 0.118, 0.408) if is_cur else Color(0.85, 0.80, 0.70)
		ds.set_corner_radius_all(5)
		dot.add_theme_stylebox_override("panel", ds)
		_dots_box.add_child(dot)


func _on_back() -> void:
	if _slide_idx > 0:
		Audio.play_sfx("select")
		_slide_idx -= 1
		_render_slide()


func _on_next() -> void:
	if _slide_idx < _slides.size() - 1:
		Audio.play_sfx("select")
		_slide_idx += 1
		_render_slide()
	else:
		Audio.play_sfx("confirm")
		close_story()


func _label(text: String, size: int, col: Color, custom_font: Font = null) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", custom_font if custom_font != null else _font)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	return l


func _button(text: String, bg: Color, border: Color, fg: Color, font_size: int = 17) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, 44)
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	b.add_theme_font_override("font", _font)
	b.add_theme_font_size_override("font_size", font_size)
	_style_btn(b, bg, border, fg)
	return b


func _style_btn(b: Button, bg: Color, border: Color, fg: Color) -> void:
	b.add_theme_color_override("font_color", fg)
	b.add_theme_color_override("font_hover_color", fg)
	b.add_theme_color_override("font_pressed_color", fg)
	b.add_theme_color_override("font_focus_color", fg)

	var normal := StyleBoxFlat.new()
	normal.bg_color = bg
	normal.border_color = border
	normal.set_border_width_all(2)
	normal.border_width_bottom = 4
	normal.set_corner_radius_all(14)
	normal.content_margin_left = 16
	normal.content_margin_right = 16

	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = bg.lightened(0.08)

	var pressed := normal.duplicate() as StyleBoxFlat
	pressed.bg_color = bg.darkened(0.08)
	pressed.border_width_bottom = 2

	b.add_theme_stylebox_override("normal", normal)
	b.add_theme_stylebox_override("hover", hover)
	b.add_theme_stylebox_override("pressed", pressed)
	b.add_theme_stylebox_override("focus", hover)
