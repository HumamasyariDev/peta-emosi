class_name TouchControls
extends Control

## Storybook-styled Virtual Analog Joystick + Action Buttons (LOMPAT & AKSI)
## Automatically enabled on Android / mobile touchscreens, and toggleable anytime from HUD.

signal interact_tapped

const BASE_RADIUS := 66.0
const KNOB_RADIUS := 28.0
const MAX_PULL := 46.0

var _font_display: Font
var _joy_area: Control
var _jump_btn: Button
var _action_btn: Button

var _joy_touch_idx: int = -1
var _joy_mouse_active: bool = false
var _joy_offset: Vector2 = Vector2.ZERO
var _action_highlighted: bool = false
var _pulse_t: float = 0.0


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_font_display = StorybookUI.font_display()
	_build_ui()
	_sync_visibility()


func set_interact_highlighted(active: bool, label_text: String = "") -> void:
	_action_highlighted = active
	if _action_btn != null:
		if active and not label_text.is_empty():
			_action_btn.text = "AKSI"
		else:
			_action_btn.text = "AKSI"
		_style_round_button(
			_action_btn,
			Color("2d8647") if active else Color("961d2d"),
			Color("ffd23f") if active else Color("61101b"),
			Color("fff8eb")
		)


func _process(delta: float) -> void:
	var should_show := Game.touch_controls_enabled and not Game.modal_open
	if visible != should_show:
		visible = should_show
		if should_show and _joy_area != null:
			_joy_area.queue_redraw()
		elif not should_show:
			_reset_joystick()
	if not visible:
		return
	if _action_highlighted and _action_btn != null:
		_pulse_t += delta * 5.0
		var s := 1.0 + sin(_pulse_t) * 0.06
		_action_btn.pivot_offset = _action_btn.size * 0.5
		_action_btn.scale = Vector2(s, s)
	elif _action_btn != null:
		_action_btn.scale = Vector2.ONE


func _sync_visibility() -> void:
	visible = Game.touch_controls_enabled and not Game.modal_open


func _exit_tree() -> void:
	_reset_joystick()


func _reset_joystick() -> void:
	_joy_touch_idx = -1
	Game.joystick_touch_index = -1
	_joy_mouse_active = false
	_joy_offset = Vector2.ZERO
	Game.virtual_move = Vector2.ZERO
	if _joy_area != null:
		_joy_area.queue_redraw()


func _build_ui() -> void:
	# Bottom-Left Analog Joystick Container (positioned cleanly ABOVE the bottom HUD bar!)
	_joy_area = Control.new()
	_joy_area.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	_joy_area.offset_left = 30.0
	_joy_area.offset_bottom = -84.0
	_joy_area.offset_right = 30.0 + BASE_RADIUS * 2.0 + 18.0
	_joy_area.offset_top = -84.0 - (BASE_RADIUS * 2.0 + 18.0)
	_joy_area.mouse_filter = Control.MOUSE_FILTER_STOP
	_joy_area.draw.connect(_draw_joystick)
	_joy_area.gui_input.connect(_on_joy_gui_input)
	add_child(_joy_area)

	# Bottom-Right Action Buttons Container (positioned cleanly ABOVE Peta Pos / Paspor Emosi!)
	var right_box := HBoxContainer.new()
	right_box.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	right_box.offset_right = -30.0
	right_box.offset_bottom = -86.0
	right_box.offset_left = -232.0
	right_box.offset_top = -182.0
	right_box.alignment = BoxContainer.ALIGNMENT_END
	right_box.add_theme_constant_override("separation", 16)
	right_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(right_box)

	# AKSI (E) button
	_action_btn = Button.new()
	_action_btn.text = "AKSI"
	_action_btn.custom_minimum_size = Vector2(88, 88)
	_action_btn.focus_mode = Control.FOCUS_NONE
	_action_btn.add_theme_font_size_override("font_size", 18)
	if _font_display != null:
		_action_btn.add_theme_font_override("font", _font_display)
	_style_round_button(_action_btn, Color("961d2d"), Color("61101b"), Color("fff8eb"))
	_action_btn.button_down.connect(_on_action_down)
	_action_btn.button_up.connect(_on_action_up)
	right_box.add_child(_action_btn)

	# LOMPAT (Space) button
	_jump_btn = Button.new()
	_jump_btn.text = "LOMPAT"
	_jump_btn.custom_minimum_size = Vector2(92, 92)
	_jump_btn.focus_mode = Control.FOCUS_NONE
	_jump_btn.add_theme_font_size_override("font_size", 16)
	if _font_display != null:
		_jump_btn.add_theme_font_override("font", _font_display)
	_style_round_button(_jump_btn, Color("d49826"), Color("6b3d1b"), Color("fffdf6"))
	_jump_btn.button_down.connect(_on_jump_down)
	_jump_btn.button_up.connect(_on_jump_up)
	right_box.add_child(_jump_btn)


func _style_round_button(btn: Button, bg: Color, border: Color, txt: Color) -> void:
	for state: String in ["normal", "hover", "pressed"]:
		var st := StyleBoxFlat.new()
		st.bg_color = bg.darkened(0.14) if state == "pressed" else (bg.lightened(0.08) if state == "hover" else Color(bg.r, bg.g, bg.b, 0.92))
		st.border_color = border
		st.set_border_width_all(4)
		st.set_corner_radius_all(48)
		st.shadow_color = Color(0.16, 0.08, 0.04, 0.32)
		st.shadow_size = 5
		st.shadow_offset = Vector2(0, 3)
		btn.add_theme_stylebox_override(state, st)
	btn.add_theme_color_override("font_color", txt)
	btn.add_theme_color_override("font_hover_color", txt)
	btn.add_theme_color_override("font_pressed_color", txt)


func _draw_joystick() -> void:
	var c := _joy_area.size * 0.5
	# Soft outer shadow
	_joy_area.draw_circle(c + Vector2(0, 4), BASE_RADIUS + 4.0, Color(0.18, 0.10, 0.05, 0.34))
	# Warm parchment base (clearly visible on both grass & cobblestone)
	_joy_area.draw_circle(c, BASE_RADIUS, Color(0.99, 0.96, 0.88, 0.78))
	# Brass gold ring border
	_joy_area.draw_arc(c, BASE_RADIUS, 0.0, TAU, 48, Color(0.83, 0.58, 0.12, 0.98), 4.5, true)
	# Subtle inner guide ring
	_joy_area.draw_arc(c, BASE_RADIUS * 0.55, 0.0, TAU, 32, Color(0.56, 0.34, 0.16, 0.38), 2.0, true)

	# Directional indicator dots (N, S, E, W)
	for dir: Vector2 in [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]:
		_joy_area.draw_circle(c + dir * (BASE_RADIUS - 13.0), 3.6, Color(0.45, 0.26, 0.12, 0.52))

	# Tactile wooden/gold thumb knob
	var knob_pos := c + _joy_offset
	_joy_area.draw_circle(knob_pos + Vector2(0, 3), KNOB_RADIUS, Color(0.18, 0.09, 0.04, 0.30))
	_joy_area.draw_circle(knob_pos, KNOB_RADIUS, Color(0.96, 0.72, 0.20, 0.95))
	_joy_area.draw_arc(knob_pos, KNOB_RADIUS, 0.0, TAU, 36, Color(0.42, 0.22, 0.09, 0.95), 3.5, true)
	_joy_area.draw_circle(knob_pos - Vector2(6, 7), 7.5, Color(1.0, 0.97, 0.86, 0.45))


func _on_joy_gui_input(event: InputEvent) -> void:
	if not visible or Game.modal_open:
		return
	var center := _joy_area.size * 0.5
	if event is InputEventScreenTouch:
		var st := event as InputEventScreenTouch
		if st.pressed and _joy_touch_idx == -1:
			_joy_touch_idx = st.index
			Game.joystick_touch_index = st.index
			_update_joystick(st.position - center)
			_joy_area.accept_event()
		elif not st.pressed and st.index == _joy_touch_idx:
			_reset_joystick()
			_joy_area.accept_event()
	elif event is InputEventScreenDrag:
		var sd := event as InputEventScreenDrag
		if sd.index == _joy_touch_idx:
			_update_joystick(sd.position - center)
			_joy_area.accept_event()
	elif not Game.is_mobile_browser and _joy_touch_idx == -1:
		# Desktop mouse test fallback only (never mix emulated mouse events with mobile multi-touch!)
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
			var mb := event as InputEventMouseButton
			if mb.pressed:
				_joy_mouse_active = true
				_update_joystick(mb.position - center)
				_joy_area.accept_event()
			else:
				_reset_joystick()
				_joy_area.accept_event()
		elif event is InputEventMouseMotion and _joy_mouse_active:
			var mm := event as InputEventMouseMotion
			_update_joystick(mm.position - center)
			_joy_area.accept_event()


func _update_joystick(delta_pos: Vector2) -> void:
	if delta_pos.length() > MAX_PULL:
		delta_pos = delta_pos.normalized() * MAX_PULL
	_joy_offset = delta_pos
	var norm := delta_pos / MAX_PULL
	if norm.length() < 0.10:
		Game.virtual_move = Vector2.ZERO
	else:
		# Note: in nara_controller, move_forward is -1 on Z axis, move_back is +1
		Game.virtual_move = Vector2(norm.x, norm.y)
	_joy_area.queue_redraw()


func _on_jump_down() -> void:
	if Game.modal_open:
		return
	var ev := InputEventAction.new()
	ev.action = "jump"
	ev.pressed = true
	Input.parse_input_event(ev)


func _on_jump_up() -> void:
	var ev := InputEventAction.new()
	ev.action = "jump"
	ev.pressed = false
	Input.parse_input_event(ev)


func _on_action_down() -> void:
	if Game.modal_open:
		return
	interact_tapped.emit()
	var ev := InputEventAction.new()
	ev.action = "interact"
	ev.pressed = true
	Input.parse_input_event(ev)


func _on_action_up() -> void:
	var ev := InputEventAction.new()
	ev.action = "interact"
	ev.pressed = false
	Input.parse_input_event(ev)

