class_name FollowCamera
extends Camera3D

@export var target_path: NodePath
@export var distance: float = 7.2
@export var height: float = 2.6
@export var pitch_deg: float = -16.0
@export var smooth_speed: float = 7.5

var yaw: float = 0.0
var _dragging: bool = false
var _touch_cam_idx: int = -1
var _target: Node3D
var _snapped_initial: bool = false


func _ready() -> void:
	if not target_path.is_empty():
		_target = get_node_or_null(target_path) as Node3D
	current = true


func set_target(node: Node3D) -> void:
	_target = node
	_snapped_initial = false


func _unhandled_input(event: InputEvent) -> void:
	if Game.modal_open:
		_dragging = false
		_touch_cam_idx = -1
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT:
		_dragging = event.pressed
	elif event is InputEventMouseMotion and _dragging:
		yaw -= event.relative.x * 0.0055
	elif event is InputEventScreenTouch:
		var st := event as InputEventScreenTouch
		if st.index == Game.joystick_touch_index:
			return
		if st.pressed and _touch_cam_idx == -1:
			# Strictly use the right open viewport half for camera rotation so left thumb analog never conflicts
			var vp_size := get_viewport().get_visible_rect().size
			if st.position.y < vp_size.y * 0.72 and st.position.x > vp_size.x * 0.42:
				_touch_cam_idx = st.index
		elif not st.pressed and st.index == _touch_cam_idx:
			_touch_cam_idx = -1
	elif event is InputEventScreenDrag:
		var sd := event as InputEventScreenDrag
		if sd.index == _touch_cam_idx and sd.index != Game.joystick_touch_index:
			var dx := clampf(sd.relative.x, -40.0, 40.0)
			yaw -= dx * 0.0055


func _compute_safe_camera_pos(pivot: Vector3) -> Vector3:
	var offset := Vector3(sin(yaw) * distance, height, cos(yaw) * distance)
	var desired := _target.global_position + offset

	# Dual-ray anti-occlusion: keeps the camera STRICTLY inside walls & wooden back gates!
	# Never clamps safe_dist beyond hit_dist (which previously pushed the lens behind closed gates).
	var space := get_world_3d().direct_space_state
	if space != null:
		var to_cam := desired - pivot
		var full_dist := to_cam.length()
		if full_dist > 0.05:
			var dir := to_cam / full_dist
			var min_hit := full_dist
			var hit_found := false

			# Check both torso-height pivot and elevated beam-height pivot so high arch beams never block view
			for ray_origin: Vector3 in [pivot, pivot + Vector3(0.0, 0.85, 0.0)]:
				var ray_end := ray_origin + dir * full_dist
				var query := PhysicsRayQueryParameters3D.create(ray_origin, ray_end, 1)
				var hit := space.intersect_ray(query)
				if not hit.is_empty():
					var d := ray_origin.distance_to(hit["position"] as Vector3)
					if d < min_hit:
						min_hit = d
						hit_found = true

			if hit_found:
				# Stay strictly in front of the blocking wall/gate with a 0.45m margin
				var safe_dist := maxf(0.55, min_hit - 0.45)
				var squeeze := clampf(1.0 - (safe_dist / full_dist), 0.0, 1.0)
				# Gently raise camera height when close to a rear wall so Nara & the arena ahead stay well-framed
				desired = pivot + dir * safe_dist + Vector3(0.0, squeeze * 0.85, 0.0)
	return desired


func _physics_process(delta: float) -> void:
	if _target == null or Game.modal_open:
		return
	if Input.is_key_pressed(KEY_Q):
		yaw += 1.4 * delta
	elif Input.is_key_pressed(KEY_R):
		yaw -= 1.4 * delta

	var pivot := _target.global_position + Vector3(0.0, 1.15, 0.0)
	var desired := _compute_safe_camera_pos(pivot)

	if not _snapped_initial:
		global_position = desired
		_snapped_initial = true
	else:
		global_position = global_position.lerp(desired, clampf(smooth_speed * delta, 0.0, 1.0))

	if global_position.distance_squared_to(pivot) > 0.01:
		look_at(pivot, Vector3.UP)
