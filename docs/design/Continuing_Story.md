# Continuing story

Ethan is Amara's child with his deceased wealthy father. Amara's long relationship with Victor ended before that relationship. The father provided for mother and child; his name and cause of death remain unspecified. Amara later chose David, a web developer and hacker. Victor claims credit for other people's achievements and resents her independence. His demand for 'my money' is an antagonist's claim, not an established debt.

The opening choices are **Call the police**, **Trace Victor's signal**, and **Go after Victor alone**. David handles technical decoding. Amara supplies personal knowledge and makes decisions about her own affairs. Detective Morris appears in the active story only on the police approach. Later episode choices can change the approach.

Levels 1–50 retain the prologue, with corrected parentage, dialogue and route ownership. Levels 51–1050 contain 100 episodes across ten seasons. Each episode spans ten puzzle levels, with an opening scene, evolving level descriptions and briefings, and a closing discovery and decision. These are 1,050 puzzle levels, not 1,050 separate story chapters.

Wins verify evidence and uncover narrowly missed opportunities. Ethan remains missing in every continuing episode, including level 1050. Season finales preserve partial progress—protected witnesses, retained evidence, blocked financial access—without rescuing him. A rescue would end this story. Losses remain on the same puzzle and display `FailureScreen.tscn`, Victor's portrait and a rotating threat. Retry, supplies and available continuations remain in the existing result flow.

`configs/story_canon.json` holds canon and failure dialogue. `configs/story_campaign.json` contains the authored episode outline. `tools/author_story_outline.py` preserves the authored beats; `tools/materialize_story_campaign.py` writes 200 physical `stories/serialNNN_intro.json` / `_outro.json` files and updates the 1,000 physical level files. The game reads those files; it does not generate episodes while playing. Rebuilding campaign levels also preserves narrative hooks through `StoryCampaign.gd`.

Completed scenes are remembered in `story_seen`; replaying a level skips already finished scenes. Story decisions save only their IDs, resolving current dialogue from the original JSON for the case file. The latest episode and ten season summaries are retained without storing duplicate scene text in every saved decision.

Run `tools/run_checks.ps1 -Suite story_checks` for all route/resource checks, narrative agreement across all 1,000 extension levels, failure presentation/rotation, persistent story progress and case-file entries. `release_checks` covers the final-level cliffhanger and return to the campaign map.
