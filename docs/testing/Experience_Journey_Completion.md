# Five-stage experience update

Completed in the requested order on 12 November 2026. This extends the earlier
first implementation; it is not another proposal awaiting approval.

## 1. Illustrated chapter and season transitions

`ChapterTransition.gd` presents the authored chapter title, season title where
available, location illustration and short rescue hook. Continue and Skip both
enter the selected case's existing story/briefing path. Each chapter introduction
is remembered in the campaign save. Locked chapters cannot be entered through
this screen. Back returns to the map, including when arriving from a completed
case rather than from an existing map. There are no new calendar expirations.

## 2. Rewards from normal play

The existing daily tasks now also earn supplies: creating two specials awards a
Rocket; clearing three blockers awards a life. Existing task coins still award
automatically. Field objectives displays progress and the prizes. Case Rewards
shows earned claims, one prize at a time so an accumulated queue cannot overflow
the phone. Claims update the inventory and consumed marker in the same saved
progress operation. A full life inventory leaves the life reward unclaimed and
explains why; unclaimed prizes survive daily resets. Duplicate claims do not pay.

The separate earned restoration opportunity continues to award its promised
Rocket and coins. Normal-play rewards do not require opening the restoration
game, spending a life, watching an ad or buying supplies.

## 3. Victory, failure and daily rewards

Results show illustrated reward amounts or remaining lives instead of the long
statistics paragraph. Case reward and daily-stamp reward are labeled separately.
Full points, narrative outcome and totals remain behind Case summary. Next Case
or Retry has the primary accent; result navigation remains outside the scrollable
summary. Paid/ad continues retain their existing actual conditions and rewards.
The daily page shows a seven-position stamp card, illustrated coin amount, a
short current task and a main route back to investigation. Previewing another
day does not claim or award it.

## 4. Shared presentation

`MobileGameUI` supplies the common Baloo lettering, palette, reward tile,
rounded button styles, focus/pressed states, click cue and short entrance fade.
Chapter, rewards, restoration, result and existing menu buttons use these
components. Screen entrances use existing audio cues; no downloaded replacement
sounds were added. Dynamic result-card fitting responds to viewport changes.
Functional coaching retains its readable immediate text and the existing help
preferences. Story dialogue and legal documents retain their appropriate roles.

## 5. Phone-layout walkthrough and regression checks

`tests/journey_checks.tscn` exercises chapter entry through real pointer input,
the first coaching acknowledgement and a real guided board swap, normal-play
task completion, Rocket/life claims, full-life deferral, reward carryover, failure
through gameplay's zero-move evaluator, result re-entry, and save/relaunch state.
Victory presentations use a seeded completed-result state; this does not claim
that a human solved each sampled case. Other established suites cover board
generation, booster tutorials, story progression and restoration's actual solve.

The graphical run captures chapter, daily, task, prize, victory and failure
screens at 320×568, 360×640, 390×844 and 412×915, plus 360×550. Godot scales its
720-wide logical canvas to those windows. Touch targets and viewport bounds are
checked. Captures under `.test-data/journey-*.png` were visually inspected.
This is a desktop Godot phone-layout playthrough, not a physical Android handset
or APK validation, and it cannot establish children's subjective enjoyment.

Problems found and corrected during the walkthrough:

- A task's progress fill was visually indistinguishable from its track.
- Case and stamp coin payouts needed separate visible captions.
- The daily/task screens initially overflowed the short phone.
- A result card's initial minimum height did not adapt after resizing smaller.
- Leaving a chapter introduction reached from Next Case needed to restore the
  map rather than expose the now-cleared board.

Validation logs are under `.test-data/`: journey, experience, mobile UI, economy,
progression/daily, character/booster, story, release and action-audio checks.
Final results: journey 244 checks; experience 63; mobile UI 1,314; character/booster
1,248; story 10,679; action audio 105 — all with zero failures. Economy,
progression/daily (including 1,000 level files/boards), and release suites also
reported zero failures. Run the new suite with
`powershell -ExecutionPolicy Bypass -File tools/run_checks.ps1 -Suite journey_checks`.
The existing certificate-store diagnostic and intentional malformed-save recovery
diagnostic are unrelated to this update. No live backend deployment is required
for these local Godot changes.
