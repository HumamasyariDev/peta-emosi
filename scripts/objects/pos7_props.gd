class_name Pos7Props
extends Node3D

## Pos 7 (Opsi 3 Upgraded):
## - Distinct themed islands (Sakura Calm Garden -> Playground Courtyard -> Toy Veranda -> Star Plaza)
## - Expressive 3D rescue animations:
##   1) Doni genuinely bonking his own head with both fists + angry eyebrows + comic stress mark!
##   2) Raka & Dodi lunging & pushing face-to-face with angry eyebrows + clash spark!
##   3) Wobbling sunflower vase & toy box teetering on a striped-awning veranda craft table!
## - Generous 2.8m clear landing porch between every choice door and bridge (doors NEVER touch bridges!)
## - Long 8.2m seamless wooden bridges over a lush lotus pond + middle-patrolling jumpable Anger Waves!

signal action_zone_changed(stage_idx: int, entered: bool)
signal gate_entered(stage_idx: int, is_correct: bool, gate_pos: Vector3)
signal jump_wave_hit(bridge_idx: int, wave_z: float)
signal next_route_entered

# Exact architectural layout with SPACIOUS 4.0m open porches beyond every sliding door + 8.4m bridges!
const STAGE_Z: Array[float] = [1.4, -16.4, -34.2]
const ACTION_POS: Array[Vector3] = [
	Vector3(0.0, 0.0, 4.8),
	Vector3(0.0, 0.0, -13.0),
	Vector3(0.0, 0.0, -30.8),
]
const BRIDGE_SPECS: Array[Dictionary] = [
	{"z": -6.4, "len": 8.4},
	{"z": -24.2, "len": 8.4},
	{"z": -42.0, "len": 8.4},
]

var star_position: Vector3 = Vector3(0.0, 0.0, -49.4)
var exit_gate_position: Vector3 = Vector3(0.0, 0.0, -53.6)

var _time: float = 0.0
var _clouds: Array[Node3D] = []
var _butterflies: Array[Dictionary] = []
var _balloons: Array[Node3D] = []
var _guide_arrow: Node3D
var _comic_bubble: Label3D
var _comic_timer: float = 0.0

var _stage_data: Array[Dictionary] = [
	{
		"badge": "PRINSIP 1: JAGA DIRI SENDIRI",
		"right": "Tarik napas & jaga\ntubuh tetap aman",
		"wrong": "Pukul kepala atau\ncakar diri sendiri",
		"wrong_hint": "Jangan menyakiti diri sendiri ya! Tubuhmu berharga!"
	},
	{
		"badge": "PRINSIP 2: JAGA ORANG LAIN",
		"right": "Bicara baik & tidak\nmenyakiti teman",
		"wrong": "Mendorong atau\nmengejek teman",
		"wrong_hint": "Jangan menyakiti orang lain ya! Teman bisa terluka!"
	},
	{
		"badge": "PRINSIP 3: JAGA BARANG",
		"right": "Jaga mainan & salurkan\nmarah dengan aman",
		"wrong": "Banting mainan atau\ntendang pintu",
		"wrong_hint": "Jangan merusak barang ya! Barang rusak tidak menyelesaikan masalah!"
	},
]

# Island 3D rescue props
var _action_done: Array[bool] = [false, false, false]
var _action_lbls: Array[Label3D] = []
var _doni: Dictionary = {}
var _doni_stress: Label3D
var _raka: Dictionary = {}
var _dodi: Dictionary = {}
var _clash_spark: Label3D
var _vase_group: Node3D
var _vase_warn: Label3D
var _toy_table_heart: Label3D

# Choice doors & seamless bridges & jumpable red anger waves
var _bridges: Array[Node3D] = []
var _bridge_floor_cols: Array[StaticBody3D] = []
var _gap_blockers: Array[StaticBody3D] = []
var _jump_waves: Array[Node3D] = []
var _wave_logs: Array[Node3D] = []
var _wave_prev_z: Array[float] = []
var _hit_burst: GPUParticles3D
var _right_door_pivots: Array[Array] = []
var _right_door_blockers: Array[StaticBody3D] = []
var _wrong_door_roots: Array[Node3D] = []
var _stage_solved: Array[bool] = [false, false, false]
var _pillar_stars: Array[MeshInstance3D] = []
var _pillar_mats: Array[ShaderMaterial] = []

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
	_build_lush_pond_and_themed_islands()
	_build_horizon_hills_and_trees()
	_build_closed_back_gate()
	_build_island_rescue_scenes()
	_build_three_choice_stages()
	_build_star_and_exit_gate()
	_guide_arrow = StorybookProps.make_guide_arrow()
	add_child(_guide_arrow)
	_clouds = StorybookProps.spawn_clouds(self)
	_butterflies = StorybookProps.spawn_butterflies(self, [
		Vector3(-4.2, 1.7, 5.2), Vector3(4.2, 1.8, -6.4), Vector3(-4.0, 1.8, -13.0),
		Vector3(4.2, 1.8, -24.2), Vector3(-4.0, 1.8, -30.8), Vector3(4.0, 1.9, -42.0),
	])
	_build_hit_impact_burst()
	ToonMat.optimize_tree(self)


func _build_hit_impact_burst() -> void:
	_hit_burst = GPUParticles3D.new()
	_hit_burst.amount = 28
	_hit_burst.lifetime = 0.72
	_hit_burst.one_shot = true
	_hit_burst.explosiveness = 0.95
	_hit_burst.emitting = false
	var pm := ParticleProcessMaterial.new()
	pm.direction = Vector3(0.0, 1.0, 0.0)
	pm.spread = 135.0
	pm.initial_velocity_min = 2.6
	pm.initial_velocity_max = 5.4
	pm.gravity = Vector3(0.0, -6.5, 0.0)
	pm.scale_min = 0.09; pm.scale_max = 0.19
	pm.color = Color(1.0, 0.84, 0.22)
	_hit_burst.process_material = pm
	var star_m := BoxMesh.new()
	star_m.size = Vector3(0.45, 0.45, 0.14)
	var sm := StandardMaterial3D.new()
	sm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	sm.albedo_color = Color(1.0, 0.88, 0.24)
	star_m.material = sm
	_hit_burst.draw_pass_1 = star_m
	add_child(_hit_burst)


func spawn_hit_impact(world_pos: Vector3) -> void:
	if _hit_burst != null:
		_hit_burst.global_position = world_pos + Vector3(0.0, 0.85, 0.0)
		_hit_burst.restart()
		_hit_burst.emitting = true


func is_action_done(stage_idx: int) -> bool:
	if stage_idx >= 0 and stage_idx < _action_done.size():
		return _action_done[stage_idx]
	return true


func complete_island_action(stage_idx: int) -> void:
	if stage_idx < 0 or stage_idx >= 3 or _action_done[stage_idx]:
		return
	_action_done[stage_idx] = true
	if stage_idx < _action_lbls.size() and _action_lbls[stage_idx] != null:
		_action_lbls[stage_idx].visible = false
	if stage_idx == 0:
		if _doni.has("heart"):
			(_doni["heart"] as Label3D).visible = true
		if _doni.has("brows"):
			(_doni["brows"] as Node3D).visible = false
		if _doni_stress != null:
			_doni_stress.visible = false
	elif stage_idx == 1:
		for npc: Dictionary in [_raka, _dodi]:
			if npc.has("heart"):
				(npc["heart"] as Label3D).visible = true
			if npc.has("brows"):
				(npc["brows"] as Node3D).visible = false
		if _clash_spark != null:
			_clash_spark.visible = false
	elif stage_idx == 2:
		if _vase_group != null:
			var tw := create_tween()
			tw.tween_property(_vase_group, "rotation_degrees:z", 0.0, 0.25)
		if _vase_warn != null:
			_vase_warn.visible = false
		if _toy_table_heart != null:
			_toy_table_heart.visible = true


func get_wrong_hint(stage_idx: int) -> String:
	if stage_idx >= 0 and stage_idx < _stage_data.size():
		return str(_stage_data[stage_idx]["wrong_hint"])
	return "Pilih pintu prinsip yang aman ya!"


func get_principle_title(stage_idx: int) -> String:
	if stage_idx >= 0 and stage_idx < _stage_data.size():
		return str(_stage_data[stage_idx]["badge"])
	return ""


func get_stage_target(stage_idx: int) -> Vector3:
	if stage_idx >= 0 and stage_idx < 3:
		if not _action_done[stage_idx]:
			return ACTION_POS[stage_idx] + Vector3(0.0, 0.0, 1.45)
		return Vector3(0.0, 0.0, STAGE_Z[stage_idx] + 1.4)
	return exit_gate_position + Vector3(0.0, 0.0, -1.0)


func show_bubble(world_pos: Vector3, text: String, duration: float = 2.1) -> void:
	if _comic_bubble == null:
		_comic_bubble = Label3D.new()
		_comic_bubble.font_size = 34
		_comic_bubble.outline_size = 8
		_comic_bubble.modulate = Color(1.0, 0.98, 0.84)
		_comic_bubble.outline_modulate = Color(0.24, 0.12, 0.06)
		_comic_bubble.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		add_child(_comic_bubble)
	_comic_bubble.text = text
	_comic_bubble.position = world_pos + Vector3(0.0, 2.35, 0.0)
	_comic_bubble.visible = true
	_comic_timer = duration


func solve_stage(stage_idx: int) -> void:
	if stage_idx < 0 or stage_idx >= 3 or _stage_solved[stage_idx]:
		return
	_stage_solved[stage_idx] = true

	# Smooth SLIDING wooden garden double-doors that retract cleanly sideways into the arch pillars
	# (zero protruding door leaves blocking the porch or touching the bridge!)
	var leaves: Array = _right_door_pivots[stage_idx]
	if leaves.size() == 2:
		var l_node := leaves[0] as Node3D
		var r_node := leaves[1] as Node3D
		var dtw := create_tween().set_parallel(true)
		dtw.tween_property(l_node, "scale:x", 0.08, 0.42).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN_OUT)
		dtw.tween_property(r_node, "scale:x", 0.08, 0.42).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN_OUT)
		dtw.tween_callback(func() -> void:
			if stage_idx < _right_door_blockers.size() and _right_door_blockers[stage_idx] != null:
				_right_door_blockers[stage_idx].collision_layer = 0
		).set_delay(0.22)
		dtw.tween_callback(func() -> void:
			l_node.visible = false
			r_node.visible = false
		).set_delay(0.40)

	if _bridge_floor_cols[stage_idx] != null:
		_bridge_floor_cols[stage_idx].collision_layer = 1
	if _gap_blockers[stage_idx] != null:
		_gap_blockers[stage_idx].collision_layer = 0

	var br := _bridges[stage_idx]
	if br != null:
		br.visible = true
		br.position.y = -0.95
		var btw := create_tween()
		btw.tween_property(br, "position:y", 0.0, 0.52).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	if _jump_waves[stage_idx] != null:
		_jump_waves[stage_idx].visible = true

	if _pillar_mats[stage_idx] != null:
		_pillar_mats[stage_idx].set_shader_parameter("albedo", Color(1.0, 0.88, 0.18))
		_pillar_mats[stage_idx].set_shader_parameter("emission_energy", 1.05)
	if _pillar_stars[stage_idx] != null:
		var stw := create_tween()
		stw.tween_property(_pillar_stars[stage_idx], "scale", Vector3(1.35, 1.35, 1.35), 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		stw.tween_property(_pillar_stars[stage_idx], "scale", Vector3.ONE, 0.18)


func solve_all_instant() -> void:
	for i in range(3):
		complete_island_action(i)
		_stage_solved[i] = true
		var leaves: Array = _right_door_pivots[i]
		if leaves.size() == 2:
			(leaves[0] as Node3D).visible = false
			(leaves[1] as Node3D).visible = false
		if i < _right_door_blockers.size() and _right_door_blockers[i] != null:
			_right_door_blockers[i].collision_layer = 0
		if _bridges[i] != null:
			_bridges[i].visible = true
			_bridges[i].position.y = 0.0
		if _bridge_floor_cols[i] != null:
			_bridge_floor_cols[i].collision_layer = 1
		if _gap_blockers[i] != null:
			_gap_blockers[i].collision_layer = 0
		if _jump_waves[i] != null:
			_jump_waves[i].visible = false
		if _pillar_mats[i] != null:
			_pillar_mats[i].set_shader_parameter("albedo", Color(1.0, 0.88, 0.18))
			_pillar_mats[i].set_shader_parameter("emission_energy", 1.05)


func trigger_wrong_gate_fx(gate_pos: Vector3) -> void:
	for i in range(3):
		if absf(STAGE_Z[i] - gate_pos.z) < 1.0:
			var wd := _wrong_door_roots[i]
			if wd != null:
				var ox := wd.position.x
				var tw := create_tween()
				tw.tween_property(wd, "position:x", ox + 0.12, 0.05)
				tw.tween_property(wd, "position:x", ox - 0.12, 0.05)
				tw.tween_property(wd, "position:x", ox + 0.08, 0.05)
				tw.tween_property(wd, "position:x", ox, 0.05)
			break


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
		_gate_lbl.text = "GERBANG POS 8 (FINISH) TERBUKA!\n(Pos 7 Selesai ★)"
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
	for i in range(_pillar_stars.size()):
		var ps := _pillar_stars[i]
		if ps != null:
			ps.rotation.y += delta * (2.0 if _stage_solved[i] else 0.6)
			ps.position.y = 3.72 + sin(_time * 2.8 + float(i)) * 0.09
	for i in range(_balloons.size()):
		var b := _balloons[i]
		if b != null:
			b.rotation.z = sin(_time * 1.9 + float(i) * 1.2) * 0.08

	# === ISLAND 1 ANIMATION: Doni ACTUALLY hitting both sides of his own head (NOT T-pose!) ===
	# Arm hangs down (-Y): rotation.z = -3.35 bends LEFT arm UP and INWARD straight onto left temple!
	# Oscillating between -2.35 (pulled out) and -3.40 (BONK on head!) + head recoil & stress mark!
	if _doni.has("root"):
		var la := _doni["l_arm"] as Node3D
		var ra := _doni["r_arm"] as Node3D
		var head := _doni["head"] as Node3D
		var rt := _doni["root"] as Node3D
		if not _action_done[0]:
			var bonk_l := maxf(0.0, sin(_time * 13.5))
			var bonk_r := maxf(0.0, -sin(_time * 13.5))
			la.rotation.z = lerpf(-2.25, -3.45, bonk_l)
			la.rotation.x = -0.35 - bonk_l * 0.25
			ra.rotation.z = lerpf(2.25, 3.45, bonk_r)
			ra.rotation.x = -0.35 - bonk_r * 0.25
			# Head visibly flinches left/right & nods on every bonk!
			head.rotation.z = (bonk_r - bonk_l) * 0.22
			head.rotation.x = 0.14 + maxf(bonk_l, bonk_r) * 0.10
			rt.position.y = absf(sin(_time * 13.5)) * 0.06
			if _doni_stress != null:
				var sc := 0.90 + maxf(bonk_l, bonk_r) * 0.35
				_doni_stress.scale = Vector3(sc, sc, sc)
				_doni_stress.position.y = 1.92 + maxf(bonk_l, bonk_r) * 0.08
		else:
			la.rotation.z = lerpf(la.rotation.z, -0.14, 7.0 * delta)
			la.rotation.x = lerpf(la.rotation.x, 0.0, 7.0 * delta)
			ra.rotation.z = lerpf(ra.rotation.z, 0.14, 7.0 * delta)
			ra.rotation.x = lerpf(ra.rotation.x, 0.0, 7.0 * delta)
			head.rotation.z = lerpf(head.rotation.z, sin(_time * 2.5) * 0.05, 6.0 * delta)
			head.rotation.x = lerpf(head.rotation.x, 0.0, 6.0 * delta)
			rt.position.y = sin(_time * 2.8) * 0.03

	# === ISLAND 2 ANIMATION: Raka & Dodi lunging & pushing each other face-to-face! ===
	if _raka.has("root") and _dodi.has("root"):
		var r_rt := _raka["root"] as Node3D
		var d_rt := _dodi["root"] as Node3D
		var r_la := _raka["l_arm"] as Node3D
		var r_ra := _raka["r_arm"] as Node3D
		var d_la := _dodi["l_arm"] as Node3D
		var d_ra := _dodi["r_arm"] as Node3D
		if not _action_done[1]:
			var shove := sin(_time * 11.0)
			r_la.rotation.x = -1.45 - maxf(0.0, shove) * 0.42
			r_ra.rotation.x = -1.45 - maxf(0.0, shove) * 0.42
			r_la.rotation.z = 0.18; r_ra.rotation.z = -0.18
			d_la.rotation.x = -1.45 - maxf(0.0, -shove) * 0.42
			d_ra.rotation.x = -1.45 - maxf(0.0, -shove) * 0.42
			d_la.rotation.z = 0.18; d_ra.rotation.z = -0.18
			r_rt.position.x = ACTION_POS[1].x - 0.82 + shove * 0.14
			d_rt.position.x = ACTION_POS[1].x + 0.82 + shove * 0.14
			if _clash_spark != null:
				var cs := 0.85 + absf(shove) * 0.45
				_clash_spark.scale = Vector3(cs, cs, cs)
		else:
			r_la.rotation.x = lerpf(r_la.rotation.x, 0.0, 6.0 * delta)
			r_ra.rotation.x = lerpf(r_ra.rotation.x, 0.0, 6.0 * delta)
			r_la.rotation.z = lerpf(r_la.rotation.z, -0.12, 6.0 * delta)
			r_ra.rotation.z = lerpf(r_ra.rotation.z, 0.12, 6.0 * delta)
			d_la.rotation.x = lerpf(d_la.rotation.x, 0.0, 6.0 * delta)
			d_ra.rotation.x = lerpf(d_ra.rotation.x, 0.0, 6.0 * delta)
			d_la.rotation.z = lerpf(d_la.rotation.z, -0.12, 6.0 * delta)
			d_ra.rotation.z = lerpf(d_ra.rotation.z, 0.12, 6.0 * delta)
			r_rt.position.x = lerpf(r_rt.position.x, ACTION_POS[1].x - 0.90, 5.0 * delta)
			d_rt.position.x = lerpf(d_rt.position.x, ACTION_POS[1].x + 0.90, 5.0 * delta)

	# === ISLAND 3 ANIMATION: Wobbling sunflower vase & toy box teetering dangerously! ===
	if _vase_group != null and not _action_done[2]:
		_vase_group.rotation_degrees.z = sin(_time * 11.5) * 20.0
		if _vase_warn != null:
			_vase_warn.position.y = 1.92 + absf(sin(_time * 11.5)) * 0.10

	# === ROLLING ANGER LOGS: Actually spin/roll physically as they patrol the middle of each 8.4m bridge! ===
	# Leaves 2.0m safe buffer at BOTH bridge ends (far from the 4.0m open porch!)
	for i in range(_jump_waves.size()):
		var w := _jump_waves[i]
		if w != null and w.visible:
			var base_z: float = float(BRIDGE_SPECS[i]["z"])
			var speed := 1.45 + float(i) * 0.22
			var new_z := base_z + sin(_time * speed + float(i) * 1.3) * 2.2
			var dz := new_z - _wave_prev_z[i]
			_wave_prev_z[i] = new_z
			w.position.z = new_z
			if i < _wave_logs.size() and _wave_logs[i] != null:
				# Physical rolling angle: delta_angle = dz / radius (radius = 0.22)
				_wave_logs[i].rotation.x += dz / 0.22

	if _comic_timer > 0.0:
		_comic_timer -= delta
		if _comic_bubble != null:
			_comic_bubble.position.y += delta * 0.22
			if _comic_timer <= 0.0:
				_comic_bubble.visible = false


func _build_island_rescue_scenes() -> void:
	# === ISLAND 1: Doni bonking his head beside a cozy Sakura park bench ===
	_doni = _make_npc(ACTION_POS[0], "DONI", Color(0.24, 0.56, 0.88), Color(0.28, 0.30, 0.38), Color(0.18, 0.12, 0.08), true)
	_doni_stress = Label3D.new()
	_doni_stress.text = "DUK! DUK!"
	_doni_stress.font_size = 28; _doni_stress.outline_size = 7; _doni_stress.modulate = Color(1.0, 0.36, 0.32)
	_doni_stress.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_doni_stress.position = Vector3(0.55, 1.92, 0.15)
	(_doni["root"] as Node3D).add_child(_doni_stress)

	var lbl0 := _make_label("TENANGKAN DONI\nTekan [E / Aksi]", ACTION_POS[0] + Vector3(0.0, 2.38, 0.0))
	lbl0.font_size = 24; lbl0.modulate = Color(1.0, 0.94, 0.48)
	add_child(lbl0)
	_action_lbls.append(lbl0)
	_add_action_zone(ACTION_POS[0], 0, 2.3)

	# === ISLAND 2: Raka & Dodi shoving each other in the Playground Courtyard ===
	_raka = _make_npc(ACTION_POS[1] + Vector3(-0.82, 0.0, 0.0), "RAKA", Color(0.92, 0.36, 0.28), Color(0.24, 0.40, 0.62), Color(0.16, 0.12, 0.10), true)
	(_raka["root"] as Node3D).rotation_degrees.y = 90.0
	_dodi = _make_npc(ACTION_POS[1] + Vector3(0.82, 0.0, 0.0), "DODI", Color(0.22, 0.68, 0.44), Color(0.46, 0.32, 0.22), Color(0.22, 0.14, 0.08), true)
	(_dodi["root"] as Node3D).rotation_degrees.y = -90.0

	_clash_spark = Label3D.new()
	_clash_spark.text = "DORONG!"
	_clash_spark.font_size = 26; _clash_spark.outline_size = 7; _clash_spark.modulate = Color(1.0, 0.42, 0.24)
	_clash_spark.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_clash_spark.position = ACTION_POS[1] + Vector3(0.0, 1.55, 0.25)
	add_child(_clash_spark)

	var lbl1 := _make_label("LERAI RAKA & DODI\nTekan [E / Aksi]", ACTION_POS[1] + Vector3(0.0, 2.38, 0.0))
	lbl1.font_size = 24; lbl1.modulate = Color(1.0, 0.94, 0.48)
	add_child(lbl1)
	_action_lbls.append(lbl1)
	_add_action_zone(ACTION_POS[1], 1, 2.55)

	# === ISLAND 3: Wobbling Toy Box & Sunflower Vase on Veranda Craft Table ===
	var tbl_root := Node3D.new()
	tbl_root.position = ACTION_POS[2]
	add_child(tbl_root)
	var wood_mat := ToonMat.make(Color(0.58, 0.36, 0.20), "res://assets/textures/wood_planks.webp", {"triplanar": true, "triplanar_scale": 0.44})
	var top := MeshInstance3D.new()
	var tb := BoxMesh.new()
	tb.size = Vector3(1.9, 0.14, 0.95)
	top.mesh = tb; top.material_override = wood_mat; top.position = Vector3(0.0, 0.68, 0.0)
	tbl_root.add_child(top)
	for lx: float in [-0.74, 0.74]:
		var leg := MeshInstance3D.new()
		var lb := BoxMesh.new()
		lb.size = Vector3(0.14, 0.68, 0.72)
		leg.mesh = lb; leg.material_override = wood_mat; leg.position = Vector3(lx, 0.34, 0.0)
		tbl_root.add_child(leg)
	_add_box_collider(tbl_root, Vector3(1.95, 1.1, 1.0), Vector3(0.0, 0.55, 0.0))

	_vase_group = Node3D.new()
	_vase_group.position = Vector3(0.0, 0.75, 0.0)
	tbl_root.add_child(_vase_group)
	var vase := MeshInstance3D.new()
	var vc := CylinderMesh.new()
	vc.top_radius = 0.15; vc.bottom_radius = 0.23; vc.height = 0.48
	vase.mesh = vc; vase.material_override = ToonMat.make(Color(0.24, 0.68, 0.90)); vase.position = Vector3(-0.36, 0.24, 0.0)
	_vase_group.add_child(vase)
	var bloom := MeshInstance3D.new()
	var bsp := SphereMesh.new()
	bsp.radius = 0.22; bsp.height = 0.34
	bloom.mesh = bsp; bloom.material_override = ToonMat.make(Color(1.0, 0.78, 0.16)); bloom.position = Vector3(-0.36, 0.56, 0.0)
	_vase_group.add_child(bloom)
	var toy_box := MeshInstance3D.new()
	var tbm := BoxMesh.new()
	tbm.size = Vector3(0.48, 0.38, 0.44)
	toy_box.mesh = tbm; toy_box.material_override = ToonMat.make(Color(0.96, 0.44, 0.34)); toy_box.position = Vector3(0.38, 0.19, 0.0)
	_vase_group.add_child(toy_box)

	_vase_warn = Label3D.new()
	_vase_warn.text = "AWAS JATUH!"
	_vase_warn.font_size = 24; _vase_warn.outline_size = 6; _vase_warn.modulate = Color(1.0, 0.44, 0.28)
	_vase_warn.billboard = BaseMaterial3D.BILLBOARD_ENABLED; _vase_warn.position = Vector3(0.0, 1.92, 0.0)
	tbl_root.add_child(_vase_warn)

	_toy_table_heart = Label3D.new()
	_toy_table_heart.text = "♥ AMAN!"
	_toy_table_heart.font_size = 34; _toy_table_heart.outline_size = 7; _toy_table_heart.modulate = Color(0.34, 0.96, 0.52)
	_toy_table_heart.billboard = BaseMaterial3D.BILLBOARD_ENABLED; _toy_table_heart.position = Vector3(0.0, 1.85, 0.0)
	_toy_table_heart.visible = false
	tbl_root.add_child(_toy_table_heart)

	var lbl2 := _make_label("SELAMATKAN VAS & MAINAN\nTekan [E / Aksi]", ACTION_POS[2] + Vector3(0.0, 2.38, 0.0))
	lbl2.font_size = 24; lbl2.modulate = Color(1.0, 0.94, 0.48)
	add_child(lbl2)
	_action_lbls.append(lbl2)
	_add_action_zone(ACTION_POS[2], 2, 2.35)


func _make_npc(pos: Vector3, label_txt: String, shirt_col: Color, bot_col: Color, hair_col: Color, with_angry_brows: bool = false) -> Dictionary:
	var root := Node3D.new()
	root.position = pos
	add_child(root)
	var skin := ToonMat.make(Color(0.98, 0.82, 0.70))
	var shirt := ToonMat.make(shirt_col)
	var bot := ToonMat.make(bot_col)
	var hair := ToonMat.make(hair_col)
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
	root.add_child(la); root.add_child(ra)

	# Articulated head group so Doni's head visibly shakes/recoils when bonking!
	var head_grp := Node3D.new()
	head_grp.position = Vector3(0.0, 1.38, 0.0)
	root.add_child(head_grp)

	var head := MeshInstance3D.new()
	var hsp := SphereMesh.new()
	hsp.radius = 0.35; hsp.height = 0.68
	head.mesh = hsp; head.material_override = skin
	head_grp.add_child(head)
	var hcap := MeshInstance3D.new()
	var hcsp := SphereMesh.new()
	hcsp.radius = 0.37; hcsp.height = 0.70
	hcap.mesh = hcsp; hcap.material_override = hair; hcap.position = Vector3(0.0, 0.06, -0.05)
	head_grp.add_child(hcap)
	for side: float in [-1.0, 1.0]:
		var eye := MeshInstance3D.new()
		var esp := SphereMesh.new()
		esp.radius = 0.045; esp.height = 0.09
		eye.mesh = esp; eye.material_override = eye_mat; eye.position = Vector3(side * 0.13, -0.01, 0.32)
		head_grp.add_child(eye)

	var brows := Node3D.new()
	brows.visible = with_angry_brows
	head_grp.add_child(brows)
	for side: float in [-1.0, 1.0]:
		var br := MeshInstance3D.new()
		var bb := BoxMesh.new()
		bb.size = Vector3(0.13, 0.032, 0.04)
		br.mesh = bb; br.material_override = eye_mat
		br.position = Vector3(side * 0.12, 0.09, 0.34)
		br.rotation_degrees.z = -side * 24.0
		brows.add_child(br)

	var tag := _make_label(label_txt, Vector3(0.0, 1.98, 0.0))
	tag.font_size = 24
	root.add_child(tag)
	var heart := Label3D.new()
	heart.text = "♥"; heart.font_size = 42; heart.outline_size = 6; heart.modulate = Color(1.0, 0.42, 0.62)
	heart.billboard = BaseMaterial3D.BILLBOARD_ENABLED; heart.position = Vector3(0.0, 2.40, 0.0); heart.visible = false
	root.add_child(heart)
	_add_box_collider(root, Vector3(0.8, 1.8, 0.8), Vector3(0.0, 0.9, 0.0))
	return {"root": root, "head": head_grp, "brows": brows, "l_arm": la, "r_arm": ra, "heart": heart}


func _make_arm(x_off: float, shirt: Material, skin: Material) -> Node3D:
	var g := Node3D.new()
	g.position = Vector3(x_off, 0.98, 0.0)
	var hand := MeshInstance3D.new()
	var hc := CapsuleMesh.new()
	hc.radius = 0.072; hc.height = 0.40
	hand.mesh = hc; hand.material_override = skin; hand.position = Vector3(0.0, -0.20, 0.0)
	g.add_child(hand)
	var sl := MeshInstance3D.new()
	var sp := SphereMesh.new()
	sp.radius = 0.105; sp.height = 0.21
	sl.mesh = sp; sl.material_override = shirt
	g.add_child(sl)
	return g


func _add_action_zone(pos: Vector3, stage_idx: int, radius: float) -> void:
	var area := Area3D.new()
	area.position = pos
	area.collision_layer = 4
	area.collision_mask = 2
	var col := CollisionShape3D.new()
	var sh := CylinderShape3D.new()
	sh.radius = radius; sh.height = 2.4
	col.shape = sh; col.position = Vector3(0.0, 1.2, 0.0)
	area.add_child(col)
	add_child(area)
	area.body_entered.connect(func(body: Node3D) -> void:
		if body is NaraController:
			action_zone_changed.emit(stage_idx, true)
	)
	area.body_exited.connect(func(body: Node3D) -> void:
		if body is NaraController:
			action_zone_changed.emit(stage_idx, false)
	)


func _build_lush_pond_and_themed_islands() -> void:
	var water_mat := ToonMat.make(Color(0.18, 0.66, 0.88), "", {"outline": false, "rim_strength": 0.28})
	var pond := MeshInstance3D.new()
	var wp := PlaneMesh.new()
	wp.size = Vector2(128.0, 128.0)
	pond.mesh = wp; pond.material_override = water_mat; pond.position = Vector3(0.0, -0.34, -20.0)
	add_child(pond)

	# Rich Lotus Pond: varied lily pads, pink & cream lotuses, mossy river rocks, and glowing lake pier posts!
	var pad_mat := ToonMat.make(Color(0.24, 0.66, 0.30), "", {"outline_width": 0.8})
	var lotus_pink := ToonMat.make(Color(1.0, 0.54, 0.72), "", {"outline_width": 0.8})
	var lotus_cream := ToonMat.make(Color(1.0, 0.94, 0.74), "", {"outline_width": 0.8})
	var rock_mat := ToonMat.make(Color(0.48, 0.52, 0.56), "", {"outline_width": 1.0})
	var wood_mat := ToonMat.make(Color(0.54, 0.34, 0.18), "res://assets/textures/wood_planks.webp", {"triplanar": true, "triplanar_scale": 0.44})
	var lamp_mat := ToonMat.make(Color(1.0, 0.92, 0.50), "", {"emission_color": Color(1.0, 0.84, 0.30), "emission_energy": 0.8})

	var pads := [
		Vector3(-4.6, -0.30, -4.8), Vector3(4.8, -0.30, -7.2), Vector3(-6.2, -0.30, -8.2), Vector3(6.5, -0.30, -4.2),
		Vector3(-4.8, -0.30, -22.5), Vector3(4.6, -0.30, -25.4), Vector3(-6.8, -0.30, -26.0), Vector3(6.4, -0.30, -22.0),
		Vector3(-4.5, -0.30, -40.2), Vector3(4.9, -0.30, -43.2), Vector3(-6.4, -0.30, -43.8), Vector3(6.8, -0.30, -39.8),
		Vector3(-7.6, -0.30, -14.5), Vector3(7.6, -0.30, -32.5),
	]
	for i in range(pads.size()):
		var lp: Vector3 = pads[i]
		var pad := MeshInstance3D.new()
		var pc := CylinderMesh.new()
		var r := 0.55 + float(i % 3) * 0.16
		pc.top_radius = r; pc.bottom_radius = r; pc.height = 0.04; pc.radial_segments = 14
		pad.mesh = pc; pad.material_override = pad_mat; pad.position = lp
		add_child(pad)
		if i % 2 == 0:
			var fl := MeshInstance3D.new()
			var fsp := SphereMesh.new()
			fsp.radius = 0.21; fsp.height = 0.25
			fl.mesh = fsp; fl.material_override = lotus_pink if i % 4 == 0 else lotus_cream
			fl.position = lp + Vector3(0.0, 0.14, 0.0)
			add_child(fl)

	for rk in [
		[Vector3(-7.4, -0.25, -6.2), Vector3(1.1, 0.55, 0.9)],
		[Vector3(7.8, -0.25, -24.0), Vector3(1.2, 0.60, 1.0)],
		[Vector3(-7.5, -0.25, -42.0), Vector3(1.0, 0.52, 0.85)],
	]:
		var rock := MeshInstance3D.new()
		var rsp := SphereMesh.new(); rsp.radius = 0.8; rsp.height = 1.6; rsp.radial_segments = 10; rsp.rings = 6
		rock.mesh = rsp; rock.scale = rk[1]; rock.position = rk[0]; rock.material_override = rock_mat
		add_child(rock)

	# Glowing wooden lakeside lantern pilings beside each bridge
	for bz: float in [-6.4, -24.2, -42.0]:
		for side: float in [-1.0, 1.0]:
			var post := MeshInstance3D.new()
			var pc := CylinderMesh.new(); pc.top_radius = 0.11; pc.bottom_radius = 0.14; pc.height = 1.9
			post.mesh = pc; post.material_override = wood_mat; post.position = Vector3(side * 3.55, 0.55, bz)
			add_child(post)
			var bulb := MeshInstance3D.new()
			var bb := BoxMesh.new(); bb.size = Vector3(0.28, 0.34, 0.28)
			bulb.mesh = bb; bulb.material_override = lamp_mat; bulb.position = Vector3(side * 3.55, 1.62, bz)
			add_child(bulb)

	# Distinct surface materials so EVERY island feels fresh and unique!
	var grass_sakura := ToonMat.make(Color(0.42, 0.76, 0.36), "res://assets/textures/grass.webp", {"triplanar": true, "triplanar_scale": 0.22, "outline": false})
	var grass_bright := ToonMat.make(Color(0.32, 0.74, 0.34), "res://assets/textures/grass.webp", {"triplanar": true, "triplanar_scale": 0.22, "outline": false})
	var grass_meadow := ToonMat.make(Color(0.38, 0.72, 0.30), "res://assets/textures/grass.webp", {"triplanar": true, "triplanar_scale": 0.22, "outline": false})

	var path_cream := ToonMat.make(Color(0.82, 0.76, 0.64), "res://assets/textures/cobblestone.webp", {"triplanar": true, "triplanar_scale": 0.34, "outline": false})
	var path_terra := ToonMat.make(Color(0.68, 0.44, 0.34), "res://assets/textures/cobblestone.webp", {"triplanar": true, "triplanar_scale": 0.34, "outline": false})
	var path_deck := ToonMat.make(Color(0.66, 0.44, 0.26), "res://assets/textures/wood_planks.webp", {"triplanar": true, "triplanar_scale": 0.36, "outline": false})
	var path_royal := ToonMat.make(Color(0.44, 0.36, 0.56), "res://assets/textures/cobblestone.webp", {"triplanar": true, "triplanar_scale": 0.34, "outline": false})

	var brick_mat := ToonMat.make(Color(0.84, 0.44, 0.34), "res://assets/textures/brick.webp", {"triplanar": true, "triplanar_scale": 0.48})
	var cap_mat := ToonMat.make(Color(0.94, 0.88, 0.76), "", {"outline_width": 1.1})

	# Exact 4 islands with SPACIOUS 4.0m open landing porches beyond every choice door!
	var islands := [
		{"z": 4.1, "d": 13.4, "w": 11.4, "grass": grass_sakura, "path": path_cream},    # z=[-2.6 .. +10.8]
		{"z": -15.3, "d": 10.2, "w": 11.4, "grass": grass_bright, "path": path_terra},  # z=[-20.4 .. -10.2]
		{"z": -33.1, "d": 10.2, "w": 11.4, "grass": grass_meadow, "path": path_deck},   # z=[-38.2 .. -28.0]
		{"z": -50.2, "d": 8.8, "w": 12.0, "grass": grass_sakura, "path": path_royal},   # z=[-54.6 .. -45.8]
	]
	for idx in range(islands.size()):
		var isl: Dictionary = islands[idx]
		var iz: float = float(isl["z"])
		var id: float = float(isl["d"])
		var iw: float = float(isl["w"])

		_add_box_collider(self, Vector3(iw, 1.0, id), Vector3(0.0, -0.5, iz))

		var turf := MeshInstance3D.new()
		var tb := BoxMesh.new()
		tb.size = Vector3(iw, 0.38, id)
		turf.mesh = tb; turf.material_override = isl["grass"]; turf.position = Vector3(0.0, -0.18, iz)
		add_child(turf)

		var stone_edge := MeshInstance3D.new()
		var sb := BoxMesh.new()
		sb.size = Vector3(iw + 0.34, 0.24, id + 0.34)
		stone_edge.mesh = sb; stone_edge.material_override = brick_mat; stone_edge.position = Vector3(0.0, -0.34, iz)
		add_child(stone_edge)

		var path := MeshInstance3D.new()
		var pb := BoxMesh.new()
		pb.size = Vector3(7.6, 0.06, id)
		path.mesh = pb; path.material_override = isl["path"]; path.position = Vector3(0.0, 0.01, iz)
		add_child(path)

		# Side walls
		for side: float in [-1.0, 1.0]:
			var wx := side * (iw * 0.5 - 0.22)
			var wall := MeshInstance3D.new()
			var wb := BoxMesh.new()
			wb.size = Vector3(0.46, 0.92, id)
			wall.mesh = wb; wall.material_override = brick_mat; wall.position = Vector3(wx, 0.46, iz)
			add_child(wall)
			var cap := MeshInstance3D.new()
			var cb := BoxMesh.new()
			cb.size = Vector3(0.58, 0.14, id + 0.12)
			cap.mesh = cb; cap.material_override = cap_mat; cap.position = Vector3(wx, 0.96, iz)
			add_child(cap)
			_add_box_collider(self, Vector3(0.65, 6.0, id + 0.3), Vector3(wx, 3.0, iz))

		# Front/Back lakeside shore curbs leaving wide center opening for 4.5m bridge!
		for edge_sign: float in [-1.0, 1.0]:
			var ez := iz + edge_sign * (id * 0.5)
			if (idx == 0 and edge_sign > 0.0) or (idx == 3 and edge_sign < 0.0):
				continue
			for sx: float in [-1.0, 1.0]:
				var seg_w := (iw * 0.5) - 2.35
				if seg_w > 0.3:
					var seg_x := sx * (2.35 + seg_w * 0.5)
					var curb := MeshInstance3D.new()
					var cb := BoxMesh.new()
					cb.size = Vector3(seg_w, 0.52, 0.36)
					curb.mesh = cb; curb.material_override = brick_mat; curb.position = Vector3(seg_x, 0.26, ez)
					add_child(curb)
					var ccap := MeshInstance3D.new()
					var ccb := BoxMesh.new()
					ccb.size = Vector3(seg_w + 0.08, 0.10, 0.44)
					ccap.mesh = ccb; ccap.material_override = cap_mat; ccap.position = Vector3(seg_x, 0.56, ez)
					add_child(ccap)
					_add_box_collider(self, Vector3(seg_w, 6.0, 0.45), Vector3(seg_x, 3.0, ez))

		# Distinct Island Theme Props!
		_decorate_island(idx, iz, id, iw)

	_add_box_collider(self, Vector3(12.5, 6.0, 0.6), Vector3(0.0, 3.0, 10.6))
	_add_box_collider(self, Vector3(7.0, 6.0, 0.6), Vector3(0.0, 3.0, -56.2))


func _decorate_island(idx: int, iz: float, id: float, _iw: float) -> void:
	var wood_mat := ToonMat.make(Color(0.58, 0.36, 0.20), "res://assets/textures/wood_planks.webp", {"triplanar": true, "triplanar_scale": 0.44})
	var trunk_mat := ToonMat.make(Color(0.52, 0.34, 0.20), "res://assets/textures/bark.webp", {"triplanar": true})

	match idx:
		0:
			# ISLAND 1: Sakura Calm Garden (pink blossom trees, park bench beside Doni, flower beds)
			var sakura_mat := ToonMat.make(Color(1.0, 0.66, 0.78), "res://assets/textures/leaf_canopy.webp", {"triplanar": true, "triplanar_scale": 0.48})
			for side: float in [-1.0, 1.0]:
				_spawn_themed_tree(Vector3(side * 4.55, 0.0, 7.6), 0.92, trunk_mat, sakura_mat)
				StorybookProps.spawn_flower(self, Vector3(side * 4.3, 0.0, 4.5), Color(1.0, 0.58, 0.74))
				StorybookProps.spawn_flower(self, Vector3(side * 4.5, 0.0, 6.2), Color(1.0, 0.94, 0.88))
			# Cozy wooden park bench on left side of Doni
			var bench := Node3D.new()
			bench.position = Vector3(-3.3, 0.0, 5.0); bench.rotation_degrees.y = 78.0
			add_child(bench)
			var seat := MeshInstance3D.new(); var sb := BoxMesh.new(); sb.size = Vector3(1.5, 0.12, 0.5)
			seat.mesh = sb; seat.material_override = wood_mat; seat.position = Vector3(0.0, 0.45, 0.0)
			bench.add_child(seat)
			var back := MeshInstance3D.new(); var bb := BoxMesh.new(); bb.size = Vector3(1.5, 0.46, 0.10)
			back.mesh = bb; back.material_override = wood_mat; back.position = Vector3(0.0, 0.74, -0.22)
			bench.add_child(back)
			_add_box_collider(bench, Vector3(1.55, 1.0, 0.6), Vector3(0.0, 0.5, 0.0))
		1:
			# ISLAND 2: Sunny Playground Courtyard (golden-lime trees, play ball, high bunting flags)
			var sunny_leaf := ToonMat.make(Color(0.56, 0.80, 0.24), "res://assets/textures/leaf_canopy.webp", {"triplanar": true, "triplanar_scale": 0.48})
			for side: float in [-1.0, 1.0]:
				_spawn_themed_tree(Vector3(side * 4.55, 0.0, -12.4), 0.88, trunk_mat, sunny_leaf)
				StorybookProps.spawn_flower(self, Vector3(side * 4.4, 0.0, -14.2), Color(1.0, 0.84, 0.22))
			var ball := MeshInstance3D.new()
			var bsp := SphereMesh.new(); bsp.radius = 0.28; bsp.height = 0.56
			ball.mesh = bsp; ball.material_override = ToonMat.make(Color(0.98, 0.56, 0.18), "", {"outline_width": 1.1})
			ball.position = Vector3(-2.6, 0.28, -12.1)
			add_child(ball)
			var fcols := [Color(0.24, 0.62, 0.96), Color(0.98, 0.80, 0.20), Color(0.94, 0.34, 0.38), Color(0.28, 0.78, 0.46)]
			for side: float in [-1.0, 1.0]:
				var p := MeshInstance3D.new(); var pc := CylinderMesh.new(); pc.top_radius = 0.08; pc.bottom_radius = 0.10; pc.height = 4.9
				p.mesh = pc; p.material_override = wood_mat; p.position = Vector3(side * 4.9, 2.45, -13.0)
				add_child(p)
			for i in range(8):
				var t := float(i + 1) / 9.0
				var fx := lerpf(-4.7, 4.7, t)
				var flag := MeshInstance3D.new(); var fm := PrismMesh.new(); fm.size = Vector3(0.42, 0.48, 0.05)
				flag.mesh = fm; flag.material_override = ToonMat.make(fcols[i % fcols.size()])
				flag.position = Vector3(fx, 4.72 - sin(t * PI) * 0.35, -13.0); flag.rotation_degrees.z = 180.0
				add_child(flag)
		2:
			# ISLAND 3: Cozy Timber Toy Veranda (red-cream striped canopy posts + stacked colorful toy blocks)
			var canopy_red := ToonMat.make(Color(0.86, 0.26, 0.30), "", {"outline_width": 1.0})
			var canopy_cream := ToonMat.make(Color(0.99, 0.95, 0.84), "", {"outline_width": 1.0})
			for side: float in [-1.0, 1.0]:
				var post := MeshInstance3D.new(); var pc := CylinderMesh.new(); pc.top_radius = 0.09; pc.bottom_radius = 0.11; pc.height = 3.2
				post.mesh = pc; post.material_override = wood_mat; post.position = Vector3(side * 2.2, 1.6, -30.8)
				add_child(post)
				StorybookProps.spawn_flower(self, Vector3(side * 4.4, 0.0, -30.4), Color(0.46, 0.76, 0.98))
			for s in range(5):
				var stripe := MeshInstance3D.new(); var sb := BoxMesh.new(); sb.size = Vector3(0.94, 0.14, 1.55)
				stripe.mesh = sb; stripe.material_override = canopy_red if s % 2 == 0 else canopy_cream
				stripe.position = Vector3(-1.88 + float(s) * 0.94, 3.22, -30.8)
				add_child(stripe)
			var block_cols := [Color(0.96, 0.36, 0.34), Color(0.98, 0.80, 0.22), Color(0.28, 0.68, 0.94)]
			for b_i in range(3):
				var blk := MeshInstance3D.new(); var bm := BoxMesh.new(); bm.size = Vector3(0.46, 0.46, 0.46)
				blk.mesh = bm; blk.material_override = ToonMat.make(block_cols[b_i])
				blk.position = Vector3(-4.1, 0.23 + float(b_i) * 0.46, -30.4 + float(b_i % 2) * 0.12)
				blk.rotation_degrees.y = float(b_i) * 16.0
				add_child(blk)
		3:
			# ISLAND 4: Star Celebration Plaza (gold-trimmed circular dais + swaying festive balloons!)
			var gold_mat := ToonMat.make(Color(0.96, 0.78, 0.20), "", {"outline_width": 1.1})
			var dais := MeshInstance3D.new(); var dc := CylinderMesh.new(); dc.top_radius = 2.3; dc.bottom_radius = 2.5; dc.height = 0.10; dc.radial_segments = 24
			dais.mesh = dc; dais.material_override = gold_mat; dais.position = Vector3(0.0, 0.05, star_position.z)
			add_child(dais)
			var bcols := [Color(0.96, 0.34, 0.44), Color(0.98, 0.82, 0.22), Color(0.28, 0.74, 0.96), Color(0.66, 0.42, 0.92)]
			for side: float in [-1.0, 1.0]:
				var grp := Node3D.new()
				grp.position = Vector3(side * 4.3, 0.0, -52.0)
				add_child(grp)
				for j in range(3):
					var bp := Vector3((float(j) - 1.0) * 0.30, 2.25 + float(j % 2) * 0.25, 0.0)
					var st := MeshInstance3D.new(); var sc := CylinderMesh.new(); sc.top_radius = 0.014; sc.bottom_radius = 0.014; sc.height = bp.y
					st.mesh = sc; st.material_override = ToonMat.make(Color(0.95, 0.92, 0.85), "", {"outline": false}); st.position = Vector3(bp.x * 0.5, bp.y * 0.5, 0.0)
					grp.add_child(st)
					var bal := MeshInstance3D.new(); var bs := SphereMesh.new(); bs.radius = 0.28; bs.height = 0.66
					bal.mesh = bs; bal.material_override = ToonMat.make(bcols[(j + (0 if side < 0 else 1)) % bcols.size()])
					bal.position = bp
					grp.add_child(bal)
				_balloons.append(grp)
				StorybookProps.spawn_flower(self, Vector3(side * 4.5, 0.0, iz + id * 0.18), Color(1.0, 0.56, 0.68))


func _spawn_themed_tree(pos: Vector3, sc: float, trunk_mat: Material, leaf_mat: Material) -> void:
	var tr := Node3D.new()
	tr.position = pos; tr.scale = Vector3(sc, sc, sc)
	add_child(tr)
	var trunk := MeshInstance3D.new(); var tc := CylinderMesh.new(); tc.top_radius = 0.22; tc.bottom_radius = 0.30; tc.height = 2.0
	trunk.mesh = tc; trunk.material_override = trunk_mat; trunk.position = Vector3(0.0, 1.0, 0.0)
	tr.add_child(trunk)
	var cr := MeshInstance3D.new(); var sp := SphereMesh.new(); sp.radius = 1.25; sp.height = 2.3
	cr.mesh = sp; cr.material_override = leaf_mat; cr.position = Vector3(0.0, 2.65, 0.0)
	tr.add_child(cr)
	_add_box_collider(tr, Vector3(0.8, 2.4, 0.8), Vector3(0.0, 1.2, 0.0))


func _build_three_choice_stages() -> void:
	var brick_mat := ToonMat.make(Color(0.84, 0.44, 0.34), "res://assets/textures/brick.webp", {"triplanar": true, "triplanar_scale": 0.48})
	var wood_mat := ToonMat.make(Color(0.58, 0.36, 0.20), "res://assets/textures/wood_planks.webp", {"triplanar": true, "triplanar_scale": 0.44})
	var sub_wood_mat := ToonMat.make(Color(0.40, 0.24, 0.12), "res://assets/textures/wood_planks.webp", {"triplanar": true, "triplanar_scale": 0.44})
	var roof_cols := [Color(0.74, 0.26, 0.36), Color(0.20, 0.58, 0.48), Color(0.32, 0.46, 0.78)]
	var gold_mat := ToonMat.make(Color(0.96, 0.76, 0.18), "", {"outline_width": 1.1})
	var lantern_mat := ToonMat.make(Color(1.0, 0.92, 0.52), "", {"emission_color": Color(1.0, 0.84, 0.32), "emission_energy": 0.85})
	var parch_mat := ToonMat.make(Color(0.99, 0.96, 0.88), "", {"outline_width": 1.1})

	for idx in range(3):
		var z_pos := STAGE_Z[idx]
		var info: Dictionary = _stage_data[idx]
		var right_on_left := (randi() % 2 == 0)
		var roof_mat := ToonMat.make(roof_cols[idx % roof_cols.size()], "", {"outline_width": 1.2})

		var stage_root := Node3D.new()
		stage_root.position = Vector3(0.0, 0.0, z_pos)
		add_child(stage_root)

		var pil := MeshInstance3D.new()
		var pb := BoxMesh.new()
		pb.size = Vector3(0.90, 3.2, 0.90)
		pil.mesh = pb; pil.material_override = brick_mat; pil.position = Vector3(0.0, 1.6, 0.0)
		stage_root.add_child(pil)
		_add_box_collider(stage_root, Vector3(0.98, 3.6, 0.98), Vector3(0.0, 1.8, 0.0))

		var pstar_mat := ToonMat.make(Color(0.76, 0.72, 0.66), "", {"emission_color": Color(1.0, 0.85, 0.22), "emission_energy": 0.18, "unique": true})
		var pstar := MeshInstance3D.new()
		pstar.mesh = _make_3d_star_mesh(0.42, 0.20, 0.12)
		pstar.material_override = pstar_mat; pstar.position = Vector3(0.0, 3.72, 0.0)
		stage_root.add_child(pstar)
		_pillar_stars.append(pstar); _pillar_mats.append(pstar_mat)

		var header := _make_label(str(info["badge"]), Vector3(0.0, 4.52, 0.0))
		header.font_size = 36
		stage_root.add_child(header)

		var right_leaves: Array = []
		var right_blocker: StaticBody3D = null
		var wrong_root: Node3D = null

		for side_i in range(2):
			var gx := -2.65 if side_i == 0 else 2.65
			var is_right := (side_i == 0 and right_on_left) or (side_i == 1 and not right_on_left)
			var txt := str(info["right"]) if is_right else str(info["wrong"])

			var outer_x := -4.95 if side_i == 0 else 4.95
			var op := MeshInstance3D.new()
			var opb := BoxMesh.new()
			opb.size = Vector3(0.84, 3.2, 0.84)
			op.mesh = opb; op.material_override = brick_mat; op.position = Vector3(outer_x, 1.6, 0.0)
			stage_root.add_child(op)
			_add_box_collider(stage_root, Vector3(1.25, 3.6, 0.95), Vector3(outer_x, 1.8, 0.0))

			var lantern := MeshInstance3D.new()
			var lb := BoxMesh.new()
			lb.size = Vector3(0.36, 0.44, 0.36)
			lantern.mesh = lb; lantern.material_override = lantern_mat; lantern.position = Vector3(outer_x, 3.44, 0.0)
			stage_root.add_child(lantern)

			var beam := MeshInstance3D.new()
			var bmb := BoxMesh.new()
			bmb.size = Vector3(4.45, 0.36, 0.68)
			beam.mesh = bmb; beam.material_override = wood_mat; beam.position = Vector3(gx, 3.12, 0.0)
			stage_root.add_child(beam)

			var roof := MeshInstance3D.new()
			var rmesh := PrismMesh.new()
			rmesh.size = Vector3(4.65, 0.58, 0.98)
			roof.mesh = rmesh; roof.material_override = roof_mat; roof.position = Vector3(gx, 3.58, 0.0)
			stage_root.add_child(roof)

			var sign_frame := MeshInstance3D.new()
			var sfb := BoxMesh.new()
			sfb.size = Vector3(3.38, 1.12, 0.10)
			sign_frame.mesh = sfb; sign_frame.material_override = wood_mat; sign_frame.position = Vector3(gx, 2.58, 0.36)
			stage_root.add_child(sign_frame)

			var sign_bg := MeshInstance3D.new()
			var sbg := BoxMesh.new()
			sbg.size = Vector3(3.16, 0.92, 0.06)
			sign_bg.mesh = sbg; sign_bg.material_override = parch_mat; sign_bg.position = Vector3(gx, 2.58, 0.42)
			stage_root.add_child(sign_bg)

			var slbl := Label3D.new()
			slbl.text = txt; slbl.font_size = 27; slbl.outline_size = 5
			slbl.modulate = Color(0.20, 0.12, 0.08); slbl.outline_modulate = Color(1.0, 0.98, 0.90)
			slbl.position = Vector3(gx, 2.58, 0.47)
			stage_root.add_child(slbl)

			var door_root := Node3D.new()
			door_root.position = Vector3(gx, 0.0, 0.0)
			stage_root.add_child(door_root)

			var lpiv := Node3D.new()
			lpiv.position = Vector3(-1.76, 0.0, 0.0)
			door_root.add_child(lpiv)
			lpiv.add_child(_make_door_leaf(0.88, 0.60, wood_mat, gold_mat))

			var rpiv := Node3D.new()
			rpiv.position = Vector3(1.76, 0.0, 0.0)
			door_root.add_child(rpiv)
			rpiv.add_child(_make_door_leaf(-0.88, -0.60, wood_mat, gold_mat))

			if is_right:
				right_leaves = [lpiv, rpiv]
				# Solid collider on the right door while closed so Nara NEVER clips through closed wood!
				right_blocker = StaticBody3D.new()
				right_blocker.collision_layer = 1; right_blocker.collision_mask = 0
				var rbcol := CollisionShape3D.new()
				var rbsh := BoxShape3D.new()
				rbsh.size = Vector3(3.85, 3.2, 0.38)
				rbcol.shape = rbsh; right_blocker.position = Vector3(gx, 1.6, 0.0); right_blocker.add_child(rbcol)
				stage_root.add_child(right_blocker)
			else:
				wrong_root = door_root
				var wb := StaticBody3D.new()
				wb.collision_layer = 1; wb.collision_mask = 0
				var wbcol := CollisionShape3D.new()
				var wbsh := BoxShape3D.new()
				wbsh.size = Vector3(4.0, 3.2, 0.45)
				wbcol.shape = wbsh; wb.position = Vector3(gx, 1.6, 0.0); wb.add_child(wbcol)
				stage_root.add_child(wb)

			var area := Area3D.new()
			area.collision_layer = 4; area.collision_mask = 2
			var col := CollisionShape3D.new()
			var sh := BoxShape3D.new()
			sh.size = Vector3(3.4, 2.4, 1.25)
			col.shape = sh; col.position = Vector3(gx, 1.2, 0.85)
			area.add_child(col); stage_root.add_child(area)
			var s_idx := idx
			var s_ok := is_right
			var s_pos := Vector3(gx, 0.0, z_pos)
			area.body_entered.connect(func(body: Node3D) -> void:
				if body is NaraController and not _stage_solved[s_idx]:
					gate_entered.emit(s_idx, s_ok, s_pos)
			)

		_right_door_pivots.append(right_leaves)
		_right_door_blockers.append(right_blocker)
		_wrong_door_roots.append(wrong_root)

		# === SPACIOUS 8.2m SEAMLESS WOODEN BRIDGE (starts well past open doors!) ===
		var br_z: float = float(BRIDGE_SPECS[idx]["z"])
		var br_len: float = float(BRIDGE_SPECS[idx]["len"])
		var br_root := Node3D.new()
		br_root.position = Vector3(0.0, 0.0, br_z)
		br_root.visible = false
		add_child(br_root)

		var sub_deck := MeshInstance3D.new()
		var sdb := BoxMesh.new()
		sdb.size = Vector3(4.65, 0.14, br_len)
		sub_deck.mesh = sdb; sub_deck.material_override = sub_wood_mat; sub_deck.position = Vector3(0.0, -0.05, 0.0)
		br_root.add_child(sub_deck)

		var plank_count := 12
		var step_z := br_len / float(plank_count)
		for p in range(plank_count):
			var pz := -br_len * 0.5 + (float(p) + 0.5) * step_z
			var plank := MeshInstance3D.new()
			var plb := BoxMesh.new()
			plb.size = Vector3(4.54, 0.07, step_z - 0.04)
			plank.mesh = plb; plank.material_override = wood_mat; plank.position = Vector3(0.0, 0.03, pz)
			br_root.add_child(plank)

		for rx: float in [-2.28, 2.28]:
			var rail := MeshInstance3D.new()
			var rb := BoxMesh.new()
			rb.size = Vector3(0.16, 0.14, br_len - 0.3)
			rail.mesh = rb; rail.material_override = gold_mat; rail.position = Vector3(rx, 0.74, 0.0)
			br_root.add_child(rail)
			for rz_i in range(5):
				var rz := -br_len * 0.44 + float(rz_i) * (br_len * 0.22)
				var post := MeshInstance3D.new()
				var pc := CylinderMesh.new()
				pc.top_radius = 0.09; pc.bottom_radius = 0.11; pc.height = 0.85
				post.mesh = pc; post.material_override = wood_mat; post.position = Vector3(rx, 0.38, rz)
				br_root.add_child(post)

		_bridges.append(br_root)

		# Rolling Wooden-Red Anger Log ("Gelondong Kayu Amarah") physically rolling back & forth!
		var wave_root := Node3D.new()
		wave_root.position = Vector3(0.0, 0.26, br_z)
		wave_root.visible = false
		add_child(wave_root)

		var log_spin := Node3D.new()
		wave_root.add_child(log_spin)
		var bar := MeshInstance3D.new()
		var barm := CylinderMesh.new()
		barm.top_radius = 0.22; barm.bottom_radius = 0.22; barm.height = 4.15; barm.radial_segments = 14
		bar.mesh = barm; bar.rotation_degrees.z = 90.0
		bar.material_override = ToonMat.make(Color(0.64, 0.30, 0.16), "res://assets/textures/bark.webp", {"triplanar": true, "triplanar_scale": 0.6})
		log_spin.add_child(bar)

		# Glowing red anger bands & wooden ridges around the log so rolling rotation is unmistakably visible!
		var band_mat := ToonMat.make(Color(0.96, 0.24, 0.22), "", {"emission_color": Color(1.0, 0.28, 0.18), "emission_energy": 0.55})
		for bx: float in [-1.5, -0.5, 0.5, 1.5]:
			var band := MeshInstance3D.new()
			var bm := CylinderMesh.new()
			bm.top_radius = 0.245; bm.bottom_radius = 0.245; bm.height = 0.22; bm.radial_segments = 14
			band.mesh = bm; band.rotation_degrees.z = 90.0; band.position.x = bx
			band.material_override = band_mat
			log_spin.add_child(band)
		for rib_i in range(4):
			var ang := float(rib_i) * PI * 0.5
			var rib := MeshInstance3D.new()
			var rb := BoxMesh.new()
			rb.size = Vector3(3.95, 0.06, 0.06)
			rib.mesh = rb; rib.material_override = band_mat
			rib.position = Vector3(0.0, cos(ang) * 0.22, sin(ang) * 0.22)
			log_spin.add_child(rib)

		var wlbl := _make_label("LOMPAT!", Vector3(0.0, 0.80, 0.0))
		wlbl.font_size = 28; wlbl.modulate = Color(1.0, 0.88, 0.34)
		wave_root.add_child(wlbl)

		var w_area := Area3D.new()
		w_area.collision_layer = 4; w_area.collision_mask = 2
		var wcol := CollisionShape3D.new()
		var wsh := BoxShape3D.new()
		wsh.size = Vector3(4.2, 0.44, 0.52)
		wcol.shape = wsh
		w_area.add_child(wcol); wave_root.add_child(w_area)
		var b_idx := idx
		w_area.body_entered.connect(func(body: Node3D) -> void:
			if body is NaraController and wave_root.visible and body.global_position.y < 0.42:
				jump_wave_hit.emit(b_idx, wave_root.position.z)
		)
		_jump_waves.append(wave_root)
		_wave_logs.append(log_spin)
		_wave_prev_z.append(br_z)

		var br_col_body := StaticBody3D.new()
		br_col_body.collision_layer = 0; br_col_body.collision_mask = 0
		var bf_col := CollisionShape3D.new()
		var bf_sh := BoxShape3D.new()
		bf_sh.size = Vector3(4.7, 1.0, br_len + 0.5)
		bf_col.shape = bf_sh; bf_col.position = Vector3(0.0, -0.45, br_z)
		br_col_body.add_child(bf_col)
		for rx: float in [-2.45, 2.45]:
			var rcol := CollisionShape3D.new()
			var rsh := BoxShape3D.new()
			rsh.size = Vector3(0.45, 5.0, br_len)
			rcol.shape = rsh; rcol.position = Vector3(rx, 2.5, br_z)
			br_col_body.add_child(rcol)
		add_child(br_col_body)
		_bridge_floor_cols.append(br_col_body)

		# Shore blocker placed at island northern shore (z_pos - 3.85) before bridge rises
		var gap_blk := StaticBody3D.new()
		gap_blk.collision_layer = 1; gap_blk.collision_mask = 0
		var gbcol := CollisionShape3D.new()
		var gbsh := BoxShape3D.new()
		gbsh.size = Vector3(11.6, 5.0, 0.55)
		gbcol.shape = gbsh; gap_blk.position = Vector3(0.0, 2.5, z_pos - 3.85)
		gap_blk.add_child(gbcol)
		add_child(gap_blk)
		_gap_blockers.append(gap_blk)


func _make_door_leaf(x_pos: float, handle_x: float, wood_mat: Material, gold_mat: Material) -> Node3D:
	var g := Node3D.new()
	var leaf := MeshInstance3D.new()
	var lb := BoxMesh.new()
	lb.size = Vector3(1.74, 2.02, 0.16)
	leaf.mesh = lb; leaf.material_override = wood_mat; leaf.position = Vector3(x_pos, 1.02, 0.0)
	g.add_child(leaf)
	var handle := MeshInstance3D.new()
	var hsp := SphereMesh.new()
	hsp.radius = 0.085; hsp.height = 0.17
	handle.mesh = hsp; handle.material_override = gold_mat; handle.position = Vector3(x_pos + handle_x, 1.02, 0.12)
	g.add_child(handle)
	return g


func _build_star_and_exit_gate() -> void:
	var star_root := Node3D.new()
	star_root.position = star_position
	add_child(star_root)
	_star_mat = ToonMat.make(Color(0.75, 0.72, 0.64), "", {"emission_color": Color(1.0, 0.85, 0.2), "emission_energy": 0.15, "unique": true})
	_star_mesh = MeshInstance3D.new()
	_star_mesh.mesh = _make_3d_star_mesh(0.78, 0.36, 0.20)
	_star_mesh.material_override = _star_mat; _star_mesh.position = Vector3(0.0, 2.35, 0.0)
	star_root.add_child(_star_mesh)

	var badge := Label3D.new()
	badge.text = "POS 7"; badge.font_size = 72; badge.outline_size = 12; badge.modulate = Color(1.0, 0.96, 0.78)
	badge.billboard = BaseMaterial3D.BILLBOARD_ENABLED; badge.position = Vector3(0.0, 3.45, 0.0)
	star_root.add_child(badge)

	_confetti = GPUParticles3D.new()
	_confetti.position = Vector3(0.0, 2.5, 0.0); _confetti.amount = 42; _confetti.lifetime = 1.5
	_confetti.one_shot = true; _confetti.explosiveness = 0.85; _confetti.emitting = false
	var cpm := ParticleProcessMaterial.new()
	cpm.direction = Vector3(0.0, 1.0, 0.0); cpm.spread = 85.0
	cpm.initial_velocity_min = 3.0; cpm.initial_velocity_max = 5.8; cpm.gravity = Vector3(0.0, -5.5, 0.0)
	cpm.scale_min = 0.09; cpm.scale_max = 0.18; cpm.color = Color(1.0, 0.85, 0.25)
	_confetti.process_material = cpm
	var cbox := BoxMesh.new(); cbox.size = Vector3(0.6, 0.6, 0.15)
	var cmat := StandardMaterial3D.new(); cmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED; cmat.albedo_color = Color(1.0, 0.76, 0.24)
	cbox.material = cmat; _confetti.draw_pass_1 = cbox
	star_root.add_child(_confetti)

	var gate_root := Node3D.new()
	gate_root.position = exit_gate_position
	add_child(gate_root)

	var brick_mat := ToonMat.make(Color(0.84, 0.44, 0.34), "res://assets/textures/brick.webp", {"triplanar": true, "triplanar_scale": 0.48})
	var gwood_mat := ToonMat.make(Color(0.62, 0.39, 0.22), "res://assets/textures/wood_planks.webp", {"triplanar": true, "triplanar_scale": 0.42})

	for side: float in [-1.0, 1.0]:
		var x: float = side * 2.95
		var pil := MeshInstance3D.new()
		var pbox := BoxMesh.new(); pbox.size = Vector3(0.85, 3.6, 0.85)
		pil.mesh = pbox; pil.material_override = brick_mat; pil.position = Vector3(x, 1.8, 0.0)
		gate_root.add_child(pil)
		_add_box_collider(gate_root, Vector3(0.95, 3.8, 0.95), Vector3(x, 1.9, 0.0))

	var beam := MeshInstance3D.new()
	var bbox := BoxMesh.new(); bbox.size = Vector3(6.8, 0.55, 0.65)
	beam.mesh = bbox; beam.material_override = gwood_mat; beam.position = Vector3(0.0, 3.65, 0.0)
	gate_root.add_child(beam)

	var sign_bg := MeshInstance3D.new()
	var sbox := BoxMesh.new(); sbox.size = Vector3(5.2, 1.15, 0.18)
	sign_bg.mesh = sbox; sign_bg.material_override = ToonMat.make(Color(0.48, 0.24, 0.56), "", {"outline_width": 1.4})
	sign_bg.position = Vector3(0.0, 4.48, 0.05)
	gate_root.add_child(sign_bg)

	_gate_lbl = Label3D.new()
	_gate_lbl.text = "NEXT RUTE -> POS 8 (FINISH)\n(Selesaikan 3 Prinsip dulu)"
	_gate_lbl.font_size = 36; _gate_lbl.outline_size = 8; _gate_lbl.modulate = Color(1.0, 0.96, 0.82)
	_gate_lbl.position = Vector3(0.0, 4.48, 0.17)
	gate_root.add_child(_gate_lbl)

	_gate_left_pivot = Node3D.new(); _gate_left_pivot.position = Vector3(-2.5, 0.0, 0.0); gate_root.add_child(_gate_left_pivot)
	var dbox := BoxMesh.new(); dbox.size = Vector3(2.45, 2.35, 0.18)
	var ld := MeshInstance3D.new(); ld.mesh = dbox; ld.material_override = gwood_mat; ld.position = Vector3(1.25, 1.2, 0.0)
	_gate_left_pivot.add_child(ld)

	_gate_right_pivot = Node3D.new(); _gate_right_pivot.position = Vector3(2.5, 0.0, 0.0); gate_root.add_child(_gate_right_pivot)
	var rd := MeshInstance3D.new(); rd.mesh = dbox; rd.material_override = gwood_mat; rd.position = Vector3(-1.25, 1.2, 0.0)
	_gate_right_pivot.add_child(rd)

	_gate_blocker = StaticBody3D.new(); _gate_blocker.collision_layer = 1; _gate_blocker.collision_mask = 0
	var bcol := CollisionShape3D.new(); var bshape := BoxShape3D.new(); bshape.size = Vector3(5.2, 2.8, 0.45)
	bcol.shape = bshape; _gate_blocker.position = Vector3(0.0, 1.4, 0.0); _gate_blocker.add_child(bcol)
	gate_root.add_child(_gate_blocker)

	_portal_area = Area3D.new(); _portal_area.collision_layer = 4; _portal_area.collision_mask = 2
	var pcol := CollisionShape3D.new(); var pshape := BoxShape3D.new(); pshape.size = Vector3(4.8, 3.2, 2.6)
	pcol.shape = pshape; pcol.position = Vector3(0.0, 1.4, -0.3); _portal_area.add_child(pcol)
	gate_root.add_child(_portal_area)
	_portal_area.body_entered.connect(func(body: Node3D) -> void:
		if body is NaraController and _gate_opened:
			next_route_entered.emit()
	)


func _build_closed_back_gate() -> void:
	var back := Node3D.new()
	back.position = Vector3(0.0, 0.0, 10.6)
	add_child(back)
	var brick_mat := ToonMat.make(Color(0.84, 0.44, 0.34), "res://assets/textures/brick.webp", {"triplanar": true, "triplanar_scale": 0.48})
	var wood_mat := ToonMat.make(Color(0.62, 0.39, 0.22), "res://assets/textures/wood_planks.webp", {"triplanar": true, "triplanar_scale": 0.42})
	for side: float in [-1.0, 1.0]:
		var pil := MeshInstance3D.new()
		var pb := BoxMesh.new(); pb.size = Vector3(0.8, 3.2, 0.8)
		pil.mesh = pb; pil.material_override = brick_mat; pil.position = Vector3(side * 2.8, 1.6, 0.0)
		back.add_child(pil)
	var door := MeshInstance3D.new()
	var db := BoxMesh.new(); db.size = Vector3(4.8, 3.08, 0.22)
	door.mesh = db; door.material_override = wood_mat; door.position = Vector3(0.0, 1.54, 0.0)
	back.add_child(door)
	var beam := MeshInstance3D.new()
	var bb := BoxMesh.new(); bb.size = Vector3(6.4, 0.5, 0.6)
	beam.mesh = bb; beam.material_override = wood_mat; beam.position = Vector3(0.0, 3.3, 0.0)
	back.add_child(beam)
	_add_box_collider(back, Vector3(15.0, 5.0, 0.65), Vector3(0.0, 2.5, 0.0))
	StorybookProps.build_flanking_brick_walls(self, 10.6, 2.8, 5.7, 1.05)
	StorybookProps.build_flanking_brick_walls(self, exit_gate_position.z, 2.95, 6.0, 1.05)
	StorybookProps.spawn_horizon_backdrop_360(self, -57.0, 12.0, 12.0)


func _build_horizon_hills_and_trees() -> void:
	var hill_mat := ToonMat.make(Color(0.30, 0.66, 0.28), "res://assets/textures/grass.webp", {"triplanar": true, "triplanar_scale": 0.14, "outline": false})
	for h in [
		[Vector3(-36.0, -3.5, -24.0), Vector3(1.6, 0.65, 1.5), 15.5],
		[Vector3(36.0, -3.5, -24.0), Vector3(1.6, 0.68, 1.5), 15.5],
		[Vector3(0.0, -4.5, -80.0), Vector3(2.6, 0.62, 1.2), 19.0],
	]:
		var m := MeshInstance3D.new()
		var sp := SphereMesh.new(); sp.radius = float(h[2]); sp.height = float(h[2]) * 2.0
		m.mesh = sp; m.scale = h[1]; m.position = h[0]; m.material_override = hill_mat
		add_child(m)

	var trunk_mat := ToonMat.make(Color(0.55, 0.36, 0.22), "res://assets/textures/bark.webp", {"triplanar": true})
	var leaf_mat := ToonMat.make(Color(0.28, 0.68, 0.30), "res://assets/textures/leaf_canopy.webp", {"triplanar": true, "triplanar_scale": 0.45})
	for t in [
		[Vector3(-10.5, -0.3, 6.2), 1.3], [Vector3(10.5, -0.3, 5.8), 1.25],
		[Vector3(-11.0, -0.3, -15.3), 1.35], [Vector3(11.0, -0.3, -15.3), 1.3],
		[Vector3(-11.0, -0.3, -33.1), 1.35], [Vector3(11.0, -0.3, -33.1), 1.3],
		[Vector3(-10.5, -0.3, -50.2), 1.3], [Vector3(10.5, -0.3, -50.2), 1.25],
	]:
		var tr := Node3D.new(); tr.position = t[0]
		var sc: float = float(t[1]); tr.scale = Vector3(sc, sc, sc)
		add_child(tr)
		var trunk := MeshInstance3D.new(); var tc := CylinderMesh.new()
		tc.top_radius = 0.26; tc.bottom_radius = 0.38; tc.height = 2.2
		trunk.mesh = tc; trunk.material_override = trunk_mat; trunk.position = Vector3(0.0, 1.1, 0.0)
		tr.add_child(trunk)
		var cr := MeshInstance3D.new(); var sp := SphereMesh.new()
		sp.radius = 1.45; sp.height = 2.8
		cr.mesh = sp; cr.material_override = leaf_mat; cr.position = Vector3(0.0, 2.95, 0.0)
		tr.add_child(cr)


func _make_label(txt: String, pos: Vector3) -> Label3D:
	var lbl := Label3D.new()
	lbl.text = txt; lbl.font_size = 32; lbl.outline_size = 7; lbl.modulate = Color(1.0, 0.96, 0.80)
	lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED; lbl.position = pos
	return lbl


func _add_box_collider(parent: Node3D, size: Vector3, pos: Vector3) -> void:
	var body := StaticBody3D.new(); body.collision_layer = 1; body.collision_mask = 0
	var col := CollisionShape3D.new(); var sh := BoxShape3D.new(); sh.size = size
	col.shape = sh; body.position = pos; body.add_child(col)
	parent.add_child(body)


func _make_3d_star_mesh(outer_r: float, inner_r: float, half_t: float) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var pts: Array[Vector2] = []
	for i in range(10):
		var a := -PI * 0.5 + float(i) * PI / 5.0
		var r := outer_r if i % 2 == 0 else inner_r
		pts.append(Vector2(cos(a) * r, sin(a) * r))
	var fc := Vector3(0.0, 0.0, half_t); var bc := Vector3(0.0, 0.0, -half_t)
	for i in range(10):
		var p1 := pts[i]; var p2 := pts[(i + 1) % 10]
		var v1f := Vector3(p1.x, -p1.y, 0.0); var v2f := Vector3(p2.x, -p2.y, 0.0)
		st.add_vertex(fc); st.add_vertex(v1f); st.add_vertex(v2f)
		st.add_vertex(bc); st.add_vertex(v2f); st.add_vertex(v1f)
	st.generate_normals()
	return st.commit()
