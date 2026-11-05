"""Build reviewable story JSON and level hooks from the authored campaign outline.

Only narrative fields are changed. Moves, boards, rewards and booster mechanics
remain untouched. The running game never generates these story files.
"""
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PORTRAITS = {
    "David": "res://assets/sprites/characters/david_portrait_v2.png",
    "Amara": "res://assets/sprites/characters/amara_and_ethan_portrait_cutout.png",
    "Victor": "res://assets/sprites/characters/victor_portrait_v2.png",
    "Detective Morris": "res://assets/sprites/characters/detective_portrait_cutout.png",
}


def line(speaker, text):
    value = {"speaker": speaker, "portrait": PORTRAITS[speaker], "text": text}
    if speaker == "Detective Morris":
        value["routes"] = ["police"]
    return value


def write(path, value):
    path.write_text(json.dumps(value, indent=2, ensure_ascii=False)+"\n", encoding="utf-8")


def build():
    config = json.loads((ROOT/"configs/story_campaign.json").read_text(encoding="utf-8"))
    assert len(config["seasons"]) == 10
    episode_id = 0
    for season_number, season in enumerate(config["seasons"], 1):
        assert len(season["episodes"]) == 10
        for local_number, episode in enumerate(season["episodes"], 1):
            episode_id += 1
            first = 51+(episode_id-1)*10
            last = first+9
            clue = episode["clue"]
            for phase in ["intro", "outro"]:
                story_id = f"serial{episode_id:03d}_{phase}"
                if phase == "intro":
                    dialogue = [line("David", episode["setup"]), line("Amara", episode["amara"])]
                    choices = []
                else:
                    dialogue = [line("David", episode["reveal"]),line("Amara", episode["hook"])]
                    choices = [
                        {"id":"police","label":"Coordinate the next lead with the police","impact":f"Bring Morris into the next investigation and preserve the evidence behind {clue}.","response":"Morris takes the lead into the formal investigation. David checks the record while Amara explains its personal significance.","speaker":"Detective Morris"},
                        {"id":"signal","label":"Decode the next connection with Amara","impact":f"David checks the technical trail from {clue}; Amara tests it against her own history.","response":"David saves the original record and checks its connections. Amara refuses to let Victor's version replace what she remembers.","speaker":"David"},
                        {"id":"alone","label":"Follow the next trail without police backup","impact":f"David follows the physical lead from {clue}, keeping Amara informed.","response":"David sends Amara his location before moving. Finding Ethan matters more than claiming the search as his own achievement.","speaker":"David"},
                    ]
                routes = {
                    "police":[line("Detective Morris",f"We will verify {clue} and keep its source intact. A lead is not a rescue; we cannot assume Victor stayed there.")],
                    "signal":[line("David",f"I will check the technical trail behind {clue}. Amara, tell me what the records cannot explain.")],
                    "alone":[line("David",f"I am following {clue} without police backup. Amara has my location; I am not going to turn this into a contest with Victor.")],
                }
                metadata = {"version":2,"season":season_number,"season_title":season["title"],"episode":local_number,"episode_id":episode_id,"campaign_levels":f"{first:03d}-{last:03d}","ethan_status":"missing","season_finale":phase=="outro" and local_number==10}
                if phase == "outro":
                    metadata["evidence_summary"] = episode["reveal"]+" "+episode["hook"]
                write(ROOT/f"stories/{story_id}.json",{
                    "story_id":story_id,"title":episode["title"]+(" | The next lead" if phase=="outro" else ""),
                    "background_music":"suspense_opening","default_background":"res://assets/sprites/backgrounds/"+season["background"],
                    "portrait":PORTRAITS["David"],"characters":["david","amara","victor","ethan","detective_morris"],
                    "scenes":[{"scene_id":story_id,"route_dialogues":routes,"dialogues":dialogue,"choices":choices}],"metadata":metadata})
            beats = [episode["setup"],f"Preserve the original evidence behind {clue}.",f"Trace the source of {clue} before trusting Victor's account.",episode["amara"],f"Compare {clue} with what the witnesses actually remember.",episode["reveal"],f"Check {clue} against an independent record.",f"Reconstruct the missing step around {clue}.",f"Give Amara a verified account of {clue}, so she can choose the next step.",f"Close this investigation and hear what {clue} changes for the family."]
            for step, level_id in enumerate(range(first,last+1)):
                path = ROOT/f"levels/level{level_id:03d}.json"
                data = json.loads(path.read_text())
                data["name"] = f"{episode['title']} {step+1:02d}"
                prefix = "Critical Case: " if data.get("difficulty")=="CRITICAL_CASE" else ""
                data["description"] = prefix+beats[step]
                data["story"] = {"before_level":f"serial{episode_id:03d}_intro" if step==0 else "","after_level":f"serial{episode_id:03d}_outro" if step==9 else "","first_clear":"","return_to_map":True,
                    "win_outcome":f"You verified the lead behind {clue}. Ethan is still missing; the trail continues.",
                    "briefings":{
                        "police":f"Morris coordinates the investigation into {clue}. David checks the records; Amara supplies the history the evidence cannot tell on its own.",
                        "signal":f"David checks the digital trail behind {clue}. Amara compares it with what she knows; no police team has joined this approach.",
                        "alone":f"David follows the physical trail behind {clue} without police backup, keeping Amara informed rather than claiming the search as his own."}}
                data["metadata"].update(season=season_number,season_title=season["title"],episode_id=episode_id,chapter_title=episode["title"],chapter_id=6+episode_id,chapter_start_level=first,chapter_end_level=last)
                write(path,data)
    print(f"Built {episode_id*2} story files and wired 1,000 level narratives; puzzle mechanics unchanged.")


if __name__ == "__main__":
    build()
