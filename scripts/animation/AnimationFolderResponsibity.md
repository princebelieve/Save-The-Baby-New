scripts/animation/

Purpose

Provides the reusable animation framework used by every gameplay subsystem.

It contains no gameplay-specific animations.

It does not know what a tile, obstacle, story character, popup, or powerup is.

It provides scheduling, sequencing, requests, and shared tween utilities.

AnimationQueue.gd

Purpose

Owns the queue of pending animations.

Example responsibilities

enqueue(animation)
dequeue()
clear()
has_pending()
is_empty()
AnimationSequence.gd

Purpose

Represents a sequence of animations that must play in order.

Example

Swap

↓

Destroy

↓

Fall

↓

Spawn

↓

Cascade

AnimationManager executes the sequence.

AnimationRequest.gd

Purpose

Represents a single animation request.

Instead of passing many parameters everywhere,

AnimationManager creates

AnimationRequest

containing

animation name
target
duration
delay
callback
priority

Then AnimationManager dispatches the request to the appropriate subsystem animator, which performs the animation.

TweenHelper.gd

Purpose

Reusable helper around Godot Tweens.

Contains reusable tween creation.

Examples

move()

fade()

scale()

rotate()

shake()

bounce()

flash()

No gameplay knowledge.

AnimationLibrary.gd

Purpose

Central registry of animation names.

Example

tile_spawn

tile_swap

tile_destroy

popup_open

popup_close

reward_collect

story_transition

No animation code.

Only names/lookup/default durations.

Then each subsystem owns HOW animations happen.

Example

TileAnimator

implements

play_spawn()

play_swap()

play_destroy()

play_fall()
ObstacleAnimator

implements

play_break()

play_damage()

play_unlock()
UIAnimator

implements

play_popup()

play_button_press()

play_notification()
StoryAnimator

implements

play_portrait_enter()

play_dialogue()

play_scene_transition()
AnimationManager becomes very clean

AnimationManager becomes only the coordinator.

play()

↓

create AnimationRequest

↓

Queue request

↓

execute request

↓

wait

↓

emit animation_finished

It never knows how a tile explodes.

It only knows that

"play tile_destroy on this tile."

The TileAnimator performs it.

This also aligns perfectly with your architecture

Your architecture already establishes this pattern:

Managers coordinate.
Subsystems implement.
Utilities provide reusable services.

The scripts/animation/ folder fits naturally as the reusable animation infrastructure between AnimationManager and the subsystem-specific animators.

So I would freeze the responsibilities as:

AnimationManager → decides when animations run.
scripts/animation/ → provides the generic animation framework (queueing, sequencing, requests, tween helpers, animation registry).
TileAnimator, PowerupAnimator, ObstacleAnimator, UIAnimator, StoryAnimator → implement how animations are performed for their own subsystem.

I think this is the cleanest design because every folder ends up with a distinct responsibility, and no two folders overlap.