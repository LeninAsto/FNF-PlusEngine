package objects;

import backend.animation.PsychAnimationController;
import backend.NoteTypesConfig;
import shaders.RGBPalette;
import shaders.RGBPalette.RGBShaderReference;
import shaders.ColorSwap;
import objects.StrumNote;
import flixel.math.FlxRect;
import flixel.math.FlxMath;

using StringTools;

typedef EventNote =
{
	strumTime:Float,
	event:String,
	value1:String,
	value2:String
}

typedef NoteSplashData =
{
	disabled:Bool,
	texture:String,
	useGlobalShader:Bool, // breaks r/g/b but makes it copy default colors for your custom note
	useRGBShader:Bool,
	antialiasing:Bool,
	r:FlxColor,
	g:FlxColor,
	b:FlxColor,
	a:Float
}

/**
 * The note object used as a data structure to spawn and manage notes during gameplay.
 * 
 * If you want to make a custom note type, you should search for: "function set_noteType"
**/
class Note extends FlxSprite
{
	// This is needed for the hardcoded note types to appear on the Chart Editor,
	// It's also used for backwards compatibility with 0.1 - 0.3.2 charts.
	public static final defaultNoteTypes:Array<String> = [
		'', // Always leave this one empty pls
		'Alt Animation',
		'Hey!',
		'Hurt Note',
		'GF Sing',
		'No Animation'
	];

	// Rendering optimization: tracks how much this note "costs" to render
	// Used to prevent FPS drops when there are many notes on screen at once
	public var noteDensity:Float = 1;

	public var extraData:Map<String, Dynamic> = new Map<String, Dynamic>();

	public var strumTime:Float = 0;
	public var noteData:Int = 0;

	public var mustPress:Bool = false;
	public var canBeHit:Bool = false;
	public var tooLate:Bool = false;

	public var wasGoodHit:Bool = false;
	public var missed:Bool = false;
	public var holdMissed:Bool = false;
	public var isOpponentMode:Bool = false; // Flag para detectar Opponent Mode

	public var ignoreNote:Bool = false;
	public var hitByOpponent:Bool = false;
	public var noteWasHit:Bool = false;
	public var prevNote:Note;
	public var nextNote:Note;

	public var spawned:Bool = false;

	public var tail:Array<Note> = []; // for sustains
	public var parent:Note;

	public var blockHit:Bool = false; // only works for player

	public var sustainLength:Float = 0;
	public var isSustainNote:Bool = false;
	public var isSustainEnd:Bool = false;
	public var noteType(default, set):String = null;

	public var eventName:String = '';
	public var eventLength:Int = 0;
	public var eventVal1:String = '';
	public var eventVal2:String = '';

	public var rgbShader:RGBShaderReference;
	public var colorSwap:ColorSwap;

	public static var globalRgbShaders:Array<RGBPalette> = [];

	public var inEditor:Bool = false;

	public var animSuffix:String = '';
	public var gfNote:Bool = false;
	public var earlyHitMult:Float = 1;
	public var lateHitMult:Float = 1;
	public var lowPriority:Bool = false;

	public static var SUSTAIN_SIZE:Int = 44;
	public static var swagWidth:Float = 160 * 0.7;
	public static var colArray:Array<String> = ['purple', 'blue', 'green', 'red'];
	public static var defaultNoteSkin(default, never):String = 'noteSkins/NOTE_assets';
	public static var noRgbNoteSkin(default, never):String = 'noteSkinsNoRGB/NOTE_assets';

	public var noteSplashData:NoteSplashData = {
		disabled: false,
		texture: null,
		antialiasing: !PlayState.isPixelStage,
		useGlobalShader: false,
		useRGBShader: (PlayState.SONG != null) ? !(PlayState.SONG.disableNoteRGB == true) : true,
		r: -1,
		g: -1,
		b: -1,
		a: ClientPrefs.data.splashAlpha
	};

	public var noteHoldSplash:SustainSplash;

	public var offsetX:Float = 0;
	public var offsetY:Float = 0;
	public var offsetAngle:Float = 0;
	public var multAlpha:Float = 1;
	public var multSpeed(default, set):Float = 1;

	public var copyX:Bool = true;
	public var copyY:Bool = true;
	public var copyAngle:Bool = true;
	public var copyAlpha:Bool = true;

	public var hitHealth:Float = 0.02;
	public var missHealth:Float = 0.1;
	public var rating:String = 'unknown';
	public var ratingMod:Float = 0; // 9 = unknown, 0.25 = shit, 0.5 = bad, 0.75 = good, 1 = sick
	public var ratingDisabled:Bool = false;

	public var texture(default, set):String = null;

	public var noAnimation:Bool = false;
	public var noMissAnimation:Bool = false;
	public var hitCausesMiss:Bool = false;
	public var distance:Float = 2000; // plan on doing scroll directions soon -bb

	public var hitsoundDisabled:Bool = false;
	public var hitsoundChartEditor:Bool = true;

	/**
	 * Forces the hitsound to be played even if the user's hitsound volume is set to 0
	**/
	public var hitsoundForce:Bool = false;

	public var hitsoundVolume(get, default):Float = 1.0;

	function get_hitsoundVolume():Float
	{
		if (ClientPrefs.data.hitsoundVolume > 0)
			return ClientPrefs.data.hitsoundVolume;
		return hitsoundForce ? hitsoundVolume : 0.0;
	}

	public var hitsound:String = 'hitsound';

	private function set_multSpeed(value:Float):Float
	{
		resizeByRatio(value / multSpeed);
		multSpeed = value;
		// trace('fuck cock');
		return value;
	}

	public function resizeByRatio(ratio:Float) // haha funny twitter shit
	{
		if (isSustainNote && !isSustainEnd)
		{
			scale.y *= ratio;
			updateHitbox();
		}
	}

	private function set_texture(value:String):String
	{
		if (texture != value)
			reloadNote(value);

		texture = value;
		return value;
	}

	public function defaultRGB()
	{
		if (!ClientPrefs.data.noteRGB)
		{
			if (colorSwap == null)
				colorSwap = new ColorSwap();
			applyHSVToColorSwap(colorSwap, noteData);
			if (rgbShader != null)
				rgbShader.enabled = false;
			shader = colorSwap.shader;
			return;
		}

		if (rgbShader == null)
			return;

		var arr:Array<FlxColor> = getNoteColorPalette(noteData);
		rgbShader.r = arr[0];
		rgbShader.g = arr[1];
		rgbShader.b = arr[2];
	}

	private function set_noteType(value:String):String
	{
		noteSplashData.texture = PlayState.SONG != null ? PlayState.SONG.splashSkin : NoteSplash.getDefaultNoteSplashPath();
		defaultRGB();

		if (noteData > -1 && noteType != value)
		{
			switch (value)
			{
				case 'Hurt Note':
					ignoreNote = mustPress;
					// reloadNote('HURTNOTE_assets');
					// this used to change the note texture to HURTNOTE_assets.png,
					// but i've changed it to something more optimized with the implementation of RGBPalette:

					// note colors
					rgbShader.r = 0xFF101010;
					rgbShader.g = 0xFFFF0000;
					rgbShader.b = 0xFF990022;

					// splash data and colors
					noteSplashData.r = 0xFFFF0000;
					noteSplashData.g = 0xFF101010;
					noteSplashData.texture = 'noteSplashes/noteSplashes-electric';

					// gameplay data
					lowPriority = true;
					missHealth = isSustainNote ? 0.25 : 0.1;
					hitCausesMiss = true;
					hitsound = 'cancelMenu';
					hitsoundChartEditor = false;
				case 'Alt Animation':
					animSuffix = '-alt';
				case 'No Animation':
					noAnimation = true;
					noMissAnimation = true;
				case 'GF Sing':
					gfNote = true;
			}
			if (value != null && value.length > 1)
				NoteTypesConfig.applyNoteTypeData(this, value);
			if (hitsound != 'hitsound' && (ClientPrefs.data.hitSounds != "None" || hitsoundForce) && hitsoundVolume > 0)
				Paths.sound(hitsound); // precache new sound for being idiot-proof
			noteType = value;
		}
		return value;
	}

	public function new(strumTime:Float, noteData:Int, ?prevNote:Note, ?sustainNote:Bool = false, ?inEditor:Bool = false, ?createdFrom:Dynamic = null)
	{
		super();

		animation = new PsychAnimationController(this);

		antialiasing = ClientPrefs.data.antialiasing;
		if (createdFrom == null)
			createdFrom = PlayState.instance;

		if (prevNote == null)
			prevNote = this;

		this.prevNote = prevNote;
		isSustainNote = sustainNote;
		this.inEditor = inEditor;
		this.moves = false;

		x += (ClientPrefs.data.middleScroll ? PlayState.STRUM_X_MIDDLESCROLL : PlayState.STRUM_X) + 50;
		// MAKE SURE ITS DEFINITELY OFF SCREEN?
		y -= 2000;
		this.strumTime = strumTime;
		if (!inEditor)
			this.strumTime += ClientPrefs.data.noteOffset;

		this.noteData = noteData;

		if (noteData > -1)
		{
			rgbShader = new RGBShaderReference(this, initializeGlobalRGBShader(noteData));
			if (PlayState.SONG != null && PlayState.SONG.disableNoteRGB)
				rgbShader.enabled = false;
			if (!ClientPrefs.data.noteRGB)
			{
				colorSwap = new ColorSwap();
				applyHSVToColorSwap(colorSwap, noteData);
				rgbShader.enabled = false;
				shader = colorSwap.shader;
			}
			texture = '';

			x += swagWidth * (noteData);
			if (!isSustainNote && noteData < colArray.length)
			{ // Doing this 'if' check to fix the warnings on Senpai songs
				var animToPlay:String = '';
				animToPlay = colArray[noteData % colArray.length];
				animation.play(animToPlay + 'Scroll');
			}
		}

		// trace(prevNote);

		if (prevNote != null)
			prevNote.nextNote = this;

		if (isSustainNote && prevNote != null)
		{
			alpha = 0.6;
			multAlpha = 0.6;
			hitsoundDisabled = true;
			if (ClientPrefs.data.downScroll)
				flipY = true;

			offsetX += width / 2;
			copyAngle = false;

			animation.play(colArray[noteData % colArray.length] + 'holdend');

			updateHitbox();

			offsetX -= width / 2;

			if (PlayState.isPixelStage)
				offsetX += 30;

			if (prevNote.isSustainNote)
			{
				prevNote.animation.play(colArray[prevNote.noteData % colArray.length] + 'hold');

				prevNote.scale.y *= Conductor.stepCrochet / 100 * 1.05;
				if (createdFrom != null && createdFrom.songSpeed != null)
					prevNote.scale.y *= createdFrom.songSpeed;

				if (PlayState.isPixelStage)
				{
					prevNote.scale.y *= 1.19;
					prevNote.scale.y *= (6 / height); // Auto adjust note size
				}
				prevNote.updateHitbox();
				// prevNote.setGraphicSize();
			}

			if (PlayState.isPixelStage)
			{
				scale.y *= PlayState.daPixelZoom;
				updateHitbox();
			}
			earlyHitMult = 0;
		}
		else if (!isSustainNote)
		{
			centerOffsets();
			centerOrigin();
		}
		x += offsetX;
	}

	public static function initializeGlobalRGBShader(noteData:Int)
	{
		var colorIndex:Int = normalizeNoteData(noteData);
		if (globalRgbShaders[colorIndex] == null)
		{
			var newRGB:RGBPalette = new RGBPalette();
			var arr:Array<FlxColor> = getNoteColorPalette(colorIndex);
			newRGB.r = arr[0];
			newRGB.g = arr[1];
			newRGB.b = arr[2];

			globalRgbShaders[colorIndex] = newRGB;
		}
		return globalRgbShaders[colorIndex];
	}

	public static function normalizeNoteData(noteData:Int):Int
	{
		var length:Int = colArray != null && colArray.length > 0 ? colArray.length : 4;
		return FlxMath.wrap(noteData, 0, length - 1);
	}

	public static function getNoteHSV(noteData:Int):Array<Float>
	{
		var colorIndex:Int = normalizeNoteData(noteData);
		var values:Array<Float> = null;
		if (ClientPrefs.data.arrowHSV != null && colorIndex < ClientPrefs.data.arrowHSV.length)
			values = ClientPrefs.data.arrowHSV[colorIndex];

		if (values != null && values.length >= 3)
			return values;
		return [0, 0, 0];
	}

	public static function applyHSVToColorSwap(colorSwap:ColorSwap, noteData:Int):Void
	{
		if (colorSwap == null)
			return;
		var hsv:Array<Float> = getNoteHSV(noteData);
		colorSwap.hue = hsv[0] / 360;
		colorSwap.saturation = hsv[1] / 100;
		colorSwap.brightness = hsv[2] / 100;
	}

	public static function resetHSVColorSwap(colorSwap:ColorSwap):Void
	{
		if (colorSwap == null)
			return;
		colorSwap.hue = 0;
		colorSwap.saturation = 0;
		colorSwap.brightness = 0;
	}

	public static function getNoteColorPalette(noteData:Int, ?pixel:Null<Bool>):Array<FlxColor>
	{
		var colorIndex:Int = normalizeNoteData(noteData);
		var usePixel:Bool = PlayState.isPixelStage;
		if (pixel != null)
			usePixel = pixel;
		var arr:Array<FlxColor> = getPaletteFrom(usePixel ? ClientPrefs.data.arrowRGBPixel : ClientPrefs.data.arrowRGB, colorIndex);

		if (!ClientPrefs.data.noteRGB)
		{
			var baseArr:Array<FlxColor> = getPaletteFrom(usePixel ? ClientPrefs.defaultData.arrowRGBPixel : ClientPrefs.defaultData.arrowRGB, colorIndex);
			var hsvArr:Array<Float> = getNoteHSV(colorIndex);
			if (baseArr != null)
			{
				var legacy:Array<FlxColor> = [];
				for (i in 0...3)
				{
					var baseColor:FlxColor = baseArr[i];
					var hue:Int = FlxMath.wrap(Math.round(baseColor.hue + hsvArr[0]), 0, 360);
					var sat:Float = FlxMath.bound(baseColor.saturation + (hsvArr[1] / 100), 0, 1);
					var bright:Float = FlxMath.bound(baseColor.brightness * (1 + (hsvArr[2] / 100)), 0, 1);
					legacy.push(FlxColor.fromHSB(hue, sat, bright));
				}
				return legacy;
			}
		}

		if (arr == null)
			arr = getPaletteFrom(usePixel ? ClientPrefs.defaultData.arrowRGBPixel : ClientPrefs.defaultData.arrowRGB, colorIndex);
		if (arr == null)
			return [0xFFFF0000, 0xFF00FF00, 0xFF0000FF];
		return [arr[0], arr[1], arr[2]];
	}

	static function getPaletteFrom(source:Array<Array<FlxColor>>, colorIndex:Int):Array<FlxColor>
	{
		if (source != null && colorIndex > -1 && colorIndex < source.length)
		{
			var arr:Array<FlxColor> = source[colorIndex];
			if (arr != null && arr.length >= 3)
				return arr;
		}
		return null;
	}

	var _lastNoteOffX:Float = 0;

	static var _lastValidChecked:String; // optimization

	public var originalHeight:Float = 6;
	public var correctionOffset:Float = 0; // dont mess with this

	public function reloadNote(texture:String = '', postfix:String = '')
	{
		if (texture == null)
			texture = '';
		if (postfix == null)
			postfix = '';

		var skin:String = texture + postfix;
		if (texture.length < 1)
		{
			skin = PlayState.SONG != null ? PlayState.SONG.arrowSkin : null;
			if (skin == null || skin.length < 1)
			{
				skin = getDefaultNoteSkinPath(PlayState.isPixelStage) + postfix;
			}
		}
		else
			rgbShader.enabled = false;

		var animName:String = null;
		if (animation.curAnim != null)
		{
			animName = animation.curAnim.name;
		}

		var skinPixel:String = skin;
		var lastScaleY:Float = scale.y;
		var skinPostfix:String = getNoteSkinPostfix();
		var customSkin:String = skin + skinPostfix;
		if (customSkin == _lastValidChecked || noteSkinPathExists(customSkin, PlayState.isPixelStage))
		{
			skin = customSkin;
			_lastValidChecked = customSkin;
		}
		else
			skinPostfix = '';

		if (PlayState.isPixelStage)
		{
			if (isSustainNote)
			{
				var graphic = Paths.image('pixelUI/' + skinPixel + 'ENDS' + skinPostfix);
				loadGraphic(graphic, true, Math.floor(graphic.width / 4), Math.floor(graphic.height / 2));
				originalHeight = graphic.height / 2;
			}
			else
			{
				var graphic = Paths.image('pixelUI/' + skinPixel + skinPostfix);
				loadGraphic(graphic, true, Math.floor(graphic.width / 4), Math.floor(graphic.height / 5));
			}
			setGraphicSize(Std.int(width * PlayState.daPixelZoom));
			loadPixelNoteAnims();
			antialiasing = false;

			if (isSustainNote)
			{
				offsetX += _lastNoteOffX;
				_lastNoteOffX = (width - 7) * (PlayState.daPixelZoom / 2);
				offsetX -= _lastNoteOffX;
			}
		}
		else
		{
			frames = Paths.getSparrowAtlas(skin);
			loadNoteAnims();
			if (!isSustainNote)
			{
				centerOffsets();
				centerOrigin();
			}
		}

		if (isSustainNote)
		{
			scale.y = lastScaleY;
		}
		updateHitbox();

		if (animName != null)
			animation.play(animName, true);

		// Detectar si es NotITG y bloquear el shader
		if (skin != null && skin.toLowerCase().contains('notitg'))
		{
			if (rgbShader != null)
			{
				rgbShader.forceDisabled = true;
				rgbShader.enabled = false;
			}
			shader = null;
		}
		else
		{
			// Desbloquear shader para skins normales
			if (rgbShader != null)
				rgbShader.forceDisabled = false;
			if (!ClientPrefs.data.noteRGB && colorSwap != null)
				shader = colorSwap.shader;
		}
	}

	public static function getNoteSkinPostfix()
	{
		var skin:String = '';
		if (ClientPrefs.data.noteSkin != ClientPrefs.defaultData.noteSkin)
			skin = '-' + ClientPrefs.data.noteSkin.trim().toLowerCase().replace(' ', '_');
		return skin;
	}

	public static function noteSkinPathExists(skin:String, ?pixel:Null<Bool>):Bool
	{
		if (skin == null || skin.length < 1)
			return false;
		var usePixel:Bool = PlayState.isPixelStage;
		if (pixel != null)
			usePixel = pixel;
		var path:String = usePixel ? 'pixelUI/' : '';
		return Paths.fileExists('images/' + path + skin + '.png', IMAGE);
	}

	public static function getDefaultNoteSkinPath(?pixel:Null<Bool>):String
	{
		var preferred:String = ClientPrefs.data.noteRGB ? defaultNoteSkin : noRgbNoteSkin;
		var fallback:String = ClientPrefs.data.noteRGB ? noRgbNoteSkin : defaultNoteSkin;
		if (noteSkinPathExists(preferred, pixel))
			return preferred;
		if (noteSkinPathExists(fallback, pixel))
			return fallback;
		return defaultNoteSkin;
	}

	public static function resolveNoteSkinPath(?skin:String, ?pixel:Null<Bool>):String
	{
		if (skin == null || skin.length < 1)
			skin = getDefaultNoteSkinPath(pixel);

		var postfix:String = getNoteSkinPostfix();
		if (postfix.length > 0)
		{
			var customSkin:String = skin + postfix;
			if (noteSkinPathExists(customSkin, pixel))
				return customSkin;
		}
		return skin;
	}

	function loadNoteAnims()
	{
		if (colArray[noteData] == null)
			return;

		if (isSustainNote)
		{
			attemptToAddAnimationByPrefix('purpleholdend', 'pruple end hold', 24, true); // this fixes some retarded typo from the original note .FLA
			animation.addByPrefix(colArray[noteData] + 'holdend', colArray[noteData] + ' hold end', 24, true);
			animation.addByPrefix(colArray[noteData] + 'hold', colArray[noteData] + ' hold piece', 24, true);
		}
		else
			animation.addByPrefix(colArray[noteData] + 'Scroll', colArray[noteData] + '0');

		setGraphicSize(Std.int(width * 0.7));
		updateHitbox();
	}

	function loadPixelNoteAnims()
	{
		if (colArray[noteData] == null)
			return;

		if (isSustainNote)
		{
			animation.add(colArray[noteData] + 'holdend', [noteData + 4], 24, true);
			animation.add(colArray[noteData] + 'hold', [noteData], 24, true);
		}
		else
			animation.add(colArray[noteData] + 'Scroll', [noteData + 4], 24, true);
	}

	function attemptToAddAnimationByPrefix(name:String, prefix:String, framerate:Float = 24, doLoop:Bool = true)
	{
		var animFrames = [];
		@:privateAccess
		animation.findByPrefix(animFrames, prefix); // adds valid frames to animFrames
		if (animFrames.length < 1)
			return;

		animation.addByPrefix(name, prefix, framerate, doLoop);
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (mustPress)
		{
			canBeHit = (strumTime > Conductor.songPosition - (Conductor.safeZoneOffset * lateHitMult)
				&& strumTime < Conductor.songPosition + (Conductor.safeZoneOffset * earlyHitMult));

			if (strumTime < Conductor.songPosition - Conductor.safeZoneOffset && !wasGoodHit)
				tooLate = true;
		}
		else
		{
			canBeHit = false;

			if (!wasGoodHit && strumTime <= Conductor.songPosition)
			{
				if (!isSustainNote || (prevNote.wasGoodHit && !ignoreNote))
					wasGoodHit = true;
			}
		}
		if (tooLate && !inEditor)
		{
			if (alpha > 0.3)
				alpha = 0.3;
		}
	}

	override public function destroy()
	{
		super.destroy();
		_lastValidChecked = '';

		super.destroy();
	}

	public function followStrumNote(myStrum:StrumNote, fakeCrochet:Float, songSpeed:Float = 1)
	{
		var strumX:Float = myStrum.x;
		var strumY:Float = myStrum.y;
		var strumAngle:Float = myStrum.angle;
		var strumAlpha:Float = myStrum.alpha;
		var strumDirection:Float = myStrum.direction;

		distance = (0.45 * (Conductor.songPosition - strumTime) * songSpeed * multSpeed);
		if (!myStrum.downScroll)
			distance *= -1;

		var angleDir = strumDirection * Math.PI / 180;
		if (isSustainNote)
			angle = strumDirection - 90 + offsetAngle;
		else if (copyAngle)
			angle = strumAngle + offsetAngle;

		if (isSustainNote)
			flipY = myStrum.downScroll;

		if (copyAlpha)
			alpha = strumAlpha * multAlpha;

		if (isSustainNote)
		{
			var axisX:Float = Math.cos(angleDir);
			var axisY:Float = Math.sin(angleDir);
			var sustainCorrectionOffset:Float = correctionOffset;
			if (!PlayState.isPixelStage)
				sustainCorrectionOffset = myStrum.downScroll ? 0 : ((parent != null) ? parent.height / 2 : correctionOffset);

			var sustainVisualOffset:Float = 0;

			if (myStrum.downScroll)
			{
				final sustainScaleY = isSustainEnd ? 1.0 : scale.y;
				sustainVisualOffset = (frameHeight * sustainScaleY) - (Note.swagWidth / 2);
				if (PlayState.isPixelStage)
					sustainVisualOffset += PlayState.daPixelZoom * 9.5;
			}

			var alongAxis:Float = distance + sustainCorrectionOffset - sustainVisualOffset + offsetY;
			var noteX:Float = strumX + offsetX + (axisX * alongAxis);
			var noteY:Float = strumY + (axisY * alongAxis);

			if (copyX)
				x = noteX;

			if (copyY)
				y = noteY;
		}
		else
		{
			if (copyX)
				x = strumX + offsetX + Math.cos(angleDir) * distance;

			if (copyY)
				y = strumY + offsetY + Math.sin(angleDir) * distance;
		}
	}

	public function clipToStrumNote(myStrum:StrumNote)
	{
		var angleDir:Float = myStrum.direction * Math.PI / 180;
		var axisX:Float = Math.cos(angleDir);
		var axisY:Float = Math.sin(angleDir);
		var clipOffset:Float = Note.swagWidth / 2;
		var centerX:Float = myStrum.x + offsetX + (axisX * clipOffset);
		var centerY:Float = myStrum.y + offsetY + (axisY * clipOffset);
		var centerProjection:Float = (centerX * axisX) + (centerY * axisY);
		var noteProjection:Float = (x * axisX) + (y * axisY);
		var localFrameHeight:Float = height / Math.max(scale.y, 0.00001);
		if ((mustPress || !ignoreNote) && (wasGoodHit || (prevNote.wasGoodHit && !canBeHit)))
		{
			var swagRect:FlxRect = clipRect;
			if (swagRect == null)
				swagRect = new FlxRect(0, 0, frameWidth, frameHeight);

			if (myStrum.downScroll)
			{
				var visibleWorldLength:Float = centerProjection - noteProjection;
				swagRect.width = frameWidth;
				swagRect.height = FlxMath.bound(visibleWorldLength / Math.max(scale.y, 0.00001), 0, localFrameHeight);
				swagRect.y = localFrameHeight - swagRect.height;
			}
			else
			{
				swagRect.y = FlxMath.bound((centerProjection - noteProjection) / Math.max(scale.y, 0.00001), 0, localFrameHeight);
				swagRect.width = frameWidth;
				swagRect.height = localFrameHeight - swagRect.y;
			}
			clipRect = swagRect;
		}
	}

	@:noCompletion
	override function set_clipRect(rect:FlxRect):FlxRect
	{
		clipRect = rect;

		if (frames != null)
			frame = frames.frames[animation.frameIndex];

		return rect;
	}
}

