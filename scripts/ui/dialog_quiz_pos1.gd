class_name DialogQuizPos1
extends CanvasLayer

signal closed

const NaraPortraitScript := preload("res://scripts/ui/nara_portrait.gd")

var _font_ui: Font
var _font_display: Font
var _font_book: Font

var _backdrop: ColorRect
var _wood_frame: PanelContainer
var _portrait: Control
var _feedback_lbl: Label
var _confirm_btn: Button

# Palet warna otentik Storybook SuperMak64 (Tanpa warna neon web generik)
const COLOR_INK := Color("2c1810")
const COLOR_INK_SOFT := Color("5e3c28")
const COLOR_PARCHMENT := Color("f7ecd5")
const COLOR_PARCHMENT_INNER := Color("fffbf0")
const COLOR_WOOD_DARK := Color("42220f")
const COLOR_WOOD_MID := Color("6b3d1b")
const COLOR_WOOD_LIGHT := Color("8f5629")
const COLOR_GOLD_BRASS := Color("d49826")
const COLOR_RIBBON_RED := Color("961d2d")
const COLOR_RIBBON_DARK := Color("61101b")
const COLOR_CREAM := Color("fff8eb")
const COLOR_CARD_UNSELECTED := Color("f4ebe1")
const COLOR_CARD_SELECTED := Color("e8f6ec")
const COLOR_CARD_BORDER_SEL := Color("2d8647")

var _selected_options: Dictionary = {}
var _option_cards: Array[PanelContainer] = []
var _cards_vbox: VBoxContainer
var _is_completed: bool = false


func _ready() -> void:
	layer = 20
	_font_ui = StorybookUI.font_body(580)
	_font_display = StorybookUI.font_display()
	_font_book = StorybookUI.font_serif()

	_build_ui()
	visible = false


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		Audio.play_sfx("select")
		close_modal()
		get_viewport().set_input_as_handled()


func open_modal() -> void:
	Game.modal_open = true
	visible = true
	_selected_options.clear()
	_is_completed = false
	_shuffle_cards()
	_refresh_card_visuals()

	Audio.play_voice("goleman_quote")

	# Animasi buku storybook terbuka dengan rotasi lembut
	_backdrop.modulate.a = 0.0
	_wood_frame.modulate.a = 0.0
	_wood_frame.scale = Vector2(0.92, 0.92)
	var tw := create_tween().set_parallel(true)
	tw.tween_property(_backdrop, "modulate:a", 1.0, 0.22)
	tw.tween_property(_wood_frame, "modulate:a", 1.0, 0.25)
	tw.tween_property(_wood_frame, "scale", Vector2.ONE, 0.32).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func close_modal() -> void:
	Audio.stop_voice()
	Audio.play_music("bgm_garden", true)
	visible = false
	Game.modal_open = false
	closed.emit()


func _build_ui() -> void:
	# 1. Dark Vignette Dimmer
	_backdrop = ColorRect.new()
	_backdrop.color = Color(0.04, 0.03, 0.02, 0.65)
	_backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_backdrop)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_backdrop.add_child(center)

	# 2. Main Wooden Tablet Board (Papan Kayu Tebal bergaya Storybook)
	_wood_frame = PanelContainer.new()
	_wood_frame.custom_minimum_size = Vector2(900, 520)
	_wood_frame.pivot_offset = Vector2(450, 260)
	var wood_st := StyleBoxFlat.new()
	wood_st.bg_color = COLOR_WOOD_MID
	wood_st.border_color = COLOR_WOOD_DARK
	wood_st.set_border_width_all(6)
	wood_st.border_width_bottom = 12
	wood_st.set_corner_radius_all(32)
	wood_st.shadow_color = Color(0.02, 0.01, 0.0, 0.45)
	wood_st.shadow_size = 28
	wood_st.shadow_offset = Vector2(0, 12)
	wood_st.content_margin_left = 18
	wood_st.content_margin_right = 18
	wood_st.content_margin_top = 16
	wood_st.content_margin_bottom = 18
	_wood_frame.add_theme_stylebox_override("panel", wood_st)
	center.add_child(_wood_frame)

	# Parchment Paper Sheet pasted onto the wooden board
	var parchment_sheet := PanelContainer.new()
	var parch_st := StyleBoxFlat.new()
	parch_st.bg_color = COLOR_PARCHMENT
	parch_st.border_color = COLOR_GOLD_BRASS
	parch_st.set_border_width_all(3)
	parch_st.border_width_top = 4
	parch_st.set_corner_radius_all(22)
	parch_st.content_margin_left = 26
	parch_st.content_margin_right = 26
	parch_st.content_margin_top = 20
	parch_st.content_margin_bottom = 20
	parchment_sheet.add_theme_stylebox_override("panel", parch_st)
	_wood_frame.add_child(parchment_sheet)

	var v_main := VBoxContainer.new()
	v_main.add_theme_constant_override("separation", 14)
	parchment_sheet.add_child(v_main)

	# 3. Top Ribbon Banner
	var top_row := HBoxContainer.new()
	top_row.add_theme_constant_override("separation", 14)
	v_main.add_child(top_row)

	# Burgundy Ribbon Tag
	var ribbon_pill := PanelContainer.new()
	var rib_st := StyleBoxFlat.new()
	rib_st.bg_color = COLOR_RIBBON_RED
	rib_st.border_color = COLOR_GOLD_BRASS
	rib_st.set_border_width_all(2)
	rib_st.set_corner_radius_all(10)
	rib_st.content_margin_left = 14
	rib_st.content_margin_right = 14
	rib_st.content_margin_top = 5
	rib_st.content_margin_bottom = 5
	ribbon_pill.add_theme_stylebox_override("panel", rib_st)
	top_row.add_child(ribbon_pill)

	var rib_hb := HBoxContainer.new()
	rib_hb.add_theme_constant_override("separation", 6)
	ribbon_pill.add_child(rib_hb)
	rib_hb.add_child(StorybookUI.make_icon("star", 18.0, StorybookUI.HONEY_LIGHT, StorybookUI.WALNUT_DARK))
	var ribbon_lbl := _label("POS 1: GERBANG AWAL", 15, COLOR_CREAM, _font_display)
	rib_hb.add_child(ribbon_lbl)

	var title_lbl := _label("Peta Emosi: Catatan Penjelajah", 23, COLOR_INK, _font_display)
	title_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_row.add_child(title_lbl)

	# Voice & Close Actions with crisp drawn vector icons
	var audio_btn := _action_btn("", COLOR_PARCHMENT_INNER, COLOR_GOLD_BRASS, COLOR_INK, 14)
	audio_btn.custom_minimum_size = Vector2(150, 40)
	var ahb := HBoxContainer.new()
	ahb.alignment = BoxContainer.ALIGNMENT_CENTER
	ahb.add_theme_constant_override("separation", 7)
	ahb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ahb.set_anchors_preset(Control.PRESET_FULL_RECT)
	audio_btn.add_child(ahb)
	ahb.add_child(StorybookUI.make_icon("sound_on", 18.0, StorybookUI.INK, StorybookUI.WALNUT))
	ahb.add_child(_label("Dengar Suara", 14, COLOR_INK, _font_display))
	audio_btn.pressed.connect(func() -> void: Audio.play_voice("goleman_quote"))
	top_row.add_child(audio_btn)

	var close_btn := _action_btn("Tutup", Color(0.96, 0.88, 0.86), COLOR_RIBBON_RED, COLOR_RIBBON_DARK, 14)
	close_btn.custom_minimum_size = Vector2(82, 40)
	close_btn.pressed.connect(func() -> void:
		Audio.play_sfx("select")
		close_modal()
	)
	top_row.add_child(close_btn)

	# 4. Two-Column Storybook Layout
	var mid_cols := HBoxContainer.new()
	mid_cols.size_flags_vertical = Control.SIZE_EXPAND_FILL
	mid_cols.add_theme_constant_override("separation", 22)
	v_main.add_child(mid_cols)

	# === LEFT: PAPAN KAYU ASLI SESUAI GAMBAR SCREENSHOT ===
	var left_col := PanelContainer.new()
	left_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var left_st := StyleBoxFlat.new()
	left_st.bg_color = Color(0.92, 0.84, 0.70) # Darker antique parchment
	left_st.border_color = COLOR_WOOD_MID
	left_st.set_border_width_all(3)
	left_st.border_width_left = 8
	left_st.set_corner_radius_all(18)
	left_st.content_margin_left = 22
	left_st.content_margin_right = 22
	left_st.content_margin_top = 18
	left_st.content_margin_bottom = 18
	left_col.add_theme_stylebox_override("panel", left_st)
	mid_cols.add_child(left_col)

	var v_left := VBoxContainer.new()
	v_left.add_theme_constant_override("separation", 10)
	left_col.add_child(v_left)

	var plank_badge := _label("PAPAN RESMI INFOGRAFIS", 13, COLOR_INK_SOFT, _font_display)
	v_left.add_child(plank_badge)

	var main_title := _label("Emosi adalah...", 26, COLOR_INK, _font_book)
	v_left.add_child(main_title)

	var quote_body := _label(
		"\"Suatu perasaan dan pikiran yang khas, suatu keadaan biologis dan psikologis dan serangkaian kecenderungan untuk bertindak.\"",
		19,
		COLOR_INK
	)
	quote_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	quote_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v_left.add_child(quote_body)

	# Author & History Footnote
	var author_plate := PanelContainer.new()
	var ap_st := StyleBoxFlat.new()
	ap_st.bg_color = COLOR_PARCHMENT_INNER
	ap_st.border_color = COLOR_GOLD_BRASS
	ap_st.set_border_width_all(2)
	ap_st.set_corner_radius_all(12)
	ap_st.content_margin_left = 14
	ap_st.content_margin_right = 14
	ap_st.content_margin_top = 8
	ap_st.content_margin_bottom = 8
	author_plate.add_theme_stylebox_override("panel", ap_st)
	v_left.add_child(author_plate)

	var ap_v := VBoxContainer.new()
	ap_v.add_theme_constant_override("separation", 2)
	author_plate.add_child(ap_v)

	var author_lbl := _label("Daniel Goleman (2022)", 15, COLOR_INK, _font_display)
	ap_v.add_child(author_lbl)
	var bio_lbl := _label("Psikolog pencetus teori Kecerdasan Emosional (EQ)", 13, COLOR_INK_SOFT)
	ap_v.add_child(bio_lbl)

	# === RIGHT: TANTANGAN 3 KANCING BUKTI NARA ===
	var right_col := PanelContainer.new()
	right_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var right_st := StyleBoxFlat.new()
	right_st.bg_color = COLOR_PARCHMENT_INNER
	right_st.border_color = COLOR_GOLD_BRASS
	right_st.set_border_width_all(2)
	right_st.border_width_right = 6
	right_st.set_corner_radius_all(18)
	right_st.content_margin_left = 20
	right_st.content_margin_right = 20
	right_st.content_margin_top = 16
	right_st.content_margin_bottom = 16
	right_col.add_theme_stylebox_override("panel", right_st)
	mid_cols.add_child(right_col)

	var v_right := VBoxContainer.new()
	v_right.add_theme_constant_override("separation", 10)
	right_col.add_child(v_right)

	# Header Right: Nara Dialogue
	var h_nara := HBoxContainer.new()
	h_nara.add_theme_constant_override("separation", 14)
	v_right.add_child(h_nara)

	_portrait = NaraPortraitScript.new()
	_portrait.custom_minimum_size = Vector2(72, 72)
	_portrait.call("set_expression", "curious")
	h_nara.add_child(_portrait)

	var nara_speech := _label(
		"Nara bertanya:\n\"Berdasarkan catatan Goleman di sebelah, pilih 3 pilar yang menjadi tanda emosi di tubuh kita:\"",
		16,
		COLOR_INK
	)
	nara_speech.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	nara_speech.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	h_nara.add_child(nara_speech)

	# 4 Chunky Interactive Cards
	_cards_vbox = VBoxContainer.new()
	_cards_vbox.add_theme_constant_override("separation", 8)
	v_right.add_child(_cards_vbox)

	var options_data := [
		{"id": "pikiran", "title": "Pikiran yang khas", "desc": "Otak dan pikiran merespons situasi", "correct": true},
		{"id": "biologis", "title": "Keadaan biologis & tubuh", "desc": "Detak jantung, nafas, dan sensasi fisik", "correct": true},
		{"id": "tindakan", "title": "Kecenderungan bertindak", "desc": "Refleks tubuh untuk bergerak atau bersuara", "correct": true},
		{"id": "makan", "title": "Perut lapar belum makan", "desc": "Kebutuhan makanan pokok tubuh sehari-hari", "correct": false}
	]
	options_data.shuffle()

	_option_cards.clear()
	for opt in options_data:
		var card := _build_chunky_card(opt)
		_option_cards.append(card)
		_cards_vbox.add_child(card)

	# Feedback Text
	_feedback_lbl = _label("Ketuk 3 kartu yang menjadi unsur emosi menurut Goleman!", 15, COLOR_INK_SOFT)
	_feedback_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v_right.add_child(_feedback_lbl)

	# 5. Bottom Ribbon Bar: Rewards & Confirmation Button
	var bottom_row := HBoxContainer.new()
	bottom_row.add_theme_constant_override("separation", 14)
	v_main.add_child(bottom_row)

	var rw_plate := PanelContainer.new()
	var rw_st := StyleBoxFlat.new()
	rw_st.bg_color = COLOR_PARCHMENT_INNER
	rw_st.border_color = COLOR_GOLD_BRASS
	rw_st.set_border_width_all(2)
	rw_st.set_corner_radius_all(14)
	rw_st.content_margin_left = 16
	rw_st.content_margin_right = 16
	rw_st.content_margin_top = 8
	rw_st.content_margin_bottom = 8
	rw_plate.add_theme_stylebox_override("panel", rw_st)
	bottom_row.add_child(rw_plate)

	var rw_hb := HBoxContainer.new()
	rw_hb.add_theme_constant_override("separation", 8)
	rw_plate.add_child(rw_hb)
	rw_hb.add_child(_label("Hadiah:", 15, COLOR_INK_SOFT, _font_display))
	rw_hb.add_child(StorybookUI.make_icon("star", 20.0, StorybookUI.HONEY, StorybookUI.WALNUT))
	rw_hb.add_child(_label("1 Bintang Pos 1", 15, COLOR_INK, _font_display))
	rw_hb.add_child(StorybookUI.make_icon("coin", 20.0, StorybookUI.HONEY, StorybookUI.WALNUT))
	rw_hb.add_child(_label("+15 Koin Emas", 15, COLOR_INK, _font_display))

	var b_spacer := Control.new()
	b_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bottom_row.add_child(b_spacer)

	_confirm_btn = _action_btn("Periksa Bukti & Buka Gerbang Pos 2", COLOR_RIBBON_RED, COLOR_RIBBON_DARK, COLOR_CREAM, 17, _font_display)
	_confirm_btn.custom_minimum_size = Vector2(320, 46)
	_confirm_btn.pressed.connect(_on_check_answers)
	bottom_row.add_child(_confirm_btn)


func _build_chunky_card(data: Dictionary) -> PanelContainer:
	var card := PanelContainer.new()
	var opt_id: String = str(data["id"])
	card.set_meta("opt_id", opt_id)
	card.set_meta("is_correct", bool(data["correct"]))

	var btn := Button.new()
	btn.flat = true
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn.set_anchors_preset(Control.PRESET_FULL_RECT)

	var h_box := HBoxContainer.new()
	h_box.add_theme_constant_override("separation", 12)
	card.add_child(h_box)

	# Tactile Vector Checkbox Badge
	var check_box := PanelContainer.new()
	check_box.custom_minimum_size = Vector2(28, 28)
	check_box.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	check_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var check_ic := StorybookUI.make_icon("check", 16.0, StorybookUI.CREAM, StorybookUI.CREAM)
	check_ic.visible = false
	var cc := CenterContainer.new()
	cc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cc.add_child(check_ic)
	check_box.add_child(cc)
	h_box.add_child(check_box)
	card.set_meta("check_box", check_box)
	card.set_meta("check_icon", check_ic)

	# Text details
	var text_v := VBoxContainer.new()
	text_v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_v.add_theme_constant_override("separation", 1)
	h_box.add_child(text_v)

	var title := _label(str(data["title"]), 16, COLOR_INK, _font_display)
	text_v.add_child(title)

	var desc := _label(str(data["desc"]), 13, COLOR_INK_SOFT)
	text_v.add_child(desc)

	card.add_child(btn)
	btn.pressed.connect(func() -> void:
		_toggle_card(opt_id)
	)

	_style_card(card, false)
	return card


func _toggle_card(opt_id: String) -> void:
	if _is_completed:
		return
	Audio.play_sfx("select")
	if _selected_options.has(opt_id):
		_selected_options.erase(opt_id)
	else:
		_selected_options[opt_id] = true

	_refresh_card_visuals()
	var count := _selected_options.size()
	_feedback_lbl.text = "Terpilih %d/3 tanda. Siap diperiksa!" % count
	_portrait.call("set_expression", "curious")


func _shuffle_cards() -> void:
	if _cards_vbox == null or _option_cards.is_empty():
		return
	var shuffled := _option_cards.duplicate()
	shuffled.shuffle()
	for i in range(shuffled.size()):
		_cards_vbox.move_child(shuffled[i], i)


func _refresh_card_visuals() -> void:
	for card in _option_cards:
		var opt_id: String = str(card.get_meta("opt_id"))
		var is_selected := _selected_options.has(opt_id)
		_style_card(card, is_selected)
		var check_box: PanelContainer = card.get_meta("check_box") as PanelContainer
		var check_ic: Control = card.get_meta("check_icon") as Control
		if check_box != null:
			check_box.add_theme_stylebox_override("panel", StorybookUI.make_panel_box(
				COLOR_CARD_BORDER_SEL if is_selected else StorybookUI.PAPER,
				COLOR_CARD_BORDER_SEL if is_selected else StorybookUI.WALNUT,
				14, 2, 2, 0, 0, false
			))
		if check_ic != null:
			check_ic.visible = is_selected


func _style_card(card: PanelContainer, selected: bool) -> void:
	var st := StyleBoxFlat.new()
	st.bg_color = COLOR_CARD_SELECTED if selected else COLOR_CARD_UNSELECTED
	st.border_color = COLOR_CARD_BORDER_SEL if selected else COLOR_GOLD_BRASS.lerp(COLOR_WOOD_MID, 0.4)
	st.set_border_width_all(2 if not selected else 3)
	st.border_width_bottom = 4
	st.set_corner_radius_all(14)
	st.content_margin_left = 14
	st.content_margin_right = 14
	st.content_margin_top = 8
	st.content_margin_bottom = 8
	card.add_theme_stylebox_override("panel", st)


func _on_check_answers() -> void:
	if _is_completed:
		close_modal()
		return

	var has_pikiran := _selected_options.has("pikiran")
	var has_biologis := _selected_options.has("biologis")
	var has_tindakan := _selected_options.has("tindakan")
	var has_makan := _selected_options.has("makan")

	if has_pikiran and has_biologis and has_tindakan and not has_makan:
		_is_completed = true
		Audio.play_sfx("star")
		Audio.play_music("bgm_victory", false)
		Audio.play_voice("goleman_correct")
		Game.complete_station(1, 15, 1)

		_portrait.call("set_expression", "celebrate")
		_feedback_lbl.text = "Tepat sekali! Menurut Daniel Goleman, emosi adalah sinergi Pikiran, Tubuh Biologis, dan Tindakan!"
		_feedback_lbl.add_theme_color_override("font_color", Color(0.08, 0.50, 0.22))

		_confirm_btn.text = "Selesai! Lanjut Jelajahi Taman"
		_apply_btn_style(_confirm_btn, Color(0.082, 0.502, 0.239), Color(0.055, 0.35, 0.16), COLOR_CREAM)
		_confirm_btn.grab_focus()
		Game.notify("Pos 1 selesai! Gerbang menuju Pos 2 (Taman 6 Emosi Dasar) siap dijelajahi.", "success")
	else:
		Audio.play_sfx("wrong")
		Audio.play_voice("goleman_wrong")
		_portrait.call("set_expression", "surprised")
		if has_makan:
			_feedback_lbl.text = "Perut lapar adalah kebutuhan makan, bukan unsur emosi! Lihat kembali papan di kiri ya!"
		else:
			_feedback_lbl.text = "Belum tepat! Pilih 3 tanda yang tercatat jelas di papan Daniel Goleman ya!"
		_feedback_lbl.add_theme_color_override("font_color", Color(0.78, 0.15, 0.12))


func _label(text: String, size: int, col: Color, custom_font: Font = null) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", custom_font if custom_font != null else _font_ui)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	return l


func _action_btn(text: String, bg: Color, border: Color, fg: Color, font_size: int = 17, custom_font: Font = null) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, 44)
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	b.add_theme_font_override("font", custom_font if custom_font != null else _font_ui)
	b.add_theme_font_size_override("font_size", font_size)
	_apply_btn_style(b, bg, border, fg)
	return b


func _apply_btn_style(b: Button, bg: Color, border: Color, fg: Color) -> void:
	b.add_theme_color_override("font_color", fg)
	b.add_theme_color_override("font_hover_color", fg)
	b.add_theme_color_override("font_pressed_color", fg)
	b.add_theme_color_override("font_focus_color", fg)

	var normal := StyleBoxFlat.new()
	normal.bg_color = bg
	normal.border_color = border
	normal.set_border_width_all(2)
	normal.border_width_bottom = 5
	normal.set_corner_radius_all(14)
	normal.content_margin_left = 18
	normal.content_margin_right = 18

	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = bg.lightened(0.08)

	var pressed := normal.duplicate() as StyleBoxFlat
	pressed.bg_color = bg.darkened(0.08)
	pressed.border_width_bottom = 2

	b.add_theme_stylebox_override("normal", normal)
	b.add_theme_stylebox_override("hover", hover)
	b.add_theme_stylebox_override("pressed", pressed)
	b.add_theme_stylebox_override("focus", hover)
