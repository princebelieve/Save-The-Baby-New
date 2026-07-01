extends Node
class_name TimeHelper

"""
Purpose:
Common date and time calculations for the entire project.

Rules:
- No gameplay logic
- No state tracking
- No dependencies on managers
- Only pure time utilities
"""

# ----------------------------------------------------
# CURRENT TIME
# ----------------------------------------------------

func current_unix_time() -> int:
	# Returns current system time in seconds (UTC-based Unix timestamp)
	return Time.get_unix_time_from_system()


func current_datetime() -> Dictionary:
	# Returns full system datetime breakdown as Dictionary
	# Example keys: year, month, day, hour, minute, second
	return Time.get_datetime_dict_from_system()


# ----------------------------------------------------
# DIFFERENCES (expects Unix timestamps)
# ----------------------------------------------------

func seconds_between(a: int, b: int) -> int:
	# Absolute difference in seconds
	return abs(a - b)


func minutes_between(a: int, b: int) -> int:
	# Converts seconds difference into minutes
	return int(abs(a - b) / 60)


func hours_between(a: int, b: int) -> int:
	# Converts seconds difference into hours
	return int(abs(a - b) / 3600)


func days_between(a: int, b: int) -> int:
	# Converts seconds difference into days
	return int(abs(a - b) / 86400)


# ----------------------------------------------------
# FORMATTING
# ----------------------------------------------------

func format_duration(seconds: int) -> String:
	"""
	Converts raw seconds into a human-readable format.

	Examples:
	- 65 -> "00:01:05"
	- 3600 -> "01:00:00"
	"""

	var clamped := max(0, seconds)

	var hrs := clamped / 3600
	var mins := (clamped % 3600) / 60
	var secs := clamped % 60

	return "%02d:%02d:%02d" % [hrs, mins, secs]