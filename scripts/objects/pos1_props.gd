class_name Pos1Props
extends Node3D

signal player_near_star_changed(is_near: bool)
signal next_route_entered

var star_position: Vector3 = Vector3(0.0, 0.0, -7.5)
var gate_position: Vector3 = Vector3(0.0, 0.0, -14.8)
var _star_mesh: MeshInstance3D
var _star_mat: ShaderMaterial
var _ring_mesh: MeshInstance3D
var _confetti: GPUParticles3D
var _gate_left_pivot: Node3D
var _gate_right_pivot: Node3D
var _gate_blocker: StaticBody3D
var _portal_area: Area3D
var _gate_lbl: Label3D
var _gate_opened: bool = false
var _time: float = 0.0
var _clouds: Array[Node3D] = []
var _butterflies: Array[Dictionary] = []


func _ready() -> void:
	_build_ground_and_road()
	_build_horizon_hills_and_flowers()
	_build_brick_fence()
	_build_start_sign()
	_build_emotion_board()
	_build_trees_and_bushes()
	_build_star_gate()
	_build_next_route_gate()
	_clouds = StorybookProps.spawn_clouds(self)
	_butterflies = StorybookProps.spawn_butterflies(self, [
		Vector3(-4.5, 1.4, 2.0), Vector3(4.8, 1.5, -3.5)
	])
	ToonMat.optimize_tree(self)
	Game.progress_changed.connect(_refresh_star_state)
	_refresh_star_state()


func _process(delta: float) -> void:
	if Game.modal_open:
		return
	_time += delta
	StorybookProps.animate_ambient(_clouds, _butterflies, _time, delta)
	if _star_mesh != null and _star_mesh.visible and not _star_mesh.has_meta("collected"):
		_star_mesh.position.y = 2.35 + sin(_time * 2.5) * 0.14
		_star_mesh.rotation.y += delta * 1.1


func _refresh_star_state() -> void:
	if _star_mat == null:
		return
	if Game.is_station_done(1):
		_star_mat.set_shader_parameter("albedo", Color(1.0, 0.88, 0.20))
		_star_mat.set_shader_parameter("emission_color", Color(1.0, 0.85, 0.20))
		_star_mat.set_shader_parameter("emission_energy", 1.1)
		var was_open := _gate_opened
		if _confetti != null and not _gate_opened:
			_confetti.restart()
			_confetti.emitting = true
		_open_next_route_gate()
		StorybookProps.collect_and_hide_star(self, _star_mesh, was_open)


func _open_next_route_gate() -> void:
	if _gate_opened:
		return
	_gate_opened = true
	if _gate_blocker != null:
		_gate_blocker.collision_layer = 0
	if _gate_lbl != null:
		_gate_lbl.text = "NEXT RUTE -> POS 2\n(TERBUKA! JALAN MASUK)"
		_gate_lbl.modulate = Color(0.75, 1.0, 0.72)
	if _gate_left_pivot != null and _gate_right_pivot != null:
		var tw := create_tween().set_parallel(true)
		tw.tween_property(_gate_left_pivot, "rotation_degrees:y", 88.0, 0.9).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(_gate_right_pivot, "rotation_degrees:y", -88.0, 0.9).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if _portal_area != null:
		for b in _portal_area.get_overlapping_bodies():
			if b is NaraController:
				next_route_entered.emit()
				break


func _build_ground_and_road() -> void:
	var grass_mat := ToonMat.make(
		Color(0.54, 0.82, 0.40),
		"res://assets/textures/grass.webp",
		{"triplanar": true, "triplanar_scale": 0.22, "outline": false, "rim_strength": 0.12}
	)
	var ground_body := StaticBody3D.new()
	var ground_col := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(90.0, 1.0, 90.0)
	ground_col.shape = box
	ground_col.position.y = -0.5
	ground_body.add_child(ground_col)

	var ground_mesh := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(90.0, 90.0)
	ground_mesh.mesh = plane
	ground_mesh.material_override = grass_mat
	ground_body.add_child(ground_mesh)
	add_child(ground_body)

	# Asphalt road matching the infographic START avenue.
	var road_mat := ToonMat.make(
		Color(0.24, 0.27, 0.33),
		"res://assets/textures/cobblestone.webp",
		{"triplanar": true, "triplanar_scale": 0.32, "outline": false, "rim_strength": 0.08}
	)
	var road := MeshInstance3D.new()
	var rbox := BoxMesh.new()
	rbox.size = Vector3(5.4, 0.06, 36.0)
	road.mesh = rbox
	road.material_override = road_mat
	road.position = Vector3(0.0, 0.02, -4.0)
	add_child(road)

	var dash_mat := ToonMat.make(Color(0.98, 0.98, 0.96), "", {"outline": false, "rim_strength": 0.05})
	for i in range(-6, 6):
		var dash := MeshInstance3D.new()
		var dbox := BoxMesh.new()
		dbox.size = Vector3(0.22, 0.07, 1.45)
		dash.mesh = dbox
		dash.material_override = dash_mat
		dash.position = Vector3(0.0, 0.03, i * 2.8 - 2.0)
		add_child(dash)


func _add_box_collider(parent: Node3D, size: Vector3, pos: Vector3) -> void:
	var body := StaticBody3D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	col.shape = shape
	body.position = pos
	body.add_child(col)
	parent.add_child(body)


func _add_cylinder_collider(parent: Node3D, radius: float, height: float, pos: Vector3) -> void:
	var body := StaticBody3D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	var col := CollisionShape3D.new()
	var shape := CylinderShape3D.new()
	shape.radius = radius
	shape.height = height
	col.shape = shape
	body.position = pos
	body.add_child(col)
	parent.add_child(body)


func _build_brick_fence() -> void:
	var brick_mat := ToonMat.make(
		Color(0.84, 0.44, 0.34),
		"res://assets/textures/brick.webp",
		{"triplanar": true, "triplanar_scale": 0.48}
	)
	var cap_mat := ToonMat.make(Color(0.95, 0.90, 0.80))
	var iron_mat := ToonMat.make(Color(0.22, 0.25, 0.31), "", {"outline_width": 1.2})

	for side: float in [-1.0, 1.0]:
		var x: float = side * 3.5
		for i in range(6):
			var z := 7.0 - i * 4.2
			var pillar := MeshInstance3D.new()
			var pbox := BoxMesh.new()
			pbox.size = Vector3(0.55, 1.35, 0.55)
			pillar.mesh = pbox
			pillar.material_override = brick_mat
			pillar.position = Vector3(x, 0.675, z)
			add_child(pillar)
			_add_box_collider(self, Vector3(0.68, 1.5, 0.68), Vector3(x, 0.75, z))

			var cap := MeshInstance3D.new()
			var cbox := BoxMesh.new()
			cbox.size = Vector3(0.68, 0.14, 0.68)
			cap.mesh = cbox
			cap.material_override = cap_mat
			cap.position = Vector3(x, 1.42, z)
			add_child(cap)

			if i < 5:
				var rail := MeshInstance3D.new()
				var rbox := BoxMesh.new()
				rbox.size = Vector3(0.10, 0.10, 3.8)
				rail.mesh = rbox
				rail.material_override = iron_mat
				rail.position = Vector3(x, 0.95, z - 2.1)
				add_child(rail)
				_add_box_collider(self, Vector3(0.28, 1.35, 3.8), Vector3(x, 0.675, z - 2.1))

	# Visual back brick wall closing Pos 1 behind spawn + flanking wall stubs aligned flush to exit gate
	StorybookProps.build_flanking_brick_walls(self, 7.2, 0.0, 3.55, 1.05)
	StorybookProps.build_flanking_brick_walls(self, -14.8, 2.95, 3.55, 1.05)
	StorybookProps.spawn_horizon_backdrop_360(self, -15.5, 8.0, 6.5)

	# Tall invisible perimeter walls so Nara can NEVER jump over fences or walk out of Pos 1!
	_add_box_collider(self, Vector3(0.6, 6.0, 23.0), Vector3(-3.55, 3.0, -3.5))
	_add_box_collider(self, Vector3(0.6, 6.0, 23.0), Vector3(3.55, 3.0, -3.5))
	_add_box_collider(self, Vector3(8.0, 6.0, 0.6), Vector3(0.0, 3.0, 7.6))
	# Backstop behind exit gate portal so Nara cannot run past into void
	_add_box_collider(self, Vector3(8.0, 6.0, 0.6), Vector3(0.0, 3.0, -16.8))


func _build_horizon_hills_and_flowers() -> void:
	var hill_mat := ToonMat.make(
		Color(0.42, 0.74, 0.34),
		"res://assets/textures/grass.webp",
		{"triplanar": true, "triplanar_scale": 0.12, "outline": false, "rim_strength": 0.08}
	)
	var hills := [
		[Vector3(-34.0, -3.2, -26.0), Vector3(1.5, 0.65, 1.2), 14.0],
		[Vector3(34.0, -3.5, -24.0), Vector3(1.6, 0.7, 1.2), 15.0],
		[Vector3(0.0, -4.0, -42.0), Vector3(2.2, 0.6, 1.3), 18.0],
		[Vector3(-38.0, -3.0, 14.0), Vector3(1.3, 0.55, 1.2), 12.0],
		[Vector3(36.0, -3.0, 16.0), Vector3(1.4, 0.58, 1.2), 12.5]
	]
	for h in hills:
		var m := MeshInstance3D.new()
		var sph := SphereMesh.new()
		sph.radius = h[2]
		sph.height = h[2] * 2.0
		m.mesh = sph
		m.scale = h[1]
		m.position = h[0]
		m.material_override = hill_mat
		add_child(m)

	var bush_mat := ToonMat.make(Color(0.28, 0.66, 0.30), "res://assets/textures/leaf_canopy.webp", {"triplanar": true, "outline": false})
	var flower_colors := [Color(1.0, 0.56, 0.68), Color(0.99, 0.88, 0.28), Color(1.0, 0.99, 0.96), Color(0.58, 0.77, 0.99)]
	var spots := [
		Vector3(-5.8, 0.0, 4.5), Vector3(5.6, 0.0, 2.2), Vector3(-6.4, 0.0, -1.5),
		Vector3(6.2, 0.0, -3.4), Vector3(-7.0, 0.0, -11.0), Vector3(6.8, 0.0, -12.5),
		Vector3(-4.8, 0.0, 7.6), Vector3(5.0, 0.0, 7.2)
	]
	for i in range(spots.size()):
		var p: Vector3 = spots[i]
		var bush := MeshInstance3D.new()
		var bsph := SphereMesh.new()
		bsph.radius = 0.65
		bsph.height = 1.05
		bush.mesh = bsph
		bush.position = p + Vector3(0.0, 0.35, 0.0)
		bush.material_override = bush_mat
		add_child(bush)

		var flower := MeshInstance3D.new()
		var fsph := SphereMesh.new()
		fsph.radius = 0.16
		fsph.height = 0.32
		flower.mesh = fsph
		flower.position = p + Vector3(0.85, 0.16, 0.4)
		flower.material_override = ToonMat.make(flower_colors[i % flower_colors.size()], "", {"outline": false})
		add_child(flower)


func _build_start_sign() -> void:
	var wood_mat := ToonMat.make(Color(0.62, 0.39, 0.22), "res://assets/textures/wood_planks.webp", {"triplanar": true})
	var sign_mat := ToonMat.make(Color(0.24, 0.38, 0.58))

	# Positioned on the right entrance side so it never blocks the Emotion Board on the left.
	var root := Node3D.new()
	root.position = Vector3(4.3, 0.0, 5.2)
	root.rotation_degrees.y = -26.0
	add_child(root)

	var post := MeshInstance3D.new()
	var pcyl := CylinderMesh.new()
	pcyl.top_radius = 0.11
	pcyl.bottom_radius = 0.13
	pcyl.height = 2.35
	post.mesh = pcyl
	post.material_override = wood_mat
	post.position = Vector3(0.0, 1.175, -0.16)
	root.add_child(post)
	_add_cylinder_collider(root, 0.22, 2.35, Vector3(0.0, 1.175, -0.16))

	var board := MeshInstance3D.new()
	var bbox := BoxMesh.new()
	bbox.size = Vector3(2.2, 1.0, 0.18)
	board.mesh = bbox
	board.material_override = sign_mat
	board.position = Vector3(0.0, 2.35, 0.0)
	root.add_child(board)
	_add_box_collider(root, Vector3(2.25, 1.05, 0.28), Vector3(0.0, 2.35, 0.0))

	var lbl := Label3D.new()
	lbl.text = "START"
	lbl.font_size = 96
	lbl.outline_size = 14
	lbl.modulate = Color(1.0, 0.97, 0.88)
	lbl.position = Vector3(0.0, 2.35, 0.12)
	root.add_child(lbl)


func _build_emotion_board() -> void:
	var wood_mat := ToonMat.make(Color(0.66, 0.42, 0.22), "res://assets/textures/wood_planks.webp", {"triplanar": true, "triplanar_scale": 0.38})
	var paper_mat := ToonMat.make(Color(0.99, 0.94, 0.84), "res://assets/textures/parchment.webp", {"outline": false, "rim_strength": 0.1})

	var root := Node3D.new()
	root.position = Vector3(-5.0, 0.0, -5.8)
	root.rotation_degrees.y = 30.0
	add_child(root)

	# Leafy vine accents on top corners matching the infographic wooden sign.
	var vine_mat := ToonMat.make(Color(0.32, 0.72, 0.32), "res://assets/textures/leaf_canopy.webp", {"triplanar": true})
	for vx in [-1.85, 1.85]:
		var leaf := MeshInstance3D.new()
		var lsph := SphereMesh.new()
		lsph.radius = 0.42
		lsph.height = 0.65
		leaf.mesh = lsph
		leaf.position = Vector3(vx, 3.95, 0.08)
		leaf.material_override = vine_mat
		root.add_child(leaf)

	for sx in [-1.75, 1.75]:
		var post := MeshInstance3D.new()
		var cyl := CylinderMesh.new()
		cyl.top_radius = 0.13
		cyl.bottom_radius = 0.15
		cyl.height = 3.9
		post.mesh = cyl
		post.material_override = wood_mat
		post.position = Vector3(sx, 1.95, -0.18)
		root.add_child(post)

	_add_box_collider(root, Vector3(4.35, 4.2, 0.45), Vector3(0.0, 2.1, 0.0))

	var frame := MeshInstance3D.new()
	var fbox := BoxMesh.new()
	fbox.size = Vector3(4.3, 2.7, 0.24)
	frame.mesh = fbox
	frame.material_override = wood_mat
	frame.position = Vector3(0.0, 2.7, 0.0)
	root.add_child(frame)

	var inner := MeshInstance3D.new()
	var ibox := BoxMesh.new()
	ibox.size = Vector3(3.85, 2.25, 0.06)
	inner.mesh = ibox
	inner.material_override = paper_mat
	inner.position = Vector3(0.0, 2.7, 0.13)
	root.add_child(inner)

	var title := Label3D.new()
	title.text = "Emosi adalah..."
	title.font_size = 64
	title.outline_size = 10
	title.modulate = Color(0.28, 0.15, 0.08)
	title.position = Vector3(0.0, 3.42, 0.18)
	root.add_child(title)

	var body := Label3D.new()
	body.text = "suatu perasaan dan pikiran yang khas,\nsuatu keadaan biologis dan psikologis\ndan serangkaian kecenderungan\nuntuk bertindak.\n( Goleman, 2022 )"
	body.font_size = 28
	body.outline_size = 4
	body.modulate = Color(0.18, 0.12, 0.08)
	body.position = Vector3(0.0, 2.38, 0.18)
	root.add_child(body)


func _build_trees_and_bushes() -> void:
	var bark_mat := ToonMat.make(Color(0.55, 0.36, 0.22), "res://assets/textures/bark.webp", {"triplanar": true})
	var leaf_mat := ToonMat.make(Color(0.32, 0.72, 0.34), "res://assets/textures/leaf_canopy.webp", {"triplanar": true, "triplanar_scale": 0.45})

	var coords := [
		Vector3(-9.5, 0.0, 2.0),
		Vector3(9.2, 0.0, 3.5),
		Vector3(-10.2, 0.0, -11.5),
		Vector3(8.6, 0.0, -9.8),
		Vector3(0.5, 0.0, -21.0)
	]

	for p in coords:
		var tree := Node3D.new()
		tree.position = p
		add_child(tree)

		var trunk := MeshInstance3D.new()
		var cyl := CylinderMesh.new()
		cyl.top_radius = 0.28
		cyl.bottom_radius = 0.42
		cyl.height = 2.8
		trunk.mesh = cyl
		trunk.material_override = bark_mat
		trunk.position.y = 1.4
		tree.add_child(trunk)
		_add_cylinder_collider(tree, 0.46, 3.0, Vector3(0.0, 1.5, 0.0))

		var puffs := [
			[Vector3(0, 3.4, 0), 1.6],
			[Vector3(-1.0, 2.9, 0.4), 1.2],
			[Vector3(1.0, 3.0, -0.3), 1.25],
			[Vector3(0.1, 4.3, 0.2), 1.05]
		]
		for puff in puffs:
			var m := MeshInstance3D.new()
			var sph := SphereMesh.new()
			sph.radius = puff[1]
			sph.height = puff[1] * 2.0
			m.mesh = sph
			m.material_override = leaf_mat
			m.position = puff[0]
			tree.add_child(m)


func _make_3d_star_mesh(outer_r: float = 0.72, inner_r: float = 0.34, half_depth: float = 0.16) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var pts: Array[Vector2] = []
	for i in range(10):
		var r := outer_r if i % 2 == 0 else inner_r
		var angle := float(i) * PI / 5.0 + PI / 2.0
		pts.append(Vector2(cos(angle) * r, sin(angle) * r))

	var front_c := Vector3(0.0, 0.0, half_depth)
	var back_c := Vector3(0.0, 0.0, -half_depth)

	for i in range(10):
		var a := pts[i]
		var b := pts[(i + 1) % 10]
		var af := Vector3(a.x, a.y, half_depth * 0.55)
		var bf := Vector3(b.x, b.y, half_depth * 0.55)
		var ab := Vector3(a.x, a.y, -half_depth * 0.55)
		var bb := Vector3(b.x, b.y, -half_depth * 0.55)

		# Front cap
		st.add_vertex(front_c)
		st.add_vertex(bf)
		st.add_vertex(af)
		# Back cap
		st.add_vertex(back_c)
		st.add_vertex(ab)
		st.add_vertex(bb)
		# Rim
		st.add_vertex(af)
		st.add_vertex(bf)
		st.add_vertex(bb)
		st.add_vertex(af)
		st.add_vertex(bb)
		st.add_vertex(ab)

	st.generate_normals()
	return st.commit()


func _build_star_gate() -> void:
	var root := Node3D.new()
	root.position = star_position
	add_child(root)

	_star_mat = ToonMat.make(
		Color(0.99, 0.80, 0.12),
		"",
		{"emission_color": Color(0.98, 0.65, 0.08), "emission_energy": 0.38, "unique": true}
	)
	_star_mesh = MeshInstance3D.new()
	_star_mesh.mesh = _make_3d_star_mesh(0.75, 0.35, 0.20)
	_star_mesh.material_override = _star_mat
	_star_mesh.position = Vector3(0.0, 2.35, 0.0)
	root.add_child(_star_mesh)

	var badge_lbl := Label3D.new()
	badge_lbl.text = "POS 1"
	badge_lbl.font_size = 72
	badge_lbl.outline_size = 12
	badge_lbl.modulate = Color(1.0, 0.96, 0.78)
	badge_lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	badge_lbl.position = Vector3(0.0, 3.45, 0.0)
	root.add_child(badge_lbl)

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
	root.add_child(_confetti)

	_ring_mesh = MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 1.45
	torus.outer_radius = 1.75
	_ring_mesh.mesh = torus
	_ring_mesh.material_override = ToonMat.make(Color(0.98, 0.78, 0.16), "", {"outline": false, "emission_energy": 0.3})
	_ring_mesh.position = Vector3(0.0, 0.08, 0.0)
	root.add_child(_ring_mesh)

	var area := Area3D.new()
	area.collision_layer = 4
	area.collision_mask = 2
	var col := CollisionShape3D.new()
	var cyl := CylinderShape3D.new()
	cyl.radius = 2.4
	cyl.height = 2.5
	col.shape = cyl
	col.position.y = 1.25
	area.add_child(col)
	root.add_child(area)

	area.body_entered.connect(func(body: Node3D) -> void:
		if body is NaraController:
			player_near_star_changed.emit(true)
	)
	area.body_exited.connect(func(body: Node3D) -> void:
		if body is NaraController:
			player_near_star_changed.emit(false)
	)


func _build_next_route_gate() -> void:
	var root := Node3D.new()
	root.position = gate_position
	add_child(root)

	var brick_mat := ToonMat.make(Color(0.84, 0.44, 0.34), "res://assets/textures/brick.webp", {"triplanar": true, "triplanar_scale": 0.48})
	var wood_mat := ToonMat.make(Color(0.62, 0.39, 0.22), "res://assets/textures/wood_planks.webp", {"triplanar": true, "triplanar_scale": 0.42})
	var gold_mat := ToonMat.make(Color(0.95, 0.74, 0.18), "", {"outline_width": 1.2})

	# Left & Right Archway Pillars
	for side: float in [-1.0, 1.0]:
		var x: float = side * 2.95
		var pil := MeshInstance3D.new()
		var pbox := BoxMesh.new()
		pbox.size = Vector3(0.85, 3.6, 0.85)
		pil.mesh = pbox
		pil.material_override = brick_mat
		pil.position = Vector3(x, 1.8, 0.0)
		root.add_child(pil)
		_add_box_collider(root, Vector3(0.95, 3.8, 0.95), Vector3(x, 1.9, 0.0))

	# Top Wooden Arch Beam
	var beam := MeshInstance3D.new()
	var bbox := BoxMesh.new()
	bbox.size = Vector3(6.8, 0.55, 0.65)
	beam.mesh = bbox
	beam.material_override = wood_mat
	beam.position = Vector3(0.0, 3.65, 0.0)
	root.add_child(beam)

	# Signboard on top of the gate
	var sign_bg := MeshInstance3D.new()
	var sbox := BoxMesh.new()
	sbox.size = Vector3(4.2, 1.1, 0.18)
	sign_bg.mesh = sbox
	sign_bg.material_override = ToonMat.make(Color(0.24, 0.50, 0.82), "", {"outline_width": 1.4})
	sign_bg.position = Vector3(0.0, 4.45, 0.05)
	root.add_child(sign_bg)

	_gate_lbl = Label3D.new()
	_gate_lbl.text = "NEXT RUTE -> POS 2\n(Selesaikan Pos 1 Dulu)"
	_gate_lbl.font_size = 44
	_gate_lbl.outline_size = 8
	_gate_lbl.modulate = Color(1.0, 0.96, 0.82)
	_gate_lbl.position = Vector3(0.0, 4.45, 0.17)
	root.add_child(_gate_lbl)

	# Swing Doors (Left & Right Pivots)
	_gate_left_pivot = Node3D.new()
	_gate_left_pivot.position = Vector3(-2.5, 0.0, 0.0)
	root.add_child(_gate_left_pivot)

	var left_door := MeshInstance3D.new()
	var dbox := BoxMesh.new()
	dbox.size = Vector3(2.45, 2.35, 0.18)
	left_door.mesh = dbox
	left_door.material_override = wood_mat
	left_door.position = Vector3(1.25, 1.2, 0.0)
	_gate_left_pivot.add_child(left_door)

	var left_knob := MeshInstance3D.new()
	var ksph := SphereMesh.new()
	ksph.radius = 0.14
	ksph.height = 0.28
	left_knob.mesh = ksph
	left_knob.material_override = gold_mat
	left_knob.position = Vector3(2.2, 1.2, 0.14)
	_gate_left_pivot.add_child(left_knob)

	_gate_right_pivot = Node3D.new()
	_gate_right_pivot.position = Vector3(2.5, 0.0, 0.0)
	root.add_child(_gate_right_pivot)

	var right_door := MeshInstance3D.new()
	right_door.mesh = dbox
	right_door.material_override = wood_mat
	right_door.position = Vector3(-1.25, 1.2, 0.0)
	_gate_right_pivot.add_child(right_door)

	var right_knob := MeshInstance3D.new()
	right_knob.mesh = ksph
	right_knob.material_override = gold_mat
	right_knob.position = Vector3(-2.2, 1.2, 0.14)
	_gate_right_pivot.add_child(right_knob)

	# Solid Blocker while closed
	_gate_blocker = StaticBody3D.new()
	_gate_blocker.collision_layer = 1
	_gate_blocker.collision_mask = 0
	var bcol := CollisionShape3D.new()
	var bshape := BoxShape3D.new()
	bshape.size = Vector3(5.2, 2.8, 0.45)
	bcol.shape = bshape
	_gate_blocker.position = Vector3(0.0, 1.4, 0.0)
	_gate_blocker.add_child(bcol)
	root.add_child(_gate_blocker)

	# Trigger Zone spanning doorway and just beyond
	_portal_area = Area3D.new()
	_portal_area.collision_layer = 4
	_portal_area.collision_mask = 2
	var pcol := CollisionShape3D.new()
	var pshape := BoxShape3D.new()
	pshape.size = Vector3(4.8, 3.2, 2.6)
	pcol.shape = pshape
	pcol.position = Vector3(0.0, 1.4, -0.3)
	_portal_area.add_child(pcol)
	root.add_child(_portal_area)

	_portal_area.body_entered.connect(func(body: Node3D) -> void:
		if body is NaraController and _gate_opened:
			next_route_entered.emit()
	)
