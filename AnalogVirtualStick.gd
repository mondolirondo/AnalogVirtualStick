tool
extends Node2D

signal activated
signal deactivated
signal active_changed

# The texture of the pad area
export(Texture) var pad : Texture = null setget set_pad
# The texture of the stick
export(Texture) var stick : Texture = null setget set_stick
# The size of the pad area. When a texture is set for the pad area this property will be updated
# to match the size of the texture since that is the desired behavior most of the time 
export(Vector2) var input_radius : Vector2 = Vector2(50,50) setget set_input_radius
# Is the pad fixed on screen or can be dragged around?
export(bool) var draggable_pad : bool = true
# Set to true to make the virtual stick hide automatically when not in use
export(bool) var auto_hide : bool = true
# Set enabled to true if you want to capture user input, otherwise set it to false
export(bool) var enabled : bool = true
# Emulate left or right stick. Affects to the property 'axis' of the generated input events.
export(int, "LEFT", "RIGHT") var stick_side : int = 0;
# Device numeric identifier. Affects to the property 'device' of the generated input events.
export(int) var _virtual_device_id : int = randi() #999
var stick_axis = [
	[JOY_AXIS_0, JOY_AXIS_1], # Gamepad left stick horizontal, vertica axis
	[JOY_AXIS_2, JOY_AXIS_3]  # Gamepad right stick horizontal, vertica axis
]
# Current stick axis position
var stick_input : Vector2 = Vector2.ZERO
# Is it being used right now?
var active : bool = false setget set_active

var pad_sprite = Sprite.new()
var stick_sprite = Sprite.new()

func _init() -> void:
	if pad_sprite.get_parent() != self:
		add_child(pad_sprite)
	if stick_sprite.get_parent() != pad_sprite:
		pad_sprite.add_child(stick_sprite)
		
func _draw() -> void:
	pad_sprite.texture = pad
	stick_sprite.texture = stick

func _ready() -> void:
	if auto_hide and not Engine.is_editor_hint():
		visible = false
	update()
	
func set_active(value: bool) -> void:
	if active != value:
		active = value
		emit_signal("active_changed", active)
		if active:
			emit_signal("activated") 
		else:
			emit_signal("deactivated")
	
func set_pad(value: Texture) -> void:
	pad = value
	if is_instance_valid(pad):
		set_input_radius(0.5 * pad.get_size())
		if Engine.is_editor_hint():
			property_list_changed_notify()
	update()
	
func set_stick(value: Texture) -> void:	
	stick = value
	update()

func set_input_radius(value: Vector2) -> void:
	input_radius.x = max(value.x, 1)
	input_radius.y = max(value.y, 1)
	update()

func _input(event: InputEvent) -> void:
	if not enabled:
		return
	if event is InputEventScreenDrag or (event is InputEventScreenTouch and event.is_pressed()):
		var event_position = event.position
		if not active and draggable_pad:
			global_position = event_position
		active = true
		var offset = event_position - global_position
		var scaled_radius = input_radius * global_scale
		stick_input = offset / scaled_radius
		if stick_input.length() > 1:
			stick_input = stick_input.normalized()
			if draggable_pad:
				global_position = event_position - stick_input * scaled_radius
		stick_sprite.position = stick_input * input_radius
		#print(stick_input)
	if event is InputEventScreenTouch and not event.is_pressed():
		active = false
		stick_input = Vector2.ZERO
		stick_sprite.position = stick_input
	if event is InputEventScreenDrag or event is InputEventScreenTouch:
		_emit_event(stick_axis[stick_side][0], stick_input.x) # horizontal axis
		_emit_event(stick_axis[stick_side][1], stick_input.y) # vertical axis
	if auto_hide:
		visible = active

func _emit_event(axis, axis_value) -> void:
	var ev = InputEventJoypadMotion.new()
	ev.device = _virtual_device_id
	ev.axis = axis
	ev.axis_value = axis_value
	Input.parse_input_event(ev)
