class_name Pos8Props
extends Node3D

## Pos 8: Finish - Alun-Alun Perayaan "Aku Tahu Emosiku!"
## Rich interactive finale:
## - 3 Interactive "Lentera Kenangan Emosi" memory pedestals along the royal carpet
##   (each launches a glowing 3D Star Orb into the Golden Trophy Cup on the Podium!)
## - Sculpted 3D Golden Trophy Cup ("Piala Emas") with twin curved handles, walnut base,
##   spinning star crown, and golden sparkle shower that detaches and flies into Nara's raised hands!
## - High unobstructed festival bunting, swaying balloon bouquets, golden carpet bollards,
##   6 cheering friends (Bima, Sinta, Bahagia, Tenang, Peduli, Empati), and 5-wave 3D fireworks + confetti!

signal pillar_zone_changed(idx: int, entered: bool)
signal trophy_zone_changed(entered: bool)

var podium_position: Vector3 = Vector3(0.0, 0.0, -11.5)
var podium_stand_pos: Vector3 = Vector3(0.0, 0.16, -10.35)
var pillar_positions: Array[Vector3] = [
	Vector3(-2.65, 0.0, 3.0),
	Vector3(2.65, 0.0, -1.2),
	Vector3(-2.65, 0.0, -5.4),
]

var _time: float = 0.0
var _clouds: Array[Node3D] = []
var _butterflies: Array[Dictionary] = []
var _guide_arrow: Node3D

var _pillars: Array[Dictionary] = []
var _lit_count: int = 0
var _flying_orbs: Array[Dictionary] = []

var _podium_root: Node3D
var _trophy_node: Node3D
var _trophy_star_crown: MeshInstance3D
var _trophy_cup_mat: ShaderMaterial
var _trophy_sparkles: GPUParticles3D
var _trophy_prompt_lbl: Label3D
var _trophy_lifted: bool = false
var _trophy_ready: bool = false
var _trophy_fly_tween: Tween

var _fireworks: Array[GPUParticles3D] = []
var _confetti_rain: GPUParticles3D
var _balloons: Array[Dictionary] = []
var _cheering_friends: Array[Dictionary] = []
var _celebrating: bool = false
var _fw_timer: float = 0.0
var _fw_wave: int = 0


func _ready() -> void:
	_build_ground_and_festive_plaza()
	_build_horizon_hills_and_trees()
	_build_closed_back_gate()
	_build_brick_enclosure()
	_build_festival_bunting_high()
	_build_carpet_lantern_bollards()
	_build_balloon_bouquets()
	_build_memory_pillars()
	_build_cheering_friends()
	_build_trophy_podium()
	_guide_arrow = StorybookProps.make_guide_arrow()
	add_child(_guide_arrow)
	_clouds = StorybookProps.spawn_clouds(self)
	_butterflies = StorybookProps.spawn_butterflies(self, [
		Vector3(-4.5, 1.9, 3.0), Vector3(4.5, 2.0, -2.0), Vector3(-3.8, 2.1, -9.0), Vector3(3.8, 2.1, -9.0)
	])
	ToonMat.optimize_tree(self)


func get_next_target_position() -> Vector3:
	for i in range(_pillars.size()):
		if not bool(_pillars[i]["lit"]):
			return pillar_positions[i]
	return podium_stand_pos


func is_pillar_lit(idx: int) -> bool:
	if idx < 0 or idx >= _pillars.size():
		return false
	return bool(_pillars[idx]["lit"])


func get_lit_count() -> int:
	return _lit_count


func is_trophy_ready() -> bool:
	return _trophy_ready


func activate_pillar(idx: int) -> void:
	if idx < 0 or idx >= _pillars.size():
		return
	var p: Dictionary = _pillars[idx]
	if bool(p["lit"]):
		return
	p["lit"] = true
	_lit_count += 1

	var gem_mat := p["gem_mat"] as ShaderMaterial
	if gem_mat != null:
		gem_mat.set_shader_parameter("albedo", Color(1.0, 0.88, 0.24))
		gem_mat.set_shader_parameter("emission_color", Color(1.0, 0.84, 0.20))
		gem_mat.set_shader_parameter("emission_energy", 1.35)

	var lbl := p["label"] as Label3D
	if lbl != null:
		lbl.text = "%s\nMENYALA!" % str(p["title"])
		lbl.modulate = Color(1.0, 0.94, 0.42)

	var burst := p["burst"] as GPUParticles3D
	if burst != null:
		burst.restart()
		burst.emitting = true

	# Launch an animated glowing 3D Star Orb from this pillar into the Golden Trophy Cup!
	_launch_star_orb(pillar_positions[idx] + Vector3(0.0, 1.85, 0.0))

	if _trophy_cup_mat != null:
		var energy := 0.28 + float(_lit_count) * 0.26
		_trophy_cup_mat.set_shader_parameter("emission_energy", energy)

	if _lit_count >= _pillars.size():
		_trophy_ready = true
		if _trophy_sparkles != null:
			_trophy_sparkles.emitting = true
		if _trophy_prompt_lbl != null:
			_trophy_prompt_lbl.text = "PIALA EMAS SIAP DIANGKAT!\nDekati & tekan [E / Aksi]!"
			_trophy_prompt_lbl.modulate = Color(1.0, 0.96, 0.45)
	elif _trophy_prompt_lbl != null:
		_trophy_prompt_lbl.text = "PIALA EMAS (%d/3 Lentera)\nNyalakan 3 Lentera Kenangan dulu!" % _lit_count


func unlock_all_pillars_immediately() -> void:
	for i in range(_pillars.size()):
		if not bool(_pillars[i]["lit"]):
			_pillars[i]["lit"] = true
			_lit_count += 1
			var gem_mat := _pillars[i]["gem_mat"] as ShaderMaterial
			if gem_mat != null:
				gem_mat.set_shader_parameter("albedo", Color(1.0, 0.88, 0.24))
				gem_mat.set_shader_parameter("emission_energy", 1.25)
			var lbl := _pillars[i]["label"] as Label3D
			if lbl != null:
				lbl.text = "%s\nMENYALA!" % str(_pillars[i]["title"])
				lbl.modulate = Color(1.0, 0.94, 0.42)
	_trophy_ready = true
	if _trophy_cup_mat != null:
		_trophy_cup_mat.set_shader_parameter("emission_energy", 1.15)
	if _trophy_sparkles != null:
		_trophy_sparkles.emitting = true
	if _trophy_prompt_lbl != null:
		_trophy_prompt_lbl.text = "PIALA EMAS JUARA!\nTekan [E / Aksi] untuk Angkat Piala & Piagam!"
		_trophy_prompt_lbl.modulate = Color(1.0, 0.96, 0.48)


func lift_trophy_to_nara(anchor: Node3D) -> void:
	if _trophy_node == null or anchor == null:
		return
	_trophy_lifted = true
	if _trophy_fly_tween != null and _trophy_fly_tween.is_valid():
		_trophy_fly_tween.kill()

	var start_xf := _trophy_node.global_transform
	if _trophy_node.get_parent() != anchor:
		_trophy_node.get_parent().remove_child(_trophy_node)
		anchor.add_child(_trophy_node)
		_trophy_node.global_transform = start_xf

	if _trophy_cup_mat != null:
		_trophy_cup_mat.set_shader_parameter("albedo", Color(1.0, 0.88, 0.22))
		_trophy_cup_mat.set_shader_parameter("emission_energy", 1.25)
	if _trophy_sparkles != null:
		_trophy_sparkles.emitting = true

	# Smooth heroic fly-up from pedestal straight into Nara's raised hands!
	_trophy_fly_tween = create_tween().set_parallel(true)
	_trophy_fly_tween.tween_property(_trophy_node, "position", Vector3.ZERO, 0.55).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_trophy_fly_tween.tween_property(_trophy_node, "rotation", Vector3.ZERO, 0.45).set_trans(Tween.TRANS_SINE)
	_trophy_fly_tween.tween_property(_trophy_node, "scale", Vector3(0.92, 0.92, 0.92), 0.50).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	if _trophy_prompt_lbl != null:
		_trophy_prompt_lbl.text = "SELAMAT! NARA JUARA EMOSI!\nTekan [E / Aksi] untuk Rayakan & Lihat Piagam"
		_trophy_prompt_lbl.modulate = Color(1.0, 0.96, 0.50)


func lower_trophy_to_chest(carry_anchor: Node3D) -> void:
	## Smoothly lowers the Golden Trophy from above Nara's head down to her chest
	## so she cradles it proudly in both hands while walking around the plaza!
	if _trophy_node == null or carry_anchor == null:
		return
	if _trophy_fly_tween != null and _trophy_fly_tween.is_valid():
		_trophy_fly_tween.kill()

	var start_xf := _trophy_node.global_transform
	if _trophy_node.get_parent() != carry_anchor:
		_trophy_node.get_parent().remove_child(_trophy_node)
		carry_anchor.add_child(_trophy_node)
		_trophy_node.global_transform = start_xf

	_trophy_fly_tween = create_tween().set_parallel(true)
	_trophy_fly_tween.tween_property(_trophy_node, "position", Vector3(0.0, -0.08, 0.08), 0.50).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_trophy_fly_tween.tween_property(_trophy_node, "rotation", Vector3.ZERO, 0.45).set_trans(Tween.TRANS_SINE)
	_trophy_fly_tween.tween_property(_trophy_node, "scale", Vector3(0.74, 0.74, 0.74), 0.48).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


func trigger_grand_celebration() -> void:
	_celebrating = true
	_fw_timer = 0.0
	_fw_wave = 0
	if _trophy_cup_mat != null:
		_trophy_cup_mat.set_shader_parameter("albedo", Color(1.0, 0.90, 0.24))
		_trophy_cup_mat.set_shader_parameter("emission_energy", 1.35)
	if _trophy_sparkles != null:
		_trophy_sparkles.emitting = true
	if _confetti_rain != null:
		_confetti_rain.emitting = true
	_fire_firework_wave(true)
	for f: Dictionary in _cheering_friends:
		var h := f.get("heart") as Label3D
		if h != null:
			h.visible = true


func _fire_firework_wave(all_at_once: bool) -> void:
	if _fireworks.is_empty():
		return
	if all_at_once:
		for fw: GPUParticles3D in _fireworks:
			if is_instance_valid(fw):
				fw.restart()
				fw.emitting = true
	else:
		# Staggered pair bursts so the sky stays lively and festive!
		var i1 := _fw_wave % _fireworks.size()
		var i2 := (_fw_wave + 2) % _fireworks.size()
		_fw_wave += 1
		for idx: int in [i1, i2]:
			var fw := _fireworks[idx]
			if is_instance_valid(fw):
				fw.restart()
				fw.emitting = true


func update_guide_arrow(player_pos: Vector3, active: bool) -> void:
	if _guide_arrow == null:
		return
	if not active:
		_guide_arrow.visible = false
		return
	var target := get_next_target_position()
	var d := target - player_pos
	d.y = 0.0
	if d.length() < 1.85:
		_guide_arrow.visible = false
		return
	_guide_arrow.visible = true
	var dir := d.normalized()
	_guide_arrow.position = player_pos + dir * 1.45 + Vector3(0.0, 0.24, 0.0)
	_guide_arrow.rotation.y = atan2(dir.x, dir.z)


func _launch_star_orb(from_pos: Vector3) -> void:
	var orb := MeshInstance3D.new()
	orb.mesh = _make_3d_star_mesh(0.32, 0.15, 0.09)
	orb.material_override = ToonMat.make(Color(1.0, 0.90, 0.25), "", {"emission_color": Color(1.0, 0.85, 0.20), "emission_energy": 1.4, "outline": false})
	orb.position = from_pos
	add_child(orb)
	_flying_orbs.append({
		"node": orb,
		"from": from_pos,
		"to": podium_position + Vector3(0.0, 2.25, -0.7),
		"t": 0.0,
		"dur": 0.95,
	})


func _process(delta: float) -> void:
	_time += delta
	StorybookProps.animate_ambient(_clouds, _butterflies, _time, delta)

	# Spin Memory Pillar crystals
	for i in range(_pillars.size()):
		var p: Dictionary = _pillars[i]
		var gem := p["gem"] as Node3D
		var lit := bool(p["lit"])
		if gem != null:
			gem.rotation.y += delta * (3.2 if lit else 1.2)
			gem.position.y = 1.65 + sin(_time * (3.4 if lit else 2.2) + float(i) * 1.3) * 0.11

	# Animate flying star orbs arcing from Memory Pillars into the Golden Trophy!
	for i in range(_flying_orbs.size() - 1, -1, -1):
		var o: Dictionary = _flying_orbs[i]
		var node := o["node"] as Node3D
		o["t"] = float(o["t"]) + delta
		var u := clampf(float(o["t"]) / float(o["dur"]), 0.0, 1.0)
		var pos: Vector3 = (o["from"] as Vector3).lerp(o["to"] as Vector3, u)
		pos.y += sin(u * PI) * 2.6
		node.position = pos
		node.rotation.y += delta * 9.0
		var sc := 1.0 + sin(u * PI) * 0.45
		node.scale = Vector3(sc, sc, sc)
		if u >= 1.0:
			node.queue_free()
			_flying_orbs.remove_at(i)
			Audio.play_sfx("coin")

	# Animate Golden Trophy Cup (gentle hover on pedestal, or crisp spin of star crown when lifted!)
	if _trophy_node != null:
		if not _trophy_lifted:
			_trophy_node.position.y = 1.44 + sin(_time * (3.2 if _trophy_ready else 2.0)) * (0.10 if _trophy_ready else 0.05)
			_trophy_node.rotation.y += delta * (1.8 if _trophy_ready else 0.7)
		if _trophy_star_crown != null:
			_trophy_star_crown.rotation.y += delta * (4.0 if _celebrating else 1.9)

	# Gently sway balloon bouquets in the warm breeze
	for i in range(_balloons.size()):
		var b: Dictionary = _balloons[i]
		var grp := b["node"] as Node3D
		if grp != null:
			var ph := float(i) * 1.1
			grp.rotation.z = sin(_time * 1.9 + ph) * 0.08
			grp.rotation.x = cos(_time * 1.5 + ph) * 0.06

	# Staggered celebratory fireworks waves
	if _celebrating:
		_fw_timer += delta
		if _fw_timer >= 1.55:
			_fw_timer = 0.0
			_fire_firework_wave(false)

	# Animate cheering friends jumping & waving happily!
	for i in range(_cheering_friends.size()):
		var f: Dictionary = _cheering_friends[i]
		var root := f["root"] as Node3D
		var la := f["l_arm"] as Node3D
		var ra := f["r_arm"] as Node3D
		var phase := float(i) * 0.85
		var speed := 7.2 if _celebrating else 4.0
		var amp := 0.25 if _celebrating else 0.08
		root.position.y = absf(sin(_time * speed + phase)) * amp
		la.rotation.z = -2.15 - sin(_time * 8.0 + phase) * 0.34
		ra.rotation.z = 2.15 + sin(_time * 8.0 + phase) * 0.34


func _build_ground_and_festive_plaza() -> void:
	var grass_mat := ToonMat.make(Color(0.38, 0.74, 0.32), "res://assets/textures/grass.webp", {"triplanar": true, "triplanar_scale": 0.22, "outline": false})
	var ground_body := StaticBody3D.new()
	var gcol := CollisionShape3D.new()
	var gbox := BoxShape3D.new()
	gbox.size = Vector3(84.0, 1.0, 84.0)
	gcol.shape = gbox
	gcol.position.y = -0.5
	ground_body.add_child(gcol)

	var gmesh := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(84.0, 84.0)
	gmesh.mesh = plane
	gmesh.material_override = grass_mat
	ground_body.add_child(gmesh)
	add_child(ground_body)

	# Wide Grand Cobblestone Plaza
	var stone_mat := ToonMat.make(Color(0.34, 0.34, 0.42), "res://assets/textures/cobblestone.webp", {"triplanar": true, "triplanar_scale": 0.34, "outline": false})
	var plaza := MeshInstance3D.new()
	var pb := BoxMesh.new()
	pb.size = Vector3(12.2, 0.06, 26.5)
	plaza.mesh = pb; plaza.material_override = stone_mat; plaza.position = Vector3(0.0, 0.02, -3.5)
	add_child(plaza)

	# Royal Berry-Red & Gold Festive Carpet leading to the Trophy Podium
	var carpet_mat := ToonMat.make(Color(0.78, 0.16, 0.27), "", {"outline": false})
	var trim_mat := ToonMat.make(Color(0.96, 0.78, 0.22), "", {"outline": false})
	var trim := MeshInstance3D.new()
	var trb := BoxMesh.new()
	trb.size = Vector3(3.35, 0.03, 18.8)
	trim.mesh = trb; trim.material_override = trim_mat; trim.position = Vector3(0.0, 0.055, -0.5)
	add_child(trim)
	var carpet := MeshInstance3D.new()
	var cb := BoxMesh.new()
	cb.size = Vector3(2.85, 0.04, 18.6)
	carpet.mesh = cb; carpet.material_override = carpet_mat; carpet.position = Vector3(0.0, 0.062, -0.5)
	add_child(carpet)


func _build_festival_bunting_high() -> void:
	# High overhead bunting poles (5.8m tall, wide x=+-6.4m) so flags frame the sky cleanly
	# and NEVER block the Finish Arch sign, Trophy, or camera!
	var wood_mat := ToonMat.make(Color(0.58, 0.36, 0.20), "res://assets/textures/wood_planks.webp", {"triplanar": true, "triplanar_scale": 0.44})
	var gold_mat := ToonMat.make(Color(0.96, 0.78, 0.22), "", {"outline_width": 1.1})
	var flag_cols := [
		Color(0.24, 0.56, 0.90), Color(0.92, 0.30, 0.28), Color(0.60, 0.34, 0.78),
		Color(0.98, 0.80, 0.18), Color(0.22, 0.74, 0.42), Color(0.96, 0.54, 0.32),
	]

	for pz: float in [5.4, -0.4, -6.2]:
		for side: float in [-1.0, 1.0]:
			var post := MeshInstance3D.new()
			var pc := CylinderMesh.new()
			pc.top_radius = 0.10; pc.bottom_radius = 0.14; pc.height = 5.8
			post.mesh = pc; post.material_override = wood_mat; post.position = Vector3(side * 6.4, 2.9, pz)
			add_child(post)
			var finial := MeshInstance3D.new()
			var fsp := SphereMesh.new()
			fsp.radius = 0.20; fsp.height = 0.40
			finial.mesh = fsp; finial.material_override = gold_mat; finial.position = Vector3(side * 6.4, 5.92, pz)
			add_child(finial)

		var count := 10
		for i in range(count):
			var t := float(i + 1) / float(count + 1)
			var fx := lerpf(-6.2, 6.2, t)
			var sag := sin(t * PI) * 0.52
			var flag := MeshInstance3D.new()
			var fm := PrismMesh.new()
			fm.size = Vector3(0.50, 0.56, 0.05)
			flag.mesh = fm
			flag.material_override = ToonMat.make(flag_cols[(i + int(absf(pz))) % flag_cols.size()])
			flag.position = Vector3(fx, 5.55 - sag, pz)
			flag.rotation_degrees.z = 180.0
			add_child(flag)


func _build_carpet_lantern_bollards() -> void:
	var stone_mat := ToonMat.make(Color(0.92, 0.86, 0.76), "", {"outline_width": 1.1})
	var lamp_mat := ToonMat.make(Color(1.0, 0.90, 0.42), "", {"emission_color": Color(1.0, 0.84, 0.30), "emission_energy": 0.65, "outline": false})
	for pz: float in [6.2, 1.0, -4.0, -8.4]:
		for side: float in [-1.0, 1.0]:
			var bx := side * 2.05
			var post := MeshInstance3D.new()
			var pc := CylinderMesh.new()
			pc.top_radius = 0.12; pc.bottom_radius = 0.16; pc.height = 0.72; pc.radial_segments = 10
			post.mesh = pc; post.material_override = stone_mat; post.position = Vector3(bx, 0.36, pz)
			add_child(post)
			var orb := MeshInstance3D.new()
			var osp := SphereMesh.new()
			osp.radius = 0.15; osp.height = 0.30
			orb.mesh = osp; orb.material_override = lamp_mat; orb.position = Vector3(bx, 0.82, pz)
			add_child(orb)


func _build_balloon_bouquets() -> void:
	var string_mat := ToonMat.make(Color(0.92, 0.88, 0.80), "", {"outline": false})
	var cols := [
		Color(0.96, 0.32, 0.42), Color(0.98, 0.80, 0.22), Color(0.26, 0.72, 0.96),
		Color(0.28, 0.80, 0.46), Color(0.68, 0.42, 0.92), Color(0.98, 0.56, 0.24),
	]
	var anchors := [
		Vector3(-5.0, 0.0, 6.2), Vector3(5.0, 0.0, 6.2),
		Vector3(-5.1, 0.0, -9.8), Vector3(5.1, 0.0, -9.8),
		Vector3(-4.2, 0.0, -14.2), Vector3(4.2, 0.0, -14.2),
	]
	for idx in range(anchors.size()):
		var anchor_pos: Vector3 = anchors[idx]
		var base := Node3D.new()
		base.position = anchor_pos
		add_child(base)

		var cluster := Node3D.new()
		base.add_child(cluster)
		var offsets := [
			Vector3(0.0, 2.55, 0.0),
			Vector3(-0.34, 2.22, 0.14),
			Vector3(0.34, 2.28, -0.12),
		]
		for j in range(offsets.size()):
			var bpos: Vector3 = offsets[j]
			var s_len := bpos.y - 0.3
			var st := MeshInstance3D.new()
			var scyl := CylinderMesh.new()
			scyl.top_radius = 0.014; scyl.bottom_radius = 0.014; scyl.height = s_len; scyl.radial_segments = 6
			st.mesh = scyl; st.material_override = string_mat
			st.position = Vector3(bpos.x * 0.5, s_len * 0.5, bpos.z * 0.5)
			st.rotation.z = -bpos.x * 0.22
			cluster.add_child(st)

			var bal := MeshInstance3D.new()
			var bsp := SphereMesh.new()
			bsp.radius = 0.30; bsp.height = 0.72
			bal.mesh = bsp
			bal.material_override = ToonMat.make(cols[(idx * 2 + j) % cols.size()], "", {"outline_width": 1.1})
			bal.position = bpos
			cluster.add_child(bal)

		_balloons.append({"node": cluster})


func _build_memory_pillars() -> void:
	var specs := [
		{
			"title": "1. KENALI EMOSIKU",
			"hint": "Lentera Pos 1-2\nTekan [E / Aksi]",
			"color": Color(0.28, 0.66, 0.96),
		},
		{
			"title": "2. TENANGKAN DIRI",
			"hint": "Lentera Pos 3-5\nTekan [E / Aksi]",
			"color": Color(0.22, 0.76, 0.48),
		},
		{
			"title": "3. EMPATI & 3 PRINSIP",
			"hint": "Lentera Pos 6-7\nTekan [E / Aksi]",
			"color": Color(0.94, 0.44, 0.36),
		},
	]

	var stone_mat := ToonMat.make(Color(0.95, 0.90, 0.80), "", {"outline_width": 1.15})
	var trim_mat := ToonMat.make(Color(0.94, 0.76, 0.24), "", {"outline_width": 1.1})

	for i in range(specs.size()):
		var sp: Dictionary = specs[i]
		var pos: Vector3 = pillar_positions[i]
		var root := Node3D.new()
		root.position = pos
		add_child(root)

		var base_plate := MeshInstance3D.new()
		var bp := CylinderMesh.new()
		bp.top_radius = 0.68; bp.bottom_radius = 0.76; bp.height = 0.14; bp.radial_segments = 16
		base_plate.mesh = bp; base_plate.material_override = trim_mat; base_plate.position = Vector3(0.0, 0.07, 0.0)
		root.add_child(base_plate)

		var ped := MeshInstance3D.new()
		var pc := CylinderMesh.new()
		pc.top_radius = 0.34; pc.bottom_radius = 0.42; pc.height = 1.05; pc.radial_segments = 12
		ped.mesh = pc; ped.material_override = stone_mat; ped.position = Vector3(0.0, 0.64, 0.0)
		root.add_child(ped)
		_add_box_collider(root, Vector3(0.86, 1.3, 0.86), Vector3(0.0, 0.65, 0.0))

		var col_c: Color = sp["color"]
		var gem_mat := ToonMat.make(col_c, "", {"emission_color": col_c, "emission_energy": 0.45, "unique": true})
		var gem := MeshInstance3D.new()
		gem.mesh = _make_3d_star_mesh(0.42, 0.20, 0.12)
		gem.material_override = gem_mat
		gem.position = Vector3(0.0, 1.65, 0.0)
		root.add_child(gem)

		var lbl := Label3D.new()
		lbl.text = "%s\n%s" % [str(sp["title"]), str(sp["hint"])]
		lbl.font_size = 30; lbl.outline_size = 7; lbl.modulate = Color(1.0, 0.98, 0.88)
		lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		lbl.position = Vector3(0.0, 2.48, 0.0)
		root.add_child(lbl)

		var burst := GPUParticles3D.new()
		burst.position = Vector3(0.0, 1.65, 0.0)
		burst.amount = 24
		burst.lifetime = 0.85
		burst.one_shot = true
		burst.explosiveness = 0.92
		burst.emitting = false
		var bpm := ParticleProcessMaterial.new()
		bpm.direction = Vector3(0.0, 1.0, 0.0)
		bpm.spread = 95.0
		bpm.initial_velocity_min = 2.0
		bpm.initial_velocity_max = 4.2
		bpm.gravity = Vector3(0.0, -4.2, 0.0)
		bpm.scale_min = 0.08; bpm.scale_max = 0.15
		bpm.color = Color(1.0, 0.90, 0.30)
		burst.process_material = bpm
		var bmesh := BoxMesh.new()
		bmesh.size = Vector3(0.45, 0.45, 0.14)
		var bm := StandardMaterial3D.new()
		bm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		bm.albedo_color = Color(1.0, 0.92, 0.35)
		bmesh.material = bm
		burst.draw_pass_1 = bmesh
		root.add_child(burst)

		var area := Area3D.new()
		area.collision_layer = 4
		area.collision_mask = 2
		var acol := CollisionShape3D.new()
		var ash := CylinderShape3D.new()
		ash.radius = 2.15; ash.height = 2.4
		acol.shape = ash; acol.position = Vector3(0.0, 1.2, 0.0)
		area.add_child(acol)
		root.add_child(area)
		var pillar_idx := i
		area.body_entered.connect(func(body: Node3D) -> void:
			if body is NaraController:
				pillar_zone_changed.emit(pillar_idx, true)
		)
		area.body_exited.connect(func(body: Node3D) -> void:
			if body is NaraController:
				pillar_zone_changed.emit(pillar_idx, false)
		)

		_pillars.append({
			"root": root,
			"gem": gem,
			"gem_mat": gem_mat,
			"label": lbl,
			"burst": burst,
			"title": sp["title"],
			"lit": false,
		})


func _build_cheering_friends() -> void:
	# All 6 Basic Emotions from Pos 2 lining the royal carpet + Bima & Sinta welcoming Nara at the Podium!
	var lineup := [
		# 6 Emosi Dasar (matching Pos 2 signature colors!)
		{"name": "SEDIH", "pos": Vector3(-4.2, 0.0, 2.2), "rot": 74.0, "shirt": Color(0.28, 0.58, 0.92), "bot": Color(0.22, 0.34, 0.56), "hair": Color(0.16, 0.14, 0.20)},
		{"name": "MARAH", "pos": Vector3(4.2, 0.0, 2.2), "rot": -74.0, "shirt": Color(0.92, 0.28, 0.26), "bot": Color(0.36, 0.22, 0.22), "hair": Color(0.18, 0.10, 0.08)},
		{"name": "TAKUT", "pos": Vector3(-4.2, 0.0, -2.2), "rot": 68.0, "shirt": Color(0.58, 0.38, 0.86), "bot": Color(0.30, 0.26, 0.48), "hair": Color(0.18, 0.12, 0.18)},
		{"name": "BAHAGIA", "pos": Vector3(4.2, 0.0, -2.2), "rot": -68.0, "shirt": Color(0.98, 0.80, 0.18), "bot": Color(0.28, 0.56, 0.84), "hair": Color(0.26, 0.16, 0.08)},
		{"name": "JIJIK", "pos": Vector3(-4.2, 0.0, -6.6), "rot": 58.0, "shirt": Color(0.26, 0.74, 0.42), "bot": Color(0.26, 0.44, 0.30), "hair": Color(0.16, 0.14, 0.10)},
		{"name": "TERKEJUT", "pos": Vector3(4.2, 0.0, -6.6), "rot": -58.0, "shirt": Color(0.98, 0.54, 0.20), "bot": Color(0.32, 0.36, 0.58), "hair": Color(0.22, 0.12, 0.08)},
		# Best Friends Bima & Sinta welcoming Nara right beside the Grand Finish Podium!
		{"name": "BIMA", "pos": Vector3(-4.1, 0.0, -10.4), "rot": 40.0, "shirt": Color(0.88, 0.34, 0.30), "bot": Color(0.24, 0.36, 0.62), "hair": Color(0.16, 0.12, 0.10)},
		{"name": "SINTA", "pos": Vector3(4.1, 0.0, -10.4), "rot": -40.0, "shirt": Color(0.94, 0.46, 0.64), "bot": Color(0.96, 0.68, 0.24), "hair": Color(0.24, 0.14, 0.08)},
	]
	for info: Dictionary in lineup:
		var root := Node3D.new()
		root.position = info["pos"]
		root.rotation_degrees.y = float(info["rot"])
		add_child(root)

		var skin := ToonMat.make(Color(0.98, 0.82, 0.70))
		var shirt := ToonMat.make(info["shirt"])
		var bot := ToonMat.make(info["bot"])
		var hair := ToonMat.make(info["hair"])
		var eye_mat := ToonMat.make(Color(0.10, 0.08, 0.12), "", {"outline": false})

		for sx: float in [-0.14, 0.14]:
			var leg := MeshInstance3D.new()
			var lc := CapsuleMesh.new()
			lc.radius = 0.08; lc.height = 0.42
			leg.mesh = lc; leg.material_override = bot; leg.position = Vector3(sx, 0.26, 0.0)
			root.add_child(leg)

		var torso := MeshInstance3D.new()
		var tc := CylinderMesh.new()
		tc.top_radius = 0.22; tc.bottom_radius = 0.25; tc.height = 0.50
		torso.mesh = tc; torso.material_override = shirt; torso.position = Vector3(0.0, 0.78, 0.0)
		root.add_child(torso)

		var la := _make_arm(-0.30, shirt, skin)
		var ra := _make_arm(0.30, shirt, skin)
		root.add_child(la)
		root.add_child(ra)

		var head := MeshInstance3D.new()
		var hsp := SphereMesh.new()
		hsp.radius = 0.35; hsp.height = 0.68
		head.mesh = hsp; head.material_override = skin; head.position = Vector3(0.0, 1.38, 0.0)
		root.add_child(head)
		var hcap := MeshInstance3D.new()
		var hcsp := SphereMesh.new()
		hcsp.radius = 0.37; hcsp.height = 0.70
		hcap.mesh = hcsp; hcap.material_override = hair; hcap.position = Vector3(0.0, 1.44, -0.05)
		root.add_child(hcap)
		for side: float in [-1.0, 1.0]:
			var eye := MeshInstance3D.new()
			var esp := SphereMesh.new()
			esp.radius = 0.045; esp.height = 0.09
			eye.mesh = esp; eye.material_override = eye_mat; eye.position = Vector3(side * 0.13, 1.37, 0.32)
			root.add_child(eye)

		var tag := Label3D.new()
		tag.text = str(info["name"])
		tag.font_size = 30; tag.outline_size = 7; tag.modulate = Color(1.0, 0.96, 0.80)
		tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED; tag.position = Vector3(0.0, 2.22, 0.0)
		root.add_child(tag)

		var heart := Label3D.new()
		heart.text = "♥"
		heart.font_size = 44; heart.outline_size = 6; heart.modulate = Color(1.0, 0.42, 0.62)
		heart.billboard = BaseMaterial3D.BILLBOARD_ENABLED; heart.position = Vector3(0.0, 2.65, 0.0)
		heart.visible = false
		root.add_child(heart)

		_add_box_collider(root, Vector3(0.85, 1.8, 0.85), Vector3(0.0, 0.9, 0.0))
		_cheering_friends.append({"root": root, "l_arm": la, "r_arm": ra, "heart": heart})


func _make_arm(x_off: float, shirt: Material, skin: Material) -> Node3D:
	var g := Node3D.new()
	g.position = Vector3(x_off, 0.96, 0.0)
	var hand := MeshInstance3D.new()
	var hc := CapsuleMesh.new()
	hc.radius = 0.07; hc.height = 0.36
	hand.mesh = hc; hand.material_override = skin; hand.position = Vector3(0.0, -0.18, 0.0)
	g.add_child(hand)
	var sl := MeshInstance3D.new()
	var sp := SphereMesh.new()
	sp.radius = 0.10; sp.height = 0.20
	sl.mesh = sp; sl.material_override = shirt
	g.add_child(sl)
	return g


func _build_3d_golden_trophy() -> Node3D:
	# Multi-part sculpted 3D Golden Trophy Cup ("Piala Emas"):
	# Walnut base + golden stem + flared golden chalice + twin curved golden handles + spinning star crown!
	var cup_root := Node3D.new()

	var walnut_mat := ToonMat.make(Color(0.32, 0.19, 0.11), "", {"outline_width": 1.15})
	_trophy_cup_mat = ToonMat.make(Color(1.0, 0.82, 0.18), "", {"emission_color": Color(1.0, 0.82, 0.16), "emission_energy": 0.28, "unique": true})
	var rim_mat := ToonMat.make(Color(1.0, 0.93, 0.45), "", {"outline_width": 1.0})

	# 1. Walnut wooden trophy base
	var base_w := MeshInstance3D.new()
	var bc := CylinderMesh.new()
	bc.top_radius = 0.22; bc.bottom_radius = 0.27; bc.height = 0.15; bc.radial_segments = 16
	base_w.mesh = bc; base_w.material_override = walnut_mat; base_w.position = Vector3(0.0, 0.075, 0.0)
	cup_root.add_child(base_w)

	# 2. Golden plaque plate on front of base
	var plaque := MeshInstance3D.new()
	var plb := BoxMesh.new()
	plb.size = Vector3(0.22, 0.08, 0.04)
	plaque.mesh = plb; plaque.material_override = rim_mat; plaque.position = Vector3(0.0, 0.08, 0.23)
	cup_root.add_child(plaque)

	# 3. Golden foot & stem
	var foot := MeshInstance3D.new()
	var fc := CylinderMesh.new()
	fc.top_radius = 0.07; fc.bottom_radius = 0.17; fc.height = 0.18; fc.radial_segments = 14
	foot.mesh = fc; foot.material_override = _trophy_cup_mat; foot.position = Vector3(0.0, 0.23, 0.0)
	cup_root.add_child(foot)

	var knob := MeshInstance3D.new()
	var ksp := SphereMesh.new()
	ksp.radius = 0.10; ksp.height = 0.16
	knob.mesh = ksp; knob.material_override = rim_mat; knob.position = Vector3(0.0, 0.34, 0.0)
	cup_root.add_child(knob)

	# 4. Flared Golden Chalice Cup
	var chalice := MeshInstance3D.new()
	var chc := CylinderMesh.new()
	chc.top_radius = 0.34; chc.bottom_radius = 0.11; chc.height = 0.46; chc.radial_segments = 18
	chalice.mesh = chc; chalice.material_override = _trophy_cup_mat; chalice.position = Vector3(0.0, 0.61, 0.0)
	cup_root.add_child(chalice)

	# 5. Thick gleaming upper chalice lip
	var lip := MeshInstance3D.new()
	var lc := TorusMesh.new()
	lc.inner_radius = 0.29; lc.outer_radius = 0.36; lc.rings = 18; lc.ring_segments = 10
	lip.mesh = lc; lip.material_override = rim_mat; lip.position = Vector3(0.0, 0.84, 0.0)
	cup_root.add_child(lip)

	# 6. Twin curved golden side handles (left & right!)
	for side: float in [-1.0, 1.0]:
		var handle := MeshInstance3D.new()
		var hm := TorusMesh.new()
		hm.inner_radius = 0.12; hm.outer_radius = 0.18; hm.rings = 16; hm.ring_segments = 10
		handle.mesh = hm
		handle.material_override = _trophy_cup_mat
		handle.position = Vector3(side * 0.31, 0.64, 0.0)
		handle.rotation_degrees = Vector3(90.0, 0.0, 0.0)
		cup_root.add_child(handle)

	# 7. Spinning Golden Star Crest floating right above the chalice rim
	_trophy_star_crown = MeshInstance3D.new()
	_trophy_star_crown.mesh = _make_3d_star_mesh(0.28, 0.13, 0.08)
	_trophy_star_crown.material_override = _trophy_cup_mat
	_trophy_star_crown.position = Vector3(0.0, 1.12, 0.0)
	cup_root.add_child(_trophy_star_crown)

	# 8. Attached Golden Sparkle Shower orbiting the trophy!
	_trophy_sparkles = GPUParticles3D.new()
	_trophy_sparkles.position = Vector3(0.0, 0.88, 0.0)
	_trophy_sparkles.amount = 28
	_trophy_sparkles.lifetime = 1.05
	_trophy_sparkles.emitting = false
	var spm := ParticleProcessMaterial.new()
	spm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	spm.emission_sphere_radius = 0.42
	spm.direction = Vector3(0.0, 1.0, 0.0)
	spm.spread = 80.0
	spm.initial_velocity_min = 0.7
	spm.initial_velocity_max = 1.8
	spm.gravity = Vector3(0.0, -0.5, 0.0)
	spm.scale_min = 0.07; spm.scale_max = 0.14
	spm.color = Color(1.0, 0.94, 0.38)
	_trophy_sparkles.process_material = spm
	var smesh := BoxMesh.new()
	smesh.size = Vector3(0.36, 0.36, 0.12)
	var smat := StandardMaterial3D.new()
	smat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	smat.albedo_color = Color(1.0, 0.95, 0.45)
	smesh.material = smat
	_trophy_sparkles.draw_pass_1 = smesh
	cup_root.add_child(_trophy_sparkles)

	return cup_root


func _build_trophy_podium() -> void:
	_podium_root = Node3D.new()
	_podium_root.position = podium_position
	add_child(_podium_root)

	var stone_mat := ToonMat.make(Color(0.96, 0.92, 0.82), "", {"outline_width": 1.2})
	var gold_mat := ToonMat.make(Color(0.96, 0.76, 0.18), "", {"outline_width": 1.2})
	var brick_mat := ToonMat.make(Color(0.84, 0.44, 0.34), "res://assets/textures/brick.webp", {"triplanar": true, "triplanar_scale": 0.48})
	var wood_mat := ToonMat.make(Color(0.62, 0.39, 0.22), "res://assets/textures/wood_planks.webp", {"triplanar": true, "triplanar_scale": 0.42})

	# Wide circular celebratory dais (0.14m high so Nara walks straight up smoothly!)
	var dais := MeshInstance3D.new()
	var dc := CylinderMesh.new()
	dc.top_radius = 3.35; dc.bottom_radius = 3.60; dc.height = 0.14; dc.radial_segments = 24
	dais.mesh = dc; dais.material_override = stone_mat; dais.position = Vector3(0.0, 0.07, 0.0)
	_podium_root.add_child(dais)

	var rim := MeshInstance3D.new()
	var rc := CylinderMesh.new()
	rc.top_radius = 2.95; rc.bottom_radius = 2.95; rc.height = 0.16; rc.radial_segments = 24
	rim.mesh = rc; rim.material_override = gold_mat; rim.position = Vector3(0.0, 0.08, 0.0)
	_podium_root.add_child(rim)

	# Trophy Pedestal behind the center spot (leaves clean standing stage in front at z=+1.15!)
	var ped := MeshInstance3D.new()
	var pc := CylinderMesh.new()
	pc.top_radius = 0.66; pc.bottom_radius = 0.80; pc.height = 1.22; pc.radial_segments = 16
	ped.mesh = pc; ped.material_override = stone_mat; ped.position = Vector3(0.0, 0.68, -0.85)
	_podium_root.add_child(ped)
	_add_box_collider(_podium_root, Vector3(1.35, 1.35, 1.35), Vector3(0.0, 0.68, -0.85))

	# Real 3D Golden Trophy Cup sitting proudly on the pedestal (ready to fly into Nara's hands!)
	_trophy_node = _build_3d_golden_trophy()
	_trophy_node.position = Vector3(0.0, 1.44, -0.85)
	_trophy_node.scale = Vector3(1.18, 1.18, 1.18)
	_podium_root.add_child(_trophy_node)

	# Grand Finish Archway right behind the Trophy Pedestal (completely unobstructed!)
	for side: float in [-1.0, 1.0]:
		var pil := MeshInstance3D.new()
		var pbox := BoxMesh.new()
		pbox.size = Vector3(0.95, 4.3, 0.95)
		pil.mesh = pbox; pil.material_override = brick_mat; pil.position = Vector3(side * 3.55, 2.15, -2.9)
		_podium_root.add_child(pil)
		_add_box_collider(_podium_root, Vector3(1.0, 4.3, 1.0), Vector3(side * 3.55, 2.15, -2.9))

	var beam := MeshInstance3D.new()
	var bb := BoxMesh.new()
	bb.size = Vector3(8.1, 0.58, 0.70)
	beam.mesh = bb; beam.material_override = wood_mat; beam.position = Vector3(0.0, 4.35, -2.9)
	_podium_root.add_child(beam)

	var banner := MeshInstance3D.new()
	var bnb := BoxMesh.new()
	bnb.size = Vector3(6.4, 1.42, 0.22)
	banner.mesh = bnb; banner.material_override = ToonMat.make(Color(0.68, 0.16, 0.26), "", {"outline_width": 1.4})
	banner.position = Vector3(0.0, 5.25, -2.82)
	_podium_root.add_child(banner)

	var title := Label3D.new()
	title.text = "FINISH • POS 8\nAKU TAHU EMOSIKU!"
	title.font_size = 46; title.outline_size = 9; title.modulate = Color(1.0, 0.94, 0.54)
	title.position = Vector3(0.0, 5.25, -2.66)
	_podium_root.add_child(title)

	_trophy_prompt_lbl = Label3D.new()
	_trophy_prompt_lbl.text = "PIALA EMAS (0/3 Lentera)\nNyalakan 3 Lentera Kenangan dulu!"
	_trophy_prompt_lbl.font_size = 33; _trophy_prompt_lbl.outline_size = 8; _trophy_prompt_lbl.modulate = Color(1.0, 0.98, 0.86)
	_trophy_prompt_lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_trophy_prompt_lbl.position = Vector3(0.0, 3.65, -0.85)
	_podium_root.add_child(_trophy_prompt_lbl)

	# 5 Multi-color Fireworks Emitters around the Finish Arch!
	var fw_specs := [
		[Vector3(-3.6, 4.9, -2.6), Color(1.0, 0.84, 0.22)],
		[Vector3(-1.8, 5.7, -2.5), Color(0.28, 0.86, 0.96)],
		[Vector3(0.0, 6.2, -2.6), Color(1.0, 0.42, 0.62)],
		[Vector3(1.8, 5.7, -2.5), Color(0.32, 0.90, 0.50)],
		[Vector3(3.6, 4.9, -2.6), Color(1.0, 0.60, 0.24)],
	]
	for spec in fw_specs:
		var fw := GPUParticles3D.new()
		fw.position = spec[0]
		fw.amount = 48
		fw.lifetime = 1.65
		fw.one_shot = true
		fw.explosiveness = 0.92
		fw.emitting = false
		var cpm := ParticleProcessMaterial.new()
		cpm.direction = Vector3(0.0, 1.0, 0.0)
		cpm.spread = 120.0
		cpm.initial_velocity_min = 3.4
		cpm.initial_velocity_max = 6.8
		cpm.gravity = Vector3(0.0, -4.6, 0.0)
		cpm.scale_min = 0.11; cpm.scale_max = 0.22
		cpm.color = spec[1]
		fw.process_material = cpm
		var cbox := BoxMesh.new()
		cbox.size = Vector3(0.58, 0.58, 0.16)
		var cmat := StandardMaterial3D.new()
		cmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		cmat.albedo_color = spec[1]
		cbox.material = cmat
		fw.draw_pass_1 = cbox
		_podium_root.add_child(fw)
		_fireworks.append(fw)

	# Continuous Celebratory Confetti Rain over the Podium once Nara lifts the Trophy!
	_confetti_rain = GPUParticles3D.new()
	_confetti_rain.position = Vector3(0.0, 5.2, 0.4)
	_confetti_rain.amount = 90
	_confetti_rain.lifetime = 2.8
	_confetti_rain.emitting = false
	var rmp := ParticleProcessMaterial.new()
	rmp.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	rmp.emission_box_extents = Vector3(4.5, 0.2, 3.2)
	rmp.direction = Vector3(0.0, -1.0, 0.0)
	rmp.spread = 28.0
	rmp.initial_velocity_min = 0.8
	rmp.initial_velocity_max = 1.8
	rmp.gravity = Vector3(0.0, -1.2, 0.0)
	rmp.angular_velocity_min = -180.0
	rmp.angular_velocity_max = 180.0
	rmp.scale_min = 0.08; rmp.scale_max = 0.16
	rmp.color = Color(1.0, 0.88, 0.32)
	_confetti_rain.process_material = rmp
	var conf_m := BoxMesh.new()
	conf_m.size = Vector3(0.55, 0.32, 0.06)
	var conf_mat := StandardMaterial3D.new()
	conf_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	conf_mat.albedo_color = Color(1.0, 0.88, 0.34)
	conf_m.material = conf_mat
	_confetti_rain.draw_pass_1 = conf_m
	_podium_root.add_child(_confetti_rain)

	# Interaction zone covering the trophy dais
	var area := Area3D.new()
	area.collision_layer = 4
	area.collision_mask = 2
	var col := CollisionShape3D.new()
	var sh := CylinderShape3D.new()
	sh.radius = 3.25; sh.height = 2.6
	col.shape = sh; col.position = Vector3(0.0, 1.3, 0.0)
	area.add_child(col)
	_podium_root.add_child(area)
	area.body_entered.connect(func(body: Node3D) -> void:
		if body is NaraController:
			trophy_zone_changed.emit(true)
	)
	area.body_exited.connect(func(body: Node3D) -> void:
		if body is NaraController:
			trophy_zone_changed.emit(false)
	)


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
		pil.mesh = pb; pil.material_override = brick_mat; pil.position = Vector3(side * 2.8, 1.6, 0.0)
		back.add_child(pil)
	var door := MeshInstance3D.new()
	var db := BoxMesh.new()
	db.size = Vector3(4.8, 3.08, 0.22)
	door.mesh = db; door.material_override = wood_mat; door.position = Vector3(0.0, 1.54, 0.0)
	back.add_child(door)
	var beam := MeshInstance3D.new()
	var bb := BoxMesh.new()
	bb.size = Vector3(6.4, 0.5, 0.6)
	beam.mesh = bb; beam.material_override = wood_mat; beam.position = Vector3(0.0, 3.3, 0.0)
	back.add_child(beam)


func _build_brick_enclosure() -> void:
	var brick_mat := ToonMat.make(Color(0.84, 0.44, 0.34), "res://assets/textures/brick.webp", {"triplanar": true, "triplanar_scale": 0.48})
	var cap_mat := ToonMat.make(Color(0.94, 0.88, 0.76), "", {"outline_width": 1.1})
	for side: float in [-1.0, 1.0]:
		var x := side * 8.6
		var wall := MeshInstance3D.new()
		var wb := BoxMesh.new()
		wb.size = Vector3(0.55, 1.05, 28.0)
		wall.mesh = wb; wall.material_override = brick_mat; wall.position = Vector3(x, 0.52, -3.5)
		add_child(wall)
		var cap := MeshInstance3D.new()
		var cb := BoxMesh.new()
		cb.size = Vector3(0.68, 0.14, 28.2)
		cap.mesh = cb; cap.material_override = cap_mat; cap.position = Vector3(x, 1.1, -3.5)
		add_child(cap)
		_add_box_collider(self, Vector3(0.7, 6.0, 28.5), Vector3(x, 3.0, -3.5))

	var back_wall := MeshInstance3D.new()
	var bwb := BoxMesh.new()
	bwb.size = Vector3(17.6, 1.05, 0.55)
	back_wall.mesh = bwb; back_wall.material_override = brick_mat; back_wall.position = Vector3(0.0, 0.52, -17.2)
	add_child(back_wall)
	var back_cap := MeshInstance3D.new()
	var bcb := BoxMesh.new()
	bcb.size = Vector3(17.8, 0.14, 0.68)
	back_cap.mesh = bcb; back_cap.material_override = cap_mat; back_cap.position = Vector3(0.0, 1.1, -17.2)
	add_child(back_cap)

	# Visual flanking brick walls sealing left & right of entrance gate (z=10.2) + 360-deg horizon hills & trees!
	StorybookProps.build_flanking_brick_walls(self, 10.2, 2.8, 8.6, 1.05)
	StorybookProps.spawn_horizon_backdrop_360(self, -18.5, 11.0, 9.0)

	_add_box_collider(self, Vector3(18.0, 6.0, 0.6), Vector3(0.0, 3.0, -17.2))
	_add_box_collider(self, Vector3(18.0, 6.0, 0.6), Vector3(0.0, 3.0, 10.2))


func _build_horizon_hills_and_trees() -> void:
	var hill_mat := ToonMat.make(Color(0.30, 0.66, 0.28), "res://assets/textures/grass.webp", {"triplanar": true, "triplanar_scale": 0.14, "outline": false})
	for h in [
		[Vector3(-34.0, -3.5, -14.0), Vector3(1.6, 0.65, 1.2), 14.0],
		[Vector3(34.0, -3.5, -14.0), Vector3(1.6, 0.68, 1.2), 14.5],
		[Vector3(0.0, -4.5, -42.0), Vector3(2.4, 0.62, 1.2), 18.0],
	]:
		var m := MeshInstance3D.new()
		var sp := SphereMesh.new()
		sp.radius = float(h[2]); sp.height = float(h[2]) * 2.0
		m.mesh = sp; m.scale = h[1]; m.position = h[0]; m.material_override = hill_mat
		add_child(m)

	var trunk_mat := ToonMat.make(Color(0.55, 0.36, 0.22), "res://assets/textures/bark.webp", {"triplanar": true})
	var leaf_mat := ToonMat.make(Color(0.28, 0.68, 0.30), "res://assets/textures/leaf_canopy.webp", {"triplanar": true, "triplanar_scale": 0.45})
	for t in [
		[Vector3(-7.0, 0.0, 6.4), 1.15], [Vector3(7.0, 0.0, 6.4), 1.15],
		[Vector3(-7.2, 0.0, -4.8), 1.2], [Vector3(7.2, 0.0, -4.8), 1.2],
		[Vector3(-6.8, 0.0, -14.8), 1.25], [Vector3(6.8, 0.0, -14.8), 1.25],
	]:
		var tr := Node3D.new()
		tr.position = t[0]
		var sc: float = float(t[1])
		tr.scale = Vector3(sc, sc, sc)
		add_child(tr)
		var trunk := MeshInstance3D.new()
		var tc := CylinderMesh.new()
		tc.top_radius = 0.26; tc.bottom_radius = 0.38; tc.height = 2.2
		trunk.mesh = tc; trunk.material_override = trunk_mat; trunk.position = Vector3(0.0, 1.1, 0.0)
		tr.add_child(trunk)
		var cr := MeshInstance3D.new()
		var sp := SphereMesh.new()
		sp.radius = 1.45; sp.height = 2.8
		cr.mesh = sp; cr.material_override = leaf_mat; cr.position = Vector3(0.0, 2.95, 0.0)
		tr.add_child(cr)

	var fcols := [Color(1.0, 0.56, 0.68), Color(0.99, 0.88, 0.28), Color(0.58, 0.77, 0.99), Color(0.99, 0.96, 0.92)]
	for i in range(10):
		var side := -1.0 if i % 2 == 0 else 1.0
		StorybookProps.spawn_flower(self, Vector3(side * 6.8, 0.0, 4.2 - float(i) * 2.0), fcols[i % fcols.size()])


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
