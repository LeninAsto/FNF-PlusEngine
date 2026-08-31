package substates;

import backend.MusicBeatSubstate;
import backend.Paths;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.addons.transition.FlxTransitionableState;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.util.FlxSort;
import flixel.util.FlxTimer;
import haxe.Json;
import openfl.utils.AssetType;
import openfl.utils.Assets;

using Lambda;
using StringTools;

typedef StickerSubStateParams =
{
	?targetState:StickerSubState->FlxState,
	?stickerPack:String,
	?oldStickers:Array<StickerSprite>,
	?playOutOnTarget:Bool,
}

class StickerSubState extends MusicBeatSubstate
{
	public static var transitionSprite:Null<StickerTransitionSprite> = null;
	public var grpStickers:FlxTypedGroup<StickerSprite>;

	var targetState:StickerSubState->FlxState;
	var stickerPackId:String;
	var stickerPack:Null<StickerPack>;
	var soundSelections:Array<String> = [];
	var soundSelection:String = "";
	var sounds:Array<String> = [];
	var playOutOnTarget:Bool = false;
	var switchingState:Bool = false;

	public function new(params:StickerSubStateParams)
	{
		super();

		if (params == null)
			params = {};

		transitionSprite ??= new StickerTransitionSprite();
		targetState = params.targetState != null ? params.targetState : _ -> states.FreeplayStateSelector.create();
		playOutOnTarget = params.playOutOnTarget == true;
		stickerPackId = params.stickerPack != null ? params.stickerPack : "default";
		stickerPack = resolveStickerPack(stickerPackId);
		grpStickers = new FlxTypedGroup<StickerSprite>();
		resolveStickerSounds();

		if (params.oldStickers != null)
		{
			for (sticker in params.oldStickers)
				grpStickers.add(sticker);
			degenStickers();
		}
		else if (stickerPack == null)
		{
			trace('Sticker transition skipped: no sticker pack available for "$stickerPackId".');
			skipStickerTransition();
		}
		else
			regenStickers();
	}

	static function resolveStickerPack(id:String):Null<StickerPack>
	{
		var packsToTry:Array<String> = [];
		if (id != null && id.length > 0)
			packsToTry.push(id);
		packsToTry.push("default");
		packsToTry.push("standard-bf");
		packsToTry.push("bonus-tutorial");
		packsToTry.push("bonus-weekend1");

		for (packId in packsToTry)
		{
			var pack = StickerPack.fromJson(packId);
			if (pack != null && pack.getStickers().length > 0)
				return pack;
		}

		var assetsInList:Array<String> = Assets.list(AssetType.TEXT);
		for (asset in assetsInList)
		{
			var marker:String = "assets/shared/data/stickerpacks/";
			if (!asset.startsWith(marker) || !asset.endsWith(".json"))
				continue;
			var packId:String = asset.substr(marker.length);
			packId = packId.substr(0, packId.length - ".json".length);
			var fallback = StickerPack.fromJson(packId);
			if (fallback != null && fallback.getStickers().length > 0)
				return fallback;
		}

		return null;
	}

	function resolveStickerSounds():Void
	{
		var assetsInList = Assets.list();
		soundSelections = assetsInList.filter(a -> a.startsWith('assets/shared/sounds/stickersounds/')).map(a ->
		{
			return a.replace('assets/shared/sounds/stickersounds/', '').split('/')[0];
		});

		for (selection in soundSelections.copy())
		{
			while (soundSelections.contains(selection))
				soundSelections.remove(selection);
			soundSelections.push(selection);
		}

		soundSelection = FlxG.random.getObject(soundSelections);
		if (soundSelection == null)
			return;

		sounds = assetsInList.filter(a -> a.startsWith('assets/shared/sounds/stickersounds/' + soundSelection + '/'));
		for (i in 0...sounds.length)
		{
			sounds[i] = sounds[i].replace('assets/shared/sounds/', '');
			sounds[i] = sounds[i].substring(0, sounds[i].lastIndexOf('.'));
		}
	}

	function skipStickerTransition():Void
	{
		switchingState = true;
		FlxTransitionableState.skipNextTransIn = true;
		FlxTransitionableState.skipNextTransOut = true;
		FlxG.switchState(() -> targetState(this));
	}

	function playRandomStickerSound():Void
	{
		if (sounds == null || sounds.length == 0)
			return;

		var sound:String = FlxG.random.getObject(sounds);
		if (sound != null && sound.length > 0)
			FlxG.sound.play(Paths.sound(sound));
	}

	public function degenStickers():Void
	{
		if (grpStickers.members == null || grpStickers.members.length == 0)
		{
			switchingState = false;
			close();
			return;
		}

		transitionSprite?.insert();
		transitionSprite?.setupStickers(grpStickers);

		for (ind => sticker in grpStickers.members)
		{
			new FlxTimer().start(sticker.timing, _ ->
			{
				sticker.visible = false;
				playRandomStickerSound();
				if (grpStickers == null || ind == grpStickers.members.length - 1)
				{
					switchingState = false;
					close();
				}
			});
		}
	}

	function regenStickers():Void
	{
		if (stickerPack == null)
		{
			skipStickerTransition();
			return;
		}

		transitionSprite?.insert();
		if (grpStickers.members.length > 0)
			grpStickers.clear();

		var xPos:Float = -100;
		var yPos:Float = -100;
		while (xPos <= FlxG.width)
		{
			var stickerPath:String = stickerPack.getRandomStickerPath(false);
			if (stickerPath == null || stickerPath.length == 0)
			{
				skipStickerTransition();
				return;
			}

			var sticky:StickerSprite = new StickerSprite(0, 0, stickerPath);
			sticky.visible = false;
			sticky.x = xPos;
			sticky.y = yPos;
			xPos += sticky.frameWidth * 0.5;
			if (xPos >= FlxG.width && yPos <= FlxG.height)
			{
				xPos = -100;
				yPos += FlxG.random.float(70, 120);
			}
			sticky.angle = FlxG.random.int(-60, 70);
			grpStickers.add(sticky);
		}

		FlxG.random.shuffle(grpStickers.members);

		var lastStickerPath:String = stickerPack.getRandomStickerPath(true);
		if (lastStickerPath == null || lastStickerPath.length == 0)
		{
			skipStickerTransition();
			return;
		}

		var lastSticker:StickerSprite = new StickerSprite(0, 0, lastStickerPath);
		lastSticker.visible = false;
		lastSticker.updateHitbox();
		lastSticker.angle = 0;
		lastSticker.screenCenter();
		grpStickers.add(lastSticker);
		transitionSprite?.setupStickers(grpStickers);

		for (ind => sticker in grpStickers.members)
		{
			sticker.timing = FlxMath.remapToRange(ind, 0, grpStickers.members.length, 0, 0.9);
			new FlxTimer().start(sticker.timing, _ ->
			{
				if (grpStickers == null)
					return;
				sticker.visible = true;
				playRandomStickerSound();
				var frameTimer:Int = FlxG.random.int(0, 2);
				if (ind == grpStickers.members.length - 1)
					frameTimer = 2;
				new FlxTimer().start((1 / 24) * frameTimer, _ ->
				{
					if (sticker == null)
						return;
					sticker.scale.x = sticker.scale.y = FlxG.random.float(0.97, 1.02);
					if (ind == grpStickers.members.length - 1)
					{
						switchingState = true;
						FlxTransitionableState.skipNextTransIn = true;
						FlxTransitionableState.skipNextTransOut = true;

						var oldStickers:Array<StickerSprite> = [];
						if (playOutOnTarget)
						{
							oldStickers = grpStickers.members.copy();
							FlxG.signals.postStateSwitch.addOnce(() ->
							{
								if (FlxG.state != null)
								{
									FlxG.state.openSubState(new StickerSubState({
										stickerPack: stickerPackId,
										oldStickers: oldStickers
									}));
								}
							});
						}

						FlxG.switchState(() -> targetState(this));
					}
				});
			});
		}

		grpStickers.sort((ord, a, b) -> FlxSort.byValues(ord, a.timing, b.timing));
	}

	override public function onResize(width:Int, height:Int):Void
		transitionSprite?.onResize();

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);
		transitionSprite?.update(elapsed);
	}

	override public function close():Void
	{
		if (switchingState)
			return;
		transitionSprite?.clear();
		super.close();
	}

	override public function destroy():Void
	{
		if (switchingState)
			return;
		transitionSprite?.clear();
		super.destroy();
	}
}

class StickerSprite extends FlxSprite
{
	public var timing:Float = 0;

	public function new(x:Float, y:Float, filePath:String)
	{
		super(x, y);
		loadGraphic(Paths.image(filePath));
		updateHitbox();
		scrollFactor.set();
	}
}

class StickerPack
{
	public final id:String;
	public final name:String;
	public final artist:String;
	final stickers:Array<String>;

	public function new(id:String, name:String, artist:String, stickers:Array<String>)
	{
		this.id = id;
		this.name = name;
		this.artist = artist;
		this.stickers = stickers;
	}

	public function getStickers():Array<String>
		return stickers;

	public function getRandomStickerPath(last:Bool):String
		return FlxG.random.getObject(stickers);

	public static function fromJson(id:String):Null<StickerPack>
	{
		if (id == null || id.length == 0)
			return null;

		var raw:String = Paths.getTextFromFile('data/stickerpacks/$id.json', true);
		if (raw == null || raw.length == 0)
			return null;

		try
		{
			var data:Dynamic = Json.parse(raw);
			var rawStickers:Array<Dynamic> = cast Reflect.field(data, "stickers");
			if (rawStickers == null || rawStickers.length == 0)
				return null;

			var stickers:Array<String> = [];
			for (rawSticker in rawStickers)
			{
				var sticker:String = Std.string(rawSticker);
				if (sticker == null || sticker.length == 0)
					continue;
				if (Paths.fileExists('images/$sticker.png', AssetType.IMAGE, true))
					stickers.push(sticker);
			}

			var packName:Dynamic = Reflect.field(data, "name");
			var packArtist:Dynamic = Reflect.field(data, "artist");
			return stickers.length > 0 ? new StickerPack(id, packName == null ? id : Std.string(packName), packArtist == null ? "" : Std.string(packArtist), stickers) : null;
		}
		catch (e:Dynamic)
		{
			trace('[StickerSubState] Could not parse sticker pack "$id": $e');
			return null;
		}
	}
}

@:access(flixel.FlxCamera)
class StickerTransitionSprite extends openfl.display.Sprite
{
	public var stickersCamera:FlxCamera;
	public var grpStickers:FlxTypedGroup<StickerSprite>;

	public function new()
	{
		super();
		visible = false;
		stickersCamera = new FlxCamera();
		stickersCamera.bgColor = 0x00000000;
		addChild(stickersCamera.flashSprite);
		FlxG.signals.gameResized.add((_, _) -> onResize());
		scrollRect = new openfl.geom.Rectangle();
		onResize();
	}

	public function update(elapsed:Float):Void
	{
		stickersCamera.visible = visible;
		if (!visible)
			return;

		grpStickers?.update(elapsed);
		stickersCamera.update(elapsed);
		stickersCamera?.clearDrawStack();
		stickersCamera?.canvas?.graphics.clear();
		grpStickers?.draw();
		stickersCamera.render();
	}

	public function insert():Void
	{
		FlxG.addChildBelowMouse(this, 1);
		visible = true;
		onResize();
	}

	public function clear():Void
	{
		FlxG.removeChild(this);
		visible = false;
		grpStickers = null;
		stickersCamera?.clearDrawStack();
		stickersCamera?.canvas?.graphics.clear();
	}

	public function onResize():Void
	{
		x = y = 0;
		scaleX = 1;
		scaleY = 1;

		var width:Float = FlxG.width;
		var height:Float = FlxG.height;
		if (FlxG.camera != null && FlxG.camera._scrollRect != null && FlxG.camera._scrollRect.scrollRect != null)
		{
			width = FlxG.camera._scrollRect.scrollRect.width;
			height = FlxG.camera._scrollRect.scrollRect.height;
		}

		__scrollRect.setTo(0, 0, width, height);
		stickersCamera.onResize();
		stickersCamera._scrollRect.scrollRect = scrollRect;
	}

	public function setupStickers(group:FlxTypedGroup<StickerSprite>):Void
	{
		grpStickers = group;
		grpStickers.camera = stickersCamera;
	}
}
