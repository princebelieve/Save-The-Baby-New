scripts/economy/
Economy System API Map (Version 1.0 Freeze)
Purpose

The Economy System owns every persistent player-owned gameplay resource.

It performs economy operations only.

It never coordinates gameplay progression.

Gameplay coordination belongs to EconomyManager.

Reward calculation belongs to RewardManager.

Configuration comes from ConfigLoader.

Time calculations come from TimeHelper.

Communication occurs through SignalBus.

The Economy System therefore acts as the gameplay engine underneath EconomyManager.

Folder Structure
scripts/
└── economy/
    ├── PlayerInventory.gd
    ├── LifeSystem.gd
    ├── BoosterInventory.gd
    ├── EthanInventory.gd
    ├── Shop.gd
    ├── Purchase.gd
    ├── EconomyValidator.gd
    └── EconomyAnimator.gd
1. PlayerInventory.gd
Purpose

Stores every persistent player-owned resource except lives.

Owns only player inventory.

Contains no gameplay progression.

Contains no shop logic.

Contains no reward calculation.

Contains no save logic.

Loaded and saved through SaveManager.

Public API
Initialization
initialize()

reset()

clear()
Coins
add_coins(amount)

remove_coins(amount)

set_coins(amount)

get_coins()

has_coins(amount)
Stars
add_stars(amount)

remove_stars(amount)

set_stars(amount)

get_stars()

has_stars(amount)
Premium Currency
add_gold_bars(amount)

remove_gold_bars(amount)

set_gold_bars(amount)

get_gold_bars()

has_gold_bars(amount)

(Version 1 may simply remain at zero.)

Utility
duplicate_inventory()
Internal
_coins

_stars

_gold_bars
2. LifeSystem.gd
Purpose

Owns player lives.

Calculates regeneration.

Owns unlimited-life sessions.

Uses TimeHelper.

Contains no reward logic.

Contains no UI logic.

Public API
Initialization
initialize()

reset()
Lives
add_life(amount)

lose_life(amount)

set_lives(amount)

get_lives()

restore_full_lives()

has_lives()

is_full()
Unlimited Lives
start_unlimited_lives(duration)

stop_unlimited_lives()

has_unlimited_lives()

remaining_unlimited_time()
Regeneration
update()

restore_regenerated_lives()

seconds_until_next_life()
Internal
_current_lives

_last_regeneration_time

_unlimited_timer
3. BoosterInventory.gd
Purpose

Stores every booster owned outside gameplay.

It owns inventory only.

Powerup behaviour belongs to the Powerup System.

Public API
Initialization
initialize()

reset()
Inventory
add_booster(type,amount)

remove_booster(type,amount)

use_booster(type)

get_booster_count(type)

has_booster(type)

get_all_boosters()

clear()
Internal
_boosters
4. EthanInventory.gd
Purpose

Owns every persistent Ethan resource.

This class exists because Ethan is a unique gameplay mechanic rather than a standard booster.

It stores Ethan ownership and availability.

It never performs Ethan board mechanics.

Those belong to the Tile and Board systems.

It never performs reward calculation.

Public API
Initialization
initialize()

reset()
Inventory
add_ethan(amount)

remove_ethan(amount)

use_ethan()

get_ethan_count()

has_ethan()
Suggestions
can_suggest_ethan()

mark_suggestion_shown()

reset_suggestion()
Internal
_ethan_count

_suggestion_shown
5. Shop.gd
Purpose

Provides shop catalogue lookups.

Uses configs/economy.json.

Never deducts currency.

Never grants rewards.

Never modifies inventory.

Public API
Initialization
initialize()

reload()
Lookup
get_item(id)

has_item(id)

get_price(id)

get_currency(id)

get_category(id)

get_all_items()
Internal
_shop_cache
6. Purchase.gd
Purpose

Represents one purchase transaction.

Contains data only.

Contains no gameplay logic.

Public API
Initialization
initialize()
Data
set_item(id)

get_item()

set_currency(currency)

get_currency()

set_price(price)

get_price()

set_quantity(quantity)

get_quantity()
Internal
_item

_currency

_price

_quantity
7. EconomyValidator.gd
Purpose

Validates economy operations.

Never changes inventory.

Never performs purchases.

Never grants rewards.

Public API
initialize()

can_afford(inventory,purchase)

can_use_booster(inventory,type)

can_use_ethan(inventory)

can_lose_life(life_system)

validate_purchase(purchase)

validate_inventory(inventory)
Internal
None
8. EconomyAnimator.gd
Purpose

Owns every animation affecting the player's economy.

AnimationManager decides when economy animations execute.

EconomyAnimator implements how they are performed.

Uses the reusable animation framework from scripts/animation/.

Contains no gameplay logic.

Contains no reward logic.

Contains no UI flow.

Public API
Initialization
initialize()
Currency
play_coin_gain()

play_coin_spend()

play_star_gain()

play_gold_bar_gain()
Lives
play_life_gain()

play_life_loss()

play_unlimited_lives_start()

play_unlimited_lives_end()
Boosters
play_booster_gain(type)

play_booster_use(type)
Ethan
play_ethan_gain()

play_ethan_use()

play_ethan_suggestion()
Shop
play_purchase_success()

play_purchase_failed()
Utility
stop(target)

stop_all()

pause(target)

resume(target)

is_playing(target)

wait_until_finished(target)
Internal
_execute(request)

_complete(request)
Frozen Economy System Dependencies
                  EconomyManager
                        │
        ┌───────────────┼────────────────────┐
        ▼               ▼                    ▼
 PlayerInventory   LifeSystem      BoosterInventory
        │               │                    │
        │               │                    ▼
        │               │             EthanInventory
        │               │                    │
        └───────────────┼────────────────────┘
                        │
                        ▼
               EconomyValidator
                        │
                 ┌──────┴──────┐
                 ▼             ▼
              Shop        Purchase

AnimationManager
        │
        ▼
EconomyAnimator

ConfigLoader
ResourceManager
TimeHelper
SignalBus
Version 1 Rules

The Economy System owns persistent player resources only.

EconomyManager coordinates the Economy System.

RewardManager determines what the player earns and when it is earned.

The Economy System stores, validates, consumes, regenerates, and spends those resources.

PlayerInventory owns Coins, Stars, and future premium currencies.

LifeSystem owns lives, regeneration, and unlimited-life timers.

BoosterInventory owns booster inventory only. Booster behaviour belongs to the Powerup System.

EthanInventory owns Ethan as a unique persistent gameplay resource. Ethan gameplay effects (such as granting an extra move or an extra life when matched according to your game rules) belong to the Board/Tile gameplay systems, while obtaining, storing, consuming, and suggesting Ethan belong to the Economy System.

Shop provides shop metadata loaded from configs/economy.json.

Purchase is a data object only.

EconomyValidator validates economy operations without modifying player resources.

EconomyAnimator owns only economy-related animations. AnimationManager decides when they run, and the reusable framework in scripts/animation/ provides the scheduling infrastructure.

The Economy System may depend on Constants, SignalBus, ConfigLoader, ResourceManager, TimeHelper, and the reusable animation framework.

The Economy System must not coordinate board mechanics, tile mechanics, powerup behaviour, obstacle behaviour, reward calculation, story progression, save operations, UI flow, or gameplay progression.