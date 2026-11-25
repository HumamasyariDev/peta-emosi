class_name PosMapModal
extends CanvasLayer

## Illustrated Winding Adventure Map (Pos 1 -> Pos 8).
## Replaces uniform card grids with a tactile stepping-stone trail & per-Pos medallions.

const STATIONS := [
	{"id": 1, "tag": "POS 1", "title": "Gerbang Pengenalan", "desc": "Kenali apa itu emosi bersama Nara", "path": "res://scenes/worlds/Pos1_GerbangPengenalan.tscn", "col": Color("a82438"), "pos": Vector2(0.11, 0.28)},
	{"id": 2, "tag": "POS 2", "title": "Taman 6 Emosi Dasar", "desc": "Kumpulkan 6 stempel emosi manusia", "path": "res://scenes/worlds/Pos2_Taman6Emosi.tscn", "col": Color("237a4b"), "pos": Vector2(0.37, 0.22)},
	{"id": 3, "tag": "POS 3", "title": "Bukit Lonceng Emas", "desc": "Seimbangkan emosi: jangan ditahan atau diledakkan", "path": "res://scenes/worlds/Pos3_AturanEmosi.tscn", "col": Color("c97a08"), "pos": Vector2(0.63, 0.30)},
	{"id": 4, "tag": "POS 4", "title": "6 Langkah Saat Marah", "desc": "Praktik 6 langkah menenangkan suhu hati", "path": "res://scenes/worlds/Pos4_6LangkahTenang.tscn", "col": Color("1e6b87"), "pos": Vector2(0.87, 0.24)},
	{"id": 5, "tag": "POS 5", "title": "Pukul Bantal & Kertas", "desc": "Salurkan rasa kesal lewat cara yang aman", "path": "res://scenes/worlds/Pos5_PukulBantalSobekKertas.tscn", "col": Color("c94d32"), "pos": Vector2(0.84, 0.72)},
	{"id": 6, "tag": "POS 6", "title": "Saat Teman Marah", "desc": "Latih empati dan bantu Bima menjadi tenang", "path": "res://scenes/worlds/Pos6_MelihatTemanMarah.tscn", "col": Color("1f7a6e"), "pos": Vector2(0.59, 0.76)},
	{"id": 7, "tag": "POS 7", "title": "Prinsip Saat Marah", "desc": "Lewati Jembatan 3 Gerbang Prinsip Saat Marah", "path": "res://scenes/worlds/Pos7_PrinsipSaatMarah.tscn", "col": Color("7d3c85"), "pos": Vector2(0.34, 0.70)},
	{"id": 8, "tag": "POS 8", "title": "Finish: Aku Tahu Emosiku!", "desc": "Alun-Alun Perayaan & Piagam Petualang Taman Emosi", "path": "res://scenes/worlds/Pos8_FinishAkuTahuEmosiku.tscn", "col": Color("d49826"), "pos": Vector2(0.11, 0.76)},
]

var _font_ui: Font
var _font_display: Font
var _backdrop: ColorRect
var _sheet: PanelContainer
var _trail_canvas: Control
var _pin_layer: Control
var _selected_id: int = 1
var _detail_tag: Label
var _detail_title: Label
var _detail_desc: Label
var _visit_btn: Button


func _ready() -> void:
	layer = 32
	_font_ui = StorybookUI.font_body(580)
	_font_display = StorybookUI.font_display()
	_build_ui()
	visible = false


func toggle_map() -> void:
	if visible:
		close_map()
	elif not Game.modal_open:
		open_map()


func open_map() -> void:
	Game.modal_open = true
	visible = true
	_selected_id = _current_pos_id()
	_refresh_pins()
	_refresh_detail()
	Audio.play_sfx("select")
	_sheet.scale = Vector2(0.94, 0.94)
	_sheet.modulate.a = 0.0
	var tw := create_tween().set_parallel(true)
	tw.tween_property(_sheet, "modulate:a", 1.0, 0.18)
	tw.tween_property(_sheet, "scale", Vector2.ONE, 0.24).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func close_map() -> void:
	visible = false
	Game.modal_open = false
	Audio.play_sfx("select")


func _unhandled_input(event: InputEvent) -> void:
	if visible and (event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_M)):
		close_map()
		get_viewport().set_input_as_handled()


func _current_pos_id() -> int:
	for s: Dictionary in STATIONS:
		if Game.current_zone.contains("Pos %d" % int(s["id"])):
			return int(s["id"])
	return 1


func _build_ui() -> void:
	_backdrop = ColorRect.new()
	_backdrop.color = Color(0.08, 0.05, 0.03, 0.64)
	_backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_backdrop)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_backdrop.add_child(center)

	_sheet = PanelContainer.new()
	_sheet.custom_minimum_size = Vector2(900, 520)
	_sheet.pivot_offset = Vector2(450, 260)
	_sheet.add_theme_stylebox_override("panel", StorybookUI.make_panel_box(
		StorybookUI.PAPER_WARM, StorybookUI.WALNUT, 24, 4, 10, 22, 18, true
	))
	center.add_child(_sheet)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	_sheet.add_child(v)

	# Header
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 10)
	v.add_child(top)

	top.add_child(StorybookUI.make_icon("compass", 32.0, StorybookUI.HONEY, StorybookUI.WALNUT))

	var title_box := VBoxContainer.new()
	title_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_box.add_theme_constant_override("separation", 1)
	title_box.add_child(_label("Peta Petualangan Taman Emosi", 22, StorybookUI.INK, _font_display))
	title_box.add_child(_label("Pilih titik Pos di peta untuk melihat misi atau langsung berkunjung.", 13, StorybookUI.INK_SOFT))
	top.add_child(title_box)

	var close_btn := Button.new()
	close_btn.text = "Tutup (M)"
	close_btn.custom_minimum_size = Vector2(114, 42)
	StorybookUI.style_tactile_button(close_btn, Color("fce8e8"), StorybookUI.BERRY, StorybookUI.BERRY_DARK, _font_display, 14, 12, 14, 6)
	close_btn.pressed.connect(close_map)
	top.add_child(close_btn)

	# Illustrated Cartographic Map Canvas
	var map_panel := PanelContainer.new()
	map_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	map_panel.custom_minimum_size = Vector2(0, 310)
	map_panel.add_theme_stylebox_override("panel", StorybookUI.make_panel_box(
		Color("efe4c6"), StorybookUI.WALNUT, 18, 3, 4, 0, 0, false
	))
	v.add_child(map_panel)

	var map_root := Control.new()
	map_root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	map_root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	map_panel.add_child(map_root)

	_trail_canvas = MapTrailCanvas.new()
	_trail_canvas.set_anchors_preset(Control.PRESET_FULL_RECT)
	_trail_canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	map_root.add_child(_trail_canvas)

	_pin_layer = Control.new()
	_pin_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	_pin_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	map_root.add_child(_pin_layer)

	# Selected Pos Detail Footer Bar
	var foot_panel := PanelContainer.new()
	foot_panel.add_theme_stylebox_override("panel", StorybookUI.make_panel_box(
		StorybookUI.PAPER, StorybookUI.WALNUT, 16, 2, 5, 16, 10, false
	))
	v.add_child(foot_panel)

	var fhb := HBoxContainer.new()
	fhb.add_theme_constant_override("separation", 14)
	foot_panel.add_child(fhb)

	var info_col := VBoxContainer.new()
	info_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_col.add_theme_constant_override("separation", 2)
	fhb.add_child(info_col)

	var tag_row := HBoxContainer.new()
	tag_row.add_theme_constant_override("separation", 8)
	info_col.add_child(tag_row)

	_detail_tag = _label("POS 1", 13, StorybookUI.BERRY, _font_display)
	tag_row.add_child(_detail_tag)
	_detail_title = _label("Gerbang Pengenalan", 18, StorybookUI.INK, _font_display)
	tag_row.add_child(_detail_title)

	_detail_desc = _label("Kenali apa itu emosi bersama Nara", 14, StorybookUI.INK_SOFT)
	info_col.add_child(_detail_desc)

	_visit_btn = Button.new()
	_visit_btn.text = "Kunjungi Pos Ini"
	_visit_btn.custom_minimum_size = Vector2(180, 46)
	_visit_btn.pressed.connect(_on_visit_selected)
	fhb.add_child(_visit_btn)


func _refresh_pins() -> void:
	for c in _pin_layer.get_children():
		c.queue_free()
	var cur_id := _current_pos_id()

	for s: Dictionary in STATIONS:
		var sid: int = int(s["id"])
		var done: bool = Game.is_station_done(sid)
		var avail: bool = not str(s["path"]).is_empty()
		var is_sel: bool = (sid == _selected_id)
		var is_cur: bool = (sid == cur_id)
		var norm: Vector2 = s["pos"]
		var col: Color = s["col"]

		var holder := Control.new()
		holder.anchor_left = norm.x
		holder.anchor_right = norm.x
		holder.anchor_top = norm.y
		holder.anchor_bottom = norm.y
		holder.offset_left = -74
		holder.offset_right = 74
		holder.offset_top = -44
		holder.offset_bottom = 44
		holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_pin_layer.add_child(holder)

		var vbox := VBoxContainer.new()
		vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
		vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		vbox.add_theme_constant_override("separation", 4)
		vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
		holder.add_child(vbox)

		var pin_btn := Button.new()
		pin_btn.text = str(sid)
		pin_btn.custom_minimum_size = Vector2(54, 54)
		pin_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		var bg := col if avail else Color("b5a896")
		var border := StorybookUI.HONEY_LIGHT if (is_sel or is_cur) else StorybookUI.WALNUT
		StorybookUI.style_tactile_button(pin_btn, bg, border, StorybookUI.CREAM, _font_display, 20, 27, 0, 0)
		if is_sel:
			pin_btn.scale = Vector2(1.10, 1.10)
			pin_btn.pivot_offset = Vector2(27, 27)
		pin_btn.pressed.connect(func() -> void:
			Audio.play_sfx("select")
			_selected_id = sid
			_refresh_pins()
			_refresh_detail()
		)
		vbox.add_child(pin_btn)

		var cap_panel := PanelContainer.new()
		cap_panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		cap_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cap_panel.add_theme_stylebox_override("panel", StorybookUI.make_panel_box(
			Color("e2f5e9") if done else (StorybookUI.PAPER if avail else Color("e5dcc8")),
			StorybookUI.EMERALD if done else StorybookUI.WALNUT,
			8, 2, 2, 7, 2, false
		))
		var cap_hb := HBoxContainer.new()
		cap_hb.add_theme_constant_override("separation", 4)
		cap_hb.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cap_panel.add_child(cap_hb)
		if done:
			cap_hb.add_child(StorybookUI.make_icon("star", 14.0, StorybookUI.HONEY, StorybookUI.WALNUT))
		var cap_txt := str(s["tag"]) + (" (Kamu)" if is_cur else "")
		cap_hb.add_child(_label(cap_txt, 11, StorybookUI.EMERALD_DARK if done else StorybookUI.INK, _font_display))
		vbox.add_child(cap_panel)

	if _trail_canvas != null:
		_trail_canvas.queue_redraw()


func _refresh_detail() -> void:
	for s: Dictionary in STATIONS:
		if int(s["id"]) != _selected_id:
			continue
		var avail: bool = not str(s["path"]).is_empty()
		var done: bool = Game.is_station_done(_selected_id)
		_detail_tag.text = str(s["tag"]) + (" • SELESAI" if done else (" • TERSEDIA" if avail else " • SEGERA HADIR"))
		_detail_tag.add_theme_color_override("font_color", StorybookUI.EMERALD if done else s["col"])
		_detail_title.text = str(s["title"])
		_detail_desc.text = str(s["desc"])
		_visit_btn.disabled = not avail
		if avail:
			_visit_btn.text = "Kunjungi " + str(s["tag"])
			StorybookUI.style_tactile_button(_visit_btn, s["col"], StorybookUI.WALNUT, StorybookUI.CREAM, _font_display, 15, 13, 18, 8)
		else:
			_visit_btn.text = "Segera Hadir"
			StorybookUI.style_tactile_button(_visit_btn, Color("c8bca8"), StorybookUI.INK_SOFT, StorybookUI.INK_SOFT, _font_display, 15, 13, 18, 8)
		break


func _on_visit_selected() -> void:
	for s: Dictionary in STATIONS:
		if int(s["id"]) == _selected_id:
			var path := str(s["path"])
			if not path.is_empty():
				close_map()
				Audio.play_sfx("confirm")
				Router.go_to(path)
			return


func _label(text: String, size: int, col: Color, custom_font: Font = null) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", custom_font if custom_font != null else _font_ui)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	return l


class MapTrailCanvas extends Control:
	func _draw() -> void:
		# Soft illustrated meadow patches & pond accents on the map
		draw_circle(Vector2(size.x * 0.24, size.y * 0.48), 58.0, Color(0.76, 0.85, 0.66, 0.45))
		draw_circle(Vector2(size.x * 0.74, size.y * 0.48), 64.0, Color(0.68, 0.84, 0.86, 0.42))
		draw_circle(Vector2(size.x * 0.48, size.y * 0.52), 42.0, Color(0.84, 0.88, 0.70, 0.45))

		# Winding dotted adventure trail connecting Pos 1 -> Pos 8
		var pts := PackedVector2Array()
		for s: Dictionary in PosMapModal.STATIONS:
			var p: Vector2 = s["pos"]
			pts.append(Vector2(p.x * size.x, p.y * size.y))

		for i in range(pts.size() - 1):
			var a := pts[i]
			var b := pts[i + 1]
			var steps := 14
			var done_seg := Game.is_station_done(i + 1)
			var dot_col := StorybookUI.EMERALD if done_seg else Color(0.48, 0.34, 0.20, 0.65)
			for j in range(1, steps):
				var t := float(j) / float(steps)
				var pt := a.lerp(b, t)
				# Gentle organic curve offset
				pt.y += sin(t * PI) * (-10.0 if i % 2 == 0 else 10.0)
				draw_circle(pt, 4.0 if done_seg else 3.2, dot_col)
