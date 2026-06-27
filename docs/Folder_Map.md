Complete Project Folder Maps (Version 1 Freeze)
✅ addons/

Purpose

Third-party plugins only.

No project code should ever be placed here.

addons/

    plugin_name/

        plugin.cfg

        plugin.gd

        ...

Rules

Only external plugins
Never modify plugin source unless necessary
Keep plugins independent of game code

Examples

godot-git-plugin/

dialogue-plugin/

admob-plugin/

✅ assets/

Purpose

Contains every imported asset used by the game.

No scripts.

No JSON.

No resources.

Only raw assets.

assets/

    sprites/

    audio/

    fonts/

assets/sprites/

Contains PNG artwork.

sprites/

    tiles/

    ui/

    characters/

    backgrounds/

    obstacles/

    powerups/

    effects/

    icons/

    logos/

sprites/tiles/

Contains collectible tile artwork.

Examples

key.png

phone.png

fingerprint.png

recorder.png

clock.png

plier.png

ethan.png

sprites/ui/

Contains UI images.

Examples

button.png

panel.png

frame.png

progress_bar.png

coin.png

star.png

sprites/characters/

Contains portraits.

Examples

amara_normal.png

amara_angry.png

victor_smile.png

ethan_scared.png

sprites/backgrounds/

Contains gameplay backgrounds.

Examples

city_day.png

warehouse.png

factory.png

office.png

sprites/obstacles/

Contains obstacle art.

Examples

chain.png

lock.png

bomb.png

missile.png

electric_trap.png

sprites/powerups/

Contains powerup icons.

Examples

rocket_h.png

rocket_v.png

bomb_power.png

thunder.png

sprites/effects/

Contains particle sprites.

Examples

spark.png

smoke.png

explosion.png

flash.png

sprites/icons/

Contains application icons.

settings.png

pause.png

play.png

shop.png

sprites/logos/

Contains branding.

logo.png

loading_logo.png

splash_logo.png

✅ assets/audio/

Contains audio only.

audio/

    music/

    sfx/

    voice/

music/

Background music.

Examples

menu.ogg

level01.ogg

victory.ogg

story_intro.ogg

boss.ogg

sfx/

Sound effects.

Examples

swap.wav

match.wav

bomb.wav

rocket.wav

button.wav

coin.wav

voice/

Reserved for future voice clips.

Examples

amara/

victor/

ethan/

✅ assets/fonts/

Contains font files only.

Examples

main.ttf

title.ttf

numbers.ttf

✅ animations/

Contains reusable animation resources.

Examples

tile_swap.tres

tile_destroy.tres

rocket.tres

bomb.tres

victory.tres

✅ configs/

Already frozen.

Contains only JSON configuration.

✅ docs/

Contains project documentation.

docs/

Architecture.md

MasterPlan.md

DevelopmentLog.md

Changelog.md

ApiMaps/

Milestones/

Testing/

docs/ApiMaps/

Contains every frozen API map.

Core.md

Board.md

Tiles.md

Managers.md

Powerups.md

Obstacles.md

Save.md

Story.md

UI.md

Configs.md

Resources.md

Levels.md

Stories.md

docs/Milestones/
Phase01.md

Phase02.md

...

Phase20.md

docs/Testing/
BoardTests.md

StoryTests.md

PowerupTests.md

RegressionChecklist.md

✅ scenes/

Contains only scenes.

boot/

menu/

board/

level/

story/

ui/

popup/

reward/

tutorial/

game/


Each folder contains only .tscn files.

✅ scripts/

Already frozen.

Contains only .gd files.

✅ resources/

Already frozen.

Contains only .tres resources.

✅ translations/

Contains localization files.

en.translation

fr.translation

es.translation


Future-proofed for additional languages.

✅ levels/

Already frozen.

Contains only

level001.json

...

level050.json

✅ stories/

Already frozen.

Contains only story JSON.

intro.json

chapter01.json

chapter02.json

ending.json

Version 1 Folder Rules
Folder	Contains
addons/	Third-party plugins only
assets/	Raw art, audio, fonts
animations/	Animation resources
configs/	JSON configuration
docs/	Documentation, API maps, milestones, testing
levels/	Level JSON files
resources/	.tres data resources
scenes/	.tscn scene files
scripts/	.gd scripts
stories/	Story JSON files
translations/	Localization files

I recommend treating this folder map the same way as the API maps: once accepted, it becomes part of the Version 1 freeze and should only change if you explicitly decide to change the project's organization. This gives every file and asset a defined home before implementation begins.