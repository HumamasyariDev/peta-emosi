class_name Pos4Props
extends Node3D

signal zone_changed(zone_id: String, entered: bool)
signal orb_bumped
signal stone_stepped(num: int)
signal next_route_entered

var step_positions: Dictionary = {
	1: Vector3(0.0, 0.0, 5.2),
	2: Vector3(0.0, 0.0, 0.4),
	3: Vector3(-2.6, 0.0, -4.6),
	4: Vector3(0.0, 0.0, -8.8),
	5: Vector3(3.6, 0.0, -25.6),
	6: Vector3(0.0, 0.0, -31.5),
}
var star_position: Vector3 = Vector3(0.0, 0.0, -36.5)
var exit_gate_position: Vector3 = Vector3(0.0, 0.0, -43.5)

var _time: float = 0.0
var _clouds: Array[Node3D] = []
var _butterflies: Array[Dictionary] = []
var _guide_arrow: Node3D
var _comic_bubble: Label3D
var _comic_timer: float = 0.0

# Angry cloud attached above Nara
var _angry_cloud_root: Node3D
var _angry_cloud_puffs: Array[MeshInstance3D] = []
var _angry_bolt: MeshInstance3D
var _anger_ratio: float = 1.0 # 1.0 = full anger, 0.0 = completely calm

# Step 1: STOP zone
var _stop_ring: MeshInstance3D
var _stop_charge_ring: MeshInstance3D
var _stop_lbl: Label3D
var _stop_sign_root: Node3D
var _stop_sign_face: MeshInstance3D

# Step 2: Provoking Anger Orb
var _orb_root: Node3D
var _orb_mesh: MeshInstance3D
var _orb_ring: MeshInstance3D
var _orb_lbl: Label3D
var _orb_burst: GPUParticles3D
var _orb_wave: MeshInstance3D
var _orb_wave_mat: StandardMaterial3D
var _orb_wave_t: float = 99.0
var _calm_beam: MeshInstance3D
var _calm_beam_t: float = 99.0
var _calm_beam_start: Vector3 = Vector3.ZERO
var _orb_calmed: bool = false

# Step 3: 3D Garden Pinwheel
var _pinwheel_blades: Node3D
var _pinwheel_ring: MeshInstance3D
var _pinwheel_lbl: Label3D
var _pinwheel_petals: GPUParticles3D
var _wind_ring: MeshInstance3D
var _wind_ring_mat: StandardMaterial3D
var _wind_ring_t: float = 99.0
var _wind_start_pos: Vector3 = Vector3.ZERO
var _pinwheel_spin_speed: float = 0.65
var _pinwheel_done: bool = false

# Step 4: 10 Stepping Stones across stream + real Water Splash burst!
var _step4_banner: Label3D
var _stone_meshes: Dictionary = {}
var _stone_labels: Dictionary = {}
var _stone_positions: Dictionary = {}
var _stone_bounce: Dictionary = {}
var _water_ripples: Array[Dictionary] = []
var _splash_particles: GPUParticles3D
var _next_stone: int = 1

# Step 5: Cozy Gazebo & Orange Cat
var _gazebo_ring: MeshInstance3D
var _gazebo_lbl: Label3D
var _cat_node: Node3D
var _cat_tail: Node3D
var _cat_head: Node3D
var _cat_bubble: Label3D
var _cat_hearts: Array[Label3D] = []
var _cat_happy_t: float = 0.0

# Step 6: Floral Archway, Star & Pos 5 Exit Gate
var _arch_lbl: Label3D
var _beacon_pillar: MeshInstance3D
var _active_step: int = 1
var _star_mesh: MeshInstance3D
var _star_mat: ShaderMaterial
var _confetti: GPUParticles3D
var _gate_left_pivot: Node3D
var _gate_right_pivot: Node3D
var _gate_blocker: StaticBody3D
var _portal_area: Area3D
var _gate_lbl: Label3D
var _gate_opened: bool = false


func _ready() -> void:
	_build_ground_stream_and_paths()
	_build_horizon_hills_and_flowers()
	_build_closed_back_gate()
	_build_brick_fences()
	_build_broken_blocks_trigger()
	_build_step1_stop_zone()
	_build_step2_anger_orb()
	_build_step3_pinwheel()
	_build_step4_stepping_stones()
	_build_step5_cozy_gazebo_and_cat()
	_build_step6_floral_arch_and_exit()
	_build_trees()
	_build_guide_arrow()
	_build_waypoint_beacon()
	_clouds = StorybookProps.spawn_clouds(self)
	_butterflies = StorybookProps.spawn_butterflies(self, [
		Vector3(-5.2, 1.4, 3.0), Vector3(5.2, 1.5, -14.0), Vector3(4.5, 1.6, -27.0), Vector3(-4.2, 1.5, -31.0)
	])
	ToonMat.optimize_tree(self)
	set_active_step(1)


func attach_angry_cloud(player: Node3D) -> void:
	_angry_cloud_root = Node3D.new()
	_angry_cloud_root.position = Vector3(0.0, 2.38, 0.0)
	player.add_child(_angry_cloud_root)

	# Cute compact cartoon storm cloud (cool slate-violet, NOT muddy brown!)
	var cmat := ToonMat.make(Color(0.52, 0.50, 0.66), "", {"outline_width": 0.9, "unique": true})
	var puff_defs := [
		[Vector3(0.0, 0.04, 0.0), 0.17],
		[Vector3(-0.15, -0.01, 0.02), 0.125],
		[Vector3(0.15, -0.01, -0.02), 0.125],
		[Vector3(0.05, 0.10, -0.03), 0.11],
	]
	for pd in puff_defs:
		var m := MeshInstance3D.new()
		var sp := SphereMesh.new()
		var r: float = float(pd[1])
		sp.radius = r
		sp.height = r * 2.0
		sp.radial_segments = 8
		sp.rings = 6
		m.mesh = sp
		m.material_override = cmat
		m.position = pd[0]
		_angry_cloud_root.add_child(m)
		_angry_cloud_puffs.append(m)

	_angry_bolt = MeshInstance3D.new()
	var bbox := BoxMesh.new()
	bbox.size = Vector3(0.06, 0.18, 0.04)
	_angry_bolt.mesh = bbox
	_angry_bolt.material_override = ToonMat.make(Color(1.0, 0.84, 0.16), "", {"emission_color": Color(1.0, 0.72, 0.08), "emission_energy": 0.85})
	_angry_bolt.position = Vector3(0.0, -0.15, 0.0)
	_angry_bolt.rotation_degrees.z = 18.0
	_angry_cloud_root.add_child(_angry_bolt)


func set_anger_ratio(ratio: float, sun_light: DirectionalLight3D) -> void:
	_anger_ratio = clampf(ratio, 0.0, 1.0)
	if sun_light != null:
		# Smoothly transition world light from heated angry coral-orange -> bright sunny calm white
		var angry_col := Color(1.0, 0.72, 0.56)
		var calm_col := Color(1.0, 0.96, 0.86)
		sun_light.light_color = calm_col.lerp(angry_col, _anger_ratio)
	if _angry_cloud_root != null:
		_angry_cloud_root.visible = _anger_ratio > 0.02
		var sc := 0.35 + _anger_ratio * 0.75
		_angry_cloud_root.scale = Vector3(sc, sc, sc)
		if _angry_bolt != null:
			_angry_bolt.visible = _anger_ratio > 0.35


func _process(delta: float) -> void:
	if Game.modal_open:
		return
	_time += delta
	StorybookProps.animate_ambient(_clouds, _butterflies, _time, delta)

	# Angry cloud bob & rumble above Nara
	if _angry_cloud_root != null and _angry_cloud_root.visible:
		_angry_cloud_root.position.y = 2.40 + sin(_time * 4.5) * 0.04
		_angry_cloud_root.position.x = sin(_time * 14.0) * 0.02 * _anger_ratio
		if _angry_bolt != null and _angry_bolt.visible:
			_angry_bolt.scale.y = 0.85 + absf(sin(_time * 10.0)) * 0.35

	# Step 2: Provoking expressive red anger orb bounce
	if _orb_mesh != null and not _orb_calmed:
		_orb_mesh.position.y = 1.12 + absf(sin(_time * 4.8)) * 0.32
		_orb_mesh.rotation.y = sin(_time * 2.2) * 0.35
		var sc := 1.0 + sin(_time * 9.6) * 0.06
		_orb_mesh.scale = Vector3(sc, sc, sc)

	# Step 3: Pinwheel spinning blades
	if _pinwheel_blades != null:
		_pinwheel_blades.rotation.z -= delta * _pinwheel_spin_speed
		if not _pinwheel_done and _pinwheel_spin_speed > 0.8:
			_pinwheel_spin_speed = maxf(0.65, _pinwheel_spin_speed - delta * 2.5)
		elif _pinwheel_done and _pinwheel_spin_speed > 3.2:
			_pinwheel_spin_speed = maxf(3.2, _pinwheel_spin_speed - delta * 1.4)

	# Step 4: Stepping stone bounce recovery
	for k: int in _stone_bounce.keys():
		var t_val: float = float(_stone_bounce[k])
		if t_val > 0.0:
			t_val = maxf(0.0, t_val - delta * 4.0)
			_stone_bounce[k] = t_val
			var m: MeshInstance3D = _stone_meshes[k] as MeshInstance3D
			var squash := sin(t_val * PI) * 0.16
			m.scale = Vector3(1.0 + squash, 1.0 - squash * 0.8, 1.0 + squash)

	# Step 2: Expanding golden calm wave & calm beam flying from Nara into Red Orb!
	if _calm_beam != null and _calm_beam_t < 0.42:
		_calm_beam_t += delta
		var bp := clampf(_calm_beam_t / 0.42, 0.0, 1.0)
		var orb_t: Vector3 = (step_positions[2] as Vector3) + Vector3(0.0, 1.15, 0.0)
		_calm_beam.global_position = _calm_beam_start.lerp(orb_t, bp)
		var bsc := 0.7 + sin(bp * PI) * 0.8
		_calm_beam.scale = Vector3(bsc, bsc, bsc)
		_calm_beam.visible = bp < 0.99

	if _orb_wave != null and _orb_wave_t < 1.0:
		_orb_wave_t += delta
		var p := clampf(_orb_wave_t / 1.0, 0.0, 1.0)
		var sc_w := 0.6 + p * 3.8
		_orb_wave.scale = Vector3(sc_w, 1.0, sc_w)
		_orb_wave.visible = p < 0.99
		if _orb_wave_mat != null:
			_orb_wave_mat.albedo_color = Color(1.0, 0.88, 0.30, (1.0 - p) * 0.85)

	# Step 3: Visible 3D Wind Gust Ring flying from Nara straight into Windmill sails!
	if _wind_ring != null and _wind_ring_t < 0.75:
		_wind_ring_t += delta
		var wp := clampf(_wind_ring_t / 0.75, 0.0, 1.0)
		var target_w: Vector3 = (step_positions[3] as Vector3) + Vector3(0.0, 2.85, 0.45)
		_wind_ring.global_position = _wind_start_pos.lerp(target_w, wp)
		var wsc := 0.55 + wp * 1.45
		_wind_ring.scale = Vector3(wsc, wsc, wsc)
		_wind_ring.visible = wp < 0.99
		if _wind_ring_mat != null:
			_wind_ring_mat.albedo_color = Color(0.62, 0.94, 1.0, (1.0 - wp) * 0.85)

	# Step 4: Expanding water ripples around stepped stones
	var keep_ripples: Array[Dictionary] = []
	for rp in _water_ripples:
		var rm: MeshInstance3D = rp["mesh"] as MeshInstance3D
		var rmat: StandardMaterial3D = rp["mat"] as StandardMaterial3D
		var rt: float = float(rp["t"]) + delta
		rp["t"] = rt
		if rt >= 0.85:
			rm.queue_free()
		else:
			var p := rt / 0.85
			var sc_r := 0.8 + p * 1.7
			rm.scale = Vector3(sc_r, 1.0, sc_r)
			rmat.albedo_color = Color(0.92, 0.98, 1.0, (1.0 - p) * 0.75)
			keep_ripples.append(rp)
	_water_ripples = keep_ripples

	# Step 5: Cute Orange Cat smooth purring & cozy head-nuzzle reaction (no jittery bouncing!)
	if _cat_happy_t > 0.0:
		_cat_happy_t = maxf(0.0, _cat_happy_t - delta)
		if _cat_node != null:
			# Soft cozy purring breath squash-and-stretch right on the cushion
			var purr := sin(_time * 4.2)
			_cat_node.position.y = 0.42
			_cat_node.scale = Vector3(1.0 - purr * 0.04, 1.0 + purr * 0.06, 1.0 - purr * 0.04)
		if _cat_tail != null:
			_cat_tail.rotation_degrees.z = sin(_time * 4.8) * 18.0
		if _cat_head != null:
			# Gently tilts head upward & leans affectionately into Nara's hand!
			_cat_head.rotation_degrees.x = lerpf(_cat_head.rotation_degrees.x, -14.0 + sin(_time * 3.0) * 4.5, clampf(delta * 6.0, 0.0, 1.0))
			_cat_head.rotation_degrees.z = sin(_time * 2.4) * 9.0
			_cat_head.rotation_degrees.y = sin(_time * 1.8) * 6.0
		for i in range(_cat_hearts.size()):
			var h := _cat_hearts[i]
			h.visible = true
			var cyc := fmod(_time * 0.85 + float(i) * 0.33, 1.0)
			h.position = Vector3(sin(cyc * TAU + float(i)) * 0.22, 0.85 + cyc * 1.05, 0.0)
			h.modulate.a = 1.0 - cyc
		if _cat_bubble != null:
			_cat_bubble.visible = true
	else:
		if _cat_node != null:
			_cat_node.position.y = 0.42
			_cat_node.scale = _cat_node.scale.lerp(Vector3.ONE, clampf(delta * 6.0, 0.0, 1.0))
		if _cat_tail != null:
			_cat_tail.rotation_degrees.z = sin(_time * 2.6) * 14.0
		if _cat_head != null:
			_cat_head.rotation_degrees.x = lerpf(_cat_head.rotation_degrees.x, 0.0, clampf(delta * 6.0, 0.0, 1.0))
			_cat_head.rotation_degrees.z = lerpf(_cat_head.rotation_degrees.z, 0.0, clampf(delta * 6.0, 0.0, 1.0))
			_cat_head.rotation_degrees.y = sin(_time * 1.2) * 10.0
		for h in _cat_hearts:
			h.visible = false
		if _cat_bubble != null:
			_cat_bubble.visible = false

	# Star bob & spin
	if _star_mesh != null and _star_mesh.visible and not _star_mesh.has_meta("collected"):
		_star_mesh.position.y = 2.35 + sin(_time * 2.5) * 0.14
		_star_mesh.rotation.y += delta * 1.1

	# Spider-Man style pulsing vertical golden waypoint beam on current objective!
	if _beacon_pillar != null and _beacon_pillar.visible:
		var pulse := 0.85 + sin(_time * 4.0) * 0.18
		_beacon_pillar.scale = Vector3(pulse, 1.0, pulse)
		_beacon_pillar.rotation.y += delta * 1.2

	# Floating 3D comic speech bubble timer
	if _comic_bubble != null and _comic_timer > 0.0:
		_comic_timer -= delta
		_comic_bubble.position.y += delta * 0.16
		if _comic_timer <= 0.0:
			_comic_bubble.visible = false


func set_active_step(step_num: int) -> void:
	_active_step = step_num
	# Eliminate 3D text clutter: ONLY show full instruction label for the CURRENT active step!
	if _stop_lbl != null:
		_stop_lbl.visible = (step_num == 1)
	if _orb_lbl != null:
		_orb_lbl.visible = (step_num == 2)
	if _pinwheel_lbl != null:
		_pinwheel_lbl.visible = (step_num == 3)
	if _step4_banner != null:
		_step4_banner.visible = (step_num == 4)
	if _gazebo_lbl != null:
		_gazebo_lbl.visible = (step_num == 5)
	if _arch_lbl != null:
		_arch_lbl.visible = (step_num == 6)

	# Move the glowing vertical Waypoint Light Pillar straight onto the active objective!
	if _beacon_pillar != null:
		if step_num >= 1 and step_num <= 6:
			var target := get_next_target_pos(step_num)
			_beacon_pillar.position = Vector3(target.x, 3.6, target.z)
			_beacon_pillar.visible = true
		else:
			_beacon_pillar.position = Vector3(exit_gate_position.x, 3.6, exit_gate_position.z)
			_beacon_pillar.visible = true


func _build_waypoint_beacon() -> void:
	_beacon_pillar = MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.22
	cyl.bottom_radius = 0.58
	cyl.height = 7.2
	cyl.radial_segments = 12
	_beacon_pillar.mesh = cyl
	var bmat := StandardMaterial3D.new()
	bmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	bmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	bmat.albedo_color = Color(1.0, 0.88, 0.28, 0.26)
	bmat.cull_mode = BaseMaterial3D.CULL_DISABLED
	_beacon_pillar.material_override = bmat
	_beacon_pillar.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_beacon_pillar)


func show_nara_bubble(world_pos: Vector3, text: String, duration: float = 2.2) -> void:
	if _comic_bubble == null:
		_comic_bubble = Label3D.new()
		_comic_bubble.font_size = 44
		_comic_bubble.outline_size = 10
		_comic_bubble.modulate = Color(1.0, 0.98, 0.82)
		_comic_bubble.outline_modulate = Color(0.22, 0.12, 0.05)
		_comic_bubble.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		add_child(_comic_bubble)
	_comic_bubble.text = text
	_comic_bubble.position = world_pos + Vector3(0.0, 2.35, 0.0)
	_comic_bubble.visible = true
	_comic_timer = duration


func update_stop_progress(ratio: float) -> void:
	if _stop_lbl == null:
		return
	if _stop_charge_ring != null:
		_stop_charge_ring.visible = ratio > 0.02 and ratio < 1.0
		_stop_charge_ring.position.y = 0.12 + ratio * 1.55
		var csc := 1.05 - ratio * 0.25
		_stop_charge_ring.scale = Vector3(csc, 1.0, csc)
	if ratio >= 1.0:
		_stop_lbl.text = "1. BERHENTI DULU ✓"
		_stop_lbl.modulate = Color(0.75, 1.0, 0.78)
		if _stop_ring != null:
			_stop_ring.material_override = ToonMat.make(Color(0.22, 0.80, 0.40), "", {"emission_color": Color(0.18, 0.76, 0.36), "emission_energy": 0.45})
		if _stop_sign_face != null:
			_stop_sign_face.material_override = ToonMat.make(Color(0.22, 0.76, 0.38), "", {"outline": false})
		if _stop_sign_root != null:
			var tw := create_tween()
			tw.tween_property(_stop_sign_root, "scale", Vector3(1.18, 0.86, 1.18), 0.12)
			tw.tween_property(_stop_sign_root, "scale", Vector3(0.94, 1.12, 0.94), 0.14)
			tw.tween_property(_stop_sign_root, "scale", Vector3.ONE, 0.14)
	elif ratio > 0.02:
		_stop_lbl.text = "1. BERHENTI DULU\nDiam sebentar... %d%%" % int(ratio * 100.0)
		_stop_lbl.modulate = Color(1.0, 0.96, 0.72)
	else:
		_stop_lbl.text = "1. BERHENTI DULU\nMasuk lingkaran & diam 1,5 detik!"
		_stop_lbl.modulate = Color(1.0, 0.86, 0.84)


func calm_anger_orb(from_player_pos: Vector3 = Vector3.ZERO) -> void:
	if _orb_calmed:
		return
	_orb_calmed = true
	if from_player_pos != Vector3.ZERO and _calm_beam != null:
		_calm_beam_start = from_player_pos + Vector3(0.0, 1.15, 0.0)
		_calm_beam_t = 0.0
		_calm_beam.visible = true
	_orb_wave_t = 0.0
	if _orb_wave != null:
		_orb_wave.visible = true
	if _orb_lbl != null:
		_orb_lbl.text = "2. TAHAN MEMUKUL ✓\n(Berubah jadi Kupu-kupu!)"
		_orb_lbl.modulate = Color(0.75, 1.0, 0.78)
	if _orb_ring != null:
		_orb_ring.material_override = ToonMat.make(Color(0.22, 0.80, 0.40), "", {"emission_color": Color(0.18, 0.76, 0.36), "emission_energy": 0.45})
	# Lively animated transformation: orb turns bright gold, spins & pops into sparkles + 3 butterflies!
	if _orb_mesh != null:
		_orb_mesh.material_override = ToonMat.make(Color(1.0, 0.86, 0.22), "", {"emission_color": Color(1.0, 0.76, 0.14), "emission_energy": 0.9})
		var tw := create_tween().set_parallel(true)
		tw.tween_property(_orb_mesh, "rotation_degrees:y", _orb_mesh.rotation_degrees.y + 540.0, 0.48)
		tw.tween_property(_orb_mesh, "scale", Vector3(1.28, 1.28, 1.28), 0.18)
		tw.chain().tween_property(_orb_mesh, "scale", Vector3(0.01, 0.01, 0.01), 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
		tw.chain().tween_callback(func() -> void:
			if is_instance_valid(_orb_mesh):
				_orb_mesh.visible = false
			if is_instance_valid(_orb_burst):
				_orb_burst.restart()
				_orb_burst.emitting = true
			var bonus := StorybookProps.spawn_butterflies(self, [
				Vector3(-0.7, 1.4, 0.4), Vector3(0.7, 1.6, 0.2), Vector3(0.0, 1.9, 0.5)
			])
			for b in bonus:
				_butterflies.append(b)
		)


func update_pinwheel_charge(ratio: float) -> void:
	if _pinwheel_done:
		return
	_pinwheel_spin_speed = 0.65 + ratio * 6.0
	if _pinwheel_lbl != null:
		if ratio > 0.04:
			_pinwheel_lbl.text = "3. TARIK NAFAS\nTekan [E / Aksi]... %d%%" % int(ratio * 100.0)
			_pinwheel_lbl.modulate = Color(0.80, 0.98, 1.0)
		else:
			_pinwheel_lbl.text = "3. TARIK NAFAS\nTekan [E / Aksi] untuk tiup kincir!"
			_pinwheel_lbl.modulate = Color(1.0, 0.96, 0.76)


func trigger_pinwheel_gust(from_player_pos: Vector3 = Vector3.ZERO) -> void:
	_pinwheel_done = true
	_pinwheel_spin_speed = 16.0
	_wind_start_pos = from_player_pos + Vector3(0.0, 1.35, 0.0)
	_wind_ring_t = 0.0
	if _wind_ring != null:
		_wind_ring.visible = true
	if _pinwheel_petals != null:
		_pinwheel_petals.restart()
		_pinwheel_petals.emitting = true
	if _pinwheel_lbl != null:
		_pinwheel_lbl.text = "3. TARIK NAFAS ✓\n(Angin Segar Menenangkan!)"
		_pinwheel_lbl.modulate = Color(0.75, 1.0, 0.78)
	if _pinwheel_ring != null:
		_pinwheel_ring.material_override = ToonMat.make(Color(0.22, 0.80, 0.40), "", {"emission_color": Color(0.18, 0.76, 0.36), "emission_energy": 0.45})


func get_cat_world_pos() -> Vector3:
	if _cat_node != null:
		return _cat_node.global_position
	return step_positions[5] as Vector3


func get_cat_pet_spot() -> Vector3:
	# Exact cozy cushion spot right in front of the Orange Cat (0.82m away so Nara pets its head cleanly!)
	if _cat_node != null:
		var cat_pos := _cat_node.global_position
		var toward_center := ((step_positions[5] as Vector3) - cat_pos)
		toward_center.y = 0.0
		if toward_center.length_squared() < 0.01:
			toward_center = Vector3(-1.0, 0.0, 0.0)
		var spot := cat_pos + toward_center.normalized() * 0.82
		return Vector3(spot.x, 0.10, spot.z)
	return step_positions[5] as Vector3


func pet_orange_cat(nara_pos: Vector3 = Vector3.ZERO) -> void:
	_cat_happy_t = 3.2
	if _cat_node != null and nara_pos != Vector3.ZERO:
		var look_d := nara_pos - _cat_node.global_position
		look_d.y = 0.0
		if look_d.length_squared() > 0.001:
			_cat_node.global_rotation.y = atan2(look_d.x, look_d.z)
	mark_gazebo_done()


func is_in_river_water(player_pos: Vector3) -> bool:
	if player_pos.z >= -8.05 or player_pos.z <= -21.95:
		return false
	if player_pos.y > 0.32:
		return false
	for k: int in _stone_positions.keys():
		var sp: Vector3 = _stone_positions[k] as Vector3
		var d2 := Vector2(player_pos.x - sp.x, player_pos.z - sp.z).length()
		if d2 <= 0.96:
			return false
	return true


func get_safe_stone_pos(last_stone: int) -> Vector3:
	if last_stone >= 1 and _stone_positions.has(last_stone):
		var sp: Vector3 = _stone_positions[last_stone] as Vector3
		return Vector3(sp.x, 0.35, sp.z)
	return Vector3(0.0, 0.25, -7.1)


func spawn_water_splash(world_pos: Vector3) -> void:
	if _splash_particles != null:
		_splash_particles.global_position = Vector3(world_pos.x, 0.14, world_pos.z)
		_splash_particles.restart()
		_splash_particles.emitting = true
	for rad_off: float in [0.0, 0.35]:
		var rip := MeshInstance3D.new()
		var rtor := TorusMesh.new()
		rtor.inner_radius = 0.45 + rad_off
		rtor.outer_radius = 0.60 + rad_off
		rtor.rings = 18
		rtor.ring_segments = 6
		rip.mesh = rtor
		var rmat := StandardMaterial3D.new()
		rmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		rmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		rmat.albedo_color = Color(0.95, 0.99, 1.0, 0.88)
		rip.material_override = rmat
		rip.position = Vector3(world_pos.x, 0.09, world_pos.z)
		add_child(rip)
		_water_ripples.append({"mesh": rip, "mat": rmat, "t": 0.0})


func mark_stone_hit(num: int) -> void:
	_next_stone = maxi(_next_stone, num + 1)
	_stone_bounce[num] = 1.0
	# Spawn a lively expanding white water ripple ring around the stone on the stream!
	if _stone_positions.has(num):
		var sp: Vector3 = _stone_positions[num] as Vector3
		var rip := MeshInstance3D.new()
		var rtor := TorusMesh.new()
		rtor.inner_radius = 0.72
		rtor.outer_radius = 0.84
		rtor.rings = 18
		rtor.ring_segments = 6
		rip.mesh = rtor
		var rmat := StandardMaterial3D.new()
		rmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		rmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		rmat.albedo_color = Color(0.94, 0.98, 1.0, 0.78)
		rip.material_override = rmat
		rip.position = Vector3(sp.x, 0.08, sp.z)
		add_child(rip)
		_water_ripples.append({"mesh": rip, "mat": rmat, "t": 0.0})
	if _stone_meshes.has(num):
		var m: MeshInstance3D = _stone_meshes[num] as MeshInstance3D
		m.material_override = ToonMat.make(Color(0.26, 0.82, 0.42), "", {"emission_color": Color(0.20, 0.75, 0.36), "emission_energy": 0.38})
	if _stone_labels.has(num):
		var l: Label3D = _stone_labels[num] as Label3D
		l.text = "%d ✓" % num
		l.modulate = Color(0.84, 1.0, 0.84)
	# Highlight next stone gold and move the Waypoint Light Pillar to the next stone!
	if _stone_meshes.has(num + 1):
		var nm: MeshInstance3D = _stone_meshes[num + 1] as MeshInstance3D
		nm.material_override = ToonMat.make(Color(1.0, 0.84, 0.22), "", {"emission_color": Color(0.98, 0.72, 0.12), "emission_energy": 0.35})
		if _beacon_pillar != null and _stone_positions.has(num + 1):
			var np: Vector3 = _stone_positions[num + 1] as Vector3
			_beacon_pillar.position = Vector3(np.x, 3.6, np.z)


func mark_gazebo_done() -> void:
	if _gazebo_lbl != null:
		_gazebo_lbl.text = "5. CARI TEMPAT NYAMAN ✓\n(Bersantai dengan Kucing Oranye!)"
		_gazebo_lbl.modulate = Color(0.75, 1.0, 0.78)
	if _gazebo_ring != null:
		_gazebo_ring.material_override = ToonMat.make(Color(0.22, 0.80, 0.40), "", {"emission_color": Color(0.18, 0.76, 0.36), "emission_energy": 0.45})


func unlock_exit_gate() -> void:
	if _gate_opened:
		return
	_gate_opened = true
	if _arch_lbl != null:
		_arch_lbl.text = "6. MENJAUH DARI SUMBER MARAH ✓\n(Hati Sejuk & Damai!)"
		_arch_lbl.modulate = Color(0.78, 1.0, 0.80)
	if _gate_blocker != null:
		_gate_blocker.collision_layer = 0
	if _confetti != null:
		_confetti.restart()
		_confetti.emitting = true
	if _star_mat != null:
		_star_mat.set_shader_parameter("emission_energy", 1.05)
	StorybookProps.collect_and_hide_star(self, _star_mesh, false)
	if _gate_lbl != null:
		_gate_lbl.text = "NEXT RUTE -> POS 5\nEkspresikan Marah Dengan Sehat!"
		_gate_lbl.modulate = Color(0.84, 1.0, 0.84)
	var tw := create_tween().set_parallel(true)
	tw.tween_property(_gate_left_pivot, "rotation_degrees:y", -105.0, 0.85).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(_gate_right_pivot, "rotation_degrees:y", 105.0, 0.85).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if _portal_area != null:
		for b in _portal_area.get_overlapping_bodies():
			if b is NaraController:
				next_route_entered.emit()
				break


func get_next_target_pos(current_step: int) -> Vector3:
	if current_step <= 3:
		return step_positions[current_step]
	if current_step == 4:
		var sn := clampi(_next_stone, 1, 10)
		if _stone_positions.has(sn):
			return _stone_positions[sn]
		return step_positions[4]
	if current_step == 5:
		return step_positions[5]
	if current_step == 6:
		return step_positions[6]
	return exit_gate_position + Vector3(0.0, 0.0, -0.6)


func update_guide_arrow(player_pos: Vector3, target_pos: Vector3) -> void:
	if _guide_arrow == null:
		return
	var diff := Vector3(target_pos.x - player_pos.x, 0.0, target_pos.z - player_pos.z)
	if diff.length() < 1.35:
		_guide_arrow.visible = false
		return
	_guide_arrow.visible = true
	var dir := diff.normalized()
	_guide_arrow.position = Vector3(player_pos.x + dir.x * 1.35, 0.28 + sin(_time * 4.5) * 0.05, player_pos.z + dir.z * 1.35)
	_guide_arrow.rotation.y = atan2(dir.x, dir.z)


func _build_ground_stream_and_paths() -> void:
	var grass_mat := ToonMat.make(Color(0.36, 0.74, 0.30), "res://assets/textures/grass.webp", {"triplanar": true, "triplanar_scale": 0.22})
	var ground := MeshInstance3D.new()
	var gbox := BoxMesh.new()
	gbox.size = Vector3(76.0, 1.0, 96.0)
	ground.mesh = gbox
	ground.material_override = grass_mat
	ground.position = Vector3(0.0, -0.5, -18.0)
	add_child(ground)
	_add_box_collider(self, Vector3(76.0, 1.0, 96.0), Vector3(0.0, -0.5, -18.0))

	# Cobblestone entrance path (z = +12 to -7.5)
	var road_mat := ToonMat.make(Color(0.42, 0.45, 0.50), "res://assets/textures/cobblestone.webp", {"triplanar": true, "triplanar_scale": 0.42})
	var path1 := MeshInstance3D.new()
	var p1b := BoxMesh.new()
	p1b.size = Vector3(4.2, 0.08, 20.5)
	path1.mesh = p1b
	path1.material_override = road_mat
	path1.position = Vector3(0.0, 0.02, 2.5)
	add_child(path1)

	# Crystal Garden Stream cutting across z = -7.8 to -22.2 (Step 4: 10 Stepping Stones!)
	var water_mat := ToonMat.make(Color(0.24, 0.72, 0.94), "", {"outline": false, "emission_color": Color(0.18, 0.58, 0.86), "emission_energy": 0.22})
	var stream := MeshInstance3D.new()
	var wbox := BoxMesh.new()
	wbox.size = Vector3(17.5, 0.06, 14.6)
	stream.mesh = wbox
	stream.material_override = water_mat
	stream.position = Vector3(0.0, 0.04, -15.0)
	add_child(stream)

	# Stream decorative stone curbs + riverside wooden posts & green reeds
	var curb_mat := ToonMat.make(Color(0.84, 0.78, 0.66), "res://assets/textures/cobblestone.webp", {"triplanar": true, "triplanar_scale": 0.6})
	var post_mat := ToonMat.make(Color(0.54, 0.34, 0.18), "res://assets/textures/wood_planks.webp", {"triplanar": true, "triplanar_scale": 0.5})
	var reed_mat := ToonMat.make(Color(0.20, 0.58, 0.24), "", {"outline_width": 0.7})
	var cattail_mat := ToonMat.make(Color(0.46, 0.26, 0.12), "", {"outline_width": 0.7})
	for cz: float in [-7.7, -22.3]:
		var curb := MeshInstance3D.new()
		var cb := BoxMesh.new()
		cb.size = Vector3(17.6, 0.16, 0.62)
		curb.mesh = cb
		curb.material_override = curb_mat
		curb.position = Vector3(0.0, 0.08, cz)
		add_child(curb)
		# Riverside wooden fence posts on left & right of crossing
		for px: float in [-6.8, -4.4, 4.4, 6.8]:
			var rp := MeshInstance3D.new()
			var rpc := CylinderMesh.new()
			rpc.top_radius = 0.09
			rpc.bottom_radius = 0.11
			rpc.height = 0.92
			rpc.radial_segments = 8
			rp.mesh = rpc
			rp.material_override = post_mat
			rp.position = Vector3(px, 0.46, cz)
			add_child(rp)
			# Decorative green reeds & cattails beside posts
			for r_off: float in [-0.28, 0.28]:
				var reed := MeshInstance3D.new()
				var rc := CylinderMesh.new()
				rc.top_radius = 0.025
				rc.bottom_radius = 0.035
				rc.height = 0.85
				rc.radial_segments = 5
				reed.mesh = rc
				reed.material_override = reed_mat
				reed.position = Vector3(px + r_off, 0.42, cz + (0.28 if cz < -15.0 else -0.28))
				reed.rotation_degrees.z = r_off * 24.0
				add_child(reed)
				var top_ct := MeshInstance3D.new()
				var ctc := CylinderMesh.new()
				ctc.top_radius = 0.045
				ctc.bottom_radius = 0.045
				ctc.height = 0.18
				ctc.radial_segments = 6
				top_ct.mesh = ctc
				top_ct.material_override = cattail_mat
				top_ct.position = Vector3(0.0, 0.32, 0.0)
				reed.add_child(top_ct)

	# Lily pads floating in the stream
	var lily_mat := ToonMat.make(Color(0.20, 0.68, 0.28), "", {"outline_width": 0.8})
	for lp in [Vector3(-4.2, 0.09, -10.5), Vector3(4.5, 0.09, -12.8), Vector3(-4.6, 0.09, -16.5), Vector3(4.2, 0.09, -19.2), Vector3(-3.2, 0.09, -20.5)]:
		var pad := MeshInstance3D.new()
		var pc := CylinderMesh.new()
		pc.top_radius = 0.55
		pc.bottom_radius = 0.55
		pc.height = 0.05
		pc.radial_segments = 10
		pad.mesh = pc
		pad.material_override = lily_mat
		pad.position = lp
		add_child(pad)

	# Sunlit exit meadow path extending all the way to Pos 5 Exit Gate (z = -22.2 to -44.5)
	var path2 := MeshInstance3D.new()
	var p2b := BoxMesh.new()
	p2b.size = Vector3(4.2, 0.08, 22.8)
	path2.mesh = p2b
	path2.material_override = road_mat
	path2.position = Vector3(0.0, 0.02, -33.5)
	add_child(path2)


func _build_horizon_hills_and_flowers() -> void:
	var hill_mat := ToonMat.make(Color(0.28, 0.64, 0.26), "res://assets/textures/grass.webp", {"triplanar": true, "triplanar_scale": 0.14})
	# Keep all back horizon hills well behind Pos 5 Exit Gate (z = -43.5) so they NEVER clip the gate!
	var hills := [
		[Vector3(-22.0, -2.5, -64.0), Vector3(18.0, 7.6, 12.0)],
		[Vector3(0.0, -3.0, -72.0), Vector3(28.0, 9.6, 14.0)],
		[Vector3(22.0, -2.5, -64.0), Vector3(18.0, 7.6, 12.0)],
		[Vector3(-25.0, -2.0, -18.0), Vector3(14.0, 6.2, 30.0)],
		[Vector3(25.0, -2.0, -18.0), Vector3(14.0, 6.2, 30.0)],
	]
	for h in hills:
		var m := MeshInstance3D.new()
		var sp := SphereMesh.new()
		sp.radius = 1.0
		sp.height = 2.0
		sp.radial_segments = 14
		sp.rings = 8
		m.mesh = sp
		m.material_override = hill_mat
		m.position = h[0]
		m.scale = h[1]
		add_child(m)

	var cols := [Color(0.98, 0.42, 0.56), Color(0.98, 0.78, 0.20), Color(0.66, 0.54, 0.98), Color(0.40, 0.80, 0.98)]
	var spots := [
		Vector3(-5.6, 0.0, 6.5), Vector3(5.6, 0.0, 6.2), Vector3(-6.2, 0.0, -1.5), Vector3(5.8, 0.0, -2.0),
		Vector3(-5.5, 0.0, -25.0), Vector3(-4.2, 0.0, -28.0), Vector3(5.5, 0.0, -29.0), Vector3(-4.8, 0.0, -33.2), Vector3(4.8, 0.0, -33.2),
	]
	for i in range(spots.size()):
		StorybookProps.spawn_flower(self, spots[i], cols[i % cols.size()])


func _build_closed_back_gate() -> void:
	var back := Node3D.new()
	back.position = Vector3(0.0, 0.0, 12.6)
	add_child(back)
	var brick_mat := ToonMat.make(Color(0.84, 0.44, 0.34), "res://assets/textures/brick.webp", {"triplanar": true, "triplanar_scale": 0.48})
	var wood_mat := ToonMat.make(Color(0.58, 0.36, 0.20), "res://assets/textures/wood_planks.webp", {"triplanar": true, "triplanar_scale": 0.42})
	for side: float in [-1.0, 1.0]:
		var pil := MeshInstance3D.new()
		var pb := BoxMesh.new()
		pb.size = Vector3(0.85, 3.4, 0.85)
		pil.mesh = pb
		pil.material_override = brick_mat
		pil.position = Vector3(side * 2.9, 1.7, 0.0)
		back.add_child(pil)
	var beam := MeshInstance3D.new()
	var bb := BoxMesh.new()
	bb.size = Vector3(6.6, 0.5, 0.6)
	beam.mesh = bb
	beam.material_override = wood_mat
	beam.position = Vector3(0.0, 3.45, 0.0)
	back.add_child(beam)
	var door := MeshInstance3D.new()
	var db := BoxMesh.new()
	db.size = Vector3(4.95, 3.20, 0.22)
	door.mesh = db
	door.material_override = wood_mat
	door.position = Vector3(0.0, 1.60, 0.0)
	back.add_child(door)
	var lbl := Label3D.new()
	lbl.text = "POS 3 SELESAI\n(Ikuti 6 Langkah Tenang!)"
	lbl.font_size = 38
	lbl.outline_size = 8
	lbl.modulate = Color(1.0, 0.96, 0.82)
	lbl.position = Vector3(0.0, 3.45, -0.35)
	lbl.rotation_degrees.y = 180.0
	back.add_child(lbl)
	_add_box_collider(back, Vector3(18.0, 3.6, 0.7), Vector3(0.0, 1.8, 0.0))


func _build_brick_fences() -> void:
	var brick_mat := ToonMat.make(Color(0.84, 0.44, 0.34), "res://assets/textures/brick.webp", {"triplanar": true, "triplanar_scale": 0.48})
	var cap_mat := ToonMat.make(Color(0.92, 0.86, 0.74), "", {"outline_width": 1.1})
	for side: float in [-1.0, 1.0]:
		var x: float = side * 8.8
		var wall := MeshInstance3D.new()
		var wb := BoxMesh.new()
		wb.size = Vector3(0.55, 1.05, 58.0)
		wall.mesh = wb
		wall.material_override = brick_mat
		wall.position = Vector3(x, 0.52, -16.0)
		add_child(wall)
		var cap := MeshInstance3D.new()
		var cb := BoxMesh.new()
		cb.size = Vector3(0.68, 0.14, 58.2)
		cap.mesh = cb
		cap.material_override = cap_mat
		cap.position = Vector3(x, 1.1, -16.0)
		add_child(cap)
		_add_box_collider(self, Vector3(0.7, 6.0, 58.6), Vector3(x, 3.0, -16.0))

	# Visual brick flanking walls sealing both gates + 360-deg horizon backdrop
	StorybookProps.build_flanking_brick_walls(self, 12.6, 2.9, 8.8, 1.05)
	StorybookProps.build_flanking_brick_walls(self, -43.5, 2.8, 8.8, 1.05)
	StorybookProps.spawn_horizon_backdrop_360(self, -46.0, 13.5, 9.5)

	# Tall invisible back & front flanking walls so Nara can NEVER escape Pos 4!
	_add_box_collider(self, Vector3(18.5, 6.0, 0.6), Vector3(0.0, 3.0, 12.8))
	_add_box_collider(self, Vector3(6.3, 6.0, 0.6), Vector3(-5.9, 3.0, -43.5))
	_add_box_collider(self, Vector3(6.3, 6.0, 0.6), Vector3(5.9, 3.0, -43.5))
	_add_box_collider(self, Vector3(6.5, 6.0, 0.6), Vector3(0.0, 3.0, -46.2))


func _build_broken_blocks_trigger() -> void:
	# Hand-crafted storybook wooden toy blocks + tipped toy wagon on play mat ("Sumber Marah")
	var root := Node3D.new()
	root.position = Vector3(-3.8, 0.0, 7.5)
	add_child(root)

	# Play mat rug on the grass
	var mat_m := MeshInstance3D.new()
	var mb := BoxMesh.new()
	mb.size = Vector3(2.35, 0.05, 1.95)
	mat_m.mesh = mb
	mat_m.material_override = ToonMat.make(Color(0.96, 0.90, 0.74), "", {"outline_width": 0.9})
	mat_m.position = Vector3(0.0, 0.025, 0.0)
	root.add_child(mat_m)

	# Textured wooden alphabet toy blocks
	var bcols := [Color(0.94, 0.36, 0.34), Color(0.98, 0.80, 0.28), Color(0.36, 0.70, 0.96), Color(0.38, 0.80, 0.48)]
	var letters := ["A", "B", "C", "D", "E"]
	var blocks := [
		[Vector3(-0.35, 0.24, 0.15), Vector3(8, 22, 16)],
		[Vector3(0.32, 0.24, 0.42), Vector3(14, -18, 6)],
		[Vector3(-0.68, 0.24, -0.35), Vector3(-6, 42, 12)],
		[Vector3(0.18, 0.24, -0.42), Vector3(10, 12, -8)],
		[Vector3(-0.18, 0.62, -0.08), Vector3(18, 35, 22)],
	]
	for i in range(blocks.size()):
		var b := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(0.40, 0.40, 0.40)
		b.mesh = bm
		b.material_override = ToonMat.make(bcols[i % bcols.size()], "res://assets/textures/wood_planks.webp", {"triplanar": true, "triplanar_scale": 1.6})
		b.position = blocks[i][0]
		b.rotation_degrees = blocks[i][1]
		root.add_child(b)
		var ch := Label3D.new()
		ch.text = letters[i]
		ch.font_size = 38
		ch.outline_size = 6
		ch.modulate = Color(1.0, 0.98, 0.90)
		ch.position = Vector3(0.0, 0.0, 0.215)
		b.add_child(ch)

	# Tipped miniature wooden toy wagon beside the blocks
	var wagon := Node3D.new()
	wagon.position = Vector3(0.68, 0.24, -0.05)
	wagon.rotation_degrees = Vector3(0.0, 28.0, 42.0)
	root.add_child(wagon)
	var wbody := MeshInstance3D.new()
	var wb := BoxMesh.new()
	wb.size = Vector3(0.68, 0.26, 0.46)
	wbody.mesh = wb
	wbody.material_override = ToonMat.make(Color(0.84, 0.26, 0.22), "res://assets/textures/wood_planks.webp", {"triplanar": true, "triplanar_scale": 1.2})
	wagon.add_child(wbody)
	var wheel_mat := ToonMat.make(Color(0.28, 0.22, 0.18), "", {"outline_width": 0.9})
	for wx: float in [-0.22, 0.22]:
		for wz: float in [-0.25, 0.25]:
			var wh := MeshInstance3D.new()
			var wc := CylinderMesh.new()
			wc.top_radius = 0.12
			wc.bottom_radius = 0.12
			wc.height = 0.08
			wc.radial_segments = 10
			wh.mesh = wc
			wh.material_override = wheel_mat
			wh.position = Vector3(wx, -0.12, wz)
			wh.rotation_degrees.x = 90.0
			wagon.add_child(wh)

	var lbl := Label3D.new()
	lbl.text = "Balok Mainan Roboh"
	lbl.font_size = 28
	lbl.outline_size = 6
	lbl.modulate = Color(1.0, 0.90, 0.84)
	lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	lbl.position = Vector3(0.0, 1.35, 0.0)
	root.add_child(lbl)


func _build_step1_stop_zone() -> void:
	var root := Node3D.new()
	root.position = step_positions[1]
	add_child(root)

	# Flat embedded cobblestone medallion flush on the road (no floating plastic hoop!)
	var disc := MeshInstance3D.new()
	var dc := CylinderMesh.new()
	dc.top_radius = 1.32
	dc.bottom_radius = 1.38
	dc.height = 0.05
	dc.radial_segments = 24
	disc.mesh = dc
	disc.material_override = ToonMat.make(Color(0.96, 0.88, 0.78), "", {"outline": false})
	disc.position = Vector3(0.0, 0.065, 0.0)
	root.add_child(disc)

	_stop_ring = MeshInstance3D.new()
	var tor := TorusMesh.new()
	tor.inner_radius = 1.24
	tor.outer_radius = 1.38
	tor.rings = 24
	tor.ring_segments = 8
	_stop_ring.mesh = tor
	_stop_ring.material_override = ToonMat.make(Color(0.92, 0.24, 0.22), "", {"emission_color": Color(0.90, 0.20, 0.18), "emission_energy": 0.42})
	_stop_ring.scale = Vector3(1.0, 0.45, 1.0)
	_stop_ring.position = Vector3(0.0, 0.09, 0.0)
	root.add_child(_stop_ring)

	# Rising glowing green calm charge ring while Nara stands still!
	_stop_charge_ring = MeshInstance3D.new()
	var ctor := TorusMesh.new()
	ctor.inner_radius = 1.02
	ctor.outer_radius = 1.14
	ctor.rings = 20
	ctor.ring_segments = 6
	_stop_charge_ring.mesh = ctor
	_stop_charge_ring.material_override = ToonMat.make(Color(0.24, 0.88, 0.46), "", {"emission_color": Color(0.20, 0.85, 0.42), "emission_energy": 0.85})
	_stop_charge_ring.visible = false
	root.add_child(_stop_charge_ring)

	# Proper Storybook 3D STOP Sign with stone base, white outer octagon, red inner octagon & crisp text!
	_stop_sign_root = Node3D.new()
	_stop_sign_root.position = Vector3(1.95, 0.0, 0.0)
	root.add_child(_stop_sign_root)
	var sign_root := _stop_sign_root

	var base := MeshInstance3D.new()
	var bc := CylinderMesh.new()
	bc.top_radius = 0.26
	bc.bottom_radius = 0.34
	bc.height = 0.34
	bc.radial_segments = 8
	base.mesh = bc
	base.material_override = ToonMat.make(Color(0.76, 0.72, 0.64), "res://assets/textures/cobblestone.webp", {"triplanar": true, "triplanar_scale": 0.8})
	base.position = Vector3(0.0, 0.17, 0.0)
	sign_root.add_child(base)

	var post := MeshInstance3D.new()
	var pc := CylinderMesh.new()
	pc.top_radius = 0.085
	pc.bottom_radius = 0.105
	pc.height = 1.65
	pc.radial_segments = 8
	post.mesh = pc
	post.material_override = ToonMat.make(Color(0.56, 0.34, 0.18), "res://assets/textures/wood_planks.webp", {"triplanar": true, "triplanar_scale": 0.6})
	# Place post neatly BEHIND the octagon sign (z = -0.11) so it NEVER pokes through the front!
	post.position = Vector3(0.0, 0.92, -0.11)
	sign_root.add_child(post)

	# Flat XY-aligned octagon basis (spin cylinder 22.5° around its own Y axis first, then tilt 90° around X so it is 100% parallel to Label3D!)
	var oct_basis := Basis(Vector3.RIGHT, deg_to_rad(90.0)) * Basis(Vector3.UP, deg_to_rad(22.5))

	# White outer octagon border
	var outer_oct := MeshInstance3D.new()
	var oc := CylinderMesh.new()
	oc.top_radius = 0.78
	oc.bottom_radius = 0.78
	oc.height = 0.10
	oc.radial_segments = 8
	outer_oct.mesh = oc
	outer_oct.material_override = ToonMat.make(Color(0.98, 0.98, 0.96), "", {"outline_width": 1.2})
	outer_oct.position = Vector3(0.0, 2.25, 0.0)
	outer_oct.basis = oct_basis
	sign_root.add_child(outer_oct)

	# Red inner octagon face
	_stop_sign_face = MeshInstance3D.new()
	var sc := CylinderMesh.new()
	sc.top_radius = 0.67
	sc.bottom_radius = 0.67
	sc.height = 0.12
	sc.radial_segments = 8
	_stop_sign_face.mesh = sc
	_stop_sign_face.material_override = ToonMat.make(Color(0.88, 0.18, 0.20), "", {"outline": false})
	_stop_sign_face.position = Vector3(0.0, 2.25, 0.015)
	_stop_sign_face.basis = oct_basis
	sign_root.add_child(_stop_sign_face)

	# Crisp centered STOP text using Fredoka with generous width so all 4 letters (S-T-O-P) render cleanly on Web & Desktop!
	var stxt := Label3D.new()
	var stop_font: Font = load("res://assets/fonts/fredoka/Fredoka-Variable.ttf")
	if stop_font != null:
		stxt.font = stop_font
	stxt.text = "STOP"
	stxt.font_size = 66
	stxt.pixel_size = 0.0052
	stxt.width = 1000.0
	stxt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stxt.outline_size = 9
	stxt.render_priority = 3
	stxt.modulate = Color.WHITE
	stxt.outline_modulate = Color(0.32, 0.06, 0.06)
	stxt.position = Vector3(0.0, 2.25, 0.16)
	sign_root.add_child(stxt)

	_stop_lbl = Label3D.new()
	_stop_lbl.text = "1. BERHENTI DULU\nMasuk lingkaran & diam 1,5 detik!"
	_stop_lbl.font_size = 36
	_stop_lbl.outline_size = 7
	_stop_lbl.modulate = Color(1.0, 0.94, 0.84)
	_stop_lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_stop_lbl.position = Vector3(0.0, 3.35, 0.0)
	root.add_child(_stop_lbl)

	_add_zone_area(root, "step1", 1.55)


func _build_step2_anger_orb() -> void:
	_orb_root = Node3D.new()
	_orb_root.position = step_positions[2]
	add_child(_orb_root)

	# Embedded outer safe calm mosaic ring
	_orb_ring = MeshInstance3D.new()
	var tor := TorusMesh.new()
	tor.inner_radius = 2.08
	tor.outer_radius = 2.22
	tor.rings = 24
	tor.ring_segments = 8
	_orb_ring.mesh = tor
	_orb_ring.material_override = ToonMat.make(Color(0.98, 0.62, 0.16), "", {"emission_color": Color(0.96, 0.54, 0.10), "emission_energy": 0.42})
	_orb_ring.scale = Vector3(1.0, 0.42, 1.0)
	_orb_ring.position = Vector3(0.0, 0.09, 0.0)
	_orb_root.add_child(_orb_ring)

	# Expressive 3D "Bola Kesal" Character Prop (with angry eyes, brows, frown & spiky collar!)
	_orb_mesh = MeshInstance3D.new()
	var sp := SphereMesh.new()
	sp.radius = 0.54
	sp.height = 1.08
	sp.radial_segments = 14
	sp.rings = 10
	_orb_mesh.mesh = sp
	_orb_mesh.material_override = ToonMat.make(Color(0.92, 0.22, 0.22), "", {"emission_color": Color(0.96, 0.30, 0.14), "emission_energy": 0.45})
	_orb_mesh.position = Vector3(0.0, 1.12, 0.0)
	_orb_root.add_child(_orb_mesh)

	var white_mat := ToonMat.make(Color.WHITE, "", {"outline": false})
	var dark_mat := ToonMat.make(Color(0.14, 0.08, 0.08), "", {"outline": false})
	var gold_mat := ToonMat.make(Color(1.0, 0.80, 0.16), "", {"outline_width": 0.9})
	for sx: float in [-1.0, 1.0]:
		var eye_w := MeshInstance3D.new()
		var ewsp := SphereMesh.new()
		ewsp.radius = 0.11
		ewsp.height = 0.22
		ewsp.radial_segments = 8
		ewsp.rings = 6
		eye_w.mesh = ewsp
		eye_w.material_override = white_mat
		eye_w.position = Vector3(sx * 0.18, 0.06, 0.46)
		_orb_mesh.add_child(eye_w)

		var pup := MeshInstance3D.new()
		var psp := SphereMesh.new()
		psp.radius = 0.055
		psp.height = 0.11
		psp.radial_segments = 6
		psp.rings = 4
		pup.mesh = psp
		pup.material_override = dark_mat
		pup.position = Vector3(sx * 0.18, 0.05, 0.54)
		_orb_mesh.add_child(pup)

		var brow := MeshInstance3D.new()
		var bbx := BoxMesh.new()
		bbx.size = Vector3(0.24, 0.065, 0.06)
		brow.mesh = bbx
		brow.material_override = dark_mat
		brow.position = Vector3(sx * 0.18, 0.20, 0.50)
		brow.rotation_degrees.z = sx * 24.0
		_orb_mesh.add_child(brow)

	# Angry frown mouth
	var mouth := MeshInstance3D.new()
	var mbx := BoxMesh.new()
	mbx.size = Vector3(0.26, 0.07, 0.06)
	mouth.mesh = mbx
	mouth.material_override = dark_mat
	mouth.position = Vector3(0.0, -0.18, 0.50)
	_orb_mesh.add_child(mouth)

	# Warning halo ring around the anger orb
	var halo := MeshInstance3D.new()
	var htor := TorusMesh.new()
	htor.inner_radius = 0.64
	htor.outer_radius = 0.72
	htor.rings = 16
	htor.ring_segments = 6
	halo.mesh = htor
	halo.material_override = gold_mat
	halo.rotation_degrees.x = 18.0
	_orb_mesh.add_child(halo)

	_orb_lbl = Label3D.new()
	_orb_lbl.text = "2. TAHAN UNTUK MEMUKUL\nJangan ditabrak! Tekan [E / Aksi] dari luar"
	_orb_lbl.font_size = 36
	_orb_lbl.outline_size = 7
	_orb_lbl.modulate = Color(1.0, 0.94, 0.78)
	_orb_lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_orb_lbl.position = Vector3(0.0, 2.75, 0.0)
	_orb_root.add_child(_orb_lbl)

	# Expanding golden calm shockwave + colorful sparkle burst when orb transforms!
	_orb_wave = MeshInstance3D.new()
	var owtor := TorusMesh.new()
	owtor.inner_radius = 0.72
	owtor.outer_radius = 0.88
	owtor.rings = 20
	owtor.ring_segments = 6
	_orb_wave.mesh = owtor
	_orb_wave_mat = StandardMaterial3D.new()
	_orb_wave_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_orb_wave_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_orb_wave_mat.albedo_color = Color(1.0, 0.88, 0.30, 0.85)
	_orb_wave.material_override = _orb_wave_mat
	_orb_wave.position = Vector3(0.0, 1.15, 0.0)
	_orb_wave.visible = false
	_orb_root.add_child(_orb_wave)

	_orb_burst = GPUParticles3D.new()
	_orb_burst.position = Vector3(0.0, 1.25, 0.0)
	_orb_burst.amount = 32
	_orb_burst.lifetime = 1.2
	_orb_burst.one_shot = true
	_orb_burst.explosiveness = 0.92
	_orb_burst.emitting = false
	var obpm := ParticleProcessMaterial.new()
	obpm.direction = Vector3(0.0, 0.6, 0.0)
	obpm.spread = 180.0
	obpm.initial_velocity_min = 2.4
	obpm.initial_velocity_max = 5.2
	obpm.gravity = Vector3(0.0, -2.6, 0.0)
	obpm.scale_min = 0.10
	obpm.scale_max = 0.20
	obpm.color = Color(1.0, 0.88, 0.28)
	_orb_burst.process_material = obpm
	var obbox := BoxMesh.new()
	obbox.size = Vector3(0.55, 0.55, 0.55)
	var obmat := StandardMaterial3D.new()
	obmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	obmat.albedo_color = Color(1.0, 0.92, 0.38)
	obbox.material = obmat
	_orb_burst.draw_pass_1 = obbox
	_orb_root.add_child(_orb_burst)

	# Glowing Golden Calm Orb/Beam shooting from Nara into the Red Orb!
	_calm_beam = MeshInstance3D.new()
	var cbsp := SphereMesh.new()
	cbsp.radius = 0.24
	cbsp.height = 0.48
	cbsp.radial_segments = 10
	cbsp.rings = 6
	_calm_beam.mesh = cbsp
	_calm_beam.material_override = ToonMat.make(Color(1.0, 0.90, 0.28), "", {"emission_color": Color(1.0, 0.82, 0.16), "emission_energy": 1.1})
	_calm_beam.visible = false
	add_child(_calm_beam)

	# Safe interaction area (radius 3.0)
	_add_zone_area(_orb_root, "step2", 3.0)

	# Inner bump area (radius 0.85) if player recklessly runs into the anger orb
	var bump_area := Area3D.new()
	bump_area.collision_layer = 4
	bump_area.collision_mask = 2
	var bcol := CollisionShape3D.new()
	var bsh := CylinderShape3D.new()
	bsh.radius = 0.85
	bsh.height = 2.0
	bcol.shape = bsh
	bcol.position = Vector3(0.0, 1.0, 0.0)
	bump_area.add_child(bcol)
	_orb_root.add_child(bump_area)
	bump_area.body_entered.connect(func(b: Node3D) -> void:
		if b is NaraController and not _orb_calmed:
			orb_bumped.emit()
	)


func _build_step3_pinwheel() -> void:
	# Storybook Dutch Garden Windmill with stone base, timber tower, red cap & framed lattice sails!
	var root := Node3D.new()
	root.position = step_positions[3]
	add_child(root)

	var stone_mat := ToonMat.make(Color(0.82, 0.78, 0.70), "res://assets/textures/cobblestone.webp", {"triplanar": true, "triplanar_scale": 0.6})
	var wood_mat := ToonMat.make(Color(0.56, 0.34, 0.18), "res://assets/textures/wood_planks.webp", {"triplanar": true, "triplanar_scale": 0.45})
	var cream_mat := ToonMat.make(Color(0.98, 0.94, 0.84), "", {"outline_width": 1.1})
	var red_mat := ToonMat.make(Color(0.84, 0.24, 0.22), "", {"outline_width": 1.1})

	var base := MeshInstance3D.new()
	var bc := CylinderMesh.new()
	bc.top_radius = 0.68
	bc.bottom_radius = 0.82
	bc.height = 0.55
	bc.radial_segments = 12
	base.mesh = bc
	base.material_override = stone_mat
	base.position = Vector3(0.0, 0.275, 0.0)
	root.add_child(base)

	var tower := MeshInstance3D.new()
	var tc := CylinderMesh.new()
	tc.top_radius = 0.42
	tc.bottom_radius = 0.62
	tc.height = 2.55
	tc.radial_segments = 10
	tower.mesh = tc
	tower.material_override = cream_mat
	tower.position = Vector3(0.0, 1.80, 0.0)
	root.add_child(tower)
	_add_box_collider(root, Vector3(1.2, 3.2, 1.2), Vector3(0.0, 1.6, 0.0))

	# Wooden decorative bands & mini door on windmill
	var door := MeshInstance3D.new()
	var db := BoxMesh.new()
	db.size = Vector3(0.38, 0.68, 0.14)
	door.mesh = db
	door.material_override = wood_mat
	door.position = Vector3(0.0, 0.90, 0.54)
	root.add_child(door)

	# Conical red windmill cap
	var cap := MeshInstance3D.new()
	var cc := CylinderMesh.new()
	cc.top_radius = 0.06
	cc.bottom_radius = 0.54
	cc.height = 0.72
	cc.radial_segments = 10
	cap.mesh = cc
	cap.material_override = red_mat
	cap.position = Vector3(0.0, 3.40, 0.0)
	root.add_child(cap)

	_pinwheel_blades = Node3D.new()
	_pinwheel_blades.position = Vector3(0.0, 2.88, 0.52)
	root.add_child(_pinwheel_blades)

	var hub := MeshInstance3D.new()
	var hsp := SphereMesh.new()
	hsp.radius = 0.22
	hsp.height = 0.44
	hsp.radial_segments = 10
	hsp.rings = 6
	hub.mesh = hsp
	hub.material_override = ToonMat.make(Color(1.0, 0.82, 0.18), "", {"outline_width": 1.1})
	_pinwheel_blades.add_child(hub)

	var blade_cols := [Color(0.98, 0.42, 0.50), Color(0.28, 0.76, 0.98), Color(0.98, 0.80, 0.22), Color(0.34, 0.80, 0.44)]
	for i in range(4):
		var arm := Node3D.new()
		arm.rotation_degrees.z = float(i) * 90.0
		# Wooden spar stick
		var spar := MeshInstance3D.new()
		var sb := BoxMesh.new()
		sb.size = Vector3(0.10, 1.48, 0.08)
		spar.mesh = sb
		spar.material_override = wood_mat
		spar.position = Vector3(0.0, 0.74, 0.0)
		arm.add_child(spar)
		# Colorful sail cloth panel attached to spar
		var sail := MeshInstance3D.new()
		var bb := BoxMesh.new()
		bb.size = Vector3(0.42, 1.12, 0.05)
		sail.mesh = bb
		sail.material_override = ToonMat.make(blade_cols[i], "", {"outline_width": 1.0})
		sail.position = Vector3(0.22, 0.82, 0.02)
		sail.rotation_degrees.y = 14.0
		arm.add_child(sail)
		_pinwheel_blades.add_child(arm)

	_pinwheel_petals = GPUParticles3D.new()
	_pinwheel_petals.position = Vector3(0.0, 2.88, 0.65)
	_pinwheel_petals.amount = 34
	_pinwheel_petals.lifetime = 1.6
	_pinwheel_petals.one_shot = true
	_pinwheel_petals.explosiveness = 0.82
	_pinwheel_petals.emitting = false
	var pm := ParticleProcessMaterial.new()
	pm.direction = Vector3(0.5, 0.4, 0.4)
	pm.spread = 95.0
	pm.initial_velocity_min = 2.6
	pm.initial_velocity_max = 5.2
	pm.gravity = Vector3(0.0, -1.6, 0.0)
	pm.scale_min = 0.10
	pm.scale_max = 0.18
	pm.color = Color(0.98, 0.78, 0.90)
	_pinwheel_petals.process_material = pm
	var pbox := BoxMesh.new()
	pbox.size = Vector3(0.5, 0.5, 0.12)
	var pmat := StandardMaterial3D.new()
	pmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	pmat.albedo_color = Color(1.0, 0.78, 0.88)
	pbox.material = pmat
	_pinwheel_petals.draw_pass_1 = pbox
	root.add_child(_pinwheel_petals)

	_pinwheel_ring = MeshInstance3D.new()
	var tor := TorusMesh.new()
	tor.inner_radius = 1.48
	tor.outer_radius = 1.62
	tor.rings = 20
	tor.ring_segments = 8
	_pinwheel_ring.mesh = tor
	_pinwheel_ring.material_override = ToonMat.make(Color(0.24, 0.76, 0.98), "", {"emission_color": Color(0.18, 0.68, 0.94), "emission_energy": 0.42})
	_pinwheel_ring.scale = Vector3(1.0, 0.42, 1.0)
	_pinwheel_ring.position = Vector3(0.55, 0.09, 0.95)
	root.add_child(_pinwheel_ring)

	_pinwheel_lbl = Label3D.new()
	_pinwheel_lbl.text = "3. TARIK NAFAS\nTekan [E / Aksi] untuk tiup kincir!"
	_pinwheel_lbl.font_size = 36
	_pinwheel_lbl.outline_size = 7
	_pinwheel_lbl.modulate = Color(1.0, 0.96, 0.76)
	_pinwheel_lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_pinwheel_lbl.position = Vector3(0.0, 4.75, 0.0)
	root.add_child(_pinwheel_lbl)

	# Visible 3D Wind Gust Ring shooting from Nara into the Windmill sails!
	_wind_ring = MeshInstance3D.new()
	var wrtor := TorusMesh.new()
	wrtor.inner_radius = 0.42
	wrtor.outer_radius = 0.54
	wrtor.rings = 18
	wrtor.ring_segments = 6
	_wind_ring.mesh = wrtor
	_wind_ring_mat = StandardMaterial3D.new()
	_wind_ring_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_wind_ring_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_wind_ring_mat.albedo_color = Color(0.62, 0.94, 1.0, 0.85)
	_wind_ring.material_override = _wind_ring_mat
	_wind_ring.rotation_degrees.x = 90.0
	_wind_ring.visible = false
	add_child(_wind_ring)

	_add_zone_area(root, "step3", 2.75)


func _build_step4_stepping_stones() -> void:
	# 10 numbered stepping stones across the crystal garden stream (z = -8.8 to -21.2)
	_step4_banner = Label3D.new()
	_step4_banner.text = "4. HITUNG SAMPAI 10\nInjak Batu 1 -> 10 Menyeberangi Sungai!"
	_step4_banner.font_size = 42
	_step4_banner.outline_size = 8
	_step4_banner.modulate = Color(1.0, 0.96, 0.76)
	_step4_banner.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_step4_banner.position = Vector3(0.0, 2.85, -8.4)
	add_child(_step4_banner)

	# Reusable 3D Water Splash fountain particle emitter when Nara falls into the river!
	_splash_particles = GPUParticles3D.new()
	_splash_particles.amount = 38
	_splash_particles.lifetime = 0.95
	_splash_particles.one_shot = true
	_splash_particles.explosiveness = 0.92
	_splash_particles.emitting = false
	var spm := ParticleProcessMaterial.new()
	spm.direction = Vector3(0.0, 1.0, 0.0)
	spm.spread = 48.0
	spm.initial_velocity_min = 3.2
	spm.initial_velocity_max = 6.2
	spm.gravity = Vector3(0.0, -9.8, 0.0)
	spm.scale_min = 0.10
	spm.scale_max = 0.22
	spm.color = Color(0.86, 0.96, 1.0)
	_splash_particles.process_material = spm
	var sdrop := SphereMesh.new()
	sdrop.radius = 0.42
	sdrop.height = 0.84
	sdrop.radial_segments = 6
	sdrop.rings = 4
	var sdmat := StandardMaterial3D.new()
	sdmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	sdmat.albedo_color = Color(0.88, 0.97, 1.0)
	sdrop.material = sdmat
	_splash_particles.draw_pass_1 = sdrop
	add_child(_splash_particles)

	for i in range(1, 11):
		var z_pos := -8.8 - float(i - 1) * 1.38
		var x_pos := sin(float(i - 1) * 0.85) * 1.35
		var pos := Vector3(x_pos, 0.0, z_pos)
		_stone_positions[i] = pos

		var s_root := Node3D.new()
		s_root.position = pos
		add_child(s_root)

		var stone := MeshInstance3D.new()
		var sc := CylinderMesh.new()
		sc.top_radius = 0.84
		sc.bottom_radius = 0.92
		sc.height = 0.28
		sc.radial_segments = 14
		stone.mesh = sc
		var is_first := (i == 1)
		stone.material_override = ToonMat.make(
			Color(1.0, 0.84, 0.22) if is_first else Color(0.86, 0.82, 0.74),
			"",
			{"emission_color": Color(0.98, 0.72, 0.12), "emission_energy": 0.35 if is_first else 0.0}
		)
		stone.position = Vector3(0.0, 0.14, 0.0)
		s_root.add_child(stone)
		_stone_meshes[i] = stone

		# Solid cylinder collider so Nara actually stands slightly elevated above the blue water!
		var sb := StaticBody3D.new()
		sb.collision_layer = 1
		sb.collision_mask = 0
		var scol := CollisionShape3D.new()
		var ssh := CylinderShape3D.new()
		ssh.radius = 0.84
		ssh.height = 0.28
		scol.shape = ssh
		sb.position = Vector3(0.0, 0.14, 0.0)
		sb.add_child(scol)
		s_root.add_child(sb)

		var lbl := Label3D.new()
		lbl.text = str(i)
		lbl.font_size = 60
		lbl.outline_size = 10
		lbl.modulate = Color(1.0, 0.96, 0.76)
		lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		lbl.position = Vector3(0.0, 0.95, 0.0)
		s_root.add_child(lbl)
		_stone_labels[i] = lbl

		var area := Area3D.new()
		area.collision_layer = 4
		area.collision_mask = 2
		var col := CollisionShape3D.new()
		var sh := CylinderShape3D.new()
		sh.radius = 0.92
		sh.height = 1.8
		col.shape = sh
		col.position = Vector3(0.0, 0.9, 0.0)
		area.add_child(col)
		s_root.add_child(area)

		var num := i
		area.body_entered.connect(func(b: Node3D) -> void:
			if b is NaraController:
				stone_stepped.emit(num)
		)


func _build_step5_cozy_gazebo_and_cat() -> void:
	var root := Node3D.new()
	root.position = step_positions[5]
	root.rotation_degrees.y = -22.0
	add_child(root)

	var wood_mat := ToonMat.make(Color(0.56, 0.34, 0.18), "res://assets/textures/wood_planks.webp", {"triplanar": true, "triplanar_scale": 0.45})
	var roof_mat := ToonMat.make(Color(0.82, 0.30, 0.24), "", {"outline_width": 1.2})
	var floor_mat := ToonMat.make(Color(0.76, 0.56, 0.34), "res://assets/textures/wood_planks.webp", {"triplanar": true, "triplanar_scale": 0.5})

	# Gazebo wooden deck flush with ground (so Nara walks smoothly without needing to jump!)
	var deck := MeshInstance3D.new()
	var db := BoxMesh.new()
	db.size = Vector3(3.8, 0.08, 3.4)
	deck.mesh = db
	deck.material_override = floor_mat
	deck.position = Vector3(0.0, 0.04, 0.0)
	root.add_child(deck)
	_add_box_collider(root, Vector3(3.8, 0.08, 3.4), Vector3(0.0, 0.04, 0.0))

	# Gentle wooden ramp at gazebo entrance towards path (seamless walk-in, 0% obstruction)
	var ramp := MeshInstance3D.new()
	var r_mesh := BoxMesh.new()
	r_mesh.size = Vector3(1.6, 0.05, 0.7)
	ramp.mesh = r_mesh
	ramp.material_override = floor_mat
	ramp.position = Vector3(-1.8, 0.025, 0.0)
	ramp.rotation_degrees.z = -3.5
	root.add_child(ramp)

	# 4 corner posts (with colliders so Nara never phases through them!)
	for sx: float in [-1.6, 1.6]:
		for sz: float in [-1.4, 1.4]:
			var p := MeshInstance3D.new()
			var pc := CylinderMesh.new()
			pc.top_radius = 0.13
			pc.bottom_radius = 0.15
			pc.height = 3.1
			pc.radial_segments = 8
			p.mesh = pc
			p.material_override = wood_mat
			p.position = Vector3(sx, 1.65, sz)
			root.add_child(p)
			_add_box_collider(root, Vector3(0.32, 3.1, 0.32), Vector3(sx, 1.65, sz))

	# Cozy pitched roof + wooden railings ONLY on back & far-right (road-facing left & front stay WIDE OPEN!)
	var roof := MeshInstance3D.new()
	var rc := CylinderMesh.new()
	rc.top_radius = 0.15
	rc.bottom_radius = 2.95
	rc.height = 1.25
	rc.radial_segments = 4
	roof.mesh = rc
	roof.material_override = roof_mat
	roof.position = Vector3(0.0, 3.75, 0.0)
	roof.rotation_degrees.y = 45.0
	root.add_child(roof)

	# Back & far-right wooden railings WITH solid colliders (never pass-through!)
	for r_def in [
		[Vector3(0.0, 0.72, -1.42), Vector3(3.2, 0.12, 0.12)],
		[Vector3(1.62, 0.72, 0.0), Vector3(0.12, 0.12, 2.8)],
	]:
		var rail := MeshInstance3D.new()
		var rbx := BoxMesh.new()
		rbx.size = r_def[1]
		rail.mesh = rbx
		rail.material_override = wood_mat
		rail.position = r_def[0]
		root.add_child(rail)
		_add_box_collider(root, (r_def[1] as Vector3) + Vector3(0.08, 1.1, 0.08), (r_def[0] as Vector3) + Vector3(0.0, 0.3, 0.0))

	# 2 warm glowing hanging lanterns on front corners
	var glow_mat := ToonMat.make(Color(1.0, 0.92, 0.62), "", {"emission_color": Color(1.0, 0.80, 0.28), "emission_energy": 0.9})
	for lx: float in [-1.45, 1.45]:
		var lamp := MeshInstance3D.new()
		var lb := BoxMesh.new()
		lb.size = Vector3(0.24, 0.30, 0.24)
		lamp.mesh = lb
		lamp.material_override = glow_mat
		lamp.position = Vector3(lx, 2.75, 1.35)
		root.add_child(lamp)

	# Mini wooden stool + open storybook on the left side
	var stool := MeshInstance3D.new()
	var scyl := CylinderMesh.new()
	scyl.top_radius = 0.32
	scyl.bottom_radius = 0.28
	scyl.height = 0.42
	scyl.radial_segments = 10
	stool.mesh = scyl
	stool.material_override = wood_mat
	stool.position = Vector3(-0.95, 0.42, -0.72)
	root.add_child(stool)
	var book := MeshInstance3D.new()
	var bkb := BoxMesh.new()
	bkb.size = Vector3(0.38, 0.06, 0.26)
	book.mesh = bkb
	book.material_override = ToonMat.make(Color(1.0, 0.97, 0.88), "", {"outline_width": 0.8})
	book.position = Vector3(-0.95, 0.66, -0.72)
	book.rotation_degrees.y = 18.0
	root.add_child(book)

	# Plush colorful floor cushions
	var c_cols := [Color(0.96, 0.52, 0.68), Color(0.46, 0.80, 0.98), Color(0.98, 0.80, 0.26)]
	var c_pos := [Vector3(-0.75, 0.16, 0.35), Vector3(0.05, 0.16, -0.35), Vector3(0.85, 0.16, 0.45)]
	for i in range(3):
		var cush := MeshInstance3D.new()
		var cc := CylinderMesh.new()
		cc.top_radius = 0.46
		cc.bottom_radius = 0.50
		cc.height = 0.16
		cc.radial_segments = 12
		cush.mesh = cc
		cush.material_override = ToonMat.make(c_cols[i], "", {"outline_width": 1.0})
		cush.position = c_pos[i]
		root.add_child(cush)

	# Adorable 3D Orange Cat (Easter egg from the infographic!) sitting on the right cushion
	_cat_node = Node3D.new()
	_cat_node.position = Vector3(0.85, 0.24, 0.42)
	_cat_node.rotation_degrees.y = -35.0
	root.add_child(_cat_node)
	var cat := _cat_node

	var orange_mat := ToonMat.make(Color(0.96, 0.58, 0.18), "", {"outline_width": 1.0})
	var stripe_mat := ToonMat.make(Color(0.76, 0.36, 0.08), "", {"outline": false})
	var cream_mat := ToonMat.make(Color(1.0, 0.94, 0.82), "", {"outline": false})
	var pink_mat := ToonMat.make(Color(0.98, 0.56, 0.66), "", {"outline": false})
	var eye_mat := ToonMat.make(Color(0.12, 0.10, 0.12), "", {"outline": false})

	var cbody := MeshInstance3D.new()
	var cbsp := SphereMesh.new()
	cbsp.radius = 0.24
	cbsp.height = 0.48
	cbsp.radial_segments = 10
	cbsp.rings = 6
	cbody.mesh = cbsp
	cbody.material_override = orange_mat
	cbody.scale = Vector3(1.0, 1.12, 1.22)
	cbody.position = Vector3(0.0, 0.22, 0.0)
	cat.add_child(cbody)

	# Cream belly patch + cute front paws + tabby stripes!
	var belly := MeshInstance3D.new()
	var bsp := SphereMesh.new()
	bsp.radius = 0.16
	bsp.height = 0.32
	bsp.radial_segments = 8
	bsp.rings = 6
	belly.mesh = bsp
	belly.material_override = cream_mat
	belly.position = Vector3(0.0, 0.18, 0.16)
	cat.add_child(belly)

	for sx: float in [-1.0, 1.0]:
		var paw := MeshInstance3D.new()
		var psp := SphereMesh.new()
		psp.radius = 0.068
		psp.height = 0.136
		psp.radial_segments = 8
		psp.rings = 4
		paw.mesh = psp
		paw.material_override = cream_mat
		paw.position = Vector3(sx * 0.11, 0.06, 0.22)
		cat.add_child(paw)

	var stripe := MeshInstance3D.new()
	var sb := SphereMesh.new()
	sb.radius = 0.12
	sb.height = 0.24
	sb.radial_segments = 8
	sb.rings = 4
	stripe.mesh = sb
	stripe.material_override = stripe_mat
	stripe.scale = Vector3(1.3, 0.28, 0.55)
	stripe.position = Vector3(0.0, 0.45, -0.04)
	cat.add_child(stripe)

	_cat_head = Node3D.new()
	_cat_head.position = Vector3(0.0, 0.52, 0.16)
	cat.add_child(_cat_head)

	var chead := MeshInstance3D.new()
	var chsp := SphereMesh.new()
	chsp.radius = 0.22
	chsp.height = 0.44
	chsp.radial_segments = 10
	chsp.rings = 6
	chead.mesh = chsp
	chead.material_override = orange_mat
	_cat_head.add_child(chead)

	var nose := MeshInstance3D.new()
	var nsp := SphereMesh.new()
	nsp.radius = 0.028
	nsp.height = 0.056
	nsp.radial_segments = 6
	nsp.rings = 4
	nose.mesh = nsp
	nose.material_override = pink_mat
	nose.position = Vector3(0.0, -0.015, 0.22)
	_cat_head.add_child(nose)

	# Cat ears
	for sx: float in [-1.0, 1.0]:
		var ear := MeshInstance3D.new()
		var ec := CylinderMesh.new()
		ec.top_radius = 0.0
		ec.bottom_radius = 0.08
		ec.height = 0.16
		ec.radial_segments = 4
		ear.mesh = ec
		ear.material_override = orange_mat
		ear.position = Vector3(sx * 0.12, 0.20, 0.0)
		ear.rotation_degrees.z = -sx * 16.0
		_cat_head.add_child(ear)

		var eye := MeshInstance3D.new()
		var esp := SphereMesh.new()
		esp.radius = 0.032
		esp.height = 0.064
		esp.radial_segments = 6
		esp.rings = 4
		eye.mesh = esp
		eye.material_override = eye_mat
		eye.position = Vector3(sx * 0.075, 0.02, 0.19)
		_cat_head.add_child(eye)

	var muzzle := MeshInstance3D.new()
	var msp := SphereMesh.new()
	msp.radius = 0.065
	msp.height = 0.13
	msp.radial_segments = 6
	msp.rings = 4
	muzzle.mesh = msp
	muzzle.material_override = cream_mat
	muzzle.position = Vector3(0.0, -0.04, 0.18)
	_cat_head.add_child(muzzle)

	_cat_tail = Node3D.new()
	_cat_tail.position = Vector3(0.0, 0.22, -0.26)
	cat.add_child(_cat_tail)
	var tail_m := MeshInstance3D.new()
	var tc := CylinderMesh.new()
	tc.top_radius = 0.045
	tc.bottom_radius = 0.055
	tc.height = 0.42
	tc.radial_segments = 6
	tail_m.mesh = tc
	tail_m.material_override = orange_mat
	tail_m.position = Vector3(0.0, 0.18, -0.08)
	tail_m.rotation_degrees.x = -25.0
	_cat_tail.add_child(tail_m)

	# Cute floating "Meong~ ♪" speech bubble & rising pink ♥ hearts when Nara pets the cat!
	_cat_bubble = Label3D.new()
	_cat_bubble.text = "Meong~ ♪"
	_cat_bubble.font_size = 40
	_cat_bubble.outline_size = 8
	_cat_bubble.modulate = Color(1.0, 0.88, 0.94)
	_cat_bubble.outline_modulate = Color(0.55, 0.14, 0.30)
	_cat_bubble.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_cat_bubble.position = Vector3(0.0, 1.35, 0.0)
	_cat_bubble.visible = false
	cat.add_child(_cat_bubble)

	for _hi in range(3):
		var heart := Label3D.new()
		heart.text = "♥"
		heart.font_size = 48
		heart.outline_size = 6
		heart.modulate = Color(1.0, 0.36, 0.58)
		heart.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		heart.visible = false
		cat.add_child(heart)
		_cat_hearts.append(heart)

	_gazebo_ring = MeshInstance3D.new()
	var tor := TorusMesh.new()
	tor.inner_radius = 1.45
	tor.outer_radius = 1.62
	tor.rings = 20
	tor.ring_segments = 8
	_gazebo_ring.mesh = tor
	_gazebo_ring.material_override = ToonMat.make(Color(0.98, 0.78, 0.18), "", {"emission_color": Color(0.96, 0.70, 0.10), "emission_energy": 0.45})
	_gazebo_ring.position = Vector3(0.0, 0.12, 0.0)
	root.add_child(_gazebo_ring)

	_gazebo_lbl = Label3D.new()
	_gazebo_lbl.text = "5. CARI TEMPAT NYAMAN\nMasuk Gazebo & tekan [E / Aksi] untuk istirahat!"
	_gazebo_lbl.font_size = 40
	_gazebo_lbl.outline_size = 8
	_gazebo_lbl.modulate = Color(1.0, 0.96, 0.76)
	_gazebo_lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_gazebo_lbl.position = Vector3(0.0, 4.75, 0.0)
	root.add_child(_gazebo_lbl)

	_add_zone_area(root, "step5", 2.45)


func _build_step6_floral_arch_and_exit() -> void:
	# Step 6 Floral Archway ("Menjauh dari Sumber Marah")
	var arch := Node3D.new()
	arch.position = step_positions[6]
	add_child(arch)
	var leaf_mat := ToonMat.make(Color(0.28, 0.72, 0.34), "res://assets/textures/leaf_canopy.webp", {"triplanar": true, "triplanar_scale": 0.45})
	var wood_mat := ToonMat.make(Color(0.56, 0.34, 0.18), "res://assets/textures/wood_planks.webp", {"triplanar": true, "triplanar_scale": 0.45})

	for sx: float in [-2.35, 2.35]:
		var p := MeshInstance3D.new()
		var pc := CylinderMesh.new()
		pc.top_radius = 0.18
		pc.bottom_radius = 0.22
		pc.height = 3.2
		pc.radial_segments = 8
		p.mesh = pc
		p.material_override = wood_mat
		p.position = Vector3(sx, 1.6, 0.0)
		arch.add_child(p)
		_add_box_collider(arch, Vector3(0.46, 3.2, 0.46), Vector3(sx, 1.6, 0.0))

	var top_bar := MeshInstance3D.new()
	var tb := BoxMesh.new()
	tb.size = Vector3(5.2, 0.42, 0.48)
	top_bar.mesh = tb
	top_bar.material_override = leaf_mat
	top_bar.position = Vector3(0.0, 3.25, 0.0)
	arch.add_child(top_bar)

	# Decorative flowers along top of arch
	var fcols := [Color(0.98, 0.42, 0.56), Color(1.0, 0.82, 0.20), Color(0.46, 0.82, 1.0)]
	for i in range(-2, 3):
		StorybookProps.spawn_flower(arch, Vector3(float(i) * 0.95, 3.35, 0.18), fcols[absi(i) % fcols.size()])

	_arch_lbl = Label3D.new()
	_arch_lbl.text = "6. MENJAUH DARI SUMBER MARAH\nBerjalan melewati Lengkungan Damai!"
	_arch_lbl.font_size = 40
	_arch_lbl.outline_size = 8
	_arch_lbl.modulate = Color(1.0, 0.96, 0.78)
	_arch_lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_arch_lbl.position = Vector3(0.0, 4.45, 0.0)
	arch.add_child(_arch_lbl)

	_add_zone_area(arch, "step6", 2.5)

	# Pos 4 Star + Confetti
	var star_root := Node3D.new()
	star_root.position = star_position
	add_child(star_root)

	_star_mat = ToonMat.make(Color(0.99, 0.80, 0.12), "", {"emission_color": Color(0.98, 0.65, 0.08), "emission_energy": 0.38, "unique": true})
	_star_mesh = MeshInstance3D.new()
	_star_mesh.mesh = _make_3d_star_mesh(0.75, 0.35, 0.20)
	_star_mesh.material_override = _star_mat
	_star_mesh.position = Vector3(0.0, 2.35, 0.0)
	star_root.add_child(_star_mesh)

	var badge_lbl := Label3D.new()
	badge_lbl.text = "POS 4"
	badge_lbl.font_size = 72
	badge_lbl.outline_size = 12
	badge_lbl.modulate = Color(1.0, 0.96, 0.78)
	badge_lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	badge_lbl.position = Vector3(0.0, 3.45, 0.0)
	star_root.add_child(badge_lbl)

	_confetti = GPUParticles3D.new()
	_confetti.position = Vector3(0.0, 2.5, 0.0)
	_confetti.amount = 36
	_confetti.lifetime = 1.4
	_confetti.one_shot = true
	_confetti.explosiveness = 0.85
	_confetti.emitting = false
	var cpm := ParticleProcessMaterial.new()
	cpm.direction = Vector3(0.0, 1.0, 0.0)
	cpm.spread = 80.0
	cpm.initial_velocity_min = 2.8
	cpm.initial_velocity_max = 5.5
	cpm.gravity = Vector3(0.0, -5.5, 0.0)
	cpm.scale_min = 0.09
	cpm.scale_max = 0.18
	cpm.color = Color(1.0, 0.85, 0.25)
	_confetti.process_material = cpm
	var cbox := BoxMesh.new()
	cbox.size = Vector3(0.6, 0.6, 0.15)
	var cmat := StandardMaterial3D.new()
	cmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	cmat.albedo_color = Color(1.0, 0.72, 0.24)
	cbox.material = cmat
	_confetti.draw_pass_1 = cbox
	star_root.add_child(_confetti)

	# Exit Gate -> Pos 5
	var gate_root := Node3D.new()
	gate_root.position = exit_gate_position
	add_child(gate_root)

	var brick_mat := ToonMat.make(Color(0.84, 0.44, 0.34), "res://assets/textures/brick.webp", {"triplanar": true, "triplanar_scale": 0.48})
	var gwood_mat := ToonMat.make(Color(0.62, 0.39, 0.22), "res://assets/textures/wood_planks.webp", {"triplanar": true, "triplanar_scale": 0.42})

	for side: float in [-1.0, 1.0]:
		var x: float = side * 2.95
		var pil := MeshInstance3D.new()
		var pbox := BoxMesh.new()
		pbox.size = Vector3(0.85, 3.6, 0.85)
		pil.mesh = pbox
		pil.material_override = brick_mat
		pil.position = Vector3(x, 1.8, 0.0)
		gate_root.add_child(pil)
		_add_box_collider(gate_root, Vector3(0.95, 3.8, 0.95), Vector3(x, 1.9, 0.0))

	var beam := MeshInstance3D.new()
	var bbox := BoxMesh.new()
	bbox.size = Vector3(6.8, 0.55, 0.65)
	beam.mesh = bbox
	beam.material_override = gwood_mat
	beam.position = Vector3(0.0, 3.65, 0.0)
	gate_root.add_child(beam)

	var sign_bg := MeshInstance3D.new()
	var sbox := BoxMesh.new()
	sbox.size = Vector3(5.0, 1.15, 0.18)
	sign_bg.mesh = sbox
	sign_bg.material_override = ToonMat.make(Color(0.24, 0.50, 0.82), "", {"outline_width": 1.4})
	sign_bg.position = Vector3(0.0, 4.48, 0.05)
	gate_root.add_child(sign_bg)

	_gate_lbl = Label3D.new()
	_gate_lbl.text = "NEXT RUTE -> POS 5\n(Selesaikan 6 Langkah Tenang)"
	_gate_lbl.font_size = 38
	_gate_lbl.outline_size = 8
	_gate_lbl.modulate = Color(1.0, 0.96, 0.82)
	_gate_lbl.position = Vector3(0.0, 4.48, 0.17)
	gate_root.add_child(_gate_lbl)

	_gate_left_pivot = Node3D.new()
	_gate_left_pivot.position = Vector3(-2.5, 0.0, 0.0)
	gate_root.add_child(_gate_left_pivot)
	var dbox := BoxMesh.new()
	dbox.size = Vector3(2.45, 2.35, 0.18)
	var ld := MeshInstance3D.new()
	ld.mesh = dbox
	ld.material_override = gwood_mat
	ld.position = Vector3(1.25, 1.2, 0.0)
	_gate_left_pivot.add_child(ld)

	_gate_right_pivot = Node3D.new()
	_gate_right_pivot.position = Vector3(2.5, 0.0, 0.0)
	gate_root.add_child(_gate_right_pivot)
	var rd := MeshInstance3D.new()
	rd.mesh = dbox
	rd.material_override = gwood_mat
	rd.position = Vector3(-1.25, 1.2, 0.0)
	_gate_right_pivot.add_child(rd)

	_gate_blocker = StaticBody3D.new()
	_gate_blocker.collision_layer = 1
	_gate_blocker.collision_mask = 0
	var bcol := CollisionShape3D.new()
	var bshape := BoxShape3D.new()
	bshape.size = Vector3(5.2, 2.8, 0.45)
	bcol.shape = bshape
	_gate_blocker.position = Vector3(0.0, 1.4, 0.0)
	_gate_blocker.add_child(bcol)
	gate_root.add_child(_gate_blocker)

	_portal_area = Area3D.new()
	_portal_area.collision_layer = 4
	_portal_area.collision_mask = 2
	var pcol := CollisionShape3D.new()
	var pshape := BoxShape3D.new()
	pshape.size = Vector3(4.8, 3.2, 2.6)
	pcol.shape = pshape
	pcol.position = Vector3(0.0, 1.4, -0.3)
	_portal_area.add_child(pcol)
	gate_root.add_child(_portal_area)
	_portal_area.body_entered.connect(func(body: Node3D) -> void:
		if body is NaraController and _gate_opened:
			next_route_entered.emit()
	)


func _build_trees() -> void:
	var trunk_mat := ToonMat.make(Color(0.55, 0.36, 0.22), "res://assets/textures/bark.webp", {"triplanar": true})
	var leaf_mat := ToonMat.make(Color(0.28, 0.68, 0.30), "res://assets/textures/leaf_canopy.webp", {"triplanar": true, "triplanar_scale": 0.45})
	var spots := [
		[Vector3(-6.8, 0.0, 9.2), 1.1],
		[Vector3(6.8, 0.0, 8.8), 1.05],
		[Vector3(-6.8, 0.0, -5.2), 1.25],
		[Vector3(6.8, 0.0, -4.2), 1.15],
		[Vector3(-6.8, 0.0, -24.8), 1.2],
		[Vector3(6.8, 0.0, -26.5), 1.25],
		[Vector3(-6.4, 0.0, -39.5), 1.15],
		[Vector3(6.4, 0.0, -39.5), 1.15],
	]
	for t in spots:
		var tr := Node3D.new()
		tr.position = t[0]
		var sc: float = float(t[1])
		tr.scale = Vector3(sc, sc, sc)
		add_child(tr)

		var trunk := MeshInstance3D.new()
		var tc := CylinderMesh.new()
		tc.top_radius = 0.26
		tc.bottom_radius = 0.40
		tc.height = 2.4
		tc.radial_segments = 10
		trunk.mesh = tc
		trunk.material_override = trunk_mat
		trunk.position = Vector3(0.0, 1.2, 0.0)
		tr.add_child(trunk)

		var c1 := MeshInstance3D.new()
		var sp1 := SphereMesh.new()
		sp1.radius = 1.4
		sp1.height = 2.8
		sp1.radial_segments = 10
		sp1.rings = 6
		c1.mesh = sp1
		c1.material_override = leaf_mat
		c1.position = Vector3(0.0, 2.95, 0.0)
		tr.add_child(c1)
		_add_box_collider(tr, Vector3(0.8, 2.4, 0.8), Vector3(0.0, 1.2, 0.0))


func _build_guide_arrow() -> void:
	_guide_arrow = StorybookProps.make_guide_arrow()
	add_child(_guide_arrow)


func _add_zone_area(parent: Node3D, zone_id: String, radius: float) -> void:
	var area := Area3D.new()
	area.collision_layer = 4
	area.collision_mask = 2
	var col := CollisionShape3D.new()
	var sh := CylinderShape3D.new()
	sh.radius = radius
	sh.height = 2.6
	col.shape = sh
	col.position = Vector3(0.0, 1.3, 0.0)
	area.add_child(col)
	parent.add_child(area)
	area.body_entered.connect(func(b: Node3D) -> void:
		if b is NaraController:
			zone_changed.emit(zone_id, true)
	)
	area.body_exited.connect(func(b: Node3D) -> void:
		if b is NaraController:
			zone_changed.emit(zone_id, false)
	)


func _make_3d_star_mesh(outer_r: float, inner_r: float, half_depth: float) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var pts: Array[Vector2] = []
	for i in range(10):
		var a := -PI * 0.5 + float(i) * PI / 5.0
		var r := outer_r if i % 2 == 0 else inner_r
		pts.append(Vector2(cos(a) * r, -sin(a) * r))
	var cf := Vector3(0.0, 0.0, half_depth)
	var cb := Vector3(0.0, 0.0, -half_depth)
	for i in range(10):
		var p1 := pts[i]
		var p2 := pts[(i + 1) % 10]
		var af := Vector3(p1.x, p1.y, half_depth * 0.32)
		var bf := Vector3(p2.x, p2.y, half_depth * 0.32)
		var ab := Vector3(p1.x, p1.y, -half_depth * 0.32)
		var bb := Vector3(p2.x, p2.y, -half_depth * 0.32)
		st.add_vertex(cf); st.add_vertex(af); st.add_vertex(bf)
		st.add_vertex(cb); st.add_vertex(bb); st.add_vertex(ab)
		st.add_vertex(af); st.add_vertex(bf); st.add_vertex(bb)
		st.add_vertex(af); st.add_vertex(bb); st.add_vertex(ab)
	st.generate_normals()
	return st.commit()


func _add_box_collider(parent: Node3D, sz: Vector3, pos: Vector3) -> void:
	var sb := StaticBody3D.new()
	sb.collision_layer = 1
	sb.collision_mask = 0
	var cs := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = sz
	cs.shape = sh
	sb.position = pos
	sb.add_child(cs)
	parent.add_child(sb)

