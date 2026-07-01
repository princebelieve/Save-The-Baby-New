extends Node

class_name Version

# =========================================================
# PURPOSE
#
# Stores project version information.
#
# Rules:
# - Engine metadata only.
# - No gameplay logic.
# - No manager dependencies.
# - No runtime state.
# =========================================================


# =========================================================
# VERSION METADATA
# =========================================================

const GAME_NAME: String = "Save The Baby"

const VERSION: String = "1.0.0"

const SAVE_VERSION: int = 1

const BUILD_NUMBER: int = 1


# =========================================================
# PUBLIC API
# =========================================================

func version_string() -> String:
	return VERSION


func save_version() -> int:
	return SAVE_VERSION


func build_number() -> int:
	return BUILD_NUMBER