class_name DialogEmotionPos2
extends CanvasLayer

signal emotion_solved(friend_id: String, emotion_label: String)
signal closed

const NaraPortraitScript := preload("res://scripts/ui/nara_portrait.gd")

const COLOR_INK := Color("2c1810")
const COLOR_INK_SOFT := Color("5e3c28")
const COLOR_PARCHMENT := Color("f7ecd5")
const COLOR_PARCHMENT_INNER := Color("fffbf0")
const COLOR_WOOD_DARK := Color("42220f")
const COLOR_WOOD_MID := Color("6b3d1b")
const COLOR_GOLD_BRASS := Color("d49826")
const COLOR_RIBBON_RED := Color("961d2d")
const COLOR_RIBBON_DARK := Color("61101b")
const COLOR_CREAM := Color("fff8eb")
const COLOR_CARD_BASE := Color("f4ebe1")
const COLOR_CARD_OK := Color("e8f6ec")
const COLOR_CARD_OK_BORDER := Color("2d8647")

var _font_ui: Font
var _font_display: Font
var _font_book: Font

var _backdrop: ColorRect
var _wood_frame: PanelContainer
var _badge_lbl: Label
var _title_lbl: Label
var _story_lbl: Label
var _body_clue_lbl: Label
var _portrait: Control
var _question_lbl: Label
var _choices_box: VBoxContainer
var _feedback_lbl: Label
var _close_action_btn: Button

var _current_id: String = ""
var _current_data: Dictionary = {}
var _solved_this_open: bool = false
var _stories: Dictionary = {}


func _ready() -> void:
	layer = 20
	_font_ui = StorybookUI.font_body(580)
	_font_display = StorybookUI.font_display()
	_font_book = StorybookUI.font_serif()
	_init_stories()
	_build_ui()
	visible = false


func _init_stories() -> void:
	_stories = {
		"sedih": {
			"badge": "EMOSI 1 / 6: SEDIH",
			"title": "Halo! Aku Emosi Sedih",
			"label": "1. Sedih",
			"expr": "upset",
			"shirt": Color(0.64, 0.52, 0.94),
			"hair": Color(0.16, 0.12, 0.16),
			"voice": "emo_sedih",
			"story": "\"Aku muncul saat kita kehilangan sesuatu atau merasa kecewa, seperti saat boneka kelinci kesayanganku jatuh dan hilang di jalan tadi.\"",
			"clue": "Ciri di tubuh: Dada terasa sesak, mata berkaca-kaca, kepala menunduk, dan ingin menangis.",
			"question": "Cek Paham: Kapan emosi Sedih biasanya muncul?",
			"correct": "Saat kita kehilangan sesuatu atau merasa kecewa",
			"choices": [
				"Saat kita kehilangan sesuatu atau merasa kecewa",
				"Saat kita mencium bau makanan basi di tong sampah"
			]
		},
		"marah": {
			"badge": "EMOSI 2 / 6: MARAH",
			"title": "Halo! Aku Emosi Marah",
			"label": "2. Marah",
			"expr": "upset",
			"shirt": Color(0.92, 0.28, 0.26),
			"hair": Color(0.14, 0.10, 0.08),
			"voice": "emo_marah",
			"story": "\"Aku muncul saat kita merasa kesal atau diperlakukan tidak adil, seperti waktu antreanku tiba-tiba diserobot! Nanti di Pos 3 kita belajar cara mengaturnya ya.\"",
			"clue": "Ciri di tubuh: Muka terasa panas, alis menukik, napas cepat, dan tangan mengepal.",
			"question": "Cek Paham: Apa yang biasa membuat emosi Marah muncul?",
			"correct": "Saat merasa kesal atau diperlakukan tidak adil",
			"choices": [
				"Saat mendapat hadiah pensil warna baru",
				"Saat merasa kesal atau diperlakukan tidak adil"
			]
		},
		"takut": {
			"badge": "EMOSI 3 / 6: TAKUT",
			"title": "Halo! Aku Emosi Takut",
			"label": "3. Takut",
			"expr": "surprised",
			"shirt": Color(0.96, 0.58, 0.20),
			"hair": Color(0.28, 0.18, 0.10),
			"voice": "emo_takut",
			"story": "\"Aku adalah alarm tubuh agar kita lebih berhati-hati, seperti saat mendengar suara ranting patah di balik pohon gelap!\"",
			"clue": "Ciri di tubuh: Jantung berdebar kencang, kaki gemetar, dan ingin mencari tempat aman.",
			"question": "Cek Paham: Apa manfaat utama emosi Takut bagi tubuh kita?",
			"correct": "Menjadi alarm agar kita berhati-hati dan menjaga diri",
			"choices": [
				"Menjadi alarm agar kita berhati-hati dan menjaga diri",
				"Membuat kita melompat kegirangan di atas perosotan"
			]
		},
		"bahagia": {
			"badge": "EMOSI 4 / 6: BAHAGIA",
			"title": "Halo! Aku Emosi Bahagia",
			"label": "4. Bahagia",
			"expr": "excited",
			"shirt": Color(0.22, 0.72, 0.95),
			"hair": Color(0.22, 0.14, 0.10),
			"voice": "emo_bahagia",
			"story": "\"Aku muncul saat kita merasa senang, nyaman, atau bangga, seperti waktu akhirnya aku berani meluncur dari perosotan tinggi ini sendirian!\"",
			"clue": "Ciri di tubuh: Wajah tersenyum lebar, dada terasa hangat, dan tubuh terasa ringan.",
			"question": "Cek Paham: Bagaimana rasanya saat emosi Bahagia datang?",
			"correct": "Hati terasa ringan, hangat, dan ingin tersenyum",
			"choices": [
				"Hati terasa ringan, hangat, dan ingin tersenyum",
				"Hidung mengernyit karena bau tidak sedap"
			]
		},
		"jijik": {
			"badge": "EMOSI 5 / 6: JIJIK",
			"title": "Halo! Aku Emosi Jijik",
			"label": "5. Jijik",
			"expr": "upset",
			"shirt": Color(0.46, 0.80, 0.34),
			"hair": Color(0.20, 0.12, 0.08),
			"voice": "emo_jijik",
			"story": "\"Aku membantu kita menjauhi benda kotor, bau, atau makanan basi yang tidak sehat, seperti saat mencium bau menyengat di dekat 3 tong sampah ini!\"",
			"clue": "Ciri di tubuh: Hidung mengernyit, mulut mencibir, dan tubuh refleks menjauh.",
			"question": "Cek Paham: Mengapa emosi Jijik penting bagi kita?",
			"correct": "Membantu kita menjauhi benda kotor atau makanan basi",
			"choices": [
				"Membantu kita menjauhi benda kotor atau makanan basi",
				"Membuat kita sedih saat kehilangan mainan"
			]
		},
		"terkejut": {
			"badge": "EMOSI 6 / 6: TERKEJUT",
			"title": "Halo! Aku Emosi Terkejut",
			"label": "6. Terkejut",
			"expr": "surprised",
			"shirt": Color(0.98, 0.82, 0.22),
			"hair": Color(0.18, 0.14, 0.12),
			"voice": "emo_terkejut",
			"story": "\"Aku muncul sekejap saat ada hal tak terduga yang datang tiba-tiba, seperti waktu balon di belakangku meletus keras sekali, DOR!\"",
			"clue": "Ciri di tubuh: Mata melotot, mulut terbuka, dan tubuh refleks melompat kaget.",
			"question": "Cek Paham: Kapan emosi Terkejut terjadi?",
			"correct": "Saat ada kejadian tak terduga yang datang tiba-tiba",
			"choices": [
				"Saat sedang tidur siang dengan tenang",
				"Saat ada kejadian tak terduga yang datang tiba-tiba"
			]
		}
	}


func open_friend(friend_id: String, already_solved: bool) -> void:
	if not _stories.has(friend_id):
		return
	_current_id = friend_id
	_current_data = _stories[friend_id]
	_solved_this_open = already_solved
	Game.modal_open = true
	visible = true

	_badge_lbl.text = str(_current_data["badge"])
	_title_lbl.text = str(_current_data["title"])
	_story_lbl.text = str(_current_data["story"])
	_body_clue_lbl.text = str(_current_data["clue"])
	_question_lbl.text = str(_current_data["question"])
	_portrait.call("set_character_style", _current_data["shirt"], _current_data["hair"], false)
	_portrait.call("set_expression", str(_current_data["expr"]))

	if already_solved:
		_feedback_lbl.text = "Stempel " + str(_current_data["label"]) + " sudah terkumpul di buku catatanmu!"
		_feedback_lbl.add_theme_color_override("font_color", COLOR_CARD_OK_BORDER)
		_close_action_btn.visible = true
	else:
		_feedback_lbl.text = "Pilih jawaban yang tepat untuk mengumpulkan Stempel Emosi (+5 Koin)!"
		_feedback_lbl.add_theme_color_override("font_color", COLOR_INK_SOFT)
		_close_action_btn.visible = false

	_rebuild_choices()
	Audio.play_voice(str(_current_data["voice"]))

	_backdrop.modulate.a = 0.0
	_wood_frame.modulate.a = 0.0
	_wood_frame.scale = Vector2(0.94, 0.94)
	var tw := create_tween().set_parallel(true)
	tw.tween_property(_backdrop, "modulate:a", 1.0, 0.2)
	tw.tween_property(_wood_frame, "modulate:a", 1.0, 0.22)
	tw.tween_property(_wood_frame, "scale", Vector2.ONE, 0.26).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func close_modal() -> void:
	Audio.stop_voice()
	visible = false
	Game.modal_open = false
	closed.emit()


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		Audio.play_sfx("select")
		close_modal()
		get_viewport().set_input_as_handled()


func _build_ui() -> void:
	_backdrop = ColorRect.new()
	_backdrop.color = Color(0.04, 0.03, 0.02, 0.62)
	_backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_backdrop)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_backdrop.add_child(center)

	_wood_frame = PanelContainer.new()
	_wood_frame.custom_minimum_size = Vector2(900, 490)
	_wood_frame.pivot_offset = Vector2(450, 245)
	_wood_frame.add_theme_stylebox_override("panel", StorybookUI.make_panel_box(
		Color("f2faf5"), StorybookUI.EMERALD_DARK, 24, 4, 10, 22, 18, true
	))
	center.add_child(_wood_frame)

	var v_main := VBoxContainer.new()
	v_main.add_theme_constant_override("separation", 14)
	_wood_frame.add_child(v_main)

	# Top Ribbon Row
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 12)
	v_main.add_child(top)

	var rib := PanelContainer.new()
	rib.add_theme_stylebox_override("panel", StorybookUI.make_panel_box(
		StorybookUI.EMERALD, StorybookUI.EMERALD_DARK, 10, 2, 4, 12, 5, false
	))
	top.add_child(rib)

	var rib_hb := HBoxContainer.new()
	rib_hb.add_theme_constant_override("separation", 6)
	rib.add_child(rib_hb)
	rib_hb.add_child(StorybookUI.make_icon("star", 17.0, StorybookUI.HONEY_LIGHT, StorybookUI.WALNUT_DARK))
	_badge_lbl = _label("EMOSI", 14, COLOR_CREAM, _font_display)
	rib_hb.add_child(_badge_lbl)

	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(sp)

	var replay_btn := _action_btn("", StorybookUI.PAPER, StorybookUI.HONEY, StorybookUI.INK, 14)
	replay_btn.custom_minimum_size = Vector2(180, 40)
	var rhb := HBoxContainer.new()
	rhb.alignment = BoxContainer.ALIGNMENT_CENTER
	rhb.add_theme_constant_override("separation", 7)
	rhb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rhb.set_anchors_preset(Control.PRESET_FULL_RECT)
	replay_btn.add_child(rhb)
	rhb.add_child(StorybookUI.make_icon("sound_on", 18.0, StorybookUI.INK, StorybookUI.WALNUT))
	rhb.add_child(_label("Dengar Perkenalan", 14, StorybookUI.INK, _font_display))
	replay_btn.pressed.connect(func() -> void:
		if _current_data.has("voice"):
			Audio.play_voice(str(_current_data["voice"]))
	)
	top.add_child(replay_btn)

	var close_btn := _action_btn("Tutup", Color("fce8e8"), StorybookUI.BERRY, StorybookUI.BERRY_DARK, 14)
	close_btn.custom_minimum_size = Vector2(82, 40)
	close_btn.pressed.connect(func() -> void:
		Audio.play_sfx("select")
		close_modal()
	)
	top.add_child(close_btn)

	# Split Content: Left Perkenalan Emosi | Right Cek Paham & Stempel
	var split := HBoxContainer.new()
	split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	split.add_theme_constant_override("separation", 20)
	v_main.add_child(split)

	# Left Page: Perkenalan & Ciri di Tubuh
	var left := PanelContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var lst := StyleBoxFlat.new()
	lst.bg_color = Color(0.92, 0.84, 0.70)
	lst.border_color = COLOR_WOOD_MID
	lst.set_border_width_all(3)
	lst.border_width_left = 8
	lst.set_corner_radius_all(18)
	lst.content_margin_left = 20
	lst.content_margin_right = 20
	lst.content_margin_top = 16
	lst.content_margin_bottom = 16
	left.add_theme_stylebox_override("panel", lst)
	split.add_child(left)

	var vl := VBoxContainer.new()
	vl.add_theme_constant_override("separation", 10)
	left.add_child(vl)

	_title_lbl = _label("", 24, COLOR_INK, _font_book)
	vl.add_child(_title_lbl)

	_story_lbl = _label("", 17, COLOR_INK)
	_story_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_story_lbl.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vl.add_child(_story_lbl)

	var clue_box := PanelContainer.new()
	var cst := StyleBoxFlat.new()
	cst.bg_color = COLOR_PARCHMENT_INNER
	cst.border_color = COLOR_GOLD_BRASS
	cst.set_border_width_all(2)
	cst.set_corner_radius_all(12)
	cst.content_margin_left = 14
	cst.content_margin_right = 14
	cst.content_margin_top = 8
	cst.content_margin_bottom = 8
	clue_box.add_theme_stylebox_override("panel", cst)
	vl.add_child(clue_box)

	_body_clue_lbl = _label("", 14, COLOR_INK_SOFT)
	_body_clue_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	clue_box.add_child(_body_clue_lbl)

	# Right Page: Cek Paham Ringan (2 Pilihan)
	var right := PanelContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var rpst := StyleBoxFlat.new()
	rpst.bg_color = COLOR_PARCHMENT_INNER
	rpst.border_color = COLOR_GOLD_BRASS
	rpst.set_border_width_all(2)
	rpst.border_width_right = 6
	rpst.set_corner_radius_all(18)
	rpst.content_margin_left = 18
	rpst.content_margin_right = 18
	rpst.content_margin_top = 14
	rpst.content_margin_bottom = 14
	right.add_theme_stylebox_override("panel", rpst)
	split.add_child(right)

	var vr := VBoxContainer.new()
	vr.add_theme_constant_override("separation", 12)
	right.add_child(vr)

	var hn := HBoxContainer.new()
	hn.add_theme_constant_override("separation", 12)
	vr.add_child(hn)

	_portrait = NaraPortraitScript.new()
	_portrait.custom_minimum_size = Vector2(68, 68)
	hn.add_child(_portrait)

	_question_lbl = _label("", 16, COLOR_INK)
	_question_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_question_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hn.add_child(_question_lbl)

	_choices_box = VBoxContainer.new()
	_choices_box.add_theme_constant_override("separation", 10)
	vr.add_child(_choices_box)

	_feedback_lbl = _label("", 15, COLOR_INK_SOFT)
	_feedback_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vr.add_child(_feedback_lbl)

	_close_action_btn = _action_btn("Lanjut Kenalan Emosi Lain", Color(0.082, 0.502, 0.239), Color(0.055, 0.35, 0.16), COLOR_CREAM, 17, _font_display)
	_close_action_btn.visible = false
	_close_action_btn.pressed.connect(func() -> void:
		Audio.play_sfx("select")
		close_modal()
	)
	vr.add_child(_close_action_btn)


func _rebuild_choices() -> void:
	for c in _choices_box.get_children():
		c.queue_free()

	var choices: Array = (_current_data["choices"] as Array).duplicate()
	choices.shuffle()
	var correct_ans: String = str(_current_data["correct"])

	for choice_raw in choices:
		var ch: String = str(choice_raw)
		var is_ok := ch == correct_ans
		var bg := COLOR_CARD_OK if (_solved_this_open and is_ok) else COLOR_CARD_BASE
		var border := COLOR_CARD_OK_BORDER if (_solved_this_open and is_ok) else COLOR_GOLD_BRASS
		var b := _action_btn(ch, bg, border, COLOR_INK, 15)
		b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		b.custom_minimum_size = Vector2(0, 58)
		b.pressed.connect(func() -> void: _on_pick_choice(ch))
		_choices_box.add_child(b)


func _on_pick_choice(picked: String) -> void:
	if _solved_this_open:
		return
	var correct_ans: String = str(_current_data["correct"])
	var emo_label: String = str(_current_data["label"])
	if picked == correct_ans:
		_solved_this_open = true
		Audio.play_sfx("coin")
		Game.add_coins(5)
		Game.collect_emotion(_current_id)
		if Game.collected_emotions.size() < 6:
			Audio.play_voice("emo_ok")
		_portrait.call("set_expression", "celebrate")
		_feedback_lbl.text = "Tepat sekali! Stempel " + emo_label + " berhasil dikumpulkan (+5 Koin)!"
		_feedback_lbl.add_theme_color_override("font_color", COLOR_CARD_OK_BORDER)
		_close_action_btn.visible = true
		_rebuild_choices()
		emotion_solved.emit(_current_id, emo_label)
		_close_action_btn.grab_focus()
	else:
		Audio.play_sfx("wrong")
		Audio.play_voice("emo_wrong")
		_portrait.call("set_expression", "curious")
		_feedback_lbl.text = "Belum tepat! Coba baca lagi perkenalan emosi di halaman kiri ya."
		_feedback_lbl.add_theme_color_override("font_color", COLOR_RIBBON_RED)


func _label(text: String, size: int, col: Color, custom_font: Font = null) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", custom_font if custom_font != null else _font_ui)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	return l


func _action_btn(text: String, bg: Color, border: Color, fg: Color, font_size: int = 16, custom_font: Font = null) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, 44)
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	b.add_theme_font_override("font", custom_font if custom_font != null else _font_ui)
	b.add_theme_font_size_override("font_size", font_size)
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
	normal.content_margin_top = 8
	normal.content_margin_bottom = 8

	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = bg.lightened(0.07)

	var pressed := normal.duplicate() as StyleBoxFlat
	pressed.bg_color = bg.darkened(0.07)
	pressed.border_width_bottom = 2

	b.add_theme_stylebox_override("normal", normal)
	b.add_theme_stylebox_override("hover", hover)
	b.add_theme_stylebox_override("pressed", pressed)
	b.add_theme_stylebox_override("focus", hover)
	return b
