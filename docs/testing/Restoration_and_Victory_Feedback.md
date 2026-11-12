# Restoration input and victory bonuses

Restoration remains an earned side challenge: no permanent competing map button,
no campaign-life cost, and access through eligible case wins or an already-earned
opportunity in Case Rewards. Enjoyment still needs player feedback; the changes
below establish the intended complementary mechanics and visible rewards.

## Restoration

- Drag/swipe a fragment onto another to exchange them. Native primary-touch and
  mouse dragging are supported; two taps still work. Menus/reference overlays
  cannot initiate a gesture. An expired/completed attempt cannot accept a swap.
- Fragments animate across the board. Selection, swapping, correct placement
  and successful restoration use the existing action sounds; no previously
  approved sound assets were replaced.
- The configured base coin prize is still 15. An earned opportunity also gives
  its promised Rocket. A daily-stamp coin reward can be added if still eligible.
- Successful restoration adds 25 points per fragment: 225 for 3×3, 400 for 4×4,
  625 for 5×5. No points are farmed from repeated partial swaps. The points prize
  is stored in the new attempt and shown on completion.
- `campaign.restoration_points` is included in `campaign.total_points`, including
  after future case-score recalculations. Completed claims cannot pay again.

## Match 3 victory settlement

The stars are determined from the actual remaining moves before the presentation.
The board is then locked while the visible bonus counter runs:

1. Remaining moves count down in the HUD, at 100 points per move.
2. Saved board boosters fire separately in row-major order. Each receives its
   usual Rocket/Bomb/Thunder effects and sound; overlapping blasts preserve other
   saved boosters until their own turn.
3. Each booster gives 250 points plus 10 per ordinary tile it actually clears.
   Already cleared tiles cannot be counted again. These are score effects, not
   additional objective collections or character/inventory rewards.
4. The existing first-clear coin bonus remains five coins per saved booster,
   capped at 25. Replays do not repeatedly grant those first-clear coins.
5. The final bonus is shown, remaining tiles leave, and only then is the result
   card displayed. It includes the victory-bonus points; case totals/details are
   still available. Scores use the existing per-level best-record accounting.

Coefficients live in `configs/economy.json` under `victory_bonus`. The calculation
and presentation settle only once per attempt. Back cannot interrupt this brief
sequence; normal Back navigation resumes afterwards.

## Verification

`celebration_checks` passes 16 checks: real mouse drag, native touch swipe,
two-tap input, requested sound cues, actual restoration coins/points, duplicate
protection, future score retention, move/booster firing order, score persistence,
coin bonus, unchanged lives and final board clearing.

The existing mobile UI, progression/daily and story suites pass. Mobile checks
include the real restored-image reward with coins, points and Rocket on short
screens. A graphical run produced inspected samples at
`.test-data/celebration-rocket.png`, `celebration-thunder.png` and
`celebration-restoration-reward.png`. These are Godot desktop checks, not a claim
of physical-handset sound or touch validation.
