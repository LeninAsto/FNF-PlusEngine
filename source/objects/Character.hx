package objects;

import backend.animation.PsychAnimationController;
import backend.AssetLoader;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.util.FlxSort;
import flixel.util.FlxDestroyUtil;
import haxe.Json;
import backend.Song;

typedef CharacterFile =
{
	var animations:Array<AnimArray>;
	var image:String;
	var scale:Float;
	var sing_duration:Float;
	var healthicon:String;

	var position:Array<Float>;
	var camera_position:Array<Float>;

	var flip_x:Bool;
	var no_antialiasing:Bool;
	var healthbar_colors:Array<Int>;
	var vocals_file:String;
	@:optional var _editor_isPlayer:Null<Bool>;
	@:optional var animatedIcon:Bool;
	@:optional var renderType:String;
	@:optional var assetPath:String;
}

typedef AnimArray =
{
	var anim:String;
	var name:String;
	var fps:Int;
	var loop:Bool;
	var indices:Array<Int>;
	var offsets:Array<Int>;
	@:optional var renderType:String;
	@:optional var assetPath:String;
	@:optional var animType:String;
}

class Character extends FlxSprite
{
	/**
	 * In case a character is missing, it will use this on its place
	**/
	public static final DEFAULT_CHARACTER:String = 'bf';

	public var animOffsets:Map<String, Array<Dynamic>>;
	public var debugMode:Bool = false;
	public var extraData:Map<String, Dynamic> = new Map<String, Dynamic>();

	public var isPlayer:Bool = false;
	public var curCharacter:String = DEFAULT_CHARACTER;
	public var animatedIcon:Bool = false;

	public var holdTimer:Float = 0;
	public var heyTimer:Float = 0;
	public var specialAnim:Bool = false;
	public var animationNotes:Array<Dynamic> = [];
	public var stunned:Bool = false;
	public var singDuration:Float = 4; // Multiplier of how long a character holds the sing pose
	public var idleSuffix:String = '';
	public var danceIdle:Bool = false; // Character use "danceLeft" and "danceRight" instead of "idle"
	public var skipDance:Bool = false;

	public var healthIcon:String = 'face';
	public var animationsArray:Array<AnimArray> = [];
	public var renderType:String = 'sparrow';

	public var positionArray:Array<Float> = [0, 0];
	public var cameraPosition:Array<Float> = [0, 0];
	public var healthColorArray:Array<Int> = [255, 0, 0];

	public var missingCharacter:Bool = false;
	public var missingText:FlxText;
	public var hasMissAnimations:Bool = false;
	public var vocalsFile:String = '';

	// Used on Character Editor
	public var imageFile:String = '';
	public var jsonScale:Float = 1;
	public var noAntialiasing:Bool = false;
	public var originalFlipX:Bool = false;
	public var editorIsPlayer:Null<Bool> = null;
	var animateAnimationMap:Map<String, Bool> = new Map<String, Bool>();

	public function new(x:Float, y:Float, ?character:String = 'bf', ?isPlayer:Bool = false)
	{
		super(x, y);

		animation = new PsychAnimationController(this);

		animOffsets = new Map<String, Array<Dynamic>>();
		this.isPlayer = isPlayer;
		changeCharacter(character);

		switch (curCharacter)
		{
			case 'pico-speaker':
				skipDance = true;
				loadMappedAnims();
				playAnim("shoot1");
			case 'pico-blazin', 'darnell-blazin':
				skipDance = true;
		}
	}

	public function changeCharacter(character:String)
	{
		animationsArray = [];
		animOffsets = [];
		curCharacter = character;
		var characterPath:String = 'characters/$character.json';

		var path:String = Paths.getPath(characterPath, TEXT);
		if (!AssetLoader.exists(path, TEXT))
		{
			path = Paths.getSharedPath('characters/' + DEFAULT_CHARACTER +
				'.json'); // If a character couldn't be found, change him to BF just to prevent a crash
			missingCharacter = true;
			missingText = new FlxText(0, 0, 300, 'ERROR:\n$character.json', 16);
			missingText.alignment = CENTER;
		}

		try
		{
			var rawJson:String = AssetLoader.loadText(path);
			if (rawJson == null || rawJson.length == 0)
				throw 'Missing character file: $path';
			loadCharacterFile(Json.parse(rawJson));
		}
		catch (e:Dynamic)
		{
			trace('Error loading character file of "$character": $e');
		}

		skipDance = false;
		hasMissAnimations = hasAnimation('singLEFTmiss') || hasAnimation('singDOWNmiss') || hasAnimation('singUPmiss') || hasAnimation('singRIGHTmiss');
		recalculateDanceIdle();
		dance();
	}

	public function loadCharacterFile(json:Dynamic)
	{
		isAnimateAtlas = false;
		animateAnimationMap = new Map<String, Bool>();

		var isVSlice:Bool = (json.assetPath != null)
			|| (json.animations != null && json.animations.length > 0 && json.animations[0].prefix != null);

		if (isVSlice)
		{
			trace('V-Slice character JSON detected and converted');

			if (json.assetPath != null)
			{
				json.assetPath = normalizeAssetPath(json.assetPath);
				json.image = json.assetPath;
			}

			if (json.flipX != null)
				json.flip_x = json.flipX;
			if (json.cameraOffsets != null)
				json.camera_position = json.cameraOffsets;
			if (json.singTime != null)
				json.sing_duration = json.singTime;
			if (json.isPixel != null)
				json.no_antialiasing = json.isPixel;

			if (json.healthIcon != null && json.healthIcon.id != null)
				json.healthicon = json.healthIcon.id;

			if (json.offsets != null)
				json.position = json.offsets;

			if (json.animations != null)
			{
				var anims:Array<Dynamic> = (json.animations : Array<Dynamic>);
				var newAnims:Array<Dynamic> = new Array<Dynamic>();

				for (a in anims)
				{
					var na:Dynamic = {
						anim: (a.name != null && a.name != '') ? a.name : (a.anim != null ? a.anim : ''),
						name: (a.prefix != null && a.prefix != '') ? a.prefix : (a.animation != null ? a.animation : ''),
						fps: (a.frameRate != null) ? a.frameRate : (a.fps != null ? a.fps : 24),
						loop: (a.looped != null) ? a.looped : (a.loop != null ? a.loop : false),
						indices: (a.frameIndices != null) ? a.frameIndices : (a.indices != null ? a.indices : []),
						offsets: (a.offsets != null) ? a.offsets : [0, 0],
						renderType: (a.renderType != null) ? a.renderType : null,
						assetPath: (a.assetPath != null) ? normalizeAssetPath(a.assetPath) : null,
						animType: (a.animType != null) ? a.animType : null
					};

					newAnims.push(na);
				}
				json.animations = newAnims;
			}
		}

		if (json.image == null && json.assetPath != null)
			json.image = normalizeAssetPath(json.assetPath);
		if (json.image == null)
			json.image = '';
		if (json.scale == null)
			json.scale = 1;
		if (json.position == null)
			json.position = [0, 0];
		if (json.camera_position == null)
			json.camera_position = [0, 0];
		if (json.sing_duration == null)
			json.sing_duration = 4;
		if (json.healthicon == null)
			json.healthicon = 'face';
		if (json.flip_x == null)
			json.flip_x = false;
		if (json.animations == null)
			json.animations = [];

		var hasExplicitRenderType:Bool = json.renderType != null;
		renderType = normalizeRenderType(json.renderType);
		#if flxanimate
		var autoAnimateAtlas:Bool = !hasExplicitRenderType && Paths.hasAnimateAtlas(json.image) && (isVSlice || !hasClassicAtlas(json.image));
		if (usesAnimateAtlas(renderType) || autoAnimateAtlas)
		{
			isAnimateAtlas = true;
			if (autoAnimateAtlas)
				renderType = 'animateatlas';
		}
		#end

		scale.set(1, 1);
		updateHitbox();

		if (!isAnimateAtlas)
		{
			frames = loadClassicFrames(json.image, json.animations, renderType);
		}
		#if flxanimate
		else
		{
			atlas = new FlxAnimate();
			atlas.showPivot = false;
			try
			{
				Paths.loadAnimateAtlas(atlas, getAnimateAtlasKeys(json.image, json.animations));
			}
			catch (e:haxe.Exception)
			{
				FlxG.log.warn('Could not load atlas ${json.image}: $e');
				trace(e.stack);
			}
			frames = loadClassicFrames(null, json.animations, renderType);
		}
		#end

		imageFile = json.image;
		jsonScale = json.scale;
		if (json.scale != 1)
		{
			scale.set(jsonScale, jsonScale);
			updateHitbox();
		}

		// positioning
		positionArray = json.position;
		cameraPosition = json.camera_position;

		// data
		healthIcon = json.healthicon;
		singDuration = json.sing_duration;
		flipX = (json.flip_x != isPlayer);
		healthColorArray = (json.healthbar_colors != null && json.healthbar_colors.length > 2) ? json.healthbar_colors : [161, 161, 161];
		vocalsFile = json.vocals_file != null ? json.vocals_file : '';
		animatedIcon = (json.animatedIcon == true);
		originalFlipX = (json.flip_x == true);
		editorIsPlayer = json._editor_isPlayer; // antialiasing
		noAntialiasing = (json.no_antialiasing == true);
		antialiasing = ClientPrefs.data.antialiasing ? !noAntialiasing : false;

		// animations
		animationsArray = json.animations;
		if (animationsArray != null && animationsArray.length > 0)
		{
			for (anim in animationsArray)
			{
				var animAnim:String = '' + anim.anim;
				var animName:String = '' + anim.name;
				var animFps:Int = anim.fps;
				var animLoop:Bool = !!anim.loop; // Bruh
				var animIndices:Array<Int> = anim.indices;
				var useAnimate:Bool = isAnimateAnimation(anim, renderType);
				animateAnimationMap.set(animAnim, useAnimate);

				if (!isAnimateAtlas || !useAnimate)
				{
					if (animIndices != null && animIndices.length > 0)
						animation.addByIndices(animAnim, animName, animIndices, "", animFps, animLoop);
					else
						animation.addByPrefix(animAnim, animName, animFps, animLoop);
				}
				#if flxanimate
				else
				{
					addAnimateAnimation(animAnim, animName, animFps, animLoop, animIndices, anim.animType);
				}
				#end

				if (anim.offsets != null && anim.offsets.length > 1)
					addOffset(anim.anim, anim.offsets[0], anim.offsets[1]);
				else
					addOffset(anim.anim, 0, 0);
			}
		}
		#if flxanimate
		if (isAnimateAtlas)
			copyAtlasValues();
		#end
		// trace('Loaded file to character ' + curCharacter);
	}

	public static function normalizeAssetPath(path:Dynamic):String
	{
		if (path == null)
			return null;

		var cleanPath:String = Std.string(path).replace('\\', '/');
		var colon:Int = cleanPath.indexOf(':');
		if (colon >= 0)
			cleanPath = cleanPath.substr(colon + 1);
		return cleanPath;
	}

	public static function normalizeRenderType(value:Dynamic):String
	{
		if (value == null)
			return 'sparrow';

		var type:String = Std.string(value).trim().toLowerCase();
		return switch (type)
		{
			case 'multisparrow', 'multi-sparrow':
				'multisparrow';
			case 'packer', 'spritesheetpacker':
				'packer';
			case 'animate', 'textureatlas', 'texture-atlas', 'texture_atlas', 'flxanimate', 'animateatlas':
				'animateatlas';
			case 'multianimate', 'multi-animate', 'multi-animateatlas', 'multi_animateatlas', 'multitextureatlas', 'multiatlas', 'multianimateatlas':
				'multianimateatlas';
			default:
				'sparrow';
		}
	}

	public static function usesAnimateAtlas(renderType:String):Bool
	{
		renderType = normalizeRenderType(renderType);
		return renderType == 'animateatlas' || renderType == 'multianimateatlas';
	}

	public static function usesClassicAtlas(renderType:String):Bool
	{
		return !usesAnimateAtlas(renderType);
	}

	function isAnimateAnimation(anim:AnimArray, parentRenderType:String):Bool
	{
		if (anim != null && anim.renderType != null)
			return usesAnimateAtlas(anim.renderType);
		return usesAnimateAtlas(parentRenderType);
	}

	function loadClassicFrames(image:String, animations:Dynamic, parentRenderType:String):FlxAtlasFrames
	{
		var keys:Array<String> = [];
		if (image != null && image.length > 0 && usesClassicAtlas(parentRenderType))
			addAtlasKeys(keys, image);

		if (animations != null)
		{
			var anims:Array<Dynamic> = cast animations;
			for (anim in anims)
			{
				if (anim == null || anim.assetPath == null)
					continue;

				var animRenderType:String = (anim.renderType != null) ? normalizeRenderType(anim.renderType) : parentRenderType;
				if (usesClassicAtlas(animRenderType))
					addAtlasKeys(keys, normalizeAssetPath(anim.assetPath));
			}
		}

		return keys.length > 0 ? Paths.getMultiAtlas(keys) : null;
	}

	function getAnimateAtlasKeys(image:String, animations:Dynamic):Array<String>
	{
		var keys:Array<String> = [];
		addAtlasKeys(keys, image);

		if (animations != null)
		{
			var anims:Array<Dynamic> = cast animations;
			for (anim in anims)
			{
				if (anim == null || anim.assetPath == null)
					continue;

				var animRenderType:String = (anim.renderType != null) ? normalizeRenderType(anim.renderType) : renderType;
				if (usesAnimateAtlas(animRenderType))
					addAtlasKeys(keys, normalizeAssetPath(anim.assetPath));
			}
		}

		return keys;
	}

	function addAtlasKeys(keys:Array<String>, value:String):Void
	{
		if (value == null)
			return;

		for (key in value.split(','))
		{
			key = normalizeAssetPath(key);
			if (key != null)
			{
				key = key.trim();
				if (key.length > 0 && !keys.contains(key))
					keys.push(key);
			}
		}
	}

	#if flxanimate
	function addAnimateAnimation(anim:String, name:String, fps:Float, loop:Bool, indices:Array<Int>, ?animType:String):Void
	{
		animType = animType != null ? animType.trim().toLowerCase() : 'framelabel';
		if (animType == 'symbol')
		{
			if (indices != null && indices.length > 0)
				atlas.anim.addBySymbolIndices(anim, name, indices, fps, loop);
			else
				atlas.anim.addBySymbol(anim, name, fps, loop);
			return;
		}

		if (indices != null && indices.length > 0)
			atlas.addByFrameLabelIndices(anim, name, indices, fps, loop);
		else
			atlas.addByFrameLabel(anim, name, fps, loop);
	}
	#end

	function hasClassicAtlas(image:String):Bool
	{
		for (key in image.split(','))
		{
			key = StringTools.trim(key);
			if (key.length < 1)
				continue;

			if (AssetLoader.exists(Paths.getPath('images/$key.xml', TEXT), TEXT)
				|| AssetLoader.exists(Paths.getPath('images/$key.json', TEXT), TEXT)
				|| AssetLoader.exists(Paths.getPath('images/$key.txt', TEXT), TEXT))
				return true;
		}
		return false;
	}

	override function update(elapsed:Float)
	{
		if (currentUsesAnimateAtlas())
			atlas.update(elapsed);

		if (debugMode || isAnimationNull())
		{
			super.update(elapsed);
			return;
		}

		if (heyTimer > 0)
		{
			var rate:Float = (PlayState.instance != null ? PlayState.instance.playbackRate : 1.0);
			heyTimer -= elapsed * rate;
			if (heyTimer <= 0)
			{
				var anim:String = getAnimationName();
				if (specialAnim && (anim == 'hey' || anim == 'cheer'))
				{
					specialAnim = false;
					dance();
				}
				heyTimer = 0;
			}
		}
		else if (specialAnim && isAnimationFinished())
		{
			specialAnim = false;
			dance();
		}
		else if (getAnimationName().endsWith('miss') && isAnimationFinished())
		{
			dance();
			finishAnimation();
		}

		switch (curCharacter)
		{
			case 'pico-speaker':
				if (animationNotes.length > 0 && Conductor.songPosition > animationNotes[0][0])
				{
					var noteData:Int = 1;
					if (animationNotes[0][1] > 2)
						noteData = 3;

					noteData += FlxG.random.int(0, 1);
					playAnim('shoot' + noteData, true);
					animationNotes.shift();
				}
				if (isAnimationFinished())
					playAnim(getAnimationName(), false, false, animation.curAnim.frames.length - 3);
		}

		if (getAnimationName().startsWith('sing'))
			holdTimer += elapsed;
		else if (isPlayer)
			holdTimer = 0;

		if (!isPlayer
			&& getAnimationName().indexOf('-hold') == -1
			&& holdTimer >= Conductor.stepCrochet * (0.0011 #if FLX_PITCH / (FlxG.sound.music != null ? FlxG.sound.music.pitch : 1) #end) * singDuration)
		{
			dance();
			holdTimer = 0;
		}

		var name:String = getAnimationName();
		if (isAnimationFinished() && hasAnimation('$name-loop'))
			playAnim('$name-loop');

		super.update(elapsed);
	}

	inline public function isAnimationNull():Bool
	{
		return currentUsesAnimateAtlas() ? (atlas.anim.curInstance == null || atlas.anim.curSymbol == null) : (animation.curAnim == null);
	}

	var _lastPlayedAnimation:String;

	inline public function getAnimationName():String
	{
		return _lastPlayedAnimation;
	}

	public function isAnimationFinished():Bool
	{
		if (isAnimationNull())
			return false;
		return currentUsesAnimateAtlas() ? atlas.anim.finished : animation.curAnim.finished;
	}

	public function finishAnimation():Void
	{
		if (isAnimationNull())
			return;

		if (currentUsesAnimateAtlas())
			atlas.anim.curFrame = atlas.anim.length - 1;
		else
			animation.curAnim.finish();
	}

	public function hasAnimation(anim:String):Bool
	{
		return animOffsets.exists(anim);
	}

	public function setAnimationUsesAnimateAtlas(anim:String, useAnimate:Bool):Void
	{
		animateAnimationMap.set(anim, useAnimate);
	}

	public var animPaused(get, set):Bool;

	private function get_animPaused():Bool
	{
		if (isAnimationNull())
			return false;
		return currentUsesAnimateAtlas() ? !atlas.anim.isPlaying : animation.curAnim.paused;
	}

	private function set_animPaused(value:Bool):Bool
	{
		if (isAnimationNull())
			return value;
		if (currentUsesAnimateAtlas())
		{
			if (value)
				atlas.pauseAnimation();
			else
				atlas.resumeAnimation();
		}
		else
			animation.curAnim.paused = value;

		return value;
	}

	public var danced:Bool = false;

	/**
	 * FOR GF DANCING SHIT
	 */
	public function dance()
	{
		if (!debugMode && !skipDance && !specialAnim)
		{
			if (danceIdle)
			{
				danced = !danced;

				if (danced)
					playAnim('danceRight' + idleSuffix);
				else
					playAnim('danceLeft' + idleSuffix);
			}
			else if (hasAnimation('idle' + idleSuffix))
				playAnim('idle' + idleSuffix);
		}
	}

	public function playAnim(AnimName:String, Force:Bool = false, Reversed:Bool = false, Frame:Int = 0):Void
	{
		specialAnim = false;
		if (!isAnimateAtlas || !shouldUseAnimateAtlas(AnimName))
		{
			animation.play(AnimName, Force, Reversed, Frame);
		}
		else
		{
			atlas.anim.play(AnimName, Force, Reversed, Frame);
			atlas.update(0);
		}
		_lastPlayedAnimation = AnimName;

		if (hasAnimation(AnimName))
		{
			var daOffset = animOffsets.get(AnimName);
			offset.set(daOffset[0], daOffset[1]);
		}
		// else offset.set(0, 0);

		if (curCharacter.startsWith('gf-') || curCharacter == 'gf')
		{
			if (AnimName == 'singLEFT')
				danced = true;
			else if (AnimName == 'singRIGHT')
				danced = false;

			if (AnimName == 'singUP' || AnimName == 'singDOWN')
				danced = !danced;
		}
	}

	function loadMappedAnims():Void
	{
		try
		{
			var songData:SwagSong = Song.getChart('picospeaker', Paths.formatToSongPath(Song.loadedSongName));
			if (songData != null)
				for (section in songData.notes)
					for (songNotes in section.sectionNotes)
						animationNotes.push(songNotes);

			animationNotes.sort(sortAnims);
		}
		catch (e:Dynamic)
		{
		}
	}

	function sortAnims(Obj1:Array<Dynamic>, Obj2:Array<Dynamic>):Int
	{
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1[0], Obj2[0]);
	}

	public var danceEveryNumBeats:Int = 2;

	private var settingCharacterUp:Bool = true;

	public function recalculateDanceIdle()
	{
		var lastDanceIdle:Bool = danceIdle;
		danceIdle = (hasAnimation('danceLeft' + idleSuffix) && hasAnimation('danceRight' + idleSuffix));

		if (settingCharacterUp)
		{
			danceEveryNumBeats = (danceIdle ? 1 : 2);
		}
		else if (lastDanceIdle != danceIdle)
		{
			var calc:Float = danceEveryNumBeats;
			if (danceIdle)
				calc /= 2;
			else
				calc *= 2;

			danceEveryNumBeats = Math.round(Math.max(calc, 1));
		}
		settingCharacterUp = false;
	}

	public function addOffset(name:String, x:Float = 0, y:Float = 0)
	{
		animOffsets[name] = [x, y];
	}

	public function quickAnimAdd(name:String, anim:String)
	{
		animation.addByPrefix(name, anim, 24, false);
	}

	// Atlas support
	// special thanks ne_eo for the references, you're the goat!!
	@:allow(states.editors.CharacterEditorState)
	public var isAnimateAtlas(default, null):Bool = false;
	#if flxanimate
	public var atlas:FlxAnimate;

	function shouldUseAnimateAtlas(animName:String):Bool
	{
		if (!isAnimateAtlas)
			return false;
		return animName == null || !animateAnimationMap.exists(animName) || animateAnimationMap.get(animName);
	}

	function currentUsesAnimateAtlas():Bool
	{
		return shouldUseAnimateAtlas(_lastPlayedAnimation);
	}

	public function isCurrentAnimationAnimateAtlas():Bool
	{
		return currentUsesAnimateAtlas();
	}

	public override function draw()
	{
		var lastAlpha:Float = alpha;
		var lastColor:FlxColor = color;
		if (missingCharacter)
		{
			alpha *= 0.6;
			color = FlxColor.BLACK;
		}

		if (currentUsesAnimateAtlas())
		{
			if (atlas.anim.curInstance != null)
			{
				copyAtlasValues();
				atlas.draw();
				alpha = lastAlpha;
				color = lastColor;
				if (missingCharacter && visible)
				{
					missingText.x = getMidpoint().x - 150;
					missingText.y = getMidpoint().y - 10;
					missingText.draw();
				}
			}
			return;
		}
		super.draw();
		if (missingCharacter && visible)
		{
			alpha = lastAlpha;
			color = lastColor;
			missingText.x = getMidpoint().x - 150;
			missingText.y = getMidpoint().y - 10;
			missingText.draw();
		}
	}

	public function copyAtlasValues()
	{
		@:privateAccess
		{
			atlas.cameras = cameras;
			atlas.scrollFactor = scrollFactor;
			atlas.scale = scale;
			atlas.offset = offset;
			atlas.origin = origin;
			atlas.x = x;
			atlas.y = y;
			atlas.angle = angle;
			atlas.alpha = alpha;
			atlas.visible = visible;
			atlas.flipX = flipX;
			atlas.flipY = flipY;
			atlas.shader = shader;
			atlas.antialiasing = antialiasing;
			atlas.colorTransform = colorTransform;
			atlas.color = color;
		}
	}

	public override function destroy()
	{
		atlas = FlxDestroyUtil.destroy(atlas);
		super.destroy();
	}
	#end
}

