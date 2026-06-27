scripts/save/
Save System API Map (Version 1.0 Freeze)
Purpose

The Save System provides the specialized implementation used by SaveManager to persist player progress.

It is responsible only for save data representation, serialization, validation, migration, and file storage.

It never coordinates gameplay.

It never coordinates saving or loading.

It never decides when saving occurs.

Those responsibilities belong exclusively to SaveManager.

Configuration comes from ConfigLoader.

File operations may use FileHelper.

Time calculations may use TimeHelper.

Communication occurs through SignalBus.

This folder is fully aligned with the frozen Manager API and Utilities API.

1. SaveData.gd
Purpose

Represents one complete save.

Contains persistent player data only.

Contains no gameplay logic.

Contains no file logic.

Contains no serialization logic.

Contains no validation logic.

Public API
Initialization

initialize()

reset()

duplicate_data() -> SaveData

Save Data

set_value(key, value)

get_value(key)

has_value(key) -> bool

remove_value(key)

clear()

Sections

set_section(name, data)

get_section(name)

has_section(name) -> bool

remove_section(name)

Metadata

set_save_version(version)

get_save_version()

set_timestamp(timestamp)

get_timestamp()

Internal

_data

_version

_timestamp

2. SaveSerializer.gd
Purpose

Converts SaveData between runtime objects and serialized data.

Contains no gameplay logic.

Contains no file operations.

Public API
Initialization

initialize()

Serialization

serialize(save_data) -> Dictionary

deserialize(data) -> SaveData

Conversion

to_json(save_data)

from_json(json_text)

Internal

_convert_to_dictionary()

_convert_from_dictionary()

3. SaveFile.gd
Purpose

Performs physical save-file operations.

Contains no gameplay logic.

Contains no serialization logic.

Contains no save coordination.

Public API
Initialization

initialize()

File Operations

read(path)

write(path, data)

delete(path)

exists(path)

copy(source, destination)

rename(path, new_name)

Backup

create_backup(path)

restore_backup(path)

Internal

_open_file()

_close_file()

4. SaveValidator.gd
Purpose

Validates save data before loading.

Contains no gameplay logic.

Contains no migration logic.

Public API
Initialization

initialize()

Validation

validate(save_data) -> bool

validate_version(save_data) -> bool

validate_sections(save_data) -> bool

validate_required_fields(save_data) -> bool

get_validation_errors() -> Array

Internal

_errors

5. SaveMigrator.gd
Purpose

Migrates older save formats to the current version.

Contains no gameplay logic.

Contains no file operations.

Public API
Initialization

initialize()

Migration

can_migrate(version) -> bool

migrate(save_data) -> SaveData

get_supported_versions()

get_current_version()

Internal

_apply_migration()

6. AutosaveScheduler.gd
Purpose

Provides autosave timing services.

It never performs saving.

It never writes files.

It only determines when an autosave should be requested.

SaveManager decides whether to save.

Public API
Initialization

initialize()

Control

start()

stop()

pause()

resume()

Timing

set_interval(seconds)

get_interval()

update(delta)

is_time_to_autosave() -> bool

reset_timer()

Internal

_interval

_elapsed_time

_running

_paused

Frozen Save System Dependency
                 SaveManager
                      │
      ┌───────────────┼───────────────┐
      ▼               ▼               ▼
 SaveSerializer   SaveValidator   AutosaveScheduler
      │               │
      ▼               ▼
   SaveData      SaveMigrator
      │
      ▼
   SaveFile
Version 1 Rules

The Save System provides the implementation used by SaveManager.

SaveManager is the only class that coordinates saving and loading.

SaveData represents persistent data only.

SaveSerializer converts between runtime objects and serialized formats.

SaveFile performs only physical file operations.

SaveValidator validates save data before loading.

SaveMigrator upgrades older save formats to the current save version.

AutosaveScheduler determines when an autosave should be requested but never performs the save itself.

The Save System contains no gameplay logic.

The Save System contains no gameplay coordination.

The Save System never decides rewards, progression, story, levels, objectives, or economy.

The Save System may depend on FileHelper, JsonLoader, TimeHelper, Version, Constants, and SignalBus from scripts/utilities/.

The Save System must not depend directly on gameplay managers. It is coordinated exclusively through SaveManager.