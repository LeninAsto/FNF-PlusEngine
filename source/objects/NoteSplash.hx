package objects;

import backend.animation.PsychAnimationController;
import shaders.RGBPalette;
import shaders.ColorSwap;
import flixel.system.FlxAssets.FlxShader;

typedef RGB =
{
	r:Null<Int>,
	g:Null<Int>,
	b:Null<Int>
}

typedef NoteSplashAnim =
{
	name:String,
	noteData:Int,
	prefix:String,
	indices:Array<Int>,
	offsets:Array<Float>,
	fps:Array<Int>
}

typedef NoteSplashConfig =
{
	animations:Map<String, NoteSplashAnim>,
	scale:Float,
	allowRGB:Bool,
	allowPixel:Bool,
	rgb:Array<Null<RGB>>
}

class NoteSplash extends FlxSprite
{
	public var rgbShader:PixelSplashShaderRef;
	public var texture:String;
	public var config(default, set):NoteSplashConfig;
	public var babyArrow:StrumNote;
	public var noteData:Int = 0;

	public var copyX:Bool = true;
	public var copyY:Bool = true;
	public var inEditor:Bool = false;

	var spawned:Bool = false;
	var noteDataMap:Map<Int, String> = new Map();
	var reusableRGBPalette:RGBPalette = new RGBPalette();
	var colorSwap:ColorSwap;

	public static var defaultNoteSplash(default, never):String = "noteSplashes/noteSplashes";
	public static var noRgbNoteSplash(default, never):String = "noteSplashesNoRGB/noteSplashes";
	public static var configs:Map<String, NoteSplashConfig> = new Map();
	static var framesCache:Map<String, Dynamic> = new Map();

	public function new(?x:Float = 0, ?y:Float = 0, ?splash:String)
	{
		super(x, y);

		animation = new PsychAnimationController(this);

		rgbShader = new PixelSplashShaderRef();
		shader = rgbShader.shader;

		loadSplash(splash);
	}

	public var maxAnims(default, set):Int = 0;

	public function loadSplash(?splash:String)
	{
		config = null;
		maxAnims = 0;
		spawned = false;
		animation.finishCallback = null;
		@:privateAccess
		animation.clearAnimations();

		if (splash == null)
		{
			splash = null;
			if (PlayState.SONG != null && PlayState.SONG.splashSkin != null && PlayState.SONG.splashSkin.length > 0)
				splash = PlayState.SONG.splashSkin;
		}
		splash = resolveNoteSplashPath(splash, PlayState.isPixelStage);

		texture = splash;
		frames = null;
		var atlasPath:String = 'images/$texture';
		var loadedAtlas:Bool = false;
		if (framesCache.exists(atlasPath))
		{
			frames = framesCache.get(atlasPath);
			loadedAtlas = frames != null;
		}
		else
		{
			frames = getSplashAtlas(texture);
			if (frames != null)
			{
				framesCache.set(atlasPath, frames);
				loadedAtlas = true;
			}
		}
		if (frames == null)
		{
			texture = resolveNoteSplashPath(null, PlayState.isPixelStage);
			atlasPath = 'images/$texture';
			if (framesCache.exists(atlasPath))
			{
				frames = framesCache.get(atlasPath);
				loadedAtlas = frames != null;
			}
			else
			{
				frames = getSplashAtlas(texture);
				if (frames != null)
				{
					framesCache.set(atlasPath, frames);
					loadedAtlas = true;
				}
			}
			if (frames == null)
			{
				texture = resolveSplashCandidate(defaultNoteSplash, PlayState.isPixelStage);
				atlasPath = 'images/$texture';
				if (framesCache.exists(atlasPath))
				{
					frames = framesCache.get(atlasPath);
					loadedAtlas = frames != null;
				}
				else
				{
					frames = getSplashAtlas(texture);
					if (frames != null)
					{
						framesCache.set(atlasPath, frames);
						loadedAtlas = true;
					}
				}
			}
		}

		if (!loadedAtlas || frames == null)
		{
			// Keep the splash invisible rather than inheriting stale frames from a recycled instance.
			texture = null;
			makeGraphic(1, 1, FlxColor.TRANSPARENT);
			updateHitbox();
			config = createConfig();
			maxAnims = 0;
			return;
		}

		var path:String = 'images/$texture';
		if (configs.exists(path))
		{
			this.config = configs.get(path);
			for (anim in this.config.animations)
			{
				if (anim.noteData % 4 == 0)
					maxAnims++;
			}
			return;
		}
		else if (Paths.fileExists('$path.json', TEXT))
		{
			var config:Dynamic = haxe.Json.parse(Paths.getTextFromFile('$path.json'));
			if (config != null)
			{
				var tempConfig:NoteSplashConfig = {
					animations: new Map(),
					scale: config.scale,
					allowRGB: config.allowRGB,
					allowPixel: config.allowPixel,
					rgb: config.rgb
				}

				for (i in Reflect.fields(config.animations))
				{
					var anim:NoteSplashAnim = Reflect.field(config.animations, i);
					tempConfig.animations.set(i, anim);
					if (anim.noteData % 4 == 0)
						maxAnims++;
				}

				this.config = tempConfig;
				configs.set(path, this.config);
				return;
			}
		}

		// Splashes with no json
		var tempConfig:NoteSplashConfig = createConfig();
		var anim:String = 'note splash';
		var fps:Array<Null<Int>> = [22, 26];
		var offsets:Array<Array<Float>> = [[0, 0]];
		if (Paths.fileExists('$path.txt', TEXT)) // Backwards compatibility with 0.7 splash txts
		{
			var configFile:Array<String> = CoolUtil.listFromString(Paths.getTextFromFile('$path.txt'));
			if (configFile.length > 0)
			{
				anim = configFile[0];
				if (configFile.length > 1)
				{
					var framerates:Array<String> = configFile[1].split(' ');
					fps = [Std.parseInt(framerates[0]), Std.parseInt(framerates[1])];
					if (fps[0] == null)
						fps[0] = 22;
					if (fps[1] == null)
						fps[1] = 26;

					if (configFile.length > 2)
					{
						offsets = [];
						for (i in 2...configFile.length)
						{
							if (configFile[i].trim() != '')
							{
								var animOffs:Array<String> = configFile[i].split(' ');
								var x:Float = Std.parseFloat(animOffs[0]);
								var y:Float = Std.parseFloat(animOffs[1]);
								if (Math.isNaN(x))
									x = 0;
								if (Math.isNaN(y))
									y = 0;
								offsets.push([x, y]);
							}
						}
					}
				}
			}
		}

		var failedToFind:Bool = false;
		while (true)
		{
			for (v in Note.colArray)
			{
				if (!checkForAnim('$anim $v ${maxAnims + 1}'))
				{
					failedToFind = true;
					break;
				}
			}
			if (failedToFind)
				break;
			maxAnims++;
		}

		for (animNum in 0...maxAnims)
		{
			for (i => col in Note.colArray)
			{
				var data:Int = i % Note.colArray.length + (animNum * Note.colArray.length);
				var name:String = animNum > 0 ? '$col' + (animNum + 1) : col;
				var offset:Array<Float> = offsets[FlxMath.wrap(data, 0, Std.int(offsets.length - 1))];
				addAnimationToConfig(tempConfig, 1, name, '$anim $col ${animNum + 1}', fps, offset, [], data);
			}
		}

		this.config = tempConfig;
		configs.set(path, this.config);
	}

	public static function warmupSplashSkin(?splash:String):Void
	{
		var preview:NoteSplash = new NoteSplash(0, 0, splash);
		preview.kill();
	}

	public static function clearCache():Void
	{
		framesCache.clear();
	}

	public function spawnSplashNote(?x:Float = 0, ?y:Float = 0, ?noteData:Int = 0, ?note:Note, ?randomize:Bool = true)
	{
		if (note != null && note.noteSplashData.disabled)
			return;

		aliveTime = 0;

		if (!inEditor)
		{
			var loadedTexture:String = resolveNoteSplashPath(null, PlayState.isPixelStage);
			if (note != null && note.noteSplashData.texture != null)
				loadedTexture = resolveNoteSplashPath(note.noteSplashData.texture, PlayState.isPixelStage, false);
			else if (PlayState.SONG != null && PlayState.SONG.splashSkin != null && PlayState.SONG.splashSkin.length > 0)
				loadedTexture = resolveNoteSplashPath(PlayState.SONG.splashSkin, PlayState.isPixelStage, false);

			if (texture != loadedTexture)
				loadSplash(loadedTexture);
		}

		setPosition(x, y);

		if (babyArrow != null)
			setPosition(babyArrow.x - Note.swagWidth * 0.95, babyArrow.y - Note.swagWidth); // To prevent it from being misplaced for one game tick

		if (note != null)
			noteData = note.noteData;

		if (randomize && maxAnims > 1)
			noteData = noteData % Note.colArray.length + (FlxG.random.int(0, maxAnims - 1) * Note.colArray.length);

		this.noteData = noteData;
		var anim:String = playDefaultAnim();

		var tempShader:RGBPalette = null;
		var colorIndex:Int = Note.normalizeNoteData(noteData);
		var canUseSplashShader:Bool = inEditor
			|| ((note == null || note.noteSplashData.useRGBShader) && (PlayState.SONG == null || !PlayState.SONG.disableNoteRGB));
		if (!ClientPrefs.data.noteRGB)
		{
			rgbShader.copyValues(null);
			if (canUseSplashShader)
			{
				if (colorSwap == null)
					colorSwap = new ColorSwap();
				Note.applyHSVToColorSwap(colorSwap, colorIndex);
				shader = colorSwap.shader;
			}
			else
				shader = null;
		}
		else
		{
			shader = rgbShader.shader;
			if (config.allowRGB)
			{
				Note.initializeGlobalRGBShader(colorIndex);
				if (canUseSplashShader)
				{
					tempShader = reusableRGBPalette;
					tempShader.mult = 1.0;
					// If Note RGB is enabled:
					if ((note == null || !note.noteSplashData.useGlobalShader) || inEditor)
					{
						var colors = config.rgb;
						if (colors != null)
						{
							for (i in 0...colors.length)
							{
								if (i > 2)
									break;

								var arr:Array<FlxColor> = Note.getNoteColorPalette(colorIndex, PlayState.isPixelStage);
								var fallbackColor:FlxColor = arr[i];

								var rgb = colors[i];
								if (rgb == null)
								{
									if (i == 0)
										tempShader.r = fallbackColor;
									else if (i == 1)
										tempShader.g = fallbackColor;
									else if (i == 2)
										tempShader.b = fallbackColor;
									continue;
								}

								var r:Null<Int> = rgb.r;
								var g:Null<Int> = rgb.g;
								var b:Null<Int> = rgb.b;

								if (r == null || Math.isNaN(r) || r < 0)
									r = fallbackColor.red;
								if (g == null || Math.isNaN(g) || g < 0)
									g = fallbackColor.green;
								if (b == null || Math.isNaN(b) || b < 0)
									b = fallbackColor.blue;

								var color:FlxColor = FlxColor.fromRGB(r, g, b);
								if (i == 0)
									tempShader.r = color;
								else if (i == 1)
									tempShader.g = color;
								else if (i == 2)
									tempShader.b = color;
							}
						}
						else
							tempShader.copyValues(Note.globalRgbShaders[colorIndex]);

						if (note != null)
						{
							if (note.noteSplashData.r != -1)
								tempShader.r = note.noteSplashData.r;
							if (note.noteSplashData.g != -1)
								tempShader.g = note.noteSplashData.g;
							if (note.noteSplashData.b != -1)
								tempShader.b = note.noteSplashData.b;
						}
					}
					else
						tempShader.copyValues(Note.globalRgbShaders[colorIndex]);
				}
			}
			rgbShader.copyValues(tempShader);
		}
		if (!config.allowPixel)
			rgbShader.pixelAmount = 1;
		else if (PlayState.isPixelStage)
			rgbShader.pixelAmount = 6;

		offset.set(10, 10);
		var conf:NoteSplashAnim = config.animations.get(anim);
		var offsets:Array<Float> = [0, 0];
		if (conf != null)
			offsets = conf.offsets;
		if (offsets != null)
		{
			offset.x += offsets[0];
			offset.y += offsets[1];
		}

		animation.finishCallback = function(name:String)
		{
			kill();
			spawned = false;
		}

		alpha = ClientPrefs.data.splashAlpha;
		if (note != null)
			alpha = note.noteSplashData.a;

		antialiasing = ClientPrefs.data.antialiasing;
		if (note != null)
			antialiasing = note.noteSplashData.antialiasing;
		if (PlayState.isPixelStage && config.allowPixel)
			antialiasing = false;

		var minFps:Int = 22;
		var maxFps:Int = 26;
		if (conf != null)
		{
			minFps = conf.fps[0];
			if (minFps < 0)
				minFps = 0;

			maxFps = conf.fps[1];
			if (maxFps < 0)
				maxFps = 0;
		}

		if (animation.curAnim != null)
			animation.curAnim.frameRate = FlxG.random.int(minFps, maxFps);

		spawned = true;
	}

	public function playDefaultAnim()
	{
		var anim:String = noteDataMap.get(noteData);
		if (anim != null && animation.exists(anim))
		{
			animation.play(anim, true);
		}
		else if (animation.getNameList().length > 0)
		{
			animation.play(animation.getNameList()[0], true);
		}

		return anim;
	}

	function checkForAnim(anim:String)
	{
		var animFrames = [];
		@:privateAccess
		animation.findByPrefix(animFrames, anim); // adds valid frames to animFrames

		return animFrames.length > 0;
	}

	var aliveTime:Float = 0;

	static var buggedKillTime:Float = 0.5; // automatically kills note splashes if they break to prevent it from flooding your HUD

	override function update(elapsed:Float)
	{
		if (spawned)
		{
			aliveTime += elapsed;
			if (animation.curAnim == null && aliveTime >= buggedKillTime)
			{
				kill();
				spawned = false;
			}
		}

		if (babyArrow != null)
		{
			if (copyX)
				x = babyArrow.x - Note.swagWidth * 0.95;

			if (copyY)
				y = babyArrow.y - Note.swagWidth;
		}
		super.update(elapsed);
	}

	public static function getSplashSkinPostfix()
	{
		var skin:String = '';
		if (ClientPrefs.data.splashSkin != ClientPrefs.defaultData.splashSkin)
			skin = '-' + ClientPrefs.data.splashSkin.trim().toLowerCase().replace(' ', '-');
		return skin;
	}

	static function getSplashAtlas(splash:String):Dynamic
	{
		if (!splashPathExists(splash, false, true))
			return null;
		return Paths.getSparrowAtlas(splash);
	}

	public static function splashPathExists(splash:String, ?pixel:Null<Bool>, ?rawOnly:Bool = false):Bool
	{
		if (splash == null || splash.length < 1)
			return false;

		var rawExists:Bool = Paths.fileExists('images/' + splash + '.png', IMAGE) && Paths.fileExists('images/' + splash + '.xml', TEXT);
		if (rawOnly || rawExists)
			return rawExists;

		var usePixel:Bool = PlayState.isPixelStage;
		if (pixel != null)
			usePixel = pixel;

		if (usePixel)
		{
			var pixelSplash:String = splash;
			if (!pixelSplash.startsWith('pixelUI/'))
				pixelSplash = 'pixelUI/' + pixelSplash;
			if (Paths.fileExists('images/' + pixelSplash + '.png', IMAGE) && Paths.fileExists('images/' + pixelSplash + '.xml', TEXT))
				return true;

			var noRgbPixelSplash:String = pixelSplash.replace('pixelUI/' + defaultNoteSplash, 'pixelUI/' + noRgbNoteSplash);
			if (noRgbPixelSplash != pixelSplash
				&& Paths.fileExists('images/' + noRgbPixelSplash + '.png', IMAGE)
				&& Paths.fileExists('images/' + noRgbPixelSplash + '.xml', TEXT))
				return true;
		}

		return false;
	}

	static function resolveSplashCandidate(splash:String, ?pixel:Null<Bool>):String
	{
		if (splash == null || splash.length < 1)
			return null;

		var usePixel:Bool = PlayState.isPixelStage;
		if (pixel != null)
			usePixel = pixel;

		if (usePixel)
		{
			var pixelSplash:String = splash;
			if (!pixelSplash.startsWith('pixelUI/'))
				pixelSplash = 'pixelUI/' + pixelSplash;
			if (splashPathExists(pixelSplash, false, true))
				return pixelSplash;

			var noRgbPixelSplash:String = pixelSplash.replace('pixelUI/' + defaultNoteSplash, 'pixelUI/' + noRgbNoteSplash);
			if (noRgbPixelSplash != pixelSplash && splashPathExists(noRgbPixelSplash, false, true))
				return noRgbPixelSplash;
		}

		if (splashPathExists(splash, false, true))
			return splash;

		if (!usePixel && splash.startsWith('pixelUI/'))
		{
			var normalSplash:String = splash.substr('pixelUI/'.length);
			if (splashPathExists(normalSplash, false, true))
				return normalSplash;
		}

		return splash;
	}

	public static function getDefaultNoteSplashPath(?pixel:Null<Bool>):String
	{
		var preferred:String = ClientPrefs.data.noteRGB ? defaultNoteSplash : noRgbNoteSplash;
		var fallback:String = ClientPrefs.data.noteRGB ? noRgbNoteSplash : defaultNoteSplash;
		var resolved:String = resolveSplashCandidate(preferred, pixel);
		if (splashPathExists(resolved, false, true))
			return resolved;
		resolved = resolveSplashCandidate(fallback, pixel);
		if (splashPathExists(resolved, false, true))
			return resolved;
		return defaultNoteSplash;
	}

	public static function resolveNoteSplashPath(?splash:String, ?pixel:Null<Bool>, ?useSkinPostfix:Bool = true):String
	{
		if (splash == null || splash.length < 1)
			splash = getDefaultNoteSplashPath(pixel);

		if (useSkinPostfix)
		{
			var postfix:String = getSplashSkinPostfix();
			if (postfix.length > 0)
			{
				var customSplash:String = splash + postfix;
				var resolvedCustom:String = resolveSplashCandidate(customSplash, pixel);
				if (splashPathExists(resolvedCustom, false, true))
					return resolvedCustom;
			}
		}

		var resolved:String = resolveSplashCandidate(splash, pixel);
		if (splashPathExists(resolved, false, true))
			return resolved;

		return getDefaultNoteSplashPath(pixel);
	}

	public static function createConfig():NoteSplashConfig
	{
		return {
			animations: new Map(),
			scale: 1,
			allowRGB: true,
			allowPixel: true,
			rgb: null
		}
	}

	public static function addAnimationToConfig(config:NoteSplashConfig, scale:Float, name:String, prefix:String, fps:Array<Int>, offsets:Array<Float>,
			indices:Array<Int>, noteData:Int):NoteSplashConfig
	{
		if (config == null)
			config = createConfig();

		config.animations.set(name, {
			name: name,
			noteData: noteData,
			prefix: prefix,
			indices: indices,
			offsets: offsets,
			fps: fps
		});
		config.scale = scale;
		return config;
	}

	function set_config(value:NoteSplashConfig):NoteSplashConfig
	{
		if (value == null)
			value = createConfig();

		@:privateAccess
		animation.clearAnimations();
		noteDataMap.clear();

		for (i in value.animations)
		{
			var key:String = i.name;
			if (i.prefix.length > 0 && key != null && key.length > 0)
			{
				if (i.indices != null && i.indices.length > 0)
					animation.addByIndices(key, i.prefix, i.indices, "", i.fps[1], false);
				else
					animation.addByPrefix(key, i.prefix, i.fps[1], false);

				noteDataMap.set(i.noteData, key);
			}
		}

		scale.set(value.scale, value.scale);
		return config = value;
	}

	function set_maxAnims(value:Int)
	{
		if (value > 0)
			noteData = Std.int(FlxMath.wrap(noteData, 0, (value * Note.colArray.length) - 1));
		else
			noteData = 0;

		return maxAnims = value;
	}
}

class PixelSplashShaderRef
{
	public var shader:PixelSplashShader = new PixelSplashShader();
	public var enabled(default, set):Bool = true;
	public var pixelAmount(default, set):Float = 1;

	public function copyValues(tempShader:RGBPalette)
	{
		if (tempShader != null)
		{
			for (i in 0...3)
			{
				shader.r.value[i] = tempShader.shader.r.value[i];
				shader.g.value[i] = tempShader.shader.g.value[i];
				shader.b.value[i] = tempShader.shader.b.value[i];
			}
			shader.mult.value[0] = tempShader.shader.mult.value[0];
		}
		else
			enabled = false;
	}

	public function set_enabled(value:Bool)
	{
		enabled = value;
		shader.mult.value = [value ? 1 : 0];
		return value;
	}

	public function set_pixelAmount(value:Float)
	{
		pixelAmount = value;
		shader.uBlocksize.value = [value, value];
		return value;
	}

	public function reset()
	{
		shader.r.value = [0, 0, 0];
		shader.g.value = [0, 0, 0];
		shader.b.value = [0, 0, 0];
	}

	public function new()
	{
		reset();
		enabled = true;

		if (!PlayState.isPixelStage)
			pixelAmount = 1;
		else
			pixelAmount = PlayState.daPixelZoom;
		// trace('Created shader ' + Conductor.songPosition);
	}
}

class PixelSplashShader extends FlxShader
{
	@:glFragmentHeader('
		#pragma header

		uniform vec3 r;
		uniform vec3 g;
		uniform vec3 b;
		uniform float mult;
		uniform vec2 uBlocksize;

		vec4 flixel_texture2DCustom(sampler2D bitmap, vec2 coord) {
			vec2 blocks = openfl_TextureSize / uBlocksize;
			vec4 color = flixel_texture2D(bitmap, floor(coord * blocks) / blocks);
			if (!hasTransform) {
				return color;
			}

			if (color.a == 0.0 || mult == 0.0) {
				return color * openfl_Alphav;
			}

			vec4 newColor = color;
			newColor.rgb = min(color.r * r + color.g * g + color.b * b, vec3(1.0));
			newColor.a = color.a;

			color = mix(color, newColor, mult);

			if (color.a > 0.0) {
				return vec4(color.rgb, color.a);
			}
			return vec4(0.0, 0.0, 0.0, 0.0);
		}')
	@:glFragmentSource('
		#pragma header

		void main() {
			gl_FragColor = flixel_texture2DCustom(bitmap, openfl_TextureCoordv);
		}')
	public function new()
	{
		super();
	}
}

