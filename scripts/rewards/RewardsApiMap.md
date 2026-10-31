scripts/reward/
Reward System API Map (Version 1.0 Freeze)
Purpose

The Reward System is responsible for calculating, validating, organizing, and preparing every reward that can be granted during gameplay.

It performs no UI presentation.

It performs no economy updates directly.

It performs no save operations.

It performs no gameplay progression.

RewardManager coordinates the subsystem and grants the finalized rewards.

Reward data originates from configs/rewards.json.

Folder Structure
scripts/reward/

RewardCalculator.gd
RewardTable.gd
RewardValidator.gd
RewardDistributor.gd
RewardQueue.gd
RewardFactory.gd
RewardPreview.gd
RewardData.gd
1. RewardCalculator.gd
Purpose

Calculates rewards earned from gameplay.

Contains no reward tables.

Contains no UI.

Contains no economy logic.

Uses RewardTable to retrieve configuration data.

Public API
initialize()

calculate_level_rewards(result)

calculate_special_move_rewards(kind, created_count)

calculate_bonus_rewards(result)

calculate_story_rewards(story_id)

calculate_daily_reward()

calculate_chest_reward(chest_id)

calculate_reward_set(type,data)
Internal
_reward_table
_validator
2. RewardTable.gd
Purpose

Provides access to reward definitions stored inside

configs/rewards.json

Performs no calculations.

Performs no randomness.

Public API
initialize()

reload()

get_level_rewards(level)

get_star_rewards(stars)

get_daily_reward()

get_story_reward(id)

get_chest_reward(id)

get_bonus_rewards()

get_random_pool(pool)

has_reward(id)
Internal
_reward_config
3. RewardValidator.gd
Purpose

Validates reward definitions before they are granted.

Ensures rewards are legal.

Performs no economy updates.

Public API
initialize()

validate_reward(reward)

validate_reward_list(rewards)

validate_reward_type(type)

validate_amount(type,amount)

is_claimable(reward)
Internal
_validation_rules
4. RewardDistributor.gd
Purpose

Converts validated rewards into economy operations.

Does not own player inventory.

Does not calculate rewards.

RewardManager calls this class after calculation.

Public API
initialize()

grant_reward(reward)

grant_rewards(rewards)

grant_special_move(kind, created_count)

grant_coins(amount)

grant_stars(amount)

grant_lives(amount)

grant_booster(type,amount)

grant_custom_reward(data)
Internal
_economy_manager
5. RewardQueue.gd
Purpose

Stores rewards waiting to be claimed.

Contains no calculations.

Contains no UI.

Public API
initialize()

add(reward)

add_multiple(rewards)

claim()

claim_all()

peek()

clear()

is_empty()

count()
Internal
_pending_rewards
6. RewardFactory.gd
Purpose

Creates standardized RewardData objects.

Ensures all rewards share the same structure.

Performs no calculations.

Public API
create_reward(type,amount)

create_coin_reward(amount)

create_star_reward(amount)

create_life_reward(amount)

create_booster_reward(type,amount)

create_custom_reward(data)
7. RewardPreview.gd
Purpose

Creates preview data for UI.

Never grants rewards.

Never modifies economy.

Public API
initialize()

preview_level_rewards(level)

preview_daily_reward()

preview_story_reward(id)

preview_chest_reward(id)

preview_reward_set(rewards)
8. RewardData.gd
Purpose

Represents one reward.

Pure data container.

Contains no gameplay logic.

Properties
type

id

amount

metadata

claimable

source

icon
Public API
duplicate()

to_dictionary()

from_dictionary(data)
Frozen Reward System Relationships
                  RewardManager
                        │
      ┌─────────────────┼─────────────────┐
      ▼                 ▼                 ▼
RewardCalculator   RewardPreview   RewardQueue
      │
      ▼
RewardTable
      │
      ▼
configs/rewards.json

RewardCalculator
      │
      ▼
RewardValidator
      │
      ▼
RewardFactory
      │
      ▼
RewardDistributor
      │
      ▼
EconomyManager
Reward Flow
Level Completed
        │
        ▼
RewardManager
        │
        ▼
RewardCalculator
        │
        ▼
RewardTable
        │
        ▼
RewardValidator
        │
        ▼
RewardFactory
        │
        ▼
RewardQueue
        │
        ▼
RewardManager.claim_rewards()
        │
        ▼
RewardDistributor
        │
        ▼
EconomyManager
Version 1 Rules
RewardManager is the only coordinator of the Reward System.
RewardCalculator performs all reward calculations but never grants rewards.
RewardTable is the only reader of reward definitions loaded from configs/rewards.json.
RewardValidator validates every reward before it can be queued or granted.
RewardFactory creates standardized RewardData objects and contains no gameplay logic.
RewardQueue stores pending rewards awaiting collection and performs no calculations.
RewardPreview generates reward previews for the UI without granting rewards.
RewardDistributor converts validated rewards into EconomyManager operations but never performs calculations.
RewardData is a pure data object containing reward information only.
Reward definitions are never hardcoded and must originate from configs/rewards.json.
The Reward System performs no UI presentation, save operations, story progression, or gameplay flow control; those responsibilities belong to their respective managers and subsystems.

This API map follows the same architectural pattern as your existing Board, Economy, and Animation subsystem maps and matches the responsibilities exposed by the frozen RewardManager API without requiring any changes to that manager interface.
