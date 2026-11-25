class_name EmotionBalancePos3
extends CanvasLayer

signal balanced
signal closed

const COLOR_INK := Color("2c1810")
const COLOR_INK_SOFT := Color("5e3c28")
const COLOR_PARCHMENT := Color("f7ecd5")
const COLOR_PARCHMENT_INNER := Color("fffbf0")
const COLOR_WOOD_DARK := Color("42220f")
const COLOR_WOOD_MID := Color("6b3d1b")
const COLOR_GOLD_BRASS := Color("d49826")
const COLOR_RIBBON_RED := Color("961d2d")
const COLOR_OK_GREEN := Color("2d8647")
const COLOR_CREAM := Color("fff8eb")

var _font_ui: Font
var _font_display: Font
var _font_book: Font

var _backdrop: ColorRect
var _frame: PanelContainer
var _scale_canvas: BalanceScaleCanvas
var _status_lbl: Label
var _hold_bar: ProgressBar
var _left_btn: Button
var _right_btn: Button
var _close_btn: Button

var _tilt: float = -0.68 # -1.0 (terlalu ditahan) .. 0.0 (seimbang) .. +1.0 (terlalu diledakkan)
var _hold_time: float = 0.0
var _solved: bool = false
var _wobble_t: float = 0.0
var _press_left: bool = false
var _press_right: bool = false
const GREEN_ZONE := 0.16
const HOLD_REQUIRED := 1.25


class BalanceScaleCanvas extends Control:
	var tilt: float = -0.68
	var in_green: bool = false
	var solved: bool = false
	var _t: float = 0.0

	func _init() -> void:
		custom_minimum_size = Vector2(680, 260)

	func _draw() -> void:
		var w := size.x
		var h := size.y
		var cx := w * 0.5
		var pivot := Vector2(cx, h * 0.48)

		# 1. Top gauge arc showing Left (Red) - Center (Green) - Right (Red)
		var gauge_c := Vector2(cx, h * 0.44)
		var gauge_r := 92.0
		var a_start := -PI * 0.80
		var a_end := -PI * 0.20
		var a_green_l := -PI * 0.50 - 0.14
		var a_green_r := -PI * 0.50 + 0.14
		draw_arc(gauge_c, gauge_r, a_start, a_green_l, 16, Color(0.86, 0.28, 0.24, 0.82), 12.0)
		draw_arc(gauge_c, gauge_r, a_green_l, a_green_r, 12, Color(0.18, 0.72, 0.36, 0.98), 16.0)
		draw_arc(gauge_c, gauge_r, a_green_r, a_end, 16, Color(0.86, 0.28, 0.24, 0.82), 12.0)

		# Needle pointing into the gauge arc
		var needle_ang := -PI * 0.50 + tilt * (PI * 0.30)
		var needle_tip := gauge_c + Vector2(cos(needle_ang), sin(needle_ang)) * (gauge_r - 8.0)
		var needle_col := Color(0.16, 0.66, 0.32) if (in_green or solved) else Color(0.76, 0.18, 0.20)
		draw_line(gauge_c, needle_tip, needle_col, 6.0)
		draw_circle(needle_tip, 7.0, needle_col)

		# 2. Wooden base & central pillar
		draw_rect(Rect2(cx - 88, h - 32, 176, 22), Color("5c3214"), true)
		draw_rect(Rect2(cx - 88, h - 32, 176, 22), Color("361a08"), false, 3.0)
		draw_rect(Rect2(cx - 14, pivot.y, 28, h - 32 - pivot.y), Color("70401c"), true)
		draw_rect(Rect2(cx - 14, pivot.y, 28, h - 32 - pivot.y), Color("361a08"), false, 3.0)

		# 3. Tilting wooden beam
		var beam_half := 215.0
		var ang := tilt * 0.34 # radians
		var dir := Vector2(cos(ang), sin(ang))
		var left_end := pivot - dir * beam_half
		var right_end := pivot + dir * beam_half
		draw_line(left_end, right_end, Color("361a08"), 18.0)
		draw_line(left_end, right_end, Color("8a5224"), 12.0)

		# Brass center hub
		draw_circle(pivot, 16.0, Color("d49826"))
		draw_arc(pivot, 16.0, 0.0, TAU, 20, Color("42220f"), 3.0)
		draw_circle(pivot, 6.0, Color("fff8eb"))

		# 4. Hanging Pans + Icons
		_draw_pan(left_end, "bottle")
		_draw_pan(right_end, "firecracker")

	func _draw_pan(anchor: Vector2, icon_kind: String) -> void:
		var pan_y := anchor.y + 62.0
		var pan_c := Vector2(anchor.x, pan_y)
		# Golden hanging chains
		draw_line(anchor, Vector2(pan_c.x - 44, pan_y), Color("b8801c"), 2.6)
		draw_line(anchor, Vector2(pan_c.x + 44, pan_y), Color("b8801c"), 2.6)
		draw_circle(anchor, 5.5, Color("d49826"))

		# Pan bowl
		draw_rect(Rect2(pan_c.x - 52, pan_y, 104, 14), Color("d49826"), true)
		draw_rect(Rect2(pan_c.x - 52, pan_y, 104, 14), Color("42220f"), false, 2.5)

		if icon_kind == "bottle":
			# Soda bottle ("Ditahan") sitting on left pan
			var bx := pan_c.x
			var by := pan_y
			draw_rect(Rect2(bx - 16, by - 36, 32, 36), Color(0.88, 0.24, 0.22), true)
			draw_rect(Rect2(bx - 16, by - 36, 32, 36), Color("2c1810"), false, 2.2)
			draw_rect(Rect2(bx - 8, by - 48, 16, 13), Color(0.92, 0.32, 0.28), true)
			draw_rect(Rect2(bx - 8, by - 48, 16, 13), Color("2c1810"), false, 2.0)
			draw_rect(Rect2(bx - 9, by - 55, 18, 8), Color(0.76, 0.50, 0.24), true)
			draw_rect(Rect2(bx - 12, by - 22, 24, 9), Color(1.0, 0.94, 0.78), true)
		else:
			# Firecracker ("Diledakkan") sitting on right pan
			var fx := pan_c.x
			var fy := pan_y
			draw_rect(Rect2(fx - 13, fy - 42, 26, 42), Color(0.90, 0.20, 0.20), true)
			draw_rect(Rect2(fx - 13, fy - 42, 26, 42), Color("2c1810"), false, 2.2)
			draw_rect(Rect2(fx - 13, fy - 26, 26, 7), Color(0.98, 0.78, 0.18), true)
			draw_line(Vector2(fx, fy - 42), Vector2(fx + 6, fy - 54), Color("361a08"), 2.5)
			if not solved:
				var sp := Vector2(fx + 8, fy - 56)
				for i in range(6):
					var a := float(i) * TAU / 6.0 + _t * 4.0
					draw_line(sp, sp + Vector2(cos(a) * 11.0, sin(a) * 11.0), Color(1.0, 0.58, 0.12), 2.2)
				draw_circle(sp, 4.5, Color(1.0, 0.92, 0.35))


func _ready() -> void:
	layer = 22
	_font_ui = StorybookUI.font_body(580)
	_font_display = StorybookUI.font_display()
	_font_book = StorybookUI.font_serif()
	_build_ui()
	visible = false


func open_balance(already_solved: bool) -> void:
	_solved = already_solved
	_tilt = 0.0 if already_solved else (-0.68 if randf() < 0.5 else 0.68)
	_hold_time = HOLD_REQUIRED if already_solved else 0.0
	_press_left = false
	_press_right = false
	Game.modal_open = true
	visible = true
	_sync_ui()

	if _frame != null:
		_frame.scale = Vector2(0.94, 0.94)
		_frame.modulate = Color(1, 1, 1, 0)
		var tw := create_tween().set_parallel(true)
		tw.tween_property(_frame, "scale", Vector2.ONE, 0.24).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(_frame, "modulate:a", 1.0, 0.18)


func close_balance() -> void:
	_press_left = false
	_press_right = false
	visible = false
	Game.modal_open = false
	closed.emit()


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel"):
		close_balance()
		get_viewport().set_input_as_handled()


func _process(delta: float) -> void:
	if not visible:
		return
	_wobble_t += delta
	_scale_canvas._t = _wobble_t

	if not _solved:
		var move_dir := 0.0
		if _press_left or Input.is_action_pressed("move_left") or Input.is_key_pressed(KEY_LEFT):
			move_dir -= 1.0
		if _press_right or Input.is_action_pressed("move_right") or Input.is_key_pressed(KEY_RIGHT):
			move_dir += 1.0

		# Gentle emotional wobble keeps the scale lively until balanced
		var wobble := sin(_wobble_t * 2.1) * 0.09
		_tilt = clampf(_tilt + (move_dir * 0.95 + wobble) * delta, -0.92, 0.92)

		var in_green := absf(_tilt) <= GREEN_ZONE
		if in_green:
			_hold_time = minf(HOLD_REQUIRED, _hold_time + delta)
			if _hold_time >= HOLD_REQUIRED:
				_on_balanced_success()
		else:
			_hold_time = maxf(0.0, _hold_time - delta * 0.7)
	else:
		_tilt = lerpf(_tilt, 0.0, clampf(delta * 6.0, 0.0, 1.0))

	_sync_ui()


func _nudge(amount: float) -> void:
	if _solved:
		return
	_tilt = clampf(_tilt + amount, -0.92, 0.92)
	Audio.play_sfx("select")
	_sync_ui()


func _on_balanced_success() -> void:
	_solved = true
	_tilt = 0.0
	_hold_time = HOLD_REQUIRED
	Game.add_coins(5)
	Audio.play_sfx("coin")
	Audio.play_sfx("sparkle")
	balanced.emit()
	_sync_ui()


func _sync_ui() -> void:
	var in_green := absf(_tilt) <= GREEN_ZONE
	_scale_canvas.tilt = _tilt
	_scale_canvas.in_green = in_green
	_scale_canvas.solved = _solved
	_scale_canvas.queue_redraw()

	_hold_bar.value = clampf((_hold_time / HOLD_REQUIRED) * 100.0, 0.0, 100.0)

	if _solved:
		_status_lbl.text = "SEIMBANG! Emosi berhasil diatur dengan baik! (+5 Koin) Ayo lanjut ke Papan Aturan!"
		_status_lbl.add_theme_color_override("font_color", COLOR_OK_GREEN)
		_left_btn.disabled = true
		_right_btn.disabled = true
		_close_btn.text = "Lanjut ke Papan Aturan Emosi"
	elif in_green:
		_status_lbl.text = "Bagus! Tahan jarum di zona HIJAU sampai penuh..."
		_status_lbl.add_theme_color_override("font_color", COLOR_OK_GREEN)
		_left_btn.disabled = false
		_right_btn.disabled = false
		_close_btn.text = "Tutup Sebentar (Esc)"
	elif _tilt < -GREEN_ZONE:
		_status_lbl.text = "Terlalu ke Kiri (DITAHAN)! Klik/Tahan 'Geser Kanan' atau tombol D / Panah Kanan"
		_status_lbl.add_theme_color_override("font_color", COLOR_RIBBON_RED)
		_left_btn.disabled = false
		_right_btn.disabled = false
		_close_btn.text = "Tutup Sebentar (Esc)"
	else:
		_status_lbl.text = "Terlalu ke Kanan (DILEDAKKAN)! Klik/Tahan 'Geser Kiri' atau tombol A / Panah Kiri"
		_status_lbl.add_theme_color_override("font_color", COLOR_RIBBON_RED)
		_left_btn.disabled = false
		_right_btn.disabled = false
		_close_btn.text = "Tutup Sebentar (Esc)"


func _build_ui() -> void:
	_backdrop = ColorRect.new()
	_backdrop.color = Color(0.04, 0.03, 0.02, 0.58)
	_backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_backdrop)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_backdrop.add_child(center)

	_frame = PanelContainer.new()
	_frame.custom_minimum_size = Vector2(780, 520)
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
	pst.content_margin_left = 24
	pst.content_margin_right = 24
	pst.content_margin_top = 16
	pst.content_margin_bottom = 16
	parchment.add_theme_stylebox_override("panel", pst)
	_frame.add_child(parchment)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	parchment.add_child(v)

	# Header
	var hdr := HBoxContainer.new()
	v.add_child(hdr)

	var badge := PanelContainer.new()
	var bst := StyleBoxFlat.new()
	bst.bg_color = COLOR_RIBBON_RED
	bst.border_color = COLOR_GOLD_BRASS
	bst.set_border_width_all(2)
	bst.set_corner_radius_all(10)
	bst.content_margin_left = 14
	bst.content_margin_right = 14
	bst.content_margin_top = 5
	bst.content_margin_bottom = 5
	badge.add_theme_stylebox_override("panel", bst)
	badge.add_child(_label("MINI-GAME POS 3 • TIMBANGAN EMOSI", 14, COLOR_CREAM, _font_display))
	hdr.add_child(badge)

	var title := _label("Seimbangkan Emosi Marahmu!", 24, COLOR_INK, _font_display)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(title)

	var subtitle := _label("Jangan terlalu ditahan di kiri, jangan terlalu diledakkan di kanan. Arahkan jarum ke zona HIJAU!", 14, COLOR_INK_SOFT)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(subtitle)

	# Scale panel
	var scale_box := PanelContainer.new()
	var sbst := StyleBoxFlat.new()
	sbst.bg_color = COLOR_PARCHMENT_INNER
	sbst.border_color = Color(0.84, 0.74, 0.56)
	sbst.set_border_width_all(2)
	sbst.set_corner_radius_all(16)
	sbst.content_margin_left = 10
	sbst.content_margin_right = 10
	sbst.content_margin_top = 8
	sbst.content_margin_bottom = 8
	scale_box.add_theme_stylebox_override("panel", sbst)
	v.add_child(scale_box)

	var sv := VBoxContainer.new()
	sv.add_theme_constant_override("separation", 2)
	scale_box.add_child(sv)

	var labels_row := HBoxContainer.new()
	sv.add_child(labels_row)
	var l_hb := HBoxContainer.new()
	l_hb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l_hb.add_theme_constant_override("separation", 5)
	l_hb.add_child(StorybookUI.make_icon("play_left", 13.0, COLOR_RIBBON_RED, COLOR_RIBBON_RED))
	l_hb.add_child(_label("JANGAN DITAHAN", 14, COLOR_RIBBON_RED, _font_display))

	var c_hb := HBoxContainer.new()
	c_hb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	c_hb.alignment = BoxContainer.ALIGNMENT_CENTER
	c_hb.add_theme_constant_override("separation", 5)
	c_hb.add_child(StorybookUI.make_icon("star", 15.0, StorybookUI.HONEY, StorybookUI.WALNUT))
	c_hb.add_child(_label("SEIMBANG", 15, COLOR_OK_GREEN, _font_display))
	c_hb.add_child(StorybookUI.make_icon("star", 15.0, StorybookUI.HONEY, StorybookUI.WALNUT))

	var r_hb := HBoxContainer.new()
	r_hb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	r_hb.alignment = BoxContainer.ALIGNMENT_END
	r_hb.add_theme_constant_override("separation", 5)
	r_hb.add_child(_label("JANGAN DILEDAKKAN", 14, COLOR_RIBBON_RED, _font_display))
	r_hb.add_child(StorybookUI.make_icon("play_right", 13.0, COLOR_RIBBON_RED, COLOR_RIBBON_RED))

	labels_row.add_child(l_hb)
	labels_row.add_child(c_hb)
	labels_row.add_child(r_hb)

	_scale_canvas = BalanceScaleCanvas.new()
	_scale_canvas.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sv.add_child(_scale_canvas)

	# Green calm fill bar
	_hold_bar = ProgressBar.new()
	_hold_bar.min_value = 0.0
	_hold_bar.max_value = 100.0
	_hold_bar.value = 0.0
	_hold_bar.show_percentage = false
	_hold_bar.custom_minimum_size = Vector2(0, 14)
	var bg_bar := StyleBoxFlat.new()
	bg_bar.bg_color = Color(0.88, 0.83, 0.74)
	bg_bar.set_corner_radius_all(7)
	var fg_bar := StyleBoxFlat.new()
	fg_bar.bg_color = COLOR_OK_GREEN
	fg_bar.set_corner_radius_all(7)
	_hold_bar.add_theme_stylebox_override("background", bg_bar)
	_hold_bar.add_theme_stylebox_override("fill", fg_bar)
	v.add_child(_hold_bar)

	_status_lbl = _label("", 15, COLOR_INK)
	_status_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(_status_lbl)

	# Controls row
	var controls := HBoxContainer.new()
	controls.add_theme_constant_override("separation", 14)
	v.add_child(controls)

	_left_btn = _btn("", Color(0.24, 0.54, 0.86), Color(0.16, 0.38, 0.66), Color.WHITE, 16)
	_left_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var lb_hb := HBoxContainer.new()
	lb_hb.set_anchors_preset(Control.PRESET_FULL_RECT)
	lb_hb.alignment = BoxContainer.ALIGNMENT_CENTER
	lb_hb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lb_hb.add_theme_constant_override("separation", 8)
	lb_hb.add_child(StorybookUI.make_icon("play_left", 15.0, Color.WHITE, Color(0.10, 0.28, 0.52)))
	lb_hb.add_child(_label("Geser Kiri (A)", 16, Color.WHITE, _font_display))
	_left_btn.add_child(lb_hb)
	_left_btn.button_down.connect(func() -> void: _press_left = true)
	_left_btn.button_up.connect(func() -> void: _press_left = false)
	_left_btn.pressed.connect(func() -> void: _nudge(-0.14))
	controls.add_child(_left_btn)

	_right_btn = _btn("", Color(0.86, 0.50, 0.14), Color(0.64, 0.34, 0.08), Color.WHITE, 16)
	_right_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var rb_hb := HBoxContainer.new()
	rb_hb.set_anchors_preset(Control.PRESET_FULL_RECT)
	rb_hb.alignment = BoxContainer.ALIGNMENT_CENTER
	rb_hb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rb_hb.add_theme_constant_override("separation", 8)
	rb_hb.add_child(_label("Geser Kanan (D)", 16, Color.WHITE, _font_display))
	rb_hb.add_child(StorybookUI.make_icon("play_right", 15.0, Color.WHITE, Color(0.48, 0.24, 0.04)))
	_right_btn.add_child(rb_hb)
	_right_btn.button_down.connect(func() -> void: _press_right = true)
	_right_btn.button_up.connect(func() -> void: _press_right = false)
	_right_btn.pressed.connect(func() -> void: _nudge(0.14))
	controls.add_child(_right_btn)

	_close_btn = _btn("Tutup Sebentar (Esc)", Color(0.95, 0.90, 0.82), COLOR_WOOD_MID, COLOR_INK, 15)
	_close_btn.custom_minimum_size = Vector2(0, 44)
	_close_btn.pressed.connect(close_balance)
	v.add_child(_close_btn)


func _btn(text: String, bg: Color, border: Color, fg: Color, size: int) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, 48)
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

