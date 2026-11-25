class_name NaraPortrait
extends Control

var expression: String = "happy" : set = set_expression
var shirt_color: Color = Color(1.0, 0.49, 0.71)
var hair_color: Color = Color(0.15, 0.12, 0.18)
var show_hairclips: bool = true
var _anim_t: float = 0.0
var _redraw_accum: float = 0.0


func _ready() -> void:
	if custom_minimum_size == Vector2.ZERO:
		custom_minimum_size = Vector2(116, 116)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = true


func set_expression(expr: String) -> void:
	expression = expr
	queue_redraw()


func set_character_style(p_shirt: Color, p_hair: Color, p_clips: bool = false) -> void:
	shirt_color = p_shirt
	hair_color = p_hair
	show_hairclips = p_clips
	queue_redraw()


func _process(delta: float) -> void:
	if not is_visible_in_tree():
		return
	_anim_t += delta
	_redraw_accum += delta
	if _redraw_accum >= 0.05:
		_redraw_accum = 0.0
		queue_redraw()


func _draw() -> void:
	var c := size * 0.5
	var r := minf(size.x, size.y) * 0.44
	var bob := sin(_anim_t * 3.0) * (r * 0.03)

	# Medallion background color shifts softly by expression
	var bg_col := Color(1.0, 0.94, 0.78)
	var rim_col := Color(0.92, 0.58, 0.08)
	match expression:
		"excited", "celebrate":
			bg_col = Color(0.90, 0.98, 0.90)
			rim_col = Color(0.14, 0.66, 0.32)
		"surprised":
			bg_col = Color(0.90, 0.95, 1.0)
			rim_col = Color(0.20, 0.52, 0.88)
		"upset":
			bg_col = Color(1.0, 0.91, 0.90)
			rim_col = Color(0.84, 0.28, 0.24)
		"curious", "thinking":
			bg_col = Color(0.97, 0.92, 1.0)
			rim_col = Color(0.56, 0.34, 0.78)

	# Outer rim & warm inner circle
	draw_circle(c, r + 3.0, rim_col)
	draw_circle(c, r, bg_col)

	var hc := c + Vector2(0.0, -r * 0.04 + bob)

	# Shirt shoulders tucked neatly INSIDE the medallion rim (zero overflow!)
	draw_circle(hc + Vector2(0.0, r * 0.62), r * 0.34, shirt_color)

	# Back bob hair
	draw_circle(hc + Vector2(0.0, -r * 0.04), r * 0.62, hair_color)

	# Face
	var skin_col := Color(1.0, 0.87, 0.77)
	draw_circle(hc + Vector2(0.0, r * 0.06), r * 0.48, skin_col)

	# Bangs (top hair arc)
	var bangs_pts := PackedVector2Array([
		hc + Vector2(-r * 0.50, -r * 0.05),
		hc + Vector2(-r * 0.38, -r * 0.45),
		hc + Vector2(0.0, -r * 0.54),
		hc + Vector2(r * 0.38, -r * 0.45),
		hc + Vector2(r * 0.50, -r * 0.05),
		hc + Vector2(r * 0.22, -r * 0.18),
		hc + Vector2(0.0, -r * 0.10),
		hc + Vector2(-r * 0.22, -r * 0.18)
	])
	draw_colored_polygon(bangs_pts, hair_color)

	# Yellow and pink hairclips matching 3D Nara
	if show_hairclips:
		draw_rect(Rect2(hc + Vector2(-r * 0.34, -r * 0.30), Vector2(r * 0.22, r * 0.10)), Color(0.98, 0.80, 0.08))
		draw_rect(Rect2(hc + Vector2(r * 0.14, -r * 0.30), Vector2(r * 0.22, r * 0.10)), Color(0.95, 0.25, 0.37))

	# Rosy cheeks
	var cheek_col := Color(0.98, 0.55, 0.62, 0.55)
	draw_circle(hc + Vector2(-r * 0.26, r * 0.18), r * 0.10, cheek_col)
	draw_circle(hc + Vector2(r * 0.26, r * 0.18), r * 0.10, cheek_col)

	# Eyes & mouth by expression
	var ink := Color(0.14, 0.10, 0.14)
	var le := hc + Vector2(-r * 0.18, r * 0.04)
	var re := hc + Vector2(r * 0.18, r * 0.04)
	var mouth_c := hc + Vector2(0.0, r * 0.24)

	match expression:
		"excited", "celebrate":
			# Happy curved eyes (^ ^)
			draw_arc(le + Vector2(0.0, 3.0), r * 0.09, PI * 1.15, PI * 1.85, 10, ink, 3.0)
			draw_arc(re + Vector2(0.0, 3.0), r * 0.09, PI * 1.15, PI * 1.85, 10, ink, 3.0)
			# Big joyful smile
			draw_arc(mouth_c - Vector2(0.0, 2.0), r * 0.15, 0.15, PI - 0.15, 12, ink, 3.0)
		"surprised":
			# Wide eyes with sparkle
			draw_circle(le, r * 0.095, ink)
			draw_circle(re, r * 0.095, ink)
			draw_circle(le + Vector2(-2.0, -2.0), r * 0.032, Color.WHITE)
			draw_circle(re + Vector2(-2.0, -2.0), r * 0.032, Color.WHITE)
			# Small O mouth
			draw_arc(mouth_c + Vector2(0.0, 2.0), r * 0.08, 0.0, TAU, 14, ink, 2.8)
		"upset":
			# Angled eyebrows + eyes
			draw_circle(le, r * 0.07, ink)
			draw_circle(re, r * 0.07, ink)
			draw_line(le + Vector2(-7.0, -10.0), le + Vector2(6.0, -5.0), ink, 2.8)
			draw_line(re + Vector2(7.0, -10.0), re + Vector2(-6.0, -5.0), ink, 2.8)
			# Frown
			draw_arc(mouth_c + Vector2(0.0, 8.0), r * 0.12, PI * 1.15, PI * 1.85, 10, ink, 2.8)
		"curious":
			draw_circle(le, r * 0.075, ink)
			draw_circle(re, r * 0.075, ink)
			draw_circle(le + Vector2(-2.0, -2.0), r * 0.028, Color.WHITE)
			draw_circle(re + Vector2(-2.0, -2.0), r * 0.028, Color.WHITE)
			# Raised eyebrow + gentle o/tilde mouth
			draw_line(re + Vector2(-6.0, -12.0), re + Vector2(6.0, -14.0), ink, 2.4)
			draw_arc(mouth_c + Vector2(0.0, 1.0), r * 0.06, 0.0, TAU, 10, ink, 2.4)
		_:
			# Friendly default smile
			draw_circle(le, r * 0.075, ink)
			draw_circle(re, r * 0.075, ink)
			draw_circle(le + Vector2(-2.0, -2.0), r * 0.028, Color.WHITE)
			draw_circle(re + Vector2(-2.0, -2.0), r * 0.028, Color.WHITE)
			draw_arc(mouth_c - Vector2(0.0, 3.0), r * 0.12, 0.25, PI - 0.25, 10, ink, 2.8)

