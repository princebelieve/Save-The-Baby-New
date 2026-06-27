scripts/story/
Story System API Map (Version 1.0 Freeze)

The story system is completely data-driven. No dialogue, choices, backgrounds, portraits, sounds, or scene flow are hardcoded. Everything is loaded from the JSON files in stories/.

The StoryManager coordinates the system, while the other classes each have a single responsibility.

47. DialoguePlayer.gd
Purpose

Displays dialogue one line at a time.

Initialization
initialize()
Dialogue Loading
load_dialogue(dialogue_data)

start()

stop()

restart()
Navigation
next_line()

previous_line()

skip()

is_finished()
Current State
get_current_line()

get_current_index()

get_total_lines()

has_next_line()
Display
show_line(line_data)

hide()

clear()
Utility
reset()
48. PortraitManager.gd
Purpose

Controls character portraits shown during dialogue.

Initialization
initialize()
Portrait Control
show_character(character)

hide_character(character)

change_expression(character, expression)

set_position(character, position)

flip(character, enabled)
Animation
play_animation(character, animation_name)

stop_animation(character)
Utility
clear()

reset()
49. ChoiceManager.gd
Purpose

Handles dialogue choices.

Initialization
initialize()
Choices
show_choices(choice_list)

hide_choices()

select_choice(choice_id)

cancel_choice()
State
has_choices()

get_selected_choice()

get_choice_result(choice_id)
Utility
clear()

reset()
50. StoryManager.gd
Purpose

Coordinates the entire story system.

Initialization
initialize()
Story Loading
load_story(story_id)

load_scene(scene_id)

reload_scene()
Playback
start_story()

continue_story()

pause_story()

resume_story()

end_story()

skip_story()
Navigation
goto_scene(scene_id)

goto_next_scene()

goto_previous_scene()
Progress
record_choice(choice_id)

get_story_progress()

set_story_progress(progress)

is_story_finished()
Integration
play_dialogue(dialogue_data)

show_portraits()

show_choices()

notify_gameplay_start()

notify_story_finished()
Utility
reset()

shutdown()
Frozen Dependency Graph
DialoguePlayer
        │
        ├──────────────┐
        ▼              ▼
PortraitManager   ChoiceManager
        │              │
        └──────┬───────┘
               ▼
         StoryManager
Responsibilities
File	Responsibility
DialoguePlayer.gd	Plays dialogue line by line
PortraitManager.gd	Displays and animates character portraits
ChoiceManager.gd	Presents dialogue choices and records selections
StoryManager.gd	Loads stories, coordinates dialogue, portraits, and choices
Story Flow Supported

The frozen API supports:

Loading story JSON
Loading scenes
Dialogue playback
Character portraits
Facial expressions
Character animations
Dialogue choices
Story branching
Story progress tracking
Scene transitions
Skipping story
Returning control to gameplay

No dialogue or story logic should be hardcoded outside these APIs.