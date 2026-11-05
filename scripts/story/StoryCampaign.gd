extends RefCounted

static func episode_for(level_id: int) -> Dictionary:
	var config := JsonLoader.load_file("res://configs/story_campaign.json")
	var first := int(config.get("first_level",51))
	var length := int(config.get("episode_length",10))
	if level_id < first:
		return {}
	var global_index := (level_id-first)/length
	var seasons: Array = config.get("seasons",[])
	var season_index := global_index/10
	if season_index >= seasons.size():
		return {}
	var season: Dictionary = seasons[season_index]
	var index := global_index%10
	var episode: Dictionary = season.episodes[index].duplicate(true)
	episode["episode_id"] = global_index+1
	episode["season"] = season_index+1
	episode["season_title"] = season.title
	episode["background"] = season.background
	episode["start_level"] = first+global_index*length
	episode["end_level"] = first+(global_index+1)*length-1
	return episode

static func apply_to_level(data: Dictionary) -> Dictionary:
	var episode := episode_for(int(data.get("level_id",0)))
	if episode.is_empty():
		return data
	var step := int(data.level_id)-int(episode.start_level)
	var clue := str(episode.clue)
	var beats := [str(episode.setup),"Preserve the original evidence behind " + clue + ".", "Trace the source of " + clue + " before trusting Victor's account.",str(episode.amara),"Compare " + clue + " with what the witnesses actually remember.",str(episode.reveal),"Check " + clue + " against an independent record.","Reconstruct the missing step around " + clue + ".","Give Amara a verified account of " + clue + ", so she can choose the next step.","Close this investigation and hear what " + clue + " changes for the family."]
	data.name = "%s %02d" % [str(episode.title),step+1]
	data.description = ("Critical Case: " if str(data.get("difficulty","")) == "CRITICAL_CASE" else "")+str(beats[step])
	data.story = {
		"before_level":"serial%03d_intro" % int(episode.episode_id) if step == 0 else "",
		"after_level":"serial%03d_outro" % int(episode.episode_id) if step == 9 else "",
		"first_clear":"", "return_to_map":true,
		"win_outcome":"You verified the lead behind %s. Ethan is still missing; the trail continues." % clue,
		"briefings":{
			"police":"Morris coordinates the investigation into %s. David checks the records; Amara supplies the history the evidence cannot tell on its own." % clue,
			"signal":"David checks the digital trail behind %s. Amara compares it with what she knows; no police team has joined this approach." % clue,
			"alone":"David follows the physical trail behind %s without police backup, keeping Amara informed rather than claiming the search as his own." % clue}}
	data.metadata["season"] = int(episode.season)
	data.metadata["season_title"] = str(episode.season_title)
	data.metadata["episode_id"] = int(episode.episode_id)
	data.metadata["chapter_title"] = str(episode.title)
	data.metadata["chapter_id"] = 6+int(episode.episode_id)
	data.metadata["chapter_start_level"] = int(episode.start_level)
	data.metadata["chapter_end_level"] = int(episode.end_level)
	return data

static func resolve_choice(story_id: String, choice_id: String) -> Dictionary:
	var path := "res://stories/"+story_id+".json"
	if FileAccess.file_exists(path):
		for scene in JsonLoader.load_file(path).get("scenes",[]):
			for choice in scene.get("choices",[]):
				if str(choice.get("id","")) == choice_id:
					return choice
	return {"id":choice_id,"label":choice_id.capitalize(),"response":"This decision sets the approach for the next investigation."}

static func compact_history(progress: ConfigFile) -> void:
	var value: Variant = progress.get_value("story_choices","history",{})
	var compact: Dictionary = {}
	if value is Dictionary:
		for id in value:
			if value[id] is Dictionary:
				compact[str(id)] = {"id":str(value[id].get("id","alone"))}
	progress.set_value("story_choices","history",compact)
