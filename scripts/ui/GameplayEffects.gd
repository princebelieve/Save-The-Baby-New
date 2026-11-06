extends CanvasLayer
class_name GameplayEffects

signal collections_finished

func notice(caption: String, font: Font) -> void:
	if is_instance_valid(_feedback): _feedback.queue_free()
	var panel := PanelContainer.new()
	_feedback = panel
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var viewport_size := get_viewport().get_visible_rect().size
	var width := minf(620, viewport_size.x - 40)
	panel.custom_minimum_size = Vector2(width, 92)
	panel.position = Vector2((viewport_size.x - width) * 0.5, viewport_size.y * 0.46)
	panel.add_theme_stylebox_override("panel", MobileGameUI.style(Color("#26394f")))
	add_child(panel)
	var label := MobileGameUI.label(panel, caption, 34, Color.WHITE)
	label.add_theme_font_override("font", font)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var tween := _effect_tween().bind_node(panel)
	tween.tween_interval(1.25)
	tween.tween_property(panel, "modulate:a", 0.0, 0.25)
	tween.tween_callback(panel.queue_free)

var pending_collections := 0
var _pulse_tweens: Dictionary = {}
var _feedback: Control
var _active_tweens: Array[Tween] = []
var _pulse_targets: Dictionary = {}
var _cutout_material: ShaderMaterial
var _last_haptic_tick := -10000


class Burst extends Node2D:
	var progress := 0.0
	var radius := 80.0
	var tint := Color("#ffd45b")
	func advance(value: float) -> void:
		progress = value
		queue_redraw()
	func _draw() -> void:
		var fade := 1.0 - progress
		draw_circle(Vector2.ZERO, radius * 0.22 * (1.0 - progress * 0.45), Color(1.0,0.96,0.76,fade * 0.85))
		draw_arc(Vector2.ZERO, maxf(1, radius * progress), 0, TAU, 48, Color(tint, fade * 0.9), 6.0 * fade + 1.0, true)
		draw_arc(Vector2.ZERO, maxf(1, radius * progress * 0.64), 0, TAU, 40, Color.WHITE * Color(1,1,1,fade * 0.7), 2.0 * fade + 1.0, true)
		for index in 16:
			var direction := Vector2.from_angle(index * TAU / 16.0)
			var at := direction * radius * progress
			draw_line(at * 0.58, at, Color(tint, fade), 5.0 * fade + 1.0, true)
			draw_circle(at, 5.0 * fade, Color.WHITE * Color(1,1,1,fade))


class RocketShot extends Node2D:
	func _draw() -> void:
		draw_line(Vector2(-25,0),Vector2(-5,0),Color(1.0,0.35,0.05,0.8),7.0,true)
		draw_colored_polygon(PackedVector2Array([Vector2(17,0),Vector2(-8,-7),Vector2(-8,7)]),Color("#fff4cc"))
		draw_colored_polygon(PackedVector2Array([Vector2(-4,-6),Vector2(-13,-12),Vector2(-11,-3)]),Color("#43c3ec"))
		draw_colored_polygon(PackedVector2Array([Vector2(-4,6),Vector2(-13,12),Vector2(-11,3)]),Color("#43c3ec"))
		draw_circle(Vector2(-7,0),3.5,Color("#ff802d"))


class Flight extends TextureRect:
	var trail: Array[Vector2] = []
	func travel(point: Vector2) -> void:
		trail.append(point + size * 0.5)
		if trail.size() > 8: trail.pop_front()
		position = point
		queue_redraw()
	func _draw() -> void:
		for index in trail.size():
			var weight := float(index + 1) / trail.size()
			draw_circle(trail[index] - position, weight * 5.0, Color(1.0,0.82,0.25,weight*0.7))


func _ready() -> void:
	layer = 8
	name = "GameplayEffects"
	var shader := Shader.new()
	shader.code = "shader_type canvas_item; varying vec4 object_tint; void vertex(){object_tint=COLOR;} void fragment(){vec4 c=texture(TEXTURE,UV); c.a*=smoothstep(0.025,0.12,max(c.r,max(c.g,c.b))); COLOR=c*object_tint;}"
	_cutout_material = ShaderMaterial.new()
	_cutout_material.shader = shader


func clear() -> void:
	for tween in _active_tweens.duplicate():
		if tween.is_running(): tween.kill()
	_active_tweens.clear()
	for reference in _pulse_targets.values():
		var control: Control = reference.get_ref()
		if is_instance_valid(control): control.scale = Vector2.ONE
	_pulse_targets.clear()
	for child in get_children(): child.queue_free()
	for tween in _pulse_tweens.values():
		if tween.is_running(): tween.kill()
	_pulse_tweens.clear()
	pending_collections = 0
	_feedback = null


func collect(texture: Texture2D, origins: Array[Vector2], target: Control, value_per_piece: int = 1, arrival_sound: String = "") -> void:
	if not is_instance_valid(target) or texture == null: return
	var count := mini(origins.size(), maxi(0, 48 - pending_collections))
	if count == 0: return
	var group_left := [count]
	for index in count:
		var token := Flight.new()
		token.name = "CollectedObjective"
		token.mouse_filter = Control.MOUSE_FILTER_IGNORE
		token.texture = texture
		token.material = _cutout_material
		token.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		token.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		token.size = Vector2(58,58)
		token.pivot_offset = token.size * 0.5
		token.position = origins[index] - token.size * 0.5
		add_child(token)
		pending_collections += 1
		var start := token.position
		var destination := target.get_global_rect().get_center() - token.size * 0.5
		var bend := (start + destination) * 0.5 + Vector2((-1 if index % 2 == 0 else 1)*80, -90)
		var tween := _effect_tween()
		tween.tween_interval(minf(index * 0.025, 0.28))
		tween.tween_property(token,"scale",Vector2(1.3,1.3),0.10).from(Vector2(0.75,0.75)).set_trans(Tween.TRANS_BACK)
		tween.tween_method(func(t: float):
			if is_instance_valid(token):
				token.travel(start * pow(1-t,2) + bend * 2*(1-t)*t + destination * t*t), 0.0,1.0,0.58).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
		tween.tween_callback(func():
			if is_instance_valid(target): pulse(target)
			group_left[0] -= 1
			if group_left[0] == 0 and is_instance_valid(target):
				gain(target.get_global_rect().get_center(), origins.size() * value_per_piece)
				if not arrival_sound.is_empty(): SignalBus.play_sfx.emit(arrival_sound)
		)
		tween.tween_property(token,"scale",Vector2(0.3,0.3),0.08)
		tween.tween_callback(func():
			if is_instance_valid(token): token.queue_free()
			pending_collections = maxi(0,pending_collections-1)
			if pending_collections == 0: collections_finished.emit())


func pulse(target: Control) -> void:
	var id := target.get_instance_id()
	var old: Tween = _pulse_tweens.get(id)
	if old != null and old.is_running(): old.kill()
	target.pivot_offset = target.size * 0.5
	target.scale = Vector2.ONE
	var tween := _effect_tween()
	_pulse_tweens[id] = tween
	_pulse_targets[id] = weakref(target)
	tween.tween_property(target,"scale",Vector2(1.24,1.24),0.08)
	tween.tween_property(target,"scale",Vector2.ONE,0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func gain(at: Vector2, amount: int) -> void:
	var label := Label.new()
	label.text = "+%d" % amount
	label.position = at - Vector2(40,-10)
	label.size = Vector2(80,44)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size",30)
	label.add_theme_color_override("font_color",Color("#ffe17a"))
	label.add_theme_color_override("font_outline_color",Color("#123b45"))
	label.add_theme_constant_override("outline_size",5)
	add_child(label)
	var tween := _effect_tween().set_parallel(true)
	tween.tween_property(label,"position:y",label.position.y-55,0.55).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(label,"modulate:a",0.0,0.25).set_delay(0.30)
	tween.chain().tween_callback(label.queue_free)


func burst(at: Vector2, radius: float = 90.0, tint: Color = Color("#ffd45b")) -> void:
	var effect := Burst.new()
	effect.position = at
	effect.radius = radius
	effect.tint = tint
	add_child(effect)
	var tween := _effect_tween()
	tween.tween_method(effect.advance,0.0,1.0,0.48)
	tween.tween_callback(effect.queue_free)


func tile_burst(at: Vector2, tint: Color = Color("#ffd45b")) -> void:
	burst(at, 48.0, tint)


func rocket_salvo(origins: Array[Vector2], targets: Array[Vector2]) -> void:
	if origins.is_empty() or targets.is_empty(): return
	for origin in origins:
		burst(origin, 54.0, Color("#ffbd52"))
		var launcher := RocketShot.new()
		launcher.position = origin
		launcher.scale = Vector2(0.1,0.1)
		add_child(launcher)
		var pull := _effect_tween().set_parallel(true)
		pull.tween_property(launcher,"scale",Vector2(1.7,1.7),0.13).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		pull.tween_property(launcher,"rotation",-0.12,0.08)
		pull.tween_property(launcher,"modulate:a",0.0,0.11).set_delay(0.12)
		pull.chain().tween_callback(launcher.queue_free)
	SignalBus.play_sfx.emit("kung_fu_shout")
	await get_tree().create_timer(0.24).timeout
	SignalBus.play_sfx.emit("rocket_launch")
	SignalBus.play_sfx.emit("gunfire_burst")
	for index in targets.size():
		var from: Vector2 = origins[index % origins.size()]
		var to: Vector2 = targets[index]
		var schedule := _effect_tween()
		schedule.tween_interval(index * 0.022)
		schedule.tween_callback(_fire_rocket.bind(from,to))


func _fire_rocket(from: Vector2, to: Vector2) -> void:
	var shot := RocketShot.new()
	shot.position = from
	shot.rotation = (to - from).angle()
	add_child(shot)
	var flight := _effect_tween()
	flight.tween_property(shot,"position",to,0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	flight.tween_callback(func():
		burst(to,39.0,Color("#ffcf68"))
		SignalBus.play_sfx.emit("tile_burst")
		shot.queue_free())


func haptic(duration_ms: int = 22, strength: float = 0.45) -> void:
	if not (OS.has_feature("mobile") or OS.has_feature("android") or OS.has_feature("ios")):
		return
	var now := Time.get_ticks_msec()
	if now - _last_haptic_tick < 70:
		return
	_last_haptic_tick = now
	Input.vibrate_handheld(duration_ms, clampf(strength,0.0,1.0))


func obstacle_debris(at: Vector2, texture: Texture2D, destroyed: bool) -> void:
	burst(at,120 if destroyed else 55,Color("#ffd16b"))
	if texture == null: return
	var pieces := 9 if destroyed else 3
	for index in pieces:
		var fragment := Sprite2D.new()
		fragment.name = "ObstacleDebris"
		var atlas := AtlasTexture.new()
		atlas.atlas = texture
		var part := texture.get_size()/3.0
		atlas.region = Rect2(Vector2(index%3,index/3)*part,part)
		fragment.texture = atlas
		fragment.material = _cutout_material
		fragment.position = at
		fragment.scale = Vector2.ONE * (36.0 / maxf(part.x,1.0))
		add_child(fragment)
		var angle := -PI + index * TAU / pieces
		var velocity := Vector2.from_angle(angle) * (170 if destroyed else 90)
		var tween := _effect_tween().set_parallel(true)
		tween.tween_method(func(t: float):
			fragment.position = at + velocity * t + Vector2(0,220*t*t),0.0,0.75,0.75)
		tween.tween_property(fragment,"rotation",(-1 if index%2==0 else 1)*3.0,0.75)
		tween.tween_property(fragment,"modulate:a",0.0,0.3).set_delay(0.4)
		tween.chain().tween_callback(fragment.queue_free)


func powerup(kind: String, at: Vector2, board_rect: Rect2) -> void:
	burst(at,175 if kind == "bomb" else 125,Color("#9cf8ff") if kind == "thunder" else Color("#ffdd73"))
	if kind == "bomb": return
	var paths: Array[PackedVector2Array] = []
	if kind == "thunder":
		for index in 7:
			var end := board_rect.position + Vector2(randf(),randf()) * board_rect.size
			paths.append(PackedVector2Array([at,at.lerp(end,0.35)+Vector2(18,-24),at.lerp(end,0.7)+Vector2(-16,20),end]))
	else:
		paths = [PackedVector2Array([Vector2(board_rect.position.x,at.y),Vector2(board_rect.end.x,at.y)]),PackedVector2Array([Vector2(at.x,board_rect.position.y),Vector2(at.x,board_rect.end.y)])]
	for points in paths:
		var line := Line2D.new()
		line.points = points
		line.width = 12
		line.default_color = Color("#a2f9ff") if kind == "thunder" else Color("#ffe390")
		line.antialiased = true
		add_child(line)
		var tween := _effect_tween().set_parallel(true)
		tween.tween_property(line,"width",1.0,0.3)
		tween.tween_property(line,"modulate:a",0.0,0.3)
		tween.chain().tween_callback(line.queue_free)


func praise(caption: String, font: Font) -> void:
	if is_instance_valid(_feedback): _feedback.queue_free()
	var label := Label.new()
	_feedback = label
	label.text = caption
	label.z_index = 20
	var viewport_size := get_viewport().get_visible_rect().size
	label.size = Vector2(minf(620.0, viewport_size.x - 24.0),130)
	label.position = viewport_size * Vector2(0.5,0.40)-label.size*0.5
	label.pivot_offset = label.size*0.5
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_override("font",font)
	label.add_theme_font_size_override("font_size",mini(76, roundi(viewport_size.x * 0.15)))
	label.add_theme_color_override("font_color",Color("#ffe674"))
	label.add_theme_color_override("font_outline_color",Color("#562051"))
	label.add_theme_constant_override("outline_size",10)
	add_child(label)
	label.scale = Vector2(0.05,0.05)
	var tween := _effect_tween().bind_node(label)
	tween.tween_property(label,"scale",Vector2(1.48,1.48),0.22).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(label,"rotation",-0.045,0.08).set_trans(Tween.TRANS_BACK)
	tween.tween_property(label,"rotation",0.045,0.10).set_trans(Tween.TRANS_BACK)
	tween.tween_property(label,"rotation",0.0,0.08)
	tween.tween_property(label,"scale",Vector2.ONE,0.14).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	tween.tween_interval(0.72)
	tween.tween_property(label,"modulate:a",0.0,0.28)
	tween.tween_callback(label.queue_free)


func _effect_tween() -> Tween:
	_active_tweens = _active_tweens.filter(func(tween: Tween): return tween.is_valid())
	var tween := create_tween()
	_active_tweens.append(tween)
	tween.finished.connect(func(): _active_tweens.erase(tween))
	return tween
