class_name Pos5Props
extends Node3D

signal zone_changed(zone_id: String, entered: bool)
signal next_route_entered

var step_positions: Dictionary = {
	1: Vector3(0.0, 0.0, 1.8),
	2: Vector3(3.1, 0.0, -5.8),
	3: Vector3(-2.2, 0.0, -12.2),
}
var star_position: Vector3 = Vector3(0.0, 0.0, -16.8)
var exit_gate_position: Vector3 = Vector3(0.0, 0.0, -22.5)

var _time: float = 0.0
var _clouds: Array[Node3D] = []
var _butterflies: Array[Dictionary] = []
var _guide_arrow: Node3D
var _beacon_pillar: MeshInstance3D
var _comic_bubble: Label3D
var _comic_timer: float = 0.0
var _active_step: int = 1

# Zona 1: Giant Cloud Pillow
var _pillow_root: Node3D
var _pillow_ring: MeshInstance3D
var _pillow_lbl: Label3D
var _feather_burst: GPUParticles3D
var _pillow_done: bool = false

# Zona 2: Craft Paper Table & Recycle Bin
var _paper_stack: Array[MeshInstance3D] = []
var _paper_ring: MeshInstance3D
var _paper_lbl: Label3D
var _paper_burst: GPUParticles3D
var _bin_pos: Vector3 = Vector3.ZERO
var _paper_done: bool = false

# Zona 3: Safe Choice Signboard, Star & Pos 6 Exit Gate
var _board_ring: MeshInstance3D
var _board_lbl: Label3D
var _board_done: bool = false
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
	_build_ground_and_path()
	_build_horizon_hills_and_flowers()
	_build_closed_back_gate()
	_build_brick_fences()
	_build_zone1_cloud_pillow()
	_build_zone2_paper_table()
	_build_zone3_safe_board_and_exit()
	_build_trees()
	_build_guide_arrow()
	_build_waypoint_beacon()
	_clouds = StorybookProps.spawn_clouds(self)
	_butterflies = StorybookProps.spawn_butterflies(self, [
		Vector3(-4.8, 1.5, 2.5), Vector3(4.8, 1.6, -3.2), Vector3(-4.2, 1.5, -10.5), Vector3(4.2, 1.6, -16.0)
	])
	ToonMat.optimize_tree(self)
	set_active_step(1)


func set_active_step(step_num: int) -> void:
	_active_step = step_num
	if _pillow_lbl != null:
		_pillow_lbl.visible = (step_num == 1 or _pillow_done)
	if _paper_lbl != null:
		_paper_lbl.visible = (step_num == 2 or _paper_done)
	if _board_lbl != null:
		_board_lbl.visible = (step_num == 3 or _board_done)
	if _beacon_pillar != null:
		if step_positions.has(step_num):
			var sp: Vector3 = step_positions[step_num] as Vector3
			_beacon_pillar.position = Vector3(sp.x, 3.6, sp.z)
			_beacon_pillar.visible = true
		elif step_num == 4:
			_beacon_pillar.position = Vector3(exit_gate_position.x, 3.6, exit_gate_position.z)
			_beacon_pillar.visible = true
		else:
			_beacon_pillar.visible = false


func get_step_target(step_num: int) -> Vector3:
	if step_positions.has(step_num):
		return step_positions[step_num] as Vector3
	return exit_gate_position + Vector3(0.0, 0.0, -1.0)


func show_nara_bubble(world_pos: Vector3, text: String, duration: float = 1.6) -> void:
	if _comic_bubble == null:
		_comic_bubble = Label3D.new()
		_comic_bubble.font_size = 44
		_comic_bubble.outline_size = 10
		_comic_bubble.modulate = Color(1.0, 0.98, 0.82)
		_comic_bubble.outline_modulate = Color(0.24, 0.12, 0.05)
		_comic_bubble.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		add_child(_comic_bubble)
	_comic_bubble.text = text
	_comic_bubble.position = world_pos + Vector3(0.0, 2.35, 0.0)
	_comic_bubble.visible = true
	_comic_timer = duration


func punch_pillow(hits: int, max_hits: int) -> void:
	if _pillow_root != null:
		var tw := create_tween()
		tw.tween_property(_pillow_root, "scale", Vector3(1.28, 0.66, 1.24), 0.08).set_ease(Tween.EASE_OUT)
		tw.tween_property(_pillow_root, "scale", Vector3(0.90, 1.18, 0.92), 0.12).set_trans(Tween.TRANS_BACK)
		tw.tween_property(_pillow_root, "scale", Vector3.ONE, 0.14)
	if _feather_burst != null:
		_feather_burst.restart()
		_feather_burst.emitting = true
	if hits >= max_hits:
		_pillow_done = true
		if _pillow_lbl != null:
			_pillow_lbl.text = "1. PUKUL BANTAL EMPUK ✓\n(Hati Lebih Lega!)"
			_pillow_lbl.modulate = Color(0.75, 1.0, 0.78)
		if _pillow_ring != null:
			_pillow_ring.material_override = ToonMat.make(Color(0.22, 0.80, 0.40), "", {"emission_color": Color(0.18, 0.76, 0.36), "emission_energy": 0.45})
	else:
		if _pillow_lbl != null:
			_pillow_lbl.text = "1. PUKUL BANTAL EMPUK (%d/%d)\nTekan [E / Aksi] lagi!" % [hits, max_hits]


func rip_paper_sheet(rips: int, max_rips: int) -> void:
	# Hide top sheet from the wooden table stack
	var idx := _paper_stack.size() - rips
	if idx >= 0 and idx < _paper_stack.size() and is_instance_valid(_paper_stack[idx]):
		_paper_stack[idx].visible = false
	if _paper_burst != null:
		_paper_burst.restart()
		_paper_burst.emitting = true
	# Launch a cute crumpled paper ball in an arc straight into the green recycle bin!
	var ball := MeshInstance3D.new()
	var sp := SphereMesh.new()
	sp.radius = 0.14
	sp.height = 0.28
	sp.radial_segments = 8
	sp.rings = 5
	ball.mesh = sp
	ball.material_override = ToonMat.make(Color(0.99, 0.97, 0.90), "", {"outline_width": 0.9})
	var start_p := (step_positions[2] as Vector3) + Vector3(-0.15, 1.05, 0.0)
	var end_p := _bin_pos + Vector3(0.0, 0.65, 0.0)
	var mid_p := (start_p + end_p) * 0.5 + Vector3(0.0, 1.1, 0.0)
	ball.position = start_p
	add_child(ball)
	var tw := create_tween()
	tw.tween_property(ball, "position", mid_p, 0.22).set_ease(Tween.EASE_OUT)
	tw.tween_property(ball, "position", end_p, 0.22).set_ease(Tween.EASE_IN)
	tw.tween_property(ball, "scale", Vector3(0.1, 0.1, 0.1), 0.08)
	tw.tween_callback(ball.queue_free)

	if rips >= max_rips:
		_paper_done = true
		if _paper_lbl != null:
			_paper_lbl.text = "2. SOBEK KERTAS BEKAS ✓\n(Masuk Keranjang Daur Ulang!)"
			_paper_lbl.modulate = Color(0.75, 1.0, 0.78)
		if _paper_ring != null:
			_paper_ring.material_override = ToonMat.make(Color(0.22, 0.80, 0.40), "", {"emission_color": Color(0.18, 0.76, 0.36), "emission_energy": 0.45})
	else:
		if _paper_lbl != null:
			_paper_lbl.text = "2. SOBEK KERTAS BEKAS (%d/%d)\nTekan [E / Aksi] lagi!" % [rips, max_rips]


func mark_board_done() -> void:
	_board_done = true
	if _board_lbl != null:
		_board_lbl.text = "3. PILIHAN AMAN ✓\n(Pintar Memilih!)"
		_board_lbl.modulate = Color(0.75, 1.0, 0.78)
	if _board_ring != null:
		_board_ring.material_override = ToonMat.make(Color(0.22, 0.80, 0.40), "", {"emission_color": Color(0.18, 0.76, 0.36), "emission_energy": 0.45})


func unlock_exit_gate() -> void:
	if _gate_opened:
		return
	_gate_opened = true
	if _star_mat != null:
		_star_mat.set_shader_parameter("albedo", Color(1.0, 0.88, 0.18))
		_star_mat.set_shader_parameter("emission_energy", 0.95)
	StorybookProps.collect_and_hide_star(self, _star_mesh, false)
	if _confetti != null:
		_confetti.restart()
		_confetti.emitting = true
	if _gate_blocker != null:
		_gate_blocker.collision_layer = 0
	if _gate_lbl != null:
		_gate_lbl.text = "GERBANG POS 6 TERBUKA!\n(Pos 5 Selesai ★)"
		_gate_lbl.modulate = Color(0.76, 1.0, 0.78)
	if _gate_left_pivot != null and _gate_right_pivot != null:
		var tw := create_tween().set_parallel(true)
		tw.tween_property(_gate_left_pivot, "rotation_degrees:y", 88.0, 0.9).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(_gate_right_pivot, "rotation_degrees:y", -88.0, 0.9).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if _portal_area != null:
		for b in _portal_area.get_overlapping_bodies():
			if b is NaraController:
				next_route_entered.emit()
				break


func update_guide_arrow(player_pos: Vector3, target_pos: Vector3) -> void:
	if _guide_arrow == null:
		return
	var d := target_pos - player_pos
	d.y = 0.0
	if d.length() < 1.6:
		_guide_arrow.visible = false
		return
	_guide_arrow.visible = true
	var dir := d.normalized()
	_guide_arrow.position = player_pos + dir * 1.45 + Vector3(0.0, 0.24, 0.0)
	_guide_arrow.rotation.y = atan2(dir.x, dir.z)


func _process(delta: float) -> void:
	_time += delta
	StorybookProps.animate_ambient(_clouds, _butterflies, _time, delta)
	if _star_mesh != null and _star_mesh.visible and not _star_mesh.has_meta("collected"):
		_star_mesh.rotation.y += delta * 1.5
		_star_mesh.position.y = 2.35 + sin(_time * 2.8) * 0.16
	if _beacon_pillar != null and _beacon_pillar.visible:
		var pulse := 0.92 + sin(_time * 4.2) * 0.14
		_beacon_pillar.scale = Vector3(pulse, 1.0, pulse)
	if _comic_timer > 0.0:
		_comic_timer -= delta
		if _comic_bubble != null:
			_comic_bubble.position.y += delta * 0.28
			if _comic_timer <= 0.0:
				_comic_bubble.visible = false


func _build_ground_and_path() -> void:
	var grass_mat := ToonMat.make(Color(0.38, 0.74, 0.32), "res://assets/textures/grass.webp", {"triplanar": true, "triplanar_scale": 0.22, "outline": false, "rim_strength": 0.10})
	var ground_body := StaticBody3D.new()
	var gcol := CollisionShape3D.new()
	var gbox := BoxShape3D.new()
	gbox.size = Vector3(80.0, 1.0, 80.0)
	gcol.shape = gbox
	gcol.position.y = -0.5
	ground_body.add_child(gcol)

	var gmesh := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(80.0, 80.0)
	gmesh.mesh = plane
	gmesh.material_override = grass_mat
	ground_body.add_child(gmesh)
	add_child(ground_body)

	var road_mat := ToonMat.make(Color(0.28, 0.30, 0.36), "res://assets/textures/cobblestone.webp", {"triplanar": true, "triplanar_scale": 0.34, "outline": false, "rim_strength": 0.06})
	var road := MeshInstance3D.new()
	var rb := BoxMesh.new()
	rb.size = Vector3(5.0, 0.06, 36.0)
	road.mesh = rb
	road.material_override = road_mat
	road.position = Vector3(0.0, 0.02, -7.0)
	add_child(road)


func _build_horizon_hills_and_flowers() -> void:
	var hill_mat := ToonMat.make(Color(0.30, 0.66, 0.28), "res://assets/textures/grass.webp", {"triplanar": true, "triplanar_scale": 0.14, "outline": false})
	for h in [
		[Vector3(-34.0, -3.5, -18.0), Vector3(1.6, 0.65, 1.2), 14.0],
		[Vector3(34.0, -3.5, -16.0), Vector3(1.6, 0.68, 1.2), 14.5],
		[Vector3(0.0, -4.5, -46.0), Vector3(2.4, 0.62, 1.2), 18.0],
		[Vector3(-32.0, -3.2, 14.0), Vector3(1.4, 0.58, 1.2), 12.0],
		[Vector3(32.0, -3.2, 14.0), Vector3(1.4, 0.58, 1.2), 12.0],
	]:
		var m := MeshInstance3D.new()
		var sp := SphereMesh.new()
		sp.radius = float(h[2])
		sp.height = float(h[2]) * 2.0
		m.mesh = sp
		m.scale = h[1]
		m.position = h[0]
		m.material_override = hill_mat
		add_child(m)

	var fcols := [Color(1.0, 0.56, 0.68), Color(0.99, 0.88, 0.28), Color(0.58, 0.77, 0.99), Color(0.99, 0.96, 0.92)]
	var spots := [
		Vector3(-5.6, 0.0, 5.0), Vector3(5.8, 0.0, 4.2), Vector3(-6.2, 0.0, -2.5),
		Vector3(6.4, 0.0, -9.5), Vector3(-5.8, 0.0, -14.2), Vector3(5.4, 0.0, -17.5),
	]
	for i in range(spots.size()):
		StorybookProps.spawn_flower(self, spots[i], fcols[i % fcols.size()])


func _build_closed_back_gate() -> void:
	var back := Node3D.new()
	back.position = Vector3(0.0, 0.0, 10.2)
	add_child(back)
	var brick_mat := ToonMat.make(Color(0.84, 0.44, 0.34), "res://assets/textures/brick.webp", {"triplanar": true, "triplanar_scale": 0.48})
	var wood_mat := ToonMat.make(Color(0.62, 0.39, 0.22), "res://assets/textures/wood_planks.webp", {"triplanar": true, "triplanar_scale": 0.42})
	for side: float in [-1.0, 1.0]:
		var pil := MeshInstance3D.new()
		var pb := BoxMesh.new()
		pb.size = Vector3(0.8, 3.2, 0.8)
		pil.mesh = pb
		pil.material_override = brick_mat
		pil.position = Vector3(side * 2.8, 1.6, 0.0)
		back.add_child(pil)
	var door := MeshInstance3D.new()
	var db := BoxMesh.new()
	db.size = Vector3(4.8, 3.08, 0.22)
	door.mesh = db
	door.material_override = wood_mat
	door.position = Vector3(0.0, 1.54, 0.0)
	back.add_child(door)
	var beam := MeshInstance3D.new()
	var bb := BoxMesh.new()
	bb.size = Vector3(6.4, 0.5, 0.6)
	beam.mesh = bb
	beam.material_override = wood_mat
	beam.position = Vector3(0.0, 3.3, 0.0)
	back.add_child(beam)


func _build_brick_fences() -> void:
	var brick_mat := ToonMat.make(Color(0.84, 0.44, 0.34), "res://assets/textures/brick.webp", {"triplanar": true, "triplanar_scale": 0.48})
	var cap_mat := ToonMat.make(Color(0.92, 0.86, 0.74), "", {"outline_width": 1.1})
	for side: float in [-1.0, 1.0]:
		var x: float = side * 8.6
		var wall := MeshInstance3D.new()
		var wb := BoxMesh.new()
		wb.size = Vector3(0.55, 1.05, 34.0)
		wall.mesh = wb
		wall.material_override = brick_mat
		wall.position = Vector3(x, 0.52, -6.4)
		add_child(wall)
		var cap := MeshInstance3D.new()
		var cb := BoxMesh.new()
		cb.size = Vector3(0.68, 0.14, 34.2)
		cap.mesh = cb
		cap.material_override = cap_mat
		cap.position = Vector3(x, 1.1, -6.4)
		add_child(cap)
		_add_box_collider(self, Vector3(0.7, 6.0, 34.4), Vector3(x, 3.0, -6.4))

	# Visual brick flanking walls sealing both gates + 360-deg horizon backdrop
	StorybookProps.build_flanking_brick_walls(self, 10.2, 2.8, 8.6, 1.05)
	StorybookProps.build_flanking_brick_walls(self, -22.5, 2.8, 8.6, 1.05)
	StorybookProps.spawn_horizon_backdrop_360(self, -24.5, 11.0, 9.0)

	# Tall invisible perimeter walls (back + flanking Pos 6 gate) so Nara can NEVER leave the map!
	_add_box_collider(self, Vector3(18.0, 6.0, 0.6), Vector3(0.0, 3.0, 10.2))
	_add_box_collider(self, Vector3(6.2, 6.0, 0.6), Vector3(-5.8, 3.0, -22.5))
	_add_box_collider(self, Vector3(6.2, 6.0, 0.6), Vector3(5.8, 3.0, -22.5))
	_add_box_collider(self, Vector3(6.5, 6.0, 0.6), Vector3(0.0, 3.0, -25.2))


func _build_zone1_cloud_pillow() -> void:
	var root := Node3D.new()
	root.position = step_positions[1]
	add_child(root)

	# Cozy pastel woven rug flush on the path
	var rug := MeshInstance3D.new()
	var rmesh := CylinderMesh.new()
	rmesh.top_radius = 1.95
	rmesh.bottom_radius = 2.02
	rmesh.height = 0.05
	rmesh.radial_segments = 24
	rug.mesh = rmesh
	rug.material_override = ToonMat.make(Color(0.98, 0.88, 0.64), "", {"outline_width": 0.9})
	rug.position = Vector3(0.0, 0.04, 0.0)
	root.add_child(rug)

	# Giant Puffy Cloud Pillow (layered soft pastel spheres + cute stitched buttons!)
	_pillow_root = Node3D.new()
	_pillow_root.position = Vector3(0.0, 0.08, 0.0)
	root.add_child(_pillow_root)

	var pmat := ToonMat.make(Color(0.98, 0.62, 0.74), "", {"outline_width": 1.3})
	var pmat_light := ToonMat.make(Color(1.0, 0.84, 0.88), "", {"outline_width": 1.1})
	var btn_mat := ToonMat.make(Color(0.99, 0.82, 0.24), "", {"outline_width": 0.8})

	var main_p := MeshInstance3D.new()
	var msp := SphereMesh.new()
	msp.radius = 0.82
	msp.height = 1.64
	main_p.mesh = msp
	main_p.scale = Vector3(1.25, 0.62, 0.95)
	main_p.material_override = pmat
	main_p.position = Vector3(0.0, 0.52, 0.0)
	_pillow_root.add_child(main_p)

	for puff in [
		[Vector3(-0.78, 0.48, 0.0), 0.44],
		[Vector3(0.78, 0.48, 0.0), 0.44],
		[Vector3(0.0, 0.72, -0.25), 0.42],
		[Vector3(-0.42, 0.66, 0.22), 0.36],
		[Vector3(0.42, 0.66, 0.22), 0.36],
	]:
		var pm := MeshInstance3D.new()
		var psp := SphereMesh.new()
		var r: float = float(puff[1])
		psp.radius = r
		psp.height = r * 2.0
		pm.mesh = psp
		pm.material_override = pmat_light
		pm.position = puff[0]
		_pillow_root.add_child(pm)

	# Stitched cute golden buttons on front of pillow
	for bx: float in [-0.28, 0.28]:
		var bt := MeshInstance3D.new()
		var bsp := SphereMesh.new()
		bsp.radius = 0.09
		bsp.height = 0.18
		bt.mesh = bsp
		bt.material_override = btn_mat
		bt.position = Vector3(bx, 0.56, 0.74)
		_pillow_root.add_child(bt)

	_add_box_collider(root, Vector3(1.65, 1.0, 1.25), Vector3(0.0, 0.5, 0.0))

	# Feather puff burst particles!
	_feather_burst = GPUParticles3D.new()
	_feather_burst.position = Vector3(0.0, 0.9, 0.0)
	_feather_burst.amount = 24
	_feather_burst.lifetime = 1.15
	_feather_burst.one_shot = true
	_feather_burst.explosiveness = 0.92
	_feather_burst.emitting = false
	var fpm := ParticleProcessMaterial.new()
	fpm.direction = Vector3(0.0, 1.0, 0.0)
	fpm.spread = 85.0
	fpm.initial_velocity_min = 2.0
	fpm.initial_velocity_max = 4.2
	fpm.gravity = Vector3(0.0, -2.2, 0.0)
	fpm.scale_min = 0.08
	fpm.scale_max = 0.16
	fpm.color = Color(1.0, 0.98, 0.94)
	_feather_burst.process_material = fpm
	var fmesh := BoxMesh.new()
	fmesh.size = Vector3(0.9, 0.25, 0.35)
	var fmat := StandardMaterial3D.new()
	fmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	fmat.albedo_color = Color(1.0, 0.98, 0.92)
	fmesh.material = fmat
	_feather_burst.draw_pass_1 = fmesh
	root.add_child(_feather_burst)

	_pillow_ring = _make_ring(Color(0.98, 0.78, 0.18), 1.95)
	root.add_child(_pillow_ring)

	_pillow_lbl = _make_label("1. PUKUL BANTAL EMPUK (0/4)\nTekan [E / Aksi] untuk menyalurkan kesal!", Vector3(0.0, 2.35, 0.0))
	root.add_child(_pillow_lbl)
	_add_zone_area(root, "step1", 2.35)


func _build_zone2_paper_table() -> void:
	var root := Node3D.new()
	root.position = step_positions[2]
	add_child(root)

	var wood_mat := ToonMat.make(Color(0.58, 0.36, 0.18), "res://assets/textures/wood_planks.webp", {"triplanar": true, "triplanar_scale": 0.45})
	var paper_mat := ToonMat.make(Color(0.99, 0.97, 0.90), "", {"outline_width": 0.9})
	var bin_mat := ToonMat.make(Color(0.22, 0.72, 0.38), "", {"outline_width": 1.1})

	# Sturdy wooden craft table
	var top := MeshInstance3D.new()
	var tb := BoxMesh.new()
	tb.size = Vector3(2.0, 0.14, 1.3)
	top.mesh = tb
	top.material_override = wood_mat
	top.position = Vector3(-0.2, 0.92, 0.0)
	root.add_child(top)
	for lx: float in [-0.95, 0.55]:
		for lz: float in [-0.48, 0.48]:
			var leg := MeshInstance3D.new()
			var lb := BoxMesh.new()
			lb.size = Vector3(0.14, 0.90, 0.14)
			leg.mesh = lb
			leg.material_override = wood_mat
			leg.position = Vector3(lx, 0.45, lz)
			root.add_child(leg)
	_add_box_collider(root, Vector3(2.05, 1.0, 1.35), Vector3(-0.2, 0.5, 0.0))

	# 3 stacked doodle paper sheets on the table
	for i in range(3):
		var sh := MeshInstance3D.new()
		var sb := BoxMesh.new()
		sb.size = Vector3(0.62, 0.035, 0.46)
		sh.mesh = sb
		sh.material_override = paper_mat
		sh.position = Vector3(-0.2, 1.02 + float(i) * 0.045, 0.0)
		sh.rotation_degrees.y = float(i - 1) * 9.0
		root.add_child(sh)
		_paper_stack.append(sh)

	# Green Recycle Bin right beside the table
	var bin_local := Vector3(1.35, 0.0, 0.05)
	_bin_pos = (step_positions[2] as Vector3) + bin_local
	var bin := MeshInstance3D.new()
	var bc := CylinderMesh.new()
	bc.top_radius = 0.44
	bc.bottom_radius = 0.34
	bc.height = 0.85
	bc.radial_segments = 12
	bin.mesh = bc
	bin.material_override = bin_mat
	bin.position = bin_local + Vector3(0.0, 0.425, 0.0)
	root.add_child(bin)
	_add_box_collider(root, Vector3(0.88, 0.90, 0.88), bin_local + Vector3(0.0, 0.45, 0.0))

	var bin_lbl := Label3D.new()
	bin_lbl.text = "DAUR ULANG"
	bin_lbl.font_size = 28
	bin_lbl.outline_size = 6
	bin_lbl.modulate = Color(0.95, 1.0, 0.92)
	bin_lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	bin_lbl.position = bin_local + Vector3(0.0, 1.15, 0.0)
	root.add_child(bin_lbl)

	# Paper scraps burst particles
	_paper_burst = GPUParticles3D.new()
	_paper_burst.position = Vector3(-0.2, 1.15, 0.0)
	_paper_burst.amount = 22
	_paper_burst.lifetime = 0.95
	_paper_burst.one_shot = true
	_paper_burst.explosiveness = 0.90
	_paper_burst.emitting = false
	var ppm := ParticleProcessMaterial.new()
	ppm.direction = Vector3(0.3, 1.0, 0.0)
	ppm.spread = 70.0
	ppm.initial_velocity_min = 1.8
	ppm.initial_velocity_max = 3.6
	ppm.gravity = Vector3(0.0, -4.5, 0.0)
	ppm.scale_min = 0.07
	ppm.scale_max = 0.14
	ppm.color = Color(0.98, 0.96, 0.86)
	_paper_burst.process_material = ppm
	var pmesh := BoxMesh.new()
	pmesh.size = Vector3(0.6, 0.08, 0.4)
	var pmat := StandardMaterial3D.new()
	pmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	pmat.albedo_color = Color(1.0, 0.97, 0.88)
	pmesh.material = pmat
	_paper_burst.draw_pass_1 = pmesh
	root.add_child(_paper_burst)

	_paper_ring = _make_ring(Color(0.34, 0.78, 0.98), 2.1)
	root.add_child(_paper_ring)

	_paper_lbl = _make_label("2. SOBEK KERTAS BEKAS (0/3)\nTekan [E / Aksi] untuk merobek & daur ulang!", Vector3(0.2, 2.45, 0.0))
	root.add_child(_paper_lbl)
	_add_zone_area(root, "step2", 2.6)


func _build_zone3_safe_board_and_exit() -> void:
	# Zone 3: Safe Choice Wooden Signboard
	var board_root := Node3D.new()
	board_root.position = step_positions[3]
	board_root.rotation_degrees.y = 18.0
	add_child(board_root)

	var wood_mat := ToonMat.make(Color(0.56, 0.34, 0.18), "res://assets/textures/wood_planks.webp", {"triplanar": true, "triplanar_scale": 0.45})
	var parch_mat := ToonMat.make(Color(0.98, 0.95, 0.86), "", {"outline_width": 1.1})
	# Place wooden posts neatly BEHIND the parchment board (z = -0.15) so they NEVER poke through the front!
	for sx: float in [-0.88, 0.88]:
		var post := MeshInstance3D.new()
		var pc := CylinderMesh.new()
		pc.top_radius = 0.095
		pc.bottom_radius = 0.11
		pc.height = 2.05
		post.mesh = pc
		post.material_override = wood_mat
		post.position = Vector3(sx, 1.02, -0.15)
		board_root.add_child(post)

	# Wooden backing frame behind the parchment sheet
	var frame := MeshInstance3D.new()
	var fb := BoxMesh.new()
	fb.size = Vector3(2.48, 1.52, 0.12)
	frame.mesh = fb
	frame.material_override = wood_mat
	frame.position = Vector3(0.0, 1.55, -0.05)
	board_root.add_child(frame)

	var panel := MeshInstance3D.new()
	var pb := BoxMesh.new()
	pb.size = Vector3(2.26, 1.32, 0.06)
	panel.mesh = pb
	panel.material_override = parch_mat
	panel.position = Vector3(0.0, 1.55, 0.03)
	board_root.add_child(panel)
	_add_box_collider(board_root, Vector3(2.5, 2.2, 0.42), Vector3(0.0, 1.1, -0.05))

	var title_lbl := Label3D.new()
	title_lbl.text = "PILIH CARA AMAN\nSALURKAN MARAH"
	title_lbl.font_size = 36
	title_lbl.outline_size = 7
	title_lbl.modulate = Color(0.26, 0.14, 0.08)
	title_lbl.outline_modulate = Color(1.0, 0.96, 0.86)
	title_lbl.position = Vector3(0.0, 1.55, 0.09)
	board_root.add_child(title_lbl)

	_board_ring = _make_ring(Color(0.98, 0.78, 0.18), 1.85)
	board_root.add_child(_board_ring)
	_board_lbl = _make_label("3. PAPAN PILIHAN AMAN\nTekan [E / Aksi] untuk memilih cara aman!", Vector3(0.0, 2.95, 0.0))
	board_root.add_child(_board_lbl)
	_add_zone_area(board_root, "step3", 2.35)

	# Pos 5 Golden Star
	var star_root := Node3D.new()
	star_root.position = star_position
	add_child(star_root)
	_star_mat = ToonMat.make(Color(0.75, 0.72, 0.64), "", {"emission_color": Color(1.0, 0.85, 0.2), "emission_energy": 0.15, "unique": true})
	_star_mesh = MeshInstance3D.new()
	_star_mesh.mesh = _make_3d_star_mesh(0.75, 0.35, 0.20)
	_star_mesh.material_override = _star_mat
	_star_mesh.position = Vector3(0.0, 2.35, 0.0)
	star_root.add_child(_star_mesh)

	var badge := Label3D.new()
	badge.text = "POS 5"
	badge.font_size = 72
	badge.outline_size = 12
	badge.modulate = Color(1.0, 0.96, 0.78)
	badge.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	badge.position = Vector3(0.0, 3.45, 0.0)
	star_root.add_child(badge)

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

	# Exit Gate -> Pos 6
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
	_gate_lbl.text = "NEXT RUTE -> POS 6\n(Selesaikan Pos 5 dulu)"
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
	for t in [
		[Vector3(-6.4, 0.0, 6.2), 1.1],
		[Vector3(6.4, 0.0, 5.8), 1.05],
		[Vector3(-6.6, 0.0, -6.0), 1.2],
		[Vector3(6.8, 0.0, -12.5), 1.15],
		[Vector3(-6.2, 0.0, -18.5), 1.15],
		[Vector3(6.2, 0.0, -18.5), 1.15],
	]:
		var tr := Node3D.new()
		tr.position = t[0]
		var sc: float = float(t[1])
		tr.scale = Vector3(sc, sc, sc)
		add_child(tr)
		var trunk := MeshInstance3D.new()
		var tc := CylinderMesh.new()
		tc.top_radius = 0.26
		tc.bottom_radius = 0.38
		tc.height = 2.2
		trunk.mesh = tc
		trunk.material_override = trunk_mat
		trunk.position = Vector3(0.0, 1.1, 0.0)
		tr.add_child(trunk)
		var cr := MeshInstance3D.new()
		var sp := SphereMesh.new()
		sp.radius = 1.45
		sp.height = 2.8
		cr.mesh = sp
		cr.material_override = leaf_mat
		cr.position = Vector3(0.0, 2.95, 0.0)
		tr.add_child(cr)


func _build_guide_arrow() -> void:
	_guide_arrow = StorybookProps.make_guide_arrow()
	add_child(_guide_arrow)


func _build_waypoint_beacon() -> void:
	_beacon_pillar = MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.75
	cyl.bottom_radius = 0.95
	cyl.height = 7.2
	cyl.radial_segments = 12
	_beacon_pillar.mesh = cyl
	var bmat := StandardMaterial3D.new()
	bmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	bmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	bmat.albedo_color = Color(1.0, 0.88, 0.28, 0.24)
	bmat.cull_mode = BaseMaterial3D.CULL_DISABLED
	_beacon_pillar.material_override = bmat
	_beacon_pillar.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_beacon_pillar)


func _make_ring(col: Color, radius: float) -> MeshInstance3D:
	var m := MeshInstance3D.new()
	var tor := TorusMesh.new()
	tor.inner_radius = radius - 0.14
	tor.outer_radius = radius
	tor.rings = 24
	tor.ring_segments = 8
	m.mesh = tor
	m.material_override = ToonMat.make(col, "", {"emission_color": col, "emission_energy": 0.42})
	m.position = Vector3(0.0, 0.08, 0.0)
	return m


func _make_label(txt: String, pos: Vector3) -> Label3D:
	var lbl := Label3D.new()
	lbl.text = txt
	lbl.font_size = 40
	lbl.outline_size = 8
	lbl.modulate = Color(1.0, 0.96, 0.78)
	lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	lbl.position = pos
	return lbl


func _add_box_collider(parent: Node3D, size: Vector3, pos: Vector3) -> void:
	var body := StaticBody3D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	var col := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = size
	col.shape = sh
	body.position = pos
	body.add_child(col)
	parent.add_child(body)


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
	area.body_entered.connect(func(body: Node3D) -> void:
		if body is NaraController:
			zone_changed.emit(zone_id, true)
	)
	area.body_exited.connect(func(body: Node3D) -> void:
		if body is NaraController:
			zone_changed.emit(zone_id, false)
	)


func _make_3d_star_mesh(outer_r: float, inner_r: float, half_t: float) -> ArrayMesh:
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
