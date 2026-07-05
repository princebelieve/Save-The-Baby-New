Save The Baby — Architecture vs Data Schema Contract Model (Version 1.0)

1. Core Principle

The project is divided into two independent but connected layers:

A. Frozen Architecture (Engine Layer)

This defines:

Which systems exist
Who owns what responsibility
How systems communicate
What dependencies are allowed
What each subsystem is responsible for (logic, not data content)

Once frozen, this layer does not change unless there is a real structural flaw or explicit redesign decision.

B. Data Schema (Content Layer)

This defines:

The structure of JSON files in /configs/
Field definitions inside those files
Data formats consumed by systems
Content rules and constraints

This layer is:

NOT required during early engine implementation
Frozen only when a system is about to consume or author the data 2. Key Separation Rule

Architecture defines who uses data and how it flows.
Schema defines what the data looks like.

They are intentionally separated so that:

Engine development is not blocked by missing data design
Data design is not prematurely locked before usage context is stable 3. What Is Frozen vs What Is Flexible
3.1 Frozen (Engine Contract)

These are already considered stable:

Manager responsibilities and coordination rules
Subsystem ownership boundaries
Communication patterns (e.g., SignalBus usage)
Folder-level responsibilities (scripts/, configs/, etc.)
Class-level roles (e.g., RewardCalculator vs RewardDistributor)
Interaction rules between systems

Example:

RewardManager coordinates reward flow
RewardCalculator computes reward values
RewardDistributor applies rewards via EconomyManager
RewardTable reads from configs/rewards.json

None of these depend on JSON structure.

3.2 Not Frozen (Data Contracts)

These remain flexible until explicitly defined:

configs/rewards.json schema
configs/tiles.json schema
configs/economy.json schema
configs/story.json schema

These are only finalized when:

A system is about to actively use them
Multiple systems depend on consistent interpretation
Implementation requires exact fields 4. Correct Development Workflow
Phase 1 — Freeze Architecture

Before implementation:

Define system responsibilities
Define class roles
Define communication flow
Define ownership boundaries

Output:

API Maps (Managers, Systems, Subsystems)
Connected File Tree
Responsibility contracts

No JSON schema is finalized at this stage.

Phase 2 — Build Engine Against Architecture

During implementation:

Implement systems strictly using frozen architectural contracts
Do NOT introduce temporary placeholder logic or incomplete stubs
Design interfaces to be fully generic and schema-agnostic from the start
Systems must operate on the assumption that:
Data exists
Data shape is not their responsibility
Any valid schema conforming to the contract must work

Key rule:

Engine systems do not simulate missing data. They define interfaces that are inherently independent of data structure.

Phase 3 — Freeze a Specific Data Schema (On Demand)

When a system reaches a point where it must consume real data:

Gather:
Relevant API Map(s)
Connected File Tree section
Systems consuming the data
Define:
Exact JSON structure
Field definitions
Constraints and rules
Ownership of fields
Freeze the schema:

Example:

configs/rewards.json API Map (Version 1.0 Freeze)

After freezing:

No system may reinterpret the schema
All implementations must follow it exactly 5. Why This Works
5.1 Prevents Early Over-Engineering

You avoid designing:

200-field JSON files too early
Premature assumptions about future gameplay needs
Rewriting schema repeatedly during engine development
5.2 Keeps Engine Development Clean

Engine systems focus only on:

Logic
Flow
Coordination
Responsibility boundaries

Not data formatting debates.

5.3 Keeps Schema Design Grounded

Schemas are defined only when a system reaches a concrete, real dependency on external data structure. At that point, the schema becomes a frozen contract between systems and data.

6. Example: Reward System Flow
   Architecture (Frozen)
   RewardManager → orchestrates reward flow
   RewardCalculator → computes reward values
   RewardValidator → ensures validity
   RewardTable → reads reward definitions
   RewardDistributor → applies rewards via EconomyManager

This is stable regardless of JSON structure.

Data Schema (Not Frozen Until Needed)

configs/rewards.json is undefined until:

RewardTable is being implemented fully
Reward logic requires actual fields

At that point, we define:

reward types
scaling rules
reward triggers
payout structure

Then freeze it.

7. Documentation Strategy Going Forward

Instead of large monolithic documents, the system uses:

Architecture Documents (Always Frozen)
Manager API Map
System API Map
Connected File Tree
Folder responsibility maps
Schema Documents (Created per data file)
Reward JSON API Map
Tile JSON API Map
Economy JSON API Map
Story JSON API Map

Each schema document is:

Independent
Small
Usage-driven
Stable once frozen 8. Practical Rule for Future Implementation

When building any system:

Ask:

“Does this logic depend on knowing the JSON field structure?”

If NO:

Implement using only the subsystem’s architectural contract
Ensure interfaces are generic and data-agnostic

If YES:

Stop and define a schema contract for that specific data source
Freeze it before continuing implementation 9. Long-Term Benefit

This structure ensures:

Engine can be fully built without waiting on perfect data design
Data design is never speculative
No repeated redefinition of JSON structure during development
Clear separation of responsibility between systems and content 10. Final Summary Rule

The architecture tells us what exists.
The schema tells us what it contains.
They are frozen at different times, intentionally.

❌ Wrong mindset
“We’ll temporarily assume structure until JSON is defined”
✅ Correct mindset
“If structure matters, it belongs in a schema contract—not the engine”
“If structure doesn’t matter, the engine must not depend on it at all”
