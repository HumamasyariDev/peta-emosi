extends Control

## Authentic 3D Adventure Game Title Screen for "Peta Emosi: Petualangan Taman Emosi".
## Zero SaaS cards, zero white callout boxes, zero marketing bullets.
## Pure Nintendo/Storybook cinema framing:
## - Bright sunlit sky at top cradling a custom-drawn layered Logo Emblem & Berry Ribbon
## - Open unobstructed 3D center stage showcasing the Ornate Brick Gate, Sakura Tree, & Waving Nara
## - Sculpted Console Play Menu + Compact Save Medallion anchored cleanly at the bottom over cobblestone

const NaraScene := preload("res://scenes/player/NaraPlayer.tscn")
const EnvPos1 := preload("res://assets/shaders/environments/env_POS1.tres")

var _font_display: Font
var _font_serif: Font
var _font_bold: Font
var _cam: Camera3D
var _nara: Node3D
var _star: MeshInstance3D
var _logo_wrap: Control
var _start_btn: Button
var _music_btn: Button
var _music_icon_wrap: CenterContainer
var _clouds: Array[Node3D] = []
var _butterflies: Array[Dictionary] = []
var _t: float = 0.0
var _bgm_started: bool = false


func _ready() -> void:
	_init_typography()
	_try_start_title_music()
	_build_3d_backdrop()
	_build_game_title_ui()


func _init_typography() -> void:
	_font_bold = StorybookUI.font_body(700)
	_font_display = StorybookUI.font_display()
	_font_serif = StorybookUI.font_serif()


func _input(event: InputEvent) -> void:
	if not _bgm_started and Game.music_enabled:
		if (event is InputEventMouseButton and event.pressed) or (event is InputEventScreenTouch and event.pressed) or (event is InputEventKey and event.pressed):
			_try_start_title_music()


func _try_start_title_music() -> void:
	if Game.music_enabled:
		Audio.play_music("bgm_story", true)
		_bgm_started = true


func _process(delta: float) -> void:
	_t += delta
	StorybookProps.animate_ambient(_clouds, _butterflies, _t, delta)

	# Smooth cinematic slow-orbit camera framing the entire gate + star + waving Nara cleanly between top logo and bottom menu!
	if _cam != null:
		var sway := sin(_t * 0.25) * 1.10
		_cam.position = Vector3(sway, 2.55 + sin(_t * 0.42) * 0.07, 7.6 + cos(_t * 0.25) * 0.30)
		_cam.look_at(Vector3(0.0, 2.15, -2.0), Vector3.UP)

	if _star != null:
		_star.rotation.y += delta * 1.45
		_star.position.y = 4.32 + sin(_t * 2.6) * 0.12

	if _nara != null:
		_nara.position.y = 0.05 + absf(sin(_t * 3.1)) * 0.07
		_nara.rotation_degrees.y = sin(_t * 1.1) * 9.0
		if _nara.get("_right_arm") != null:
			var ra := _nara.get("_right_arm") as Node3D
			ra.rotation.z = 2.48 + sin(_t * 6.8) * 0.28
			ra.rotation.x = -0.35
		if _nara.get("_left_arm") != null:
			var la := _nara.get("_left_arm") as Node3D
			la.rotation.z = -0.18
			la.rotation.x = 0.0
		if _nara.get("_head_group") != null:
			var hg := _nara.get("_head_group") as Node3D
			hg.rotation.z = sin(_t * 2.8) * 0.08

	# Gentle joyful breathing float on the Logo container & Play CTA (zero layout jitter!)
	if _logo_wrap != null:
		var bob := sin(_t * 2.0) * 3.5
		_logo_wrap.offset_top = bob
		_logo_wrap.offset_bottom = bob
	if _start_btn != null and not _start_btn.is_hovered():
		var pulse := 1.0 + sin(_t * 3.2) * 0.016
		_start_btn.pivot_offset = _start_btn.size * 0.5
		_start_btn.scale = Vector2(pulse, pulse)


func _build_3d_backdrop() -> void:
	var svc := SubViewportContainer.new()
	svc.set_anchors_preset(Control.PRESET_FULL_RECT)
	svc.stretch = true
	svc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(svc)

	var vp := SubViewport.new()
	vp.own_world_3d = true
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	vp.msaa_3d = Viewport.MSAA_2X if Game.is_mobile_browser else Viewport.MSAA_4X
	vp.scaling_3d_scale = 1.0
	vp.anisotropic_filtering_level = Viewport.ANISOTROPY_8X if Game.is_mobile_browser else Viewport.ANISOTROPY_16X
	vp.use_debanding = true
	svc.add_child(vp)

	var world := Node3D.new()
	vp.add_child(world)

	var wenv := WorldEnvironment.new()
	wenv.environment = EnvPos1.duplicate()
	if OS.has_feature("web") and wenv.environment != null:
		wenv.environment.ambient_light_energy = 0.46
		wenv.environment.ambient_light_sky_contribution = 0.72
		wenv.environment.tonemap_exposure = 1.0
		wenv.environment.adjustment_enabled = true
		wenv.environment.adjustment_brightness = 1.02
		wenv.environment.adjustment_contrast = 1.06
		wenv.environment.adjustment_saturation = 1.12
	world.add_child(wenv)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-40.0, -30.0, 0.0)
	sun.light_color = Color(1.0, 0.96, 0.86)
	sun.light_energy = 1.24
	sun.shadow_enabled = true
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS
	sun.directional_shadow_blend_splits = true
	sun.directional_shadow_max_distance = 45.0
	sun.shadow_bias = 0.03
	sun.shadow_normal_bias = 1.2
	sun.shadow_blur = 1.4
	world.add_child(sun)

	_cam = Camera3D.new()
	_cam.fov = 48.0
	_cam.position = Vector3(0.0, 2.55, 7.6)
	world.add_child(_cam)

	var grass_mat := ToonMat.make(Color(0.38, 0.74, 0.32), "res://assets/textures/grass.webp", {"triplanar": true, "triplanar_scale": 0.22, "outline": false, "rim_strength": 0.10})
	var ground := MeshInstance3D.new()
	var gplane := PlaneMesh.new()
	gplane.size = Vector2(72.0, 72.0)
	ground.mesh = gplane; ground.material_override = grass_mat
	world.add_child(ground)

	# Centered cobblestone hero path leading through the Taman Emosi Gate!
	var road_mat := ToonMat.make(Color(0.30, 0.32, 0.38), "res://assets/textures/cobblestone.webp", {"triplanar": true, "triplanar_scale": 0.34, "outline": false})
	var road := MeshInstance3D.new()
	var rb := BoxMesh.new(); rb.size = Vector3(4.4, 0.06, 28.0)
	road.mesh = rb; road.material_override = road_mat; road.position = Vector3(0.0, 0.02, -4.0)
	world.add_child(road)

	var hill_mat := ToonMat.make(Color(0.28, 0.64, 0.28), "res://assets/textures/grass.webp", {"triplanar": true, "triplanar_scale": 0.14, "outline": false})
	for h in [
		[Vector3(-20.0, -3.5, -22.0), Vector3(1.6, 0.62, 1.2), 13.0],
		[Vector3(20.0, -3.5, -20.0), Vector3(1.6, 0.65, 1.2), 14.0],
		[Vector3(0.0, -4.8, -36.0), Vector3(2.4, 0.56, 1.2), 16.0],
	]:
		var hm := MeshInstance3D.new()
		var sp := SphereMesh.new()
		var r: float = float(h[2])
		sp.radius = r; sp.height = r * 2.0; sp.radial_segments = 22; sp.rings = 10
		hm.mesh = sp; hm.scale = h[1]; hm.position = h[0]; hm.material_override = hill_mat
		world.add_child(hm)

	# Centered Iconic Brick & Wood Taman Emosi Gate + Ornate Lanterns + Festive Flags
	var gate := Node3D.new()
	gate.position = Vector3(0.0, 0.0, -5.2)
	world.add_child(gate)
	var brick_mat := ToonMat.make(Color(0.84, 0.44, 0.34), "res://assets/textures/brick.webp", {"triplanar": true, "triplanar_scale": 0.48})
	var wood_mat := ToonMat.make(Color(0.62, 0.39, 0.22), "res://assets/textures/wood_planks.webp", {"triplanar": true, "triplanar_scale": 0.42})
	var walnut_mat := ToonMat.make(Color(0.32, 0.19, 0.11), "", {"outline_width": 1.1})
	var lamp_mat := ToonMat.make(Color(1.0, 0.92, 0.52), "", {"emission_color": Color(1.0, 0.84, 0.28), "emission_energy": 0.9})

	for side: float in [-1.0, 1.0]:
		var pil := MeshInstance3D.new()
		var pb := BoxMesh.new(); pb.size = Vector3(0.85, 3.4, 0.85)
		pil.mesh = pb; pil.material_override = brick_mat; pil.position = Vector3(side * 2.55, 1.7, 0.0)
		gate.add_child(pil)
		var lbase := MeshInstance3D.new(); var lbc := CylinderMesh.new(); lbc.top_radius = 0.24; lbc.bottom_radius = 0.28; lbc.height = 0.12; lbc.radial_segments = 10
		lbase.mesh = lbc; lbase.material_override = walnut_mat; lbase.position = Vector3(side * 2.55, 3.82, 0.0)
		gate.add_child(lbase)
		var bulb := MeshInstance3D.new(); var bsp := SphereMesh.new(); bsp.radius = 0.20; bsp.height = 0.40; bsp.radial_segments = 10; bsp.rings = 6
		bulb.mesh = bsp; bulb.material_override = lamp_mat; bulb.position = Vector3(side * 2.55, 4.04, 0.0)
		gate.add_child(bulb)
		var lcap := MeshInstance3D.new(); var lcc := CylinderMesh.new(); lcc.top_radius = 0.03; lcc.bottom_radius = 0.32; lcc.height = 0.24; lcc.radial_segments = 6
		lcap.mesh = lcc; lcap.material_override = walnut_mat; lcap.position = Vector3(side * 2.55, 4.30, 0.0)
		gate.add_child(lcap)

	var beam := MeshInstance3D.new()
	var bb := BoxMesh.new(); bb.size = Vector3(6.1, 0.52, 0.62)
	beam.mesh = bb; beam.material_override = wood_mat; beam.position = Vector3(0.0, 3.5, 0.0)
	gate.add_child(beam)

	var flag_cols := [Color(0.96, 0.34, 0.42), Color(0.98, 0.80, 0.20), Color(0.24, 0.68, 0.94), Color(0.28, 0.78, 0.46), Color(0.68, 0.40, 0.88)]
	for i in range(5):
		var fl := MeshInstance3D.new()
		var fm := PrismMesh.new(); fm.size = Vector3(0.42, 0.46, 0.05)
		fl.mesh = fm; fl.material_override = ToonMat.make(flag_cols[i])
		fl.position = Vector3(-1.6 + float(i) * 0.80, 3.10 - absf(float(i) - 2.0) * 0.05, 0.33)
		fl.rotation_degrees.z = 180.0
		gate.add_child(fl)

	_star = MeshInstance3D.new()
	_star.mesh = _make_star_mesh(0.65, 0.30, 0.18)
	_star.material_override = ToonMat.make(Color(1.0, 0.86, 0.18), "", {"emission_color": Color(1.0, 0.82, 0.20), "emission_energy": 0.72})
	_star.position = Vector3(0.0, 4.32, -5.2)
	world.add_child(_star)

	# Lush balanced framing trees (Sakura pink on right, sunlit green on left!)
	var trunk_mat := ToonMat.make(Color(0.55, 0.36, 0.22), "res://assets/textures/bark.webp", {"triplanar": true})
	var leaf_mat := ToonMat.make(Color(0.28, 0.68, 0.30), "res://assets/textures/leaf_canopy.webp", {"triplanar": true, "triplanar_scale": 0.45})
	var sakura_mat := ToonMat.make(Color(1.0, 0.66, 0.78), "res://assets/textures/leaf_canopy.webp", {"triplanar": true, "triplanar_scale": 0.48})
	for t in [
		[Vector3(-5.6, 0.0, -4.8), 1.25, leaf_mat],
		[Vector3(5.6, 0.0, -4.6), 1.22, sakura_mat],
		[Vector3(-7.4, 0.0, -11.2), 1.35, sakura_mat],
		[Vector3(7.4, 0.0, -11.0), 1.35, leaf_mat],
		[Vector3(0.0, 0.0, -15.5), 1.15, leaf_mat],
	]:
		var tr := Node3D.new()
		tr.position = t[0]
		var sc: float = float(t[1])
		tr.scale = Vector3(sc, sc, sc)
		world.add_child(tr)
		var trunk := MeshInstance3D.new()
		var tc := CylinderMesh.new(); tc.top_radius = 0.26; tc.bottom_radius = 0.38; tc.height = 2.2; tc.radial_segments = 16
		trunk.mesh = tc; trunk.material_override = trunk_mat; trunk.position = Vector3(0.0, 1.1, 0.0)
		tr.add_child(trunk)
		var cr := MeshInstance3D.new()
		var sp := SphereMesh.new(); sp.radius = 1.45; sp.height = 2.8; sp.radial_segments = 20; sp.rings = 12
		cr.mesh = sp; cr.material_override = t[2]; cr.position = Vector3(0.0, 2.95, 0.0)
		tr.add_child(cr)

	# Colorful flower beds framing both sides of the garden path
	var fcols := [Color(1.0, 0.56, 0.68), Color(0.99, 0.88, 0.28), Color(0.58, 0.77, 0.99), Color(0.99, 0.96, 0.92)]
	for i in range(10):
		var side := -1.0 if i % 2 == 0 else 1.0
		var fx := side * (3.0 + float(i % 3) * 0.95)
		var fz := 2.4 - float(i) * 0.95
		StorybookProps.spawn_flower(world, Vector3(fx, 0.0, fz), fcols[i % fcols.size()])

	# Nara right in the sunny hero spotlight waving cheerfully to the player!
	_nara = NaraScene.instantiate()
	_nara.position = Vector3(0.0, 0.05, -1.6)
	_nara.scale = Vector3(1.15, 1.15, 1.15)
	world.add_child(_nara)
	_nara.set_physics_process(false)
	if _nara.has_method("set_control_locked"):
		_nara.call("set_control_locked", true)

	_clouds = StorybookProps.spawn_clouds(world)
	_butterflies = StorybookProps.spawn_butterflies(world, [
		Vector3(-2.4, 1.8, -1.2), Vector3(2.4, 2.0, -1.8), Vector3(0.0, 2.2, -3.2)
	])
	ToonMat.optimize_tree(world)


func _build_game_title_ui() -> void:
	# Subtle bottom-edge-only warm floor fade so bottom controls stay effortless to read without darkening the sky!
	var bot_fade := TextureRect.new()
	bot_fade.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	bot_fade.offset_top = -200.0
	bot_fade.offset_bottom = 0.0
	bot_fade.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bot_fade.stretch_mode = TextureRect.STRETCH_SCALE
	bot_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var bg_grad := Gradient.new()
	bg_grad.set_color(0, Color(0.08, 0.05, 0.02, 0.0))
	bg_grad.set_color(1, Color(0.08, 0.05, 0.02, 0.52))
	var gtex := GradientTexture2D.new()
	gtex.gradient = bg_grad
	gtex.fill_from = Vector2(0.5, 0.0)
	gtex.fill_to = Vector2(0.5, 1.0)
	bot_fade.texture = gtex
	add_child(bot_fade)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 36)
	margin.add_theme_constant_override("margin_right", 36)
	margin.add_theme_constant_override("margin_top", 22)
	margin.add_theme_constant_override("margin_bottom", 20)
	add_child(margin)

	var root_v := VBoxContainer.new()
	root_v.add_theme_constant_override("separation", 0)
	margin.add_child(root_v)

	# === TOP ZONE: Centered Iconic Game Logo Emblem + Minimal Corner Audio Button ===
	var top_overlay := Control.new()
	top_overlay.custom_minimum_size = Vector2(0, 144)
	top_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root_v.add_child(top_overlay)

	# Minimal Circular Sound Toggle at Top-Right (Nintendo-clean!)
	_music_btn = Button.new()
	_music_btn.text = ""
	_music_btn.custom_minimum_size = Vector2(48, 48)
	_music_btn.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_music_btn.offset_left = -48.0
	_music_btn.offset_bottom = 48.0
	_music_btn.tooltip_text = "Aktifkan / Matikan Musik"
	_music_btn.mouse_entered.connect(func() -> void:
		Audio.play_sfx("select")
		_music_btn.pivot_offset = _music_btn.size * 0.5
		_music_btn.scale = Vector2(1.07, 1.07)
	)
	_music_btn.mouse_exited.connect(func() -> void:
		_music_btn.scale = Vector2.ONE
	)
	_music_btn.pressed.connect(_on_toggle_music)
	_music_icon_wrap = CenterContainer.new()
	_music_icon_wrap.set_anchors_preset(Control.PRESET_FULL_RECT)
	_music_icon_wrap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_music_btn.add_child(_music_icon_wrap)
	top_overlay.add_child(_music_btn)
	_refresh_music_btn()

	# Centered Floating Game Logo Emblem over the open blue sky!
	var logo_center := CenterContainer.new()
	logo_center.set_anchors_preset(Control.PRESET_FULL_RECT)
	logo_center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top_overlay.add_child(logo_center)
	_logo_wrap = logo_center

	var logo_v := VBoxContainer.new()
	logo_v.alignment = BoxContainer.ALIGNMENT_CENTER
	logo_v.add_theme_constant_override("separation", 3)
	logo_v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	logo_center.add_child(logo_v)

	# Big Chunky Layered Game Title ("PETA EMOSI")
	var title_row := HBoxContainer.new()
	title_row.alignment = BoxContainer.ALIGNMENT_CENTER
	title_row.add_theme_constant_override("separation", 14)
	logo_v.add_child(title_row)

	title_row.add_child(StorybookUI.make_icon("star", 28.0, StorybookUI.HONEY_LIGHT, StorybookUI.WALNUT_DARK))
	var logo := Label.new()
	logo.text = "PETA EMOSI"
	logo.add_theme_font_override("font", _font_display)
	logo.add_theme_font_size_override("font_size", 74)
	logo.add_theme_color_override("font_color", StorybookUI.HONEY_LIGHT)
	logo.add_theme_color_override("font_outline_color", StorybookUI.WALNUT_DARK)
	logo.add_theme_color_override("font_shadow_color", Color(0.14, 0.06, 0.01, 0.72))
	logo.add_theme_constant_override("outline_size", 16)
	logo.add_theme_constant_override("shadow_offset_x", 0)
	logo.add_theme_constant_override("shadow_offset_y", 7)
	title_row.add_child(logo)
	title_row.add_child(StorybookUI.make_icon("star", 28.0, StorybookUI.HONEY_LIGHT, StorybookUI.WALNUT_DARK))

	# Clean Berry-Crimson Game Subtitle Ribbon tucked right under the logo
	var rib_center := HBoxContainer.new()
	rib_center.alignment = BoxContainer.ALIGNMENT_CENTER
	logo_v.add_child(rib_center)

	var rib := PanelContainer.new()
	rib.add_theme_stylebox_override("panel", StorybookUI.make_panel_box(
		StorybookUI.BERRY, StorybookUI.HONEY_LIGHT, 14, 2, 4, 22, 4, true
	))
	var rib_lbl := Label.new()
	rib_lbl.text = "Petualangan Taman Emosi"
	rib_lbl.add_theme_font_override("font", _font_serif)
	rib_lbl.add_theme_font_size_override("font_size", 19)
	rib_lbl.add_theme_color_override("font_color", StorybookUI.CREAM)
	rib.add_child(rib_lbl)
	rib_center.add_child(rib)

	# Crisp 1-line bold storybook tagline floating cleanly under the ribbon (ZERO box, 100% readable!)
	var tag_lbl := Label.new()
	tag_lbl.text = "Jelajahi 8 Pulau Cerita  •  Kenali 6 Perasaan Dasar  •  Raih Piala Juara!"
	tag_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tag_lbl.add_theme_font_override("font", _font_bold)
	tag_lbl.add_theme_font_size_override("font_size", 14)
	tag_lbl.add_theme_color_override("font_color", StorybookUI.CREAM)
	tag_lbl.add_theme_color_override("font_outline_color", StorybookUI.WALNUT_DARK)
	tag_lbl.add_theme_constant_override("outline_size", 6)
	logo_v.add_child(tag_lbl)

	# === MIDDLE STAGE: 100% OPEN UNOBSTRUCTED 3D HERO SHOWCASE (GATE + WAVING NARA!) ===
	var open_stage := Control.new()
	open_stage.size_flags_vertical = Control.SIZE_EXPAND_FILL
	open_stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root_v.add_child(open_stage)

	# === BOTTOM ZONE: Sleek Console Play Menu + Compact Save Medallion ===
	var bot_v := VBoxContainer.new()
	bot_v.alignment = BoxContainer.ALIGNMENT_CENTER
	bot_v.add_theme_constant_override("separation", 10)
	root_v.add_child(bot_v)

	# Compact Nintendo-style Save Medallion (only shown when player has saved progress!)
	if Game.has_save():
		var save_center := HBoxContainer.new()
		save_center.alignment = BoxContainer.ALIGNMENT_CENTER
		bot_v.add_child(save_center)

		var save_pill := PanelContainer.new()
		save_pill.add_theme_stylebox_override("panel", StorybookUI.make_panel_box(
			Color(0.18, 0.11, 0.06, 0.88), StorybookUI.HONEY, 16, 2, 3, 16, 5, false
		))
		var shb := HBoxContainer.new()
		shb.add_theme_constant_override("separation", 6)
		for st_id in range(1, 9):
			var done := Game.is_station_done(st_id)
			shb.add_child(StorybookUI.make_icon(
				"star",
				17.0 if done else 14.0,
				StorybookUI.HONEY_LIGHT if done else Color(0.95, 0.90, 0.80, 0.34),
				StorybookUI.WALNUT_DARK
			))
		var slbl := Label.new()
		slbl.text = "%d/8" % Game.get_completed_count()
		slbl.add_theme_font_override("font", _font_bold)
		slbl.add_theme_font_size_override("font_size", 14)
		slbl.add_theme_color_override("font_color", StorybookUI.CREAM)
		shb.add_child(slbl)
		var div := ColorRect.new()
		div.color = Color(1.0, 0.86, 0.45, 0.35)
		div.custom_minimum_size = Vector2(2, 16)
		div.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		shb.add_child(div)
		shb.add_child(StorybookUI.make_icon("coin", 17.0, StorybookUI.HONEY_LIGHT, StorybookUI.WALNUT_DARK))
		var clbl := Label.new()
		clbl.text = "%d Koin" % Game.coins
		clbl.add_theme_font_override("font", _font_bold)
		clbl.add_theme_font_size_override("font_size", 14)
		clbl.add_theme_color_override("font_color", StorybookUI.HONEY_LIGHT)
		shb.add_child(clbl)
		save_pill.add_child(shb)
		save_center.add_child(save_pill)

	# Centered Sculpted Console Action Buttons
	var cta_center := HBoxContainer.new()
	cta_center.alignment = BoxContainer.ALIGNMENT_CENTER
	cta_center.add_theme_constant_override("separation", 14)
	bot_v.add_child(cta_center)

	_start_btn = Button.new()
	_start_btn.text = ""
	_start_btn.custom_minimum_size = Vector2(315, 58)
	StorybookUI.style_tactile_button(_start_btn, StorybookUI.BERRY, StorybookUI.HONEY_LIGHT, StorybookUI.CREAM, _font_display, 22, 18, 24, 10)
	var cta_hb := HBoxContainer.new()
	cta_hb.set_anchors_preset(Control.PRESET_FULL_RECT)
	cta_hb.alignment = BoxContainer.ALIGNMENT_CENTER
	cta_hb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cta_hb.add_theme_constant_override("separation", 10)
	cta_hb.add_child(StorybookUI.make_icon("play_right", 18.0, StorybookUI.HONEY_LIGHT, StorybookUI.WALNUT_DARK))
	var cta_lbl := Label.new()
	cta_lbl.text = "Lanjutkan Petualangan" if Game.has_save() else "Mulai Petualangan"
	cta_lbl.add_theme_font_override("font", _font_display)
	cta_lbl.add_theme_font_size_override("font_size", 22)
	cta_lbl.add_theme_color_override("font_color", StorybookUI.CREAM)
	cta_hb.add_child(cta_lbl)
	_start_btn.add_child(cta_hb)
	_start_btn.mouse_entered.connect(func() -> void:
		Audio.play_sfx("select")
		_start_btn.pivot_offset = _start_btn.size * 0.5
		_start_btn.scale = Vector2(1.04, 1.04)
	)
	_start_btn.mouse_exited.connect(func() -> void:
		_start_btn.scale = Vector2.ONE
	)
	_start_btn.pressed.connect(func() -> void:
		Audio.play_sfx("confirm")
		var target_scene := Game.get_continue_scene() if Game.has_save() else "res://scenes/worlds/Pos1_GerbangPengenalan.tscn"
		Router.go_to(target_scene)
	)
	cta_center.add_child(_start_btn)

	if Game.has_save():
		var reset_btn := Button.new()
		reset_btn.text = "Mulai Baru"
		reset_btn.custom_minimum_size = Vector2(148, 58)
		StorybookUI.style_tactile_button(reset_btn, Color("fffaf0"), StorybookUI.WALNUT, StorybookUI.INK, _font_display, 17, 18, 16, 10)
		reset_btn.mouse_entered.connect(func() -> void:
			Audio.play_sfx("select")
			reset_btn.pivot_offset = reset_btn.size * 0.5
			reset_btn.scale = Vector2(1.03, 1.03)
		)
		reset_btn.mouse_exited.connect(func() -> void:
			reset_btn.scale = Vector2.ONE
		)
		reset_btn.pressed.connect(func() -> void:
			Audio.play_sfx("select")
			Game.reset_progress()
			Router.go_to("res://scenes/worlds/Pos1_GerbangPengenalan.tscn")
		)
		cta_center.add_child(reset_btn)

	_start_btn.grab_focus()

	# Clean console-style keycap hint row at bottom
	var hints_row := HBoxContainer.new()
	hints_row.alignment = BoxContainer.ALIGNMENT_CENTER
	hints_row.add_theme_constant_override("separation", 18)
	bot_v.add_child(hints_row)
	for pair in [["WASD / Analog", "Jalan"], ["Spasi", "Lompat"], ["E", "Aksi"], ["M", "Peta Pos"]]:
		var item := HBoxContainer.new()
		item.add_theme_constant_override("separation", 6)
		var cap := PanelContainer.new()
		cap.add_theme_stylebox_override("panel", StorybookUI.make_panel_box(
			Color(0.14, 0.09, 0.05, 0.86), Color(1.0, 0.84, 0.40, 0.55), 7, 1, 2, 8, 2, false
		))
		var klbl := Label.new()
		klbl.text = pair[0]
		klbl.add_theme_font_override("font", _font_bold)
		klbl.add_theme_font_size_override("font_size", 12)
		klbl.add_theme_color_override("font_color", StorybookUI.HONEY_LIGHT)
		cap.add_child(klbl)
		item.add_child(cap)
		var dlbl := Label.new()
		dlbl.text = pair[1]
		dlbl.add_theme_font_override("font", _font_bold)
		dlbl.add_theme_font_size_override("font_size", 13)
		dlbl.add_theme_color_override("font_color", StorybookUI.CREAM)
		dlbl.add_theme_color_override("font_outline_color", StorybookUI.WALNUT_DARK)
		dlbl.add_theme_constant_override("outline_size", 5)
		item.add_child(dlbl)
		hints_row.add_child(item)


func _on_toggle_music() -> void:
	var next_state := not Game.music_enabled
	Game.music_enabled = next_state
	Game.sound_enabled = next_state
	Game.save_progress()
	if next_state:
		Audio.play_sfx("pop")
		Audio.play_music("bgm_story", true)
		_bgm_started = true
	else:
		Audio.stop_music()
		Audio.stop_voice()
	_refresh_music_btn()


func _refresh_music_btn() -> void:
	if _music_btn == null:
		return
	var on := Game.music_enabled
	var bg := StorybookUI.HONEY if on else StorybookUI.PAPER_DEEP
	var fg := StorybookUI.INK if on else StorybookUI.INK_SOFT
	StorybookUI.style_tactile_button(_music_btn, bg, StorybookUI.WALNUT, fg, _font_display, 14, 24, 0, 0)
	if _music_icon_wrap != null:
		for c in _music_icon_wrap.get_children():
			c.queue_free()
		_music_icon_wrap.add_child(StorybookUI.make_icon("sound_on" if on else "sound_off", 22.0, fg, StorybookUI.WALNUT if on else StorybookUI.BERRY))


func _make_star_mesh(outer_r: float, inner_r: float, half_t: float) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var pts: Array[Vector2] = []
	for i in range(10):
		var a := -PI * 0.5 + float(i) * PI / 5.0
		var r := outer_r if i % 2 == 0 else inner_r
		pts.append(Vector2(cos(a) * r, sin(a) * r))
	var fc := Vector3(0.0, 0.0, half_t)
	var bc := Vector3(0.0, 0.0, -half_t)
	for i in range(10):
		var p1 := pts[i]
		var p2 := pts[(i + 1) % 10]
		var v1f := Vector3(p1.x, -p1.y, 0.0)
		var v2f := Vector3(p2.x, -p2.y, 0.0)
		st.add_vertex(fc); st.add_vertex(v1f); st.add_vertex(v2f)
		st.add_vertex(bc); st.add_vertex(v2f); st.add_vertex(v1f)
	st.generate_normals()
	return st.commit()
