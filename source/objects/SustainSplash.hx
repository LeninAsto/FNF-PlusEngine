package objects;

import backend.ClientPrefs;

class SustainSplash extends FlxSprite
{
	public static var startCrochet:Float;
	public static var frameRate:Int;
	static var atlasCache:Map<String, Dynamic> = new Map();

	public var strumNote:StrumNote;

	var timer:FlxTimer;

	public function new():Void
	{
		super();

		x = -50000;

		// Verificar si el archivo existe antes de cargarlo
		var atlasPath = getHoldCoverPath();
		if (Paths.fileExists('images/$atlasPath.png', IMAGE) && Paths.fileExists('images/$atlasPath.xml', TEXT))
		{
			var cacheKey:String = 'images/$atlasPath';
			if (atlasCache.exists(cacheKey))
				frames = atlasCache.get(cacheKey);
			else
			{
				frames = Paths.getSparrowAtlas(atlasPath);
				if (frames != null)
					atlasCache.set(cacheKey, frames);
			}
			animation.addByPrefix('hold', 'holdCover0', 24, true);
			animation.addByPrefix('end', 'holdCoverEnd0', 24, false);
			if(!animation.getNameList().contains("hold")) trace("Hold splash is missing 'hold' anim!");
		}
		else
		{
			// Usar un atlas por defecto o crear frames vacíos
			trace('Hold splash atlas not found: $atlasPath');
			makeGraphic(1, 1, 0x00000000); // Crear una imagen transparente
		}
	}

	public static function warmupHoldCover():Void
	{
		var splash = new SustainSplash();
		splash.kill();
	}

	function getHoldCoverPath():String
	{
		if(!ClientPrefs.data.noteRGB)
		{
			var noRgbCandidates:Array<String> = [
				'holdCoversNoRGB/holdCover-Purple',
				'holdCoversNoRGB/holdCover-Blue',
				'holdCoversNoRGB/holdCover-Green',
				'holdCoversNoRGB/holdCover-Red'
			];
			for(path in noRgbCandidates)
				if (Paths.fileExists('images/$path.png', IMAGE) && Paths.fileExists('images/$path.xml', TEXT))
					return path;
		}
		return 'holdCovers/holdCover-Vanilla';
	}

	override function update(elapsed)
	{
		super.update(elapsed);

		if (strumNote != null)
		{
			setPosition(strumNote.x, strumNote.y);

			if (ClientPrefs.data.hideSustainSplash) {
				visible = false;
				alpha = 0;
			} else {
				visible = strumNote.visible;
				alpha = 1;
			}

			if (animation.curAnim?.name == "hold" && strumNote.animation.curAnim?.name == "static")
			{
				x = -50000;
				kill();
			}
		}
	}

	public function setupSusSplash(strum:StrumNote, daNote:Note, ?playbackRate:Float = 1):Void
	{
		if (ClientPrefs.data.hideSustainSplash) {
			visible = false;
			alpha = 0;
			kill();
			return;
		}

		final lengthToGet:Int = !daNote.isSustainNote ? daNote.tail.length : daNote.parent.tail.length;
		final timeToGet:Float = !daNote.isSustainNote ? daNote.strumTime : daNote.parent.strumTime;
		final timeThingy:Float = (startCrochet * lengthToGet + (timeToGet - Conductor.songPosition + ClientPrefs.data.ratingOffset)) / playbackRate * .001;

		var tailEnd:Note = !daNote.isSustainNote ? daNote.tail[daNote.tail.length - 1] : daNote.parent.tail[daNote.parent.tail.length - 1];

		animation.play('hold', true, false, 0);
		if (animation.curAnim != null)
		{
			animation.curAnim.frameRate = frameRate;
			animation.curAnim.looped = true;
		}
		clipRect = new flixel.math.FlxRect(0, !PlayState.isPixelStage ? 0 : -210, frameWidth, frameHeight);

		if (daNote.shader != null)
		{
			shader = new objects.NoteSplash.PixelSplashShaderRef().shader;
			shader.data.r.value = daNote.shader.data.r.value;
			shader.data.g.value = daNote.shader.data.g.value;
			shader.data.b.value = daNote.shader.data.b.value;
			shader.data.mult.value = daNote.shader.data.mult.value;
		}

		strumNote = strum;
		alpha = 1;
		offset.set(PlayState.isPixelStage ? 112.5 : 106.25, 100);

		if (timer != null)
			timer.cancel();

		if (!daNote.hitByOpponent && alpha != 0 && !ClientPrefs.data.hideSustainSplash)
			timer = new FlxTimer().start(timeThingy, (idk:FlxTimer) ->
			{
				if (!(daNote.isSustainNote ? daNote.parent.noteSplashData.disabled : daNote.noteSplashData.disabled) && animation != null)
				{
					alpha = 1;
					animation.play('end', true, false, 0);
					if (animation.curAnim != null)
					{
						animation.curAnim.looped = false;
						animation.curAnim.frameRate = 24;
					}
					clipRect = null;
					animation.finishCallback = (idkEither:Dynamic) ->
					{
						kill();
					}
					return;
				}
				kill();
			});
	}
}
