# Mobile screen design comparison

Follow-up: [seasonal, daily and bonus-game research](../design/Seasonal_Events_and_Bonus_Game_Research.md)
records ten additional visual references and a proposed restoration flow before
implementation.

Reviewed 11 November 2026. This is an audit and proposed direction, not a claim
that the screens have been redesigned. Existing blocker changes are unrelated.

## References and limits

- King Community paint-stripe tutorial screenshot:
  https://community.king.com/en/candy-crush-saga/discussion/457708/help
  Image inspected locally: `.test-data/candy-crush-tutorial-reference.png`.
  The screenshot shows a short action instruction, a large booster illustration,
  a highlighted tray control and a board that stays visible. It is a historical
  example, not evidence that every current Candy Crush screen uses this layout.
- King Community accessibility settings screenshot:
  https://community.king.com/en/candy-crush-saga/discussion/485350/how-do-i-turn-hints-off
  Search results show a dedicated accessibility section with labeled toggles.
  The full-size image could not be fetched for close visual inspection.
- Official controls explanation:
  https://candycrush.zendesk.com/hc/en-us/articles/360000750278-Controls-how-to-switch-and-match-candies
- Official booster guide, including examples of pre-level and in-game screens:
  https://candycrush.zendesk.com/hc/en-us/articles/360000750998-What-are-Boosters

The recommendations below are our design judgments from those examples and a
review of this game's implementation; they are not measured Candy Crush rules.

## Findings in Save The Baby

1. **We measure design units rather than the resulting phone text.** The project
   uses a 720-wide logical canvas. On a 360-wide presentation, font sizes 20–22
   become approximately 10–11 display pixels, and 32 becomes approximately 16.
   On 320-wide presentation, 32 becomes roughly 14.2. Physical density and font
   metrics affect perceived size, but the shrinkage is enough to explain the
   complaint. Briefing copy uses 20–22 in several places.
2. **Tutorial pagination and rendering disagree.** `TutorialOverlay.show_tip`
   calculates two-line chunks at size 22, while `_layout_tip` and the body label
   use 32. Chunks can therefore wrap into more lines than the pagination assumes.
3. **The tutorial card spends space on framing and navigation.** The 570-unit
   maximum width, portrait column, FIELD GUIDE title, speaker name, parchment
   decoration, Back/Continue, close and Help Settings compete with the message.
   A scrolling body makes a simple instruction feel like a document.
4. **We teach too much before letting players act.** Level one's Academy lesson
   has six source paragraphs: story, matching, move costs, goals, lives/rewards
   and the case file. The board is locked while the lesson pages are presented.
   Chunking can create still more pages. These facts do not all need teaching
   before the first swap.
5. **We already have guided swaps, spotlights and a gesture hand, but the Academy
   presentation still sends complete lesson text through the overlay.** The
   improvement should reuse those interaction tools rather than add more panels.
6. **The mission card mixes narrative and the immediate play decision.** It
   combines a level title, portrait, approach, description, optional route detail,
   objective, difficulty, moves and conditional supply guidance. Generous paper
   margins further reduce usable space. Scrollability prevents clipping but
   does not make the main decision easier to understand.
7. **Typewriter text adds friction to functional guidance.** SHOW TEXT and then
   NEXT/CONTINUE introduce reading controls before the requested board action.
   This effect can suit optional story dialogue; a one-line move instruction
   should appear immediately.
8. **Settings repeats audio controls vertically.** Music and effects each get a
   label, slider and separate Enabled/Disabled row. The existing hint/tutorial
   toggles and legal shortcuts should remain in Settings, but the layout could
   use concise rows and optional expansion for finer volume adjustment.

## Proposed direction

| Screen | Primary content | Secondary content |
| --- | --- | --- |
| First move | Highlight two tiles; one short swap instruction | Detailed matching explanation in the existing case file |
| New booster | Large booster icon; one action; demonstrate the result | Full mechanics in optional help |
| Mission start | Level number, large goal icon/count, moves, prominent Play | Story/approach details available on demand |
| Gameplay | Board, goal progress, moves, booster stock | Explanations only when the mechanic first appears or help is requested |
| Settings | Clearly labeled compact audio and guidance rows | Legal/account actions remain reachable here |

Keep David, Ethan, the investigation story and our own visual identity. Borrow
the communication approach rather than Candy Crush artwork or exact layouts.

Proposed acceptance targets:

- One new action per mandatory tutorial step; approximately 8–16 words when
  practical, with no scrolling instruction and no typewriter wait.
- Use the actual rendered font and available width for pagination, and reflow
  after size changes. Never shrink a message to fit a crowded card.
- Start with a body-text target equivalent to 18–20 pixels on a 360-wide phone
  preview, then validate on devices; on our current canvas that implies roughly
  36–40 logical units. This is a proposed product target, not a universal minimum.
- Important actions should be comfortably tappable, with a proposed target of
  at least 48-by-48 in the same phone-preview coordinate system.
- Essential goal/count/moves/Play must fit without scrolling on compact phones.
- Preserve separate hints/tutorial preferences and the shortcut to existing
  Settings. Do not add a separate competing help-settings screen.
- Keep full story and lesson information available in optional views.

## Implementation priority and verification

First fix tutorial measurement and phone typography together with reducing the
mandatory copy; increasing fonts alone will make existing cards more crowded.
Then convert the first swap and booster lessons to short demonstrated actions.
Next simplify mission cards, followed by Settings and optional reference views.

Capture and inspect actual rendered screens at 320, 360, 390 and 412 logical
phone widths. Check the longest messages, first-time and returning-player paths,
all booster lessons, and both guidance settings disabled. Verify focus targets,
button visibility, actual text size, overlap and scroll requirements. Existing
font-size/geometry tests are useful but cannot establish visual interest or
comprehension; a short phone playtest is also needed.
