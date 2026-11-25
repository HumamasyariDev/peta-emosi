class_name StorybookProps
extends RefCounted

## Shared lightweight 3D storybook helpers:
## - True extruded 3D Guide Arrow pointing strictly along +Z
## - Multi-petal 3D Wildflowers
## - Soft drifting toon clouds
## - Flapping colorful 3D butterflies


static func make_guide_arrow() -> Node3D:
	var root := Node3D.new()
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	# 2D arrow polygon in XZ plane pointing cleanly toward +Z
	# Center near (0, 0), tail at -0.38, head tip at +0.46
	var poly := [
		Vector2(-0.11, -0.38),
		Vector2(0.11, -0.38),
		Vector2(0.11, 0.06),
		Vector2(0.28, 0.06),
		Vector2(0.0, 0.46),
		Vector2(-0.28, 0.06),
		Vector2(-0.11, 0.06),
	]
	var h := 0.065 # half-thickness

	# Triangulate top (+h) and bottom (-h) faces manually for guaranteed convexity:
	# Shaft quad (0,1,2,6) + Head triangle (3,4,5)
	var tris := [
		[0, 1, 2], [0, 2, 6],
		[3, 4, 5],
	]
	for t in tris:
		var a: Vector2 = poly[t[0]]
		var b: Vector2 = poly[t[1]]
		var c: Vector2 = poly[t[2]]
		# Top face (normal +Y in Godot clockwise front-face convention)
		st.add_vertex(Vector3(a.x, h, a.y))
		st.add_vertex(Vector3(b.x, h, b.y))
		st.add_vertex(Vector3(c.x, h, c.y))
		# Bottom face (normal -Y)
		st.add_vertex(Vector3(a.x, -h, a.y))
		st.add_vertex(Vector3(c.x, -h, c.y))
		st.add_vertex(Vector3(b.x, -h, b.y))

	# Extruded side walls
	var n := poly.size()
	for i in range(n):
		var p1: Vector2 = poly[i]
		var p2: Vector2 = poly[(i + 1) % n]
		var t1 := Vector3(p1.x, h, p1.y)
		var t2 := Vector3(p2.x, h, p2.y)
		var b1 := Vector3(p1.x, -h, p1.y)
		var b2 := Vector3(p2.x, -h, p2.y)
		st.add_vertex(t1); st.add_vertex(b2); st.add_vertex(t2)
		st.add_vertex(t1); st.add_vertex(b1); st.add_vertex(b2)

	st.generate_normals()
	var mesh := st.commit()

	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = ToonMat.make(
		Color(1.0, 0.84, 0.16),
		"",
		{"emission_color": Color(1.0, 0.72, 0.06), "emission_energy": 0.55, "outline_width": 1.3}
	)
	root.add_child(mi)
	return root


static func spawn_flower(parent: Node3D, pos: Vector3, petal_color: Color) -> void:
	var fl := Node3D.new()
	fl.position = pos
	parent.add_child(fl)

	var stem := MeshInstance3D.new()
	var sc := CylinderMesh.new()
	sc.top_radius = 0.03
	sc.bottom_radius = 0.035
	sc.height = 0.28
	sc.radial_segments = 6
	stem.mesh = sc
	stem.material_override = ToonMat.make(Color(0.22, 0.62, 0.24), "", {"outline_width": 0.6})
	stem.position = Vector3(0.0, 0.14, 0.0)
	fl.add_child(stem)

	var petal_mat := ToonMat.make(petal_color, "", {"outline_width": 0.8})
	var pmesh := SphereMesh.new()
	pmesh.radius = 0.095
	pmesh.height = 0.19
	pmesh.radial_segments = 6
	pmesh.rings = 4
	for i in range(5):
		var ang := float(i) * TAU / 5.0
		var p := MeshInstance3D.new()
		p.mesh = pmesh
		p.material_override = petal_mat
		p.scale = Vector3(1.0, 0.45, 1.0)
		p.position = Vector3(cos(ang) * 0.11, 0.30, sin(ang) * 0.11)
		fl.add_child(p)

	var center := MeshInstance3D.new()
	var csp := SphereMesh.new()
	csp.radius = 0.075
	csp.height = 0.15
	csp.radial_segments = 6
	csp.rings = 4
	center.mesh = csp
	center.material_override = ToonMat.make(Color(1.0, 0.84, 0.14), "", {"outline_width": 0.6})
	center.position = Vector3(0.0, 0.32, 0.0)
	fl.add_child(center)


static func spawn_clouds(parent: Node3D) -> Array[Node3D]:
	var clouds: Array[Node3D] = []
	var cloud_mat := ToonMat.make(Color(0.99, 0.99, 1.0), "", {"outline": false, "rim_strength": 0.05})
	var cloud_defs := [
		[Vector3(-18.0, 14.5, -24.0), 1.3],
		[Vector3(6.0, 16.0, -28.0), 1.6],
		[Vector3(22.0, 13.8, -18.0), 1.15],
		[Vector3(-10.0, 15.2, -10.0), 1.05],
	]
	for cd in cloud_defs:
		var croot := Node3D.new()
		croot.position = cd[0]
		var sc: float = float(cd[1])
		croot.scale = Vector3(sc, sc, sc)
		parent.add_child(croot)

		var puffs := [
			[Vector3(0.0, 0.0, 0.0), 1.45],
			[Vector3(-1.35, -0.25, 0.1), 1.05],
			[Vector3(1.4, -0.20, -0.1), 1.12],
			[Vector3(0.4, 0.45, 0.15), 0.95],
		]
		for pf in puffs:
			var m := MeshInstance3D.new()
			var sp := SphereMesh.new()
			var r: float = float(pf[1])
			sp.radius = r
			sp.height = r * 2.0
			sp.radial_segments = 10
			sp.rings = 6
			m.mesh = sp
			m.material_override = cloud_mat
			m.scale = Vector3(1.2, 0.72, 0.9)
			m.position = pf[0]
			croot.add_child(m)
		clouds.append(croot)
	return clouds


static func spawn_butterflies(parent: Node3D, bases: Array) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var colors := [Color(1.0, 0.76, 0.18), Color(0.98, 0.48, 0.72), Color(0.42, 0.82, 1.0)]
	for i in range(bases.size()):
		var b_root := Node3D.new()
		var base_pos: Vector3 = bases[i]
		b_root.position = base_pos
		parent.add_child(b_root)

		var wmat := ToonMat.make(colors[i % colors.size()], "", {"outline": false, "emission_color": colors[i % colors.size()], "emission_energy": 0.25})
		var wbox := BoxMesh.new()
		wbox.size = Vector3(0.18, 0.02, 0.14)

		var lw := Node3D.new()
		var lmesh := MeshInstance3D.new()
		lmesh.mesh = wbox
		lmesh.material_override = wmat
		lmesh.position = Vector3(-0.09, 0.0, 0.0)
		lw.add_child(lmesh)
		b_root.add_child(lw)

		var rw := Node3D.new()
		var rmesh := MeshInstance3D.new()
		rmesh.mesh = wbox
		rmesh.material_override = wmat
		rmesh.position = Vector3(0.09, 0.0, 0.0)
		rw.add_child(rmesh)
		b_root.add_child(rw)

		result.append({
			"root": b_root,
			"lw": lw,
			"rw": rw,
			"base": base_pos,
			"phase": float(i) * 2.1,
			"speed": 0.95 + float(i % 2) * 0.35
		})
	return result


static func animate_ambient(clouds: Array[Node3D], butterflies: Array[Dictionary], t: float, delta: float) -> void:
	for i in range(clouds.size()):
		var c := clouds[i]
		c.position.x += delta * (0.42 + float(i % 2) * 0.18)
		if c.position.x > 34.0:
			c.position.x = -34.0

	for b in butterflies:
		var root: Node3D = b["root"] as Node3D
		var lw: Node3D = b["lw"] as Node3D
		var rw: Node3D = b["rw"] as Node3D
		var base: Vector3 = b["base"] as Vector3
		var ph: float = float(b["phase"])
		var spd: float = float(b["speed"])
		var prev := root.position
		root.position = base + Vector3(
			sin(t * spd + ph) * 1.15,
			sin(t * (spd * 2.2) + ph) * 0.35,
			cos(t * spd * 0.8 + ph) * 1.15
		)
		var dir := root.position - prev
		if dir.length_squared() > 0.00001:
			root.rotation.y = atan2(dir.x, dir.z)
		var flap := sin(t * 18.0 + ph) * 48.0
		lw.rotation_degrees.z = flap
		rw.rotation_degrees.z = -flap


static func _add_wall_collider(parent: Node3D, sz: Vector3, pos: Vector3) -> void:
	var body := StaticBody3D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	var col := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = sz
	col.shape = sh
	body.position = pos
	body.add_child(col)
	parent.add_child(body)


static func build_flanking_brick_walls(parent: Node3D, z_pos: float, inner_x: float, outer_x: float, height: float = 1.05) -> void:
	## Connects left & right brick garden walls seamlessly between gate pillars (inner_x)
	## and outer perimeter walls (outer_x), WITH matching tall solid StaticBody3D colliders
	## so Nara NEVER clips into or jumps over ANY brick wall across all 8 Pos.
	## Pass inner_x <= 0.0 to build one continuous solid wall from -outer_x to +outer_x.
	var brick_mat := ToonMat.make(
		Color(0.84, 0.44, 0.34),
		"res://assets/textures/brick.webp",
		{"triplanar": true, "triplanar_scale": 0.48}
	)
	var cap_mat := ToonMat.make(Color(0.94, 0.88, 0.76), "", {"outline_width": 1.1})

	if inner_x <= 0.05:
		var full_w := outer_x * 2.0 + 0.65
		var wall := MeshInstance3D.new()
		var wb := BoxMesh.new()
		wb.size = Vector3(full_w, height, 0.55)
		wall.mesh = wb; wall.material_override = brick_mat
		wall.position = Vector3(0.0, height * 0.5, z_pos)
		parent.add_child(wall)
		var cap := MeshInstance3D.new()
		var cb := BoxMesh.new()
		cb.size = Vector3(full_w + 0.14, 0.14, 0.68)
		cap.mesh = cb; cap.material_override = cap_mat
		cap.position = Vector3(0.0, height + 0.06, z_pos)
		parent.add_child(cap)
		_add_wall_collider(parent, Vector3(full_w + 0.20, 6.0, 0.78), Vector3(0.0, 3.0, z_pos))
	else:
		var span := maxf(0.4, (outer_x - inner_x) + 0.50)
		var mid_x := (inner_x + outer_x) * 0.5
		for side: float in [-1.0, 1.0]:
			var wall := MeshInstance3D.new()
			var wb := BoxMesh.new()
			wb.size = Vector3(span, height, 0.55)
			wall.mesh = wb; wall.material_override = brick_mat
			wall.position = Vector3(side * mid_x, height * 0.5, z_pos)
			parent.add_child(wall)
			var cap := MeshInstance3D.new()
			var cb := BoxMesh.new()
			cb.size = Vector3(span + 0.12, 0.14, 0.68)
			cap.mesh = cb; cap.material_override = cap_mat
			cap.position = Vector3(side * mid_x, height + 0.06, z_pos)
			parent.add_child(cap)
			_add_wall_collider(parent, Vector3(span + 0.12, 6.0, 0.78), Vector3(side * mid_x, 3.0, z_pos))

	# Finished corner pillars at +-outer_x so every arena corner closes cleanly
	for side: float in [-1.0, 1.0]:
		var pil := MeshInstance3D.new()
		var pb := BoxMesh.new()
		pb.size = Vector3(0.76, height + 0.32, 0.76)
		pil.mesh = pb; pil.material_override = brick_mat
		pil.position = Vector3(side * outer_x, (height + 0.32) * 0.5, z_pos)
		parent.add_child(pil)
		var pcap := MeshInstance3D.new()
		var pcb := BoxMesh.new()
		pcb.size = Vector3(0.88, 0.15, 0.88)
		pcap.mesh = pcb; pcap.material_override = cap_mat
		pcap.position = Vector3(side * outer_x, height + 0.38, z_pos)
		parent.add_child(pcap)
		_add_wall_collider(parent, Vector3(0.92, 6.0, 0.92), Vector3(side * outer_x, 3.0, z_pos))


static func spawn_horizon_backdrop_360(parent: Node3D, z_front_min: float, z_back_max: float, half_width: float) -> void:
	## Surrounds the arena on ALL 4 sides (especially +Z behind the entrance gate!) with
	## overlapping rolling green storybook hills and outer park trees so rotating the camera
	## 360 degrees NEVER reveals an empty flat horizon edge.
	var hill_mat := ToonMat.make(
		Color(0.32, 0.68, 0.29),
		"res://assets/textures/grass.webp",
		{"triplanar": true, "triplanar_scale": 0.13, "outline": false, "rim_strength": 0.08}
	)
	var far_hill_mat := ToonMat.make(
		Color(0.27, 0.60, 0.28),
		"res://assets/textures/grass.webp",
		{"triplanar": true, "triplanar_scale": 0.11, "outline": false, "rim_strength": 0.06}
	)
	var mid_z := (z_front_min + z_back_max) * 0.5
	var z_back_hill := z_back_max + 24.0
	var z_front_hill := z_front_min - 26.0
	var x_side := half_width + 24.0

	var hills := [
		# Back (+Z) rolling hills behind entrance gate so turning camera backward looks lush!
		[Vector3(0.0, -4.2, z_back_hill + 6.0), Vector3(2.5, 0.62, 1.15), 17.5, far_hill_mat],
		[Vector3(-24.0, -3.5, z_back_hill - 2.0), Vector3(1.75, 0.66, 1.25), 14.5, hill_mat],
		[Vector3(24.0, -3.5, z_back_hill - 2.0), Vector3(1.75, 0.68, 1.25), 14.5, hill_mat],
		# Front (-Z) far backdrop hills
		[Vector3(-26.0, -3.8, z_front_hill + 2.0), Vector3(1.7, 0.64, 1.2), 14.5, far_hill_mat],
		[Vector3(26.0, -3.8, z_front_hill + 2.0), Vector3(1.7, 0.66, 1.2), 14.5, far_hill_mat],
		# Left & Right mid-flank hills sealing diagonal corners
		[Vector3(-x_side, -3.5, mid_z + 10.0), Vector3(1.4, 0.60, 1.5), 13.5, hill_mat],
		[Vector3(x_side, -3.5, mid_z + 10.0), Vector3(1.4, 0.62, 1.5), 13.5, hill_mat],
		[Vector3(-x_side, -3.5, mid_z - 10.0), Vector3(1.4, 0.62, 1.5), 13.5, hill_mat],
		[Vector3(x_side, -3.5, mid_z - 10.0), Vector3(1.4, 0.60, 1.5), 13.5, hill_mat],
	]
	for h in hills:
		var m := MeshInstance3D.new()
		var sp := SphereMesh.new()
		var r: float = float(h[2])
		sp.radius = r
		sp.height = r * 2.0
		sp.radial_segments = 14
		sp.rings = 8
		m.mesh = sp
		m.scale = h[1]
		m.position = h[0]
		m.material_override = h[3]
		parent.add_child(m)

	# Outer park tree line behind the entrance gate (+Z) & side flanks so the garden feels embedded in a real park!
	var trunk_mat := ToonMat.make(Color(0.55, 0.36, 0.22), "res://assets/textures/bark.webp", {"triplanar": true})
	var leaf_mat := ToonMat.make(Color(0.28, 0.68, 0.30), "res://assets/textures/leaf_canopy.webp", {"triplanar": true, "triplanar_scale": 0.45})
	var bush_mat := ToonMat.make(Color(0.24, 0.62, 0.28), "res://assets/textures/leaf_canopy.webp", {"triplanar": true, "outline": false})

	var tree_spots := [
		[Vector3(-9.5, 0.0, z_back_max + 4.8), 1.35],
		[Vector3(-4.2, 0.0, z_back_max + 6.5), 1.45],
		[Vector3(0.0, 0.0, z_back_max + 8.0), 1.55],
		[Vector3(4.2, 0.0, z_back_max + 6.5), 1.45],
		[Vector3(9.5, 0.0, z_back_max + 4.8), 1.35],
		[Vector3(-(half_width + 4.2), 0.0, z_back_max - 1.0), 1.3],
		[Vector3(half_width + 4.2, 0.0, z_back_max - 1.0), 1.3],
		[Vector3(-(half_width + 4.8), 0.0, mid_z), 1.4],
		[Vector3(half_width + 4.8, 0.0, mid_z), 1.4],
	]
	for t in tree_spots:
		var tr := Node3D.new()
		tr.position = t[0]
		var sc: float = float(t[1])
		tr.scale = Vector3(sc, sc, sc)
		parent.add_child(tr)
		var trunk := MeshInstance3D.new()
		var tc := CylinderMesh.new()
		tc.top_radius = 0.26; tc.bottom_radius = 0.38; tc.height = 2.4; tc.radial_segments = 8
		trunk.mesh = tc; trunk.material_override = trunk_mat; trunk.position = Vector3(0.0, 1.2, 0.0)
		tr.add_child(trunk)
		var cr := MeshInstance3D.new()
		var sp := SphereMesh.new()
		sp.radius = 1.55; sp.height = 2.9; sp.radial_segments = 10; sp.rings = 7
		cr.mesh = sp; cr.material_override = leaf_mat; cr.position = Vector3(0.0, 3.15, 0.0)
		tr.add_child(cr)

	for bx: float in [-7.2, -3.6, 3.6, 7.2]:
		var bush := MeshInstance3D.new()
		var bsp := SphereMesh.new()
		bsp.radius = 1.05; bsp.height = 1.5; bsp.radial_segments = 8; bsp.rings = 6
		bush.mesh = bsp; bush.material_override = bush_mat
		bush.position = Vector3(bx, 0.55, z_back_max + 2.2)
		parent.add_child(bush)


static func collect_and_hide_star(host: Node, star_mesh: MeshInstance3D, instant: bool = false) -> void:
	## Juicy Mario-style star collection animation: spins fast, pops golden, rockets upward,
	## and hides the 3D map star cleanly once the Pos is completed!
	if star_mesh == null or not is_instance_valid(star_mesh):
		return
	if star_mesh.has_meta("collected"):
		star_mesh.visible = false
		return
	star_mesh.set_meta("collected", true)
	if instant or host == null or not host.is_inside_tree():
		star_mesh.visible = false
		return
	var tw := host.create_tween().set_parallel(true)
	tw.tween_property(star_mesh, "rotation:y", star_mesh.rotation.y + TAU * 2.5, 0.65).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_property(star_mesh, "position:y", star_mesh.position.y + 2.8, 0.65).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tw.tween_property(star_mesh, "scale", Vector3(0.01, 0.01, 0.01), 0.62).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tw.chain().tween_callback(func() -> void:
		if is_instance_valid(star_mesh):
			star_mesh.visible = false
	)


