class_name DialogPos5
extends CanvasLayer

## Pos 5: Illustrated 2x2 Action Card Board ("Pilih 3 Cara Aman Menyalurkan Marah")
## Terracotta & Sky palette with custom vector illustrations and tactile stamp badges.

signal completed
signal closed

const NaraPortraitScript := preload("res://scripts/ui/nara_portrait.gd")

var _font_ui: Font
var _font_display: Font
var _backdrop: ColorRect
var _sheet: PanelContainer
var _portrait: Control
var _count_lbl: Label
var _feedback_lbl: Label
var _confirm_btn: Button
var _selected: Dictionary = {}
var _cards: Dictionary = {}
var _grid: GridContainer
var _solved: bool = false


func _ready() -> void:
	layer = 20
	_font_ui = StorybookUI.font_body(580)
	_font_display = StorybookUI.font_display()
	_build_ui()
	visible = false


func open_modal() -> void:
	Game.modal_open = true
	visible = true
	if not _solved and _grid != null:
		var kids := _grid.get_children()
		kids.shuffle()
		for i in range(kids.size()):
			_grid.move_child(kids[i], i)
	Audio.play_sfx("select")
	if _portrait != null:
		_portrait.call("set_expression", "happy" if _solved else "thinking")
	_sheet.scale = Vector2(0.94, 0.94)
	_sheet.modulate.a = 0.0
	var tw := create_tween().set_parallel(true)
	tw.tween_property(_sheet, "modulate:a", 1.0, 0.18)
	tw.tween_property(_sheet, "scale", Vector2.ONE, 0.24).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func close_modal() -> void:
	visible = false
	Game.modal_open = false
	Audio.play_sfx("select")
	closed.emit()


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		close_modal()
		get_viewport().set_input_as_handled()


func _build_ui() -> void:
	_backdrop = ColorRect.new()
	_backdrop.color = Color(0.10, 0.05, 0.04, 0.64)
	_backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_backdrop)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_backdrop.add_child(center)

	# Warm Terracotta Studio Frame (distinct from Pos 1 wood & Pos 6 sage)
	_sheet = PanelContainer.new()
	_sheet.custom_minimum_size = Vector2(880, 520)
	_sheet.pivot_offset = Vector2(440, 260)
	_sheet.add_theme_stylebox_override("panel", StorybookUI.make_panel_box(
		Color("fff6ee"), StorybookUI.TERRACOTTA_DARK, 24, 4, 10, 22, 18, true
	))
	center.add_child(_sheet)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	_sheet.add_child(v)

	# Header bar
	var hdr := HBoxContainer.new()
	hdr.add_theme_constant_override("separation", 12)
	v.add_child(hdr)

	var badge := PanelContainer.new()
	badge.add_theme_stylebox_override("panel", StorybookUI.make_panel_box(
		StorybookUI.TERRACOTTA, StorybookUI.TERRACOTTA_DARK, 10, 2, 4, 12, 5, false
	))
	badge.add_child(_label("POS 5: KARTU AKSI AMAN", 14, StorybookUI.CREAM, _font_display))
	hdr.add_child(badge)

	hdr.add_child(_label("Pilih 3 Benda Aman untuk Salurkan Kesal", 20, StorybookUI.INK, _font_display))

	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hdr.add_child(sp)

	var count_box := PanelContainer.new()
	count_box.add_theme_stylebox_override("panel", StorybookUI.make_panel_box(
		StorybookUI.PAPER_WARM, StorybookUI.HONEY, 10, 2, 3, 12, 5, false
	))
	_count_lbl = _label("Terpilih: 0 / 3", 14, StorybookUI.INK, _font_display)
	count_box.add_child(_count_lbl)
	hdr.add_child(count_box)

	var close_btn := Button.new()
	close_btn.text = "Tutup"
	close_btn.custom_minimum_size = Vector2(86, 40)
	StorybookUI.style_tactile_button(close_btn, Color("fce8e8"), StorybookUI.BERRY, StorybookUI.BERRY_DARK, _font_display, 14, 11, 12, 5)
	close_btn.pressed.connect(close_modal)
	hdr.add_child(close_btn)

	# Nara prompt strip
	var prow := HBoxContainer.new()
	prow.add_theme_constant_override("separation", 12)
	v.add_child(prow)

	_portrait = NaraPortraitScript.new()
	_portrait.custom_minimum_size = Vector2(58, 58)
	prow.add_child(_portrait)

	var q_lbl := _label("Energi kesal boleh dikeluarkan supaya dada lega, asal tidak menyakiti siapa pun. Ketuk 3 kartu benda yang AMAN!", 15, StorybookUI.INK_SOFT)
	q_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	q_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	prow.add_child(q_lbl)

	# 2x2 Visual Action Card Grid (distinct from vertical checklist!)
	_grid = GridContainer.new()
	_grid.columns = 2
	_grid.add_theme_constant_override("h_separation", 14)
	_grid.add_theme_constant_override("v_separation", 14)
	_grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(_grid)

	var options := [
		{"id": "bantal", "icon": "pillow", "icol": Color("dff2fb"), "irim": StorybookUI.LAGOON, "title": "Pukul Bantal Empuk", "desc": "Lembut dan aman, tidak menyakiti tangan atau orang lain."},
		{"id": "kertas", "icon": "paper", "icol": Color("fff2d4"), "irim": StorybookUI.HONEY, "title": "Sobek Kertas Bekas", "desc": "Keluarkan rasa kesal lalu buang ke keranjang daur ulang."},
		{"id": "squishy", "icon": "squishy", "icol": Color("ffd8cc"), "irim": StorybookUI.TERRACOTTA, "title": "Remas Bola Spons", "desc": "Membantu tangan yang tegang jadi lebih rileks."},
		{"id": "lempar", "icon": "broken_toy", "icol": Color("d94848"), "irim": StorybookUI.BERRY_DARK, "title": "Lempar Mainan / Pukul Teman", "desc": "Berbahaya, bisa merusak barang dan melukai teman."},
	]
	options.shuffle()
	for opt: Dictionary in options:
		var card := _make_visual_card(opt)
		_cards[opt["id"]] = card
		_grid.add_child(card)

	# Footer
	var foot := HBoxContainer.new()
	foot.add_theme_constant_override("separation", 12)
	v.add_child(foot)

	_feedback_lbl = _label("Ketuk 3 kartu benda yang aman lalu tekan Periksa!", 14, StorybookUI.INK_SOFT)
	_feedback_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_feedback_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	foot.add_child(_feedback_lbl)

	_confirm_btn = Button.new()
	_confirm_btn.text = "Periksa Pilihan & Buka Gerbang Pos 6"
	_confirm_btn.custom_minimum_size = Vector2(300, 46)
	StorybookUI.style_tactile_button(_confirm_btn, StorybookUI.TERRACOTTA, StorybookUI.TERRACOTTA_DARK, StorybookUI.CREAM, _font_display, 15, 13, 18, 8)
	_confirm_btn.pressed.connect(_on_confirm)
	foot.add_child(_confirm_btn)


func _make_visual_card(opt: Dictionary) -> PanelContainer:
	var card := PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.size_flags_vertical = Control.SIZE_EXPAND_FILL
	card.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	card.set_meta("opt_id", opt["id"])

	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 14)
	hb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(hb)

	# Illustrated icon medallion on the left of each card
	var icon_box := PanelContainer.new()
	icon_box.custom_minimum_size = Vector2(78, 78)
	icon_box.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	icon_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon_box.add_theme_stylebox_override("panel", StorybookUI.make_panel_box(
		StorybookUI.PAPER, opt["irim"], 16, 2, 4, 8, 8, false
	))
	var ic := CenterContainer.new()
	ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ic.add_child(StorybookUI.make_icon(opt["icon"], 54.0, opt["icol"], opt["irim"]))
	icon_box.add_child(ic)
	hb.add_child(icon_box)

	var tv := VBoxContainer.new()
	tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tv.alignment = BoxContainer.ALIGNMENT_CENTER
	tv.add_theme_constant_override("separation", 4)
	tv.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hb.add_child(tv)

	var top_r := HBoxContainer.new()
	top_r.add_theme_constant_override("separation", 6)
	top_r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tv.add_child(top_r)

	var title := _label(opt["title"], 16, StorybookUI.INK, _font_display)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	top_r.add_child(title)

	var stamp := PanelContainer.new()
	stamp.name = "StampBadge"
	stamp.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var slbl := _label("PILIH", 11, StorybookUI.INK_SOFT, _font_display)
	slbl.name = "StampLbl"
	stamp.add_child(slbl)
	top_r.add_child(stamp)

	var desc := _label(opt["desc"], 13, StorybookUI.INK_SOFT)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tv.add_child(desc)

	_style_card(card, false)
	card.gui_input.connect(func(ev: InputEvent) -> void:
		if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
			_toggle_card(card)
	)
	return card


func _toggle_card(card: PanelContainer) -> void:
	if _solved:
		return
	var oid: String = card.get_meta("opt_id")
	if _selected.has(oid):
		_selected.erase(oid)
		_style_card(card, false)
	else:
		_selected[oid] = true
		_style_card(card, true)
	Audio.play_sfx("select")
	_count_lbl.text = "Terpilih: %d / 3" % _selected.size()
	card.pivot_offset = card.size * 0.5
	var tw := create_tween()
	tw.tween_property(card, "scale", Vector2(0.96, 0.96), 0.06)
	tw.tween_property(card, "scale", Vector2.ONE, 0.14).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _style_card(card: PanelContainer, sel: bool) -> void:
	card.add_theme_stylebox_override("panel", StorybookUI.make_panel_box(
		Color("e4f5ea") if sel else StorybookUI.PAPER,
		StorybookUI.EMERALD if sel else StorybookUI.PAPER_DEEP,
		16, 3 if sel else 2, 5 if sel else 4, 12, 10, false
	))
	var stamp := card.find_child("StampBadge", true, false) as PanelContainer
	var slbl := card.find_child("StampLbl", true, false) as Label
	if stamp != null and slbl != null:
		stamp.add_theme_stylebox_override("panel", StorybookUI.make_panel_box(
			StorybookUI.EMERALD if sel else StorybookUI.PAPER_WARM,
			StorybookUI.EMERALD_DARK if sel else StorybookUI.PAPER_DEEP,
			8, 2, 2, 8, 2, false
		))
		slbl.text = "DIPILIH" if sel else "KETUK"
		slbl.add_theme_color_override("font_color", StorybookUI.CREAM if sel else StorybookUI.INK_SOFT)


func _on_confirm() -> void:
	if _solved:
		close_modal()
		return
	var ok := (_selected.size() == 3 and _selected.has("bantal") and _selected.has("kertas") and _selected.has("squishy") and not _selected.has("lempar"))
	if ok:
		_solved = true
		Audio.play_sfx("star")
		Audio.play_voice("pos5_win")
		if _portrait != null:
			_portrait.call("set_expression", "happy")
		_feedback_lbl.text = "Hebat! Semua pilihanmu aman dan tidak menyakiti siapa pun!"
		_feedback_lbl.add_theme_color_override("font_color", StorybookUI.EMERALD_DARK)
		_confirm_btn.text = "Selesai! Lanjut ke Gerbang Pos 6"
		StorybookUI.style_tactile_button(_confirm_btn, StorybookUI.EMERALD, StorybookUI.EMERALD_DARK, StorybookUI.CREAM, _font_display, 15, 13, 18, 8)
		completed.emit()
	else:
		Audio.play_sfx("wrong")
		if _portrait != null:
			_portrait.call("set_expression", "surprised")
		if _selected.has("lempar"):
			_feedback_lbl.text = "Hati-hati! Melempar mainan atau memukul teman itu berbahaya. Pilih 3 benda aman saja!"
		else:
			_feedback_lbl.text = "Pilih tepat 3 benda aman: bantal empuk, kertas bekas, dan bola spons!"
		_feedback_lbl.add_theme_color_override("font_color", StorybookUI.BERRY)


func _label(txt: String, sz: int, col: Color, f: Font = null) -> Label:
	var l := Label.new()
	l.text = txt
	l.add_theme_font_size_override("font_size", sz)
	l.add_theme_color_override("font_color", col)
	l.add_theme_font_override("font", f if f != null else _font_ui)
	return l
