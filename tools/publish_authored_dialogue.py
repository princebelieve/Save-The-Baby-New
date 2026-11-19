"""Publish individually authored dialogue; never synthesize conversations from templates.

Source scripts use @@ scene/episode, I/O phase and Speaker|spoken words.
Changing narrative fields must never change puzzle mechanics or rewards.
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
STAGING = [
    "Amara and David compare records at the kitchen table. The empty feeding cup remains beside her hand.",
    "The conversation moves between Amara's home and the estate's public offices. Keep documents distinct from what people claim about them.",
    "Calls and protected interviews interrupt the search. Amara asks practical questions about Ethan's care before she asks about blame.",
    "Private memories interrupt the investigation. David listens without competing with either man from Amara's past.",
    "The household's polished public account meets the records retained by its workers. Amara speaks for herself.",
    "Phone contact becomes tangible. Let Amara listen before David interprets what the new evidence means.",
    "Victor's commands meet increasingly specific questions he cannot answer. His uncertainty must not be played as proof Ethan is safe.",
    "Adrian's surviving records reopen grief. Leave a pause around Amara's response; David does not speak over it.",
    "The search becomes a confrontation with named decision-makers. Each signed record changes a concrete next step.",
    "The room grows quieter as live contact approaches. The last call is real; physical reunion is still beyond this campaign.",
]
PROLOGUE_TITLES = {
    "opening_story": "The Morning Ethan Vanished", "chapter01": "Behind the Bolted Door",
    "season01": "The Gate Was Never Opened", "chapter02": "My Money or Ethan",
    "season02": "A Debt That Never Existed", "season03": "Someone Knew the House",
    "chapter03": "What He Called Luck", "season04": "The Wrong Man",
    "chapter04": "The Sound She Remembered", "season05": "The Question After the Funeral",
    "season06": "The Service Vehicle", "chapter05": "A Refusal He Would Not Hear",
    "season07": "The Estate Account", "season08": "What Amara Saw",
    "chapter06": "The Missing Corner", "season09": "Victor Inside",
    "season10": "Her Name at the Door",
}


def read_json(path):
    return json.loads(path.read_text(encoding="utf-8"))


def write_json(path, value):
    path.write_text(json.dumps(value, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")


def dialogue(speaker, text):
    assert speaker in PORTRAITS, speaker
    assert text.strip() and "|" not in text
    value = {"speaker": speaker, "portrait": PORTRAITS[speaker], "text": text}
    if speaker == "Detective Morris":
        value["routes"] = ["police"]
    return value


def parse_script(path, phases=False):
    result = {}
    current = None
    for number, raw in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
        if not raw.strip():
            continue
        if raw.startswith("@@ "):
            current = raw[3:].strip()
            assert current not in result, (path, number, current)
            result[current] = {"I": [], "O": []} if phases else []
            continue
        assert current is not None, (path, number)
        phase, value = (raw[0], raw[2:]) if phases else (None, raw)
        speaker, text = value.split("|", 1)
        target = result[current][phase] if phases else result[current]
        target.append(dialogue(speaker, text))
    return result


def opening_choices():
    return [
        {"id": "police", "label": "Call Detective Morris", "speaker": "David",
         "impact": "Request police assistance and preserve the scene while the search begins.",
         "response": "I am calling Morris. He needs to hear what you saw from you, Amara. I will stay beside you."},
        {"id": "signal", "label": "Trace the message with Amara", "speaker": "David",
         "impact": "Begin with the original message and Amara's knowledge of the household. No technical result is certain.",
         "response": "Keep the original message open. I will examine the record; you tell me what the names and places mean."},
        {"id": "alone", "label": "Follow the rear passage yourself", "speaker": "David",
         "impact": "Begin with direct observation without nearby police backup. Amara receives David's location.",
         "response": "I will check the passage first. Here is my location. If I need help, I am going to ask for it—not disappear too."},
    ]


def build():
    plan = read_json(ROOT / "docs/design/serialized-story-ledger.json")
    prologue = parse_script(ROOT / "docs/design/prologue-dialogue.script")
    episodes = parse_script(ROOT / "docs/design/campaign-dialogue.script", True)
    assert len(prologue) == 17 and set(episodes) == {str(i) for i in range(1, 101)}
    old = read_json(ROOT / "configs/story_campaign.json")
    screenplay = ["# Save The Baby — playable dramatic adaptation", "",
                  "Individually authored conversations. Scene directions below are production notes, not implemented character animation. Ethan is not rescued in levels 1–1050.", ""]
    published = []
    for record in plan["scenes"]:
        sid = record["scene"]
        path = ROOT / "stories" / (sid + ".json")
        story = read_json(path)
        if sid in prologue:
            lines = prologue[sid]
            story["title"] = PROLOGUE_TITLES[sid]
            direction = "Rain, interrupted sleep and a missing infant. Preserve the distinction between Amara's true sighting and the unexplained means of entry."
            choices = opening_choices() if sid == "opening_story" else []
        else:
            number = int(sid[6:9])
            arc = plan["arcs"][(number - 1) // 10]
            episode = arc["episodes"][(number - 1) % 10]
            phase = "I" if sid.endswith("intro") else "O"
            lines = episodes[str(number)][phase]
            assert len(lines) >= 2
            story["title"] = episode["title"]
            story["metadata"].update(season=arc["number"], season_title=arc["title"],
                                     known_before=episode["required_fact"],
                                     unlocks_fact=episode["new_fact"] if phase == "O" else "")
            story["metadata"].pop("evidence_summary", None)
            if phase == "O":
                story["metadata"]["evidence_summary"] = episode["discovery"]
            direction = STAGING[(number - 1) // 10]
            choices = []  # Do not pretend cosmetic repeated choices branch the plot.
        story["background_music"] = "case_investigation"
        story["characters"] = ["david", "amara", "victor", "detective_morris"]
        story["scenes"] = [{"scene_id": sid, "stage_direction": direction,
                            "dialogues": lines, "choices": choices}]
        story["metadata"].update(authored_dialogue_revision=1, ethan_status="missing")
        write_json(path, story)
        published.append(sid)
        screenplay.extend([f"## {sid} — {record['trigger']}", "", f"*{direction}*", ""])
        for entry in lines:
            screenplay.extend([f"**{entry['speaker'].upper()}:** {entry['text']}", ""])
    # Match all later mission descriptions to the new story without exposing
    # an episode's earned outcome before the outro has played.
    new_seasons = []
    for arc in plan["arcs"]:
        season = {"title": arc["title"], "background": old["seasons"][arc["number"] - 1]["background"], "episodes": []}
        for ep in arc["episodes"]:
            season["episodes"].append({"title": ep["title"], "clue": ep["title"].lower(),
                                       "setup": ep["entry"], "reveal": ep["discovery"],
                                       "hook": ep["hook"], "authored_episode": ep["episode"]})
            for index, level in enumerate(range(ep["levels"][0], ep["levels"][1] + 1)):
                path = ROOT / f"levels/level{level:03}.json"
                data = read_json(path)
                data["name"] = f"{ep['title']} {index + 1:02}"
                data["description"] = ep["entry"]
                data["metadata"].update(chapter_title=ep["title"], season_title=arc["title"])
                data["story"].update(win_outcome=f"The investigation into {ep['title'].lower()} advances.", briefings={})
                write_json(path, data)
        new_seasons.append(season)
    write_json(ROOT / "configs/story_campaign.json", {"version": 3, "first_level": 51,
               "episode_length": 10, "dialogue_source": "docs/design/campaign-dialogue.script", "seasons": new_seasons})
    canon = read_json(ROOT / "configs/story_canon.json")
    canon.update(version=3, father_name="Adrian", father_death_cause="unresolved; murder suspected but not proved",
                 continuing_story_rule="Ethan is not rescued during levels 1–1050. The search earns lasting discoveries and genuine proof of life. His eventual rescue belongs to later content.")
    canon["summary"] = ("Amara left Victor after he urged her to exploit Adrian's marriage proposal. "
        "Victor claimed his aura caused her success while she supported them through street work. "
        "Adrian's royal family opposed the marriage and rejected their infant Ethan. Adrian acknowledged his son "
        "and left him a private provision before dying mysteriously. Amara suspected Victor without proof. "
        "She refused Victor's attempt to reclaim her and later fell in love with David, a web developer. "
        "Victor demanded a share of Ethan's provision and abducted the baby, saying 'My money or Ethan.' "
        "Amara truly saw Victor taking Ethan, although the house appeared securely locked. David must help her "
        "uncover the access conspiracy and locate Ethan. Neither Victor's aura nor his ownership claim is a fact.")
    write_json(ROOT / "configs/story_canon.json", canon)
    (ROOT / "docs/design/playable-story-screenplay.md").write_text("\n".join(screenplay), encoding="utf-8")
    print(f"Published {len(published)} authored conversations and updated narrative-only level fields.")


if __name__ == "__main__":
    build()
