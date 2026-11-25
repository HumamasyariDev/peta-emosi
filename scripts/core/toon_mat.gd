class_name ToonMat
extends RefCounted

static var _toon_shader: Shader
static var _outline_shader: Shader
static var _tex_cache: Dictionary = {}
static var _mat_cache: Dictionary = {}
static var _outline_cache: Dictionary = {}


static func make(
	albedo: Color,
	texture_path: String = "",
	opts: Dictionary = {}
) -> ShaderMaterial:
	if _toon_shader == null:
		_toon_shader = load("res://assets/shaders/toon.gdshader")
	if _outline_shader == null:
		_outline_shader = load("res://assets/shaders/outline.gdshader")

	var is_unique: bool = bool(opts.get("unique", false))
	var cache_key := ""
	if not is_unique:
		cache_key = "%s|%s|%s" % [albedo.to_html(true), texture_path, str(opts)]
		if _mat_cache.has(cache_key):
			return _mat_cache[cache_key]

	var mat := ShaderMaterial.new()
	mat.shader = _toon_shader
	mat.set_shader_parameter("albedo", albedo)
	mat.set_shader_parameter("shadow_tint", opts.get("shadow_tint", Color(0.56, 0.50, 0.68, 1.0)))
	mat.set_shader_parameter("rim_strength", opts.get("rim_strength", 0.38))
	mat.set_shader_parameter("spec_strength", opts.get("spec_strength", 0.25))
	mat.set_shader_parameter("triplanar", opts.get("triplanar", false))
	mat.set_shader_parameter("triplanar_scale", opts.get("triplanar_scale", 0.35))
	mat.set_shader_parameter("uv_scale", opts.get("uv_scale", Vector2.ONE))

	if not texture_path.is_empty():
		var tex: Resource = _tex_cache.get(texture_path, null)
		if tex == null:
			tex = load(texture_path)
			if tex != null:
				_tex_cache[texture_path] = tex
		if tex != null:
			mat.set_shader_parameter("albedo_texture", tex)

	if float(opts.get("emission_energy", 0.0)) > 0.0:
		mat.set_shader_parameter("emission_color", opts.get("emission_color", albedo))
		mat.set_shader_parameter("emission_energy", opts.get("emission_energy", 0.0))

	if bool(opts.get("outline", true)):
		var out_col: Color = opts.get("outline_color", Color(0.22, 0.13, 0.12, 1.0))
		var out_w: float = float(opts.get("outline_width", 1.8))
		var max_w: float = float(opts.get("max_world_width", 0.025))
		var out_key := "%s|%.2f|%.3f" % [out_col.to_html(true), out_w, max_w]
		var out_mat: ShaderMaterial = _outline_cache.get(out_key, null)
		if out_mat == null:
			out_mat = ShaderMaterial.new()
			out_mat.shader = _outline_shader
			out_mat.set_shader_parameter("outline_color", out_col)
			out_mat.set_shader_parameter("outline_width", out_w)
			out_mat.set_shader_parameter("max_world_width", max_w)
			_outline_cache[out_key] = out_mat
		mat.next_pass = out_mat

	if not is_unique:
		_mat_cache[cache_key] = mat
	return mat


static func optimize_tree(root: Node) -> void:
	if root is MeshInstance3D:
		var mi := root as MeshInstance3D
		var m := mi.mesh
		if m is SphereMesh:
			var sm := m as SphereMesh
			if sm.radius <= 0.18:
				sm.radial_segments = mini(sm.radial_segments, 12)
				sm.rings = mini(sm.rings, 8)
				mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			else:
				sm.radial_segments = mini(sm.radial_segments, 24)
				sm.rings = mini(sm.rings, 12)
				if mi.scale.x >= 8.0:
					mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		elif m is CylinderMesh:
			var cm := m as CylinderMesh
			cm.radial_segments = mini(cm.radial_segments, 18)
			cm.rings = 1
		elif m is TorusMesh:
			var tm := m as TorusMesh
			tm.rings = mini(tm.rings, 32)
			tm.ring_segments = mini(tm.ring_segments, 14)
			mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		elif m is PlaneMesh:
			mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for child in root.get_children():
		optimize_tree(child)
