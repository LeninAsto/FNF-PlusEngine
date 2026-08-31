const psychCategories = [
  {
    id: "playstate",
    title: "PlayState Functions",
    description: "General functions related to game state, songs, and cutscenes.",
    functions: [
      {
        name: "startCountdown",
        signature: "startCountdown()",
        description: "Starts the countdown, should be used after finishing your Pre-Song Cutscene."
      },
      {
        name: "endSong",
        signature: "endSong()",
        description: "Ends the song, can be cancelled through the Lua/HScript callback 'onEndSong' to make cutscenes."
      },
      {
        name: "getSongPosition",
        signature: "getSongPosition()",
        description: "Returns the current song position, in milliseconds."
      },
      {
        name: "restartSong",
        signature: "restartSong(?skipTransition:Bool = false):Void",
        description: "Restarts the Song, pretty self explanatory.",
        parameters: [
          {
            name: "skipTransition",
            type: "Bool",
            optional: true,
            description: "Skips fade in/out transition, defaults to false."
          }
        ],
        examples: [
          { code: "restartSong()", description: "Restarts the song with fade transition." },
          { code: "restartSong(true)", description: "Restarts the song without fade transition." }
        ]
      },
      {
        name: "exitSong",
        signature: "exitSong(?skipTransition:Bool = false):Void",
        description: "Quits the Song and goes back to Freeplay/Story Mode based on where you started."
      },
      {
        name: "loadSong",
        signature: "loadSong(?name:String = null, ?difficultyNum:Int = -1):Void",
        description: "Loads the chart for a song.",
        parameters: [
          {
            name: "name",
            type: "String",
            optional: true,
            description: "Song Name (ex. \"Bopeebo\", \"Lit Up\"), use null to keep current."
          },
          {
            name: "difficultyNum",
            type: "Int",
            optional: true,
            description: "Week's Difficulty Number (0 = Easy, 1 = Normal, 2 = Hard), use -1 to keep it the same as current."
          }
        ],
        examples: [
          { code: "loadSong('Bopeebo', 0)", description: "Loads Bopeebo on Easy difficulty." },
          { code: "loadSong('Lit Up', 1)", description: "Loads Lit Up on Normal difficulty." }
        ]
      },
      {
        name: "triggerEvent",
        signature: "triggerEvent(name:String, ?value1:String = '', ?value2:String = ''):Bool",
        description: "Calls an event and uses two arguments for it, exactly like the Chart Editor does. Should always return 'true'.",
        parameters: [
          {
            name: "name",
            type: "String",
            optional: false,
            description: "Event Name."
          },
          {
            name: "value1",
            type: "String",
            optional: true,
            description: "Does the same as what the Event says in the Chart Editor."
          },
          {
            name: "value2",
            type: "String",
            optional: true,
            description: "Does the same as what the Event says in the Chart Editor."
          }
        ],
        examples: [
          { code: "triggerEvent('Hey!', 'BF', 0.6)", description: "Calls \"Hey!\" event with BF as value1 and 0.6 as value2." }
        ]
      },
      {
        name: "setHealthBarColors",
        signature: "setHealthBarColors(left:String, right:String):Void",
        description: "Changes Health Bar colors using hexadecimal or color names.",
        parameters: [
          {
            name: "left",
            type: "String",
            optional: false,
            description: "Color hexadecimal string or color name for the left side of the bar."
          },
          {
            name: "right",
            type: "String",
            optional: false,
            description: "Color hexadecimal string or color name for the right side of the bar."
          }
        ],
        examples: [
          { code: "setHealthBarColors('FF0000', '00FF00')", description: "Makes left side red and right side lime." },
          { code: "setHealthBarColors('red', 'lime')", description: "Same as above, but using color names." }
        ]
      },
      {
        name: "setTimeBarColors",
        signature: "setTimeBarColors(left:String, right:String):Void",
        description: "Changes Time Bar colors.",
        examples: ["setTimeBarColors('FF0000', '00FF00')"]
      },
      {
        name: "startDialogue",
        signature: "startDialogue(dialogueFile:String, ?music:String):Void",
        description: "Loads a Dialogue .JSON inside the Chart folder, handles translation loading automatically.",
        parameters: [
          {
            name: "dialogueFile",
            type: "String",
            optional: false,
            description: "Dialogue file .JSON name."
          },
          {
            name: "music",
            type: "String",
            optional: true,
            description: "Plays a background music inside 'music/' folder."
          }
        ],
        examples: [
          { code: "startDialogue('dialogue')", description: "Loads \"dialogue.json\" inside the chart folder, will prefer \"dialogue_pt-BR.json\" if you're playing on Portuguese (Brazil)." },
          { code: "startDialogue('dialogue', 'breakfast')", description: "Same as above, but plays \"Breakfast\" as background music." }
        ]
      },
      {
        name: "startVideo",
        signature: "startVideo(videoFile:String, ?canSkip:Bool = true, ?forMidSong:Bool = false, ?shouldLoop:Bool = false, ?playOnLoad:Bool = true):Void",
        description: "Plays a Video Cutscene.",
        parameters: [
          {
            name: "videoFile",
            type: "String",
            optional: false,
            description: "Video .MP4 file located inside 'videos/' folder, don't include the extension!"
          },
          {
            name: "canSkip",
            type: "Bool",
            optional: true,
            description: "Allows the video to be skipped by holding down Enter for a second. Defaults to true."
          },
          {
            name: "forMidSong",
            type: "Bool",
            optional: true,
            description: "Doesn't start/finish song after the video ends, needed for mid-song cutscenes. Defaults to false."
          },
          {
            name: "shouldLoop",
            type: "Bool",
            optional: true,
            description: "Video will repeat once finished. Defaults to false."
          },
          {
            name: "playOnLoad",
            type: "Bool",
            optional: true,
            description: "Videos plays instantly after loading. Defaults to true."
          }
        ],
        examples: [
          { code: "startVideo('test_video')", description: "Plays the video mods/My-Mod/videos/test_video.mp4." }
        ]
      }
    ]
  },
  {
    id: "reflection",
    title: "Reflection Functions",
    description: "Get and set properties from objects and call their methods. Access both hardcoded and Lua objects.",
    functions: [
      {
        name: "getProperty",
        signature: "getProperty(variable:String, ?allowMaps:Bool = false):Dynamic",
        description: "Returns the value of a property or variable inside PlayState, a saved variable, or a Lua Sprite/Text.",
        examples: ["getProperty('dad.scale.x')", "getProperty('singAnimations[0]')", "getProperty('boyfriend.animOffsets.idle', true)"]
      },
      {
        name: "setProperty",
        signature: "setProperty(variable:String, value:Dynamic, ?allowMaps:Bool = false, ?allowInstances:Bool = false):Dynamic",
        description: "Sets the value of a property or variable inside PlayState. Returns the value.",
        parameters: [
          { name: "variable", type: "String", optional: false, description: "Variable path to set (ex. \"boyfriend.stunned\", \"singAnimations[3]\")." },
          { name: "value", type: "Dynamic", optional: false, description: "The new value to assign." },
          { name: "allowMaps", type: "Bool", optional: true, description: "Allows setting map-type values. Defaults to false." },
          { name: "allowInstances", type: "Bool", optional: true, description: "Allows setting custom instances. Defaults to false." }
        ],
        examples: [
          { code: "setProperty('boyfriend.stunned', true)", description: "Stuns the boyfriend character." },
          { code: "setProperty('singAnimations[3]', 'singLEFT')", description: "Sets the 4th sing animation to 'singLEFT'." }
        ]
      },
      {
        name: "getPropertyFromGroup",
        signature: "getPropertyFromGroup(variable:String, index:Int, property:Dynamic, ?allowMaps:Bool = false):Dynamic",
        description: "Returns the value of a property of a member inside a FlxTypedGroup/FlxSpriteGroup.",
        parameters: [
          { name: "variable", type: "String", optional: false, description: "FlxTypedGroup or FlxSpriteGroup variable name." },
          { name: "index", type: "Int", optional: false, description: "Index of the member in the group." },
          { name: "property", type: "Dynamic", optional: false, description: "Property path to retrieve." },
          { name: "allowMaps", type: "Bool", optional: true, description: "Allows getting map-type values. Defaults to false." }
        ],
        examples: [
          { code: "getPropertyFromGroup('playerStrums', 1, 'animation.curAnim.name')", description: "Gets the current animation name of the 2nd player strum." }
        ]
      },
      {
        name: "setPropertyFromGroup",
        signature: "setPropertyFromGroup(variable:String, index:Int, property:Dynamic, value:Dynamic, ?allowMaps:Bool = false, ?allowInstances:Bool = false):Dynamic",
        description: "Sets the value of a property of a member inside a FlxTypedGroup/FlxSpriteGroup.",
        parameters: [
          { name: "variable", type: "String", optional: false, description: "FlxTypedGroup or FlxSpriteGroup variable name." },
          { name: "index", type: "Int", optional: false, description: "Index of the member in the group." },
          { name: "property", type: "Dynamic", optional: false, description: "Property path to set." },
          { name: "value", type: "Dynamic", optional: false, description: "The new value to assign." }
        ],
        examples: [
          { code: "setPropertyFromGroup('playerStrums', 2, 'visible', false)", description: "Hides the 3rd player strum." }
        ]
      },
      {
        name: "getPropertyFromClass",
        signature: "getPropertyFromClass(classVar:String, variable:String, ?allowMaps:Bool = false):Dynamic",
        description: "Returns the value of a property inside a class.",
        parameters: [
          { name: "classVar", type: "String", optional: false, description: "Class path (ex. 'backend.ClientPrefs')." },
          { name: "variable", type: "String", optional: false, description: "Variable path inside the class." },
          { name: "allowMaps", type: "Bool", optional: true, description: "Allows getting map values. Defaults to false." }
        ],
        examples: [
          { code: "getPropertyFromClass('backend.ClientPrefs', 'data.downScroll')", description: "Gets the downScroll preference from ClientPrefs." }
        ]
      },
      {
        name: "setPropertyFromClass",
        signature: "setPropertyFromClass(classVar:String, variable:String, value:Dynamic, ?allowMaps:Bool = false, ?allowInstances:Bool = false):Dynamic",
        description: "Sets the value of a property inside a class.",
        parameters: [
          { name: "classVar", type: "String", optional: false, description: "Class path." },
          { name: "variable", type: "String", optional: false, description: "Variable path inside the class." },
          { name: "value", type: "Dynamic", optional: false, description: "The new value to assign." }
        ]
      },
      {
        name: "callMethod",
        signature: "callMethod(method:String, ?args:Array<Dynamic> = null):Dynamic",
        description: "Calls a method from PlayState or a Lua Sprite/Text.",
        parameters: [
          { name: "method", type: "String", optional: false, description: "Method name to call." },
          { name: "args", type: "Array<Dynamic>", optional: true, description: "Optional arguments to pass to the method." }
        ]
      },
      {
        name: "callMethodFromClass",
        signature: "callMethodFromClass(classVar:String, method:String, ?args:Array<Dynamic> = null):Dynamic",
        description: "Calls a method from a class.",
        parameters: [
          { name: "classVar", type: "String", optional: false, description: "Class path." },
          { name: "method", type: "String", optional: false, description: "Method name to call." },
          { name: "args", type: "Array<Dynamic>", optional: true, description: "Optional arguments to pass to the method." }
        ]
      },
      {
        name: "createInstance",
        signature: "createInstance(className:String, ?args:Array<Dynamic> = null):Dynamic",
        description: "Creates a new instance of a class.",
        parameters: [
          { name: "className", type: "String", optional: false, description: "Full class path." },
          { name: "args", type: "Array<Dynamic>", optional: true, description: "Constructor arguments." }
        ]
      },
      {
        name: "updateHitbox",
        signature: "updateHitbox(tag:String):Void",
        description: "Updates the hitbox of a sprite to match its graphic.",
        parameters: [
          { name: "tag", type: "String", optional: false, description: "Lua Sprite tag name." }
        ]
      }
    ]
  },
  {
    id: "spritesheet",
    title: "Spritesheet Functions",
    description: "Display, animate, and manipulate images on screen using Lua Sprites.",
    functions: [
      {
        name: "makeLuaSprite",
        signature: "makeLuaSprite(tag:String, ?image:String = null, ?x:Float = 0, ?y:Float = 0):Void",
        description: "Creates a Lua Sprite with a specific image and stores it with the given tag name.",
        parameters: [
          { name: "tag", type: "String", optional: false, description: "Unique identifier for the sprite." },
          { name: "image", type: "String", optional: true, description: "Image path from 'images/' folder (ex. 'funkay', 'myStage/myImage'). Use null for no image." },
          { name: "x", type: "Float", optional: true, description: "X position on screen. Defaults to 0." },
          { name: "y", type: "Float", optional: true, description: "Y position on screen. Defaults to 0." }
        ],
        examples: [
          { code: "makeLuaSprite('mySprite', 'funkay')", description: "Creates a sprite with the 'funkay' image." },
          { code: "makeLuaSprite('mySprite', 'myStage/myImage', 100, 200)", description: "Creates a sprite at position (100, 200)." }
        ]
      },
      {
        name: "makeAnimatedLuaSprite",
        signature: "makeAnimatedLuaSprite(tag:String, ?image:String = null, ?x:Float = 0, ?y:Float = 0, ?spriteType:String = 'auto'):Void",
        description: "Creates an animated Lua Sprite with image and .XML/.JSON/.TXT animation data.",
        parameters: [
          { name: "tag", type: "String", optional: false, description: "Unique identifier for the sprite." },
          { name: "image", type: "String", optional: true, description: "Image path with animation data files (ex. 'logoBumpin' loads logoBumpin.png/.xml)." },
          { name: "x", type: "Float", optional: true, description: "X position on screen. Defaults to 0." },
          { name: "y", type: "Float", optional: true, description: "Y position on screen. Defaults to 0." },
          { name: "spriteType", type: "String", optional: true, description: "Animation format: 'auto', 'aseprite', 'opensfl', 'json', etc. Defaults to 'auto'." }
        ],
        examples: [
          { code: "makeAnimatedLuaSprite('mySprite', 'logoBumpin')", description: "Creates animated sprite from logoBumpin.png/.xml." },
          { code: "makeAnimatedLuaSprite('mySprite', 'aseprite-test', 0, 0, 'aseprite')", description: "Creates Aseprite-format sprite." }
        ]
      },
      {
        name: "makeGraphic",
        signature: "makeGraphic(tag:String, ?width:Int = 256, ?height:Int = 256, ?color:String = 'FFFFFF'):Void",
        description: "Generates a solid color square as graphic for a Lua Sprite.",
        parameters: [
          { name: "tag", type: "String", optional: false, description: "Unique identifier for the sprite." },
          { name: "width", type: "Int", optional: true, description: "Width in pixels. Defaults to 256." },
          { name: "height", type: "Int", optional: true, description: "Height in pixels. Defaults to 256." },
          { name: "color", type: "String", optional: true, description: "Hex color or color name (ex. 'FF0000', 'red'). Defaults to 'FFFFFF' (white)." }
        ],
        examples: [
          { code: "makeGraphic('mySprite', 500, 500, 'FF0000')", description: "Creates a 500x500 red square." },
          { code: "makeGraphic('mySprite', 1000, 200, 'green')", description: "Creates a 1000x200 green rectangle." }
        ]
      },
      {
        name: "loadGraphic",
        signature: "loadGraphic(tag:String, image:String = null, ?gridX:Int = 0, ?gridY:Int = 0):Void",
        description: "Loads an image to a Lua Sprite with optional grid for frame division.",
        parameters: [
          { name: "tag", type: "String", optional: false, description: "Lua Sprite tag name." },
          { name: "image", type: "String", optional: false, description: "Image path from 'images/' folder." },
          { name: "gridX", type: "Int", optional: true, description: "Frame width for grid division. Defaults to 0 (no grid)." },
          { name: "gridY", type: "Int", optional: true, description: "Frame height for grid division. Defaults to 0 (no grid)." }
        ],
        examples: [
          { code: "loadGraphic('mySprite', 'funkay')", description: "Loads the 'funkay' image to the sprite." },
          { code: "loadGraphic('mySprite', 'icons/icon-bf', 150, 150)", description: "Loads image with 150x150 frame grid for sprite sheet." }
        ]
      },
      {
        name: "loadFrames",
        signature: "loadFrames(tag:String, image:String, ?spriteType:String = 'auto'):Void",
        description: "Loads a specific image and .XML/.JSON/.TXT animation data to a Lua Sprite.",
        parameters: [
          { name: "tag", type: "String", optional: false, description: "Lua Sprite tag name." },
          { name: "image", type: "String", optional: false, description: "Image path (loads image.png and image.xml/json automatically)." },
          { name: "spriteType", type: "String", optional: true, description: "Animation format ('auto', 'aseprite', 'opensfl'). Defaults to 'auto'." }
        ],
        examples: [
          { code: "loadFrames('mySprite', 'logoBumpin')", description: "Loads logoBumpin.png with logoBumpin.xml animation data." },
          { code: "loadFrames('mySprite', 'aseprite-test', 'aseprite')", description: "Loads with Aseprite animation format." }
        ]
      },
      {
        name: "addAnimation",
        signature: "addAnimation(tag:String, name:String, frames:Dynamic, ?framerate:Float = 24, ?loop:Bool = false):Void",
        description: "Adds an animation to a Lua Sprite from loaded frames.",
        parameters: [
          { name: "tag", type: "String", optional: false, description: "Lua Sprite tag name." },
          { name: "name", type: "String", optional: false, description: "Animation name identifier." },
          { name: "frames", type: "Dynamic", optional: false, description: "Frame indices as string (\"0,1,2\") or array ({0,1,2,3})." },
          { name: "framerate", type: "Float", optional: true, description: "Animation speed in frames per second. Defaults to 24." },
          { name: "loop", type: "Bool", optional: true, description: "Whether animation repeats. Defaults to false." }
        ],
        examples: [
          { code: "addAnimation('mySprite', 'idle', '0, 1, 2')", description: "Adds 'idle' animation using frames 0, 1, and 2." },
          { code: "addAnimation('mySprite', 'idle', {0, 1, 2, 3}, 12, true)", description: "Adds looping 'idle' at 12 fps with frames 0-3." }
        ]
      },
      {
        name: "addAnimationByPrefix",
        signature: "addAnimationByPrefix(tag:String, name:String, prefix:String, ?framerate:Float = 24, ?loop:Bool = false):Void",
        description: "Adds an animation using frame prefix matching (matches frames starting with prefix).",
        parameters: [
          { name: "tag", type: "String", optional: false, description: "Lua Sprite tag name." },
          { name: "name", type: "String", optional: false, description: "Animation name identifier." },
          { name: "prefix", type: "String", optional: false, description: "Prefix to match frames (ex. 'character-idle' matches 'character-idle0', 'character-idle1', etc)." },
          { name: "framerate", type: "Float", optional: true, description: "Animation speed in FPS. Defaults to 24." },
          { name: "loop", type: "Bool", optional: true, description: "Whether animation repeats. Defaults to false." }
        ],
        examples: [
          { code: "addAnimationByPrefix('mySprite', 'idle', 'character-idle')", description: "Adds animation matching frames starting with 'character-idle'." }
        ]
      },
      {
        name: "playAnim",
        signature: "playAnim(tag:String, name:String, ?force:Bool = false, ?reverse:Bool = false, ?startFrame:Int = 0):Void",
        description: "Plays an animation on a Lua Sprite.",
        parameters: [
          { name: "tag", type: "String", optional: false, description: "Lua Sprite tag name." },
          { name: "name", type: "String", optional: false, description: "Animation name to play." },
          { name: "force", type: "Bool", optional: true, description: "Force restart even if already playing. Defaults to false." },
          { name: "reverse", type: "Bool", optional: true, description: "Play animation backwards. Defaults to false." },
          { name: "startFrame", type: "Int", optional: true, description: "Start at specific frame. Defaults to 0." }
        ],
        examples: [
          { code: "playAnim('mySprite', 'idle')", description: "Plays the 'idle' animation." },
          { code: "playAnim('mySprite', 'jump', true)", description: "Force-plays 'jump' animation from the start." }
        ]
      },
      {
        name: "addLuaSprite",
        signature: "addLuaSprite(tag:String, ?inFront:Bool = false):Void",
        description: "Adds a Lua Sprite to the scene. By default adds it behind the stage.",
        parameters: [
          { name: "tag", type: "String", optional: false, description: "Lua Sprite tag name." },
          { name: "inFront", type: "Bool", optional: true, description: "If true, adds in front of stage. If false, adds behind. Defaults to false." }
        ],
        examples: [
          { code: "addLuaSprite('mySprite')", description: "Adds sprite behind the stage." },
          { code: "addLuaSprite('mySprite', true)", description: "Adds sprite in front of the stage." }
        ]
      },
      {
        name: "removeLuaSprite",
        signature: "removeLuaSprite(tag:String, ?destroy:Bool = true):Void",
        description: "Removes a Lua Sprite from the scene.",
        parameters: [
          { name: "tag", type: "String", optional: false, description: "Lua Sprite tag name." },
          { name: "destroy", type: "Bool", optional: true, description: "Whether to destroy the sprite entirely. Defaults to true." }
        ]
      },
      {
        name: "luaSpriteExists",
        signature: "luaSpriteExists(tag:String):Bool",
        description: "Returns whether a Lua Sprite with the given tag exists.",
        parameters: [
          { name: "tag", type: "String", optional: false, description: "Lua Sprite tag name to check." }
        ]
      }
    ]
  },
  {
    id: "flxanimate",
    title: "FlxAnimate Functions",
    description: "Work with Adobe Animate Atlas and advanced animation symbols.",
    functions: [
      {
        name: "makeFlxAnimateSprite",
        signature: "makeFlxAnimateSprite(tag:String, ?folderOrImg:String = null, ?x:Float = 0, ?y:Float = 0, ?animationJson:String = null):Void",
        description: "Creates a Lua Sprite that can use Animate Atlas.",
        parameters: [
          { name: "tag", type: "String", optional: false, description: "Sprite identifier tag." },
          { name: "folderOrImg", type: "String", optional: true, description: "Path to image or atlas folder. Defaults to null." },
          { name: "x", type: "Float", optional: true, description: "X position. Defaults to 0." },
          { name: "y", type: "Float", optional: true, description: "Y position. Defaults to 0." },
          { name: "animationJson", type: "String", optional: true, description: "Path to animation JSON. Defaults to null." }
        ]
      },
      {
        name: "loadAnimateAtlas",
        signature: "loadAnimateAtlas(tag:String, folderOrImg:String, ?animationJson:String = null):Void",
        description: "Loads the Atlas folder for a FlxAnimate sprite.",
        parameters: [
          { name: "tag", type: "String", optional: false, description: "Sprite tag." },
          { name: "folderOrImg", type: "String", optional: false, description: "Path to atlas folder or image." },
          { name: "animationJson", type: "String", optional: true, description: "Path to animation JSON. Defaults to null." }
        ],
        examples: [
          { code: "loadAnimateAtlas('mySprite', 'characters/atlasTest')", description: "Loads atlas for the sprite." }
        ]
      },
      {
        name: "addAnimationBySymbol",
        signature: "addAnimationBySymbol(tag:String, name:String, symbol:String, ?framerate:Float = 24, ?loop:Bool = false):Void",
        description: "Adds an animation using a symbol from Adobe Animate.",
        parameters: [
          { name: "tag", type: "String", optional: false, description: "Sprite tag." },
          { name: "name", type: "String", optional: false, description: "Animation name to register." },
          { name: "symbol", type: "String", optional: false, description: "Symbol identifier in the Animate file." },
          { name: "framerate", type: "Float", optional: true, description: "Animation FPS. Defaults to 24." },
          { name: "loop", type: "Bool", optional: true, description: "Whether animation loops. Defaults to false." }
        ]
      }
    ]
  },
  {
    id: "text",
    title: "Text Functions",
    description: "Create, style, and update Lua text objects on screen.",
    functions: [
      {
        name: "makeLuaText",
        signature: "makeLuaText(tag:String, ?text:String = '', ?width:Int = 0, ?x:Float = 0, ?y:Float = 0, ?size:Int = 16, ?fontName:String = 'Arial'):Void",
        description: "Creates a Lua Text object with styling options.",
        parameters: [
          { name: "tag", type: "String", optional: false, description: "Unique identifier for the text." },
          { name: "text", type: "String", optional: true, description: "Text content to display. Defaults to empty string." },
          { name: "width", type: "Int", optional: true, description: "Text box width. Defaults to 0 (auto)." },
          { name: "x", type: "Float", optional: true, description: "X position on screen. Defaults to 0." },
          { name: "y", type: "Float", optional: true, description: "Y position on screen. Defaults to 0." },
          { name: "size", type: "Int", optional: true, description: "Font size in pixels. Defaults to 16." },
          { name: "fontName", type: "String", optional: true, description: "Font name. Defaults to 'Arial'." }
        ],
        examples: [
          { code: "makeLuaText('myText', 'Hello World', 0, 100, 100, 32)", description: "Creates 32px text at position (100, 100)." }
        ]
      },
      {
        name: "addLuaText",
        signature: "addLuaText(tag:String, ?inFront:Bool = false):Void",
        description: "Adds a Lua Text to the scene.",
        parameters: [
          { name: "tag", type: "String", optional: false, description: "Lua Text tag name." },
          { name: "inFront", type: "Bool", optional: true, description: "If true, adds in front. Defaults to false (behind)." }
        ]
      },
      {
        name: "removeLuaText",
        signature: "removeLuaText(tag:String, ?destroy:Bool = true):Void",
        description: "Removes a Lua Text from the scene.",
        parameters: [
          { name: "tag", type: "String", optional: false, description: "Lua Text tag name." },
          { name: "destroy", type: "Bool", optional: true, description: "Whether to destroy entirely. Defaults to true." }
        ]
      },
      {
        name: "setTextString",
        signature: "setTextString(tag:String, text:String):Void",
        description: "Sets the text content of a Lua Text object.",
        parameters: [
          { name: "tag", type: "String", optional: false, description: "Lua Text tag name." },
          { name: "text", type: "String", optional: false, description: "New text content." }
        ]
      },
      {
        name: "setTextSize",
        signature: "setTextSize(tag:String, size:Int):Void",
        description: "Sets the font size of a Lua Text.",
        parameters: [
          { name: "tag", type: "String", optional: false, description: "Lua Text tag name." },
          { name: "size", type: "Int", optional: false, description: "Font size in pixels." }
        ]
      },
      {
        name: "setTextFont",
        signature: "setTextFont(tag:String, font:String):Void",
        description: "Sets the font of a Lua Text.",
        parameters: [
          { name: "tag", type: "String", optional: false, description: "Lua Text tag name." },
          { name: "font", type: "String", optional: false, description: "Font name (must be available in system or assets)." }
        ]
      },
      {
        name: "luaTextExists",
        signature: "luaTextExists(tag:String):Bool",
        description: "Returns whether a Lua Text with the given tag exists.",
        parameters: [
          { name: "tag", type: "String", optional: false, description: "Lua Text tag name to check." }
        ]
      }
    ]
  },
  {
    id: "sound",
    title: "Sound Functions",
    description: "Play and control sounds and music with volume and pitch control.",
    functions: [
      {
        name: "playSound",
        signature: "playSound(sound:String, ?volume:Float = 1, ?tag:String = null):Void",
        description: "Plays a sound from the 'sounds/' folder.",
        parameters: [
          { name: "sound", type: "String", optional: false, description: "Sound file name without extension (ex. 'confirm', 'missnote1')." },
          { name: "volume", type: "Float", optional: true, description: "Volume level from 0 to 1. Defaults to 1 (full volume)." },
          { name: "tag", type: "String", optional: true, description: "Tag identifier for later control. Defaults to null." }
        ],
        examples: [
          { code: "playSound('confirm')", description: "Plays the confirm sound at full volume." },
          { code: "playSound('missnote1', 0.5)", description: "Plays missnote at 50% volume." }
        ]
      },
      {
        name: "playMusic",
        signature: "playMusic(music:String, ?volume:Float = 1, ?loop:Bool = true, ?tag:String = null):Void",
        description: "Plays music from the 'music/' folder.",
        parameters: [
          { name: "music", type: "String", optional: false, description: "Music file name without extension." },
          { name: "volume", type: "Float", optional: true, description: "Volume level from 0 to 1. Defaults to 1." },
          { name: "loop", type: "Bool", optional: true, description: "Whether music loops. Defaults to true." },
          { name: "tag", type: "String", optional: true, description: "Tag identifier. Defaults to null." }
        ]
      },
      {
        name: "soundFadeIn",
        signature: "soundFadeIn(sound:String, duration:Float, fromVolume:Float, toVolume:Float, ?tag:String = null):Void",
        description: "Fades in a sound over time.",
        parameters: [
          { name: "sound", type: "String", optional: false, description: "Sound file name." },
          { name: "duration", type: "Float", optional: false, description: "Fade duration in seconds." },
          { name: "fromVolume", type: "Float", optional: false, description: "Starting volume (0-1)." },
          { name: "toVolume", type: "Float", optional: false, description: "Ending volume (0-1)." }
        ]
      },
      {
        name: "soundFadeOut",
        signature: "soundFadeOut(sound:String, duration:Float, toVolume:Float, ?tag:String = null):Void",
        description: "Fades out a sound over time.",
        parameters: [
          { name: "sound", type: "String", optional: false, description: "Sound file name or tag." },
          { name: "duration", type: "Float", optional: false, description: "Fade duration in seconds." },
          { name: "toVolume", type: "Float", optional: false, description: "Ending volume (0-1)." }
        ]
      },
      {
        name: "stopSound",
        signature: "stopSound(tag:String):Void",
        description: "Stops a sound completely.",
        parameters: [
          { name: "tag", type: "String", optional: false, description: "Sound tag or file name to stop." }
        ]
      },
      {
        name: "setSoundVolume",
        signature: "setSoundVolume(tag:String, volume:Float):Void",
        description: "Sets the volume of a sound (0.0 to 1.0).",
        parameters: [
          { name: "tag", type: "String", optional: false, description: "Sound tag or file name." },
          { name: "volume", type: "Float", optional: false, description: "Volume level from 0 (silent) to 1 (full)." }
        ]
      }
    ]
  },
  {
    id: "shaders",
    title: "Shaders Functions",
    description: "Load and manage custom shaders with uniform updates.",
    functions: [
      {
        name: "initLuaShader",
        signature: "initLuaShader(name:String):Bool",
        description: "Preloads a Shader .vert/.frag from 'shaders/' folder.",
        examples: ["initLuaShader('myShader')"]
      },
      {
        name: "setSpriteShader",
        signature: "setSpriteShader(tag:String, shaderName:String):Void",
        description: "Applies a shader to a sprite."
      },
      {
        name: "removeSpriteShader",
        signature: "removeSpriteShader(tag:String):Void",
        description: "Removes a shader from a sprite."
      },
      {
        name: "setShaderFloat",
        signature: "setShaderFloat(tag:String, uniform:String, value:Float):Void",
        description: "Sets a float uniform in a shader."
      }
    ]
  },
  {
    id: "camera",
    title: "Camera Functions",
    description: "Control camera movement, follow points, and apply effects like shake, flash, and fade.",
    functions: [
      {
        name: "setCameraScroll",
        signature: "setCameraScroll(x:Float, y:Float):Void",
        description: "Sets the camera's scroll position directly.",
        parameters: [
          { name: "x", type: "Float", optional: false, description: "X scroll position." },
          { name: "y", type: "Float", optional: false, description: "Y scroll position." }
        ]
      },
      {
        name: "cameraSetTarget",
        signature: "cameraSetTarget(character:String):Void",
        description: "Makes the camera follow a character.",
        parameters: [
          { name: "character", type: "String", optional: false, description: "Character name: 'bf', 'dad', 'gf', etc." }
        ],
        examples: [
          { code: "cameraSetTarget('bf')", description: "Camera follows the boyfriend." },
          { code: "cameraSetTarget('dad')", description: "Camera follows the opponent." }
        ]
      },
      {
        name: "cameraShake",
        signature: "cameraShake(camera:String, intensity:Float, duration:Float):Void",
        description: "Creates a camera shake effect.",
        parameters: [
          { name: "camera", type: "String", optional: false, description: "Camera identifier ('hud', 'game', etc)." },
          { name: "intensity", type: "Float", optional: false, description: "Shake strength." },
          { name: "duration", type: "Float", optional: false, description: "Shake duration in seconds." }
        ]
      },
      {
        name: "cameraFlash",
        signature: "cameraFlash(camera:String, color:String, duration:Float, ?forced:Bool = false):Void",
        description: "Flashes the camera with a color.",
        parameters: [
          { name: "camera", type: "String", optional: false, description: "Camera identifier." },
          { name: "color", type: "String", optional: false, description: "Flash color as hex or name." },
          { name: "duration", type: "Float", optional: false, description: "Flash duration in seconds." },
          { name: "forced", type: "Bool", optional: true, description: "Force the flash. Defaults to false." }
        ]
      },
      {
        name: "cameraFade",
        signature: "cameraFade(camera:String, color:String, duration:Float, ?toAlpha:Float = 1, ?fromAlpha:Float = 0):Void",
        description: "Fades the camera in or out.",
        parameters: [
          { name: "camera", type: "String", optional: false, description: "Camera identifier." },
          { name: "color", type: "String", optional: false, description: "Fade color." },
          { name: "duration", type: "Float", optional: false, description: "Fade duration in seconds." },
          { name: "toAlpha", type: "Float", optional: true, description: "End transparency (0-1). Defaults to 1." },
          { name: "fromAlpha", type: "Float", optional: true, description: "Start transparency (0-1). Defaults to 0." }
        ]
      }
    ]
  },
  {
    id: "input",
    title: "Input Functions",
    description: "Detect keyboard, mouse, and gamepad input.",
    functions: [
      {
        name: "mouseClicked",
        signature: "mouseClicked(?button:String = 'left'):Bool",
        description: "Returns whether the mouse button just got clicked this frame.",
        parameters: [
          { name: "button", type: "String", optional: true, description: "Mouse button: 'left', 'right', 'middle'. Defaults to 'left'." }
        ]
      },
      {
        name: "mousePressed",
        signature: "mousePressed(?button:String = 'left'):Bool",
        description: "Returns whether the mouse button is held down.",
        parameters: [
          { name: "button", type: "String", optional: true, description: "Mouse button to check. Defaults to 'left'." }
        ]
      },
      {
        name: "keyJustPressed",
        signature: "keyJustPressed(key:String):Bool",
        description: "Returns whether a key was just pressed.",
        parameters: [
          { name: "key", type: "String", optional: false, description: "Key name (ex. 'enter', 'space', 'escape')." }
        ],
        examples: [
          { code: "keyJustPressed('enter')", description: "Detects Enter key press." },
          { code: "keyJustPressed('space')", description: "Detects Space key press." }
        ]
      },
      {
        name: "keyPressed",
        signature: "keyPressed(key:String):Bool",
        description: "Returns whether a key is held down.",
        parameters: [
          { name: "key", type: "String", optional: false, description: "Key name to check." }
        ]
      },
      {
        name: "getMouseX",
        signature: "getMouseX():Int",
        description: "Gets the mouse X position on screen."
      },
      {
        name: "getMouseY",
        signature: "getMouseY():Int",
        description: "Gets the mouse Y position on screen."
      }
    ]
  },
  {
    id: "tween",
    title: "Tween Functions",
    description: "Create smooth animations over time for objects and values.",
    functions: [
      {
        name: "doTweenX",
        signature: "doTweenX(tag:String, objTag:String, targetX:Float, duration:Float, ?options:Any = null):String",
        description: "Tweens an object's X position.",
        parameters: [
          { name: "tag", type: "String", optional: false, description: "Tween identifier tag." },
          { name: "objTag", type: "String", optional: false, description: "Object (sprite/text) tag to tween." },
          { name: "targetX", type: "Float", optional: false, description: "Target X position." },
          { name: "duration", type: "Float", optional: false, description: "Tween duration in seconds." },
          { name: "options", type: "Any", optional: true, description: "Options table (ex. {ease: 'quadInOut'})." }
        ]
      },
      {
        name: "doTweenY",
        signature: "doTweenY(tag:String, objTag:String, targetY:Float, duration:Float, ?options:Any = null):String",
        description: "Tweens an object's Y position.",
        parameters: [
          { name: "tag", type: "String", optional: false, description: "Tween identifier tag." },
          { name: "objTag", type: "String", optional: false, description: "Object tag to tween." },
          { name: "targetY", type: "Float", optional: false, description: "Target Y position." },
          { name: "duration", type: "Float", optional: false, description: "Tween duration in seconds." }
        ]
      },
      {
        name: "doTweenAlpha",
        signature: "doTweenAlpha(tag:String, objTag:String, targetAlpha:Float, duration:Float, ?options:Any = null):String",
        description: "Tweens an object's transparency (0 = invisible, 1 = opaque).",
        parameters: [
          { name: "tag", type: "String", optional: false, description: "Tween identifier." },
          { name: "objTag", type: "String", optional: false, description: "Object tag." },
          { name: "targetAlpha", type: "Float", optional: false, description: "Target transparency (0-1)." },
          { name: "duration", type: "Float", optional: false, description: "Tween duration in seconds." }
        ]
      },
      {
        name: "doTweenColor",
        signature: "doTweenColor(tag:String, objTag:String, color:String, duration:Float, ?options:Any = null):String",
        description: "Tweens an object's color over time.",
        parameters: [
          { name: "tag", type: "String", optional: false, description: "Tween identifier." },
          { name: "objTag", type: "String", optional: false, description: "Object tag." },
          { name: "color", type: "String", optional: false, description: "Target color (hex or name)." },
          { name: "duration", type: "Float", optional: false, description: "Tween duration in seconds." }
        ]
      },
      {
        name: "doTweenAngle",
        signature: "doTweenAngle(tag:String, objTag:String, targetAngle:Float, duration:Float, ?options:Any = null):String",
        description: "Tweens an object's rotation angle.",
        parameters: [
          { name: "tag", type: "String", optional: false, description: "Tween identifier." },
          { name: "objTag", type: "String", optional: false, description: "Object tag." },
          { name: "targetAngle", type: "Float", optional: false, description: "Target rotation in degrees." },
          { name: "duration", type: "Float", optional: false, description: "Tween duration in seconds." }
        ]
      },
      {
        name: "cancelTween",
        signature: "cancelTween(tag:String):Void",
        description: "Cancels a tween before it completes.",
        parameters: [
          { name: "tag", type: "String", optional: false, description: "Tween tag to cancel." }
        ]
      }
    ]
  },
  {
    id: "timer",
    title: "Timer Functions",
    description: "Schedule Lua code to run after delays or repeating intervals.",
    functions: [
      {
        name: "runTimer",
        signature: "runTimer(tmrTag:String, ?time:Float = 1.0, ?loops:Int = 1):String",
        description: "Runs a timer that triggers the 'onTimerCompleted' callback.",
        parameters: [
          { name: "tmrTag", type: "String", optional: false, description: "Timer identifier tag." },
          { name: "time", type: "Float", optional: true, description: "Timer duration in seconds. Defaults to 1.0." },
          { name: "loops", type: "Int", optional: true, description: "Number of repetitions. Defaults to 1." }
        ],
        examples: [
          { code: "runTimer('myTimer', 1.0)", description: "Runs timer for 1 second." },
          { code: "runTimer('myTimer', 2.5, 3)", description: "Runs timer 3 times, 2.5 seconds each." }
        ]
      },
      {
        name: "cancelTimer",
        signature: "cancelTimer(tag:String):Void",
        description: "Cancels a timer before it completes.",
        parameters: [
          { name: "tag", type: "String", optional: false, description: "Timer tag to cancel." }
        ]
      }
    ]
  },
  {
    id: "character",
    title: "Character Functions",
    description: "Control character positions and animations.",
    functions: [
      {
        name: "getCharacterX",
        signature: "getCharacterX(character:String):Float",
        description: "Gets a character's X position.",
        parameters: [
          { name: "character", type: "String", optional: false, description: "Character name ('bf', 'dad', 'gf', etc)." }
        ],
        examples: [
          { code: "getCharacterX('bf')", description: "Gets boyfriend's X position." },
          { code: "getCharacterX('dad')", description: "Gets opponent's X position." }
        ]
      },
      {
        name: "getCharacterY",
        signature: "getCharacterY(character:String):Float",
        description: "Gets a character's Y position.",
        parameters: [
          { name: "character", type: "String", optional: false, description: "Character name." }
        ]
      },
      {
        name: "setCharacterX",
        signature: "setCharacterX(character:String, x:Float):Void",
        description: "Sets a character's X position.",
        parameters: [
          { name: "character", type: "String", optional: false, description: "Character name." },
          { name: "x", type: "Float", optional: false, description: "New X position." }
        ]
      },
      {
        name: "setCharacterY",
        signature: "setCharacterY(character:String, y:Float):Void",
        description: "Sets a character's Y position.",
        parameters: [
          { name: "character", type: "String", optional: false, description: "Character name." },
          { name: "y", type: "Float", optional: false, description: "New Y position." }
        ]
      },
      {
        name: "characterDance",
        signature: "characterDance(character:String):Void",
        description: "Makes a character play their idle/dance animation.",
        parameters: [
          { name: "character", type: "String", optional: false, description: "Character name." }
        ]
      }
    ]
  },
  {
    id: "substate",
    title: "Substate Functions",
    description: "Create custom menus and UI substates.",
    functions: [
      {
        name: "openCustomSubstate",
        signature: "openCustomSubstate(name:String, ?pauseGame:Bool = false):Void",
        description: "Opens an empty custom substate.",
        parameters: [
          { name: "name", type: "String", optional: false, description: "Substate name identifier." },
          { name: "pauseGame", type: "Bool", optional: true, description: "Whether game is paused. Defaults to false." }
        ],
        examples: [
          { code: "openCustomSubstate('custom_substate')", description: "Opens custom substate." },
          { code: "openCustomSubstate('custom_pause_menu', true)", description: "Opens pause menu substate." }
        ]
      },
      {
        name: "closeCustomSubstate",
        signature: "closeCustomSubstate():Void",
        description: "Closes the currently open custom substate."
      }
    ]
  },
  {
    id: "discord",
    title: "Discord Functions",
    description: "Update Discord Rich Presence status.",
    functions: [
      {
        name: "changeDiscordPresence",
        signature: "changeDiscordPresence(details:String = 'In the Menus', ?state:String, ?smallImageKey:String, ?largeImageKey:String):Void",
        description: "Updates Discord rich presence with custom text and images.",
        parameters: [
          { name: "details", type: "String", optional: true, description: "Main text shown in presence. Defaults to 'In the Menus'." },
          { name: "state", type: "String", optional: true, description: "Secondary text. Defaults to null." },
          { name: "smallImageKey", type: "String", optional: true, description: "Small image identifier. Defaults to null." },
          { name: "largeImageKey", type: "String", optional: true, description: "Large image identifier. Defaults to null." }
        ]
      },
      {
        name: "changeDiscordClientID",
        signature: "changeDiscordClientID(clientID:String):Void",
        description: "Changes the Discord application ID being used.",
        parameters: [
          { name: "clientID", type: "String", optional: false, description: "Discord application/client ID." }
        ]
      }
    ]
  },
  {
    id: "achievements",
    title: "Achievements Functions",
    description: "Read and update softcoded achievement progress.",
    functions: [
      {
        name: "getAchievementScore",
        signature: "getAchievementScore(name:String):Float",
        description: "Returns the score/progress for an achievement with counters.",
        parameters: [
          { name: "name", type: "String", optional: false, description: "Achievement name identifier." }
        ]
      },
      {
        name: "setAchievementScore",
        signature: "setAchievementScore(name:String, value:Float):Void",
        description: "Sets the progress/score of an achievement.",
        parameters: [
          { name: "name", type: "String", optional: false, description: "Achievement name." },
          { name: "value", type: "Float", optional: false, description: "New progress value." }
        ]
      },
      {
        name: "addAchievementScore",
        signature: "addAchievementScore(name:String, value:Float):Void",
        description: "Adds to an achievement's score.",
        parameters: [
          { name: "name", type: "String", optional: false, description: "Achievement name." },
          { name: "value", type: "Float", optional: false, description: "Amount to add." }
        ]
      },
      {
        name: "unlockAchievement",
        signature: "unlockAchievement(name:String):Void",
        description: "Unlocks an achievement.",
        parameters: [
          { name: "name", type: "String", optional: false, description: "Achievement name." }
        ]
      },
      {
        name: "isAchievementUnlocked",
        signature: "isAchievementUnlocked(name:String):Bool",
        description: "Returns whether an achievement is unlocked.",
        parameters: [
          { name: "name", type: "String", optional: false, description: "Achievement name." }
        ]
      }
    ]
  },
  {
    id: "translations",
    title: "Language/Translation Functions",
    description: "Build translatable mods with multi-language support.",
    functions: [
      {
        name: "getTranslationPhrase",
        signature: "getTranslationPhrase(key:String, ?defaultPhrase:String, ?args:Array<Dynamic> = null):String",
        description: "Gets a translated phrase by key with optional parameter replacement.",
        parameters: [
          { name: "key", type: "String", optional: false, description: "Translation key identifier." },
          { name: "defaultPhrase", type: "String", optional: true, description: "Fallback if key not found. Defaults to key itself." },
          { name: "args", type: "Array<Dynamic>", optional: true, description: "Replacement arguments. Defaults to null." }
        ]
      },
      {
        name: "getFileTranslation",
        signature: "getFileTranslation(file:String, ?ignoreModFolders:Bool = false):Dynamic",
        description: "Loads a translation file and returns its contents.",
        parameters: [
          { name: "file", type: "String", optional: false, description: "Translation file path." },
          { name: "ignoreModFolders", type: "Bool", optional: true, description: "Ignore mod folder files. Defaults to false." }
        ]
      }
    ]
  },
  {
    id: "precache",
    title: "Precache Functions",
    description: "Preload assets to prevent stuttering during gameplay.",
    functions: [
      {
        name: "precacheImage",
        signature: "precacheImage(file:String, ?allowGPU:Bool = true):Void",
        description: "Precaches an image file from 'images/' folder.",
        parameters: [
          { name: "file", type: "String", optional: false, description: "Image file path (without 'images/' prefix)." },
          { name: "allowGPU", type: "Bool", optional: true, description: "Allow GPU caching. Defaults to true." }
        ]
      },
      {
        name: "precacheSound",
        signature: "precacheSound(file:String):Void",
        description: "Precaches a sound file from 'sounds/' folder.",
        parameters: [
          { name: "file", type: "String", optional: false, description: "Sound file path (without 'sounds/' prefix)." }
        ]
      },
      {
        name: "precacheMusic",
        signature: "precacheMusic(file:String):Void",
        description: "Precaches a music file from 'music/' folder.",
        parameters: [
          { name: "file", type: "String", optional: false, description: "Music file path (without 'music/' prefix)." }
        ]
      }
    ]
  },
  {
    id: "score",
    title: "Score Functions",
    description: "Control score, misses, hits, health, and rating display.",
    functions: [
      {
        name: "addScore",
        signature: "addScore(value:Int):Void",
        description: "Adds to the current score.",
        parameters: [
          { name: "value", type: "Int", optional: false, description: "Points to add." }
        ]
      },
      {
        name: "setScore",
        signature: "setScore(value:Int):Void",
        description: "Sets the score to a specific value.",
        parameters: [
          { name: "value", type: "Int", optional: false, description: "New score value." }
        ]
      },
      {
        name: "addMisses",
        signature: "addMisses(value:Int):Void",
        description: "Adds to the miss counter.",
        parameters: [
          { name: "value", type: "Int", optional: false, description: "Misses to add." }
        ]
      },
      {
        name: "setMisses",
        signature: "setMisses(value:Int):Void",
        description: "Sets the miss count.",
        parameters: [
          { name: "value", type: "Int", optional: false, description: "New miss count." }
        ]
      },
      {
        name: "addHits",
        signature: "addHits(value:Int):Void",
        description: "Adds to the hit counter.",
        parameters: [
          { name: "value", type: "Int", optional: false, description: "Hits to add." }
        ]
      },
      {
        name: "addHealth",
        signature: "addHealth(value:Float):Void",
        description: "Adds to the player's health.",
        parameters: [
          { name: "value", type: "Float", optional: false, description: "Health amount to add." }
        ]
      },
      {
        name: "setHealth",
        signature: "setHealth(?value:Float = 1):Void",
        description: "Sets health (0 = dead, 2 = full health).",
        parameters: [
          { name: "value", type: "Float", optional: true, description: "Health value (0-2). Defaults to 1." }
        ]
      }
    ]
  },
  {
    id: "savedata",
    title: "Save Data Functions",
    description: "Initialize and manage save slots for persistent data storage.",
    functions: [
      {
        name: "initSaveData",
        signature: "initSaveData(save:String, ?folder:String = 'psychenginemods'):Void",
        description: "Initializes a save data file.",
        parameters: [
          { name: "save", type: "String", optional: false, description: "Save identifier/filename." },
          { name: "folder", type: "String", optional: true, description: "Save folder. Defaults to 'psychenginemods'." }
        ]
      },
      {
        name: "flushSaveData",
        signature: "flushSaveData(save:String):Void",
        description: "Saves data to file.",
        parameters: [
          { name: "save", type: "String", optional: false, description: "Save identifier." }
        ]
      },
      {
        name: "eraseSaveData",
        signature: "eraseSaveData(save:String, ?folder:String = 'psychenginemods'):Void",
        description: "Deletes a save file.",
        parameters: [
          { name: "save", type: "String", optional: false, description: "Save identifier." },
          { name: "folder", type: "String", optional: true, description: "Save folder. Defaults to 'psychenginemods'." }
        ]
      },
      {
        name: "getDataFromSave",
        signature: "getDataFromSave(save:String, key:String, ?defaultValue:Dynamic = null):Dynamic",
        description: "Reads a value from save data.",
        parameters: [
          { name: "save", type: "String", optional: false, description: "Save identifier." },
          { name: "key", type: "String", optional: false, description: "Data key to retrieve." },
          { name: "defaultValue", type: "Dynamic", optional: true, description: "Value if key missing. Defaults to null." }
        ],
        examples: [
          { code: "getDataFromSave('playerSave', 'level', 1)", description: "Gets level, defaults to 1 if missing." }
        ]
      },
      {
        name: "setDataFromSave",
        signature: "setDataFromSave(save:String, key:String, value:Dynamic):Void",
        description: "Writes a value to save data.",
        parameters: [
          { name: "save", type: "String", optional: false, description: "Save identifier." },
          { name: "key", type: "String", optional: false, description: "Data key." },
          { name: "value", type: "Dynamic", optional: false, description: "Value to save." }
        ],
        examples: [
          { code: "setDataFromSave('playerSave', 'level', 5)", description: "Sets level to 5." }
        ]
      }
    ]
  },
  {
    id: "file",
    title: "File I/O Functions",
    description: "Read, write, and manage external files for custom data.",
    functions: [
      {
        name: "getTextFromFile",
        signature: "getTextFromFile(path:String, ?ignoreModFolders:Bool = false):String",
        description: "Reads a text file and returns its content.",
        parameters: [
          { name: "path", type: "String", optional: false, description: "File path to read." },
          { name: "ignoreModFolders", type: "Bool", optional: true, description: "Ignore mod folder paths. Defaults to false." }
        ]
      },
      {
        name: "checkFileExists",
        signature: "checkFileExists(file:String, ?absolute:Bool = false):Bool",
        description: "Returns true if a file exists.",
        parameters: [
          { name: "file", type: "String", optional: false, description: "File path to check." },
          { name: "absolute", type: "Bool", optional: true, description: "Use absolute path. Defaults to false." }
        ],
        examples: [
          { code: "checkFileExists('data/myFile.json')", description: "Checks relative path." },
          { code: "checkFileExists('mods/My-Mod/data/myFile.json', true)", description: "Checks absolute path." }
        ]
      },
      {
        name: "saveFile",
        signature: "saveFile(file:String, content:String, ?absolute:Bool = false):Void",
        description: "Saves content to a file.",
        parameters: [
          { name: "file", type: "String", optional: false, description: "File path to save to." },
          { name: "content", type: "String", optional: false, description: "Content to write." },
          { name: "absolute", type: "Bool", optional: true, description: "Use absolute path. Defaults to false." }
        ]
      },
      {
        name: "deleteFile",
        signature: "deleteFile(file:String, ?absolute:Bool = false):Void",
        description: "Deletes a file.",
        parameters: [
          { name: "file", type: "String", optional: false, description: "File path to delete." },
          { name: "absolute", type: "Bool", optional: true, description: "Use absolute path. Defaults to false." }
        ]
      },
      {
        name: "directoryFileList",
        signature: "directoryFileList(directory:String, ?absolute:Bool = false):Array<String>",
        description: "Lists all files in a directory.",
        parameters: [
          { name: "directory", type: "String", optional: false, description: "Directory path to list." },
          { name: "absolute", type: "Bool", optional: true, description: "Use absolute path. Defaults to false." }
        ]
      }
    ]
  },
  {
    id: "script",
    title: "Script Functions",
    description: "Communicate between Lua scripts, HScript, and run Haxe code.",
    functions: [
      {
        name: "getRunningScripts",
        signature: "getRunningScripts():Array<String>",
        description: "Returns a table with paths of all running Lua scripts.",
        parameters: []
      },
      {
        name: "callScript",
        signature: "callScript(luaFile:String, ?ignoreAlreadyRunning:Bool = false):Void",
        description: "Initializes a new Lua script.",
        parameters: [
          { name: "luaFile", type: "String", optional: false, description: "Script file path." },
          { name: "ignoreAlreadyRunning", type: "Bool", optional: true, description: "Skip if already running. Defaults to false." }
        ],
        examples: [
          { code: "callScript('mods/scripts/disabled/test.lua')", description: "Loads absolute path." },
          { code: "callScript('scripts/disabled/test')", description: "Loads script by name." }
        ]
      },
      {
        name: "addLuaScript",
        signature: "addLuaScript(luaFile:String, ?ignoreAlreadyRunning:Bool = false):Void",
        description: "Adds a Lua script without immediately running callbacks.",
        parameters: [
          { name: "luaFile", type: "String", optional: false, description: "Script file path." },
          { name: "ignoreAlreadyRunning", type: "Bool", optional: true, description: "Skip if already running. Defaults to false." }
        ]
      },
      {
        name: "removeLuaScript",
        signature: "removeLuaScript(luaFile:String):Void",
        description: "Removes a running Lua script.",
        parameters: [
          { name: "luaFile", type: "String", optional: false, description: "Script file path to remove." }
        ]
      },
      {
        name: "isRunning",
        signature: "isRunning(luaFile:String):Bool",
        description: "Checks if a script is currently running.",
        parameters: [
          { name: "luaFile", type: "String", optional: false, description: "Script file path to check." }
        ]
      },
      {
        name: "setVar",
        signature: "setVar(varName:String, value:Dynamic):Void",
        description: "Saves a variable accessible to all scripts.",
        parameters: [
          { name: "varName", type: "String", optional: false, description: "Variable name identifier." },
          { name: "value", type: "Dynamic", optional: false, description: "Value to store." }
        ],
        examples: [
          { code: "setVar('storedValue', 10.5)", description: "Stores a numeric value for other scripts." }
        ]
      },
      {
        name: "getVar",
        signature: "getVar(varName:String):Dynamic",
        description: "Gets a variable saved with setVar.",
        parameters: [
          { name: "varName", type: "String", optional: false, description: "Variable name to retrieve." }
        ],
        examples: [
          { code: "getVar('storedValue')", description: "Retrieves previously stored variable." }
        ]
      },
      {
        name: "callOnScripts",
        signature: "callOnScripts(funcName:String, ?args:Array<Dynamic> = null, ?ignoreStops:Bool = false, ?ignoreSelf:Bool = true, ?exclusions:Array<String> = null):Dynamic",
        description: "Calls a function on all running scripts.",
        parameters: [
          { name: "funcName", type: "String", optional: false, description: "Function name to call." },
          { name: "args", type: "Array<Dynamic>", optional: true, description: "Function arguments. Defaults to null." },
          { name: "ignoreStops", type: "Bool", optional: true, description: "Ignore return false. Defaults to false." },
          { name: "ignoreSelf", type: "Bool", optional: true, description: "Ignore calling script. Defaults to true." },
          { name: "exclusions", type: "Array<String>", optional: true, description: "Scripts to exclude. Defaults to null." }
        ],
        examples: [
          { code: "callOnScripts('customFunction', {1})", description: "Calls function with arguments on all scripts." }
        ]
      },
      {
        name: "runHaxeCode",
        signature: "runHaxeCode(codeToRun:String, ?varsToBring:Any = null, ?funcToRun:String = null, ?funcArgs:Array<Dynamic> = null):Dynamic",
        description: "Runs Haxe code inside a Lua script.",
        parameters: [
          { name: "codeToRun", type: "String", optional: false, description: "Haxe code to execute." },
          { name: "varsToBring", type: "Any", optional: true, description: "Variables to expose to Haxe. Defaults to null." },
          { name: "funcToRun", type: "String", optional: true, description: "Function to run after code. Defaults to null." },
          { name: "funcArgs", type: "Array<Dynamic>", optional: true, description: "Function arguments. Defaults to null." }
        ],
        examples: [
          { code: "runHaxeCode('game.boyfriend.color = FlxColor.RED;')", description: "Changes boyfriend color via Haxe." }
        ]
      },
      {
        name: "close",
        signature: "close():Void",
        description: "Closes the current Lua script."
      }
    ]
  },
  {
    id: "uncategorized",
    title: "Uncategorized Functions",
    description: "Utility helpers for colors, strings, random values, and debugging.",
    functions: [
      {
        name: "FlxColor",
        signature: "FlxColor(color:String):Int",
        description: "Converts a color string/hex to an integer value.",
        parameters: [
          { name: "color", type: "String", optional: false, description: "Color name or hex value (ex. 'FF0000', 'red')." }
        ],
        examples: [
          { code: "FlxColor('FF0000')", description: "Convert hex to integer." },
          { code: "FlxColor('red')", description: "Convert color name to integer." }
        ]
      },
      {
        name: "getColorFromName",
        signature: "getColorFromName(name:String):Int",
        description: "Gets an integer color value from a color name.",
        parameters: [
          { name: "name", type: "String", optional: false, description: "Color name (ex. 'red', 'blue', 'white')." }
        ]
      },
      {
        name: "getColorFromString",
        signature: "getColorFromString(value:String):Int",
        description: "Gets an integer color value from a hex string.",
        parameters: [
          { name: "value", type: "String", optional: false, description: "Hex color string (ex. 'FF0000', '#FF0000')." }
        ]
      },
      {
        name: "stringSplit",
        signature: "stringSplit(string:String, separator:String):Array<String>",
        description: "Splits a string by separator.",
        parameters: [
          { name: "string", type: "String", optional: false, description: "String to split." },
          { name: "separator", type: "String", optional: false, description: "Delimiter to split on." }
        ],
        examples: [
          { code: "stringSplit('hello,world', ',')", description: "Splits by comma." }
        ]
      },
      {
        name: "stringStartsWith",
        signature: "stringStartsWith(string:String, start:String):Bool",
        description: "Returns true if string starts with the specified text.",
        parameters: [
          { name: "string", type: "String", optional: false, description: "String to check." },
          { name: "start", type: "String", optional: false, description: "Expected start text." }
        ]
      },
      {
        name: "stringEndsWith",
        signature: "stringEndsWith(string:String, end:String):Bool",
        description: "Returns true if string ends with the specified text.",
        parameters: [
          { name: "string", type: "String", optional: false, description: "String to check." },
          { name: "end", type: "String", optional: false, description: "Expected end text." }
        ]
      },
      {
        name: "stringTrim",
        signature: "stringTrim(string:String):String",
        description: "Removes whitespace from start and end of string.",
        parameters: [
          { name: "string", type: "String", optional: false, description: "String to trim." }
        ]
      },
      {
        name: "getRandomBool",
        signature: "getRandomBool(?chance:Float = 0.5):Bool",
        description: "Returns a random boolean value.",
        parameters: [
          { name: "chance", type: "Float", optional: true, description: "Probability (0-1). Defaults to 0.5 (50%)." }
        ],
        examples: [
          { code: "getRandomBool()", description: "50% chance to return true." },
          { code: "getRandomBool(0.75)", description: "75% chance to return true." }
        ]
      },
      {
        name: "getRandomInt",
        signature: "getRandomInt(min:Int, ?max:Int = 1, ?exclude:String = ''):Int",
        description: "Returns a random integer between min and max.",
        parameters: [
          { name: "min", type: "Int", optional: false, description: "Minimum value (inclusive)." },
          { name: "max", type: "Int", optional: true, description: "Maximum value (inclusive). Defaults to 1." },
          { name: "exclude", type: "String", optional: true, description: "Numbers to exclude (comma-separated). Defaults to empty." }
        ],
        examples: [
          { code: "getRandomInt(1, 5)", description: "Random integer 1-5." },
          { code: "getRandomInt(1, 8, '3, 4')", description: "Random 1-8 except 3 and 4." }
        ]
      },
      {
        name: "debugPrint",
        signature: "debugPrint(text:String, ?color:String = null):Void",
        description: "Prints debug text to the console with optional color.",
        parameters: [
          { name: "text", type: "String", optional: false, description: "Text to print." },
          { name: "color", type: "String", optional: true, description: "Text color (hex or name). Defaults to white." }
        ]
      },
      {
        name: "getModSetting",
        signature: "getModSetting(save:String, variable:String):Dynamic",
        description: "Gets a mod setting value.",
        parameters: [
          { name: "save", type: "String", optional: false, description: "Save/mod identifier." },
          { name: "variable", type: "String", optional: false, description: "Setting variable name." }
        ]
      }
    ]
  }
];

function normalize(value) {
  return value.toLowerCase().trim();
}

function renderNavigation(categories) {
  const nav = document.getElementById("categoryNav");
  nav.innerHTML = categories
    .map((cat) => `<a href="#${cat.id}">${cat.title}</a>`)
    .join("");
}

function renderSections(categories, filterText = "") {
  const container = document.getElementById("functionSections");
  const query = normalize(filterText);
  const filtered = categories.filter((category) => {
    if (!query) {
      return true;
    }
    const haystack = `${category.title} ${category.description} ${category.functions
      .map((f) => `${f.name} ${f.description || ""}`)
      .join(" ")}`
      .toLowerCase();
    return haystack.includes(query);
  });

  if (filtered.length === 0) {
    container.innerHTML = `
      <article class="card function-group">
        <h3>No matches found</h3>
        <p>Try another keyword, like setProperty, runTimer, or playSound.</p>
      </article>
    `;
    return;
  }

  container.innerHTML = filtered
    .map(
      (category) => `
      <article class="card function-group" id="${category.id}">
        <h3>${category.title}</h3>
        <p>${category.description}</p>
        <div class="function-list">
          ${category.functions
            .map(
              (fn) => `
            <div class="function-item">
              <h2 id="${fn.name}">${fn.name}</h2>
              <p class="function-sig"><code>${fn.signature}</code></p>
              <p class="function-desc">${fn.description}</p>
              ${
                fn.parameters && fn.parameters.length > 0
                  ? `<ul class="function-params">
                      ${fn.parameters.map((param) => `
                        <li><strong>${param.name}</strong>${param.optional ? ' (Optional)' : ''} - <em>${param.type}</em><br>${param.description}</li>
                      `).join('')}
                    </ul>`
                  : ""
              }
              ${
                fn.examples && fn.examples.length > 0
                  ? `<div class="function-examples">
                      <strong>Examples:</strong>
                      ${Array.isArray(fn.examples[0]) || (fn.examples[0] && fn.examples[0].code !== undefined)
                        ? fn.examples.map((ex) => `<div class="example-item"><code>${ex.code || ex}</code><p>${ex.description || ''}</p></div>`).join('')
                        : fn.examples.map((ex) => `<div class="example-item"><code>${ex}</code></div>`).join('')
                      }
                    </div>`
                  : ""
              }
            </div>
          `
            )
            .join("")}
        </div>
      </article>
    `
    )
    .join("");
}

(function initPsychPage() {
  const searchInput = document.getElementById("functionSearch");
  if (!searchInput) {
    return;
  }

  renderNavigation(psychCategories);
  renderSections(psychCategories);

  searchInput.addEventListener("input", (event) => {
    renderSections(psychCategories, event.target.value);
  });
})();

window.psychCategories = psychCategories;
