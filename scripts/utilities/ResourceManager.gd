extends Node
class_name ResourceManager

# =========================================================
# PURPOSE
# Central cache for all Godot resources.
#
# Rules:
# - No gameplay logic
# - No coordination
# - No decision-making
# - Only load/cache/unload resources
# =========================================================

var _resource_cache: Dictionary = {}

# =========================================================
# INITIALIZATION
# =========================================================
func initialize() -> void:
	_resource_cache.clear()


# =========================================================
# CORE CACHE CONTROL
# =========================================================
func clear() -> void:
	_resource_cache.clear()


func clear_unused() -> void:
	# Removes unused cached resources from memory
	for path in _resource_cache.keys():
		var res = _resource_cache[path]

		if res == null:
			_resource_cache.erase(path)
			continue

		# If no external references exist, safe to drop
		if res.get_reference_count() <= 1:
			_resource_cache.erase(path)

	# Also ask engine to purge unused cache entries
	ResourceLoader.clear_cache()


# =========================================================
# GENERIC LOADING
# =========================================================
func load_resource(path: String) -> Resource:
	if _resource_cache.has(path):
		return _resource_cache[path]

	var resource = ResourceLoader.load(path)

	if resource == null:
		DebugLogger.error("ResourceManager: Failed to load resource -> " + path)
		return null

	_resource_cache[path] = resource
	return resource


func reload_resource(path: String) -> Resource:
	unload_resource(path)
	return load_resource(path)


func unload_resource(path: String) -> void:
	if _resource_cache.has(path):
		var res = _resource_cache[path]
		_resource_cache.erase(path)

		# Remove from engine cache so it can be fully freed if unused
		if res != null:
			ResourceLoader.remove_from_cache(path)


# =========================================================
# CACHE QUERIES
# =========================================================
func has(path: String) -> bool:
	return _resource_cache.has(path)


func get(path: String) -> Resource:
	if _resource_cache.has(path):
		return _resource_cache[path]

	return load_resource(path)


# =========================================================
# SPECIALIZED LOADERS
# =========================================================

func load_scene(path: String) -> PackedScene:
	var res = get(path)

	if res is PackedScene:
		return res

	DebugLogger.error("ResourceManager: Not a PackedScene -> " + path)
	return null


func load_texture(path: String) -> Texture2D:
	var res = get(path)

	if res is Texture2D:
		return res

	DebugLogger.error("ResourceManager: Not a Texture2D -> " + path)
	return null


func load_audio(path: String) -> AudioStream:
	var res = get(path)

	if res is AudioStream:
		return res

	DebugLogger.error("ResourceManager: Not an AudioStream -> " + path)
	return null


func load_font(path: String) -> Font:
	var res = get(path)

	if res is Font:
		return res

	DebugLogger.error("ResourceManager: Not a Font -> " + path)
	return null


func load_animation(path: String) -> Resource:
	# Animation resources can vary (AnimationPlayer libraries, custom resources, etc.)
	return get(path)