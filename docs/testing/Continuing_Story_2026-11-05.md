# Continuing story verification — 5 November 2026

The corrected opening identifies Ethan as Amara's child with his deceased wealthy father. It identifies David as her later partner and a web developer/hacker, and Victor as her former long-term partner. The father's name and cause of death remain unspecified. The third opening option is **Trace Victor's signal**.

## Checks run

- `story_checks`: 10,671 checks, zero failures. Loads all 217 story resources on each of the three approaches, verifies dialogue/portrait/background resources, restricts Morris to police, and checks repeated loads do not duplicate branch dialogue.
- Verifies narrative hooks and descriptions for all 1,000 extension levels against the campaign outline. Every win outcome keeps Ethan missing. All 200 new episode resources exist on disk.
- Exercises the real Game loss-result path twice: designated failure scene, Victor portrait, successive taunts, no level advancement or completion, and persisted failure counter.
- Checks failure presentation and visible action bounds at 720×960, 720×1280 and 720×1600.
- Verifies compact legacy choice migration, ID resolution, completed-scene persistence, latest evidence and season journal records.
- Full-completion story save fixture is 21,456 bytes, including 1,050 completed levels, stars, 217 seen scenes, decisions and ten season summaries. The server's actual `validateSave` accepts it within its 96,000-byte limit. This fixture does not claim to contain every possible unrelated daily-activity record.
- `release_checks`: zero failures, including final level 1050 opening `serial100_outro`, then returning to the continuing map.
- `progression_daily_checks`: zero failures; all 1,000 extension JSON schemas and starting boards checked, with opening/closing episode hooks verified.
- `economy_checks`: zero failures after the shared result-screen changes.
- Before/after hashes of all non-narrative puzzle fields match for every one of the 1,050 levels. This story update changes no boards, moves, objectives, rewards or booster mechanics.

The Windows environment reports an unrelated root-certificate-store error. Release checks deliberately corrupt a fixture to test backup recovery. Some existing suites also report shutdown resource warnings; none reported script failures in the successful runs above.

These are local automated checks. Android device play, Play billing, rewarded ads and live Google login require their usual device/test-track verification; story checks do not certify those services.
