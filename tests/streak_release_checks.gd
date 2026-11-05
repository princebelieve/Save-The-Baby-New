extends Node

const MONDAY := 20003 * 86400
const FIXTURE := "user://streak_restart_fixture.cfg"
var failures: Array[String] = []
var checks := 0


func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)
		push_error(message)


func _ready() -> void:
	if not OS.get_user_data_dir().replace("\\", "/").contains("/.test-data/"):
		get_tree().quit(1)
		return
	call_deferred("_run")


func _run() -> void:
	if "--resume" in OS.get_cmdline_user_args():
		_check_process_restart()
		_finish("restart")
		return
	_check_calendar()
	_check_missed_days()
	_check_slots()
	_check_missions()
	_prepare_restart()
	_finish("calendar")


func _check_calendar() -> void:
	var progress := ConfigFile.new()
	var total := 0
	for day in 35:
		var now := MONDAY + day * 86400 + 3600
		var reward := DailyActivities.stamp(progress, now)
		var expected := int(DailyActivities.settings().streak_coins[day % 7])
		if day % 7 == 4:
			expected += 75
		check(int(reward.get("streak", -1)) == day + 1, "Consecutive day %d retains streak" % day)
		check(int(reward.get("coins", -1)) == expected, "Exact cycle and weekly reward for day %d" % day)
		check(DailyActivities.stamp(progress, now + 20).is_empty(), "No second stamp on day %d" % day)
		check(int(progress.get_value("daily", "weekly_count", -1)) == day % 7 + 1, "UTC Monday resets weekly count")
		total += int(reward.get("coins", 0))
		check(CampaignProgressStore.write(progress, "user://calendar_roundtrip.cfg") == OK, "Calendar save writes")
		var restored := ConfigFile.new()
		check(CampaignProgressStore.read(restored, "user://calendar_roundtrip.cfg") == OK, "Calendar save reloads")
		progress = restored
		check(DailyActivities.stamp(progress, now + 30).is_empty(), "Restart cannot repeat daily claim")
	check(total == 1375, "35 consecutive days pay exactly five cycles and five weekly bonuses")
	check(DailyActivities.stamp(progress, MONDAY - 1).is_empty(), "Rollback cannot earn rewards")
	var boundary := ConfigFile.new()
	check(int(DailyActivities.stamp(boundary, MONDAY + 86399).streak) == 1, "Stamp just before UTC midnight")
	check(int(DailyActivities.stamp(boundary, MONDAY + 86400).streak) == 2, "Stamp just after UTC midnight")
	var sunday := ConfigFile.new()
	DailyActivities.stamp(sunday, MONDAY + 6 * 86400 + 10)
	DailyActivities.stamp(sunday, MONDAY + 7 * 86400 + 10)
	check(int(sunday.get_value("daily", "weekly_count", 0)) == 1, "Sunday to Monday starts a fresh weekly bonus")


func _check_missed_days() -> void:
	var progress := ConfigFile.new()
	var days := [0, 1, 3, 5, 6, 7, 8, 9, 11]
	var expected := [1, 2, 3, 1, 2, 3, 4, 5, 6]
	for index in days.size():
		var reward := DailyActivities.stamp(progress, MONDAY + int(days[index]) * 86400 + 100)
		check(int(reward.streak) == int(expected[index]), "Missed-day grace and cooldown at day %d" % int(days[index]))
		check(bool(reward.protected) == (index in [2, 8]), "Grace used only when eligible")
	var reward := DailyActivities.stamp(progress, MONDAY + 20 * 86400 + 100)
	check(int(reward.streak) == 1, "Long absence resets consecutive streak")


func _solve(progress: ConfigFile, attempt: Dictionary, now: int) -> Dictionary:
	attempt.pieces = [0, 1, 2, 3, 4, 5, 6, 7, 8]
	progress.set_value("daily", "attempt", attempt)
	return DailyActivities.finish_portrait(progress, int(attempt.slot), now)


func _check_slots() -> void:
	var progress := ConfigFile.new()
	var morning := MONDAY + 3600
	var first := DailyActivities.start_portrait(progress, morning)
	check(not first.is_empty(), "Morning portrait available")
	check(int(first.deadline) == morning + 120, "Full portrait timer is 120 seconds")
	check(DailyActivities.start_portrait(progress, morning + 1).is_empty(), "Cannot restart slot to reset time")
	check(int(_solve(progress, first, morning + 30).coins) == 40, "First portrait grants 30 coins and first stamp")
	check(DailyActivities.finish_portrait(progress, int(first.slot), morning + 31).is_empty(), "Double completion rejected")
	check(not DailyActivities.available(progress, MONDAY + 43199), "Still locked one second before second slot")
	check(DailyActivities.available(progress, MONDAY + 43200), "Second slot opens exactly at noon UTC")
	var second := DailyActivities.start_portrait(progress, MONDAY + 43200)
	check(int(_solve(progress, second, MONDAY + 43220).coins) == 30, "Second portrait gives only portrait reward, no duplicate stamp")
	check(int(progress.get_value("daily", "streak", 0)) == 1, "Two portraits count as one daily stamp")
	check(not DailyActivities.available(progress, MONDAY + 86399), "No third rewarded slot in a UTC day")
	check(DailyActivities.available(progress, MONDAY + 86400), "Next day's portrait unlocks at midnight")
	var expired := ConfigFile.new()
	var attempt := DailyActivities.start_portrait(expired, morning)
	check(DailyActivities.active_attempt(expired, morning + 120).is_empty(), "Expiry enforced at exact deadline")
	check(_solve(expired, attempt, morning + 120).is_empty(), "Solving at deadline earns no reward")
	var midnight := ConfigFile.new()
	attempt = DailyActivities.start_portrait(midnight, MONDAY + 86399)
	check(int(attempt.deadline) == MONDAY + 86400, "Slot boundary clips portrait deadline")
	check(_solve(midnight, attempt, MONDAY + 86400).is_empty(), "Old slot cannot pay after midnight")


func _check_missions() -> void:
	var progress := ConfigFile.new()
	var now := MONDAY + 3600
	check(DailyActivities.record_mission(progress, "specials", 1, now) == 0, "Partial special goal")
	check(DailyActivities.record_mission(progress, "specials", 1, now + 1) == 20, "Special goal exact reward")
	check(DailyActivities.record_mission(progress, "specials", 100, now + 2) == 0, "Special goal pays only once")
	check(DailyActivities.record_mission(progress, "blockers", 3, now + 3) == 25, "Blocker goal exact reward")
	check(DailyActivities.record_mission(progress, "blockers", 3, now - 1) == 0, "Clock rollback cannot pay mission")
	check(DailyActivities.record_mission(progress, "blockers", 3, now + 86400) == 25, "Goals reset next day")
	check(int(progress.get_value("daily", "streak", 0)) == 0, "Goals alone cannot inflate streak")


func _prepare_restart() -> void:
	var progress := ConfigFile.new()
	var now := MONDAY + 3600
	DailyActivities.stamp(progress, now)
	var attempt := DailyActivities.start_portrait(progress, now + 10)
	# Persist a genuinely incomplete arrangement and fixed deadline.
	progress.set_value("test", "now", now)
	progress.set_value("test", "deadline", int(attempt.deadline))
	progress.set_value("test", "pieces", attempt.pieces)
	check(CampaignProgressStore.write(progress, FIXTURE) == OK, "Cross-process fixture writes")


func _check_process_restart() -> void:
	var progress := ConfigFile.new()
	check(CampaignProgressStore.read(progress, FIXTURE) == OK, "Separate Godot process loads saved activity")
	var now := int(progress.get_value("test", "now", 0))
	check(now > 0, "Restart fixture has expected timestamp")
	var attempt := DailyActivities.active_attempt(progress, now + 20)
	check(not attempt.is_empty(), "Unfinished puzzle survives process restart")
	if attempt.is_empty():
		return
	check(int(attempt.deadline) == int(progress.get_value("test", "deadline", 0)), "Restart does not extend deadline")
	check(attempt.pieces == progress.get_value("test", "pieces", []), "Restart preserves exact piece arrangement")
	check(DailyActivities.stamp(progress, now + 21).is_empty(), "Restart cannot duplicate previously claimed stamp")
	check(int(_solve(progress, attempt, now + 30).coins) == 30, "Resumed portrait pays once without duplicate stamp")
	check(CampaignProgressStore.write(progress, FIXTURE) == OK, "Claim is persisted")
	var restored := ConfigFile.new()
	check(CampaignProgressStore.read(restored, FIXTURE) == OK, "Claimed activity reloads")
	check(DailyActivities.active_attempt(restored, now + 31).is_empty(), "Claimed portrait cannot resume")
	check(not DailyActivities.available(restored, now + 31), "Claimed slot stays consumed after reload")
	check(DailyActivities.finish_portrait(restored, int(attempt.slot), now + 31).is_empty(), "Saved claim cannot pay twice")
	check(int(DailyActivities.stamp(restored, now + 86400).streak) == 2, "Next day continues saved streak")


func _finish(phase: String) -> void:
	var file := FileAccess.open("res://.test-data/streak-release-%s.json" % phase, FileAccess.WRITE)
	file.store_string(JSON.stringify({"phase": phase, "checks": checks, "failures": failures}, "  ") + "\n")
	file.close()
	print("STREAK_RELEASE_%s: %d checks; %d failures" % [phase.to_upper(), checks, failures.size()])
	get_tree().quit(0 if failures.is_empty() else 1)
