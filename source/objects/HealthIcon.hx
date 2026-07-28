package objects;

import flixel.graphics.frames.FlxAtlasFrames;

class HealthIcon extends FlxSprite
{
	public var sprTracker:FlxSprite;
	private var isPlayer:Bool = false;
	private var char:String = '';

	public var isAnimated:Bool = false;
	public var animFPS:Int = 24;

	public function new(char:String = 'face', isPlayer:Bool = false, ?allowGPU:Bool = true)
	{
		super();
		this.isPlayer = isPlayer;
		changeIcon(char, allowGPU);
		scrollFactor.set();
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (sprTracker != null)
			setPosition(sprTracker.x + sprTracker.width + 12, sprTracker.y - 30);
	}

	private var iconOffsets:Array<Float> = [0, 0];
	public function changeIcon(char:String, ?allowGPU:Bool = true, ?forceAnimated:Bool = false) {
		if(this.char != char) {
			try {
				var name:String = 'icons/' + char;
				if(!Paths.fileExists('images/' + name + '.png', IMAGE)) name = 'icons/icon-' + char; //Older versions of psych engine's support
				if(!Paths.fileExists('images/' + name + '.png', IMAGE)) name = 'icons/icon-face'; //Prevents crash from missing icon

				var xmlPath:String = name + '.xml';
				isAnimated = forceAnimated || Paths.fileExists('images/' + xmlPath, TEXT);
				
				if(isAnimated) {
					var atlas:FlxAtlasFrames = null;
					try {
						atlas = Paths.getSparrowAtlas(name.substring(6));
					} catch(e:Dynamic) {
						trace('Error loading animated icon atlas for $char: $e');
						atlas = null;
					}
					
				if(atlas != null && atlas.frames != null && atlas.frames.length > 0) {
					frames = atlas;
					var hasNormalAnim:Bool = false;
					var hasLosingAnim:Bool = false;
					
					for(frame in frames.frames) {
						if(frame.name.startsWith('normal')) hasNormalAnim = true;
						if(frame.name.startsWith('losing')) hasLosingAnim = true;
						if(hasNormalAnim && hasLosingAnim) break;
					}
					if(hasNormalAnim) {
						animation.addByPrefix('normal', 'normal', animFPS, true, isPlayer);
						if(hasLosingAnim) {
							animation.addByPrefix('losing', 'losing', animFPS, true, isPlayer);
						}
						animation.play('normal');
					} else {
						animation.addByPrefix(char, '', animFPS, true, isPlayer);
						animation.play(char);
					}

					if(animation.curAnim != null && animation.curAnim.numFrames > 0) {
						var firstFrameData = frames.frames[0];
						if(firstFrameData != null && firstFrameData.frame != null) {
							iconOffsets[0] = (firstFrameData.frame.width - 150) / 2;
							iconOffsets[1] = (firstFrameData.frame.height - 150) / 2;
						} else {
							iconOffsets[0] = iconOffsets[1] = 0;
						}
					} else {
						iconOffsets[0] = iconOffsets[1] = 0;
					}
				} else {
					isAnimated = false;
					loadStaticIcon(name, allowGPU);
				}
			} else {
				loadStaticIcon(name, allowGPU);
			}
			
			updateHitbox();
			this.char = char;

			if(char.endsWith('-pixel'))
				antialiasing = false;
			else
				antialiasing = ClientPrefs.data.antialiasing;
			} catch(e:Dynamic) {
				trace('CRITICAL ERROR loading icon for $char: $e');
				var defaultName:String = 'icons/icon-face';
				if(Paths.fileExists('images/' + defaultName + '.png', IMAGE)) {
					try {
						isAnimated = false;
						loadStaticIcon(defaultName, allowGPU);
						updateHitbox();
						this.char = char;
					} catch(e2:Dynamic) {
						trace('ERROR: Could not load fallback icon either: $e2');
					}
				}
			}
		}
	}

	private function loadStaticIcon(name:String, allowGPU:Bool = true):Void {
		var graphic = Paths.image(name, allowGPU);
		if(graphic == null) {
			trace('ERROR: Could not load graphic for icon: $name');
			return;
		}
		
		var iSize:Float = 1.0;
		if(graphic.width > 0 && graphic.height > 0) {
			iSize = Math.round(graphic.width / graphic.height);
			if(iSize <= 0) iSize = 1.0;
		}
		
		loadGraphic(graphic, true, Math.floor(graphic.width / iSize), Math.floor(graphic.height));
		
		if(width > 0 && height > 0) {
			iconOffsets[0] = (width - 150) / iSize;
			iconOffsets[1] = (height - 150) / iSize;
		} else {
			iconOffsets[0] = iconOffsets[1] = 0;
		}
		
		if(frames != null && frames.frames != null && frames.frames.length > 0) {
			animation.add(char, [for(i in 0...frames.frames.length) i], 0, false, isPlayer);
			animation.play(char);
		}
	}

	public function playAnim(animName:String):Void {
		if(!isAnimated || animation.getByName(animName) == null) return;
		animation.play(animName);
	}

	public function updateIconState(healthPercent:Float):Void {
		if(!isAnimated) return;

		if(animation.getByName('losing') != null) {
			if(healthPercent < 0.2) {
				if(animation.curAnim == null || animation.curAnim.name != 'losing')
					playAnim('losing');
			} else {
				if(animation.curAnim == null || animation.curAnim.name != 'normal')
					playAnim('normal');
			}
		}
	}

	public var autoAdjustOffset:Bool = true;
	override function updateHitbox()
	{
		super.updateHitbox();
		if(autoAdjustOffset)
		{
			offset.x = iconOffsets[0];
			offset.y = iconOffsets[1];
		}
	}

	public function getCharacter():String {
		return char;
	}
}
