"""Summarize completed real-Board balance runs; never substitute a forecast for data."""
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def load(variant):
    path = ROOT / f".test-data/balance-{variant}/report.json"
    data = json.loads(path.read_text(encoding="utf-8"))
    if not data.get("complete", "attempts" in data):
        raise SystemExit(f"{variant} run is incomplete ({len(data['runs'])} completed attempts).")
    if data["technical_failures"]:
        raise SystemExit(f"{variant} has technical failures; review the raw report.")
    return data


def main():
    before, after = load("before"), load("after")
    initial_after_wins = sum(r["won"] for r in after["runs"])
    follow_up_used = False
    follow_up_path = ROOT / ".test-data/balance-final-1050.json"
    current_budget = json.loads((ROOT / "levels/level1050.json").read_text())["moves"]["total"]
    if any(r["level"] == 1050 and r["budget"] != current_budget for r in after["runs"]):
        follow_up = json.loads(follow_up_path.read_text())
        if not follow_up.get("complete") or follow_up["technical_failures"] or len(follow_up["runs"]) != 3 or any(r["level"] != 1050 or r["budget"] != current_budget for r in follow_up["runs"]):
            raise SystemExit("The final level adjustment needs a completed three-policy follow-up.")
        replacements = {r["policy"]: r for r in follow_up["runs"]}
        after["runs"] = [replacements[r["policy"]] if r["level"] == 1050 else r for r in after["runs"]]
        follow_up_used = True
    if [(r["level"], r["policy"]) for r in before["runs"]] != [(r["level"], r["policy"]) for r in after["runs"]]:
        raise SystemExit("The two runs do not compare identical cases and policies.")
    lines = [
        "# Measured economy and difficulty check — 5 November 2026", "",
        "These are actual Board swaps, cascades, obstacle damage and refills. Initial outcomes exclude tray boosters and extra moves. A separate five-move probe then tests recovery on each failed board. These are deterministic bot-policy outcomes, not estimated human probabilities or revenue.", "",
        "Baseline: committed level definitions at `e764ce9`. Three policies per case, nine selected cases (three per difficulty), using the same seed and policies before and after. Both batches completed without technical assertion failures.", "",
        "| Difficulty | Before wins / losses | After wins / losses | Revised losses rescued by five moves |",
        "| --- | ---: | ---: | ---: |",
    ]
    if any(json.loads((ROOT/f"levels/level{r['level']:03d}.json").read_text()).get("difficulty") == "CRITICAL_CASE" and r["difficulty"] != "CRITICAL_CASE" for r in after["runs"]):
        lines[2:2] = ["Historical phase: these stored attempts predate the current Critical Case inventory seals. See `../design/Critical_Cases_and_Return_Assistance.md` for the current mechanics and additional trials.",""]
    for difficulty in ["EASY", "MEDIUM", "HARD", "CRITICAL_CASE"]:
        old = [r for r in before["runs"] if r["difficulty"] == difficulty]
        new = [r for r in after["runs"] if r["difficulty"] == difficulty]
        if not old and not new:
            continue
        wins_old, wins_new = sum(r["won"] for r in old), sum(r["won"] for r in new)
        rescued = sum(not r["won"] and r["won_with_five_extra_moves"] for r in new)
        lines.append(f"| {difficulty} | {wins_old} / {len(old)-wins_old} | {wins_new} / {len(new)-wins_new} | {rescued} |")
    for variant, data in [("Before", before), ("After", after)]:
        wins = sum(r["won"] for r in data["runs"])
        rescued = sum(not r["won"] and r["won_with_five_extra_moves"] for r in data["runs"])
        lines += ["", f"{variant}: {wins} wins and {len(data['runs'])-wins} losses in {len(data['runs'])} initial attempts; five extra moves rescued {rescued} failed attempts."]
    lines += ["", "| Case | Difficulty | Old free wins | Revised free wins | Revised continuation wins |", "| --- | --- | ---: | ---: | ---: |"]
    no_free_win = []
    for level in after["sample_levels"]:
        old = [r for r in before["runs"] if r["level"] == level]
        new = [r for r in after["runs"] if r["level"] == level]
        count = sum(r["won"] for r in new)
        if not count:
            no_free_win.append(level)
        lines.append(f"| {level} | {new[0]['difficulty']} | {sum(r['won'] for r in old)}/{len(old)} | {count}/{len(new)} | {sum(r['won_with_five_extra_moves'] for r in new)} |")
    lines += ["", f"Cases without an initial free win under these policies: {', '.join(map(str,no_free_win)) if no_free_win else 'none'}. A bot loss is not proof of an impossible level."]
    if follow_up_used:
        lines += ["", f"The first revised batch had {initial_after_wins}/27 wins and no free win on level 1050. That case was adjusted from 24 to 26 moves and all three policies were rerun; its follow-up replaces that case in the final comparison above. Raw first-trial results remain unchanged. Total completed playthroughs: 57 (27 baseline, 27 first revision, three final follow-ups). Follow-up: `.test-data/balance-final-1050.json`."]
    economy = json.loads((ROOT / "configs/economy.json").read_text())
    progression = json.loads((ROOT / "configs/endless_progression.json").read_text())
    daily = json.loads((ROOT / "configs/daily_activities.json").read_text())
    lines += ["", "## Currency purchasing power", "", "| First-clear tier | Base coins | Clears to fund one 200-coin life | Clears to fund a 900-coin refill |", "| --- | ---: | ---: | ---: |"]
    for tier, reward in progression["coins_by_difficulty"].items():
        lines.append(f"| {tier} | {reward} | {economy['items']['life']['price']/reward:.2f} | {economy['items']['life_refill']['price']/reward:.2f} |")
    peak_daily = 2*daily["portrait_coins"] + sum(m["coins"] for m in daily["missions"]) + max(daily["streak_coins"]) + daily["weekly_coins"]
    lines += ["", f"Even an upper-bound daily combination of two portraits, both missions, the largest stamp and the weekly chest is {peak_daily} coins, below one 200-coin life. This excludes campaign clears and character rewards and is not a total player-income measurement.", "", "Previously two 50-coin first clears funded five lives. The revised refill requires 15 hard clears, 22.5 medium clears or 30 easy clears before other income. Existing balances are retained.", "", "## Reproduce and limitations", "", "Run `powershell -ExecutionPolicy Bypass -File tools/run_balance_checks.ps1`, then `python tools/report_economy_balance.py`. Raw reports and per-attempt outcomes are in `.test-data/balance-before/report.json` and `.test-data/balance-after/report.json`.", "", "All 1,000 added boards have separate schema/opening-board validation. These nine cases do not establish full-campaign human balance. Automated payment checks use a local test server; actual Google Play transactions, AdMob inventory and human retention still require Play-track testing. See `docs/design/Monetization_Implementation_2026-11-05.md` for implementation and sourced competitor price distinctions."]
    destination = ROOT / "docs/testing/Economy_Balance_2026-11-05.md"
    destination.write_text("\n".join(lines)+"\n", encoding="utf-8")
    print(destination)
    print(f"Before {sum(r['won'] for r in before['runs'])}/{len(before['runs'])}; after {sum(r['won'] for r in after['runs'])}/{len(after['runs'])}; no free win: {no_free_win}")


if __name__ == "__main__":
    main()
