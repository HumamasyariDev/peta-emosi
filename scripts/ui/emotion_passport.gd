class_name EmotionPassport
extends CanvasLayer

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
const COLOR_OK_BG := Color("e8f6ec")
const COLOR_OK_BORDER := Color("2d8647")

var _font_ui: Font
var _font_display: Font
var _backdrop: ColorRect
var _frame: PanelContainer
var _stats_lbl: Label
var _grid: GridContainer


func _ready() -> void:
	layer = 30
	_font_ui = StorybookUI.font_body(580)
	_font_display = StorybookUI.font_display()
	_build_ui()
	visible = false


func toggle_passport() -> void:
	if visible:
		close_passport()
	elif not Game.modal_open:
		open_passport()


func open_passport() -> void:
	Game.modal_open = true
	visible = true
	_refresh_entries()
	Audio.play_sfx("select")


func close_passport() -> void:
	visible = false
	Game.modal_open = false
	Audio.play_sfx("select")


func _unhandled_input(event: InputEvent) -> void:
	if visible and (event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_B)):
		close_passport()
		get_viewport().set_input_as_handled()


func _build_ui() -> void:
	_backdrop = ColorRect.new()
	_backdrop.color = Color(0.04, 0.03, 0.02, 0.62)
	_backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_backdrop)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_backdrop.add_child(center)

	_frame = PanelContainer.new()
	_frame.custom_minimum_size = Vector2(880, 480)
	var wst := StyleBoxFlat.new()
	wst.bg_color = COLOR_WOOD_MID
	wst.border_color = COLOR_WOOD_DARK
	wst.set_border_width_all(6)
	wst.border_width_bottom = 10
	wst.set_corner_radius_all(28)
	wst.content_margin_left = 16
	wst.content_margin_right = 16
	wst.content_margin_top = 14
	wst.content_margin_bottom = 16
	_frame.add_theme_stylebox_override("panel", wst)
	center.add_child(_frame)

	var parchment := PanelContainer.new()
	var pst := StyleBoxFlat.new()
	pst.bg_color = COLOR_PARCHMENT
	pst.border_color = COLOR_GOLD_BRASS
	pst.set_border_width_all(3)
	pst.set_corner_radius_all(20)
	pst.content_margin_left = 22
	pst.content_margin_right = 22
	pst.content_margin_top = 16
	pst.content_margin_bottom = 16
	parchment.add_theme_stylebox_override("panel", pst)
	_frame.add_child(parchment)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	parchment.add_child(v)

	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 12)
	v.add_child(top)

	var title := _label("Paspor Koleksi Peta Emosi Nara", 22, COLOR_INK, _font_display)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(title)

	var close_btn := Button.new()
	close_btn.text = "Tutup (B / Esc)"
	close_btn.custom_minimum_size = Vector2(130, 38)
	close_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	close_btn.add_theme_font_override("font", _font_ui)
	close_btn.add_theme_font_size_override("font_size", 14)
	close_btn.add_theme_color_override("font_color", COLOR_RIBBON_DARK)
	var cst := StyleBoxFlat.new()
	cst.bg_color = Color(0.96, 0.88, 0.86)
	cst.border_color = COLOR_RIBBON_RED
	cst.set_border_width_all(2)
	cst.set_corner_radius_all(12)
	close_btn.add_theme_stylebox_override("normal", cst)
	close_btn.pressed.connect(close_passport)
	top.add_child(close_btn)

	_stats_lbl = _label("", 15, COLOR_INK_SOFT)
	v.add_child(_stats_lbl)

	_grid = GridContainer.new()
	_grid.columns = 3
	_grid.add_theme_constant_override("h_separation", 12)
	_grid.add_theme_constant_override("v_separation", 12)
	_grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(_grid)


func _refresh_entries() -> void:
	var pos3_badge := "Lencana Sahabat Tenang: Diraih" if Game.is_station_done(3) else "Lencana Sahabat Tenang: Belum"
	_stats_lbl.text = "Bintang Pos: %d/8   |   Koin: %d   |   Stempel Emosi: %d/6   |   %s" % [
		Game.get_completed_count(), Game.coins, Game.collected_emotions.size(), pos3_badge
	]
	for c in _grid.get_children():
		c.queue_free()

	var catalog := [
		["sedih", "1. Sedih", "Muncul saat kehilangan atau kecewa. Dada sesak & mata berkaca-kaca."],
		["marah", "2. Marah", "Muncul saat kesal/tidak adil. Muka panas & tangan mengepal."],
		["takut", "3. Takut", "Alarm agar berhati-hati. Jantung berdebar & kaki gemetar."],
		["bahagia", "4. Bahagia", "Muncul saat senang/bangga. Hati ringan & tersenyum lebar."],
		["jijik", "5. Jijik", "Menjauhkan dari hal kotor/bau. Hidung mengernyit."],
		["terkejut", "6. Terkejut", "Muncul sekejap saat ada hal tak terduga tiba-tiba."]
	]

	for item in catalog:
		var id: String = item[0]
		var unlocked: bool = Game.collected_emotions.has(id)
		var card := PanelContainer.new()
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var st := StyleBoxFlat.new()
		st.bg_color = COLOR_OK_BG if unlocked else Color(0.93, 0.89, 0.82)
		st.border_color = COLOR_OK_BORDER if unlocked else Color(0.76, 0.68, 0.56)
		st.set_border_width_all(2)
		st.set_corner_radius_all(14)
		st.content_margin_left = 14
		st.content_margin_right = 14
		st.content_margin_top = 10
		st.content_margin_bottom = 10
		card.add_theme_stylebox_override("panel", st)

		var cv := VBoxContainer.new()
		cv.add_theme_constant_override("separation", 4)
		card.add_child(cv)

		var head_row := HBoxContainer.new()
		head_row.add_theme_constant_override("separation", 6)
		if unlocked:
			head_row.add_child(StorybookUI.make_icon("check", 16.0, COLOR_OK_BORDER, COLOR_OK_BORDER))
		var head := _label(item[1], 17, COLOR_OK_BORDER if unlocked else COLOR_INK_SOFT, _font_display)
		head_row.add_child(head)
		cv.add_child(head_row)

		var body := _label(item[2] if unlocked else "Belum ditemukan. Sapa karakter emosi ini di Taman Pos 2!", 13, COLOR_INK if unlocked else COLOR_INK_SOFT)
		body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		cv.add_child(body)
		_grid.add_child(card)


func _label(text: String, size: int, col: Color, custom_font: Font = null) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", custom_font if custom_font != null else _font_ui)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	return l

