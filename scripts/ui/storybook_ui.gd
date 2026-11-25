class_name StorybookUI
extends RefCounted

## Shared Tactile Storybook UI Kit for Peta Emosi.
## Provides cohesive typography, tactile beveled StyleBox builders, per-Pos accent
## palettes, and crisp procedural vector icons (zero broken Unicode tofu boxes).

const INK := Color("2a1a12")
const INK_SOFT := Color("5c4030")
const PAPER := Color("fff8ea")
const PAPER_WARM := Color("f6ead2")
const PAPER_DEEP := Color("ead7b7")
const WALNUT := Color("5c341a")
const WALNUT_DARK := Color("3b1f0e")
const HONEY := Color("e59a16")
const HONEY_LIGHT := Color("ffd666")
const BERRY := Color("a82438")
const BERRY_DARK := Color("6e1322")
const EMERALD := Color("237a4b")
const EMERALD_DARK := Color("165232")
const LAGOON := Color("1e6b87")
const LAGOON_DARK := Color("124659")
const TERRACOTTA := Color("c94d32")
const TERRACOTTA_DARK := Color("8c2f1b")
const SAGE := Color("1f7a6e")
const SAGE_DARK := Color("134f47")
const CREAM := Color("fffaf0")

static var _font_cache: Dictionary = {}


static func font_body(weight: int = 550) -> Font:
	var key := "fredoka_%d" % weight
	if _font_cache.has(key):
		return _font_cache[key] as Font
	var base := load("res://assets/fonts/fredoka/Fredoka-Variable.ttf") as FontFile
	if base == null:
		return ThemeDB.fallback_font
	var fv := FontVariation.new()
	fv.base_font = base
	var ts := TextServerManager.get_primary_interface()
	var wght_tag: int = ts.name_to_tag("wght") if ts != null else 2003265652
	fv.variation_opentype = {wght_tag: weight}
	_font_cache[key] = fv
	return fv


static func font_display() -> Font:
	if _font_cache.has("display"):
		return _font_cache["display"] as Font
	var f: Font = load("res://assets/fonts/lilita/LilitaOne-Regular.ttf") if ResourceLoader.exists("res://assets/fonts/lilita/LilitaOne-Regular.ttf") else font_body(700)
	_font_cache["display"] = f
	return f


static func font_serif() -> Font:
	if _font_cache.has("serif"):
		return _font_cache["serif"] as Font
	var f: Font = load("res://assets/fonts/cherryswash/CherrySwash-Bold.ttf") if ResourceLoader.exists("res://assets/fonts/cherryswash/CherrySwash-Bold.ttf") else font_display()
	_font_cache["serif"] = f
	return f


static func pos_accent(zone_name: String) -> Dictionary:
	if zone_name.contains("Pos 2"):
		return {"bg": EMERALD, "dark": EMERALD_DARK, "soft": Color("e6f5ec"), "tag": "POS 2"}
	if zone_name.contains("Pos 3"):
		return {"bg": Color("c97a08"), "dark": Color("824d02"), "soft": Color("fff4dc"), "tag": "POS 3"}
	if zone_name.contains("Pos 4"):
		return {"bg": LAGOON, "dark": LAGOON_DARK, "soft": Color("e5f4fa"), "tag": "POS 4"}
	if zone_name.contains("Pos 5"):
		return {"bg": TERRACOTTA, "dark": TERRACOTTA_DARK, "soft": Color("fdece7"), "tag": "POS 5"}
	if zone_name.contains("Pos 6"):
		return {"bg": SAGE, "dark": SAGE_DARK, "soft": Color("e4f5f2"), "tag": "POS 6"}
	if zone_name.contains("Pos 7"):
		return {"bg": Color("7d3c85"), "dark": Color("4f2254"), "soft": Color("f4eaf7"), "tag": "POS 7"}
	if zone_name.contains("Pos 8"):
		return {"bg": HONEY, "dark": WALNUT, "soft": Color("fff6db"), "tag": "POS 8"}
	return {"bg": BERRY, "dark": BERRY_DARK, "soft": Color("fcecef"), "tag": "POS 1"}


static func make_panel_box(
	bg: Color,
	border: Color,
	radius: int = 16,
	border_w: int = 2,
	bottom_lip: int = 4,
	pad_x: int = 14,
	pad_y: int = 8,
	with_shadow: bool = false
) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(border_w)
	s.border_width_bottom = bottom_lip
	s.set_corner_radius_all(radius)
	s.content_margin_left = pad_x
	s.content_margin_right = pad_x
	s.content_margin_top = pad_y
	s.content_margin_bottom = pad_y
	if with_shadow:
		s.shadow_color = Color(0.14, 0.08, 0.04, 0.24)
		s.shadow_size = 10
		s.shadow_offset = Vector2(0, 4)
	return s


static func style_tactile_button(
	btn: Button,
	bg: Color,
	border: Color,
	fg: Color,
	font: Font,
	font_size: int = 15,
	radius: int = 14,
	pad_x: int = 14,
	pad_y: int = 7
) -> void:
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	if font != null:
		btn.add_theme_font_override("font", font)
	btn.add_theme_font_size_override("font_size", font_size)
	btn.add_theme_color_override("font_color", fg)
	btn.add_theme_color_override("font_hover_color", fg)
	btn.add_theme_color_override("font_pressed_color", fg)
	btn.add_theme_color_override("font_focus_color", fg)

	var normal := make_panel_box(bg, border, radius, 2, 5, pad_x, pad_y, true)
	var hover := make_panel_box(bg.lightened(0.08), border, radius, 2, 5, pad_x, pad_y, true)
	var pressed := make_panel_box(bg.darkened(0.10), border, radius, 2, 2, pad_x, pad_y + 2, false)
	var focus := make_panel_box(bg.lightened(0.05), HONEY_LIGHT, radius, 3, 5, pad_x, pad_y, true)

	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", pressed)
	btn.add_theme_stylebox_override("focus", focus)


static func make_icon(kind: String, sz: float = 24.0, primary: Color = HONEY, secondary: Color = WALNUT) -> Control:
	var icon := VectorIcon.new()
	icon.kind = kind
	icon.primary_color = primary
	icon.secondary_color = secondary
	icon.custom_minimum_size = Vector2(sz, sz)
	icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return icon


static func make_bima_portrait(sz: float = 110.0) -> Control:
	var p := BimaPortrait.new()
	p.custom_minimum_size = Vector2(sz, sz)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return p


class VectorIcon extends Control:
	var kind: String = "star"
	var primary_color: Color = Color("e59a16")
	var secondary_color: Color = Color("5c341a")

	func _draw() -> void:
		var s := minf(size.x, size.y)
		var c := size * 0.5
		var r := s * 0.44
		match kind:
			"star":
				_draw_star(c, r, primary_color, secondary_color)
			"coin":
				draw_circle(c + Vector2(0, 1.5), r, Color(0, 0, 0, 0.20))
				draw_circle(c, r, secondary_color)
				draw_circle(c, r * 0.84, primary_color)
				draw_circle(c, r * 0.62, primary_color.lightened(0.22))
				draw_arc(c, r * 0.62, 0.0, TAU, 20, secondary_color, 1.4, true)
				draw_circle(c + Vector2(-r * 0.22, -r * 0.22), r * 0.16, Color(1, 1, 1, 0.72))
			"compass":
				draw_circle(c, r, secondary_color)
				draw_circle(c, r * 0.84, Color("fff8ea"))
				draw_arc(c, r * 0.72, 0.0, TAU, 24, primary_color, 1.4, true)
				var n_pts := PackedVector2Array([
					c + Vector2(0, -r * 0.62),
					c + Vector2(r * 0.22, 0),
					c + Vector2(-r * 0.22, 0)
				])
				var s_pts := PackedVector2Array([
					c + Vector2(0, r * 0.62),
					c + Vector2(r * 0.22, 0),
					c + Vector2(-r * 0.22, 0)
				])
				draw_colored_polygon(n_pts, Color("c94d32"))
				draw_colored_polygon(s_pts, Color("1e6b87"))
				draw_circle(c, r * 0.14, secondary_color)
			"book":
				var w := r * 1.7
				var h := r * 1.25
				var tl := c - Vector2(w * 0.5, h * 0.5)
				draw_rect(Rect2(tl, Vector2(w, h)), secondary_color, true)
				draw_rect(Rect2(tl + Vector2(2, 2), Vector2(w * 0.5 - 3, h - 4)), Color("fff8ea"), true)
				draw_rect(Rect2(tl + Vector2(w * 0.5 + 1, 2), Vector2(w * 0.5 - 3, h - 4)), Color("f6ead2"), true)
				draw_line(Vector2(c.x, tl.y + 1), Vector2(c.x, tl.y + h - 1), secondary_color, 2.0)
				draw_line(tl + Vector2(5, h * 0.38), tl + Vector2(w * 0.42, h * 0.38), primary_color, 1.8)
				draw_line(tl + Vector2(5, h * 0.62), tl + Vector2(w * 0.38, h * 0.62), primary_color, 1.8)
			"sound_on":
				var body := PackedVector2Array([
					c + Vector2(-r * 0.72, -r * 0.26),
					c + Vector2(-r * 0.28, -r * 0.26),
					c + Vector2(r * 0.16, -r * 0.65),
					c + Vector2(r * 0.16, r * 0.65),
					c + Vector2(-r * 0.28, r * 0.26),
					c + Vector2(-r * 0.72, r * 0.26)
				])
				draw_colored_polygon(body, primary_color)
				draw_arc(c + Vector2(r * 0.18, 0), r * 0.36, -0.75, 0.75, 10, secondary_color, 2.2, true)
				draw_arc(c + Vector2(r * 0.18, 0), r * 0.62, -0.82, 0.82, 12, secondary_color, 2.2, true)
			"sound_off":
				var body := PackedVector2Array([
					c + Vector2(-r * 0.72, -r * 0.26),
					c + Vector2(-r * 0.28, -r * 0.26),
					c + Vector2(r * 0.16, -r * 0.65),
					c + Vector2(r * 0.16, r * 0.65),
					c + Vector2(-r * 0.28, r * 0.26),
					c + Vector2(-r * 0.72, r * 0.26)
				])
				draw_colored_polygon(body, primary_color)
				draw_line(c + Vector2(r * 0.25, -r * 0.35), c + Vector2(r * 0.78, r * 0.35), secondary_color, 2.4, true)
				draw_line(c + Vector2(r * 0.78, -r * 0.35), c + Vector2(r * 0.25, r * 0.35), secondary_color, 2.4, true)
			"gamepad":
				draw_circle(c, r * 0.90, secondary_color)
				draw_circle(c, r * 0.72, Color("fff8ea"))
				draw_circle(c, r * 0.38, primary_color)
				draw_circle(c + Vector2(-r * 0.10, -r * 0.10), r * 0.12, Color(1, 1, 1, 0.75))
			"pillow":
				# Fluffy cloud pillow illustration for Pos 5
				var col := primary_color
				var rim := secondary_color
				draw_circle(c + Vector2(-r * 0.42, -r * 0.22), r * 0.46, rim)
				draw_circle(c + Vector2(r * 0.42, -r * 0.22), r * 0.46, rim)
				draw_circle(c + Vector2(-r * 0.42, r * 0.22), r * 0.46, rim)
				draw_circle(c + Vector2(r * 0.42, r * 0.22), r * 0.46, rim)
				draw_rect(Rect2(c - Vector2(r * 0.50, r * 0.45), Vector2(r * 1.0, r * 0.90)), rim, true)
				draw_circle(c + Vector2(-r * 0.40, -r * 0.20), r * 0.38, col)
				draw_circle(c + Vector2(r * 0.40, -r * 0.20), r * 0.38, col)
				draw_circle(c + Vector2(-r * 0.40, r * 0.20), r * 0.38, col)
				draw_circle(c + Vector2(r * 0.40, r * 0.20), r * 0.38, col)
				draw_rect(Rect2(c - Vector2(r * 0.46, r * 0.38), Vector2(r * 0.92, r * 0.76)), col, true)
				draw_arc(c + Vector2(0, r * 0.04), r * 0.24, 0.2, PI - 0.2, 10, rim, 2.0, true)
				draw_circle(c + Vector2(-r * 0.20, -r * 0.12), r * 0.07, rim)
				draw_circle(c + Vector2(r * 0.20, -r * 0.12), r * 0.07, rim)
			"paper":
				# Craft paper sheet with torn zig-zag corner for Pos 5
				var pts := PackedVector2Array([
					c + Vector2(-r * 0.62, -r * 0.76),
					c + Vector2(r * 0.35, -r * 0.76),
					c + Vector2(r * 0.66, -r * 0.42),
					c + Vector2(r * 0.66, r * 0.74),
					c + Vector2(r * 0.28, r * 0.56),
					c + Vector2(0.0, r * 0.78),
					c + Vector2(-r * 0.32, r * 0.58),
					c + Vector2(-r * 0.62, r * 0.76)
				])
				draw_colored_polygon(pts, primary_color)
				draw_polyline(pts + PackedVector2Array([pts[0]]), secondary_color, 2.4, true)
				draw_line(c + Vector2(-r * 0.38, -r * 0.25), c + Vector2(r * 0.38, -r * 0.25), secondary_color, 2.0)
				draw_line(c + Vector2(-r * 0.38, r * 0.08), c + Vector2(r * 0.26, r * 0.08), secondary_color, 2.0)
			"squishy":
				# Bouncy stress ball illustration for Pos 5
				draw_circle(c, r * 0.86, secondary_color)
				draw_circle(c, r * 0.74, primary_color)
				draw_circle(c + Vector2(-r * 0.24, -r * 0.26), r * 0.18, Color(1, 1, 1, 0.55))
				draw_circle(c + Vector2(-r * 0.22, -r * 0.04), r * 0.08, secondary_color)
				draw_circle(c + Vector2(r * 0.22, -r * 0.04), r * 0.08, secondary_color)
				draw_arc(c + Vector2(0, r * 0.10), r * 0.24, 0.15, PI - 0.15, 10, secondary_color, 2.2, true)
			"broken_toy":
				# Warning block / unsafe toy throw icon for Pos 5
				var box := Rect2(c - Vector2(r * 0.68, r * 0.68), Vector2(r * 1.36, r * 1.36))
				draw_rect(box, secondary_color, true)
				draw_rect(box.grow(-3.0), primary_color, true)
				draw_line(c + Vector2(-r * 0.36, -r * 0.36), c + Vector2(r * 0.36, r * 0.36), Color("fffaf0"), 3.4, true)
				draw_line(c + Vector2(r * 0.36, -r * 0.36), c + Vector2(-r * 0.36, r * 0.36), Color("fffaf0"), 3.4, true)
			"check":
				draw_polyline(PackedVector2Array([
					c + Vector2(-r * 0.58, r * 0.02),
					c + Vector2(-r * 0.14, r * 0.46),
					c + Vector2(r * 0.62, -r * 0.46)
				]), primary_color, 3.0, true)
			"play_right":
				var pts := PackedVector2Array([
					c + Vector2(-r * 0.45, -r * 0.62),
					c + Vector2(r * 0.62, 0.0),
					c + Vector2(-r * 0.45, r * 0.62)
				])
				draw_colored_polygon(pts, primary_color)
				draw_polyline(pts + PackedVector2Array([pts[0]]), secondary_color, 1.6, true)
			"play_left":
				var pts := PackedVector2Array([
					c + Vector2(r * 0.45, -r * 0.62),
					c + Vector2(-r * 0.62, 0.0),
					c + Vector2(r * 0.45, r * 0.62)
				])
				draw_colored_polygon(pts, primary_color)
				draw_polyline(pts + PackedVector2Array([pts[0]]), secondary_color, 1.6, true)
			"close_x":
				draw_line(c + Vector2(-r * 0.48, -r * 0.48), c + Vector2(r * 0.48, r * 0.48), primary_color, 2.8, true)
				draw_line(c + Vector2(r * 0.48, -r * 0.48), c + Vector2(-r * 0.48, r * 0.48), primary_color, 2.8, true)

	func _draw_star(center: Vector2, rad: float, fill: Color, rim: Color) -> void:
		var pts := PackedVector2Array()
		for i in range(10):
			var ang := -PI * 0.5 + float(i) * (PI / 5.0)
			var rr := rad if (i % 2 == 0) else rad * 0.46
			pts.append(center + Vector2(cos(ang), sin(ang)) * rr)
		draw_colored_polygon(pts, fill)
		draw_polyline(pts + PackedVector2Array([pts[0]]), rim, 2.0, true)


class BimaPortrait extends Control:
	## Expressive 2D storybook portrait of Bima for Pos 6 empathy interaction.
	## mood: "angry", "cooling", "calm", "hurt"
	var mood: String = "angry"
	var _t: float = 0.0

	func set_mood(next_mood: String) -> void:
		mood = next_mood
		queue_redraw()

	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()

	func _draw() -> void:
		var s := minf(size.x, size.y)
		var c := size * 0.5
		var r := s * 0.44
		var bob := sin(_t * 3.2) * 2.0

		# Outer medallion ring colored by mood
		var ring_bg := Color("fde4df")
		var ring_border := Color("c94d32")
		if mood == "cooling":
			ring_bg = Color("fff2d6")
			ring_border = Color("e59a16")
		elif mood == "calm":
			ring_bg = Color("e2f5ee")
			ring_border = Color("1f7a6e")
		elif mood == "hurt":
			ring_bg = Color("f9d8dc")
			ring_border = Color("a82438")

		draw_circle(c + Vector2(0, 3), r + 3.0, Color(0.14, 0.08, 0.04, 0.22))
		draw_circle(c, r + 2.0, ring_border)
		draw_circle(c, r - 3.0, ring_bg)

		var head_c := c + Vector2(0, 3.0 + bob)
		# Spiky hair back
		draw_circle(head_c + Vector2(0, -r * 0.14), r * 0.56, Color("38261a"))
		# Ears
		draw_circle(head_c + Vector2(-r * 0.48, r * 0.04), r * 0.12, Color("f2c29b"))
		draw_circle(head_c + Vector2(r * 0.48, r * 0.04), r * 0.12, Color("f2c29b"))
		# Face
		draw_circle(head_c + Vector2(0, r * 0.04), r * 0.48, Color("f7cca8"))
		# Hair bangs
		var bangs := PackedVector2Array([
			head_c + Vector2(-r * 0.50, -r * 0.12),
			head_c + Vector2(-r * 0.28, -r * 0.50),
			head_c + Vector2(0.0, -r * 0.34),
			head_c + Vector2(r * 0.24, -r * 0.52),
			head_c + Vector2(r * 0.50, -r * 0.12),
			head_c + Vector2(r * 0.22, -r * 0.20),
			head_c + Vector2(0.0, -r * 0.10),
			head_c + Vector2(-r * 0.24, -r * 0.22)
		])
		draw_colored_polygon(bangs, Color("38261a"))

		# Cheeks
		var cheek_col := Color(0.95, 0.38, 0.32, 0.45) if (mood == "angry" or mood == "hurt") else Color(0.96, 0.62, 0.56, 0.38)
		draw_circle(head_c + Vector2(-r * 0.28, r * 0.16), r * 0.10, cheek_col)
		draw_circle(head_c + Vector2(r * 0.28, r * 0.16), r * 0.10, cheek_col)

		# Eyes
		draw_circle(head_c + Vector2(-r * 0.18, r * 0.02), r * 0.075, Color("2a1a12"))
		draw_circle(head_c + Vector2(r * 0.18, r * 0.02), r * 0.075, Color("2a1a12"))
		draw_circle(head_c + Vector2(-r * 0.20, -r * 0.01), r * 0.025, Color.WHITE)
		draw_circle(head_c + Vector2(r * 0.16, -r * 0.01), r * 0.025, Color.WHITE)

		# Eyebrows & mouth based on mood
		if mood == "angry":
			draw_line(head_c + Vector2(-r * 0.30, -r * 0.14), head_c + Vector2(-r * 0.08, -r * 0.06), Color("2a1a12"), 2.8, true)
			draw_line(head_c + Vector2(r * 0.30, -r * 0.14), head_c + Vector2(r * 0.08, -r * 0.06), Color("2a1a12"), 2.8, true)
			draw_arc(head_c + Vector2(0, r * 0.32), r * 0.16, PI + 0.35, TAU - 0.35, 10, Color("2a1a12"), 2.6, true)
			# Little steam puff
			var puff_y := -r * 0.66 + sin(_t * 6.0) * 3.0
			draw_circle(head_c + Vector2(r * 0.46, puff_y), r * 0.12, Color("d9534f"))
		elif mood == "hurt":
			draw_line(head_c + Vector2(-r * 0.30, -r * 0.06), head_c + Vector2(-r * 0.08, -r * 0.14), Color("2a1a12"), 2.4, true)
			draw_line(head_c + Vector2(r * 0.30, -r * 0.06), head_c + Vector2(r * 0.08, -r * 0.14), Color("2a1a12"), 2.4, true)
			draw_arc(head_c + Vector2(0, r * 0.34), r * 0.17, PI + 0.25, TAU - 0.25, 10, Color("2a1a12"), 2.4, true)
		elif mood == "cooling":
			draw_line(head_c + Vector2(-r * 0.26, -r * 0.11), head_c + Vector2(-r * 0.09, -r * 0.11), Color("2a1a12"), 2.2, true)
			draw_line(head_c + Vector2(r * 0.26, -r * 0.11), head_c + Vector2(r * 0.09, -r * 0.11), Color("2a1a12"), 2.2, true)
			draw_line(head_c + Vector2(-r * 0.13, r * 0.24), head_c + Vector2(r * 0.13, r * 0.24), Color("2a1a12"), 2.4, true)
		else:
			# Calm & happy smile
			draw_arc(head_c + Vector2(0, r * 0.16), r * 0.18, 0.22, PI - 0.22, 12, Color("2a1a12"), 2.6, true)
			# Little green/teal sparkle dot
			draw_circle(head_c + Vector2(r * 0.48, -r * 0.56), r * 0.09, Color("1f7a6e"))

