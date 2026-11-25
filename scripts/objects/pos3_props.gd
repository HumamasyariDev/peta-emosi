class_name Pos3Props
extends Node3D

signal near_bell_changed(is_near: bool)
signal near_board_changed(is_near: bool)
signal next_route_entered

var bell_position: Vector3 = Vector3(-2.8, 0.0, -1.2)
var board_position: Vector3 = Vector3(3.8, 0.0, -1.2)
var star_position: Vector3 = Vector3(0.0, 0.0, -8.2)
var exit_gate_position: Vector3 = Vector3(0.0, 0.0, -14.8)

var _bell_pivot: Node3D
var _bell_clapper: Node3D
var _bell_wave: MeshInstance3D
var _bell_wave_mat: StandardMaterial3D
var _bell_sparkles: GPUParticles3D
var _bell_ring_lbl: Label3D
var _bell_ground_ring: MeshInstance3D
var _bell_swing_amp: float = 0.0
var _bell_swing_phase: float = 0.0
var _bell_wave_t: float = 99.0
var _bell_rung_once: bool = false

var _board_ground_ring: MeshInstance3D
var _board_prompt_lbl: Label3D

var _bottle_node: Node3D
var _bottle_puffs: Array[MeshInstance3D] = []
var _bottle_lbl: Label3D
var _firecracker_sparks: Array[MeshInstance3D] = []
var _firecracker_lbl: Label3D
var _plaza_calmed: bool = false
var _comic_bubble: Label3D
var _comic_timer: float = 0.0
var _fireflies: Array[Dictionary] = []
var _clouds: Array[Node3D] = []
var _butterflies: Array[Dictionary] = []

var _star_mesh: MeshInstance3D
var _star_mat: ShaderMaterial
var _confetti: GPUParticles3D
var _gate_left_pivot: Node3D
var _gate_right_pivot: Node3D
var _gate_blocker: StaticBody3D
var _portal_area: Area3D
var _gate_lbl: Label3D
var _gate_opened: bool = false
var _guide_arrow: Node3D
var _time: float = 0.0


func _ready() -> void:
	_build_ground_and_plaza()
	_build_horizon_hills_and_flowers()
	_build_closed_back_gate()
	_build_brick_fences()
	_build_garden_lanterns()
	_build_golden_bell_pavilion()
	_build_rule_board()
	_build_diorama_pedestals()
	_build_trees_and_fireflies()
	_build_star_and_exit_gate()
	_build_guide_arrow()
	_clouds = StorybookProps.spawn_clouds(self)
	_butterflies = StorybookProps.spawn_butterflies(self, [
		Vector3(-5.8, 1.35, 0.8), Vector3(5.6, 1.45, 0.5), Vector3(2.8, 1.5, -6.5)
	])
	ToonMat.optimize_tree(self)


func _process(delta: float) -> void:
	if Game.modal_open:
		return
	_time += delta
	StorybookProps.animate_ambient(_clouds, _butterflies, _time, delta)

	# Star bob & spin
	if _star_mesh != null and _star_mesh.visible and not _star_mesh.has_meta("collected"):
		_star_mesh.position.y = 2.35 + sin(_time * 2.5) * 0.14
		_star_mesh.rotation.y += delta * 1.1

	# Golden Bell physics swing (gentle breeze idle + strong damped swing when rung)
	if _bell_pivot != null:
		var idle_sway := sin(_time * 1.5) * 2.4
		if _bell_swing_amp > 0.15:
			_bell_swing_phase += delta * 6.2
			_bell_swing_amp = maxf(0.0, _bell_swing_amp - delta * 6.8)
			var swing := sin(_bell_swing_phase) * _bell_swing_amp
			_bell_pivot.rotation_degrees.z = swing + idle_sway
			if _bell_clapper != null:
				_bell_clapper.rotation_degrees.z = -swing * 0.7
		else:
			_bell_pivot.rotation_degrees.z = idle_sway
			if _bell_clapper != null:
				_bell_clapper.rotation_degrees.z = -idle_sway * 0.4

	# Expanding golden shockwave ring when bell is rung
	if _bell_wave != null and _bell_wave_t < 1.8:
		_bell_wave_t += delta
		var p := clampf(_bell_wave_t / 1.8, 0.0, 1.0)
		var sc := 0.8 + p * 6.2
		_bell_wave.scale = Vector3(sc, 1.0, sc)
		_bell_wave.visible = p < 0.99
		if _bell_wave_mat != null:
			_bell_wave_mat.albedo_color = Color(1.0, 0.86, 0.28, (1.0 - p) * 0.72)

	# Shaking pressurized soda bottle ("Jangan Ditahan") -> calms down once balanced!
	if _bottle_node != null:
		if _plaza_calmed:
			_bottle_node.position.x = lerpf(_bottle_node.position.x, 0.0, clampf(delta * 6.0, 0.0, 1.0))
			_bottle_node.rotation_degrees.z = lerpf(_bottle_node.rotation_degrees.z, 0.0, clampf(delta * 6.0, 0.0, 1.0))
			for puff in _bottle_puffs:
				puff.visible = false
		else:
			_bottle_node.position.x = sin(_time * 26.0) * 0.022
			_bottle_node.rotation_degrees.z = sin(_time * 22.0) * 4.5
			for i in range(_bottle_puffs.size()):
				var puff := _bottle_puffs[i]
				puff.visible = true
				var cyc := fmod(_time * 1.2 + float(i) * 0.33, 1.0)
				puff.position = Vector3(sin(cyc * TAU + float(i)) * 0.14, 0.92 + cyc * 0.65, 0.0)
				var s := (1.0 - cyc) * 0.85 + 0.25
				puff.scale = Vector3(s, s, s)

	# Flickering firecracker sparks ("Jangan Diledakkan") -> fades out once balanced!
	for i in range(_firecracker_sparks.size()):
		var sp := _firecracker_sparks[i]
		if _plaza_calmed:
			sp.visible = false
		else:
			sp.visible = true
			var pulse := 0.65 + absf(sin(_time * 14.0 + float(i) * 2.1)) * 0.75
			sp.scale = Vector3(pulse, pulse, pulse)
			sp.rotation.y += delta * 5.0

	# Floating 3D comic speech bubble timer
	if _comic_bubble != null and _comic_timer > 0.0:
		_comic_timer -= delta
		_comic_bubble.position.y += delta * 0.18
		if _comic_timer <= 0.0:
			_comic_bubble.visible = false

	# Floating golden fireflies around the hilltop
	for f in _fireflies:
		var node: MeshInstance3D = f["node"] as MeshInstance3D
		var base: Vector3 = f["base"] as Vector3
		var spd: float = float(f["spd"])
		var ph: float = float(f["ph"])
		node.position = base + Vector3(
			sin(_time * spd + ph) * 0.55,
			sin(_time * (spd * 1.4) + ph * 1.7) * 0.32,
			cos(_time * spd + ph) * 0.55
		)


func ring_bell() -> void:
	_bell_rung_once = true
	_bell_swing_amp = 28.0
	_bell_swing_phase = 0.0
	_bell_wave_t = 0.0
	if _bell_wave != null:
		_bell_wave.visible = true
	if _bell_sparkles != null:
		_bell_sparkles.restart()
		_bell_sparkles.emitting = true
	if _bell_ring_lbl != null:
		_bell_ring_lbl.text = "LONCENG ELING ✓\n[E / Aksi] Bunyikan Lagi"
		_bell_ring_lbl.modulate = Color(0.75, 1.0, 0.78)
	if _bell_ground_ring != null:
		_bell_ground_ring.material_override = ToonMat.make(Color(0.24, 0.82, 0.42), "", {"emission_color": Color(0.20, 0.78, 0.38), "emission_energy": 0.45})


func calm_plaza() -> void:
	_plaza_calmed = true
	_bell_wave_t = 0.0
	if _bell_wave != null:
		_bell_wave.visible = true
	if _bell_sparkles != null:
		_bell_sparkles.restart()
		_bell_sparkles.emitting = true
	if _bottle_lbl != null:
		_bottle_lbl.text = "TERKENDALI ✓\n(Tidak Dipendam)"
		_bottle_lbl.modulate = Color(0.75, 1.0, 0.78)
	if _firecracker_lbl != null:
		_firecracker_lbl.text = "TENANG ✓\n(Tidak Diledakkan)"
		_firecracker_lbl.modulate = Color(0.75, 1.0, 0.78)


func show_nara_bubble(world_pos: Vector3, text: String, duration: float = 2.6) -> void:
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


func mark_board_solved() -> void:
	if _board_prompt_lbl != null:
		_board_prompt_lbl.text = "ATURAN EMOSI ✓\n[E / Aksi] Baca Lagi"
		_board_prompt_lbl.modulate = Color(0.75, 1.0, 0.78)
	if _board_ground_ring != null:
		_board_ground_ring.material_override = ToonMat.make(Color(0.24, 0.82, 0.42), "", {"emission_color": Color(0.20, 0.78, 0.38), "emission_energy": 0.45})


func unlock_exit_gate() -> void:
	if _gate_opened:
		return
	_gate_opened = true
	if _gate_blocker != null:
		_gate_blocker.collision_layer = 0
	if _confetti != null:
		_confetti.restart()
		_confetti.emitting = true
	if _star_mat != null:
		_star_mat.set_shader_parameter("emission_energy", 1.05)
	StorybookProps.collect_and_hide_star(self, _star_mesh, false)
	if _gate_lbl != null:
		_gate_lbl.text = "NEXT RUTE -> POS 4\n6 Langkah Menenangkan Diri!"
		_gate_lbl.modulate = Color(0.84, 1.0, 0.84)
	var tw := create_tween().set_parallel(true)
	tw.tween_property(_gate_left_pivot, "rotation_degrees:y", -105.0, 0.85).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(_gate_right_pivot, "rotation_degrees:y", 105.0, 0.85).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if _portal_area != null:
		for b in _portal_area.get_overlapping_bodies():
			if b is NaraController:
				next_route_entered.emit()
				break


func get_next_target_pos(bell_rung: bool, pos3_done: bool) -> Vector3:
	if pos3_done:
		return exit_gate_position + Vector3(0.0, 0.0, -0.6)
	if not bell_rung:
		return Vector3(-1.8, 0.0, 0.0)
	return Vector3(2.4, 0.0, -0.2)


func update_guide_arrow(player_pos: Vector3, target_pos: Vector3) -> void:
	if _guide_arrow == null:
		return
	var diff := Vector3(target_pos.x - player_pos.x, 0.0, target_pos.z - player_pos.z)
	if diff.length() < 1.9:
		_guide_arrow.visible = false
		return
	_guide_arrow.visible = true
	var dir := diff.normalized()
	_guide_arrow.position = Vector3(player_pos.x + dir.x * 1.35, 0.26 + sin(_time * 4.5) * 0.05, player_pos.z + dir.z * 1.35)
	_guide_arrow.rotation.y = atan2(dir.x, dir.z)


func _build_ground_and_plaza() -> void:
	var grass_mat := ToonMat.make(Color(0.36, 0.72, 0.29), "res://assets/textures/grass.webp", {"triplanar": true, "triplanar_scale": 0.22})
	var ground := MeshInstance3D.new()
	var gbox := BoxMesh.new()
	gbox.size = Vector3(68.0, 1.0, 68.0)
	ground.mesh = gbox
	ground.material_override = grass_mat
	ground.position = Vector3(0.0, -0.5, -4.0)
	add_child(ground)
	_add_box_collider(self, Vector3(68.0, 1.0, 68.0), Vector3(0.0, -0.5, -4.0))

	# Cobblestone road leading from Pos 2 entrance to Pos 4 exit
	var road_mat := ToonMat.make(Color(0.40, 0.44, 0.50), "res://assets/textures/cobblestone.webp", {"triplanar": true, "triplanar_scale": 0.45})
	var road := MeshInstance3D.new()
	var rbox := BoxMesh.new()
	rbox.size = Vector3(4.0, 0.08, 25.0)
	road.mesh = rbox
	road.material_override = road_mat
	road.position = Vector3(0.0, 0.02, -3.5)
	add_child(road)

	# Circular Golden Stone Plaza in the middle
	var plaza_mat := ToonMat.make(Color(0.86, 0.79, 0.64), "res://assets/textures/cobblestone.webp", {"triplanar": true, "triplanar_scale": 0.52})
	var plaza := MeshInstance3D.new()
	var pcyl := CylinderMesh.new()
	pcyl.top_radius = 5.6
	pcyl.bottom_radius = 5.8
	pcyl.height = 0.14
	pcyl.radial_segments = 24
	plaza.mesh = pcyl
	plaza.material_override = plaza_mat
	plaza.position = Vector3(0.0, 0.05, 0.0)
	add_child(plaza)

	# Warm golden decorative border ring around the plaza
	var rim := MeshInstance3D.new()
	var rtor := TorusMesh.new()
	rtor.inner_radius = 5.45
	rtor.outer_radius = 5.75
	rtor.rings = 24
	rtor.ring_segments = 8
	rim.mesh = rtor
	rim.material_override = ToonMat.make(Color(0.88, 0.66, 0.22), "", {"outline_width": 0.0})
	rim.position = Vector3(0.0, 0.12, 0.0)
	add_child(rim)

	# Road dashes
	var dash_mat := ToonMat.make(Color(0.98, 0.96, 0.88), "", {"outline_width": 0.0})
	for z_val: float in [6.8, 5.2, -6.5, -8.3, -10.1, -11.9, -13.5]:
		var dash := MeshInstance3D.new()
		var dbox := BoxMesh.new()
		dbox.size = Vector3(0.22, 0.03, 0.95)
		dash.mesh = dbox
		dash.material_override = dash_mat
		dash.position = Vector3(0.0, 0.075, z_val)
		add_child(dash)


func _build_horizon_hills_and_flowers() -> void:
	var hill_mat := ToonMat.make(Color(0.28, 0.64, 0.26), "res://assets/textures/grass.webp", {"triplanar": true, "triplanar_scale": 0.14})
	var hills := [
		[Vector3(-18.0, -2.5, -22.0), Vector3(16.0, 7.2, 13.0)],
		[Vector3(0.0, -3.0, -29.0), Vector3(24.0, 9.0, 15.0)],
		[Vector3(18.0, -2.5, -22.0), Vector3(17.0, 7.6, 13.0)],
		[Vector3(-23.0, -2.0, -2.0), Vector3(13.0, 6.2, 19.0)],
		[Vector3(23.0, -2.0, -2.0), Vector3(13.0, 6.2, 19.0)],
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

	var flower_colors := [Color(0.98, 0.42, 0.56), Color(0.98, 0.72, 0.22), Color(0.68, 0.56, 0.98), Color(0.42, 0.80, 0.98)]
	var spots := [
		Vector3(-6.8, 0.0, 4.5), Vector3(-7.4, 0.0, 0.5), Vector3(-6.5, 0.0, -4.5),
		Vector3(6.8, 0.0, 4.5), Vector3(7.4, 0.0, 0.5), Vector3(6.5, 0.0, -4.5),
		Vector3(-4.2, 0.0, -10.5), Vector3(4.2, 0.0, -10.5), Vector3(-5.8, 0.0, -8.0), Vector3(5.8, 0.0, -8.0),
	]
	for i in range(spots.size()):
		StorybookProps.spawn_flower(self, spots[i], flower_colors[i % flower_colors.size()])


func _build_closed_back_gate() -> void:
	var back_root := Node3D.new()
	back_root.position = Vector3(0.0, 0.0, 8.8)
	add_child(back_root)

	var brick_mat := ToonMat.make(Color(0.84, 0.44, 0.34), "res://assets/textures/brick.webp", {"triplanar": true, "triplanar_scale": 0.48})
	var wood_mat := ToonMat.make(Color(0.58, 0.36, 0.20), "res://assets/textures/wood_planks.webp", {"triplanar": true, "triplanar_scale": 0.42})

	for side: float in [-1.0, 1.0]:
		var pil := MeshInstance3D.new()
		var pbox := BoxMesh.new()
		pbox.size = Vector3(0.85, 3.4, 0.85)
		pil.mesh = pbox
		pil.material_override = brick_mat
		pil.position = Vector3(side * 2.9, 1.7, 0.0)
		back_root.add_child(pil)

	var beam := MeshInstance3D.new()
	var bbox := BoxMesh.new()
	bbox.size = Vector3(6.6, 0.5, 0.6)
	beam.mesh = bbox
	beam.material_override = wood_mat
	beam.position = Vector3(0.0, 3.45, 0.0)
	back_root.add_child(beam)

	var door := MeshInstance3D.new()
	var dbox := BoxMesh.new()
	dbox.size = Vector3(4.95, 3.20, 0.22)
	door.mesh = dbox
	door.material_override = wood_mat
	door.position = Vector3(0.0, 1.60, 0.0)
	back_root.add_child(door)

	var lbl := Label3D.new()
	lbl.text = "POS 2 SELESAI\n(Maju ke Bukit Lonceng Emas!)"
	lbl.font_size = 38
	lbl.outline_size = 8
	lbl.modulate = Color(1.0, 0.96, 0.82)
	lbl.position = Vector3(0.0, 3.45, -0.35)
	lbl.rotation_degrees.y = 180.0
	back_root.add_child(lbl)

	_add_box_collider(back_root, Vector3(18.0, 3.6, 0.7), Vector3(0.0, 1.8, 0.0))


func _build_brick_fences() -> void:
	var brick_mat := ToonMat.make(Color(0.84, 0.44, 0.34), "res://assets/textures/brick.webp", {"triplanar": true, "triplanar_scale": 0.48})
	var cap_mat := ToonMat.make(Color(0.92, 0.86, 0.74), "", {"outline_width": 1.1})
	for side: float in [-1.0, 1.0]:
		var x: float = side * 8.6
		var wall := MeshInstance3D.new()
		var wbox := BoxMesh.new()
		wbox.size = Vector3(0.55, 1.05, 24.0)
		wall.mesh = wbox
		wall.material_override = brick_mat
		wall.position = Vector3(x, 0.52, -3.0)
		add_child(wall)

		var cap := MeshInstance3D.new()
		var cbox := BoxMesh.new()
		cbox.size = Vector3(0.68, 0.14, 24.2)
		cap.mesh = cbox
		cap.material_override = cap_mat
		cap.position = Vector3(x, 1.1, -3.0)
		add_child(cap)
		_add_box_collider(self, Vector3(0.7, 6.0, 24.4), Vector3(x, 3.0, -3.0))

	# Visual brick flanking walls sealing both gates + 360-deg horizon backdrop
	StorybookProps.build_flanking_brick_walls(self, 8.8, 2.9, 8.6, 1.05)
	StorybookProps.build_flanking_brick_walls(self, -14.8, 2.8, 8.6, 1.05)
	StorybookProps.spawn_horizon_backdrop_360(self, -16.5, 9.5, 9.0)

	# Tall invisible back & front flanking walls so Nara can NEVER escape Pos 3!
	_add_box_collider(self, Vector3(18.0, 6.0, 0.6), Vector3(0.0, 3.0, 9.2))
	_add_box_collider(self, Vector3(6.2, 6.0, 0.6), Vector3(-5.8, 3.0, -14.8))
	_add_box_collider(self, Vector3(6.2, 6.0, 0.6), Vector3(5.8, 3.0, -14.8))
	_add_box_collider(self, Vector3(6.5, 6.0, 0.6), Vector3(0.0, 3.0, -17.5))


func _build_garden_lanterns() -> void:
	var wood_mat := ToonMat.make(Color(0.46, 0.28, 0.14), "res://assets/textures/wood_planks.webp", {"triplanar": true, "triplanar_scale": 0.5})
	var glow_mat := ToonMat.make(Color(1.0, 0.92, 0.62), "", {"emission_color": Color(1.0, 0.82, 0.32), "emission_energy": 0.9})
	var spots := [
		Vector3(-2.6, 0.0, 5.2), Vector3(2.6, 0.0, 5.2),
		Vector3(-2.6, 0.0, -7.2), Vector3(2.6, 0.0, -7.2),
	]
	for p in spots:
		var lr := Node3D.new()
		lr.position = p
		add_child(lr)

		var post := MeshInstance3D.new()
		var pc := CylinderMesh.new()
		pc.top_radius = 0.12
		pc.bottom_radius = 0.16
		pc.height = 1.45
		pc.radial_segments = 8
		post.mesh = pc
		post.material_override = wood_mat
		post.position = Vector3(0.0, 0.72, 0.0)
		lr.add_child(post)

		var lamp := MeshInstance3D.new()
		var lb := BoxMesh.new()
		lb.size = Vector3(0.36, 0.42, 0.36)
		lamp.mesh = lb
		lamp.material_override = glow_mat
		lamp.position = Vector3(0.0, 1.62, 0.0)
		lr.add_child(lamp)

		var roof := MeshInstance3D.new()
		var rc := CylinderMesh.new()
		rc.top_radius = 0.04
		rc.bottom_radius = 0.36
		rc.height = 0.24
		rc.radial_segments = 4
		roof.mesh = rc
		roof.material_override = wood_mat
		roof.position = Vector3(0.0, 1.94, 0.0)
		roof.rotation_degrees.y = 45.0
		lr.add_child(roof)


func _build_golden_bell_pavilion() -> void:
	var pav := Node3D.new()
	pav.position = bell_position
	pav.rotation_degrees.y = 18.0
	add_child(pav)

	var wood_mat := ToonMat.make(Color(0.50, 0.28, 0.14), "res://assets/textures/wood_planks.webp", {"triplanar": true, "triplanar_scale": 0.45})
	var red_trim := ToonMat.make(Color(0.76, 0.18, 0.22), "", {"outline_width": 1.3})
	var gold_mat := ToonMat.make(Color(0.99, 0.80, 0.18), "", {"emission_color": Color(0.95, 0.68, 0.10), "emission_energy": 0.32})
	var stone_mat := ToonMat.make(Color(0.78, 0.74, 0.66), "", {"outline_width": 1.1})

	# Raised stone dais beneath the bell
	var dais := MeshInstance3D.new()
	var dc := CylinderMesh.new()
	dc.top_radius = 2.05
	dc.bottom_radius = 2.25
	dc.height = 0.24
	dc.radial_segments = 16
	dais.mesh = dc
	dais.material_override = stone_mat
	dais.position = Vector3(0.0, 0.12, 0.0)
	pav.add_child(dais)

	# Two sturdy timber columns
	for side: float in [-1.0, 1.0]:
		var col := MeshInstance3D.new()
		var cmesh := CylinderMesh.new()
		cmesh.top_radius = 0.22
		cmesh.bottom_radius = 0.26
		cmesh.height = 4.1
		cmesh.radial_segments = 10
		col.mesh = cmesh
		col.material_override = wood_mat
		col.position = Vector3(side * 1.65, 2.15, 0.0)
		pav.add_child(col)
		_add_box_collider(pav, Vector3(0.55, 4.1, 0.55), Vector3(side * 1.65, 2.15, 0.0))

	# Top horizontal beam & storybook pagoda roof
	var beam := MeshInstance3D.new()
	var bbox := BoxMesh.new()
	bbox.size = Vector3(4.3, 0.36, 0.46)
	beam.mesh = bbox
	beam.material_override = wood_mat
	beam.position = Vector3(0.0, 4.15, 0.0)
	pav.add_child(beam)

	var roof := MeshInstance3D.new()
	var rbox := BoxMesh.new()
	rbox.size = Vector3(4.8, 0.32, 1.65)
	roof.mesh = rbox
	roof.material_override = red_trim
	roof.position = Vector3(0.0, 4.52, 0.0)
	pav.add_child(roof)

	var roof_cap := MeshInstance3D.new()
	var rcbox := BoxMesh.new()
	rcbox.size = Vector3(3.6, 0.28, 1.05)
	roof_cap.mesh = rcbox
	roof_cap.material_override = gold_mat
	roof_cap.position = Vector3(0.0, 4.82, 0.0)
	pav.add_child(roof_cap)

	# Swinging Golden Bell Pivot hanging from the top beam
	_bell_pivot = Node3D.new()
	_bell_pivot.position = Vector3(0.0, 4.0, 0.0)
	pav.add_child(_bell_pivot)

	# Hanging rod
	var rod := MeshInstance3D.new()
	var rmesh := CylinderMesh.new()
	rmesh.top_radius = 0.07
	rmesh.bottom_radius = 0.07
	rmesh.height = 0.65
	rmesh.radial_segments = 8
	rod.mesh = rmesh
	rod.material_override = wood_mat
	rod.position = Vector3(0.0, -0.32, 0.0)
	_bell_pivot.add_child(rod)

	# Bell crown dome
	var crown := MeshInstance3D.new()
	var crsp := SphereMesh.new()
	crsp.radius = 0.42
	crsp.height = 0.84
	crsp.radial_segments = 14
	crsp.rings = 8
	crown.mesh = crsp
	crown.material_override = gold_mat
	crown.position = Vector3(0.0, -0.78, 0.0)
	_bell_pivot.add_child(crown)

	# Bell flared body
	var body := MeshInstance3D.new()
	var bcyl := CylinderMesh.new()
	bcyl.top_radius = 0.42
	bcyl.bottom_radius = 0.78
	bcyl.height = 1.05
	bcyl.radial_segments = 16
	body.mesh = bcyl
	body.material_override = gold_mat
	body.position = Vector3(0.0, -1.32, 0.0)
	_bell_pivot.add_child(body)

	# Bell bottom thick brass lip
	var lip := MeshInstance3D.new()
	var ltor := TorusMesh.new()
	ltor.inner_radius = 0.66
	ltor.outer_radius = 0.86
	ltor.rings = 16
	ltor.ring_segments = 8
	lip.mesh = ltor
	lip.material_override = gold_mat
	lip.position = Vector3(0.0, -1.84, 0.0)
	_bell_pivot.add_child(lip)

	# Swinging clapper + red pull rope + golden tassel
	_bell_clapper = Node3D.new()
	_bell_clapper.position = Vector3(0.0, -1.25, 0.0)
	_bell_pivot.add_child(_bell_clapper)

	var clapper_ball := MeshInstance3D.new()
	var cbsp := SphereMesh.new()
	cbsp.radius = 0.22
	cbsp.height = 0.44
	cbsp.radial_segments = 10
	cbsp.rings = 6
	clapper_ball.mesh = cbsp
	clapper_ball.material_override = ToonMat.make(Color(0.84, 0.56, 0.08), "", {"outline_width": 1.2})
	clapper_ball.position = Vector3(0.0, -0.68, 0.0)
	_bell_clapper.add_child(clapper_ball)

	var rope := MeshInstance3D.new()
	var rpcyl := CylinderMesh.new()
	rpcyl.top_radius = 0.045
	rpcyl.bottom_radius = 0.045
	rpcyl.height = 1.05
	rpcyl.radial_segments = 8
	rope.mesh = rpcyl
	rope.material_override = red_trim
	rope.position = Vector3(0.0, -1.32, 0.0)
	_bell_clapper.add_child(rope)

	var tassel := MeshInstance3D.new()
	var tsp := SphereMesh.new()
	tsp.radius = 0.13
	tsp.height = 0.26
	tsp.radial_segments = 8
	tsp.rings = 6
	tassel.mesh = tsp
	tassel.material_override = gold_mat
	tassel.position = Vector3(0.0, -1.88, 0.0)
	_bell_clapper.add_child(tassel)

	# Glowing interaction ring on floor
	_bell_ground_ring = MeshInstance3D.new()
	var gr := TorusMesh.new()
	gr.inner_radius = 1.45
	gr.outer_radius = 1.62
	gr.rings = 20
	gr.ring_segments = 8
	_bell_ground_ring.mesh = gr
	_bell_ground_ring.material_override = ToonMat.make(Color(0.98, 0.78, 0.16), "", {"emission_color": Color(0.98, 0.72, 0.10), "emission_energy": 0.55})
	_bell_ground_ring.position = Vector3(0.0, 0.28, 0.0)
	pav.add_child(_bell_ground_ring)

	# Expanding golden shockwave ring (hidden until bell is rung)
	_bell_wave = MeshInstance3D.new()
	var wtor := TorusMesh.new()
	wtor.inner_radius = 0.85
	wtor.outer_radius = 1.02
	wtor.rings = 24
	wtor.ring_segments = 8
	_bell_wave.mesh = wtor
	_bell_wave_mat = StandardMaterial3D.new()
	_bell_wave_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_bell_wave_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_bell_wave_mat.albedo_color = Color(1.0, 0.86, 0.28, 0.7)
	_bell_wave.material_override = _bell_wave_mat
	_bell_wave.position = Vector3(0.0, 1.45, 0.0)
	_bell_wave.visible = false
	pav.add_child(_bell_wave)

	# Sparkle burst particles when ringing bell
	_bell_sparkles = GPUParticles3D.new()
	_bell_sparkles.position = Vector3(0.0, 2.3, 0.0)
	_bell_sparkles.amount = 28
	_bell_sparkles.lifetime = 1.3
	_bell_sparkles.one_shot = true
	_bell_sparkles.explosiveness = 0.9
	_bell_sparkles.emitting = false
	var pm := ParticleProcessMaterial.new()
	pm.direction = Vector3(0.0, 0.6, 0.0)
	pm.spread = 180.0
	pm.initial_velocity_min = 2.0
	pm.initial_velocity_max = 4.5
	pm.gravity = Vector3(0.0, -1.8, 0.0)
	pm.scale_min = 0.08
	pm.scale_max = 0.16
	pm.color = Color(1.0, 0.88, 0.28)
	_bell_sparkles.process_material = pm
	var sbox := BoxMesh.new()
	sbox.size = Vector3(0.55, 0.55, 0.55)
	var smat := StandardMaterial3D.new()
	smat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	smat.albedo_color = Color(1.0, 0.92, 0.45)
	sbox.material = smat
	_bell_sparkles.draw_pass_1 = sbox
	pav.add_child(_bell_sparkles)

	# Floating Label3D above pavilion
	_bell_ring_lbl = Label3D.new()
	_bell_ring_lbl.text = "LONCENG ELING\n[E / Aksi] Bunyikan Lonceng"
	_bell_ring_lbl.font_size = 54
	_bell_ring_lbl.outline_size = 10
	_bell_ring_lbl.modulate = Color(1.0, 0.95, 0.72)
	_bell_ring_lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_bell_ring_lbl.position = Vector3(0.0, 5.55, 0.0)
	pav.add_child(_bell_ring_lbl)

	# Trigger Area3D around the bell (compact radius so it never overlaps the rule board)
	var area := Area3D.new()
	area.collision_layer = 4
	area.collision_mask = 2
	var col := CollisionShape3D.new()
	var sh := CylinderShape3D.new()
	sh.radius = 2.05
	sh.height = 2.6
	col.shape = sh
	col.position = Vector3(0.0, 1.3, 0.0)
	area.add_child(col)
	pav.add_child(area)

	area.body_entered.connect(func(b: Node3D) -> void:
		if b is NaraController:
			near_bell_changed.emit(true)
	)
	area.body_exited.connect(func(b: Node3D) -> void:
		if b is NaraController:
			near_bell_changed.emit(false)
	)


func _build_rule_board() -> void:
	var brd := Node3D.new()
	brd.position = board_position
	brd.rotation_degrees.y = -32.0
	add_child(brd)

	var wood_mat := ToonMat.make(Color(0.46, 0.27, 0.13), "res://assets/textures/wood_planks.webp", {"triplanar": true, "triplanar_scale": 0.45})
	var parch_mat := ToonMat.make(Color(0.98, 0.94, 0.84), "", {"outline_width": 1.1})
	var gold_mat := ToonMat.make(Color(0.94, 0.72, 0.18), "", {"outline_width": 1.0})

	for side: float in [-1.0, 1.0]:
		var leg := MeshInstance3D.new()
		var lbox := BoxMesh.new()
		lbox.size = Vector3(0.24, 2.5, 0.24)
		leg.mesh = lbox
		leg.material_override = wood_mat
		leg.position = Vector3(side * 1.45, 1.25, 0.0)
		brd.add_child(leg)

	var frame := MeshInstance3D.new()
	var fbox := BoxMesh.new()
	fbox.size = Vector3(3.6, 2.35, 0.22)
	frame.mesh = fbox
	frame.material_override = wood_mat
	frame.position = Vector3(0.0, 2.45, 0.0)
	brd.add_child(frame)

	var plaque := MeshInstance3D.new()
	var pbox := BoxMesh.new()
	pbox.size = Vector3(3.25, 1.98, 0.08)
	plaque.mesh = pbox
	plaque.material_override = parch_mat
	plaque.position = Vector3(0.0, 2.45, 0.12)
	brd.add_child(plaque)

	var header_bar := MeshInstance3D.new()
	var hbox := BoxMesh.new()
	hbox.size = Vector3(1.85, 0.42, 0.14)
	header_bar.mesh = hbox
	header_bar.material_override = gold_mat
	header_bar.position = Vector3(0.0, 3.62, 0.06)
	brd.add_child(header_bar)

	var h_lbl := Label3D.new()
	h_lbl.text = "MORE INFO 3"
	h_lbl.font_size = 42
	h_lbl.outline_size = 7
	h_lbl.modulate = Color(0.24, 0.12, 0.04)
	h_lbl.position = Vector3(0.0, 3.62, 0.16)
	brd.add_child(h_lbl)

	var rule_lbl := Label3D.new()
	rule_lbl.text = "Emosi negatif seperti marah,\ntidak boleh ditahan,\ntapi juga tidak boleh diledakkan.\n\nEmosi negatif harus diatur\ndengan baik yaaa."
	rule_lbl.font_size = 26
	rule_lbl.outline_size = 4
	rule_lbl.modulate = Color(0.18, 0.11, 0.06)
	rule_lbl.outline_modulate = Color(1.0, 0.98, 0.92)
	rule_lbl.position = Vector3(0.0, 2.45, 0.19)
	brd.add_child(rule_lbl)

	_board_prompt_lbl = Label3D.new()
	_board_prompt_lbl.text = "PAPAN ATURAN EMOSI\n[E / Aksi] Buka Buku & Misi"
	_board_prompt_lbl.font_size = 44
	_board_prompt_lbl.outline_size = 8
	_board_prompt_lbl.modulate = Color(1.0, 0.96, 0.78)
	_board_prompt_lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_board_prompt_lbl.position = Vector3(0.0, 4.45, 0.0)
	brd.add_child(_board_prompt_lbl)

	_board_ground_ring = MeshInstance3D.new()
	var gr := TorusMesh.new()
	gr.inner_radius = 1.05
	gr.outer_radius = 1.20
	gr.rings = 18
	gr.ring_segments = 8
	_board_ground_ring.mesh = gr
	_board_ground_ring.material_override = ToonMat.make(Color(0.32, 0.72, 0.98), "", {"emission_color": Color(0.24, 0.62, 0.96), "emission_energy": 0.45})
	_board_ground_ring.position = Vector3(0.0, 0.14, 1.35)
	brd.add_child(_board_ground_ring)

	_add_box_collider(brd, Vector3(3.5, 3.6, 0.55), Vector3(0.0, 1.8, 0.0))

	var area := Area3D.new()
	area.collision_layer = 4
	area.collision_mask = 2
	var col := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = Vector3(3.8, 2.4, 3.0)
	col.shape = sh
	col.position = Vector3(0.0, 1.2, 1.4)
	area.add_child(col)
	brd.add_child(area)

	area.body_entered.connect(func(b: Node3D) -> void:
		if b is NaraController:
			near_board_changed.emit(true)
	)
	area.body_exited.connect(func(b: Node3D) -> void:
		if b is NaraController:
			near_board_changed.emit(false)
	)


func _build_diorama_pedestals() -> void:
	var stone_mat := ToonMat.make(Color(0.80, 0.76, 0.68), "", {"outline_width": 1.1})
	var red_mat := ToonMat.make(Color(0.92, 0.24, 0.22), "", {"outline_width": 1.2})
	var cork_mat := ToonMat.make(Color(0.76, 0.52, 0.28), "", {"outline_width": 1.0})
	var gold_mat := ToonMat.make(Color(0.98, 0.80, 0.20), "", {"outline_width": 1.0})
	var steam_mat := ToonMat.make(Color(0.98, 0.98, 1.0), "", {"outline_width": 0.8})
	var spark_mat := ToonMat.make(Color(1.0, 0.68, 0.14), "", {"emission_color": Color(1.0, 0.55, 0.10), "emission_energy": 0.9})

	# LEFT PEDESTAL: Shaking Pressurized Soda Bottle ("JANGAN DITAHAN!")
	var left_ped := Node3D.new()
	left_ped.position = Vector3(-4.6, 0.0, 2.8)
	add_child(left_ped)

	var base_l := MeshInstance3D.new()
	var blc := CylinderMesh.new()
	blc.top_radius = 0.72
	blc.bottom_radius = 0.86
	blc.height = 0.95
	blc.radial_segments = 12
	base_l.mesh = blc
	base_l.material_override = stone_mat
	base_l.position = Vector3(0.0, 0.48, 0.0)
	left_ped.add_child(base_l)
	_add_box_collider(left_ped, Vector3(1.6, 2.2, 1.6), Vector3(0.0, 1.1, 0.0))

	_bottle_node = Node3D.new()
	_bottle_node.position = Vector3(0.0, 0.96, 0.0)
	left_ped.add_child(_bottle_node)

	var b_body := MeshInstance3D.new()
	var bbc := CylinderMesh.new()
	bbc.top_radius = 0.30
	bbc.bottom_radius = 0.34
	bbc.height = 0.76
	bbc.radial_segments = 12
	b_body.mesh = bbc
	b_body.material_override = red_mat
	b_body.position = Vector3(0.0, 0.38, 0.0)
	_bottle_node.add_child(b_body)

	var b_neck := MeshInstance3D.new()
	var bnc := CylinderMesh.new()
	bnc.top_radius = 0.14
	bnc.bottom_radius = 0.28
	bnc.height = 0.28
	bnc.radial_segments = 10
	b_neck.mesh = bnc
	b_neck.material_override = red_mat
	b_neck.position = Vector3(0.0, 0.86, 0.0)
	_bottle_node.add_child(b_neck)

	var cork := MeshInstance3D.new()
	var ckc := CylinderMesh.new()
	ckc.top_radius = 0.16
	ckc.bottom_radius = 0.12
	ckc.height = 0.20
	ckc.radial_segments = 10
	cork.mesh = ckc
	cork.material_override = cork_mat
	cork.position = Vector3(0.0, 1.06, 0.0)
	_bottle_node.add_child(cork)

	for _i in range(3):
		var puff := MeshInstance3D.new()
		var psp := SphereMesh.new()
		psp.radius = 0.14
		psp.height = 0.28
		psp.radial_segments = 8
		psp.rings = 6
		puff.mesh = psp
		puff.material_override = steam_mat
		_bottle_node.add_child(puff)
		_bottle_puffs.append(puff)

	_bottle_lbl = Label3D.new()
	_bottle_lbl.text = "JANGAN DITAHAN!\n(Dada Jadi Sesak)"
	_bottle_lbl.font_size = 38
	_bottle_lbl.outline_size = 7
	_bottle_lbl.modulate = Color(1.0, 0.86, 0.84)
	_bottle_lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_bottle_lbl.position = Vector3(0.0, 2.75, 0.0)
	left_ped.add_child(_bottle_lbl)

	# RIGHT PEDESTAL: Sparking Firecracker ("JANGAN DILEDAKKAN!")
	var right_ped := Node3D.new()
	right_ped.position = Vector3(4.6, 0.0, 2.8)
	add_child(right_ped)

	var base_r := MeshInstance3D.new()
	base_r.mesh = blc
	base_r.material_override = stone_mat
	base_r.position = Vector3(0.0, 0.48, 0.0)
	right_ped.add_child(base_r)
	_add_box_collider(right_ped, Vector3(1.6, 2.2, 1.6), Vector3(0.0, 1.1, 0.0))

	var fc_root := Node3D.new()
	fc_root.position = Vector3(0.0, 0.96, 0.0)
	right_ped.add_child(fc_root)

	var fc_offsets := [Vector3(0.0, 0.0, 0.0), Vector3(-0.22, -0.05, 0.14), Vector3(0.22, -0.05, -0.10)]
	for off in fc_offsets:
		var stick := MeshInstance3D.new()
		var scyl := CylinderMesh.new()
		scyl.top_radius = 0.16
		scyl.bottom_radius = 0.16
		scyl.height = 0.82
		scyl.radial_segments = 10
		stick.mesh = scyl
		stick.material_override = red_mat
		stick.position = off + Vector3(0.0, 0.42, 0.0)
		fc_root.add_child(stick)

		var band := MeshInstance3D.new()
		var bc := CylinderMesh.new()
		bc.top_radius = 0.175
		bc.bottom_radius = 0.175
		bc.height = 0.14
		bc.radial_segments = 10
		band.mesh = bc
		band.material_override = gold_mat
		band.position = off + Vector3(0.0, 0.42, 0.0)
		fc_root.add_child(band)

		var spark := MeshInstance3D.new()
		var spbox := BoxMesh.new()
		spbox.size = Vector3(0.18, 0.18, 0.18)
		spark.mesh = spbox
		spark.material_override = spark_mat
		spark.position = off + Vector3(0.0, 0.96, 0.0)
		fc_root.add_child(spark)
		_firecracker_sparks.append(spark)

	_firecracker_lbl = Label3D.new()
	_firecracker_lbl.text = "JANGAN DILEDAKKAN!\n(Bisa Melukai Teman)"
	_firecracker_lbl.font_size = 38
	_firecracker_lbl.outline_size = 7
	_firecracker_lbl.modulate = Color(1.0, 0.92, 0.72)
	_firecracker_lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_firecracker_lbl.position = Vector3(0.0, 2.75, 0.0)
	right_ped.add_child(_firecracker_lbl)


func _build_trees_and_fireflies() -> void:
	var trunk_mat := ToonMat.make(Color(0.55, 0.36, 0.22), "res://assets/textures/bark.webp", {"triplanar": true})
	var leaf_mat := ToonMat.make(Color(0.28, 0.68, 0.30), "res://assets/textures/leaf_canopy.webp", {"triplanar": true, "triplanar_scale": 0.45})
	var leaf_hi := ToonMat.make(Color(0.38, 0.78, 0.34), "res://assets/textures/leaf_canopy.webp", {"triplanar": true, "triplanar_scale": 0.45})

	var tree_spots := [
		[Vector3(-4.2, 0.0, -4.4), 1.35],
		[Vector3(5.8, 0.0, -5.2), 1.15],
		[Vector3(-6.8, 0.0, 5.8), 1.05],
		[Vector3(6.8, 0.0, 5.8), 1.05],
		[Vector3(-6.2, 0.0, -11.5), 1.15],
		[Vector3(6.2, 0.0, -11.5), 1.15],
	]
	for t in tree_spots:
		var pos: Vector3 = t[0]
		var sc: float = float(t[1])
		var tr := Node3D.new()
		tr.position = pos
		tr.scale = Vector3(sc, sc, sc)
		add_child(tr)

		var trunk := MeshInstance3D.new()
		var tc := CylinderMesh.new()
		tc.top_radius = 0.28
		tc.bottom_radius = 0.42
		tc.height = 2.4
		tc.radial_segments = 10
		trunk.mesh = tc
		trunk.material_override = trunk_mat
		trunk.position = Vector3(0.0, 1.2, 0.0)
		tr.add_child(trunk)

		var canopy1 := MeshInstance3D.new()
		var sp1 := SphereMesh.new()
		sp1.radius = 1.45
		sp1.height = 2.9
		sp1.radial_segments = 12
		sp1.rings = 8
		canopy1.mesh = sp1
		canopy1.material_override = leaf_mat
		canopy1.position = Vector3(0.0, 3.0, 0.0)
		tr.add_child(canopy1)

		var canopy2 := MeshInstance3D.new()
		var sp2 := SphereMesh.new()
		sp2.radius = 1.05
		sp2.height = 2.1
		sp2.radial_segments = 10
		sp2.rings = 6
		canopy2.mesh = sp2
		canopy2.material_override = leaf_hi
		canopy2.position = Vector3(0.65, 3.65, 0.35)
		tr.add_child(canopy2)

		_add_box_collider(tr, Vector3(0.85, 2.5, 0.85), Vector3(0.0, 1.25, 0.0))

	# Gentle floating golden fireflies around the plaza
	var ff_mat := StandardMaterial3D.new()
	ff_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	ff_mat.albedo_color = Color(1.0, 0.94, 0.48)
	var ff_spots := [
		Vector3(-2.4, 2.2, -2.5), Vector3(2.4, 2.5, -2.2),
		Vector3(-3.2, 1.8, 0.8), Vector3(3.1, 2.1, 0.4),
		Vector3(0.0, 3.2, -3.5), Vector3(-1.5, 1.9, -5.5), Vector3(1.8, 2.0, -5.2)
	]
	for i in range(ff_spots.size()):
		var ff := MeshInstance3D.new()
		var sp := SphereMesh.new()
		sp.radius = 0.08
		sp.height = 0.16
		sp.radial_segments = 6
		sp.rings = 4
		ff.mesh = sp
		ff.material_override = ff_mat
		ff.position = ff_spots[i]
		add_child(ff)
		_fireflies.append({"node": ff, "base": ff_spots[i], "spd": 1.1 + float(i % 3) * 0.35, "ph": float(i) * 1.1})


func _build_guide_arrow() -> void:
	_guide_arrow = StorybookProps.make_guide_arrow()
	add_child(_guide_arrow)


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


func _build_star_and_exit_gate() -> void:
	# Pos 3 Star
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
	badge_lbl.text = "POS 3"
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

	# Exit Gate -> Pos 4
	var gate_root := Node3D.new()
	gate_root.position = exit_gate_position
	add_child(gate_root)

	var brick_mat := ToonMat.make(Color(0.84, 0.44, 0.34), "res://assets/textures/brick.webp", {"triplanar": true, "triplanar_scale": 0.48})
	var wood_mat := ToonMat.make(Color(0.62, 0.39, 0.22), "res://assets/textures/wood_planks.webp", {"triplanar": true, "triplanar_scale": 0.42})

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
	beam.material_override = wood_mat
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
	_gate_lbl.text = "NEXT RUTE -> POS 4\n(Bunyikan Lonceng & Pahami Aturan)"
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
	ld.material_override = wood_mat
	ld.position = Vector3(1.25, 1.2, 0.0)
	_gate_left_pivot.add_child(ld)

	_gate_right_pivot = Node3D.new()
	_gate_right_pivot.position = Vector3(2.5, 0.0, 0.0)
	gate_root.add_child(_gate_right_pivot)
	var rd := MeshInstance3D.new()
	rd.mesh = dbox
	rd.material_override = wood_mat
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

