package objects;

import backend.animation.PsychAnimationController;
import shaders.RGBPalette.RGBShaderReference;
import shaders.ColorSwap;
#if mobile
import mobile.backend.MobileScaleMode;
#end

class StrumNote extends FlxSprite
{
	public var rgbShader:RGBShaderReference;
	public var colorSwap:ColorSwap;
	public var resetAnim:Float = 0;

	private var noteData:Int = 0;

	public var direction:Float = 90;
	public var downScroll:Bool = false;
	public var sustainReduce:Bool = true;

	private var player:Int;
	public var strumLineIndex(default, null):Int;

	public var texture(default, set):String = null;

	private function set_texture(value:String):String
	{
		if (texture != value)
		{
			texture = value;
			reloadNote();
		}
		return value;
	}

	public var useRGBShader:Bool = true;

	private var lastCenteredAnim:String = null;

	public function new(x:Float, y:Float, leData:Int, player:Int)
	{
		animation = new PsychAnimationController(this);

		noteData = leData;
		this.player = player;
		this.strumLineIndex = player;
		this.noteData = leData;
		this.ID = noteData;
		super(x, y);

		var skin:String = null;
		if (PlayState.SONG != null && PlayState.SONG.arrowSkin != null && PlayState.SONG.arrowSkin.length > 1)
			skin = PlayState.SONG.arrowSkin;
		else
			skin = Note.getDefaultNoteSkinPath(PlayState.isPixelStage);
		skin = Note.resolveNoteSkinPath(skin, PlayState.isPixelStage);

		rgbShader = new RGBShaderReference(this, Note.initializeGlobalRGBShader(leData));
		rgbShader.enabled = false;
		useRGBShader = Note.usesRGBShader();
		if (Note.usesClassicColors())
		{
			colorSwap = new ColorSwap();
			shader = colorSwap.shader;
		}

		var arr:Array<FlxColor> = Note.getNoteColorPalette(leData);
		@:bypassAccessor
		{
			rgbShader.r = arr[0];
			rgbShader.g = arr[1];
			rgbShader.b = arr[2];
		}

		texture = skin; // Load texture and anims

		scrollFactor.set();
		playAnim('static');
	}

	public function reloadNote()
	{
		var lastAnim:String = null;
		if (animation.curAnim != null)
			lastAnim = animation.curAnim.name;
		lastCenteredAnim = null;

		if (PlayState.isPixelStage)
		{
			loadGraphic(Paths.image('pixelUI/' + texture));
			width = width / 4;
			height = height / 5;
			loadGraphic(Paths.image('pixelUI/' + texture), true, Math.floor(width), Math.floor(height));

			antialiasing = false;
			setGraphicSize(Std.int(width * PlayState.daPixelZoom));

			animation.add('green', [6]);
			animation.add('red', [7]);
			animation.add('blue', [5]);
			animation.add('purple', [4]);
			switch (Math.abs(noteData) % 4)
			{
				case 0:
					animation.add('static', [0]);
					animation.add('pressed', [4, 8], 12, false);
					animation.add('confirm', [12, 16], 24, false);
				case 1:
					animation.add('static', [1]);
					animation.add('pressed', [5, 9], 12, false);
					animation.add('confirm', [13, 17], 24, false);
				case 2:
					animation.add('static', [2]);
					animation.add('pressed', [6, 10], 12, false);
					animation.add('confirm', [14, 18], 12, false);
				case 3:
					animation.add('static', [3]);
					animation.add('pressed', [7, 11], 12, false);
					animation.add('confirm', [15, 19], 24, false);
			}
		}
		else
		{
			frames = Paths.getSparrowAtlas(texture);
			animation.addByPrefix('green', 'arrowUP');
			animation.addByPrefix('blue', 'arrowDOWN');
			animation.addByPrefix('purple', 'arrowLEFT');
			animation.addByPrefix('red', 'arrowRIGHT');

			antialiasing = ClientPrefs.data.antialiasing;
			setGraphicSize(Std.int(width * 0.7));

			switch (Math.abs(noteData) % 4)
			{
				case 0:
					animation.addByPrefix('static', 'arrowLEFT');
					animation.addByPrefix('pressed', 'left press', 24, false);
					animation.addByPrefix('confirm', 'left confirm', 24, false);
				case 1:
					animation.addByPrefix('static', 'arrowDOWN');
					animation.addByPrefix('pressed', 'down press', 24, false);
					animation.addByPrefix('confirm', 'down confirm', 24, false);
				case 2:
					animation.addByPrefix('static', 'arrowUP');
					animation.addByPrefix('pressed', 'up press', 24, false);
					animation.addByPrefix('confirm', 'up confirm', 24, false);
				case 3:
					animation.addByPrefix('static', 'arrowRIGHT');
					animation.addByPrefix('pressed', 'right press', 24, false);
					animation.addByPrefix('confirm', 'right confirm', 24, false);
			}
		}
		updateHitbox();

		if (lastAnim != null)
			playAnim(lastAnim, true);

		useRGBShader = Note.usesRGBShader();
		if (Note.usesClassicColors())
		{
			if (colorSwap == null)
				colorSwap = new ColorSwap();
			shader = colorSwap.shader;
		}
	}

	public function playerPosition(?overridePlayer:Null<Int> = null)
	{
		var playerValue:Int = overridePlayer != null ? overridePlayer : player;
		x += Note.swagWidth * noteData;
		x += 50;
		#if mobile
		x += MobileScaleMode.getHorizontalOffset();
		x += ((MobileScaleMode.getSafeWidth() / 2) * playerValue);
		#else
		x += ((FlxG.width / 2) * playerValue);
		#end
	}

	override function update(elapsed:Float)
	{
		if (resetAnim > 0)
		{
			resetAnim -= elapsed;
			if (resetAnim <= 0)
			{
				playAnim('static');
				resetAnim = 0;
			}
		}
		super.update(elapsed);
	}

	public function playAnim(anim:String, ?force:Bool = false)
	{
		animation.play(anim, force);
		if (animation.curAnim != null)
		{
			var curAnimName:String = animation.curAnim.name;
			if (curAnimName != lastCenteredAnim)
			{
				centerOffsets();
				centerOrigin();
				lastCenteredAnim = curAnimName;
			}
		}

		if (rgbShader != null)
		{
			var shouldUseRGB:Bool = useRGBShader && animation.curAnim != null && animation.curAnim.name != 'static';
			if (rgbShader.enabled != shouldUseRGB)
				rgbShader.enabled = shouldUseRGB;
		}
		if (Note.usesClassicColors())
		{
			if (animation.curAnim == null || animation.curAnim.name == 'static')
				Note.resetHSVColorSwap(colorSwap);
			else
				Note.applyHSVToColorSwap(colorSwap, noteData);
		}
	}
}
