class_name DialogPos4
extends CanvasLayer

signal closed

const COLOR_INK := Color("2c1810")
const COLOR_INK_SOFT := Color("5e3c28")
const COLOR_PARCHMENT := Color("f7ecd5")
const COLOR_PARCHMENT_INNER := Color("fffbf0")
const COLOR_WOOD_DARK := Color("42220f")
const COLOR_WOOD_MID := Color("6b3d1b")
const COLOR_GOLD_BRASS := Color("d49826")
const COLOR_OK_BG := Color("e8f6ec")
const COLOR_OK_BORDER := Color("2d8647")
const COLOR_CREAM := Color("fff8eb")

var _font_ui: Font
var _font_display: Font
var _frame: PanelContainer


func _ready() -> void:
	layer = 20
	_font_ui = StorybookUI.font_body(580)
	_font_display = StorybookUI.font_display()
	_build_ui()
	visible = false


func open_summary() -> void:
	Game.modal_open = true
	visible = true
	if _frame != null:
		_frame.scale = Vector2(0.94, 0.94)
		_frame.modulate = Color(1, 1, 1, 0)
		var tw := create_tween().set_parallel(true)
		tw.tween_property(_frame, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(_frame, "modulate:a", 1.0, 0.18)


func close_summary() -> void:
	visible = false
	Game.modal_open = false
	closed.emit()


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		close_summary()
		get_viewport().set_input_as_handled()


func _build_ui() -> void:
	var backdrop := ColorRect.new()
	backdrop.color = Color(0.04, 0.03, 0.02, 0.60)
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	backdrop.add_child(center)

	_frame = PanelContainer.new()
	_frame.custom_minimum_size = Vector2(880, 510)
	_frame.pivot_offset = Vector2(440, 255)
	_frame.add_theme_stylebox_override("panel", StorybookUI.make_panel_box(
		Color("f2f9fc"), StorybookUI.LAGOON_DARK, 24, 4, 10, 24, 20, true
	))
	center.add_child(_frame)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	_frame.add_child(v)

	var badge := PanelContainer.new()
	badge.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	badge.add_theme_stylebox_override("panel", StorybookUI.make_panel_box(
		StorybookUI.LAGOON, StorybookUI.LAGOON_DARK, 10, 2, 4, 14, 5, false
	))
	var bhb := HBoxContainer.new()
	bhb.add_theme_constant_override("separation", 8)
	badge.add_child(bhb)
	bhb.add_child(StorybookUI.make_icon("star", 18.0, StorybookUI.HONEY_LIGHT, StorybookUI.WALNUT_DARK))
	bhb.add_child(_label("POS 4 SELESAI: HATI SEJUK & DAMAI", 14, COLOR_CREAM, _font_display))
	bhb.add_child(StorybookUI.make_icon("star", 18.0, StorybookUI.HONEY_LIGHT, StorybookUI.WALNUT_DARK))
	v.add_child(badge)

	var title := _label("6 Langkah Saat Merasa Marah", 26, StorybookUI.INK, _font_display)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(title)

	var sub := _label("Kamu baru saja mempraktikkan langsung ke-6 langkah menenangkan diri di taman!", 15, StorybookUI.INK_SOFT)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(sub)

	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", 10)
	grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(grid)

	var steps := [
		["1. Berhenti dulu", "Berhenti sejenak di zona STOP sebelum bertindak."],
		["2. Tahan untuk memukul", "Simpan tangan dengan aman, jangan merusak atau memukul."],
		["3. Tarik nafas", "Tarik nafas dalam & hembuskan pelan seperti meniup kincir."],
		["4. Hitung sampai 10", "Hitung perlahan 1 sampai 10 agar amarah mereda."],
		["5. Cari tempat nyaman", "Duduk santai sejenak di pojok yang teduh dan tenang."],
		["6. Menjauh dari sumber marah", "Beri jarak dari pemicu kesal sampai hati kembali sejuk."],
	]
	for item in steps:
		var card := PanelContainer.new()
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card.add_theme_stylebox_override("panel", StorybookUI.make_panel_box(
			Color("e6f6ee"), StorybookUI.EMERALD, 14, 2, 4, 12, 8, false
		))
		var chb := HBoxContainer.new()
		chb.add_theme_constant_override("separation", 10)
		card.add_child(chb)
		var ck_wrap := PanelContainer.new()
		ck_wrap.custom_minimum_size = Vector2(28, 28)
		ck_wrap.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		ck_wrap.add_theme_stylebox_override("panel", StorybookUI.make_panel_box(
			StorybookUI.EMERALD, StorybookUI.EMERALD_DARK, 14, 2, 2, 0, 0, false
		))
		var ckc := CenterContainer.new()
		ckc.add_child(StorybookUI.make_icon("check", 16.0, StorybookUI.CREAM, StorybookUI.CREAM))
		ck_wrap.add_child(ckc)
		chb.add_child(ck_wrap)
		var cv := VBoxContainer.new()
		cv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		cv.add_theme_constant_override("separation", 2)
		chb.add_child(cv)
		cv.add_child(_label(item[0], 15, StorybookUI.EMERALD_DARK, _font_display))
		var dl := _label(item[1], 13, StorybookUI.INK)
		dl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		cv.add_child(dl)
		grid.add_child(card)

	var ok_btn := Button.new()
	ok_btn.text = "Lanjut ke Gerbang Pos 5!"
	ok_btn.custom_minimum_size = Vector2(0, 48)
	StorybookUI.style_tactile_button(ok_btn, StorybookUI.EMERALD, StorybookUI.EMERALD_DARK, StorybookUI.CREAM, _font_display, 17, 14, 20, 8)
	ok_btn.pressed.connect(close_summary)
	v.add_child(ok_btn)


func _label(text: String, size: int, col: Color, custom_font: Font = null) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", custom_font if custom_font != null else _font_ui)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	return l

