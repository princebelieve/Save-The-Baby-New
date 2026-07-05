extends Resource
class_name AnimationRequest

# =========================================================
# PURPOSE
# =========================================================
# Represents a single animation request passed into the
# AnimationManager and routed to subsystem animators.
#
# This is a PURE DATA OBJECT.
# No execution logic belongs here.

# =========================================================
# CORE FIELDS
# =========================================================

var animation_name: String = ""

# The target Node (Tile, UI element, Board element, etc.)
var target: Node = null

# Duration of the animation in seconds
var duration: float = 0.0

# Optional delay before animation starts
var delay: float = 0.0

# Optional callback function to call when animation completes
var callback: Callable = Callable()

# Higher value = higher priority in queue processing
var priority: int = 0


# =========================================================
# INITIALIZATION HELPER
# =========================================================

func setup(
	p_animation_name: String,
	p_target: Node,
	p_duration: float = 0.0,
	p_delay: float = 0.0,
	p_callback: Callable = Callable(),
	p_priority: int = 0
) -> void:
	animation_name = p_animation_name
	target = p_target
	duration = p_duration
	delay = p_delay
	callback = p_callback
	priority = p_priority


# =========================================================
# DEBUG / SAFETY HELPERS
# =========================================================

func is_valid() -> bool:
	return animation_name != "" and target != null