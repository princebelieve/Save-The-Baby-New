extends Control
class_name MapStars

var earned := 0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	size = Vector2(156, 60)

func _draw() -> void:
	var plate := StyleBoxFlat.new()
	plate.bg_color = Color("#17283f")
	plate.border_color = Color("#f5d077")
	plate.set_border_width_all(2)
	plate.set_corner_radius_all(24)
	draw_style_box(plate, Rect2(Vector2.ZERO, Vector2(156, 60)))
	for index in 3:
		var points := PackedVector2Array()
		var center := Vector2(30 + index * 48, 30)
		for vertex in 10:
			var angle := -PI / 2 + vertex * PI / 5
			points.append(center + Vector2(cos(angle), sin(angle)) * (23 if vertex % 2 == 0 else 10))
		draw_colored_polygon(points, Color("#ffd44f") if index < earned else Color("#61728a"))
		points.append(points[0])
		draw_polyline(points, Color("#fff3ac") if index < earned else Color("#93a4b9"), 2, true)
