# Gameplay flow review ? 18 November 2026

Implemented source changes (no Android build):
- Chains and locks anchor captive tiles; tape is a flowing coating; other hazards occupy cells without a hidden tile.
- Gravity descends vertically and diagonally into available cells without crossing anchored blockers.
- Refill supplies only authored inlets, or exposed column tops, rather than manufacturing tiles in sealed pockets.
- Shuffle preserves trapped tiles. Blocker overlays are more visible.
- Falling animations follow recorded cell paths with distance-based timing. Existing transition-cue mix and repeated impact variation remain.

Validation:
- flow_checks: zero failures, including sealed pockets, reopening supply, diagonal flow, solid hazards and tape.
- release_checks: zero failures (before final exposed-edge source adjustment); action_audio_checks: 105 checks, zero failures.
- Structural supply audit: all 1,050 level layouts can receive supply after blockers clear. This is not a solvability proof.
- Twelve sampled levels, three move policies: zero technical failures. Level 16 initially appeared to fail because the bot counted a destruction objective as collection; correcting the bot yielded 3/3 wins. Other sampled levels yielded 33/33 wins.

Outstanding:
- Difficulty is still too forgiving in this sample. No blanket health/move-budget retuning has been applied.
- Full phone visual/audio verification and wider difficulty calibration remain.
- The difficulty_checks campaign fixture failed at scout-supply selection and must be repaired before claiming that suite passes.

Reports: .test-data/campaign-flow-audit.json, .test-data/final-flow-playtest.json, .test-data/flow-destroy-objective.json.

## Event music implementation
Six original 96 BPM arrangements now cover investigation, play, low-move pressure, restoration, victory and setback. New music crossfades over 0.65 seconds. Repeated state notifications do not restart the current track. Shared dialogs emit open/close cues, with additional game-screen hooks. Generated WAV files have phrase-length loops and peak headroom; this is a first arrangement/mix pass, not a claim of finished mastering or verified cue coverage for every screen. Source: tools/generate_adaptive_music.py. Phone listening, remaining screen coverage and difficulty progression calibration are still outstanding.

## Continued progression and audio pass
- tools/rebalance_campaign.py applies staged, idempotent tuning to levels 21?1050. Opening lessons 1?20 are preserved. Later hard cases reinforce up to three existing one-hit blockers; early cases introduce reinforcement gradually. Easy cases retain one-hit layouts. Move reductions are bounded to 0?3; geometry and objective counts are preserved. Run this tool after materializing new campaign content.
- Fixed refill type selection to avoid accidental matches at settled destinations, rather than testing only the inlet. Natural cascades from existing falling tiles remain.
- Final sample: 12 levels x 3 play policies, 32/36 wins, zero technical failures; every sampled level has at least one free win. This is not human win-rate calibration or proof all levels are solvable.
- Difficulty suite: 93 checks, zero failures. Corrected its chapter/story fixture and separated single-hit seal tests from authored reinforced health.
- Screen layer lifecycle now supplies entry/exit cues, including replacements and Back. Shared dialogs cover popup, hide and visible destruction. Musical arrangements retain phrase position on state changes; obsolete fades are cleaned up. Both active/fading tracks respect background pause; voice ducking covers both.
- Master hard limiter ceiling: -1 dB. Final mastering, every-screen phone review and human difficulty testing remain pending. No Android build was started.

## Level 68 continuation regression — 19 November 2026
Godot-only reproduction follows level 67 result ? restoration result ? level 68 briefing ? Play. Normal continuation passed. Injecting a leftover paused state reproduced an unresponsive board after Play; _begin_level now clears that state and removes old pause UI, and briefings process while paused so Play can recover. The regression failed before the fix and passes afterward, including accepting and settling a real level-68 swap. Test: tests/continuation_checks.tscn. No phone interaction or Android build was used for this fix; the installed APK does not yet contain it.


## Play-screen correction — 19 November 2026
The earlier regression emitted the pressed signal and therefore did not prove hit-testing worked. The revised Godot test awaits the real victory result, follows restoration continuation, issues duplicate briefing requests, then injects mouse press/release at the visible Play button. Before the correction, a stale briefing remained over the running level. Afterward, one click removes the briefing, enters level 68 and accepts/settles a real swap. _show_level_briefing now replaces its previous instance immediately; _begin_level clears pending story navigation before end_story can re-enter the briefing. This reproduces a UI failure condition, but the exact initiating callback sequence on the user's phone has not been observed. No phone testing or rebuild was used.

