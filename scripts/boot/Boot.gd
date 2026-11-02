extends Control

var _game_scene: Node = null
var _is_initialized: bool = false


func _ready() -> void:
	initialize()


func initialize() -> void:
	if _is_initialized:
		return

	_is_initialized = true

	_build_splash_screen()
	await RenderingServer.frame_post_draw
	initialize_utilities()
	load_configuration()
	await get_tree().create_timer(3.6).timeout
	create_game_scene()
	finish_boot()


func _build_splash_screen() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var background := ColorRect.new()
	background.name = "GlossyBrandBackground"
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var shader := Shader.new()
	shader.code = """
	shader_type canvas_item;

	uniform vec4 cream_a : source_color = vec4(0.96, 0.91, 0.78, 1.0);
	uniform vec4 cream_b : source_color = vec4(0.98, 0.94, 0.84, 1.0);
	uniform vec4 cream_c : source_color = vec4(0.95, 0.89, 0.75, 1.0);

	void fragment() {
		float cycle = mod(TIME * 0.84, 3.0);
		vec3 base_color;
		if (cycle < 1.0) {
			base_color = mix(cream_a.rgb, cream_b.rgb, smoothstep(0.0, 1.0, cycle));
		} else if (cycle < 2.0) {
			base_color = mix(cream_b.rgb, cream_c.rgb, smoothstep(1.0, 2.0, cycle));
		} else {
			base_color = mix(cream_c.rgb, cream_a.rgb, smoothstep(2.0, 3.0, cycle));
		}
		float diagonal = UV.x * 0.72 + UV.y * 0.28;
		float sweep = mod(TIME * 0.22, 1.5) - 0.25;
		float broad_gloss = exp(-pow((diagonal - sweep) * 8.0, 2.0)) * 0.045;
		float shine_line = exp(-pow((diagonal - sweep) * 34.0, 2.0)) * 0.09;
		float center_glow = max(0.0, 1.0 - distance(UV, vec2(0.5)) / 0.8) * 0.025;
		COLOR = vec4(base_color + vec3(broad_gloss + shine_line + center_glow), 1.0);
	}
	"""
	var material := ShaderMaterial.new()
	material.shader = shader
	background.material = material
	add_child(background)
	var logo := TextureRect.new()
	logo.name = "CompanySplashLogo"
	var viewport_size := get_viewport_rect().size
	var logo_size := minf(viewport_size.x * 0.94, viewport_size.y * 0.78)
	logo.size = Vector2.ONE * logo_size
	logo.position = (viewport_size - logo.size) * 0.5
	logo.texture = preload("res://assets/sb_ibhadode_splash.png")
	logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	logo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(logo)


func initialize_utilities() -> void:
	DebugLogger.initialize()
	RandomGenerator.initialize()
	ConfigLoader.initialize()
	ResourceManager.initialize()
	JsonLoader.initialize()


func load_configuration() -> void:
	ConfigLoader.reload()


func create_game_scene() -> void:
	var packed_scene = ResourceManager.load_scene(Constants.ScenePaths.GAME)
	if packed_scene == null:
		DebugLogger.error("Boot: Could not load the game scene.")
		return

	_game_scene = packed_scene.instantiate()
	if _game_scene == null:
		DebugLogger.error("Boot: Could not instantiate the game scene.")
		return

	get_tree().root.add_child(_game_scene)
	get_tree().current_scene = _game_scene


func finish_boot() -> void:
	if _game_scene == null:
		return
	var ads := get_node_or_null("/root/AdProvider")
	if ads != null:
		ads.start_session()
	queue_free()
