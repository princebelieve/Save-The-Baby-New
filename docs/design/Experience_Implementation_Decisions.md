# Experience research corrections and implementation decisions

**November 12 follow-through:** the five requested subsequent stages are now
implemented and verified. See [the completion record](../testing/Experience_Journey_Completion.md).
The notes below retain the historical boundary of the November 11 first pass.

11 November 2026. This supersedes the earlier suggestion that a permanent bonus
menu alone solves side-activity discovery. The user authorized implementation
after recording the research; no further planning approval is required.

## Research conclusions

- **Composition is the unit of design.** In the saved Candy Crush references,
  lettering, card silhouette, illustration, reward objects and action buttons
  share scale, palette and emphasis. Large text fits because its space is planned,
  not because small generic labels were placed over a finished background.
  Preserve text as live controls for readability and adaptation while making the
  composition feel illustrated. We are not claiming the reference text is baked
  into one bitmap, or claiming a particular proprietary font identity.
- **Events have different participation models.** They can track main-level
  actions, celebrate a milestone, offer a daily reward, or open a separate game.
  A persistent entry can support returning, but it should not replace the earned
  introduction. Our earlier optional-hub proposal was too narrow.
- [Official Rocket Rush](https://candycrush.zendesk.com/hc/en-us/articles/30886478350621--Rocket-Rush)
  uses consecutive main-level wins and milestone checkpoints to award rewards;
  loss preserves reached checkpoints. This is an event wrapped around play, not
  necessarily a separate board game. Do not confuse the Saga rules with Soda's
  different event of the same name.
- [Official Don't feed the Troll](https://candycrush.zendesk.com/hc/en-us/articles/23238941854877--Don-t-feed-the-Troll)
  describes collecting orange candies on new levels to retain portions of a
  reward cake, including boosters and Unlimited Lives. Its illustrated stack
  explains potential prizes. Its timer pressure is not a requirement for our game.
- [King's design process described by Figma](https://www.figma.com/customers/how-king-brings-game-design-together/)
  brings mechanics, economy, narrative, interface, interaction and microcopy
  together. A visual rewrite without real reward accounting is incomplete.
- [Apple's game-interface guidance](https://developer.apple.com/design/human-interface-guidelines/designing-for-games)
  reinforces legibility and adaptation to smaller displays. A logical font-size
  assertion alone does not establish on-phone readability. We therefore inspect
  composed screens as well as measuring their controls; this does not claim
  platform-wide accessibility support or a completed physical-device playtest.
- The previous ten saved references additionally cover season identity, Free/
  Premium tracks, challenge invitations, rules, daily tasks, reward presentation
  and a historical animated activation→reward→extra-ad sequence. They do not
  establish one universal startup flow. These are published observations, not
  a personal Candy Crush playthrough.

## First implementation pass

1. Recompose coaching as a wide illustrated speech card: use the game's existing
   Baloo display lettering, larger body text, clear outline/contrast, portrait
   header, consistent padding and one action area. Measure and render the same
   font size. Show functional instructions immediately. Keep the existing
   Settings shortcut and independent tutorial/hint preferences.
2. Replace the multi-paragraph compulsory Academy reading with one concise
   introduction, followed by the existing real-board practice where authored.
   Preserve full lesson facts in the case file.
3. Introduce restoration through an earned case-clear opportunity with an
   illustrated invitation showing the actual picture, time and guaranteed prize.
   First opportunity after case 3; subsequent opportunities every four numbered
   cases on first clear, capped by the existing twelve-hour availability slot.
   The continuation remains dismissible and cannot start a timer by itself.
4. Remove the permanent restoration call-to-action from the map footer. Keep
   earned or active opportunities recoverable through Case Rewards. Daily
   briefing's main action should lead to the investigation, not the picture game.
5. Earned restoration success grants the existing coin reward plus one configured
   booster (initially Rocket). Show the booster before play and after success;
   consume the claim marker and grant through the existing inventory together.
   Existing attempts keep their already promised rewards. Do not invent stored
   extra-move or unlimited-life currencies: they need their own balancing and
   persistence before being offered.
6. Give the player a reference/practice screen before Start. Reading it costs no
   attempt time or slot. A started attempt receives the full advertised duration
   across a slot boundary. Background time still counts. Preserve backward
   compatibility for already saved attempts.

The first pass deliberately uses our existing characters/art and fonts. Follow-up
work recorded below is not silently included in the completion claim.

## Further experience work and boundaries

| Area | Direction | Status after recording |
| --- | --- | --- |
| Mission start | Goal/count/moves as a single illustrated composition, optional story detail | Implemented in this pass |
| Story seasons | One recognizable chapter transition, matching map/background identity | Recorded; no new calendar expiration system |
| Main-play daily tasks | Existing special-piece/blocker tasks can grow into illustrated booster tracks | Recorded; avoid adding several competing event systems at once |
| Failure recovery | Clear immediate cost/benefit, consistent retry and +5-move presentation | Preserve working behavior; later visual pass |
| Rewards | Actual inventory icons and quantities, single grants, context-preserving return | Part of earned-restoration pass |
| Audio/motion | Pair existing sounds with action; short entrance, no forced long animation | Use existing cues; no claim of newly generated audio |
| Help/preferences | Readable, discoverable Settings; instruction bypass remains available | Preserve and verify |
| Difficulty/fairness | Transparent blockers and predictable objective accounting | Preserve preceding fixes |

## Verification

Test first-clear eligibility, repeats, offer dismissal/recovery, configured reward
snapshots, expired/resumed attempts, slot-boundary duration and duplicate grants.
Test tutorial pages at the actual font/width with no phantom typewriter step.
Inspect rendered phone layouts, not just font-size constants. Run the existing
mobile, character/booster and economy checks affected by these changes.

The previous research document remains a historical record; this document is
the accepted correction and implementation direction for the current work.

## Implementation and verification record

Implemented the first pass in `TutorialOverlay`, `RestorationInvite`, `Game`,
`MobileGameUI`, `CampaignMap`, `RewardsHub`, `PortraitPuzzle` and `DailyActivities`.
Academy introductions are explicit short copy; full pages remain archived.
The first introduction now leads to the real guided board practice.

The earned invitation appears on the next-case transition after eligible first
clears, not merely as a new static map menu. Dismissal proceeds with the original
next-case action; an unstarted earned opportunity remains accessible through
Case Rewards until its availability slot ends. Tutorials off skips practice.
An old saved attempt keeps its original coin-only contract. New earned attempts
snapshot their booster reward, and the consumed claim and actual inventory save
together. No life is spent by restoration. In-attempt reference viewing and
background time still consume time; the new demonstration occurs before Start.

The mission card now has larger goal/count/move lettering and an illustration,
with story paragraphs behind Case story. The map footer is shorter. No new paid
pass, life/move currency, global reward event queue or season transition is claimed
as implemented. Those broader systems remain recorded follow-up work.

Validation at this stage:

- `experience_checks`: 63 checks, zero failures, including real tap-to-solve
  practice, actual Rocket inventory grant, repeat-claim protection, persistence,
  next-case continuation, compact-phone geometry and intro-to-guided-swap flow.
- `mobile_ui_checks`: 1,274 checks, zero failures; now includes booster reward
  output on the restored-image result screen.
- `character_booster_checks`: 1,248 checks, zero failures.
- `progression_daily_checks`: zero failures; 1,000 level files and boards checked.
- `economy_checks`: zero failures.
- `story_checks`: 10,673 checks, zero failures.
- `release_checks`: zero failures, including the existing intentional malformed-save
  recovery test. The known headless certificate-store diagnostic is unrelated.
- Actual booster tutorial playthrough at the short-phone size: Rocket, Bomb and
  Thunder teaching/targeting completed with zero failures.
- Rendered the tutorial, invitation, untimed exercise and mission card with the
  graphical renderer. Captures are under `.test-data/experience-*.png`. This caught
  a squeezed prize label and clipped text, both corrected before completion.

These checks verify the specified behavior and inspected layouts; they do not
prove every game screen is finished or substitute for a child's phone playtest.
