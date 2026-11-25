class_name FxPost
extends MeshInstance3D

@export_range(0.0, 1.0) var line_strength := 0.42
@export_range(0.0, 1.0) var vignette := 0.16
@export_range(0.0, 0.3) var paper_amount := 0.022
@export var grade_enabled := false
@export var full_screen_ink_pass := false

var _mat: ShaderMaterial
var _grade: ShaderMaterial
var _layer: CanvasLayer


func _ready() -> void:
	# Per-mesh toon ink outlines already render crisply; skip heavy fullscreen Sobel pass by default for smooth 60 FPS fullscreen.
	if full_screen_ink_pass and not OS.has_feature("web"):
		var q := QuadMesh.new()
		q.size = Vector2(2, 2)
		mesh = q
		extra_cull_margin = 16384.0
		cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

		_mat = ShaderMaterial.new()
		_mat.shader = load("res://assets/shaders/post_storybook.gdshader")
		_mat.render_priority = 127
		material_override = _mat

	if grade_enabled:
		_layer = CanvasLayer.new()
		_layer.layer = -10
		add_child(_layer)
		var rect := ColorRect.new()
		rect.set_anchors_preset(Control.PRESET_FULL_RECT)
		rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_grade = ShaderMaterial.new()
		_grade.shader = load("res://assets/shaders/post_grade.gdshader")
		_grade.set_shader_parameter("paper_tex", load("res://assets/textures/parchment.webp"))
		rect.material = _grade
		_layer.add_child(rect)

	apply()


func apply() -> void:
	if _mat != null:
		_mat.set_shader_parameter("line_strength", line_strength)
	if _grade != null:
		var size := get_viewport().get_visible_rect().size
		_grade.set_shader_parameter("aspect", size.x / maxf(size.y, 1.0))
		_grade.set_shader_parameter("vignette", vignette)
		_grade.set_shader_parameter("paper_amount", paper_amount)

