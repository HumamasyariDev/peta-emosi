class_name NaraController
extends CharacterBody3D

@export var move_speed: float = 5.4
@export var jump_velocity: float = 6.2
@export var turn_speed: float = 10.0

var _gravity: float = 18.0
var _walk_time: float = 0.0
var _step_accum: float = 0.0
var _auto_target: Variant = null

var _body_pivot: Node3D
var _head_group: Node3D
var _left_leg: Node3D
var _right_leg: Node3D
var _left_arm: Node3D
var _right_arm: Node3D
var _blob_shadow: MeshInstance3D
var _dust_particles: GPUParticles3D
var _emote_name: String = ""
var _emote_timer: float = 0.0
var _emote_t: float = 0.0
var _control_locked: bool = false
var _knockback_timer: float = 0.0
var _carrying: bool = false
var _carry_anchor: Node3D
var _holding_trophy: bool = false
var _trophy_anchor: Node3D
var _pushing_wall: bool = false
var _wall_bonk_cd: float = 0.0
var _wall_bubble: Label3D
var _wall_bubble_timer: float = 0.0


func set_control_locked(locked: bool) -> void:
	_control_locked = locked
	if locked:
		_auto_target = null
		velocity = Vector3.ZERO


func set_carrying(carrying: bool) -> void:
	_carrying = carrying


func get_carry_anchor() -> Node3D:
	if _carry_anchor == null and _body_pivot != null:
		_carry_anchor = Node3D.new()
		_carry_anchor.position = Vector3(0.0, 0.78, 0.34)
		_body_pivot.add_child(_carry_anchor)
	return _carry_anchor


func set_holding_trophy(holding: bool) -> void:
	_holding_trophy = holding


func get_trophy_anchor() -> Node3D:
	if _trophy_anchor == null and _body_pivot != null:
		_trophy_anchor = Node3D.new()
		_trophy_anchor.position = Vector3(0.0, 1.98, 0.06)
		_body_pivot.add_child(_trophy_anchor)
	return _trophy_anchor


func play_emote(emote_name: String, duration: float = 1.4) -> void:
	_emote_name = emote_name
	_emote_timer = duration
	_emote_t = 0.0


func apply_knockback(impulse: Vector3, tumble_duration: float = 0.62) -> void:
	_auto_target = null
	velocity = impulse
	_knockback_timer = tumble_duration
	play_emote("knockback", tumble_duration)


func face_toward(world_pos: Vector3) -> void:
	var d := world_pos - global_position
	d.y = 0.0
	if d.length_squared() > 0.001:
		rotation.y = atan2(d.x, d.z)


func _ready() -> void:
	collision_layer = 2
	collision_mask = 1
	_build_collision()
	_build_visuals()
	_build_blob_shadow()
	_build_run_dust()
	ToonMat.optimize_tree(self)


func walk_to(world_pos: Vector3) -> void:
	_auto_target = world_pos


func cancel_auto_walk() -> void:
	_auto_target = null


func _build_collision() -> void:
	var col := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.34
	cap.height = 1.45
	col.shape = cap
	col.position.y = 0.725
	add_child(col)


func _build_visuals() -> void:
	_body_pivot = Node3D.new()
	add_child(_body_pivot)

	var skin := ToonMat.make(Color(1.0, 0.86, 0.77))
	var shirt := ToonMat.make(Color(1.0, 0.49, 0.71))
	var skirt := ToonMat.make(Color(1.0, 0.72, 0.2))
	var shoe := ToonMat.make(Color(0.94, 0.32, 0.58))
	var hair := ToonMat.make(Color(0.14, 0.12, 0.16))
	var white := ToonMat.make(Color(1.0, 1.0, 1.0), "", {"outline": false})
	var eye_mat := ToonMat.make(Color(0.11, 0.08, 0.13), "", {"outline": false})
	var clip_y := ToonMat.make(Color(0.98, 0.8, 0.08), "", {"outline_width": 1.2})
	var clip_r := ToonMat.make(Color(0.95, 0.25, 0.37), "", {"outline_width": 1.2})

	_left_leg = _make_leg(-0.14, skin, white, shoe)
	_right_leg = _make_leg(0.14, skin, white, shoe)
	_body_pivot.add_child(_left_leg)
	_body_pivot.add_child(_right_leg)

	var skirt_m := _mesh(CylinderMesh.new(), skirt, Vector3(0, 0.62, 0))
	(skirt_m.mesh as CylinderMesh).top_radius = 0.22
	(skirt_m.mesh as CylinderMesh).bottom_radius = 0.33
	(skirt_m.mesh as CylinderMesh).height = 0.30
	_body_pivot.add_child(skirt_m)

	var torso := _mesh(CylinderMesh.new(), shirt, Vector3(0, 0.95, 0))
	(torso.mesh as CylinderMesh).top_radius = 0.20
	(torso.mesh as CylinderMesh).bottom_radius = 0.24
	(torso.mesh as CylinderMesh).height = 0.42
	_body_pivot.add_child(torso)

	_left_arm = _make_arm(-1.0, shirt, skin)
	_right_arm = _make_arm(1.0, shirt, skin)
	_body_pivot.add_child(_left_arm)
	_body_pivot.add_child(_right_arm)

	_head_group = Node3D.new()
	_head_group.position = Vector3(0, 1.48, 0)
	_body_pivot.add_child(_head_group)

	var head := _mesh(SphereMesh.new(), skin, Vector3.ZERO)
	(head.mesh as SphereMesh).radius = 0.36
	(head.mesh as SphereMesh).height = 0.70
	_head_group.add_child(head)

	var hair_top := _mesh(SphereMesh.new(), hair, Vector3(0, 0.05, -0.04))
	(hair_top.mesh as SphereMesh).radius = 0.385
	(hair_top.mesh as SphereMesh).height = 0.74
	_head_group.add_child(hair_top)

	var bangs := _mesh(BoxMesh.new(), hair, Vector3(0, 0.16, 0.25))
	(bangs.mesh as BoxMesh).size = Vector3(0.50, 0.16, 0.18)
	_head_group.add_child(bangs)

	var c1 := _mesh(BoxMesh.new(), clip_y, Vector3(-0.20, 0.20, 0.34))
	(c1.mesh as BoxMesh).size = Vector3(0.11, 0.045, 0.04)
	c1.rotation_degrees = Vector3(0, -18, 12)
	_head_group.add_child(c1)

	var c2 := _mesh(BoxMesh.new(), clip_r, Vector3(0.20, 0.20, 0.34))
	(c2.mesh as BoxMesh).size = Vector3(0.11, 0.045, 0.04)
	c2.rotation_degrees = Vector3(0, 18, -12)
	_head_group.add_child(c2)

	for side: float in [-1.0, 1.0]:
		var eye := _mesh(SphereMesh.new(), eye_mat, Vector3(side * 0.13, -0.01, 0.33))
		(eye.mesh as SphereMesh).radius = 0.048
		(eye.mesh as SphereMesh).height = 0.105
		_head_group.add_child(eye)

		var glint := _mesh(SphereMesh.new(), white, Vector3(side * 0.13 + 0.015, 0.015, 0.365))
		(glint.mesh as SphereMesh).radius = 0.016
		(glint.mesh as SphereMesh).height = 0.032
		_head_group.add_child(glint)


func _make_leg(x_off: float, skin: Material, sock_m: Material, shoe_m: Material) -> Node3D:
	var g := Node3D.new()
	g.position = Vector3(x_off, 0.52, 0)

	var limb := _mesh(CapsuleMesh.new(), skin, Vector3(0, -0.20, 0))
	(limb.mesh as CapsuleMesh).radius = 0.075
	(limb.mesh as CapsuleMesh).height = 0.34
	g.add_child(limb)

	var sock := _mesh(CylinderMesh.new(), sock_m, Vector3(0, -0.40, 0))
	(sock.mesh as CylinderMesh).top_radius = 0.08
	(sock.mesh as CylinderMesh).bottom_radius = 0.078
	(sock.mesh as CylinderMesh).height = 0.11
	g.add_child(sock)

	var shoe := _mesh(SphereMesh.new(), shoe_m, Vector3(0, -0.46, 0.04))
	(shoe.mesh as SphereMesh).radius = 0.105
	(shoe.mesh as SphereMesh).height = 0.16
	shoe.scale = Vector3(0.95, 0.78, 1.35)
	g.add_child(shoe)
	return g


func _make_arm(side: float, shirt: Material, skin: Material) -> Node3D:
	var g := Node3D.new()
	g.position = Vector3(side * 0.26, 1.08, 0)

	var sleeve := _mesh(SphereMesh.new(), shirt, Vector3.ZERO)
	(sleeve.mesh as SphereMesh).radius = 0.10
	(sleeve.mesh as SphereMesh).height = 0.20
	g.add_child(sleeve)

	var hand := _mesh(CapsuleMesh.new(), skin, Vector3(side * 0.04, -0.18, 0))
	(hand.mesh as CapsuleMesh).radius = 0.062
	(hand.mesh as CapsuleMesh).height = 0.28
	hand.rotation.z = side * 0.16
	g.add_child(hand)
	return g


func _mesh(m: Mesh, mat: Material, pos: Vector3) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = m
	mi.material_override = mat
	mi.position = pos
	return mi


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= _gravity * delta

	var input_dir := Vector3.ZERO
	if _knockback_timer > 0.0:
		_knockback_timer = maxf(0.0, _knockback_timer - delta)
		# Preserve parabolic knockback arc with gentle air drag so Nara truly flies back ("terpental!")
		velocity.x = move_toward(velocity.x, 0.0, 4.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, 4.5 * delta)
	elif not Game.modal_open and not _control_locked and not Game.voice_briefing_active:
		var ix := Input.get_axis("move_left", "move_right") + Game.virtual_move.x
		var iz := Input.get_axis("move_forward", "move_back") + Game.virtual_move.y
		var move_vec := Vector2(ix, iz)
		if move_vec.length() > 1.0:
			move_vec = move_vec.normalized()
		if move_vec.length() > 0.08:
			_auto_target = null
			var cam := get_viewport().get_camera_3d()
			if cam != null:
				var forward := -cam.global_transform.basis.z
				forward.y = 0.0
				forward = forward.normalized()
				var right := cam.global_transform.basis.x
				right.y = 0.0
				right = right.normalized()
				input_dir = (right * move_vec.x - forward * move_vec.y)
			else:
				input_dir = Vector3(move_vec.x, 0.0, move_vec.y)
		elif _auto_target is Vector3:
			var to_target: Vector3 = (_auto_target as Vector3) - global_position
			to_target.y = 0.0
			if to_target.length() < 0.75:
				_auto_target = null
			else:
				input_dir = to_target.normalized()

		if Input.is_action_just_pressed("jump") and is_on_floor():
			velocity.y = jump_velocity

	if _knockback_timer <= 0.0:
		if input_dir.length() > 0.05:
			velocity.x = input_dir.x * move_speed
			velocity.z = input_dir.z * move_speed
			var target_yaw := atan2(input_dir.x, input_dir.z)
			rotation.y = lerp_angle(rotation.y, target_yaw, turn_speed * delta)
		else:
			velocity.x = move_toward(velocity.x, 0.0, move_speed * 6.0 * delta)
			velocity.z = move_toward(velocity.z, 0.0, move_speed * 6.0 * delta)

	var prev_pos := global_position
	move_and_slide()
	if global_position.y < -3.0:
		global_position = Vector3(0.0, 0.4, 5.0)
		velocity = Vector3.ZERO

	# Detect when Nara is pushing against a wall / map boundary so she plays a cute "Mentok!" animation instead of freezing!
	var horiz_moved := Vector2(global_position.x - prev_pos.x, global_position.z - prev_pos.z).length()
	var expected_move := input_dir.length() * move_speed * delta
	_pushing_wall = (input_dir.length() > 0.25 and is_on_floor() and (is_on_wall() or (expected_move > 0.01 and horiz_moved < expected_move * 0.22)))
	if _wall_bonk_cd > 0.0:
		_wall_bonk_cd = maxf(0.0, _wall_bonk_cd - delta)
	if _pushing_wall and _wall_bonk_cd <= 0.0:
		_wall_bonk_cd = 1.6
		Audio.play_sfx("select")
		_show_wall_bubble("Batas Taman!")
	if _wall_bubble_timer > 0.0:
		_wall_bubble_timer = maxf(0.0, _wall_bubble_timer - delta)
		if _wall_bubble != null:
			_wall_bubble.position.y = 2.25 + sin(_walk_time * 8.0) * 0.05
			if _wall_bubble_timer <= 0.0:
				_wall_bubble.visible = false

	_animate_body(delta, Vector2(velocity.x, velocity.z).length() > 0.25)


func _show_wall_bubble(text: String) -> void:
	if _wall_bubble == null:
		_wall_bubble = Label3D.new()
		_wall_bubble.font_size = 38
		_wall_bubble.outline_size = 8
		_wall_bubble.modulate = Color(1.0, 0.96, 0.78)
		_wall_bubble.outline_modulate = Color(0.32, 0.16, 0.08)
		_wall_bubble.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		_wall_bubble.position = Vector3(0.0, 2.25, 0.0)
		add_child(_wall_bubble)
	_wall_bubble.text = text
	_wall_bubble.visible = true
	_wall_bubble_timer = 1.15


func _build_blob_shadow() -> void:
	_blob_shadow = MeshInstance3D.new()
	var quad := PlaneMesh.new()
	quad.size = Vector2(0.95, 0.95)
	_blob_shadow.mesh = quad
	_blob_shadow.position = Vector3(0.0, 0.055, 0.0)
	_blob_shadow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	var grad := GradientTexture2D.new()
	grad.fill = GradientTexture2D.FILL_RADIAL
	grad.fill_from = Vector2(0.5, 0.5)
	grad.fill_to = Vector2(0.5, 0.0)
	var g := Gradient.new()
	g.set_color(0, Color(0.14, 0.10, 0.18, 0.48))
	g.set_color(1, Color(0.14, 0.10, 0.18, 0.0))
	grad.gradient = g

	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_texture = grad
	mat.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
	_blob_shadow.material_override = mat
	add_child(_blob_shadow)


func _build_run_dust() -> void:
	_dust_particles = GPUParticles3D.new()
	_dust_particles.position = Vector3(0.0, 0.12, -0.2)
	_dust_particles.amount = 14
	_dust_particles.lifetime = 0.45
	_dust_particles.emitting = false

	var pm := ParticleProcessMaterial.new()
	pm.direction = Vector3(0.0, 1.0, -0.5)
	pm.spread = 35.0
	pm.initial_velocity_min = 0.4
	pm.initial_velocity_max = 1.1
	pm.gravity = Vector3(0.0, 0.4, 0.0)
	pm.scale_min = 0.08
	pm.scale_max = 0.18
	pm.color = Color(0.96, 0.93, 0.85, 0.65)
	_dust_particles.process_material = pm

	var puff := SphereMesh.new()
	puff.radius = 0.5
	puff.height = 1.0
	var pmat := StandardMaterial3D.new()
	pmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	pmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	pmat.albedo_color = Color(0.98, 0.95, 0.88, 0.65)
	puff.material = pmat
	_dust_particles.draw_pass_1 = puff
	add_child(_dust_particles)


func _animate_body(delta: float, moving: bool) -> void:
	_walk_time += delta
	if _blob_shadow != null:
		var lift := maxf(0.0, global_position.y)
		var sc := clampf(1.0 - lift * 0.18, 0.45, 1.0)
		_blob_shadow.scale = Vector3(sc, 1.0, sc)
		_blob_shadow.global_position.y = 0.055

	if _dust_particles != null:
		_dust_particles.emitting = moving and is_on_floor()

	if _emote_timer > 0.0:
		_emote_timer = maxf(0.0, _emote_timer - delta)
		_emote_t += delta
		if _emote_timer <= 0.0:
			_emote_name = ""

	if not _emote_name.is_empty() and (not moving or _emote_name == "knockback"):
		_left_leg.rotation.x = lerpf(_left_leg.rotation.x, 0.0, 10.0 * delta)
		_right_leg.rotation.x = lerpf(_right_leg.rotation.x, 0.0, 10.0 * delta)
		match _emote_name:
			"stop":
				# Right arm raised straight forward in clear STOP gesture, gentle steady stance
				_right_arm.rotation.x = lerpf(_right_arm.rotation.x, -1.45, 12.0 * delta)
				_right_arm.rotation.z = lerpf(_right_arm.rotation.z, 0.15, 12.0 * delta)
				_left_arm.rotation.x = lerpf(_left_arm.rotation.x, 0.12, 10.0 * delta)
				_left_arm.rotation.z = lerpf(_left_arm.rotation.z, -0.15, 10.0 * delta)
				_body_pivot.rotation.x = lerpf(_body_pivot.rotation.x, 0.0, 10.0 * delta)
				_body_pivot.position.y = sin(_emote_t * 3.0) * 0.02
			"hold_back":
				# Calm self-control pose: both hands clasped neatly in front of chest + slow calm head shake ("no hitting!")
				_left_arm.rotation.x = lerpf(_left_arm.rotation.x, -0.78, 10.0 * delta)
				_right_arm.rotation.x = lerpf(_right_arm.rotation.x, -0.78, 10.0 * delta)
				_left_arm.rotation.z = lerpf(_left_arm.rotation.z, 0.32, 10.0 * delta)
				_right_arm.rotation.z = lerpf(_right_arm.rotation.z, -0.32, 10.0 * delta)
				_head_group.rotation.y = sin(_emote_t * 5.2) * 0.18
				_body_pivot.position.y = sin(_emote_t * 2.5) * 0.015
			"inhale":
				# Deep breath in: body rises & arms open softly outward
				_left_arm.rotation.z = lerpf(_left_arm.rotation.z, -0.75, 8.0 * delta)
				_right_arm.rotation.z = lerpf(_right_arm.rotation.z, 0.75, 8.0 * delta)
				_left_arm.rotation.x = lerpf(_left_arm.rotation.x, -0.25, 8.0 * delta)
				_right_arm.rotation.x = lerpf(_right_arm.rotation.x, -0.25, 8.0 * delta)
				_body_pivot.position.y = lerpf(_body_pivot.position.y, 0.10, 6.0 * delta)
				_head_group.rotation.x = lerpf(_head_group.rotation.x, -0.18, 6.0 * delta)
			"blow":
				# Blowing wind forward toward the windmill!
				_body_pivot.rotation.x = lerpf(_body_pivot.rotation.x, 0.16, 12.0 * delta)
				_left_arm.rotation.x = lerpf(_left_arm.rotation.x, -0.45, 12.0 * delta)
				_right_arm.rotation.x = lerpf(_right_arm.rotation.x, -0.45, 12.0 * delta)
				_left_arm.rotation.z = lerpf(_left_arm.rotation.z, -0.35, 12.0 * delta)
				_right_arm.rotation.z = lerpf(_right_arm.rotation.z, 0.35, 12.0 * delta)
				_head_group.rotation.x = lerpf(_head_group.rotation.x, 0.10, 10.0 * delta)
			"pet_cat":
				# Gentle, cozy forward lean + slow affectionate petting stroke toward the cat's head!
				_body_pivot.rotation.x = lerpf(_body_pivot.rotation.x, 0.18, 8.0 * delta)
				_right_arm.rotation.x = lerpf(_right_arm.rotation.x, -0.82 + sin(_emote_t * 4.2) * 0.16, 10.0 * delta)
				_right_arm.rotation.z = lerpf(_right_arm.rotation.z, -0.18, 8.0 * delta)
				_left_arm.rotation.x = lerpf(_left_arm.rotation.x, -0.18, 8.0 * delta)
				_left_arm.rotation.z = lerpf(_left_arm.rotation.z, 0.08, 8.0 * delta)
				_head_group.rotation.x = lerpf(_head_group.rotation.x, 0.18, 8.0 * delta)
				_head_group.rotation.z = sin(_emote_t * 2.4) * 0.08
			"ring_bell":
				# Reaching right arm up to pull the golden bell rope!
				_right_arm.rotation.x = -2.35 + sin(_emote_t * 10.0) * 0.45
				_right_arm.rotation.z = lerpf(_right_arm.rotation.z, 0.25, 10.0 * delta)
				_body_pivot.position.y = absf(sin(_emote_t * 5.0)) * 0.08
			"celebrate":
				# Joyful victory jump + both arms waving high overhead!
				_body_pivot.position.y = absf(sin(_emote_t * 7.5)) * 0.22
				_left_arm.rotation.z = -2.35 - sin(_emote_t * 12.0) * 0.30
				_right_arm.rotation.z = 2.35 + sin(_emote_t * 12.0) * 0.30
				_left_arm.rotation.x = -0.25
				_right_arm.rotation.x = -0.25
				_head_group.rotation.z = sin(_emote_t * 7.5) * 0.15
			"lift_trophy":
				# Heroic 3D Trophy Lift: both arms raised straight up gripping the Golden Trophy overhead,
				# rhythmic triumphant hops, joyful heel kicks, and proud beaming tilt!
				var hop := absf(sin(_emote_t * 6.8))
				var pulse := sin(_emote_t * 6.8)
				_body_pivot.position.y = hop * 0.26
				_body_pivot.rotation.x = lerpf(_body_pivot.rotation.x, -0.06, 10.0 * delta)
				_left_arm.rotation.x = lerpf(_left_arm.rotation.x, -2.86 - hop * 0.08, 14.0 * delta)
				_right_arm.rotation.x = lerpf(_right_arm.rotation.x, -2.86 - hop * 0.08, 14.0 * delta)
				_left_arm.rotation.z = lerpf(_left_arm.rotation.z, 0.22, 14.0 * delta)
				_right_arm.rotation.z = lerpf(_right_arm.rotation.z, -0.22, 14.0 * delta)
				_left_leg.rotation.x = lerpf(_left_leg.rotation.x, pulse * 0.34, 14.0 * delta)
				_right_leg.rotation.x = lerpf(_right_leg.rotation.x, -pulse * 0.34, 14.0 * delta)
				_head_group.rotation.x = lerpf(_head_group.rotation.x, -0.14, 10.0 * delta)
				_head_group.rotation.z = sin(_emote_t * 6.8) * 0.12
			"splash":
				# Funny kecemplung flailing animation in water!
				_body_pivot.position.y = -0.32 + sin(_emote_t * 14.0) * 0.08
				_left_arm.rotation.z = -2.1 + sin(_emote_t * 22.0) * 0.55
				_right_arm.rotation.z = 2.1 - sin(_emote_t * 22.0) * 0.55
				_left_arm.rotation.x = -0.45
				_right_arm.rotation.x = -0.45
				_left_leg.rotation.x = sin(_emote_t * 20.0) * 0.75
				_right_leg.rotation.x = -sin(_emote_t * 20.0) * 0.75
				_head_group.rotation.z = sin(_emote_t * 16.0) * 0.22
			"punch_pillow":
				# Playful bouncy 1-2 soft punch into the giant cloud pillow!
				var beat := sin(_emote_t * 18.0)
				_body_pivot.rotation.x = lerpf(_body_pivot.rotation.x, 0.20, 14.0 * delta)
				_body_pivot.position.y = absf(beat) * 0.09
				_right_arm.rotation.x = -1.45 - maxf(0.0, beat) * 0.45
				_left_arm.rotation.x = -1.45 - maxf(0.0, -beat) * 0.45
				_right_arm.rotation.z = 0.14
				_left_arm.rotation.z = -0.14
				_head_group.rotation.x = 0.10
			"rip_paper":
				# Expressive paper ripping & crumpling motion (hands pull apart then squeeze together)
				var rip_p := sin(_emote_t * 12.0)
				_body_pivot.rotation.x = lerpf(_body_pivot.rotation.x, 0.14, 12.0 * delta)
				_body_pivot.position.y = absf(rip_p) * 0.04
				_left_arm.rotation.x = -1.05
				_right_arm.rotation.x = -1.05
				_left_arm.rotation.z = -0.45 - rip_p * 0.35
				_right_arm.rotation.z = 0.45 + rip_p * 0.35
				_head_group.rotation.z = rip_p * 0.10
			"surprised":
				# Startled bounce-back pose: both arms thrown up, slight backward lean
				_body_pivot.rotation.x = lerpf(_body_pivot.rotation.x, -0.22, 16.0 * delta)
				_left_arm.rotation.z = lerpf(_left_arm.rotation.z, -2.2, 16.0 * delta)
				_right_arm.rotation.z = lerpf(_right_arm.rotation.z, 2.2, 16.0 * delta)
				_left_arm.rotation.x = lerpf(_left_arm.rotation.x, -0.35, 14.0 * delta)
				_right_arm.rotation.x = lerpf(_right_arm.rotation.x, -0.35, 14.0 * delta)
				_head_group.rotation.x = lerpf(_head_group.rotation.x, -0.15, 14.0 * delta)
			"knockback":
				# Hilarious cartoony "TERPENTAL!" flying tumble: tilted back, arms & legs flailing, head dizzy!
				_body_pivot.rotation.x = lerpf(_body_pivot.rotation.x, -0.68 + sin(_emote_t * 18.0) * 0.16, 16.0 * delta)
				_left_arm.rotation.z = -2.45 + sin(_emote_t * 26.0) * 0.50
				_right_arm.rotation.z = 2.45 - sin(_emote_t * 26.0) * 0.50
				_left_arm.rotation.x = -0.65
				_right_arm.rotation.x = -0.65
				_left_leg.rotation.x = -0.75 + sin(_emote_t * 24.0) * 0.45
				_right_leg.rotation.x = -0.75 - sin(_emote_t * 24.0) * 0.45
				_head_group.rotation.z = sin(_emote_t * 22.0) * 0.28
				_head_group.rotation.x = -0.22
		return

	# Reset emote tilt cleanly when moving or back to normal idle
	_body_pivot.rotation.x = lerpf(_body_pivot.rotation.x, 0.0, 10.0 * delta)
	_head_group.rotation.x = lerpf(_head_group.rotation.x, 0.0, 10.0 * delta)
	_head_group.rotation.y = lerpf(_head_group.rotation.y, 0.0, 10.0 * delta)
	_head_group.rotation.z = lerpf(_head_group.rotation.z, 0.0, 10.0 * delta)
	_left_arm.rotation.z = lerpf(_left_arm.rotation.z, 0.0, 10.0 * delta)
	_right_arm.rotation.z = lerpf(_right_arm.rotation.z, 0.0, 10.0 * delta)

	if _pushing_wall and _emote_name.is_empty():
		# Cute lively "Mentok / pushing boundary" animation (arms pushing forward, little steps, head shake)
		var p := _walk_time * 9.0
		_body_pivot.rotation.x = lerpf(_body_pivot.rotation.x, 0.18, 12.0 * delta)
		_body_pivot.position.y = absf(sin(p)) * 0.045
		_left_arm.rotation.x = lerpf(_left_arm.rotation.x, -1.25 + sin(p) * 0.14, 14.0 * delta)
		_right_arm.rotation.x = lerpf(_right_arm.rotation.x, -1.25 - sin(p) * 0.14, 14.0 * delta)
		_left_arm.rotation.z = lerpf(_left_arm.rotation.z, 0.12, 12.0 * delta)
		_right_arm.rotation.z = lerpf(_right_arm.rotation.z, -0.12, 12.0 * delta)
		_left_leg.rotation.x = sin(p) * 0.36
		_right_leg.rotation.x = -sin(p) * 0.36
		_head_group.rotation.y = sin(_walk_time * 6.5) * 0.20
		_head_group.rotation.z = sin(p * 0.5) * 0.08
		return

	if moving:
		var w := _walk_time * 10.5
		_left_leg.rotation.x = sin(w) * 0.55
		_right_leg.rotation.x = -sin(w) * 0.55
		if _holding_trophy:
			_left_arm.rotation.x = lerpf(_left_arm.rotation.x, -2.82, 14.0 * delta)
			_right_arm.rotation.x = lerpf(_right_arm.rotation.x, -2.82, 14.0 * delta)
			_left_arm.rotation.z = lerpf(_left_arm.rotation.z, 0.22, 14.0 * delta)
			_right_arm.rotation.z = lerpf(_right_arm.rotation.z, -0.22, 14.0 * delta)
		elif _carrying:
			_left_arm.rotation.x = lerpf(_left_arm.rotation.x, -1.08, 14.0 * delta)
			_right_arm.rotation.x = lerpf(_right_arm.rotation.x, -1.08, 14.0 * delta)
			_left_arm.rotation.z = lerpf(_left_arm.rotation.z, 0.28, 14.0 * delta)
			_right_arm.rotation.z = lerpf(_right_arm.rotation.z, -0.28, 14.0 * delta)
		else:
			_left_arm.rotation.x = -sin(w) * 0.45
			_right_arm.rotation.x = sin(w) * 0.45
		_body_pivot.position.y = absf(sin(w)) * 0.07
		if is_on_floor():
			_step_accum += delta
			if _step_accum >= 0.38:
				_step_accum = 0.0
				Audio.play_sfx("step")
	else:
		_step_accum = 0.2
		_left_leg.rotation.x = lerpf(_left_leg.rotation.x, 0.0, 10.0 * delta)
		_right_leg.rotation.x = lerpf(_right_leg.rotation.x, 0.0, 10.0 * delta)
		if _holding_trophy:
			_left_arm.rotation.x = lerpf(_left_arm.rotation.x, -2.82, 12.0 * delta)
			_right_arm.rotation.x = lerpf(_right_arm.rotation.x, -2.82, 12.0 * delta)
			_left_arm.rotation.z = lerpf(_left_arm.rotation.z, 0.22, 12.0 * delta)
			_right_arm.rotation.z = lerpf(_right_arm.rotation.z, -0.22, 12.0 * delta)
			_body_pivot.position.y = absf(sin(_walk_time * 3.4)) * 0.05
		elif _carrying:
			_left_arm.rotation.x = lerpf(_left_arm.rotation.x, -1.08, 12.0 * delta)
			_right_arm.rotation.x = lerpf(_right_arm.rotation.x, -1.08, 12.0 * delta)
			_left_arm.rotation.z = lerpf(_left_arm.rotation.z, 0.28, 12.0 * delta)
			_right_arm.rotation.z = lerpf(_right_arm.rotation.z, -0.28, 12.0 * delta)
			_body_pivot.position.y = sin(_walk_time * 2.2) * 0.02
		else:
			_left_arm.rotation.x = lerpf(_left_arm.rotation.x, 0.0, 10.0 * delta)
			_right_arm.rotation.x = lerpf(_right_arm.rotation.x, 0.0, 10.0 * delta)
			_body_pivot.position.y = sin(_walk_time * 2.2) * 0.02
