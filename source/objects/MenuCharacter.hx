package objects;

import backend.AssetLoader;
import backend.Mods;
import haxe.Json;

typedef MenuCharacterFile =
{
	var image:String;
	var scale:Float;
	var position:Array<Int>;
	var idle_anim:String;
	var confirm_anim:String;
	var flipX:Bool;
	var antialiasing:Null<Bool>;
}

class MenuCharacter extends FlxSprite
{
	public var character:String;
	public var hasConfirmAnimation:Bool = false;

	private static var DEFAULT_CHARACTER:String = 'bf';

	var loadedModDirectory:String = null;

	public function new(x:Float, character:String = 'bf')
	{
		super(x);

		changeCharacter(character);
	}

	public function changeCharacter(?character:String = 'bf')
	{
		if (character == null)
			character = '';
		var currentDirectory:String = #if MODS_ALLOWED Mods.currentModDirectory #else '' #end;
		if (character == this.character && currentDirectory == loadedModDirectory)
			return;

		this.character = character;
		loadedModDirectory = currentDirectory;
		visible = true;

		var dontPlayAnim:Bool = false;
		scale.set(1, 1);
		updateHitbox();

		color = FlxColor.WHITE;
		alpha = 1;

		hasConfirmAnimation = false;
		switch (character)
		{
			case '':
				visible = false;
				dontPlayAnim = true;
			default:
				var characterPath:String = 'images/menucharacters/' + character + '.json';

				var path:String = Paths.getPath(characterPath, TEXT);
				if (!AssetLoader.exists(path, TEXT))
				{
					path = Paths.getPath('images/menucharacters/' + DEFAULT_CHARACTER + '.json', TEXT);
					color = FlxColor.BLACK;
					alpha = 0.6;
				}

				var charFile:MenuCharacterFile = null;
				try
				{
					var rawJson:String = AssetLoader.loadText(path);
					if (rawJson == null || rawJson.length == 0)
						throw 'Missing menu character file: $path';

					charFile = Json.parse(rawJson);
				}
				catch (e:Dynamic)
				{
					trace('Error loading menu character file of "$character": $e');
				}

				if (charFile == null || charFile.image == null || charFile.image.length == 0 || charFile.idle_anim == null || charFile.idle_anim.length == 0)
				{
					trace('Invalid menu character file of "$character", hiding sprite to prevent a crash.');
					visible = false;
					dontPlayAnim = true;
					return;
				}

				try
				{
					frames = Paths.getSparrowAtlas('menucharacters/' + charFile.image);
				}
				catch (e:Dynamic)
				{
					trace('Error loading menu character atlas of "$character": $e');
				}

				if (frames == null)
				{
					trace('Error loading menu character atlas of "$character": menucharacters/${charFile.image}');
					visible = false;
					dontPlayAnim = true;
					return;
				}

				animation.addByPrefix('idle', charFile.idle_anim, 24);
				if (animation.getByName('idle') == null)
				{
					trace('Error loading menu character idle animation of "$character": ${charFile.idle_anim}');
					visible = false;
					dontPlayAnim = true;
					return;
				}

				var confirmAnim:String = charFile.confirm_anim;
				if (confirmAnim != null && confirmAnim.length > 0 && confirmAnim != charFile.idle_anim)
				{
					animation.addByPrefix('confirm', confirmAnim, 24, false);
					if (animation.getByName('confirm') != null) // check for invalid animation
						hasConfirmAnimation = true;
				}
				flipX = (charFile.flipX == true);

				var charScale:Float = (charFile.scale > 0) ? charFile.scale : 1;
				if (charScale != 1)
				{
					scale.set(charScale, charScale);
					updateHitbox();
				}
				if (charFile.position != null && charFile.position.length >= 2)
					offset.set(charFile.position[0], charFile.position[1]);
				animation.play('idle');

				antialiasing = (charFile.antialiasing != false && ClientPrefs.data.antialiasing);
		}
	}
}

