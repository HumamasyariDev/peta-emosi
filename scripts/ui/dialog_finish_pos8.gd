class_name DialogFinishPos8
extends CanvasLayer

## Grand Storybook Explorer Certificate ("Piagam Petualang: Aku Tahu Emosiku!")
## Displays REAL player stats (earned stars & coins), 4 mastered skills with crisp StorybookUI
## vector icons, and real functional actions (Explore More / Return to Title).

signal closed
signal replay_trophy_pressed

const NaraPortraitScript := preload("res://scripts/ui/nara_portrait.gd")

var _font_ui: Font
var _font_display: Font
var _backdrop: ColorRect
var _sheet: PanelContainer
var _stars_lbl: Label
var _coins_lbl: Label


func _ready() -> void:
	layer = 24
	_font_ui = StorybookUI.font_body(580)
	_font_display = StorybookUI.font_display()
	_build_ui()
	visible = false


func open_certificate() -> void:
	Game.modal_open = true
	visible = true
	if _stars_lbl != null:
		_stars_lbl.text = "%d / 8 Bintang" % Game.get_completed_count()
	if _coins_lbl != null:
		_coins_lbl.text = "%d Koin Emas" % Game.coins
	_sheet.scale = Vector2(0.92, 0.92)
	_sheet.modulate.a = 0.0
	var tw := create_tween().set_parallel(true)
	tw.tween_property(_sheet, "modulate:a", 1.0, 0.22)
	tw.tween_property(_sheet, "scale", Vector2.ONE, 0.30).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func close_certificate() -> void:
	visible = false
	Game.modal_open = false
	Audio.play_sfx("select")
	closed.emit()


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		close_certificate()
		get_viewport().set_input_as_handled()


func _build_ui() -> void:
	_backdrop = ColorRect.new()
	_backdrop.color = Color(0.08, 0.05, 0.02, 0.68)
	_backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_backdrop)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_backdrop.add_child(center)

	# Warm Honey-Gold & Ivory Storybook Certificate Frame
	_sheet = PanelContainer.new()
	_sheet.custom_minimum_size = Vector2(860, 510)
	_sheet.pivot_offset = Vector2(430, 255)
	_sheet.add_theme_stylebox_override("panel", StorybookUI.make_panel_box(
		StorybookUI.PAPER, StorybookUI.HONEY, 26, 5, 11, 28, 22, true
	))
	center.add_child(_sheet)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 14)
	_sheet.add_child(v)

	# Top Crest Header (Portrait + Grand Title + Real Stats)
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 18)
	v.add_child(top)

	var crest := PanelContainer.new()
	crest.add_theme_stylebox_override("panel", StorybookUI.make_panel_box(
		StorybookUI.PAPER_WARM, StorybookUI.HONEY, 52, 3, 5, 6, 6, false
	))
	var portrait := NaraPortraitScript.new()
	portrait.custom_minimum_size = Vector2(90, 90)
	portrait.call("set_expression", "excited")
	crest.add_child(portrait)
	top.add_child(crest)

	var title_col := VBoxContainer.new()
	title_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_col.alignment = BoxContainer.ALIGNMENT_CENTER
	title_col.add_theme_constant_override("separation", 4)
	top.add_child(title_col)

	var rib := PanelContainer.new()
	rib.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	rib.add_theme_stylebox_override("panel", StorybookUI.make_panel_box(
		StorybookUI.BERRY, StorybookUI.BERRY_DARK, 9, 2, 3, 12, 3, false
	))
	var rhb := HBoxContainer.new()
	rhb.add_theme_constant_override("separation", 6)
	rhb.add_child(StorybookUI.make_icon("star", 16.0, StorybookUI.HONEY_LIGHT, StorybookUI.WALNUT_DARK))
	rhb.add_child(_label("PIAGAM PENJELAJAH TAMAN EMOSI", 13, StorybookUI.CREAM, _font_display))
	rib.add_child(rhb)
	title_col.add_child(rib)

	title_col.add_child(_label("Selamat! Aku Tahu Emosiku!", 30, StorybookUI.INK, _font_display))
	title_col.add_child(_label("Kamu telah menyelesaikan perjalanan dari Pos 1 hingga Garis Finish Pos 8 bersama Nara.", 14, StorybookUI.INK_SOFT))

	# Real Earned Progress Pills (Bintang & Koin from GameState)
	var stat_row := HBoxContainer.new()
	stat_row.add_theme_constant_override("separation", 12)
	v.add_child(stat_row)

	var star_box := PanelContainer.new()
	star_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	star_box.add_theme_stylebox_override("panel", StorybookUI.make_panel_box(
		Color("fff4d4"), StorybookUI.HONEY, 14, 2, 4, 14, 8, false
	))
	var shb := HBoxContainer.new()
	shb.alignment = BoxContainer.ALIGNMENT_CENTER
	shb.add_theme_constant_override("separation", 8)
	shb.add_child(StorybookUI.make_icon("star", 24.0, StorybookUI.HONEY, StorybookUI.WALNUT))
	_stars_lbl = _label("8 / 8 Bintang", 18, StorybookUI.INK, _font_display)
	shb.add_child(_stars_lbl)
	star_box.add_child(shb)
	stat_row.add_child(star_box)

	var coin_box := PanelContainer.new()
	coin_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	coin_box.add_theme_stylebox_override("panel", StorybookUI.make_panel_box(
		Color("e6f6ee"), StorybookUI.EMERALD, 14, 2, 4, 14, 8, false
	))
	var chb := HBoxContainer.new()
	chb.alignment = BoxContainer.ALIGNMENT_CENTER
	chb.add_theme_constant_override("separation", 8)
	chb.add_child(StorybookUI.make_icon("coin", 24.0, StorybookUI.HONEY, StorybookUI.WALNUT))
	_coins_lbl = _label("0 Koin Emas", 18, StorybookUI.EMERALD_DARK, _font_display)
	chb.add_child(_coins_lbl)
	coin_box.add_child(chb)
	stat_row.add_child(coin_box)

	# 2x2 Mastered Life-Skills Grid
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 10)
	grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(grid)

	var skills := [
		["Kenali 6 Emosi Dasar", "Sedih, marah, takut, bahagia, jijik, dan terkejut semua wajar dirasakan."],
		["6 Langkah & Penyaluran Aman", "Tarik napas, hitung 1-10, pukul bantal empuk, atau sobek kertas bekas."],
		["Empati Saat Teman Marah", "Hargai apakah teman mau ditemani main bareng atau butuh waktu sendiri."],
		["3 Prinsip Saat Marah", "Jangan menyakiti diri sendiri, jangan menyakiti orang lain, jangan merusak barang."],
	]
	for item in skills:
		var card := PanelContainer.new()
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card.add_theme_stylebox_override("panel", StorybookUI.make_panel_box(
			StorybookUI.PAPER_WARM, StorybookUI.PAPER_DEEP, 14, 2, 4, 12, 9, false
		))
		var hb := HBoxContainer.new()
		hb.add_theme_constant_override("separation", 10)
		card.add_child(hb)
		var ck := PanelContainer.new()
		ck.custom_minimum_size = Vector2(28, 28)
		ck.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		ck.add_theme_stylebox_override("panel", StorybookUI.make_panel_box(
			StorybookUI.EMERALD, StorybookUI.EMERALD_DARK, 14, 2, 2, 0, 0, false
		))
		var ckc := CenterContainer.new()
		ckc.add_child(StorybookUI.make_icon("check", 16.0, StorybookUI.CREAM, StorybookUI.CREAM))
		ck.add_child(ckc)
		hb.add_child(ck)

		var tv := VBoxContainer.new()
		tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tv.add_theme_constant_override("separation", 2)
		tv.add_child(_label(item[0], 15, StorybookUI.INK, _font_display))
		var dl := _label(item[1], 13, StorybookUI.INK_SOFT)
		dl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		tv.add_child(dl)
		hb.add_child(tv)
		grid.add_child(card)

	# Bottom Functional Actions
	var foot := HBoxContainer.new()
	foot.add_theme_constant_override("separation", 12)
	v.add_child(foot)

	var lift_btn := Button.new()
	lift_btn.text = "Angkat Piala Lagi!"
	lift_btn.custom_minimum_size = Vector2(210, 48)
	StorybookUI.style_tactile_button(lift_btn, StorybookUI.HONEY, StorybookUI.WALNUT, StorybookUI.INK, _font_display, 15, 14, 14, 8)
	lift_btn.pressed.connect(func() -> void:
		close_certificate()
		replay_trophy_pressed.emit()
	)
	foot.add_child(lift_btn)

	var explore_btn := Button.new()
	explore_btn.text = "Jelajahi Alun-Alun"
	explore_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	explore_btn.custom_minimum_size = Vector2(0, 48)
	StorybookUI.style_tactile_button(explore_btn, StorybookUI.EMERALD, StorybookUI.EMERALD_DARK, StorybookUI.CREAM, _font_display, 15, 14, 14, 8)
	explore_btn.pressed.connect(close_certificate)
	foot.add_child(explore_btn)

	var home_btn := Button.new()
	home_btn.text = "Layar Awal"
	home_btn.custom_minimum_size = Vector2(165, 48)
	StorybookUI.style_tactile_button(home_btn, StorybookUI.BERRY, StorybookUI.BERRY_DARK, StorybookUI.CREAM, _font_display, 15, 14, 14, 8)
	home_btn.pressed.connect(func() -> void:
		close_certificate()
		Audio.play_sfx("confirm")
		Router.go_to("res://scenes/ui/TitleScreen.tscn")
	)
	foot.add_child(home_btn)


func _label(txt: String, sz: int, col: Color, f: Font = null) -> Label:
	var l := Label.new()
	l.text = txt
	l.add_theme_font_size_override("font_size", sz)
	l.add_theme_color_override("font_color", col)
	l.add_theme_font_override("font", f if f != null else _font_ui)
	return l

