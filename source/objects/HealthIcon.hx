package objects;

import flixel.graphics.frames.FlxAtlasFrames;
import flixel.graphics.FlxGraphic;
import openfl.display.BitmapData;
#if MODS_ALLOWED
import backend.Mods;
#end

class HealthIcon extends FlxSprite
{
	public var sprTracker:FlxSprite;

	private var isPlayer:Bool = false;
	private var char:String = '';
	private var requestedAnimated:Bool = false;

	public var isAnimated:Bool = false;
	public var animFPS:Int = 24;

	public var baseScale:Float = 1.0;

	public function new(char:String = 'face', isPlayer:Bool = false, ?allowGPU:Bool = true, ?animFPS:Int = 24)
	{
		super();
		this.isPlayer = isPlayer;
		changeIcon(char, allowGPU, false, animFPS);
		scrollFactor.set();
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (sprTracker != null)
			setPosition(sprTracker.x + sprTracker.width + 12, sprTracker.y - 30);
	}

	private var iconOffsets:Array<Float> = [0, 0];
	public static var verboseIconLoading:Bool = false;

	public function changeIcon(char:String, ?allowGPU:Bool = true, ?forceAnimated:Bool = false, ?animFPS:Int = 24)
	{
		if (this.char != char || this.animFPS != animFPS || this.requestedAnimated != forceAnimated)
		{
			this.animFPS = animFPS > 0 ? animFPS : 24;
			this.requestedAnimated = forceAnimated;
			try
			{
				var requestedChar:String = char;
				var wasAnimated:Bool = isAnimated;

				var name:String = 'icons/' + char;
				var currentModForTrace:String = '';
				#if MODS_ALLOWED
				currentModForTrace = Mods.currentModDirectory;
				#end
				iconTrace('request "$requestedChar" currentMod="$currentModForTrace"');
				iconTrace('  try images/$name.png -> ${Paths.fileExists('images/' + name + '.png', IMAGE)}');
				if (!Paths.fileExists('images/' + name + '.png', IMAGE))
				{
					name = 'icons/icon-' + char; // Older versions of psych engine's support
					iconTrace('  try images/$name.png -> ${Paths.fileExists('images/' + name + '.png', IMAGE)}');
				}
				if (!Paths.fileExists('images/' + name + '.png', IMAGE))
				{
					iconTrace('  missing "$requestedChar"; falling back to icons/icon-face');
					name = 'icons/icon-face'; // Prevents crash from missing icon
				}

				var xmlPath:String = name + '.xml';
				isAnimated = forceAnimated && Paths.fileExists('images/' + xmlPath, TEXT);
				if (forceAnimated && !isAnimated)
					trace('Animated icon XML not found: images/$xmlPath');
				iconTrace('  selected "$name" animated=$isAnimated');

				if (isAnimated)
				{
					var atlas:FlxAtlasFrames = null;
					try
					{
						atlas = Paths.getSparrowAtlas(name, null, allowGPU);
					}
					catch (e:Dynamic)
					{
						trace('Error loading animated icon atlas for $char: $e');
						atlas = null;
					}

					if (atlas != null && atlas.frames != null && atlas.frames.length > 0)
					{
						var normalPrefix:String = null;
						var losingPrefix:String = null;
						var winningPrefix:String = null;
						for (frame in atlas.frames)
						{
							if (frame.name == null) continue;
							var lower = frame.name.toLowerCase();
							if (normalPrefix == null && (lower.startsWith('normal') || lower.startsWith('neutral')))
								normalPrefix = frame.name.substr(0, lower.startsWith('neutral') ? 7 : 6);
							if (losingPrefix == null && (lower.startsWith('losing') || lower.startsWith('defeat')))
								losingPrefix = frame.name.substr(0, 6);
							if (winningPrefix == null && lower.startsWith('winning'))
								winningPrefix = frame.name.substr(0, 7);
						}
						frames = normalizeStripAtlas(atlas, normalPrefix != null && losingPrefix != null);
						animation.addByPrefix('normal', normalPrefix != null ? normalPrefix : '', this.animFPS, true, isPlayer);
						if (losingPrefix != null) animation.addByPrefix('losing', losingPrefix, this.animFPS, true, isPlayer);
						if (winningPrefix != null) animation.addByPrefix('winning', winningPrefix, this.animFPS, true, isPlayer);
						animation.play('normal', true);
						recalculateOffsetsForAnim('normal');
					}
					else
					{
						isAnimated = false;
						loadStaticIcon(name, allowGPU);
					}
				}
				else
				{
					loadStaticIcon(name, allowGPU);
				}

				if (wasAnimated && !isAnimated)
					scale.set(1, 1);
				updateHitbox();
				this.char = char;
				computeBaseScale();
				if (isAnimated)
				{
					scale.set(baseScale, baseScale);
					updateHitbox();
				}
				iconTrace('loaded "$requestedChar" as "$name" size=${width}x${height}');

				if (char.endsWith('-pixel'))
					antialiasing = false;
				else
					antialiasing = ClientPrefs.data.antialiasing;
			}
			catch (e:Dynamic)
			{
				trace('CRITICAL ERROR loading icon for $char: $e');
				var defaultName:String = 'icons/icon-face';
				if (Paths.fileExists('images/' + defaultName + '.png', IMAGE))
				{
					try
					{
						isAnimated = false;
						loadStaticIcon(defaultName, allowGPU);
						updateHitbox();
						this.char = char;
						computeBaseScale();
					}
					catch (e2:Dynamic)
					{
						trace('ERROR: Could not load fallback icon either: $e2');
					}
				}
			}
		}
	}

	static function iconTrace(message:String):Void
	{
		if (verboseIconLoading)
			trace('[HealthIcon] ' + message);
	}

	private static function normalizeStripAtlas(atlas:FlxAtlasFrames, hasStates:Bool):FlxAtlasFrames
	{
		if (!hasStates || atlas.frames.length == 0)
			return atlas;
		var first = atlas.frames[0];
		var cell = first.sourceSize.y;
		if (cell <= 0 || Math.abs(first.sourceSize.x - cell * 3) > 0.01)
			return atlas;
		for (frame in atlas.frames)
		{
			var slot = iconStripSlot(frame.name);
			var localX = frame.offset.x - slot * cell;
			if (slot < 0 || frame.sourceSize.x != cell * 3 || frame.sourceSize.y != cell
				|| localX < -cell * 0.1 || localX + frame.frame.width > cell * 1.1)
				return atlas;
		}
		var normalized = new FlxAtlasFrames(atlas.parent);
		for (frame in atlas.frames)
		{
			var localX = frame.offset.x - iconStripSlot(frame.name) * cell;
			normalized.addAtlasFrame(flixel.math.FlxRect.get(frame.frame.x, frame.frame.y, frame.frame.width, frame.frame.height), flixel.math.FlxPoint.get(cell, cell),
				flixel.math.FlxPoint.get(localX, frame.offset.y), frame.name, frame.angle, frame.flipX, frame.flipY, frame.duration);
		}
		return normalized;
	}

	private static function iconStripSlot(name:String):Int
	{
		if (name == null) return -1;
		var lower = name.toLowerCase();
		if (lower.startsWith('normal') || lower.startsWith('neutral')) return 0;
		if (lower.startsWith('losing') || lower.startsWith('defeat')) return 1;
		if (lower.startsWith('winning')) return 2;
		return -1;
	}

	private function computeBaseScale():Void
	{
		baseScale = frameWidth > 0 ? 150 / frameWidth : 1.0;
	}

	private function recalculateOffsetsForAnim(animName:String):Void
	{
		var referenceAnim = animation.getByName('normal');
		if (referenceAnim == null)
			referenceAnim = animation.getByName(animName);

		if (referenceAnim == null || referenceAnim.frames == null || referenceAnim.frames.length < 1)
		{
			iconOffsets[0] = iconOffsets[1] = 0;
			return;
		}

		var firstFrameIndex:Int = referenceAnim.frames[0];
		var firstFrame = (frames != null && frames.frames != null && firstFrameIndex >= 0 && firstFrameIndex < frames.frames.length)
			? frames.frames[firstFrameIndex]
			: null;

		if (firstFrame != null && firstFrame.frame != null)
		{
			var frameW:Float = firstFrame.frame.width;
			var frameH:Float = firstFrame.frame.height;

			if (frameW > 0 && frameH > 0)
			{
				iconOffsets[0] = (frameW - 150) / 2;
				iconOffsets[1] = (frameH - 150) / 2;
				return;
			}
		}

		iconOffsets[0] = iconOffsets[1] = 0;
	}

	private function loadStaticIcon(name:String, allowGPU:Bool = true):Void
	{
		var graphic = Paths.image(name, null, allowGPU);
		if (graphic == null)
		{
			trace('ERROR: Could not load graphic for icon: $name');
			return;
		}

		var iSize:Float = 1.0;
		if (graphic.width > 0 && graphic.height > 0)
		{
			iSize = Math.round(graphic.width / graphic.height);
			if (iSize <= 0)
				iSize = 1.0;
		}

		loadGraphic(graphic, true, Math.floor(graphic.width / iSize), Math.floor(graphic.height));

		if (width > 0 && height > 0)
		{
			iconOffsets[0] = (width - 150) / iSize;
			iconOffsets[1] = (height - 150) / iSize;
		}
		else
		{
			iconOffsets[0] = iconOffsets[1] = 0;
		}

		if (frames != null && frames.frames != null && frames.frames.length > 0)
		{
			animation.add(char, [for (i in 0...frames.frames.length) i], 0, false, isPlayer);
			animation.play(char);
		}
	}

	public function playAnim(animName:String):Void
	{
		if (!isAnimated || animation.getByName(animName) == null)
			return;
		animation.play(animName);
	}

	public function updateIconState(healthPercent:Float):Void
	{
		if (!isAnimated)
			return;

		var hasLosing:Bool = animation.getByName('losing') != null;
		var hasWinning:Bool = animation.getByName('winning') != null;

		var targetAnim:String = 'normal';

		if (hasWinning && healthPercent > 0.8)
			targetAnim = 'winning';
		else if (hasLosing && healthPercent < 0.2)
			targetAnim = 'losing';

		if (animation.curAnim == null || animation.curAnim.name != targetAnim)
		{
			playAnim(targetAnim);
			recalculateOffsetsForAnim(targetAnim);
			updateHitbox();
		}
	}

	public var autoAdjustOffset:Bool = true;

	override function updateHitbox()
	{
		super.updateHitbox();
		if (autoAdjustOffset)
		{
			offset.x = isAnimated ? (width - 150) * 0.5 : iconOffsets[0];
			offset.y = isAnimated ? (height - 150) * 0.5 : iconOffsets[1];
		}
	}

	public function getCharacter():String
	{
		return char;
	}
}
