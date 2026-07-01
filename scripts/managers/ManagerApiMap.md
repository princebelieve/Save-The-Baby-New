scripts/managers/
Manager System API Map (Version 1.0 Freeze)

The manager layer coordinates every major gameplay subsystem.

Managers communicate through SignalBus, use helper classes from utilities, and coordinate specialized classes in their respective folders.

No manager should perform another manager's responsibility.

Initialization Contract

Each manager exposes an initialize() method for setup of its internal state.

Managers do not define or control application startup flow.

Managers do not depend on a specific startup orchestrator.

Initialization timing is handled by the scene or system that instantiates the managers.

1. GameManager.gd
   Purpose

Owns the overall game lifecycle and global game state.

Public Signals
game_started

game_paused

game_resumed

game_restarted

game_quit

game_state_changed(previous_state,current_state)
Public API
initialize()

start_game()

pause_game()

resume_game()

restart_game()

quit_game()

set_state(state)

get_state()

is_state(state)

is_game_running()

is_game_paused()

reset_game()
Internal
\_current_state

\_is_initialized

2. BoardManager.gd
   Purpose

Owns board creation and gameplay flow.

Coordinates the board subsystem.

Public Signals
board_created

board_ready

board_locked

board_unlocked

board_cleared
Public API
initialize()

create_board(level_data)

clear_board()

reset_board()

lock_board()

unlock_board()

is_board_locked()

get_board()

get_tile(position)

swap_tiles(tile_a,tile_b)

refill_board()

update_board()

is_board_stable()
Internal
\_board

\_board_locked

3. LevelManager.gd
   Purpose

Loads levels and controls level progression.

Public Signals
level_loading(level)

level_loaded(level)

level_started(level)

level_completed(level)

level_failed(level)
Public API
initialize()

load_level(level_id)

reload_level()

start_level()

complete_level()

fail_level()

next_level()

previous_level()

current_level()

get_level_data()

is_last_level()
Internal
\_current_level

\_level_data

4. RewardManager.gd
   Purpose

Calculates and grants all rewards.

Public Signals
reward_granted(data)

reward_collected(data)
Public API
initialize()

calculate_level_rewards(result)

calculate_bonus_rewards(result)

grant_rewards(reward_data)

grant_daily_reward()

grant_story_reward()

grant_chest_reward()

preview_rewards(level)

claim_rewards()

clear_pending_rewards()
Internal
\_pending_rewards

5. StoryManager.gd
   Purpose

Controls story progression.

Public Signals
story_started(id)

dialogue_started(id)

dialogue_finished(id)

choice_selected(choice)

story_finished(id)
Public API
initialize()

load_story(id)

start_story(id)

play_dialogue(dialogue)

present_choices(choices)

select_choice(choice)

next_dialogue()

skip_story()

end_story()

story_progress()
Internal
\_current_story

\_current_dialogue

6. AudioManager.gd
   Purpose

Controls all game audio.

Public Signals
music_changed(track)

music_finished

sound_played(sound)
Public API
initialize()

play_music(track)

stop_music()

pause_music()

resume_music()

play_sfx(sound)

stop_sfx(sound)

set_master_volume(value)

set_music_volume(value)

set_sfx_volume(value)

mute()

unmute()
Internal
\_music_player

\_sfx_players

7. SaveManager.gd
   Purpose

Owns all player save data.

Public Signals
save_requested

save_completed

save_failed

load_requested

load_completed

load_failed
Public API
initialize()

new_game()

save_game()

load_game()

auto_save()

delete_save()

save_exists()

export_save(path)

import_save(path)

get_save_data()

set_save_data(data)
Internal
\_save_data

\_save_path

8. UIManager.gd
   Purpose

Controls all UI screens and popups.

Public Signals
popup_opened(name)

popup_closed(name)

hud_updated
Public API
initialize()

show_screen(name)

hide_screen(name)

show_popup(name,data={})

hide_popup(name)

update_hud()

show_notification(text)

show_loading()

hide_loading()
Internal
\_current_screen

\_open_popups

9. AnimationManager.gd
   Purpose

Coordinates game animations.

Public Signals
animation_started(name)

animation_finished(name)
Public API
initialize()

play(name,target)

stop(target)

stop_all()

pause_all()

resume_all()

is_playing(target)

wait_for_animation(target)
Internal
\_active_animations

10. EconomyManager.gd
    Purpose

Owns the player's economy.

Public Signals
coins_changed(coins)

lives_changed(lives)

boosters_changed(boosters)

stars_changed(stars)
Public API
initialize()

add_coins(amount)

remove_coins(amount)

get_coins()

add_life(amount=1)

lose_life(amount=1)

get_lives()

restore_full_lives()

start_unlimited_lives(duration)

has_unlimited_lives()

add_booster(type,amount)

use_booster(type)

get_booster_count(type)

add_stars(amount)

get_stars()

can_afford(cost)

purchase(cost)

update_life_timer()
Internal
\_coins

\_lives

\_stars

\_boosters

\_unlimited_lives_timer
Relationships
GameManager
│
┌──────────────┼──────────────┐
│ │ │
LevelManager BoardManager StoryManager
│ │ │
├──────────────┼──────────────┤
│ │ │
RewardManager EconomyManager SaveManager
│ │ │
└──────────────┼──────────────┘
│
UIManager
│
AnimationManager
│
AudioManager
Version 1 Rules
Every gameplay subsystem has one coordinating manager.
Managers communicate through SignalBus rather than direct dependencies whenever practical.
Managers may call utility classes (JsonLoader, RandomGenerator, FileHelper, etc.) but utilities never manage gameplay.
Managers coordinate the specialized scripts within their corresponding folders but do not duplicate their responsibilities.
Managers should not contain hardcoded level, story, reward, or configuration data; those come from JSON/configuration files.
This API map defines the complete public surface of the scripts/managers/ folder for Version 1. Subsequent folder APIs (board, economy, story, save, animation, UI, etc.) should be designed to work under these managers without requiring changes to the manager interfaces.
