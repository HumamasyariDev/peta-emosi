class_name DialogPos3
extends CanvasLayer

signal pos3_solved
signal closed

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
var _choices_box: VBoxContainer
var _feedback_lbl: Label
var _close_action_btn: Button
var _solved: bool = false


class TrapIllustration extends Control:
	var kind: String = "bottle"
	var _t: float = 0.0
	var _accum: float = 0.0

	func _init(p_kind: String) -> void:
		kind = p_kind
		custom_minimum_size = Vector2(120, 96)

	func _process(delta: float) -> void:
		if not is_visible_in_tree():
			return
		_t += delta
		_accum += delta
		if _accum >= 0.05:
			_accum = 0.0
			queue_redraw()

	func _draw() -> void:
		var cx := size.x * 0.5
		var cy := size.y * 0.54
		if kind == "bottle":
			var shake := sin(_t * 24.0) * 3.0
			var bx := cx + shake
			# Pressurized soda bottle body
			draw_rect(Rect2(bx - 18, cy - 10, 36, 44), Color(0.88, 0.22, 0.20), true)
			draw_rect(Rect2(bx - 18, cy - 10, 36, 44), Color(0.28, 0.10, 0.08), false, 2.5)
			# Bottle neck
			draw_rect(Rect2(bx - 9, cy - 26, 18, 17), Color(0.92, 0.30, 0.26), true)
			draw_rect(Rect2(bx - 9, cy - 26, 18, 17), Color(0.28, 0.10, 0.08), false, 2.5)
			# Cork stopper popping slightly
			var cork_y := cy - 35.0 - absf(sin(_t * 10.0)) * 3.0
			draw_rect(Rect2(bx - 10, cork_y, 20, 10), Color(0.76, 0.50, 0.24), true)
			draw_rect(Rect2(bx - 10, cork_y, 20, 10), Color(0.28, 0.14, 0.06), false, 2.0)
			# Pressure bubbles & steam lines
			for i in range(3):
				var p := fmod(_t * 1.4 + float(i) * 0.33, 1.0)
				draw_circle(Vector2(bx + sin(p * TAU + float(i)) * 14.0, cork_y - 4.0 - p * 16.0), 4.5 * (1.0 - p * 0.5), Color(1.0, 0.96, 0.90, 1.0 - p))
			# Label stripe
			draw_rect(Rect2(bx - 15, cy + 4, 30, 12), Color(1.0, 0.94, 0.78), true)
		else:
			# Wild sparking firecracker
			var tilt := sin(_t * 12.0) * 2.5
			var fx := cx + tilt
			draw_rect(Rect2(fx - 14, cy - 12, 28, 46), Color(0.90, 0.20, 0.20), true)
			draw_rect(Rect2(fx - 14, cy - 12, 28, 46), Color(0.28, 0.10, 0.08), false, 2.5)
			# Gold bands
			draw_rect(Rect2(fx - 14, cy - 2, 28, 7), Color(0.98, 0.78, 0.18), true)
			draw_rect(Rect2(fx - 14, cy + 16, 28, 7), Color(0.98, 0.78, 0.18), true)
			# Fuse
			draw_line(Vector2(fx, cy - 12), Vector2(fx + 6, cy - 26), Color(0.32, 0.22, 0.14), 3.0)
			# Bursting sparks
			var sp_center := Vector2(fx + 8, cy - 28)
			var rays := 7
			for i in range(rays):
				var a := float(i) * TAU / float(rays) + _t * 3.5
				var r1 := 6.0
				var r2 := 15.0 + absf(sin(_t * 16.0 + float(i))) * 8.0
				draw_line(sp_center + Vector2(cos(a) * r1, sin(a) * r1), sp_center + Vector2(cos(a) * r2, sin(a) * r2), Color(1.0, 0.56, 0.12), 2.8)
			draw_circle(sp_center, 6.0, Color(1.0, 0.92, 0.35))


func _ready() -> void:
	layer = 20
	_font_ui = StorybookUI.font_body(580)
	_font_display = StorybookUI.font_display()
	_font_book = StorybookUI.font_serif()
	_build_ui()
	visible = false


func open_dialog(already_solved: bool) -> void:
	_solved = already_solved
	Game.modal_open = true
	visible = true
	_rebuild_choices()
	Audio.play_sfx("select")
	Audio.play_voice("pos3_rule")

	if _wood_frame != null:
		_wood_frame.scale = Vector2(0.94, 0.94)
		_wood_frame.modulate = Color(1, 1, 1, 0)
		var tw := create_tween().set_parallel(true)
		tw.tween_property(_wood_frame, "scale", Vector2.ONE, 0.24).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(_wood_frame, "modulate:a", 1.0, 0.18)


func close_dialog() -> void:
	Audio.stop_voice()
	visible = false
	Game.modal_open = false
	closed.emit()


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		close_dialog()
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
	_wood_frame.custom_minimum_size = Vector2(910, 520)
	_wood_frame.pivot_offset = Vector2(455, 260)
	_wood_frame.add_theme_stylebox_override("panel", StorybookUI.make_panel_box(
		Color("fff9ec"), Color("824d02"), 24, 4, 10, 22, 18, true
	))
	center.add_child(_wood_frame)

	var outer_v := VBoxContainer.new()
	outer_v.add_theme_constant_override("separation", 14)
	_wood_frame.add_child(outer_v)

	# Header bar
	var hdr := HBoxContainer.new()
	hdr.add_theme_constant_override("separation", 12)
	outer_v.add_child(hdr)

	var badge_box := PanelContainer.new()
	badge_box.add_theme_stylebox_override("panel", StorybookUI.make_panel_box(
		Color("c97a08"), Color("824d02"), 10, 2, 4, 12, 5, false
	))
	var bhb := HBoxContainer.new()
	bhb.add_theme_constant_override("separation", 6)
	badge_box.add_child(bhb)
	bhb.add_child(StorybookUI.make_icon("star", 17.0, StorybookUI.HONEY_LIGHT, StorybookUI.WALNUT_DARK))
	bhb.add_child(_label("POS 3: LONCENG ELING", 14, COLOR_CREAM, _font_display))
	hdr.add_child(badge_box)

	var h_spacer := Control.new()
	h_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hdr.add_child(h_spacer)

	var replay_btn := _styled_button("", StorybookUI.PAPER, StorybookUI.HONEY, StorybookUI.INK, 14)
	replay_btn.custom_minimum_size = Vector2(166, 40)
	var rhb := HBoxContainer.new()
	rhb.alignment = BoxContainer.ALIGNMENT_CENTER
	rhb.add_theme_constant_override("separation", 7)
	rhb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rhb.set_anchors_preset(Control.PRESET_FULL_RECT)
	replay_btn.add_child(rhb)
	rhb.add_child(StorybookUI.make_icon("sound_on", 18.0, StorybookUI.INK, StorybookUI.WALNUT))
	rhb.add_child(_label("Dengarkan Lagi", 14, StorybookUI.INK, _font_display))
	replay_btn.pressed.connect(func() -> void:
		Audio.play_sfx("bell")
		Audio.play_voice("pos3_rule")
	)
	hdr.add_child(replay_btn)

	# Double-page spread
	var pages := HBoxContainer.new()
	pages.add_theme_constant_override("separation", 22)
	pages.size_flags_vertical = Control.SIZE_EXPAND_FILL
	outer_v.add_child(pages)

	# LEFT PAGE: Rule & Two Traps Visuals
	var left_page := PanelContainer.new()
	left_page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left_page.add_theme_stylebox_override("panel", _page_style())
	pages.add_child(left_page)

	var lv := VBoxContainer.new()
	lv.add_theme_constant_override("separation", 12)
	left_page.add_child(lv)

	lv.add_child(_label("Rahasia Mengatur Emosi Negatif", 22, COLOR_INK, _font_display))

	var quote_panel := PanelContainer.new()
	var qst := StyleBoxFlat.new()
	qst.bg_color = Color(1.0, 0.96, 0.84)
	qst.border_color = COLOR_GOLD_BRASS
	qst.set_border_width_all(2)
	qst.set_corner_radius_all(14)
	qst.content_margin_left = 14
	qst.content_margin_right = 14
	qst.content_margin_top = 10
	qst.content_margin_bottom = 10
	quote_panel.add_theme_stylebox_override("panel", qst)
	var quote_lbl := _label(
		"\"Emosi negatif seperti marah, tidak boleh ditahan, tapi juga tidak boleh diledakkan. Emosi negatif harus diatur dengan baik yaaa.\"",
		16, COLOR_INK, _font_book
	)
	quote_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	quote_panel.add_child(quote_lbl)
	lv.add_child(quote_panel)

	var traps_row := HBoxContainer.new()
	traps_row.add_theme_constant_override("separation", 12)
	traps_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	lv.add_child(traps_row)

	traps_row.add_child(_make_trap_card(
		"bottle",
		"1. Jangan Ditahan",
		"Seperti botol soda dikocok rapat, dada jadi sesak dan bisa meledak tiba-tiba!"
	))
	traps_row.add_child(_make_trap_card(
		"firecracker",
		"2. Jangan Diledakkan",
		"Seperti petasan liar, meledakkan marah bisa melukai teman dan membuat kita menyesal!"
	))

	# RIGHT PAGE: Nara's Question & Quiz
	var right_page := PanelContainer.new()
	right_page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_page.add_theme_stylebox_override("panel", _page_style())
	pages.add_child(right_page)

	var rv := VBoxContainer.new()
	rv.add_theme_constant_override("separation", 12)
	right_page.add_child(rv)

	rv.add_child(_label("Pertanyaan Nara", 22, COLOR_INK, _font_display))

	var nara_q := _label(
		"\"Apa yang harus kita lakukan saat merasa marah agar hati tetap aman dan tidak menyakiti siapa pun?\"",
		16, COLOR_INK_SOFT, _font_book
	)
	nara_q.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	rv.add_child(nara_q)

	_choices_box = VBoxContainer.new()
	_choices_box.add_theme_constant_override("separation", 10)
	_choices_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	rv.add_child(_choices_box)

	_feedback_lbl = _label("", 15, COLOR_INK_SOFT)
	_feedback_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	rv.add_child(_feedback_lbl)

	_close_action_btn = _styled_button("Tutup Buku", Color(0.95, 0.90, 0.82), COLOR_WOOD_MID, COLOR_INK, 16)
	_close_action_btn.custom_minimum_size = Vector2(0, 46)
	_close_action_btn.pressed.connect(close_dialog)
	rv.add_child(_close_action_btn)


func _make_trap_card(kind: String, heading: String, desc: String) -> PanelContainer:
	var card := PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var st := StyleBoxFlat.new()
	st.bg_color = COLOR_CARD_BASE
	st.border_color = Color(0.84, 0.62, 0.44)
	st.set_border_width_all(2)
	st.set_corner_radius_all(14)
	st.content_margin_left = 10
	st.content_margin_right = 10
	st.content_margin_top = 10
	st.content_margin_bottom = 10
	card.add_theme_stylebox_override("panel", st)

	var cv := VBoxContainer.new()
	cv.add_theme_constant_override("separation", 6)
	card.add_child(cv)

	var ill := TrapIllustration.new(kind)
	ill.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cv.add_child(ill)

	var h := _label(heading, 15, COLOR_RIBBON_RED, _font_display)
	h.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cv.add_child(h)

	var d := _label(desc, 13, COLOR_INK_SOFT)
	d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	d.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cv.add_child(d)

	return card


func _rebuild_choices() -> void:
	for c in _choices_box.get_children():
		c.queue_free()

	var options := [
		["Memendam marah sendirian sampai dada sesak", false],
		["Membanting mainan atau memukul benda keras", false],
		["Berhenti sejenak, tenangkan diri, dan atur dengan baik", true],
	]
	options.shuffle()
	var prefixes := ["A. ", "B. ", "C. "]

	if _solved:
		_feedback_lbl.text = "Keren! Lencana Sahabat Tenang sudah diraih. Sekarang lanjut ke Gerbang Pos 4!"
		_feedback_lbl.add_theme_color_override("font_color", COLOR_CARD_OK_BORDER)
		_close_action_btn.text = "Lanjut ke Gerbang Pos 4"
	else:
		_feedback_lbl.text = "Pilih satu jawaban yang paling bijak untuk membuka Gerbang Pos 4!"
		_feedback_lbl.add_theme_color_override("font_color", COLOR_INK_SOFT)
		_close_action_btn.text = "Tutup Sebentar (Esc)"

	for idx in range(options.size()):
		var opt: Array = options[idx]
		var text: String = prefixes[idx] + str(opt[0])
		var is_correct: bool = opt[1]
		var btn := _styled_button(
			text,
			COLOR_CARD_OK if (_solved and is_correct) else COLOR_PARCHMENT_INNER,
			COLOR_CARD_OK_BORDER if (_solved and is_correct) else COLOR_GOLD_BRASS,
			COLOR_CARD_OK_BORDER if (_solved and is_correct) else COLOR_INK,
			15
		)
		btn.custom_minimum_size = Vector2(0, 52)
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		btn.pressed.connect(func() -> void:
			_on_choice_picked(is_correct)
		)
		_choices_box.add_child(btn)


func _on_choice_picked(is_correct: bool) -> void:
	if is_correct:
		if not _solved:
			_solved = true
			Game.add_coins(5)
			Audio.play_sfx("coin")
			pos3_solved.emit()
		_feedback_lbl.text = "Tepat sekali! (+5 Koin) Emosi negatif diatur dengan tenang, bukan ditahan atau diledakkan!"
		_feedback_lbl.add_theme_color_override("font_color", COLOR_CARD_OK_BORDER)
		_close_action_btn.text = "Buka Gerbang Pos 4!"
		_rebuild_choices()
	else:
		Audio.play_sfx("error")
		Audio.play_voice("pos3_wrong")
		_feedback_lbl.text = "Ups, belum tepat! Ingat aturan di halaman kiri: jangan ditahan dan jangan diledakkan ya!"
		_feedback_lbl.add_theme_color_override("font_color", COLOR_RIBBON_RED)


func _page_style() -> StyleBoxFlat:
	var st := StyleBoxFlat.new()
	st.bg_color = COLOR_PARCHMENT_INNER
	st.border_color = Color(0.84, 0.74, 0.56)
	st.set_border_width_all(2)
	st.set_corner_radius_all(16)
	st.content_margin_left = 18
	st.content_margin_right = 18
	st.content_margin_top = 16
	st.content_margin_bottom = 16
	return st


func _styled_button(text: String, bg: Color, border: Color, fg: Color, size: int) -> Button:
	var b := Button.new()
	b.text = text
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	b.add_theme_font_override("font", _font_ui)
	b.add_theme_font_size_override("font_size", size)
	b.add_theme_color_override("font_color", fg)
	b.add_theme_color_override("font_hover_color", fg)
	b.add_theme_color_override("font_pressed_color", fg)
	var st := StyleBoxFlat.new()
	st.bg_color = bg
	st.border_color = border
	st.set_border_width_all(2)
	st.border_width_bottom = 4
	st.set_corner_radius_all(14)
	st.content_margin_left = 14
	st.content_margin_right = 14
	st.content_margin_top = 8
	st.content_margin_bottom = 8
	b.add_theme_stylebox_override("normal", st)
	var hv := st.duplicate() as StyleBoxFlat
	hv.bg_color = bg.lightened(0.06)
	b.add_theme_stylebox_override("hover", hv)
	b.add_theme_stylebox_override("pressed", st)
	return b


func _label(text: String, size: int, col: Color, custom_font: Font = null) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", custom_font if custom_font != null else _font_ui)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	return l

