class_name Pos2Props
extends Node3D

signal near_friend_changed(friend_id: String)
signal next_route_entered

var star_position: Vector3 = Vector3(0.0, 0.0, -5.2)
var exit_gate_position: Vector3 = Vector3(0.0, 0.0, -15.8)

var _star_mesh: MeshInstance3D
var _star_mat: ShaderMaterial
var _confetti: GPUParticles3D
var _gate_left_pivot: Node3D
var _gate_right_pivot: Node3D
var _gate_blocker: StaticBody3D
var _portal_area: Area3D
var _gate_lbl: Label3D
var _gate_opened: bool = false
var _time: float = 0.0

var _friend_nodes: Dictionary = {}
var _friend_badges: Dictionary = {}
var _friend_rings: Dictionary = {}
var _friend_positions: Dictionary = {}
var _solved_friends: Dictionary = {}
var _sedih_tear: MeshInstance3D
var _terkejut_balloon: Node3D
var _balloon_popped: bool = false
var _guide_arrow: Node3D
var _clouds: Array[Node3D] = []
var _butterflies: Array[Dictionary] = []


func _ready() -> void:
	_build_ground_and_road()
	_build_horizon_hills_and_flowers()
	_build_closed_back_gate()
	_build_brick_fences()
	_build_title_board()
	_build_playground_slide()
	_build_trash_bins()
	_build_park_bench()
	_build_trees_and_bushes()
	_build_six_emotion_friends()
	_build_star_and_exit_gate()
	_build_guide_arrow()
	_clouds = StorybookProps.spawn_clouds(self)
	_butterflies = StorybookProps.spawn_butterflies(self, [
		Vector3(-5.5, 1.4, 2.0), Vector3(5.8, 1.6, -2.5), Vector3(-4.2, 1.5, -7.5)
	])
	ToonMat.optimize_tree(self)


func _process(delta: float) -> void:
	if Game.modal_open:
		return
	_time += delta
	StorybookProps.animate_ambient(_clouds, _butterflies, _time, delta)
	if _star_mesh != null and _star_mesh.visible and not _star_mesh.has_meta("collected"):
		_star_mesh.position.y = 2.35 + sin(_time * 2.5) * 0.14
		_star_mesh.rotation.y += delta * 1.1

	# Smooth articulated per-emotion animations for all 6 friends
	for id: String in _friend_nodes.keys():
		var rig: Dictionary = _friend_nodes[id]
		var body: Node3D = rig["body"] as Node3D
		var head: Node3D = rig["head"] as Node3D
		var la: Node3D = rig["l_arm"] as Node3D
		var ra: Node3D = rig["r_arm"] as Node3D
		var ll: Node3D = rig["l_leg"] as Node3D
		var rl: Node3D = rig["r_leg"] as Node3D
		if body == null:
			continue

		match id:
			"bahagia":
				# Joyful rhythmic jump + waving both arms OUTWARD & UP overhead + happy head sway
				var hop := absf(sin(_time * 4.6))
				body.position.y = hop * 0.24
				head.rotation_degrees.z = sin(_time * 4.6) * 10.0
				la.rotation_degrees = Vector3(-16.0, 0.0, -132.0 - sin(_time * 9.2) * 16.0)
				ra.rotation_degrees = Vector3(-16.0, 0.0, 132.0 + sin(_time * 9.2) * 16.0)
				ll.rotation_degrees.x = sin(_time * 4.6) * 20.0
				rl.rotation_degrees.x = -sin(_time * 4.6) * 20.0
			"sedih":
				if _solved_friends.has("sedih"):
					# Cheered up after Nara's empathy!
					body.position.y = absf(sin(_time * 3.2)) * 0.06
					head.rotation_degrees = Vector3(-4.0, sin(_time * 2.0) * 8.0, 0.0)
					la.rotation_degrees = Vector3(-16.0, 0.0, -32.0)
					ra.rotation_degrees = Vector3(-16.0, 0.0, 32.0)
				else:
					# Slow sighing breath, head gently looking down, arms slightly forward
					var sigh := sin(_time * 1.8)
					body.position.y = sigh * 0.015
					head.rotation_degrees = Vector3(16.0 + sigh * 4.0, sin(_time * 0.9) * 6.0, 0.0)
					la.rotation_degrees = Vector3(-24.0 + sigh * 6.0, 0.0, -14.0)
					ra.rotation_degrees = Vector3(-58.0 + sin(_time * 2.6) * 10.0, 0.0, 14.0)
			"marah":
				# Alternating foot stomp, pumping fists forward, sharp head shake
				var stomp := sin(_time * 6.5)
				body.position.y = absf(stomp) * 0.06
				head.rotation_degrees = Vector3(6.0, sin(_time * 8.0) * 10.0, 0.0)
				la.rotation_degrees = Vector3(-55.0 + stomp * 24.0, 0.0, -20.0)
				ra.rotation_degrees = Vector3(-55.0 - stomp * 24.0, 0.0, 20.0)
				ll.rotation_degrees.x = maxf(0.0, stomp) * 26.0
				rl.rotation_degrees.x = maxf(0.0, -stomp) * 26.0
			"takut":
				# Subtle nervous shiver, defensive raised arms in front of chest, darting glance
				body.position.x = sin(_time * 22.0) * 0.025
				body.position.y = -0.04 + absf(sin(_time * 3.0)) * 0.02
				head.rotation_degrees = Vector3(-4.0, sin(_time * 2.2) * 24.0, 0.0)
				la.rotation_degrees = Vector3(-68.0 + sin(_time * 18.0) * 4.0, 0.0, -14.0)
				ra.rotation_degrees = Vector3(-68.0 - sin(_time * 18.0) * 4.0, 0.0, 14.0)
			"jijik":
				# Leaning back, waving right hand outward in front of nose ("bau!")
				var wave := sin(_time * 7.0)
				body.rotation_degrees.x = -8.0 + sin(_time * 2.4) * 2.5
				head.rotation_degrees = Vector3(-6.0, 18.0 + sin(_time * 2.0) * 6.0, -6.0)
				la.rotation_degrees = Vector3(-16.0, 0.0, -24.0)
				ra.rotation_degrees = Vector3(-78.0, wave * 20.0, 20.0 + wave * 12.0)
			"terkejut":
				# Periodic startled jump with arms flying OUTWARD & WIDE open
				var pulse := pow(maxf(0.0, sin(_time * 2.8)), 3.0)
				body.position.y = pulse * 0.30
				head.rotation_degrees.x = -12.0 * pulse
				la.rotation_degrees = Vector3(-18.0, 0.0, -38.0 - pulse * 78.0)
				ra.rotation_degrees = Vector3(-18.0, 0.0, 38.0 + pulse * 78.0)
				ll.rotation_degrees.x = -18.0 * pulse
				rl.rotation_degrees.x = 18.0 * pulse


func mark_friend_solved(friend_id: String, emotion_label: String) -> void:
	_solved_friends[friend_id] = true
	if friend_id == "sedih" and _sedih_tear != null:
		_sedih_tear.visible = false
	if _friend_badges.has(friend_id):
		var lbl: Label3D = _friend_badges[friend_id] as Label3D
		lbl.text = "✓ " + emotion_label
		lbl.modulate = Color(0.55, 1.0, 0.62)
	if _friend_rings.has(friend_id):
		var ring: MeshInstance3D = _friend_rings[friend_id] as MeshInstance3D
		ring.material_override = ToonMat.make(Color(0.16, 0.78, 0.35), "", {"outline": false, "emission_energy": 0.3})


func pop_terkejut_balloon() -> bool:
	if _balloon_popped or _terkejut_balloon == null:
		return false
	_balloon_popped = true
	var tw := create_tween()
	tw.tween_property(_terkejut_balloon, "scale", Vector3(1.5, 1.5, 1.5), 0.08)
	tw.tween_property(_terkejut_balloon, "scale", Vector3(0.01, 0.01, 0.01), 0.10)
	tw.tween_callback(func() -> void:
		if is_instance_valid(_terkejut_balloon):
			_terkejut_balloon.visible = false
	)
	return true


func update_guide_arrow(player_pos: Vector3, target_pos: Vector3) -> void:
	if _guide_arrow == null:
		return
	var diff := target_pos - player_pos
	diff.y = 0.0
	if diff.length() < 2.1:
		_guide_arrow.visible = false
		return
	_guide_arrow.visible = true
	var dir := diff.normalized()
	_guide_arrow.global_position = Vector3(player_pos.x, 0.22 + sin(_time * 4.5) * 0.04, player_pos.z) + dir * 1.35
	_guide_arrow.rotation.y = atan2(dir.x, dir.z)


func _build_guide_arrow() -> void:
	_guide_arrow = StorybookProps.make_guide_arrow()
	add_child(_guide_arrow)


func get_next_unsolved_pos() -> Vector3:
	var order := ["sedih", "marah", "takut", "bahagia", "jijik", "terkejut"]
	for id: String in order:
		if not _solved_friends.has(id) and _friend_positions.has(id):
			return _friend_positions[id]
	return exit_gate_position + Vector3(0.0, 0.0, -1.0)


func unlock_exit_gate() -> void:
	if _star_mat != null:
		_star_mat.set_shader_parameter("albedo", Color(0.16, 0.78, 0.35))
		_star_mat.set_shader_parameter("emission_color", Color(0.16, 0.78, 0.35))
		_star_mat.set_shader_parameter("emission_energy", 0.38)
	if _confetti != null:
		_confetti.restart()
		_confetti.emitting = true
	StorybookProps.collect_and_hide_star(self, _star_mesh, _gate_opened)
	if _gate_opened:
		return
	_gate_opened = true
	if _gate_blocker != null:
		_gate_blocker.collision_layer = 0
	if _gate_lbl != null:
		_gate_lbl.text = "NEXT RUTE -> POS 3\n(TERBUKA! SELESAI POS 2)"
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

	# Central cobblestone garden walkway
	var road_mat := ToonMat.make(
		Color(0.24, 0.27, 0.33),
		"res://assets/textures/cobblestone.webp",
		{"triplanar": true, "triplanar_scale": 0.32, "outline": false, "rim_strength": 0.08}
	)
	var road := MeshInstance3D.new()
	var rbox := BoxMesh.new()
	rbox.size = Vector3(4.6, 0.06, 29.0)
	road.mesh = rbox
	road.material_override = road_mat
	road.position = Vector3(0.0, 0.02, -3.5)
	add_child(road)

	var dash_mat := ToonMat.make(Color(0.98, 0.98, 0.96), "", {"outline": false, "rim_strength": 0.05})
	for i in range(-5, 5):
		var dash := MeshInstance3D.new()
		var dbox := BoxMesh.new()
		dbox.size = Vector3(0.20, 0.07, 1.35)
		dash.mesh = dbox
		dash.material_override = dash_mat
		dash.position = Vector3(0.0, 0.03, i * 2.8 - 2.5)
		add_child(dash)


func _build_closed_back_gate() -> void:
	# Closed one-way gate behind Nara (cannot go back to Pos 1 -> lightweight!)
	var root := Node3D.new()
	root.position = Vector3(0.0, 0.0, 9.2)
	add_child(root)

	var brick_mat := ToonMat.make(Color(0.84, 0.44, 0.34), "res://assets/textures/brick.webp", {"triplanar": true, "triplanar_scale": 0.48})
	var wood_mat := ToonMat.make(Color(0.56, 0.34, 0.18), "res://assets/textures/wood_planks.webp", {"triplanar": true, "triplanar_scale": 0.42})

	for side: float in [-1.0, 1.0]:
		var pil := MeshInstance3D.new()
		var pbox := BoxMesh.new()
		pbox.size = Vector3(0.85, 3.3, 0.85)
		pil.mesh = pbox
		pil.material_override = brick_mat
		pil.position = Vector3(side * 2.8, 1.65, 0.0)
		root.add_child(pil)

	var closed_door := MeshInstance3D.new()
	var dbox := BoxMesh.new()
	dbox.size = Vector3(4.9, 3.15, 0.24)
	closed_door.mesh = dbox
	closed_door.material_override = wood_mat
	closed_door.position = Vector3(0.0, 1.58, 0.0)
	root.add_child(closed_door)

	var beam := MeshInstance3D.new()
	var bbox := BoxMesh.new()
	bbox.size = Vector3(6.5, 0.48, 0.62)
	beam.mesh = bbox
	beam.material_override = wood_mat
	beam.position = Vector3(0.0, 3.35, 0.0)
	root.add_child(beam)

	var lbl := Label3D.new()
	lbl.text = "POS 1 SELESAI\n(Gerbang Satu Arah)"
	lbl.font_size = 38
	lbl.outline_size = 6
	lbl.modulate = Color(1.0, 0.94, 0.78)
	lbl.position = Vector3(0.0, 1.5, -0.18)
	lbl.rotation_degrees.y = 180.0
	root.add_child(lbl)

	# Solid wide boundary collider behind Pos 2
	_add_box_collider(root, Vector3(26.0, 3.5, 0.8), Vector3(0.0, 1.75, 0.0))


func _build_brick_fences() -> void:
	# Outer perimeter brick fence framing the playground nicely
	var brick_mat := ToonMat.make(Color(0.84, 0.44, 0.34), "res://assets/textures/brick.webp", {"triplanar": true, "triplanar_scale": 0.48})
	var cap_mat := ToonMat.make(Color(0.95, 0.90, 0.80))
	var iron_mat := ToonMat.make(Color(0.22, 0.25, 0.31), "", {"outline_width": 1.2})

	for side: float in [-1.0, 1.0]:
		var x: float = side * 11.2
		for i in range(7):
			var z: float = 8.5 - i * 4.0
			var pil := MeshInstance3D.new()
			var pbox := BoxMesh.new()
			pbox.size = Vector3(0.6, 1.45, 0.6)
			pil.mesh = pbox
			pil.material_override = brick_mat
			pil.position = Vector3(x, 0.725, z)
			add_child(pil)
			_add_box_collider(self, Vector3(0.7, 1.6, 0.7), Vector3(x, 0.8, z))

			var cap := MeshInstance3D.new()
			var cbox := BoxMesh.new()
			cbox.size = Vector3(0.72, 0.14, 0.72)
			cap.mesh = cbox
			cap.material_override = cap_mat
			cap.position = Vector3(x, 1.52, z)
			add_child(cap)

			if i < 6:
				var rail := MeshInstance3D.new()
				var rbox := BoxMesh.new()
				rbox.size = Vector3(0.10, 0.10, 3.6)
				rail.mesh = rbox
				rail.material_override = iron_mat
				rail.position = Vector3(x, 1.0, z - 2.0)
				add_child(rail)
				_add_box_collider(self, Vector3(0.32, 1.5, 3.6), Vector3(x, 0.75, z - 2.0))

	# Visual brick walls sealing left & right of back gate and exit gate + 360-deg horizon hills
	StorybookProps.build_flanking_brick_walls(self, 9.2, 2.8, 11.2, 1.15)
	StorybookProps.build_flanking_brick_walls(self, -15.8, 2.8, 11.2, 1.15)
	StorybookProps.spawn_horizon_backdrop_360(self, -17.5, 10.0, 11.5)

	# Tall invisible perimeter walls so Nara can NEVER escape Pos 2!
	_add_box_collider(self, Vector3(0.6, 6.0, 26.0), Vector3(-11.2, 3.0, -3.6))
	_add_box_collider(self, Vector3(0.6, 6.0, 26.0), Vector3(11.2, 3.0, -3.6))
	_add_box_collider(self, Vector3(23.5, 6.0, 0.6), Vector3(0.0, 3.0, 8.8))
	# Flanking walls left & right of exit gate (z = -15.8), leaving doorway x = -2.5..2.5 open
	_add_box_collider(self, Vector3(8.6, 6.0, 0.6), Vector3(-7.0, 3.0, -15.8))
	_add_box_collider(self, Vector3(8.6, 6.0, 0.6), Vector3(7.0, 3.0, -15.8))
	_add_box_collider(self, Vector3(6.5, 6.0, 0.6), Vector3(0.0, 3.0, -18.5))


func _build_title_board() -> void:
	# Hanging wooden sign "Jenis Emosi Dasar" matching the infographic
	var wood_mat := ToonMat.make(Color(0.66, 0.42, 0.22), "res://assets/textures/wood_planks.webp", {"triplanar": true, "triplanar_scale": 0.38})
	var paper_mat := ToonMat.make(Color(0.99, 0.94, 0.84), "res://assets/textures/parchment.webp", {"outline": false, "rim_strength": 0.1})
	var vine_mat := ToonMat.make(Color(0.32, 0.72, 0.32), "res://assets/textures/leaf_canopy.webp", {"triplanar": true})

	var root := Node3D.new()
	root.position = Vector3(-6.2, 0.0, 2.2)
	root.rotation_degrees.y = 22.0
	add_child(root)

	for sx: float in [-1.85, 1.85]:
		var post := MeshInstance3D.new()
		var cyl := CylinderMesh.new()
		cyl.top_radius = 0.12
		cyl.bottom_radius = 0.14
		cyl.height = 3.6
		post.mesh = cyl
		post.material_override = wood_mat
		post.position = Vector3(sx, 1.8, -0.18)
		root.add_child(post)

		var leaf := MeshInstance3D.new()
		var lsph := SphereMesh.new()
		lsph.radius = 0.36
		lsph.height = 0.56
		leaf.mesh = lsph
		leaf.material_override = vine_mat
		leaf.position = Vector3(sx, 3.62, 0.04)
		root.add_child(leaf)

	_add_box_collider(root, Vector3(4.5, 3.7, 0.45), Vector3(0.0, 1.85, 0.0))

	var frame := MeshInstance3D.new()
	var fbox := BoxMesh.new()
	fbox.size = Vector3(4.4, 2.0, 0.22)
	frame.mesh = fbox
	frame.material_override = wood_mat
	frame.position = Vector3(0.0, 2.55, 0.0)
	root.add_child(frame)

	var inner := MeshInstance3D.new()
	var ibox := BoxMesh.new()
	ibox.size = Vector3(4.0, 1.6, 0.06)
	inner.mesh = ibox
	inner.material_override = paper_mat
	inner.position = Vector3(0.0, 2.55, 0.12)
	root.add_child(inner)

	var title := Label3D.new()
	title.text = "POS 2: Jenis Emosi Dasar"
	title.font_size = 44
	title.outline_size = 8
	title.modulate = Color(0.28, 0.15, 0.08)
	title.position = Vector3(0.0, 2.86, 0.18)
	root.add_child(title)

	var sub := Label3D.new()
	sub.text = "Sapa 6 teman di taman bermain ini\ndan kenali emosi yang mereka rasakan!"
	sub.font_size = 24
	sub.outline_size = 4
	sub.modulate = Color(0.22, 0.16, 0.10)
	sub.position = Vector3(0.0, 2.22, 0.18)
	root.add_child(sub)


func _build_playground_slide() -> void:
	# Iconic blue & yellow slide from infographic Pos 2
	var root := Node3D.new()
	root.position = Vector3(7.2, 0.0, -3.5)
	root.rotation_degrees.y = -32.0
	add_child(root)

	var yellow_mat := ToonMat.make(Color(0.98, 0.80, 0.16))
	var blue_mat := ToonMat.make(Color(0.20, 0.58, 0.90))
	var red_mat := ToonMat.make(Color(0.90, 0.26, 0.28))

	# Platform legs
	for lx: float in [-0.75, 0.75]:
		for lz: float in [-0.75, 0.75]:
			var leg := MeshInstance3D.new()
			var cyl := CylinderMesh.new()
			cyl.top_radius = 0.09
			cyl.bottom_radius = 0.09
			cyl.height = 2.2
			leg.mesh = cyl
			leg.material_override = red_mat
			leg.position = Vector3(lx, 1.1, lz)
			root.add_child(leg)

	# Top platform
	var plat := MeshInstance3D.new()
	var pbox := BoxMesh.new()
	pbox.size = Vector3(1.8, 0.22, 1.8)
	plat.mesh = pbox
	plat.material_override = yellow_mat
	plat.position = Vector3(0.0, 2.2, 0.0)
	root.add_child(plat)

	# Angled slide chute
	var chute := MeshInstance3D.new()
	var cbox := BoxMesh.new()
	cbox.size = Vector3(1.15, 0.16, 3.4)
	chute.mesh = cbox
	chute.material_override = blue_mat
	chute.position = Vector3(0.0, 1.15, 2.05)
	chute.rotation_degrees.x = 34.0
	root.add_child(chute)

	# Slide side rails
	for sx: float in [-0.58, 0.58]:
		var rail := MeshInstance3D.new()
		var rbox := BoxMesh.new()
		rbox.size = Vector3(0.12, 0.36, 3.4)
		rail.mesh = rbox
		rail.material_override = yellow_mat
		rail.position = Vector3(sx, 1.32, 2.05)
		rail.rotation_degrees.x = 34.0
		root.add_child(rail)

	_add_box_collider(root, Vector3(2.2, 2.5, 4.8), Vector3(0.0, 1.25, 1.2))


func _build_trash_bins() -> void:
	# 3 colorful recycling/trash bins (red, yellow, green) matching the Jijik spot
	var root := Node3D.new()
	root.position = Vector3(-7.4, 0.0, -4.6)
	root.rotation_degrees.y = 28.0
	add_child(root)

	var bin_colors := [Color(0.88, 0.24, 0.24), Color(0.96, 0.78, 0.14), Color(0.20, 0.68, 0.34)]
	var lid_mat := ToonMat.make(Color(0.24, 0.26, 0.30))

	for i in range(3):
		var bx: float = (i - 1) * 1.05
		var bin := MeshInstance3D.new()
		var bmesh := CylinderMesh.new()
		bmesh.top_radius = 0.36
		bmesh.bottom_radius = 0.30
		bmesh.height = 1.05
		bin.mesh = bmesh
		bin.material_override = ToonMat.make(bin_colors[i])
		bin.position = Vector3(bx, 0.525, 0.0)
		root.add_child(bin)

		var lid := MeshInstance3D.new()
		var lmesh := CylinderMesh.new()
		lmesh.top_radius = 0.32
		lmesh.bottom_radius = 0.40
		lmesh.height = 0.16
		lid.mesh = lmesh
		lid.material_override = lid_mat
		lid.position = Vector3(bx, 1.12, 0.0)
		root.add_child(lid)

	# Trash bag next to bins + subtle green stink puffs above bins
	var bag := MeshInstance3D.new()
	var bsph := SphereMesh.new()
	bsph.radius = 0.36
	bsph.height = 0.62
	bag.mesh = bsph
	bag.material_override = ToonMat.make(Color(0.18, 0.20, 0.24))
	bag.position = Vector3(1.65, 0.30, 0.35)
	root.add_child(bag)

	var stink_mat := ToonMat.make(Color(0.62, 0.88, 0.32), "", {"outline": false, "emission_color": Color(0.55, 0.85, 0.25), "emission_energy": 0.22})
	for sp_pos in [Vector3(-0.4, 1.55, 0.0), Vector3(0.3, 1.85, 0.1), Vector3(0.9, 1.48, -0.1)]:
		var puff := MeshInstance3D.new()
		var psph := SphereMesh.new()
		psph.radius = 0.13
		psph.height = 0.26
		puff.mesh = psph
		puff.material_override = stink_mat
		puff.position = sp_pos
		root.add_child(puff)

	_add_box_collider(root, Vector3(3.8, 1.4, 1.2), Vector3(0.2, 0.7, 0.0))


func _build_park_bench() -> void:
	var root := Node3D.new()
	root.position = Vector3(-6.4, 0.0, 0.2)
	root.rotation_degrees.y = 75.0
	add_child(root)

	var wood_mat := ToonMat.make(Color(0.68, 0.42, 0.22), "res://assets/textures/wood_planks.webp", {"triplanar": true})
	var iron_mat := ToonMat.make(Color(0.20, 0.22, 0.26))

	var seat := MeshInstance3D.new()
	var sbox := BoxMesh.new()
	sbox.size = Vector3(2.2, 0.14, 0.68)
	seat.mesh = sbox
	seat.material_override = wood_mat
	seat.position = Vector3(0.0, 0.58, 0.0)
	root.add_child(seat)

	var back := MeshInstance3D.new()
	var bbox := BoxMesh.new()
	bbox.size = Vector3(2.2, 0.52, 0.12)
	back.mesh = bbox
	back.material_override = wood_mat
	back.position = Vector3(0.0, 0.96, -0.32)
	back.rotation_degrees.x = -12.0
	root.add_child(back)

	for lx: float in [-0.88, 0.88]:
		var leg := MeshInstance3D.new()
		var lbox := BoxMesh.new()
		lbox.size = Vector3(0.12, 0.58, 0.62)
		leg.mesh = lbox
		leg.material_override = iron_mat
		leg.position = Vector3(lx, 0.29, 0.0)
		root.add_child(leg)

	_add_box_collider(root, Vector3(2.3, 1.2, 0.85), Vector3(0.0, 0.6, 0.0))


func _build_six_emotion_friends() -> void:
	var friends := [
		{
			"id": "sedih", "badge": "1. Sedih",
			"pos": Vector3(-4.5, 0.0, 0.2), "yaw": 68.0,
			"shirt": Color(0.64, 0.52, 0.94), "hair": Color(0.16, 0.12, 0.16), "pants": Color(0.36, 0.32, 0.56),
			"ring": Color(0.42, 0.62, 0.94)
		},
		{
			"id": "marah", "badge": "2. Marah",
			"pos": Vector3(4.2, 0.0, 3.2), "yaw": -65.0,
			"shirt": Color(0.92, 0.28, 0.26), "hair": Color(0.14, 0.10, 0.08), "pants": Color(0.24, 0.26, 0.32),
			"ring": Color(0.94, 0.34, 0.26)
		},
		{
			"id": "takut", "badge": "3. Takut",
			"pos": Vector3(-6.4, 0.0, -8.5), "yaw": 48.0,
			"shirt": Color(0.96, 0.58, 0.20), "hair": Color(0.28, 0.18, 0.10), "pants": Color(0.26, 0.42, 0.30),
			"ring": Color(0.76, 0.50, 0.92)
		},
		{
			"id": "bahagia", "badge": "4. Bahagia",
			"pos": Vector3(4.5, 0.0, -2.5), "yaw": -45.0,
			"shirt": Color(0.22, 0.72, 0.95), "hair": Color(0.22, 0.14, 0.10), "pants": Color(0.18, 0.36, 0.66),
			"ring": Color(0.98, 0.78, 0.16)
		},
		{
			"id": "jijik", "badge": "5. Jijik",
			"pos": Vector3(-4.6, 0.0, -4.4), "yaw": 55.0,
			"shirt": Color(0.46, 0.80, 0.34), "hair": Color(0.20, 0.12, 0.08), "pants": Color(0.28, 0.46, 0.24),
			"ring": Color(0.44, 0.78, 0.32)
		},
		{
			"id": "terkejut", "badge": "6. Terkejut",
			"pos": Vector3(6.8, 0.0, -9.2), "yaw": -42.0,
			"shirt": Color(0.98, 0.82, 0.22), "hair": Color(0.18, 0.14, 0.12), "pants": Color(0.24, 0.38, 0.62),
			"ring": Color(0.98, 0.56, 0.16)
		}
	]

	for f in friends:
		_spawn_friend(f)


func _spawn_friend(f: Dictionary) -> void:
	var id: String = str(f["id"])
	var badge_text: String = str(f["badge"])
	var pos: Vector3 = f["pos"]
	_friend_positions[id] = pos

	var root := Node3D.new()
	root.position = pos
	root.rotation_degrees.y = float(f["yaw"])
	add_child(root)

	# Articulated Chibi Toon NPC matching Nara's exact visual quality & shader
	var body_pivot := Node3D.new()
	root.add_child(body_pivot)

	var skin := ToonMat.make(Color(1.0, 0.86, 0.76))
	var shirt := ToonMat.make(f["shirt"])
	var pants := ToonMat.make(f["pants"])
	var shoe_mat := ToonMat.make(Color(0.22, 0.24, 0.28))
	var hair := ToonMat.make(f["hair"])
	var white_mat := ToonMat.make(Color(1.0, 1.0, 1.0), "", {"outline": false})
	var eye_mat := ToonMat.make(Color(0.11, 0.08, 0.13), "", {"outline": false})
	var cheek_mat := ToonMat.make(Color(0.98, 0.56, 0.64), "", {"outline": false})

	# Articulated Legs with Shoes
	var l_leg := _make_friend_leg(-0.14, pants, shoe_mat)
	var r_leg := _make_friend_leg(0.14, pants, shoe_mat)
	body_pivot.add_child(l_leg)
	body_pivot.add_child(r_leg)

	# Torso
	var torso := MeshInstance3D.new()
	var tcyl := CylinderMesh.new()
	tcyl.top_radius = 0.20
	tcyl.bottom_radius = 0.25
	tcyl.height = 0.50
	torso.mesh = tcyl
	torso.material_override = shirt
	torso.position = Vector3(0.0, 0.76, 0.0)
	body_pivot.add_child(torso)

	# Articulated Arms with Puffed Sleeves & Round Hands (spaced cleanly outside torso)
	var l_arm := _make_friend_arm(-0.29, shirt, skin)
	var r_arm := _make_friend_arm(0.29, shirt, skin)
	body_pivot.add_child(l_arm)
	body_pivot.add_child(r_arm)

	# Articulated Head Pivot with Cute Face (Eyes, Highlights, Cheeks, Eyebrows)
	var head_pivot := Node3D.new()
	head_pivot.position = Vector3(0.0, 1.32, 0.0)
	body_pivot.add_child(head_pivot)

	var head := MeshInstance3D.new()
	var hsph := SphereMesh.new()
	hsph.radius = 0.32
	hsph.height = 0.64
	head.mesh = hsph
	head.material_override = skin
	head_pivot.add_child(head)

	var hcap := MeshInstance3D.new()
	var csph := SphereMesh.new()
	csph.radius = 0.34
	csph.height = 0.62
	hcap.mesh = csph
	hcap.material_override = hair
	hcap.position = Vector3(0.0, 0.08, -0.04)
	head_pivot.add_child(hcap)

	# Properly spherical eyes (height = radius * 2.0!) + white eye sparkle + rosy cheeks
	for side: float in [-1.0, 1.0]:
		var ex: float = side * 0.115
		var eye := MeshInstance3D.new()
		var esph := SphereMesh.new()
		esph.radius = 0.048
		esph.height = 0.096
		eye.mesh = esph
		eye.material_override = eye_mat
		eye.position = Vector3(ex, 0.02, 0.285)
		head_pivot.add_child(eye)

		var glint := MeshInstance3D.new()
		var gsph := SphereMesh.new()
		gsph.radius = 0.018
		gsph.height = 0.036
		glint.mesh = gsph
		glint.material_override = white_mat
		glint.position = Vector3(ex - 0.015, 0.038, 0.322)
		head_pivot.add_child(glint)

		var cheek := MeshInstance3D.new()
		var chsph := SphereMesh.new()
		chsph.radius = 0.045
		chsph.height = 0.055
		cheek.mesh = chsph
		cheek.material_override = cheek_mat
		cheek.position = Vector3(side * 0.18, -0.055, 0.245)
		head_pivot.add_child(cheek)

		# Expressive eyebrows for Marah / Sedih / Takut
		if id == "marah" or id == "sedih" or id == "takut":
			var brow := MeshInstance3D.new()
			var bmesh := BoxMesh.new()
			bmesh.size = Vector3(0.09, 0.022, 0.02)
			brow.mesh = bmesh
			brow.material_override = eye_mat
			brow.position = Vector3(ex, 0.105, 0.285)
			if id == "marah":
				brow.rotation_degrees.z = -side * 24.0
			else:
				brow.rotation_degrees.z = side * 18.0
			head_pivot.add_child(brow)

	# Expressive Mouth
	var mouth := MeshInstance3D.new()
	if id == "terkejut" or id == "takut":
		var msph := SphereMesh.new()
		msph.radius = 0.038
		msph.height = 0.076
		mouth.mesh = msph
		mouth.material_override = eye_mat
	elif id == "bahagia":
		var msph := SphereMesh.new()
		msph.radius = 0.052
		msph.height = 0.068
		mouth.mesh = msph
		mouth.material_override = ToonMat.make(Color(0.88, 0.28, 0.38), "", {"outline": false})
	else:
		var mbox := BoxMesh.new()
		mbox.size = Vector3(0.11, 0.024, 0.022)
		mouth.mesh = mbox
		mouth.material_override = eye_mat
	mouth.position = Vector3(0.0, -0.10, 0.29)
	head_pivot.add_child(mouth)

	# Mini story prop per emotion so each character tells a story visually
	if id == "sedih":
		var tear := MeshInstance3D.new()
		var tsph := SphereMesh.new()
		tsph.radius = 0.032
		tsph.height = 0.064
		tear.mesh = tsph
		tear.material_override = ToonMat.make(Color(0.35, 0.74, 0.98), "", {"outline": false})
		tear.position = Vector3(0.13, -0.02, 0.30)
		head_pivot.add_child(tear)
		_sedih_tear = tear
	elif id == "marah":
		var spark := MeshInstance3D.new()
		var sbox := BoxMesh.new()
		sbox.size = Vector3(0.14, 0.14, 0.04)
		spark.mesh = sbox
		spark.material_override = ToonMat.make(Color(0.95, 0.22, 0.20), "", {"outline": false, "emission_color": Color(0.95, 0.22, 0.20), "emission_energy": 0.4})
		spark.position = Vector3(0.26, 0.36, 0.05)
		spark.rotation_degrees.z = 45.0
		head_pivot.add_child(spark)
	elif id == "terkejut":
		# Red balloon prop floating behind Tomi (pops when Nara approaches!)
		_terkejut_balloon = Node3D.new()
		_terkejut_balloon.position = Vector3(0.55, 1.4, -0.45)
		root.add_child(_terkejut_balloon)

		var b_str := MeshInstance3D.new()
		var scyl := CylinderMesh.new()
		scyl.top_radius = 0.012
		scyl.bottom_radius = 0.012
		scyl.height = 1.2
		b_str.mesh = scyl
		b_str.material_override = white_mat
		b_str.position = Vector3(0.0, -0.45, 0.0)
		_terkejut_balloon.add_child(b_str)

		var balloon := MeshInstance3D.new()
		var bsph := SphereMesh.new()
		bsph.radius = 0.26
		bsph.height = 0.62
		balloon.mesh = bsph
		balloon.material_override = ToonMat.make(Color(0.95, 0.22, 0.28))
		balloon.position = Vector3(0.0, 0.42, 0.0)
		_terkejut_balloon.add_child(balloon)

	_friend_nodes[id] = {
		"body": body_pivot,
		"head": head_pivot,
		"l_arm": l_arm,
		"r_arm": r_arm,
		"l_leg": l_leg,
		"r_leg": r_leg
	}

	# Floating Numbered Emotion Label matching the infographic (e.g. "1. Sedih")
	var badge := Label3D.new()
	badge.text = badge_text
	badge.font_size = 58
	badge.outline_size = 11
	badge.modulate = Color(1.0, 0.96, 0.78)
	badge.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	badge.position = Vector3(0.0, 2.25, 0.0)
	root.add_child(badge)
	_friend_badges[id] = badge

	# Interaction Ring on the ground
	var ring := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 0.95
	torus.outer_radius = 1.12
	ring.mesh = torus
	ring.material_override = ToonMat.make(f["ring"], "", {"outline": false, "emission_energy": 0.25})
	ring.position = Vector3(0.0, 0.06, 0.0)
	root.add_child(ring)
	_friend_rings[id] = ring

	# Solid NPC collider + Interaction Area3D
	_add_cylinder_collider(root, 0.42, 1.65, Vector3(0.0, 0.825, 0.0))

	var area := Area3D.new()
	area.collision_layer = 4
	area.collision_mask = 2
	var col := CollisionShape3D.new()
	var cyl := CylinderShape3D.new()
	cyl.radius = 2.05
	cyl.height = 2.2
	col.shape = cyl
	col.position.y = 1.1
	area.add_child(col)
	root.add_child(area)

	area.body_entered.connect(func(body: Node3D) -> void:
		if body is NaraController:
			near_friend_changed.emit(id)
	)
	area.body_exited.connect(func(body: Node3D) -> void:
		if body is NaraController:
			near_friend_changed.emit("")
	)


func _build_horizon_hills_and_flowers() -> void:
	var hill_mat := ToonMat.make(
		Color(0.42, 0.72, 0.34),
		"res://assets/textures/grass.webp",
		{"triplanar": true, "triplanar_scale": 0.10, "outline": false, "rim_strength": 0.18}
	)
	var hills := [
		[Vector3(-22.0, -3.8, -26.0), Vector3(18.0, 7.5, 14.0)],
		[Vector3(24.0, -4.0, -24.0), Vector3(20.0, 8.2, 15.0)],
		[Vector3(0.0, -4.6, -34.0), Vector3(28.0, 8.8, 14.0)]
	]
	for h in hills:
		var mesh_inst := MeshInstance3D.new()
		var sph := SphereMesh.new()
		sph.radius = 1.0
		sph.height = 2.0
		mesh_inst.mesh = sph
		mesh_inst.scale = h[1]
		mesh_inst.position = h[0]
		mesh_inst.material_override = hill_mat
		add_child(mesh_inst)

	var flower_colors := [Color(0.98, 0.78, 0.16), Color(0.96, 0.42, 0.62), Color(0.56, 0.80, 0.98)]
	var spots := [
		Vector3(-9.2, 0.0, 5.5), Vector3(9.4, 0.0, 6.0),
		Vector3(-9.6, 0.0, -2.0), Vector3(9.5, 0.0, -0.5),
		Vector3(-9.2, 0.0, -11.0), Vector3(9.2, 0.0, -11.5)
	]
	var bush_mat := ToonMat.make(Color(0.28, 0.66, 0.30), "res://assets/textures/leaf_canopy.webp", {"triplanar": true, "outline": false})
	for idx in range(spots.size()):
		var b := MeshInstance3D.new()
		var bs := SphereMesh.new()
		bs.radius = 0.7
		bs.height = 1.0
		b.mesh = bs
		b.position = spots[idx] + Vector3(0.0, 0.32, 0.0)
		b.material_override = bush_mat
		add_child(b)

		var fl := MeshInstance3D.new()
		var fs := SphereMesh.new()
		fs.radius = 0.16
		fs.height = 0.32
		fl.mesh = fs
		fl.position = spots[idx] + Vector3(0.35, 0.72, 0.25)
		fl.material_override = ToonMat.make(flower_colors[idx % flower_colors.size()], "", {"outline": false})
		add_child(fl)


func _make_friend_leg(x_off: float, pants_mat: Material, shoe_mat: Material) -> Node3D:
	var pivot := Node3D.new()
	pivot.position = Vector3(x_off, 0.52, 0.0)

	var leg := MeshInstance3D.new()
	var lcyl := CylinderMesh.new()
	lcyl.top_radius = 0.08
	lcyl.bottom_radius = 0.075
	lcyl.height = 0.42
	leg.mesh = lcyl
	leg.material_override = pants_mat
	leg.position = Vector3(0.0, -0.21, 0.0)
	pivot.add_child(leg)

	var shoe := MeshInstance3D.new()
	var sbox := BoxMesh.new()
	sbox.size = Vector3(0.16, 0.12, 0.24)
	shoe.mesh = sbox
	shoe.material_override = shoe_mat
	shoe.position = Vector3(0.0, -0.46, 0.04)
	pivot.add_child(shoe)
	return pivot


func _make_friend_arm(x_off: float, shirt_mat: Material, skin_mat: Material) -> Node3D:
	var pivot := Node3D.new()
	pivot.position = Vector3(x_off, 0.96, 0.0)

	var sleeve := MeshInstance3D.new()
	var ssph := SphereMesh.new()
	ssph.radius = 0.105
	ssph.height = 0.21
	sleeve.mesh = ssph
	sleeve.material_override = shirt_mat
	pivot.add_child(sleeve)

	var arm := MeshInstance3D.new()
	var acyl := CylinderMesh.new()
	acyl.top_radius = 0.062
	acyl.bottom_radius = 0.055
	acyl.height = 0.34
	arm.mesh = acyl
	arm.material_override = skin_mat
	arm.position = Vector3(0.0, -0.19, 0.0)
	pivot.add_child(arm)

	var hand := MeshInstance3D.new()
	var hsph := SphereMesh.new()
	hsph.radius = 0.065
	hsph.height = 0.13
	hand.mesh = hsph
	hand.material_override = skin_mat
	hand.position = Vector3(0.0, -0.37, 0.0)
	pivot.add_child(hand)
	return pivot


func _build_trees_and_bushes() -> void:
	var bark_mat := ToonMat.make(Color(0.55, 0.36, 0.22), "res://assets/textures/bark.webp", {"triplanar": true})
	var leaf_mat := ToonMat.make(Color(0.32, 0.72, 0.34), "res://assets/textures/leaf_canopy.webp", {"triplanar": true, "triplanar_scale": 0.45})

	var coords := [
		Vector3(-9.2, 0.0, -9.8), # Big tree near Dito (Takut)
		Vector3(9.6, 0.0, 2.2),
		Vector3(-9.5, 0.0, 2.6),
		Vector3(9.4, 0.0, -9.5)
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
		_add_cylinder_collider(tree, 0.48, 3.0, Vector3(0.0, 1.5, 0.0))

		for off in [Vector3(0.0, 3.4, 0.0), Vector3(-0.75, 2.8, 0.45), Vector3(0.75, 2.85, -0.35)]:
			var puff := MeshInstance3D.new()
			var sph := SphereMesh.new()
			sph.radius = 1.25
			sph.height = 2.2
			puff.mesh = sph
			puff.material_override = leaf_mat
			puff.position = off
			tree.add_child(puff)


func _make_3d_star_mesh(outer_r: float = 0.75, inner_r: float = 0.34, half_depth: float = 0.22) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var pts: Array[Vector2] = []
	for i in range(10):
		var ang := deg_to_rad(90.0 + i * 36.0)
		var r := outer_r if i % 2 == 0 else inner_r
		pts.append(Vector2(cos(ang) * r, sin(ang) * r))
	var front_c := Vector3(0.0, 0.0, half_depth)
	var back_c := Vector3(0.0, 0.0, -half_depth)
	for i in range(10):
		var a := pts[i]
		var b := pts[(i + 1) % 10]
		var af := Vector3(a.x, a.y, half_depth * 0.55)
		var bf := Vector3(b.x, b.y, half_depth * 0.55)
		var ab := Vector3(a.x, a.y, -half_depth * 0.55)
		var bb := Vector3(b.x, b.y, -half_depth * 0.55)
		st.add_vertex(front_c); st.add_vertex(bf); st.add_vertex(af)
		st.add_vertex(back_c); st.add_vertex(ab); st.add_vertex(bb)
		st.add_vertex(af); st.add_vertex(bf); st.add_vertex(bb)
		st.add_vertex(af); st.add_vertex(bb); st.add_vertex(ab)
	st.generate_normals()
	return st.commit()


func _build_star_and_exit_gate() -> void:
	# Pos 2 Star
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
	badge_lbl.text = "POS 2"
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

	# Exit Gate -> Pos 3
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
	sbox.size = Vector3(4.4, 1.1, 0.18)
	sign_bg.mesh = sbox
	sign_bg.material_override = ToonMat.make(Color(0.24, 0.50, 0.82), "", {"outline_width": 1.4})
	sign_bg.position = Vector3(0.0, 4.45, 0.05)
	gate_root.add_child(sign_bg)

	_gate_lbl = Label3D.new()
	_gate_lbl.text = "NEXT RUTE -> POS 3\n(Kenali 6 Emosi Dulu)"
	_gate_lbl.font_size = 44
	_gate_lbl.outline_size = 8
	_gate_lbl.modulate = Color(1.0, 0.96, 0.82)
	_gate_lbl.position = Vector3(0.0, 4.45, 0.17)
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

