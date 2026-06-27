stories/
Story JSON API Map (Version 1.0 Freeze)

These files contain all story content. The story engine reads them, but never hardcodes dialogue.

Each story file follows the same structure so StoryManager, DialoguePlayer, PortraitManager, and ChoiceManager can load any story without special handling.

Folder
stories/
    intro.json
    chapter01.json
    chapter02.json
    ending.json
Common JSON Structure

Every story file uses this layout.

{
    "story_id": "",
    "title": "",
    "background_music": "",
    "default_background": "",
    "characters": [],
    "scenes": [],
    "metadata": {}
}
story_id

Unique identifier.

Example

"story_id": "intro"
title

Human-readable title.

"title": "Opening"
background_music

Music played while the story runs.

"background_music": "story_intro"
default_background

Fallback background image.

"default_background": "backgrounds/city_day.png"
characters

Characters used in this story.

[
    {
        "id": "amara",
        "name": "Amara",
        "portrait": "amara_normal"
    },
    {
        "id": "victor",
        "name": "Victor",
        "portrait": "victor_smile"
    }
]
scenes

Array of story scenes.

[
    { ... },
    { ... }
]
Scene Object

Each scene contains:

{
    "id": "",
    "background": "",
    "music": "",
    "dialogues": [],
    "choices": [],
    "next_scene": ""
}
Scene Fields
id

Unique scene identifier.

"id": "intro_001"
background

Scene background.

"background": "backgrounds/street_night.png"
music

Optional scene music override.

"music": "suspense"
dialogues

Dialogue sequence.

[
    { ... },
    { ... }
]
choices

Player choices.

[
    { ... },
    { ... }
]

Empty array if no choices.

next_scene

Automatically loaded when no choices exist.

"next_scene": "intro_002"
Dialogue Object

Every dialogue entry uses:

{
    "speaker": "",
    "portrait": "",
    "expression": "",
    "text": "",
    "voice": "",
    "animation": "",
    "sound": "",
    "delay": 0,
    "auto_continue": false
}
Dialogue Fields
speaker
"speaker": "Amara"
portrait

Portrait resource name.

"portrait": "amara_normal"
expression

Portrait expression.

"expression": "worried"
text

Dialogue text.

"text": "Ethan is gone."
voice

Optional voice sound.

"voice": "amara_voice"
animation

Portrait animation.

"animation": "shake"

Examples

idle
shake
fade
slide_left
slide_right
zoom
sound

Optional SFX.

"sound": "door_close"
delay

Delay before dialogue advances automatically.

"delay": 1.5
auto_continue
true
false
Choice Object

Every choice uses:

{
    "id": "",
    "text": "",
    "next_scene": "",
    "track": "",
    "effects": {}
}
Choice Fields
id
"id": "call_police"
text
"text": "Call the Police"
next_scene
"next_scene": "intro_010"
track

Story branch identifier.

"track": "CALL_POLICE"

Possible values:

CALL_POLICE
TRACE_SIGNAL
GO_ALONE
effects

Optional gameplay effects resulting from the choice.

{
    "coins": 50,
    "lives": 1,
    "flags": [
        "police_contacted"
    ]
}
Metadata Object

Additional information about the story.

{
    "chapter": 1,
    "unlock_level": 1,
    "version": 1
}
Individual Story File Responsibilities
intro.json

Purpose

Opening cinematic
Introduce Amara, David, Ethan, and Victor
Present the player's first story choice
Transition into the tutorial levels

Contains

Initial kidnapping
Investigation setup
First branching decision
Links to tutorial gameplay
chapter01.json

Purpose

Story for Levels 6–20
Introduce evidence collection
Reveal Victor's organization
Continue branch-specific dialogue
Converge branches where appropriate

Contains

New locations
New suspects
Character development
Mid-chapter choices
Links between gameplay milestones
chapter02.json

Purpose

Story for Levels 21–49
Factory infiltration
Escalating danger
Preparation for the final rescue

Contains

Late-game cinematics
High-stakes dialogue
Final investigations
Pre-ending convergence
ending.json

Purpose

Final rescue of Ethan
Defeat of Victor
Resolution of all story branches
Credits transition

Contains

Final confrontation
Ending dialogue
Outcome scenes
Campaign completion
Credits trigger
Story Flow
intro.json
      │
      ▼
chapter01.json
      │
      ▼
chapter02.json
      │
      ▼
ending.json
Frozen Responsibilities
File	Responsibility
intro.json	Opening cinematic, tutorial introduction, first player choice
chapter01.json	Early investigation, new characters, branch progression
chapter02.json	Late-game story, infiltration, climax setup
ending.json	Final rescue, ending sequences, campaign completion

This freezes the JSON schema and responsibilities for every file under:

stories/

During Version 1, the story engine should read these files through the documented structure without requiring changes to the schema.