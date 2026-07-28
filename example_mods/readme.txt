Psych's mods/ folder.

If you're a beginner, we recommend you extract modTemplate.zip to get started on developing your mod.
Read the Psych GitHub wiki here:
https://github.com/ShadowMario/FNF-PsychEngine/wiki
Read the Lua Script API here:
https://shadowmario.github.io/psychengine.lua/

Plus Engine adds extra mod paths for New Freeplay assets and scripted states/substates.
The extracted My-Mod template already includes readme files for albumRoll, song metadata, states, and substates.

You can also add or edit specific files without the mod template, you just have to re-create the path to said file.

ABOUT EDITING:
If you want to change something, for example, within assets/shared/images or assets/base_game/images,
said edited files *must* be put in mods/images, the engine will handle the rest.

For song charts and New Freeplay metadata, it should look something like this:

assets/shared/data/your-song-name/
---- ./your-song-name-easy.json
---- ./your-song-name.json
---- ./your-song-name-hard.json
---- ./events.json
---- ./preload.json
---- ./song_meta.json
---- ./script.lua
---- ./script.hx
