# Level 48 and swap regressions

Run in an isolated save profile:

```powershell
powershell -ExecutionPolicy Bypass -File tools/run_checks.ps1 -Suite level48_checks
```

The report is written to `.test-data/level48-report.json`, including the seed,
move sequence, collected timestamps, remaining blockers, and outcome of each run.

The authored level remains unchanged: 24 moves, 30 timestamps, and eight blockers.
The goal-aware diagnostic solver won 10 of 12 runs with seeds 48000–48011 and no
inventory boosters. This demonstrates winning routes; it is not a human win-rate
estimate. The survey skips presentation delays while retaining production move,
blast, collection, cascade, gravity, refill, and blocker-damage rules.

Regression checks also exercise the real game HUD:

- A rocket crossing eight timestamp tiles adds eight to the objective.
- A mixed blast containing one timestamp adds one. Other tile types do not count
  toward the timestamp objective.
- A long swipe moves one cell in its direction instead of attempting to jump to
  the release cell.
- Refilled tiles cannot draw above existing blockers. Blocked swaps remain
  invalid and report the blocker as the reason.
- Move validation leaves live tile positions unchanged.

The persistent hint text previously covering the top board row has been replaced
with a short, readable rejection notice.
