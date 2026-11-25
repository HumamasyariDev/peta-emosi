class_name Pos6Props
extends Node3D

signal zone_changed(zone_id: String, entered: bool)
signal block_touched(block_idx: int)
signal tower_zone_touched
signal danger_zone_touched
signal next_route_entered

# 1=Bima Safe Space, 35=Bima 3 Blocks, 2=Sinta Safe Space, 3=Take Water, 4=Place Water for Sinta, 5=Done
var step_positions: Dictionary = {
	1: Vector3(-1.4, 0.0, -5.0),
	2: Vector3(3.2, 0.0, -9.8),
	3: Vector3(4.8, 0.0, -5.6),
	4: Vector3(2.2, 0.0, -11.4),
}
var bima_position: Vector3 = Vector3(-1.4, 0.0, -8.8)
var tower_position: Vector3 = Vector3(-3.0, 0.0, -8.6)
var sinta_position: Vector3 = Vector3(3.8, 0.0, -13.2)
var sinta_table_pos: Vector3 = Vector3(2.2, 0.0, -11.4)
var star_position: Vector3 = Vector3(0.0, 0.0, -17.8)
var exit_gate_position: Vector3 = Vector3(0.0, 0.0, -23.0)

var _time: float = 0.0
var _clouds: Array[Node3D] = []
var _butterflies: Array[Dictionary] = []
var _guide_arrow: Node3D
var _beacon_pillar: MeshInstance3D
var _comic_bubble: Label3D
var _comic_timer: float = 0.0

# Friend 1: Bima (needs play-together: 3 blocks in order!)
var _bima_root: Node3D
var _bima_head: Node3D
var _bima_left_arm: Node3D
var _bima_right_arm: Node3D
var _thor_light: OmniLight3D
var _lightning_cd: float = 1.8
var _bima_danger_ring: MeshInstance3D
var _bima_hearts: Array[Label3D] = []
var _bima_mood: String = "angry" # "angry", "cooling", "calm"

# Friend 2: Sinta (needs alone time + quiet water delivery!)
var _sinta_root: Node3D
var _sinta_head: Node3D
var _sinta_left_arm: Node3D
var _sinta_right_arm: Node3D
var _sinta_danger_ring: MeshInstance3D
var _sinta_hearts: Array[Label3D] = []
var _sinta_mood: String = "angry" # "angry", "cooling", "calm"
var _sinta_delivered_bottle: Node3D

# Toy Blocks Rescue (3 scattered blocks -> stack in order 1. MERAH -> 2. KUNING -> 3. BIRU)
var _block_spots: Array[Vector3] = [
	Vector3(-5.2, 0.0, -4.8),
	Vector3(0.8, 0.0, -10.8),
	Vector3(-4.8, 0.0, -12.6),
]
var _block_colors: Array[Color] = [
	Color(0.92, 0.30, 0.28),
	Color(0.96, 0.76, 0.16),
	Color(0.18, 0.68, 0.66),
]
var _block_names: Array[String] = ["MERAH", "KUNING", "BIRU"]
var _scattered_blocks: Array[Node3D] = []
var _block_collected: Array[bool] = [false, false, false]
var _carrying_block_idx: int = -1
var _carried_block_mesh: Node3D
var _tower_blocks: Array[MeshInstance3D] = []
var _tower_ring: MeshInstance3D
var _tower_lbl: Label3D
var _blocks_active: bool = false

# Zone visuals
var _ring1: MeshInstance3D
var _lbl1: Label3D
var _ring2: MeshInstance3D
var _lbl2: Label3D
var _ring3: MeshInstance3D
var _lbl3: Label3D
var _water_bottle: Node3D
var _carried_bottle: Node3D
var _ring4: MeshInstance3D
var _lbl4: Label3D

# Star & Pos 7 Exit Gate
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
	_build_picnic_play_corner()
	_build_bima_friend()
	_build_sinta_friend()
	_build_scattered_blocks_and_tower()
	_build_zone1_bima_safe_space()
	_build_zone2_sinta_safe_space()
	_build_zone3_water_stand()
	_build_zone4_sinta_care_table()
	_build_star_and_exit_gate()
	_build_trees()
	_guide_arrow = StorybookProps.make_guide_arrow()
	add_child(_guide_arrow)
	_build_waypoint_beacon()
	_clouds = StorybookProps.spawn_clouds(self)
	_butterflies = StorybookProps.spawn_butterflies(self, [
		Vector3(-4.8, 1.5, 2.2), Vector3(4.8, 1.6, -3.5), Vector3(-4.4, 1.5, -11.0), Vector3(4.2, 1.6, -16.5)
	])
	ToonMat.optimize_tree(self)
	set_active_step(1)


func get_bima_node() -> Node3D:
	return _bima_root


func get_sinta_node() -> Node3D:
	return _sinta_root


func prepare_intro_cutscene() -> void:
	_bima_mood = "cooling"
	_sinta_mood = "angry"
	if _bima_danger_ring != null:
		_bima_danger_ring.visible = false
	for h: Label3D in _bima_hearts:
		h.visible = false
	for i in range(_scattered_blocks.size()):
		if _scattered_blocks[i] != null:
			_scattered_blocks[i].visible = false
	for i in range(_tower_blocks.size()):
		if _tower_blocks[i] != null:
			_tower_blocks[i].visible = true
			_tower_blocks[i].position.y = 0.38 + float(i) * 0.48
			_tower_blocks[i].scale = Vector3.ONE
			_tower_blocks[i].rotation = Vector3.ZERO
	set_active_step(0)


func play_tower_collapse_cutscene() -> void:
	show_nara_bubble(bima_position, "Hati-hati... menaraku goyang!", 1.1)
	var wobble_tw := create_tween()
	for k in range(6):
		var ang := 12.0 if (k % 2 == 0) else -12.0
		for i in range(_tower_blocks.size()):
			var tb := _tower_blocks[i]
			if tb != null:
				wobble_tw.parallel().tween_property(tb, "rotation_degrees:z", ang * (0.6 + float(i) * 0.45), 0.10)
		wobble_tw.chain()
	await wobble_tw.finished

	Audio.play_sfx("thunder")
	for i in range(_tower_blocks.size()):
		var tb := _tower_blocks[i]
		if tb != null:
			tb.visible = false
			tb.rotation = Vector3.ZERO
		_launch_flying_block(i, tower_position + Vector3(0.0, 0.45 + float(i) * 0.48, 0.0), _block_spots[i] + Vector3(0.0, 0.26, 0.0))

	await get_tree().create_timer(0.82).timeout

	for i in range(_scattered_blocks.size()):
		var sb := _scattered_blocks[i]
		if sb != null:
			sb.visible = true
			sb.scale = Vector3(1.25, 0.70, 1.25)
			var btw := create_tween()
			btw.tween_property(sb, "scale", Vector3.ONE, 0.26).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	_bima_mood = "angry"
	_lightning_cd = 2.4
	strike_thor_lightning(bima_position)
	if _bima_danger_ring != null:
		_bima_danger_ring.visible = true
		_bima_danger_ring.scale = Vector3(0.05, 1.0, 0.05)
		var rtw := create_tween()
		rtw.tween_property(_bima_danger_ring, "scale", Vector3.ONE, 0.38).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	show_nara_bubble(bima_position, "Aaaah!! Menaraku roboh semua!!", 2.0)
	await get_tree().create_timer(1.25).timeout


func strike_thor_lightning(target_pos: Vector3 = Vector3.ZERO) -> void:
	var strike_pos := bima_position if target_pos == Vector3.ZERO else target_pos
	var bolt_root := Node3D.new()
	bolt_root.position = strike_pos
	add_child(bolt_root)

	var core_mat := StandardMaterial3D.new()
	core_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	core_mat.albedo_color = Color(0.92, 0.98, 1.0)
	core_mat.emission_enabled = true
	core_mat.emission = Color(0.55, 0.85, 1.0)
	core_mat.emission_energy_multiplier = 3.2

	var glow_mat := StandardMaterial3D.new()
	glow_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	glow_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glow_mat.albedo_color = Color(0.32, 0.72, 1.0, 0.55)
	glow_mat.emission_enabled = true
	glow_mat.emission = Color(0.28, 0.68, 1.0)
	glow_mat.emission_energy_multiplier = 2.0

	var pts: Array[Vector3] = [Vector3(randf_range(-0.6, 0.6), 14.5, randf_range(-0.4, 0.4))]
	var segs := 8
	for i in range(1, segs):
		var t := float(i) / float(segs)
		var y := lerpf(14.5, 1.55, t)
		var jitter := (1.0 - t * 0.55) * 0.85
		pts.append(Vector3(randf_range(-jitter, jitter), y, randf_range(-jitter * 0.6, jitter * 0.6)))
	pts.append(Vector3(0.0, 1.55, 0.0))

	for i in range(pts.size() - 1):
		var a := pts[i]
		var b := pts[i + 1]
		var seg_len := a.distance_to(b)
		if seg_len < 0.05:
			continue
		var mid := (a + b) * 0.5
		var dir := (b - a).normalized()
		var up_axis := Vector3.UP
		if absf(dir.dot(up_axis)) > 0.99:
			up_axis = Vector3.RIGHT
		var x_axis := up_axis.cross(dir).normalized()
		var z_axis := dir.cross(x_axis).normalized()
		var basis := Basis(x_axis, dir, z_axis)

		var core := MeshInstance3D.new()
		var cc := CylinderMesh.new()
		cc.top_radius = 0.055
		cc.bottom_radius = 0.045
		cc.height = seg_len + 0.06
		cc.radial_segments = 6
		core.mesh = cc
		core.material_override = core_mat
		core.transform = Transform3D(basis, mid)
		bolt_root.add_child(core)

		var glow := MeshInstance3D.new()
		var gc := CylinderMesh.new()
		gc.top_radius = 0.16
		gc.bottom_radius = 0.14
		gc.height = seg_len + 0.08
		gc.radial_segments = 6
		glow.mesh = gc
		glow.material_override = glow_mat
		glow.transform = Transform3D(basis, mid)
		bolt_root.add_child(glow)

	_spawn_ring_ripple(strike_pos, Color(0.50, 0.86, 1.0))

	if _thor_light != null:
		_thor_light.global_position = strike_pos + Vector3(0.0, 2.8, 0.6)
		_thor_light.light_energy = 5.5
		var ltw := create_tween()
		ltw.tween_property(_thor_light, "light_energy", 0.0, 0.28)

	var tw := create_tween()
	tw.tween_interval(0.09)
	tw.tween_property(bolt_root, "scale", Vector3(1.35, 1.0, 1.35), 0.05)
	tw.tween_property(bolt_root, "scale", Vector3(0.25, 1.0, 0.25), 0.14)
	tw.tween_callback(func() -> void:
		if is_instance_valid(bolt_root):
			bolt_root.queue_free()
	)


func _launch_flying_block(idx: int, start_pos: Vector3, end_pos: Vector3) -> void:
	var flyer := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.52, 0.52, 0.52)
	flyer.mesh = bm
	flyer.material_override = ToonMat.make(_block_colors[idx], "", {"emission_color": _block_colors[idx], "emission_energy": 0.35})
	flyer.position = start_pos
	add_child(flyer)

	var mid_pos := start_pos.lerp(end_pos, 0.5) + Vector3(0.0, 2.8 + float(idx) * 0.45, 0.0)
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_method(func(t: float) -> void:
		if not is_instance_valid(flyer):
			return
		var a := start_pos.lerp(mid_pos, t)
		var b := mid_pos.lerp(end_pos, t)
		flyer.position = a.lerp(b, t)
	, 0.0, 1.0, 0.80).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(flyer, "rotation_degrees", Vector3(420.0, 320.0 + float(idx) * 90.0, 260.0), 0.80)
	tw.chain().tween_callback(func() -> void:
		if is_instance_valid(flyer):
			flyer.queue_free()
	)


func trigger_danger_repel_fx(target_pos: Vector3 = Vector3.ZERO) -> void:
	var pos := bima_position if target_pos == Vector3.ZERO else target_pos
	strike_thor_lightning(pos)
	_spawn_ring_ripple(pos, Color(0.98, 0.22, 0.18))
	var ring := _bima_danger_ring if pos == bima_position else _sinta_danger_ring
	if ring != null and ring.visible:
		var tw := create_tween()
		tw.tween_property(ring, "scale", Vector3(1.24, 1.8, 1.24), 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(ring, "scale", Vector3.ONE, 0.22)


func trigger_zone_hover_fx(zone_id: String, entered: bool) -> void:
	var ring: MeshInstance3D = null
	var col := Color(0.98, 0.82, 0.24)
	var pos := Vector3.ZERO
	match zone_id:
		"step1":
			ring = _ring1; col = Color(0.98, 0.82, 0.24); pos = step_positions[1] as Vector3
		"step2":
			ring = _ring2; col = Color(0.96, 0.56, 0.72); pos = step_positions[2] as Vector3
		"step3":
			ring = _ring3; col = Color(0.28, 0.82, 0.98); pos = step_positions[3] as Vector3
		"step4":
			ring = _ring4; col = Color(0.24, 0.86, 0.56); pos = step_positions[4] as Vector3
	if ring == null or not ring.visible:
		return
	var tw := create_tween()
	if entered:
		Audio.play_sfx("select")
		tw.tween_property(ring, "scale", Vector3(1.18, 1.35, 1.18), 0.14).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(ring, "scale", Vector3(1.07, 1.0, 1.07), 0.16)
		_spawn_ring_ripple(pos, col)
	else:
		tw.tween_property(ring, "scale", Vector3.ONE, 0.18)


func _spawn_ring_ripple(world_pos: Vector3, col: Color) -> void:
	var wave := MeshInstance3D.new()
	var tor := TorusMesh.new()
	tor.inner_radius = 1.55
	tor.outer_radius = 1.72
	tor.rings = 24
	tor.ring_segments = 8
	wave.mesh = tor
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(col.r, col.g, col.b, 0.82)
	wave.material_override = mat
	wave.position = Vector3(world_pos.x, 0.16, world_pos.z)
	add_child(wave)

	var tw := create_tween().set_parallel(true)
	tw.tween_property(wave, "scale", Vector3(1.55, 1.0, 1.55), 0.50).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(wave, "position:y", 1.15, 0.50).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(mat, "albedo_color:a", 0.0, 0.50)
	tw.chain().tween_callback(func() -> void:
		if is_instance_valid(wave):
			wave.queue_free()
	)


func set_active_step(step_num: int) -> void:
	if _ring1 != null:
		_ring1.visible = (step_num == 1)
	if _lbl1 != null:
		_lbl1.visible = (step_num == 1)
	if _ring2 != null:
		_ring2.visible = (step_num == 2)
	if _lbl2 != null:
		_lbl2.visible = (step_num == 2)
	if _ring3 != null:
		_ring3.visible = (step_num == 3)
	if _lbl3 != null:
		_lbl3.visible = (step_num == 3)
	if _ring4 != null:
		_ring4.visible = (step_num == 4)
	if _lbl4 != null:
		_lbl4.visible = (step_num == 4)
	_blocks_active = (step_num == 35)
	_refresh_block_guides()
	if _tower_lbl != null:
		_tower_lbl.visible = (step_num == 35)
	if _beacon_pillar != null:
		if step_num == 35:
			var tgt := tower_position if _carrying_block_idx >= 0 else get_next_uncollected_block_pos()
			_beacon_pillar.position = Vector3(tgt.x, 3.6, tgt.z)
			_beacon_pillar.visible = true
		elif step_positions.has(step_num):
			var sp: Vector3 = step_positions[step_num] as Vector3
			_beacon_pillar.position = Vector3(sp.x, 3.6, sp.z)
			_beacon_pillar.visible = true
		elif step_num == 5:
			_beacon_pillar.position = Vector3(exit_gate_position.x, 3.6, exit_gate_position.z)
			_beacon_pillar.visible = true
		else:
			_beacon_pillar.visible = false


func get_expected_block_idx() -> int:
	return get_collected_block_count()


func get_block_name(idx: int) -> String:
	if idx >= 0 and idx < _block_names.size():
		return _block_names[idx]
	return "BALOK"


func shake_wrong_block(idx: int) -> void:
	if idx < 0 or idx >= _scattered_blocks.size():
		return
	var sb := _scattered_blocks[idx]
	if sb == null or not sb.visible:
		return
	var orig_x := _block_spots[idx].x
	var tw := create_tween()
	tw.tween_property(sb, "position:x", orig_x + 0.16, 0.06)
	tw.tween_property(sb, "position:x", orig_x - 0.16, 0.06)
	tw.tween_property(sb, "position:x", orig_x + 0.10, 0.06)
	tw.tween_property(sb, "position:x", orig_x, 0.06)


func _refresh_block_guides() -> void:
	var holding := (_carrying_block_idx >= 0)
	var exp_idx := get_expected_block_idx()
	for i in range(_scattered_blocks.size()):
		var sb := _scattered_blocks[i]
		if sb != null:
			var b_ring := sb.get_node_or_null("BlockRing") as Node3D
			if b_ring != null:
				b_ring.visible = _blocks_active and not holding and (i == exp_idx) and not _block_collected[i]
			var b_lbl := sb.get_node_or_null("BlockLbl") as Label3D
			if b_lbl != null:
				b_lbl.visible = _blocks_active and not _block_collected[i]
	if _tower_ring != null:
		_tower_ring.visible = _blocks_active and holding
	if _beacon_pillar != null and _blocks_active:
		var tgt := tower_position if holding else get_next_uncollected_block_pos()
		_beacon_pillar.position = Vector3(tgt.x, 3.6, tgt.z)


func is_carrying_block() -> bool:
	return _carrying_block_idx >= 0


func get_next_uncollected_block_pos() -> Vector3:
	for i in range(_block_spots.size()):
		if not _block_collected[i]:
			return _block_spots[i]
	return tower_position


func get_step_target(step_num: int) -> Vector3:
	if step_num == 35:
		return tower_position if _carrying_block_idx >= 0 else get_next_uncollected_block_pos()
	if step_positions.has(step_num):
		return step_positions[step_num] as Vector3
	return exit_gate_position + Vector3(0.0, 0.0, -1.0)


func show_nara_bubble(world_pos: Vector3, text: String, duration: float = 1.9) -> void:
	if _comic_bubble == null:
		_comic_bubble = Label3D.new()
		_comic_bubble.font_size = 40
		_comic_bubble.outline_size = 9
		_comic_bubble.modulate = Color(1.0, 0.98, 0.82)
		_comic_bubble.outline_modulate = Color(0.24, 0.12, 0.05)
		_comic_bubble.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		add_child(_comic_bubble)
	_comic_bubble.text = text
	_comic_bubble.position = world_pos + Vector3(0.0, 2.35, 0.0)
	_comic_bubble.visible = true
	_comic_timer = duration


func set_bima_cooling() -> void:
	_bima_mood = "cooling"
	if _bima_danger_ring != null:
		var tw_r := create_tween()
		tw_r.tween_property(_bima_danger_ring, "scale", Vector3(0.01, 0.01, 0.01), 0.35)
		tw_r.tween_callback(func() -> void:
			if is_instance_valid(_bima_danger_ring):
				_bima_danger_ring.visible = false
		)


func set_sinta_cooling() -> void:
	_sinta_mood = "cooling"
	if _sinta_danger_ring != null:
		var tw_r := create_tween()
		tw_r.tween_property(_sinta_danger_ring, "scale", Vector3(0.01, 0.01, 0.01), 0.35)
		tw_r.tween_callback(func() -> void:
			if is_instance_valid(_sinta_danger_ring):
				_sinta_danger_ring.visible = false
		)


func calm_bima_completely() -> void:
	_bima_mood = "calm"
	if _bima_danger_ring != null:
		_bima_danger_ring.visible = false
	for i in range(_block_collected.size()):
		_block_collected[i] = true
		if i < _scattered_blocks.size():
			_scattered_blocks[i].visible = false
		if i < _tower_blocks.size():
			_tower_blocks[i].visible = true
	for h: Label3D in _bima_hearts:
		h.visible = true


func calm_sinta_completely() -> void:
	_sinta_mood = "calm"
	if _sinta_danger_ring != null:
		_sinta_danger_ring.visible = false
	if _sinta_delivered_bottle != null:
		_sinta_delivered_bottle.visible = true
	for h: Label3D in _sinta_hearts:
		h.visible = true


func take_water_bottle(carrier: Node3D) -> void:
	if _water_bottle != null:
		_water_bottle.visible = false
	if carrier != null and _carried_bottle == null:
		_carried_bottle = _make_water_bottle_mesh()
		_carried_bottle.scale = Vector3(0.78, 0.78, 0.78)
		if carrier.has_method("get_carry_anchor"):
			var anchor: Node3D = carrier.call("get_carry_anchor") as Node3D
			if anchor != null:
				_carried_bottle.position = Vector3(0.0, -0.18, 0.0)
				anchor.add_child(_carried_bottle)
			else:
				_carried_bottle.position = Vector3(0.0, 0.64, 0.34)
				carrier.add_child(_carried_bottle)
		else:
			_carried_bottle.position = Vector3(0.0, 0.64, 0.34)
			carrier.add_child(_carried_bottle)
		if carrier.has_method("set_carrying"):
			carrier.call("set_carrying", true)


func place_water_for_sinta(carrier: Node3D = null) -> void:
	if carrier != null and carrier.has_method("set_carrying"):
		carrier.call("set_carrying", false)
	if _carried_bottle != null and is_instance_valid(_carried_bottle):
		_carried_bottle.queue_free()
		_carried_bottle = null
	if _sinta_delivered_bottle != null:
		_sinta_delivered_bottle.visible = true
		_sinta_delivered_bottle.scale = Vector3(0.1, 0.1, 0.1)
		var tw := create_tween()
		tw.tween_property(_sinta_delivered_bottle, "scale", Vector3.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func pickup_block_to_hands(idx: int, carrier: Node3D) -> bool:
	if idx < 0 or idx >= _block_collected.size() or _block_collected[idx] or _carrying_block_idx >= 0:
		return false
	_carrying_block_idx = idx
	if idx < _scattered_blocks.size() and is_instance_valid(_scattered_blocks[idx]):
		_scattered_blocks[idx].visible = false
	if carrier != null:
		var cube := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(0.42, 0.42, 0.42)
		cube.mesh = bm
		cube.material_override = ToonMat.make(_block_colors[idx], "", {"emission_color": _block_colors[idx], "emission_energy": 0.22})
		_carried_block_mesh = cube
		if carrier.has_method("get_carry_anchor"):
			var anchor: Node3D = carrier.call("get_carry_anchor") as Node3D
			if anchor != null:
				cube.position = Vector3(0.0, 0.02, 0.05)
				anchor.add_child(cube)
			else:
				cube.position = Vector3(0.0, 0.78, 0.36)
				carrier.add_child(cube)
		else:
			cube.position = Vector3(0.0, 0.78, 0.36)
			carrier.add_child(cube)
		if carrier.has_method("set_carrying"):
			carrier.call("set_carrying", true)
	if _tower_lbl != null:
		_tower_lbl.text = "TARUH BALOK KE MENARA! (%d/3)" % get_collected_block_count()
	_refresh_block_guides()
	return true


func place_carried_block_on_tower(carrier: Node3D) -> int:
	if _carrying_block_idx < 0:
		return get_collected_block_count()
	var idx := _carrying_block_idx
	_carrying_block_idx = -1
	_block_collected[idx] = true
	if carrier != null and carrier.has_method("set_carrying"):
		carrier.call("set_carrying", false)
	if _carried_block_mesh != null and is_instance_valid(_carried_block_mesh):
		_carried_block_mesh.queue_free()
		_carried_block_mesh = null
	var count := get_collected_block_count()
	if count - 1 < _tower_blocks.size():
		var tb := _tower_blocks[count - 1]
		var target_y := 0.38 + float(count - 1) * 0.48
		tb.material_override = ToonMat.make(_block_colors[idx])
		tb.visible = true
		tb.position.y = target_y + 0.75
		tb.scale = Vector3(1.18, 0.82, 1.18)
		var tw := create_tween().set_parallel(true)
		tw.tween_property(tb, "position:y", target_y, 0.32).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
		tw.tween_property(tb, "scale", Vector3.ONE, 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if _tower_lbl != null:
		_tower_lbl.text = "MENARA BALOK BIMA (%d/3)" % count
	_refresh_block_guides()
	return count


func get_collected_block_count() -> int:
	var n := 0
	for b in _block_collected:
		if b:
			n += 1
	return n


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
		_gate_lbl.text = "GERBANG POS 7 TERBUKA!\n(Pos 6 Selesai ★)"
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
	if d.length() < 1.4:
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
	if _bima_danger_ring != null and _bima_danger_ring.visible and _bima_mood == "angry":
		var dp := 1.0 + sin(_time * 5.2) * 0.06
		_bima_danger_ring.scale = Vector3(dp, 1.0, dp)
	if _sinta_danger_ring != null and _sinta_danger_ring.visible and _sinta_mood == "angry":
		var sp := 1.0 + sin(_time * 4.8) * 0.05
		_sinta_danger_ring.scale = Vector3(sp, 1.0, sp)
	for i in range(_scattered_blocks.size()):
		var sb := _scattered_blocks[i]
		if sb != null and sb.visible:
			var cube := sb.get_node_or_null("BlockMesh") as Node3D
			if cube != null:
				cube.rotation.y += delta * (1.8 if _blocks_active else 0.5)
				cube.position.y = (0.48 + sin(_time * 4.0 + float(i) * 1.4) * 0.12) if _blocks_active else 0.26
	if _comic_timer > 0.0:
		_comic_timer -= delta
		if _comic_bubble != null:
			_comic_bubble.position.y += delta * 0.24
			if _comic_timer <= 0.0:
				_comic_bubble.visible = false
	_animate_friend(_bima_root, _bima_head, _bima_left_arm, _bima_right_arm, _bima_hearts, _bima_mood, delta, true)
	_animate_friend(_sinta_root, _sinta_head, _sinta_left_arm, _sinta_right_arm, _sinta_hearts, _sinta_mood, delta, false)


func _animate_friend(root: Node3D, head: Node3D, l_arm: Node3D, r_arm: Node3D, hearts: Array[Label3D], mood: String, delta: float, with_lightning: bool) -> void:
	if root == null:
		return
	if mood == "angry":
		if with_lightning:
			_lightning_cd -= delta
			if _lightning_cd <= 0.0:
				_lightning_cd = randf_range(2.2, 3.4)
				strike_thor_lightning(bima_position)
		root.position.y = absf(sin(_time * 9.5)) * 0.09
		if l_arm != null and r_arm != null:
			l_arm.rotation.x = -0.6 + sin(_time * 13.0) * 0.40
			r_arm.rotation.x = -0.6 - sin(_time * 13.0) * 0.40
		if head != null:
			head.rotation.z = sin(_time * 10.0) * 0.09
	elif mood == "cooling":
		root.position.y = sin(_time * 3.0) * 0.025
		if l_arm != null and r_arm != null:
			l_arm.rotation.x = lerpf(l_arm.rotation.x, -0.15, 5.0 * delta)
			r_arm.rotation.x = lerpf(r_arm.rotation.x, -0.15, 5.0 * delta)
	else:
		root.position.y = absf(sin(_time * 4.6)) * 0.09
		if l_arm != null and r_arm != null:
			l_arm.rotation.z = -1.9 - sin(_time * 6.0) * 0.25
			r_arm.rotation.z = 1.9 + sin(_time * 6.0) * 0.25
			l_arm.rotation.x = -0.2
			r_arm.rotation.x = -0.2
		for i in range(hearts.size()):
			var h := hearts[i]
			if h.visible:
				h.position = Vector3(sin(_time * 2.2 + float(i) * 2.1) * 0.48, 2.05 + fmod(_time * 0.55 + float(i) * 0.35, 0.9), 0.1)


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

	var road_mat := ToonMat.make(Color(0.30, 0.32, 0.38), "res://assets/textures/cobblestone.webp", {"triplanar": true, "triplanar_scale": 0.34, "outline": false, "rim_strength": 0.06})
	var road := MeshInstance3D.new()
	var rb := BoxMesh.new()
	rb.size = Vector3(4.6, 0.06, 37.0)
	road.mesh = rb
	road.material_override = road_mat
	road.position = Vector3(0.0, 0.02, -7.2)
	add_child(road)


func _build_picnic_play_corner() -> void:
	var mat_root := Node3D.new()
	mat_root.position = Vector3(-2.0, 0.06, -8.8)
	add_child(mat_root)

	var cream_mat := ToonMat.make(Color(0.99, 0.96, 0.88), "", {"outline": false})
	var coral_mat := ToonMat.make(Color(0.92, 0.42, 0.36), "", {"outline": false})
	var tile_w := 1.15
	var tile_d := 1.05
	for ix in range(4):
		for iz in range(4):
			var tile := MeshInstance3D.new()
			var tb := BoxMesh.new()
			tb.size = Vector3(tile_w, 0.03, tile_d)
			tile.mesh = tb
			tile.material_override = coral_mat if ((ix + iz) % 2 == 0) else cream_mat
			tile.position = Vector3((float(ix) - 1.5) * tile_w, 0.0, (float(iz) - 1.5) * tile_d)
			mat_root.add_child(tile)


func _build_scattered_blocks_and_tower() -> void:
	var base_root := Node3D.new()
	base_root.position = tower_position
	add_child(base_root)

	var wood_mat := ToonMat.make(Color(0.62, 0.39, 0.22), "res://assets/textures/wood_planks.webp", {"triplanar": true, "triplanar_scale": 0.45})
	var ped := MeshInstance3D.new()
	var pb := BoxMesh.new()
	pb.size = Vector3(1.15, 0.14, 1.15)
	ped.mesh = pb
	ped.material_override = wood_mat
	ped.position = Vector3(0.0, 0.07, 0.0)
	base_root.add_child(ped)

	_tower_ring = _make_ring(Color(0.98, 0.78, 0.18), 1.45)
	_tower_ring.visible = false
	base_root.add_child(_tower_ring)

	var t_area := Area3D.new()
	t_area.collision_layer = 4
	t_area.collision_mask = 2
	var tcol := CollisionShape3D.new()
	var tsh := CylinderShape3D.new()
	tsh.radius = 1.65
	tsh.height = 2.2
	tcol.shape = tsh
	tcol.position = Vector3(0.0, 1.1, 0.0)
	t_area.add_child(tcol)
	base_root.add_child(t_area)
	t_area.body_entered.connect(func(body: Node3D) -> void:
		if body is NaraController and _blocks_active and _carrying_block_idx >= 0:
			tower_zone_touched.emit()
	)

	_tower_lbl = _make_label("MENARA BALOK BIMA (0/3)", Vector3(0.0, 2.35, 0.0))
	_tower_lbl.visible = false
	base_root.add_child(_tower_lbl)

	for i in range(3):
		var tb := MeshInstance3D.new()
		var bm := BoxMesh.new()
		var sz := 0.62 - float(i) * 0.08
		bm.size = Vector3(sz, 0.48, sz)
		tb.mesh = bm
		tb.material_override = ToonMat.make(_block_colors[i])
		tb.position = Vector3(0.0, 0.38 + float(i) * 0.48, 0.0)
		tb.visible = false
		base_root.add_child(tb)
		_tower_blocks.append(tb)

	for i in range(_block_spots.size()):
		var b_root := Node3D.new()
		b_root.position = _block_spots[i]
		add_child(b_root)

		var bmesh := MeshInstance3D.new()
		bmesh.name = "BlockMesh"
		var bm := BoxMesh.new()
		bm.size = Vector3(0.52, 0.52, 0.52)
		bmesh.mesh = bm
		bmesh.material_override = ToonMat.make(_block_colors[i], "", {"emission_color": _block_colors[i], "emission_energy": 0.28})
		bmesh.position = Vector3(0.0, 0.26, 0.0)
		b_root.add_child(bmesh)

		var ring := _make_ring(_block_colors[i], 0.85)
		ring.name = "BlockRing"
		ring.visible = false
		b_root.add_child(ring)

		var blbl := _make_label("%d. %s" % [i + 1, _block_names[i]], Vector3(0.0, 1.15, 0.0))
		blbl.name = "BlockLbl"
		blbl.font_size = 34
		blbl.visible = false
		b_root.add_child(blbl)

		var area := Area3D.new()
		area.collision_layer = 4
		area.collision_mask = 2
		var col := CollisionShape3D.new()
		var sh := CylinderShape3D.new()
		sh.radius = 1.25
		sh.height = 2.0
		col.shape = sh
		col.position = Vector3(0.0, 1.0, 0.0)
		area.add_child(col)
		b_root.add_child(area)
		var b_idx := i
		area.body_entered.connect(func(body: Node3D) -> void:
			if body is NaraController and _blocks_active and not _block_collected[b_idx]:
				block_touched.emit(b_idx)
		)
		_scattered_blocks.append(b_root)


func _build_bima_friend() -> void:
	var built := _create_character(bima_position, "BIMA", Color(0.92, 0.32, 0.28), Color(0.24, 0.36, 0.62), Color(0.16, 0.12, 0.10))
	_bima_root = built["root"]
	_bima_head = built["head"]
	_bima_left_arm = built["l_arm"]
	_bima_right_arm = built["r_arm"]
	_bima_hearts = built["hearts"]

	_thor_light = OmniLight3D.new()
	_thor_light.position = Vector3(0.0, 2.8, 0.6)
	_thor_light.light_color = Color(0.55, 0.86, 1.0)
	_thor_light.light_energy = 0.0
	_thor_light.omni_range = 9.0
	_bima_root.add_child(_thor_light)

	_bima_danger_ring = _make_ring(Color(0.92, 0.22, 0.20), 2.55)
	_bima_danger_ring.position.y = 0.11
	_bima_root.add_child(_bima_danger_ring)


func _build_sinta_friend() -> void:
	var built := _create_character(sinta_position, "SINTA", Color(0.56, 0.36, 0.82), Color(0.96, 0.68, 0.24), Color(0.24, 0.14, 0.08))
	_sinta_root = built["root"]
	_sinta_head = built["head"]
	_sinta_left_arm = built["l_arm"]
	_sinta_right_arm = built["r_arm"]
	_sinta_hearts = built["hearts"]

	_sinta_danger_ring = _make_ring(Color(0.92, 0.26, 0.42), 2.15)
	_sinta_danger_ring.position.y = 0.11
	_sinta_root.add_child(_sinta_danger_ring)


func _create_character(pos: Vector3, label_txt: String, shirt_col: Color, bottom_col: Color, hair_col: Color) -> Dictionary:
	var root := Node3D.new()
	root.position = pos
	add_child(root)

	var skin := ToonMat.make(Color(0.98, 0.82, 0.70))
	var shirt := ToonMat.make(shirt_col)
	var shorts := ToonMat.make(bottom_col)
	var hair := ToonMat.make(hair_col)
	var eye_mat := ToonMat.make(Color(0.10, 0.08, 0.12), "", {"outline": false})

	for sx: float in [-0.14, 0.14]:
		var leg := MeshInstance3D.new()
		var lc := CapsuleMesh.new()
		lc.radius = 0.08
		lc.height = 0.42
		leg.mesh = lc
		leg.material_override = shorts
		leg.position = Vector3(sx, 0.26, 0.0)
		root.add_child(leg)

	var torso := MeshInstance3D.new()
	var tc := CylinderMesh.new()
	tc.top_radius = 0.22
	tc.bottom_radius = 0.25
	tc.height = 0.50
	torso.mesh = tc
	torso.material_override = shirt
	torso.position = Vector3(0.0, 0.78, 0.0)
	root.add_child(torso)

	var l_arm := _make_arm(-0.30, shirt, skin)
	var r_arm := _make_arm(0.30, shirt, skin)
	root.add_child(l_arm)
	root.add_child(r_arm)

	var head_grp := Node3D.new()
	head_grp.position = Vector3(0.0, 1.38, 0.0)
	root.add_child(head_grp)
	var head := MeshInstance3D.new()
	var hsp := SphereMesh.new()
	hsp.radius = 0.35
	hsp.height = 0.68
	head.mesh = hsp
	head.material_override = skin
	head_grp.add_child(head)
	var hcap := MeshInstance3D.new()
	var hcsp := SphereMesh.new()
	hcsp.radius = 0.37
	hcsp.height = 0.70
	hcap.mesh = hcsp
	hcap.material_override = hair
	hcap.position = Vector3(0.0, 0.06, -0.05)
	head_grp.add_child(hcap)
	for side: float in [-1.0, 1.0]:
		var eye := MeshInstance3D.new()
		var esp := SphereMesh.new()
		esp.radius = 0.045
		esp.height = 0.09
		eye.mesh = esp
		eye.material_override = eye_mat
		eye.position = Vector3(side * 0.13, -0.01, 0.32)
		head_grp.add_child(eye)

	var tag := _make_label(label_txt, Vector3(0.0, 2.45, 0.0))
	root.add_child(tag)

	var hearts: Array[Label3D] = []
	for _i in range(3):
		var h := Label3D.new()
		h.text = "♥"
		h.font_size = 46
		h.outline_size = 6
		h.modulate = Color(1.0, 0.40, 0.60)
		h.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		h.visible = false
		root.add_child(h)
		hearts.append(h)

	_add_box_collider(root, Vector3(0.9, 1.8, 0.9), Vector3(0.0, 0.9, 0.0))
	return {"root": root, "head": head_grp, "l_arm": l_arm, "r_arm": r_arm, "hearts": hearts}


func _make_arm(x_off: float, shirt: Material, skin: Material) -> Node3D:
	var g := Node3D.new()
	g.position = Vector3(x_off, 0.96, 0.0)
	var hand := MeshInstance3D.new()
	var hc := CapsuleMesh.new()
	hc.radius = 0.07
	hc.height = 0.36
	hand.mesh = hc
	hand.material_override = skin
	hand.position = Vector3(0.0, -0.18, 0.0)
	g.add_child(hand)
	var sl := MeshInstance3D.new()
	var sp := SphereMesh.new()
	sp.radius = 0.10
	sp.height = 0.20
	sl.mesh = sp
	sl.material_override = shirt
	g.add_child(sl)
	return g


func _build_zone1_bima_safe_space() -> void:
	var root := Node3D.new()
	root.position = step_positions[1]
	add_child(root)
	_ring1 = _make_ring(Color(0.98, 0.78, 0.18), 1.65)
	root.add_child(_ring1)
	_lbl1 = _make_label("1. TEMAN PERTAMA: BIMA\nBerdiri di sini lalu tekan [E / Aksi] untuk menawari Bima!", Vector3(0.0, 2.15, 0.0))
	root.add_child(_lbl1)
	_add_zone_area(root, "step1", 1.95)


func _build_zone2_sinta_safe_space() -> void:
	var root := Node3D.new()
	root.position = step_positions[2]
	add_child(root)
	_ring2 = _make_ring(Color(0.96, 0.56, 0.72), 1.65)
	root.add_child(_ring2)
	_lbl2 = _make_label("2. TEMAN KEDUA: SINTA\nTekan [E / Aksi] untuk menanyakan kebutuhan Sinta!", Vector3(0.0, 2.15, 0.0))
	root.add_child(_lbl2)
	_add_zone_area(root, "step2", 2.05)


func _make_water_bottle_mesh() -> Node3D:
	var bot := Node3D.new()
	var bbody := MeshInstance3D.new()
	var bc := CylinderMesh.new()
	bc.top_radius = 0.13
	bc.bottom_radius = 0.15
	bc.height = 0.42
	bbody.mesh = bc
	bbody.material_override = ToonMat.make(Color(0.28, 0.78, 0.98), "", {"emission_color": Color(0.22, 0.68, 0.96), "emission_energy": 0.38})
	bbody.position = Vector3(0.0, 0.21, 0.0)
	bot.add_child(bbody)
	var bcap := MeshInstance3D.new()
	var bcc := CylinderMesh.new()
	bcc.top_radius = 0.07
	bcc.bottom_radius = 0.07
	bcc.height = 0.10
	bcap.mesh = bcc
	bcap.material_override = ToonMat.make(Color(0.98, 0.98, 0.96))
	bcap.position = Vector3(0.0, 0.46, 0.0)
	bot.add_child(bcap)
	return bot


func _build_zone3_water_stand() -> void:
	var root := Node3D.new()
	root.position = step_positions[3]
	add_child(root)
	var wood_mat := ToonMat.make(Color(0.56, 0.34, 0.18), "res://assets/textures/wood_planks.webp", {"triplanar": true, "triplanar_scale": 0.45})

	var seat := MeshInstance3D.new()
	var sb := BoxMesh.new()
	sb.size = Vector3(2.0, 0.14, 0.85)
	seat.mesh = sb
	seat.material_override = wood_mat
	seat.position = Vector3(0.0, 0.62, 0.0)
	root.add_child(seat)
	for lx: float in [-0.75, 0.75]:
		var leg := MeshInstance3D.new()
		var lb := BoxMesh.new()
		lb.size = Vector3(0.14, 0.62, 0.68)
		leg.mesh = lb
		leg.material_override = wood_mat
		leg.position = Vector3(lx, 0.31, 0.0)
		root.add_child(leg)

	var pole := MeshInstance3D.new()
	var pc := CylinderMesh.new()
	pc.top_radius = 0.06
	pc.bottom_radius = 0.07
	pc.height = 2.65
	pole.mesh = pc
	pole.material_override = ToonMat.make(Color(0.92, 0.88, 0.78))
	pole.position = Vector3(0.55, 1.32, -0.25)
	root.add_child(pole)

	var canopy := MeshInstance3D.new()
	var cc := CylinderMesh.new()
	cc.top_radius = 0.08
	cc.bottom_radius = 1.65
	cc.height = 0.58
	cc.radial_segments = 10
	canopy.mesh = cc
	canopy.material_override = ToonMat.make(Color(0.16, 0.66, 0.68))
	canopy.position = Vector3(0.55, 2.58, -0.25)
	root.add_child(canopy)

	_add_box_collider(root, Vector3(2.1, 1.2, 0.95), Vector3(0.0, 0.6, 0.0))

	_water_bottle = _make_water_bottle_mesh()
	_water_bottle.position = Vector3(-0.25, 0.69, 0.05)
	root.add_child(_water_bottle)

	_ring3 = _make_ring(Color(0.28, 0.78, 0.98), 1.85)
	root.add_child(_ring3)
	_lbl3 = _make_label("3. AMBIL AIR MINUM SEJUK\nTekan [E / Aksi] untuk membawa air bagi Sinta!", Vector3(0.0, 2.25, 0.0))
	root.add_child(_lbl3)
	_add_zone_area(root, "step3", 2.35)


func _build_zone4_sinta_care_table() -> void:
	# Small quiet wooden stool near Sinta so Nara can leave cool water respectfully!
	var root := Node3D.new()
	root.position = sinta_table_pos
	add_child(root)
	var wood_mat := ToonMat.make(Color(0.62, 0.39, 0.22), "res://assets/textures/wood_planks.webp", {"triplanar": true, "triplanar_scale": 0.45})
	var top := MeshInstance3D.new()
	var tb := BoxMesh.new()
	tb.size = Vector3(0.95, 0.12, 0.95)
	top.mesh = tb
	top.material_override = wood_mat
	top.position = Vector3(0.0, 0.55, 0.0)
	root.add_child(top)
	var leg := MeshInstance3D.new()
	var lc := CylinderMesh.new()
	lc.top_radius = 0.14
	lc.bottom_radius = 0.18
	lc.height = 0.55
	leg.mesh = lc
	leg.material_override = wood_mat
	leg.position = Vector3(0.0, 0.27, 0.0)
	root.add_child(leg)
	_add_box_collider(root, Vector3(1.0, 0.7, 1.0), Vector3(0.0, 0.35, 0.0))

	_sinta_delivered_bottle = _make_water_bottle_mesh()
	_sinta_delivered_bottle.position = Vector3(0.0, 0.62, 0.0)
	_sinta_delivered_bottle.visible = false
	root.add_child(_sinta_delivered_bottle)

	_ring4 = _make_ring(Color(0.24, 0.84, 0.56), 1.65)
	root.add_child(_ring4)
	_lbl4 = _make_label("4. TARUH AIR DI MEJA SINTA\nTekan [E / Aksi] tanpa mengganggu ruang tenangnya!", Vector3(0.0, 2.25, 0.0))
	root.add_child(_lbl4)
	_add_zone_area(root, "step4", 2.15)


func _build_star_and_exit_gate() -> void:
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
	badge.text = "POS 6"
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
	sign_bg.material_override = ToonMat.make(Color(0.14, 0.50, 0.46), "", {"outline_width": 1.4})
	sign_bg.position = Vector3(0.0, 4.48, 0.05)
	gate_root.add_child(sign_bg)

	_gate_lbl = Label3D.new()
	_gate_lbl.text = "NEXT RUTE -> POS 7\n(Bantu Bima & Sinta dulu)"
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
		Vector3(-5.6, 0.0, 5.2), Vector3(5.8, 0.0, 4.0), Vector3(-6.0, 0.0, -1.5),
		Vector3(6.6, 0.0, -8.5), Vector3(-5.8, 0.0, -15.5), Vector3(5.6, 0.0, -18.0),
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
		wb.size = Vector3(0.55, 1.05, 34.5)
		wall.mesh = wb
		wall.material_override = brick_mat
		wall.position = Vector3(x, 0.52, -6.5)
		add_child(wall)
		var cap := MeshInstance3D.new()
		var cb := BoxMesh.new()
		cb.size = Vector3(0.68, 0.14, 34.7)
		cap.mesh = cb
		cap.material_override = cap_mat
		cap.position = Vector3(x, 1.1, -6.5)
		add_child(cap)
		_add_box_collider(self, Vector3(0.7, 6.0, 34.8), Vector3(x, 3.0, -6.5))

	# Visual brick flanking walls sealing both gates + 360-deg horizon backdrop
	StorybookProps.build_flanking_brick_walls(self, 10.2, 2.8, 8.6, 1.05)
	StorybookProps.build_flanking_brick_walls(self, -23.0, 2.8, 8.6, 1.05)
	StorybookProps.spawn_horizon_backdrop_360(self, -25.0, 11.0, 9.0)

	_add_box_collider(self, Vector3(18.0, 6.0, 0.6), Vector3(0.0, 3.0, 10.2))
	_add_box_collider(self, Vector3(6.2, 6.0, 0.6), Vector3(-5.8, 3.0, -23.0))
	_add_box_collider(self, Vector3(6.2, 6.0, 0.6), Vector3(5.8, 3.0, -23.0))
	_add_box_collider(self, Vector3(6.5, 6.0, 0.6), Vector3(0.0, 3.0, -25.8))


func _build_trees() -> void:
	var trunk_mat := ToonMat.make(Color(0.55, 0.36, 0.22), "res://assets/textures/bark.webp", {"triplanar": true})
	var leaf_mat := ToonMat.make(Color(0.28, 0.68, 0.30), "res://assets/textures/leaf_canopy.webp", {"triplanar": true, "triplanar_scale": 0.45})
	for t in [
		[Vector3(-6.4, 0.0, 6.2), 1.1],
		[Vector3(6.4, 0.0, 5.8), 1.05],
		[Vector3(-6.8, 0.0, -1.2), 1.15],
		[Vector3(6.8, 0.0, -15.5), 1.15],
		[Vector3(-6.2, 0.0, -19.0), 1.15],
		[Vector3(6.2, 0.0, -19.0), 1.15],
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


func _build_waypoint_beacon() -> void:
	_beacon_pillar = MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.72
	cyl.bottom_radius = 0.90
	cyl.height = 7.2
	cyl.radial_segments = 12
	_beacon_pillar.mesh = cyl
	var bmat := StandardMaterial3D.new()
	bmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	bmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	bmat.albedo_color = Color(1.0, 0.88, 0.28, 0.22)
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
	lbl.font_size = 36
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
