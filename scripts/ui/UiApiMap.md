scripts/ui/
UI System API Map (Version 1.0 Freeze)

The UI system is responsible only for presentation and user interaction. It never contains gameplay logic. Gameplay managers (GameManager, BoardManager, StoryManager, RewardManager, etc.) notify the UI through signals or public APIs.

51. HUD.gd
Purpose

Displays gameplay information while a level is running.

Initialization
initialize()
Moves
set_moves(value)

get_moves()

update_moves(value)
Score
set_score(value)

get_score()

add_score(points)

update_score(value)
Objectives
set_objectives(objectives)

update_objective(id, progress)

complete_objective(id)

get_objectives()
Economy
set_coins(value)

update_coins(value)

set_lives(value)

update_lives(value)

set_boosters(boosters)

update_booster(type, amount)
Powerups
show_powerup(type)

hide_powerup(type)

update_powerup_count(type, amount)
Utility
show_message(text)

clear_message()

show()

hide()

reset()
52. PauseMenu.gd
Purpose

Handles the in-game pause menu.

Initialization
initialize()
Visibility
show_menu()

hide_menu()

toggle()

is_visible()
Actions
resume_game()

restart_level()

open_settings()

return_to_menu()

quit_game()
Utility
reset()
53. VictoryScreen.gd
Purpose

Displays level completion information.

Initialization
initialize()
Results
show_results(result)

hide_results()

set_score(score)

set_stars(stars)

set_rewards(rewards)
Navigation
next_level()

replay_level()

return_to_menu()
Animation
play_open_animation()

play_close_animation()
Utility
reset()
54. GameOverScreen.gd
Purpose

Displays failure information.

Initialization
initialize()
Results
show_results(result)

hide_results()

set_reason(reason)

set_remaining_objectives(objectives)
Navigation
retry_level()

return_to_menu()

watch_reward_ad()

buy_extra_moves()
Animation
play_open_animation()

play_close_animation()
Utility
reset()
55. LoadingScreen.gd
Purpose

Displays loading progress during scene transitions.

Initialization
initialize()
Loading
start_loading()

finish_loading()

cancel_loading()

set_progress(percent)

get_progress()
Display
set_message(text)

show_spinner()

hide_spinner()
Utility
show()

hide()

reset()
56. UIManager.gd
Purpose

Coordinates every UI screen in the game.

Initialization
initialize()
HUD
show_hud()

hide_hud()

update_hud()
Screens
show_pause()

hide_pause()

show_victory(result)

hide_victory()

show_game_over(result)

hide_game_over()

show_loading()

hide_loading()
Popups
show_popup(name, data)

hide_popup(name)

close_all_popups()
Notifications
show_notification(text)

hide_notification()
Input
lock_input()

unlock_input()

is_input_locked()
Utility
reset()

shutdown()
Frozen Dependency Graph
HUD
 │
 ├──────────────┬──────────────┬──────────────┐
 ▼              ▼              ▼              ▼
PauseMenu  VictoryScreen  GameOverScreen  LoadingScreen
        │         │              │              │
        └─────────┴──────────────┴──────────────┘
                          │
                          ▼
                     UIManager
Responsibilities
File	Responsibility
HUD.gd	Displays gameplay information (moves, score, objectives, coins, lives, boosters)
PauseMenu.gd	Handles the pause menu
VictoryScreen.gd	Displays level completion results and rewards
GameOverScreen.gd	Displays failure results and retry options
LoadingScreen.gd	Displays loading progress during scene transitions
UIManager.gd	Coordinates every UI screen and popup
UI Features Supported

The frozen API supports:

Gameplay HUD
Pause menu
Victory screen
Game over screen
Loading screen
Popups
Notifications
Reward displays
Input locking
UI transitions
Screen management

No gameplay logic should be implemented in these UI classes. They should only display information provided by the game's managers.

This freezes the public API for every file under:

scripts/ui/