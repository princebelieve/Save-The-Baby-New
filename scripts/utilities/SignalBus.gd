extends Node

# --------------------------------------------------
# SignalBus.gd
#
# Version 1.0
#
# Central event hub.
#
# Managers communicate through SignalBus instead of
# directly referencing one another whenever practical.
#
# Contains no gameplay logic.
# Contains no runtime state.
# Contains only global project signals.
# --------------------------------------------------

# ==================================================
# Game
# ==================================================

signal game_started
signal game_paused
signal game_resumed
signal game_restarted
signal game_quit
signal game_state_changed(previous, current)

# ==================================================
# Level
# ==================================================

signal level_loading(level_id)
signal level_loaded(level_data)
signal level_started(level_id)
signal level_completed(level_id)
signal level_failed(level_id)
signal next_level_requested

# ==================================================
# Board
# ==================================================

signal board_creating(level_data)
signal board_created
signal board_ready
signal board_locked
signal board_unlocked
signal board_shuffled
signal board_stable
signal board_cleared

# ==================================================
# Input
# ==================================================

signal swipe_started(tile)
signal swipe_completed(from_tile, to_tile)
signal swipe_cancelled(tile)

# ==================================================
# Tile
# ==================================================

signal tile_swapped(tile_a, tile_b)
signal tile_swap_rejected(tile_a, tile_b)
signal tile_spawned(tile)
signal tile_falling(tile)
signal tile_landed(tile)
signal tile_destroyed(tile)

# ==================================================
# Match
# ==================================================

signal match_found(match)
signal matches_found(matches)
signal cascade_started
signal cascade_finished
signal gravity_started
signal gravity_finished
signal refill_started
signal refill_finished

# ==================================================
# Powerups
# ==================================================

signal powerup_created(powerup)
signal powerup_activated(powerup)
signal powerup_combined(first, second)
signal powerup_finished(powerup)

# ==================================================
# Obstacles
# ==================================================

signal obstacle_damaged(obstacle)
signal obstacle_destroyed(obstacle)

# ==================================================
# Objectives
# ==================================================

signal objective_progress(type, amount)
signal objective_completed(type)
signal objective_failed(type)
signal all_objectives_completed

# ==================================================
# Score
# ==================================================

signal score_added(points)
signal score_changed(score)

# ==================================================
# Moves
# ==================================================

signal move_used(moves)
signal moves_changed(moves)

# ==================================================
# Economy
# ==================================================

signal coins_changed(coins)
signal stars_changed(stars)
signal lives_changed(lives)
signal boosters_changed(boosters)
signal life_restored
signal unlimited_lives_started
signal unlimited_lives_finished

# ==================================================
# Story
# ==================================================

signal story_started(id)
signal story_choice_presented(choices)
signal choice_selected(choice)
signal dialogue_started(id)
signal dialogue_finished(id)
signal story_finished(id)

# ==================================================
# Rewards
# ==================================================

signal reward_granted(data)
signal reward_collected(data)
signal daily_reward_claimed
signal chest_opened(id)

# ==================================================
# Save
# ==================================================

signal save_requested
signal save_completed
signal save_failed
signal load_requested
signal load_completed(data)
signal load_failed

# ==================================================
# Audio
# ==================================================

signal play_music(track)
signal stop_music
signal music_changed(track)
signal music_finished
signal play_sfx(sound)

# ==================================================
# Animation
# ==================================================

signal animation_started(name)
signal animation_finished(name)

# ==================================================
# UI
# ==================================================

signal hud_updated
signal popup_requested(name, data)
signal popup_closed(name)

# ==================================================
# Debug
# ==================================================

signal debug_message(message)
signal error_occurred(message)