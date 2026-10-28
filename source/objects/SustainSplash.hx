package objects;

import backend.ClientPrefs;
import shaders.ColorSwap;

class SustainSplash extends FlxSprite
{
	public static var startCrochet:Float;
	public static var frameRate:Int;

	public var strumNote:StrumNote;

	var timer:FlxTimer;
	var colorSwap:ColorSwap;
	var loadedPath:String;
	var loadedLane:Int = -1;
	var atlasScaleX:Float = 1;
	var atlasScaleY:Float = 1;

	public function new():Void
	{
		super();

		x = -50000;
		colorSwap = new ColorSwap();
		loadHoldCover(0);
	}

	function loadHoldCover(noteData:Int):Bool
	{
		final lane:Int = Note.normalizeNoteData(noteData);
		final atlasPath:String = getHoldCoverPath();
		if (loadedPath == atlasPath && loadedLane == lane && frames != null)
			return animation.exists('holdStart') && animation.exists('hold') && animation.exists('holdEnd');

		loadedPath = null;
		loadedLane = -1;
		frames = null;
		@:privateAccess animation.clearAnimations();

		if (Paths.fileExists('images/$atlasPath.png', IMAGE) && Paths.fileExists('images/$atlasPath.xml', TEXT))
		{
			// Paths owns the graphic cache. Keeping FlxAtlasFrames in another static
			// cache leaves them pointing at destroyed graphics after changing songs/mods.
			frames = Paths.getSparrowAtlas(atlasPath);
			if (frames == null)
				return false;
			scale.set(1, 1);
			updateHitbox();
			if (PlayState.isPixelStage)
			{
				setGraphicSize(Std.int(width * PlayState.daPixelZoom));
				updateHitbox();
			}
			atlasScaleX = scale.x;
			atlasScaleY = scale.y;
			antialiasing = ClientPrefs.data.antialiasing && !PlayState.isPixelStage;

			final suffix:String = getAnimationColor(lane);
			// The shader atlas has no color suffix. `holdCover` alone would also
			// swallow holdCoverStart/holdCoverEnd and replay the whole atlas as a GIF.
			final holdPrefix:String = suffix.length > 0 ? 'holdCover$suffix' : 'holdCover0';
			animation.addByPrefix('holdStart', 'holdCoverStart$suffix', 24, false);
			animation.addByPrefix('hold', holdPrefix, 24, true);
			animation.addByPrefix('holdEnd', 'holdCoverEnd$suffix', 24, false);
			if (!animation.exists('holdStart') || !animation.exists('hold') || !animation.exists('holdEnd'))
			{
				trace('Hold splash atlas is missing animations for lane $lane: $atlasPath');
				return false;
			}
			loadedPath = atlasPath;
			loadedLane = lane;
			return true;
		}

		trace('Hold splash atlas not found: $atlasPath');
		makeGraphic(1, 1, 0x00000000);
		return false;
	}

	public static function warmupHoldCover():Void
	{
		var splash = new SustainSplash();
		splash.kill();
	}

	function getHoldCoverPath():String
	{
		final pixelPrefix:String = PlayState.isPixelStage ? 'pixelUI/' : '';
		return pixelPrefix + (Note.usesRGBShader() ? 'holdCovers/holdCover-Vanilla' : 'holdCover-vanilla');
	}

	function getAnimationColor(lane:Int):String
	{
		// The pixel RGB atlas uses blue as its recolorable source; desktop RGB is neutral.
		if (Note.usesRGBShader())
			return PlayState.isPixelStage ? 'Blue' : '';

		final color:String = Note.colArray[lane];
		return color.charAt(0).toUpperCase() + color.substr(1);
	}

	override function update(elapsed)
	{
		super.update(elapsed);

		if (strumNote != null)
		{
			syncToStrumLayout();

			if (ClientPrefs.data.hideSustainSplash)
			{
				visible = false;
				alpha = 0;
			}
			else
			{
				// Manager restores renderer-suppressed sprites before this update.
				// Reading the normal property also keeps the native/no-manager path valid.
				visible = strumNote.visible;
				alpha = strumNote.alpha;
			}

		}
	}

	function syncToStrumLayout():Void
	{
		if (strumNote == null)
			return;

		var lineScale:Float = strumNote.layoutScale;
		if (!Math.isFinite(lineScale) || lineScale <= 0)
			lineScale = 1;
		var targetScaleX:Float = atlasScaleX * lineScale;
		var targetScaleY:Float = atlasScaleY * lineScale;
		if (Math.abs(scale.x - targetScaleX) > 0.0001 || Math.abs(scale.y - targetScaleY) > 0.0001)
		{
			scale.set(targetScaleX, targetScaleY);
			updateHitbox();
		}
		setPosition(strumNote.x, strumNote.y);
	}

	function playHoldLoop():Void
	{
		if (!alive || animation.curAnim?.name == 'holdEnd')
			return;

		animation.finishCallback = null;
		animation.play('hold', true, false, 0);
		if (animation.curAnim != null)
		{
			animation.curAnim.frameRate = frameRate;
			animation.curAnim.looped = true;
		}
		// Atlas animations do not necessarily share the same source size/offset.
		// The native FlxSprite renderer honors clipRect, so keeping holdStart's
		// smaller rectangle can clip the classic-color hold loop completely. The
		// modchart renderer draws its own geometry and used to hide this problem.
		refreshHoldClip();
	}

	inline function refreshHoldClip():Void
	{
		clipRect = null;
		clipRect = new flixel.math.FlxRect(0, !PlayState.isPixelStage ? 0 : -210, frameWidth, frameHeight);
	}

	public function finishHold():Void
	{
		if (!alive || animation.curAnim?.name == 'holdEnd')
			return;

		if (timer != null)
		{
			timer.cancel();
			timer = null;
		}

		clipRect = null;
		animation.finishCallback = null;
		animation.play('holdEnd', true, false, 0);
		if (animation.curAnim != null)
		{
			animation.curAnim.looped = false;
			animation.curAnim.frameRate = 24;
		}
		animation.finishCallback = (_:Dynamic) ->
		{
			x = -50000;
			kill();
		};
	}

	public function setupSusSplash(strum:StrumNote, daNote:Note, ?playbackRate:Float = 1):Void
	{
		if (ClientPrefs.data.hideSustainSplash || strum == null || daNote == null || !loadHoldCover(daNote.noteData))
		{
			visible = false;
			alpha = 0;
			kill();
			return;
		}

		final root:Note = daNote.isSustainNote ? daNote.parent : daNote;
		final safeRate:Float = playbackRate > 0 ? playbackRate : 1;
		final endTime:Float = root.strumTime + Math.max(0, root.sustainLength);
		final timeThingy:Float = Math.max(0.01, (endTime - Conductor.songPosition + ClientPrefs.data.ratingOffset) / safeRate * .001);
		final splashDisabled:Bool = root.noteSplashData.disabled;

		strumNote = strum;
		syncToStrumLayout();
		visible = true;
		active = true;
		animation.finishCallback = null;
		animation.play('holdStart', true, false, 0);
		if (animation.curAnim != null)
		{
			animation.curAnim.frameRate = 24;
			animation.curAnim.looped = false;
		}
		animation.finishCallback = (name:Dynamic) ->
		{
			if (name == 'holdStart')
				playHoldLoop();
		};
		refreshHoldClip();

		if (!Note.usesRGBShader())
		{
			shader = colorSwap.shader;
			Note.applyHSVToColorSwap(colorSwap, daNote.noteData);
		}
		else if (daNote.rgbShader != null && daNote.rgbShader.enabled && daNote.shader != null)
		{
			shader = new objects.NoteSplash.PixelSplashShaderRef().shader;
			shader.data.r.value = daNote.shader.data.r.value;
			shader.data.g.value = daNote.shader.data.g.value;
			shader.data.b.value = daNote.shader.data.b.value;
			shader.data.mult.value = daNote.shader.data.mult.value;
		}
		else
			shader = null;

		alpha = strum.alpha;
		offset.set(PlayState.isPixelStage ? 112.5 : 106.25, 100);

		if (timer != null)
			timer.cancel();

		timer = new FlxTimer().start(timeThingy, (idk:FlxTimer) ->
			{
				timer = null;
				if (!splashDisabled && animation != null && !ClientPrefs.data.hideSustainSplash)
				{
					alpha = strumNote != null ? strumNote.alpha : 1;
					finishHold();
					return;
				}
				kill();
			});
	}
}

