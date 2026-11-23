package states.editors.content;

import psychlua.backend.LuaUtils;

/** Replays only captured visual operations; never starts gameplay scripts. */
class ModchartScenePreview
{
	var sprites:Map<String, FlxSprite> = [];
	var operations:Array<Dynamic>;
	var targets:Map<String, FlxSprite>;
	var groups:Array<FlxTypedGroup<FlxSprite>>;
	var gameCamera:FlxCamera;
	var hudCamera:FlxCamera;
	var defaults:Array<Dynamic> = [];
	public var warnings:Array<String> = [];

	public function new(operations:Array<Dynamic>, targets:Map<String, FlxSprite>, groups:Array<FlxTypedGroup<FlxSprite>>,
		gameCamera:FlxCamera, hudCamera:FlxCamera)
	{
		this.operations = operations; this.targets = targets; this.groups = groups;
		this.gameCamera = gameCamera; this.hudCamera = hudCamera;
		for (target in targets) defaults.push({sprite: target, x: target.x, y: target.y, alpha: target.alpha, angle: target.angle,
			visible: target.visible, flipX: target.flipX, flipY: target.flipY, scaleX: target.scale.x, scaleY: target.scale.y,
			downScroll: Std.isOfType(target, objects.StrumNote) ? cast(target, objects.StrumNote).downScroll : null});
		for (op in operations)
		{
			var args:Array<Dynamic> = op.args;
			var tag = Std.string(args[0]);
			try switch (op.kind)
			{
				case 'makeLuaText':
					var text = new FlxText(args[3], args[4], args[2], args[1], 16);
					text.setFormat(Paths.font('vcr.ttf'), 16, FlxColor.WHITE, CENTER);
					sprites.set(tag, text);
				case 'makeLuaSprite', 'makeAnimatedLuaSprite':
					var sprite = new FlxSprite(args[2], args[3]);
					sprite.antialiasing = ClientPrefs.data.antialiasing;
					var image:String = args[1];
					if (image != null && image.length > 0)
					{
						if (op.kind == 'makeAnimatedLuaSprite') sprite.frames = Paths.getAtlas(image);
						else sprite.loadGraphic(Paths.image(image));
					}
					if (sprites.exists(tag)) { var previous = sprites.get(tag); for (group in groups) group.remove(previous, true); previous.destroy(); }
					sprites.set(tag, sprite);
				case 'makeGraphic':
					var sprite = sprites.get(tag);
					if (sprite != null) sprite.makeGraphic(Std.int(args[1]), Std.int(args[2]), CoolUtil.colorFromString(Std.string(args[3])));
				case 'addAnimationByPrefix':
					var sprite = sprites.get(tag);
					if (sprite != null) sprite.animation.addByPrefix(args[1], args[2], args[3], args[4]);
				case 'addAnimationByIndices':
					var sprite = sprites.get(tag);
					var indices = [for (part in Std.string(args[3]).split(',')) Std.parseInt(part)];
					if (sprite != null) sprite.animation.addByIndices(args[1], args[2], indices, '', args[4], args[5]);
				default:
			}
			catch (error:Dynamic) warnings.push(tag + ': ' + error);
		}
		// Resolve camera and order even if a script sets them before addLuaSprite.
		var cameras:Map<String, String> = [];
		var orders:Map<String, Int> = [];
		for (op in operations)
		{
			var args:Array<Dynamic> = op.args; var tag = Std.string(args[0]);
			if (op.kind == 'setObjectCamera') cameras.set(tag, Std.string(args[1]).toLowerCase());
			if (op.kind == 'setObjectOrder') orders.set(tag, Std.int(args[1]));
		}
		for (op in operations) if (op.kind == 'addLuaSprite' || op.kind == 'addLuaText')
		{
			var args:Array<Dynamic> = op.args; var tag = Std.string(args[0]); var sprite = sprites.get(tag);
			if (sprite == null) continue;
			var camera = cameras.get(tag);
			var hud = op.kind == 'addLuaText' || camera == 'hud' || camera == 'camhud' || camera == 'other' || camera == 'camother';
			var index = hud ? 2 : (args[1] == true ? 1 : 0);
			sprite.cameras = [hud ? hudCamera : gameCamera];
			sprite.ID = orders.exists(tag) ? orders.get(tag) : groups[index].length;
			if (index == 0)
			{
				// Behind characters still means above the stage backdrop, as in PlayState.
				var insertion = groups[0].length;
				for (target in targets) if (Std.isOfType(target, objects.Character)) {
					var position = groups[0].members.indexOf(target);
					if (position >= 0 && position < insertion) insertion = position;
				}
				if (orders.exists(tag)) insertion = Std.int(FlxMath.bound(orders.get(tag), 0, groups[0].length));
				groups[0].insert(insertion, sprite);
			}
			else groups[index].add(sprite);
		}
		for (index in 1...groups.length) groups[index].members.sort((a, b) -> a.ID - b.ID);
		update(-1);
	}

	function find(tag:String):FlxSprite return sprites.exists(tag) ? sprites.get(tag) : targets.get(tag);
	function property(path:String, value:Dynamic):Void
	{
		var parts = path.split('.'); var sprite = find(parts.shift());
		if (sprite == null) return;
		var key = parts.join('.');
		switch (key)
		{
			case 'x': sprite.x = value;
			case 'y': sprite.y = value;
			case 'alpha': sprite.alpha = value;
			case 'angle': sprite.angle = value;
			case 'visible': sprite.visible = value;
			case 'flipX': sprite.flipX = value;
			case 'flipY': sprite.flipY = value;
			case 'scale.x': sprite.scale.x = value;
			case 'scale.y': sprite.scale.y = value;
			case 'color': sprite.color = CoolUtil.colorFromString(Std.string(value));
			case 'downScroll': if (Std.isOfType(sprite, objects.StrumNote)) cast(sprite, objects.StrumNote).downScroll = value;
			case 'text': if (Std.isOfType(sprite, FlxText)) cast(sprite, FlxText).text = Std.string(value);
			default:
		}
	}

	public function update(time:Float):Void
	{
		resetTargets();
		for (sprite in sprites) sprite.visible = false;
		for (op in operations)
		{
			var args:Array<Dynamic> = op.args;
			var sprite = find(Std.string(args[0]));
			if (op.phase == 'start' && time < 0) continue;
			switch (op.kind)
			{
				case 'makeLuaText': if (sprite != null) { sprite.setPosition(args[3], args[4]); sprite.visible = true; cast(sprite, FlxText).text = args[1]; }
				case 'makeLuaSprite', 'makeAnimatedLuaSprite':
					if (sprite != null) { sprite.setPosition(args[2], args[3]); sprite.alpha = 1; sprite.angle = 0; sprite.visible = true; sprite.scale.set(1, 1); sprite.updateHitbox(); }
				case 'setProperty': property(args[0], args[1]);
				case 'setPropertyFromGroup': property(Std.string(args[0]) + Std.string(args[1]) + '.' + args[2], args[3]);
				case 'scaleObject': if (sprite != null) { sprite.scale.set(args[1], args[2]); sprite.updateHitbox(); }
				case 'setScrollFactor': if (sprite != null) sprite.scrollFactor.set(args[1], args[2]);
				case 'screenCenter':
					if (sprite != null) { var axes = Std.string(args[1]).toLowerCase(); if (axes.indexOf('x') != -1) sprite.x = (1280 - sprite.width) / 2; if (axes.indexOf('y') != -1) sprite.y = (720 - sprite.height) / 2; }
				case 'setBlendMode': if (sprite != null) sprite.blend = LuaUtils.blendModeFromString(args[1]);
				case 'setTextSize': if (Std.isOfType(sprite, FlxText)) cast(sprite, FlxText).size = Std.int(args[1]);
				case 'setTextColor': if (sprite != null) sprite.color = CoolUtil.colorFromString(Std.string(args[1]));
				case 'setTextAlignment': if (Std.isOfType(sprite, FlxText)) cast(sprite, FlxText).alignment = args[1];
				case 'playAnim', 'objectPlayAnimation': if (sprite != null) sprite.animation.play(args[1]);
				case 'removeLuaSprite': if (sprite != null) sprite.visible = false;
				case 'doTweenAlpha', 'doTweenX', 'doTweenY', 'doTweenAngle':
					var target = find(args[1]);
					if (target != null)
					{
						var key = switch (op.kind) { case 'doTweenAlpha': 'alpha'; case 'doTweenX': 'x'; case 'doTweenY': 'y'; default: 'angle'; };
						var start:Float = Reflect.getProperty(target, key);
						var progress = FlxMath.bound((time - (op.phase == 'start' ? 0 : -5 * Conductor.crochet)) / Math.max(1, args[3] * 1000), 0, 1);
						var ease = LuaUtils.getTweenEaseByString(args[4]);
						Reflect.setProperty(target, key, FlxMath.lerp(start, args[2], ease(progress)));
					}
				default:
			}
		}
	}
	function resetTargets():Void
	{
		for (data in defaults)
		{
			var sprite:FlxSprite = data.sprite;
			sprite.setPosition(data.x, data.y); sprite.alpha = data.alpha; sprite.angle = data.angle;
			sprite.visible = data.visible; sprite.flipX = data.flipX; sprite.flipY = data.flipY;
			sprite.scale.set(data.scaleX, data.scaleY);
			if (data.downScroll != null) cast(sprite, objects.StrumNote).downScroll = data.downScroll;
		}
	}
	public function destroy():Void
	{
		resetTargets(); defaults = [];
		for (sprite in sprites) { for (group in groups) group.remove(sprite, true); sprite.destroy(); }
		sprites.clear();
	}
}
