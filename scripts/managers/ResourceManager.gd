extends Node

class_name ResourceManager


var _cache: Dictionary = {}


# ==========================================================
# LOADING
# ==========================================================

func load_resource(path: String) -> Resource:
	if path.is_empty():
		push_warning("ResourceManager: Empty resource path.")
		return null

	if _cache.has(path):
		return _cache[path]

	if not ResourceLoader.exists(path):
		push_warning("ResourceManager: Resource not found: %s" % path)
		return null

	var resource := ResourceLoader.load(path)

	if resource == null:
		push_warning("ResourceManager: Failed to load resource: %s" % path)
		return null

	_cache[path] = resource
	return resource


func preload_resource(path: String) -> void:
	load_resource(path)


func preload_resources(paths: Array) -> void:
	for path in paths:
		if path is String:
			load_resource(path)


# ==========================================================
# CACHE
# ==========================================================

func has_resource(path: String) -> bool:
	return _cache.has(path)


func get_cached_resource(path: String) -> Resource:
	if _cache.has(path):
		return _cache[path]

	return null


func unload_resource(path: String) -> void:
	if _cache.has(path):
		_cache.erase(path)


func clear_cache() -> void:
	_cache.clear()


func cache_size() -> int:
	return _cache.size()


# ==========================================================
# HELPERS
# ==========================================================

func load_scene(path: String) -> PackedScene:
	var resource := load_resource(path)

	if resource is PackedScene:
		return resource

	push_warning("ResourceManager: Resource is not a PackedScene: %s" % path)
	return null


func instantiate_scene(path: String) -> Node:
	var scene := load_scene(path)

	if scene == null:
		return null

	return scene.instantiate()


func load_texture(path: String) -> Texture2D:
	var resource := load_resource(path)

	if resource is Texture2D:
		return resource

	push_warning("ResourceManager: Resource is not a Texture2D: %s" % path)
	return null


func load_audio(path: String) -> AudioStream:
	var resource := load_resource(path)

	if resource is AudioStream:
		return resource

	push_warning("ResourceManager: Resource is not an AudioStream: %s" % path)
	return null


func load_font(path: String) -> Font:
	var resource := load_resource(path)

	if resource is Font:
		return resource

	push_warning("ResourceManager: Resource is not a Font: %s" % path)
	return null


func load_material(path: String) -> Material:
	var resource := load_resource(path)

	if resource is Material:
		return resource

	push_warning("ResourceManager: Resource is not a Material: %s" % path)
	return null


# ==========================================================
# DEBUG
# ==========================================================

func print_cache() -> void:
	print("--------------------------------")
	print("Resource Cache")
	print("--------------------------------")

	for path in _cache.keys():
		print(path)

	print("--------------------------------")
	print("Total Cached: ", _cache.size())
	print("--------------------------------")