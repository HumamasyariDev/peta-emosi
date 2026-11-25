extends Node

var _fade_layer: CanvasLayer
var _iris_rect: ColorRect
var _iris_mat: ShaderMaterial
var _banner_panel: PanelContainer
var _banner_lbl: Label
var _busy: bool = false

const IRIS_SHADER_CODE := """
shader_type canvas_item;

uniform float radius : hint_range(0.0, 1.5) = 1.4;
uniform vec4 fill_color : source_color = vec4(0.18, 0.11, 0.06, 1.0);
uniform vec4 rim_color : source_color = vec4(0.83, 0.60, 0.15, 1.0);
uniform float aspect = 1.7777;

void fragment() {
	vec2 uv = UV - vec2(0.5);
	uv.x *= aspect;
	float dist = length(uv);
	float edge = smoothstep(radius - 0.012, radius + 0.012, dist);
	float rim = smoothstep(radius - 0.022, radius - 0.004, dist) * (1.0 - smoothstep(radius + 0.004, radius + 0.022, dist));
	vec4 col = mix(vec4(0.0), fill_color, edge);
	col = mix(col, rim_color, rim * step(0.005, radius));
	COLOR = col;
}
"""


func _ready() -> void:
	_fade_layer = CanvasLayer.new()
	_fade_layer.layer = 100
	add_child(_fade_layer)

	_iris_rect = ColorRect.new()
	_iris_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_iris_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_iris_rect.visible = false

	var sh := Shader.new()
	sh.code = IRIS_SHADER_CODE
	_iris_mat = ShaderMaterial.new()
	_iris_mat.shader = sh
	_iris_mat.set_shader_parameter("radius", 1.4)
	_iris_mat.set_shader_parameter("fill_color", Color("2c1810"))
	_iris_mat.set_shader_parameter("rim_color", Color("d49826"))
	_iris_rect.material = _iris_mat
	_fade_layer.add_child(_iris_rect)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade_layer.add_child(center)

	_banner_panel = PanelContainer.new()
	_banner_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_banner_panel.visible = false
	_banner_panel.modulate.a = 0.0
	var st := StyleBoxFlat.new()
	st.bg_color = Color("fffbf0")
	st.border_color = Color("d49826")
	st.set_border_width_all(4)
	st.border_width_bottom = 7
	st.set_corner_radius_all(24)
	st.content_margin_left = 34
	st.content_margin_right = 34
	st.content_margin_top = 18
	st.content_margin_bottom = 18
	_banner_panel.add_theme_stylebox_override("panel", st)
	center.add_child(_banner_panel)

	_banner_lbl = Label.new()
	_banner_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var f: Font = StorybookUI.font_display()
	if f != null:
		_banner_lbl.add_theme_font_override("font", f)
	_banner_lbl.add_theme_font_size_override("font_size", 30)
	_banner_lbl.add_theme_color_override("font_color", Color("2c1810"))
	_banner_panel.add_child(_banner_lbl)


func _scene_title(scene_path: String) -> String:
	if scene_path.contains("Pos1"):
		return "POS 1\nGerbang Pengenalan Emosi"
	if scene_path.contains("Pos2"):
		return "POS 2\nTaman 6 Emosi Dasar"
	if scene_path.contains("Pos3"):
		return "POS 3\nBukit Lonceng Emas"
	if scene_path.contains("Pos4"):
		return "POS 4\n6 Langkah Menenangkan Diri"
	if scene_path.contains("Pos5"):
		return "POS 5\nEkspresikan Marah Dengan Sehat"
	if scene_path.contains("Pos6"):
		return "POS 6\nSaat Melihat Teman Marah"
	if scene_path.contains("Pos7"):
		return "POS 7\nPrinsip Saat Marah"
	if scene_path.contains("Pos8"):
		return "POS 8\nFinish: Aku Tahu Emosiku!"
	return "Petualangan Peta Emosi"


func _set_iris_radius(val: float) -> void:
	if _iris_mat != null:
		_iris_mat.set_shader_parameter("radius", val)


func go_to(scene_path: String) -> void:
	if _busy:
		return
	_busy = true
	Game.modal_open = false
	Audio.stop_voice()

	# Keep circle perfectly round for any screen aspect ratio
	var vp_size := get_viewport().get_visible_rect().size
	var asp := vp_size.x / maxf(1.0, vp_size.y)
	_iris_mat.set_shader_parameter("aspect", asp)
	var max_r := Vector2(asp * 0.5, 0.5).length() + 0.12

	_iris_rect.visible = true
	_set_iris_radius(max_r)
	_banner_lbl.text = _scene_title(scene_path)
	_banner_panel.visible = true
	_banner_panel.modulate.a = 0.0
	_banner_panel.scale = Vector2(0.92, 0.92)

	# 1. Classic circular iris closes down to center dot!
	var tw_close := create_tween()
	tw_close.tween_method(_set_iris_radius, max_r, 0.0, 0.42).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	await tw_close.finished

	# 2. Show Storybook Pos title card & swap scene cleanly
	var tw_b_in := create_tween().set_parallel(true)
	tw_b_in.tween_property(_banner_panel, "modulate:a", 1.0, 0.18)
	tw_b_in.tween_property(_banner_panel, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await tw_b_in.finished

	var err := get_tree().change_scene_to_file(scene_path)
	if err != OK:
		push_error("Router gagal memuat scene: %s (code %d)" % [scene_path, err])

	await get_tree().create_timer(0.45).timeout

	# 3. Hide title card & expand circular iris wide open into the new Pos!
	var tw_b_out := create_tween()
	tw_b_out.tween_property(_banner_panel, "modulate:a", 0.0, 0.16)
	await tw_b_out.finished
	_banner_panel.visible = false

	var tw_open := create_tween()
	tw_open.tween_method(_set_iris_radius, 0.0, max_r, 0.48).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	await tw_open.finished

	_iris_rect.visible = false
	_busy = false
