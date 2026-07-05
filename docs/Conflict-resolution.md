Memory rule (copy this if you want to store it)

Always classify every API map element into one of three layers before deciding placement:

ENGINE LAYER (Constants.gd / Utilities)
structural definitions only
scene paths, config paths, node groups, physics layers
enums that define system contracts
NO gameplay or balancing values
DATA LAYER (configs/\*.json)
all gameplay tuning values
economy, levels, difficulty, grid sizes, lives, rewards
single source of truth for balancing
RUNTIME LAYER (Managers / Scenes)
execution and coordination only
no ownership of static configuration

If a value appears in configs/\*.json, it MUST NOT exist in Constants.gd.
Conflicts are resolved in favor of CONFIGS ALWAYS.
