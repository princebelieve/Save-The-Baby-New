# Save The Baby - Game Implementation Plan

## Story Flow

### Act 1: The Kidnapping (Overview Scene)

- **Scene**: overview.png fades in with dangerous sounds
- **Story**: Victor has kidnapped Ethan (baby)
- **Next**: Transition to Amara's appeal scene

### Act 2: Amara's Plea (Main Story Scene)

- **Image**: badge.png (Amara)
- **Text**: Amara begs David to save Ethan
- **Victor's Demand**: "All your wealth should be transferred to me or you lose the baby"
- **David's Choices**:
  1. **Call Police** → Police Station Scene → Level Track 1 (50 levels)
  2. **Trace Signal** → Tech Specialist Scene → Level Track 2 (50 levels)
  3. **Go Alone** → David Solo Scene → Level Track 3 (50 levels)

---

## Level Structure (Per Choice Track)

Each choice determines what to target before a limited number of moves. e.g. lets say five keys forlevel one, 10 bombs to deflate in level 2, e.t.c. If my game idea is complicated just use candy crush calculation

### Track 1: Call Police (Police Station Investigation)

- **Scenes**:
  - police-station.png: Detective says "We need evidence"
  - Levels 1-50: Collect evidence (phone records, fingerprints, witness statements)
  - Final Scene: "We found the key to Victor's factory location"
- **Level Progression**:
  - Levels 1-10: Easy difficulty
  - Levels 11-30: Medium difficulty
  - Levels 31-50: Hard difficulty

### Track 2: Trace Signal (Phone Hacking)

- **Scenes**:
  - phone.png + recorder.png: Tech specialist says "Decrypt communication data"
  - Levels 1-50: Match signal patterns and decrypt data
  - Final Scene: "Signal traced! Factory location discovered"
- **Level Progression**: Similar difficulty curve

### Track 3: Go Alone (Factory Traps)

- **Scenes**:
  - david.png: "I'm going alone"
  - Levels 1-50: Navigate bombs, chains, locked doors, traps
  - Encounters missles, pinchers, pliers (tools), tape, thunder-bolts
  - **Lives System**:
    - Start with 5 lives
    - Each failed level costs 1 life
    - After 5 lives exhausted: Wait 20 minutes OR watch ad to play
    - After 20 min privilege used: Wait 24 hours for 5 more lives (or watch ads)

---

## Victory Condition

After completing 50 levels in any track:

- **Victory Scene**: David receives key pieces (minimum 10 keys)
- **Next Act**: Factory rescue with remaining puzzles
- **Final Boss**: Confront Victor, rescue Ethan

---

## Asset Mapping

| Asset              | Purpose                                |
| ------------------ | -------------------------------------- |
| overview.png       | Opening scene - Victor kidnaps Ethan   |
| badge.png          | Amara
| kidnapping.png     | Story illustration                     |
| police.png         | Police officer                         |
| police-station.png | Police station setting                 |
| detective.png      | Detective                              |
| david.png          | David (protagonist)                    |
| Victor.png         | Victor (antagonist)                    |
| etan.png           | Ethan (baby)                           |
| phone.png          | Phone/communication                    |
| key.png            | Evidence/puzzle piece                  |
| bomb.png           | Obstacle tile                          |
| chain.png          | Obstacle tile                          |
| clock.png          | Timer/special tile                     |
| finger-print.png   | Evidence tile                          |
| missile.png        | Trap/obstacle                          |
| locked.png         | Locked door tile                       |
| opened.png         | Unlocked state                         |
| pincher.png        | Trap/tool                              |
| plier.png          | Tool/obstacle                          |
| recorder.png       | Recording/evidence                     |
| tape.png           | Evidence/obstacle                      |
| thunder-bolt.png   | Power/special effect                   |


all these assets are what will also be used for the matches, let's also consider adding some realistic reward systems like any matches in level opening counts. Then "bomb" item destroys surrounding blocks, e.t.c. Just arrage eveything in an achievable way. I am thinking of building the as a godot game, in VS Code, then import to gotdot, to enable you write the code. Let's plan out everything first, so that it will be easy to contunue in next chat session. If the game don't make sense, you can suggest something better
