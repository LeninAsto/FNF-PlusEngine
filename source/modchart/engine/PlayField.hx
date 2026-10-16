package modchart.engine;

import flixel.FlxSprite;
import flixel.math.FlxAngle;
import flixel.math.FlxPoint;
import flixel.tweens.FlxEase.EaseFunction;
import modchart.PlayfieldState;
import modchart.backend.core.ArrowData;
import modchart.backend.core.ModifierOutput;
import modchart.backend.core.TransformMode;
import modchart.backend.core.Node.NodeFunction;
import modchart.backend.math.Vector3;
import modchart.backend.graphics.*;
import modchart.backend.graphics.renderers.*;
import modchart.engine.events.types.*;
import openfl.geom.Matrix;

using flixel.util.FlxColorTransformUtil;

/**
	* Container for a modifier timeline and its rendered note field.
	*
	* Standard sprite transforms, color, alpha, blend and shader are inherited by
	* generated draw commands. Triangle clipping remains item/camera-owned because
	* a sprite clipRect cannot correctly clip perspective-projected geometry.
 */
#if !openfl_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end
final class PlayField extends FlxSprite
{
	public var context:Context;
	public var displayName:Null<String> = null;
	public var state(default, null):PlayfieldState;

	public var events:EventManager;
	public var modifiers:ModifierGroup;

	public var view(get, never):View3D;

	public var skew(default, null):FlxPoint = FlxPoint.get();

	var _skewMatrix:Matrix = new Matrix();

	function get_view()
		return context.view;

	public function new()
	{
		super();

		moves = false;
		state = new PlayfieldState();

		events = new EventManager(this);
		modifiers = new ModifierGroup(this);

		context = new Context(this);

		// default mods
		addModifier('reverse');
		addModifier('confusion');
		addModifier('stealth');
		addModifier('modSpline');
		addModifier('skew');
		addModifier('zoom');

		setPercent('arrowPathAlpha', 0, -1);
		setPercent('arrowPathThickness', 2, -1);
		setPercent('rotateHoldY', 1, -1);
		setPercent('spawnTime', 2000, -1);

		frameWidth = FlxG.width;
		frameHeight = FlxG.height;

		updateHitbox();
	}

	public inline function beginFrame(frameId:Int, songPosition:Float, beat:Float):Void
	{
		state.beginFrame(frameId, songPosition, beat);
	}

	public inline function setPercent(name:String, value:Float, player:Int = -1)
		return modifiers.setPercent(name, value, player);

	public inline function getPercent(name:String, player:Int)
		return modifiers.getPercent(name, player);

	public inline function setRawValue(name:String, value:Float, player:Int = -1)
		return modifiers.setRawValue(name, value, player);

	public inline function getRawValue(name:String, player:Int)
		return modifiers.getRawValue(name, player);

	public inline function resetModsNow(player:Int = -1):Void
	{
		events.cancelActiveModEvents(player);
		modifiers.resetPercents(player);
	}

	public inline function addModifier(name:String)
		return modifiers.addModifier(name);

	public inline function addScriptedModifier(name:String, instance:Modifier)
		return modifiers.addScriptedModifier(name, instance);

	public inline function getCachedPath(pos:Vector3, data:ArrowData, ?posDiff:Float = 0, ?allowVis:Bool = true, ?allowPos:Bool = true,
			?transformMode:Int = 15):ModifierOutput
	{
		final key = __makePathCacheKey(pos, data, posDiff, allowVis, allowPos, transformMode);
		final cached = state.getCachedPath(key);
		if (cached != null)
			return cached;

		final resolved = modifiers.getPath(pos, data, posDiff, allowVis, allowPos, transformMode);
		final cloned = state.cloneOutput(resolved);
		state.setCachedPath(key, cloned);
		return cloned;
	}

	public inline function getNotePath(pos:Vector3, data:ArrowData, ?posDiff:Float = 0, ?allowVis:Bool = true, ?allowPos:Bool = true):ModifierOutput
		return getCachedPath(pos, data, posDiff, allowVis, allowPos, TransformMode.FIELD | TransformMode.NOTE);

	public inline function getReceptorPath(pos:Vector3, data:ArrowData, ?posDiff:Float = 0, ?allowVis:Bool = true, ?allowPos:Bool = true):ModifierOutput
		return getCachedPath(pos, data, posDiff, allowVis, allowPos, TransformMode.FIELD | TransformMode.RECEPTOR);

	public inline function getFieldPath(pos:Vector3, data:ArrowData, ?posDiff:Float = 0, ?allowVis:Bool = true, ?allowPos:Bool = true):ModifierOutput
		return getCachedPath(pos, data, posDiff, allowVis, allowPos, TransformMode.FIELD);

	public inline function getSplashPath(pos:Vector3, data:ArrowData, ?posDiff:Float = 0, ?allowVis:Bool = true, ?allowPos:Bool = true):ModifierOutput
		return getCachedPath(pos, data, posDiff, allowVis, allowPos, TransformMode.FIELD | TransformMode.SPLASH);

	/** Internal allocation-free equivalents used by renderers. */
	public inline function getNotePathInto(pos:Vector3, data:ArrowData, out:ModifierOutput, outPos:Vector3, visuals:modchart.backend.core.VisualParameters,
			?posDiff:Float = 0, ?allowVis:Bool = true, ?allowPos:Bool = true):ModifierOutput
		return modifiers.getPathInto(pos, data, out, outPos, visuals, posDiff, allowVis, allowPos, TransformMode.FIELD | TransformMode.NOTE);

	public inline function getReceptorPathInto(pos:Vector3, data:ArrowData, out:ModifierOutput, outPos:Vector3, visuals:modchart.backend.core.VisualParameters,
			?posDiff:Float = 0, ?allowVis:Bool = true, ?allowPos:Bool = true):ModifierOutput
		return modifiers.getPathInto(pos, data, out, outPos, visuals, posDiff, allowVis, allowPos, TransformMode.FIELD | TransformMode.RECEPTOR);

	public inline function addEvent(event:Event)
	{
		events.add(event);
	}

	public inline function resetMods(beat:Float, player:Int = -1):Void
		callback(beat, (_) -> resetModsNow(player));

	public inline function set(name:String, beat:Float, value:Float, player:Int = -1):Void
	{
		if (player == -1)
		{
			for (curField in 0...Adapter.instance.getPlayerCount())
				set(name, beat, value, curField);
			return;
		}

		addEvent(new SetEvent(name.toLowerCase(), beat, value, player, events));
	}

	public inline function ease(name:String, beat:Float, length:Float, value:Float = 1, easeFunc:EaseFunction, player:Int = -1):Void
	{
		if (player == -1)
		{
			for (curField in 0...Adapter.instance.getPlayerCount())
				ease(name, beat, length, value, easeFunc, curField);
			return;
		}

		addEvent(new EaseEvent(name.toLowerCase(), beat, length, value, easeFunc, player, events));
	}

	public inline function add(name:String, beat:Float, length:Float, addition:Float = 1, easeFunc:EaseFunction, player:Int = -1):Void
	{
		if (player == -1)
		{
			for (curField in 0...Adapter.instance.getPlayerCount())
				add(name, beat, length, addition, easeFunc, curField);
			return;
		}

		addEvent(new AddEvent(name.toLowerCase(), beat, length, addition, easeFunc, player, events));
	}

	public inline function setAdd(name:String, beat:Float, valueToAdd:Float, player:Int = -1):Void
	{
		var addition = getPercent(name, player == -1 ? 0 : player);
		var value = addition + valueToAdd;
		if (player == -1)
		{
			for (curField in 0...Adapter.instance.getPlayerCount())
				set(name, beat, value, curField);
			return;
		}

		addEvent(new SetEvent(name.toLowerCase(), beat, value, player, events));
	}

	public inline function repeater(beat:Float, length:Float, callback:Event->Void):Void
		addEvent(new RepeaterEvent(beat, length, callback, events));

	public inline function callback(beat:Float, callback:Event->Void):Void
		addEvent(new Event(beat, callback, events));

	public inline function scheduleCallback(beat:Float, cb:Event->Void):Void
		callback(beat, cb);

	public inline function alias(name:String, alias:String)
	{
		return modifiers.addAlias(name, alias);
	}

	private var nodes:Array<Node> = [];

	/**
	 * Register a node.
	 * @param input Input Aux Mods
	 * @param output Output Mods
	 * @param func Processor function, Array<InputModPercs> -> Array<OutputModPercs>
	 */
	public inline function node(input:Array<String>, output:Array<String>, func:NodeFunction)
	{
		nodes.push({
			input: input,
			output: output,
			inputIDs: [for (name in input) modifiers.resolvePercentID(name)],
			inputValues: [for (_ in input) 0.0],
			func: func
		});
	}

	/** Updates derived modifier values after timeline events for the current frame. */
	public function updateNodes()
	{
		if (nodes.length <= 0)
			return;

		for (player in 0...Adapter.instance.getPlayerCount())
		{
			for (node in nodes)
			{
				if (node == null)
					continue;

				final entryPercs = node.inputValues;
				for (i in 0...entryPercs.length)
					entryPercs[i] = modifiers.getPercentByID(node.inputIDs[i], player);

				var outPercs = node.func(entryPercs, player);

				final nbl = node.output.length;
				if (outPercs == null)
					outPercs = [];

				for (i in 0...nbl)
				{
					final prc = i < outPercs.length ? outPercs[i] : 0;

					// Zero is a valid output and must clear the previous frame's value.
					if (!Math.isNaN(prc))
						setPercent(node.output[i], prc, player);
				}
			}
		}
	}

	override function update(elapsed:Float):Void
	{
		// Update Event Timeline
		events.update(Adapter.instance.getCurrentBeat());

		updateNodes();

		super.update(elapsed);
	}

	override public function draw()
	{
	}

	override public function destroy()
	{
		if (context != null)
			context.dispose();
		context = null;
		nodes.resize(0);
		if (skew != null)
			skew.put();
		skew = null;
		super.destroy();
	}

	private function transformCmd(cmd:DrawCommand)
	{
		var vertex = cmd.vertices;
		var vc = Std.int(vertex.length / 2);
		final identityGeometry = !flipX && !flipY && scale.x == 1 && scale.y == 1
			&& (bakedRotationAngle > 0 || angle == 0) && skew.x == 0 && skew.y == 0
			&& offset.x == 0 && offset.y == 0;

		if (!identityGeometry) {
		final matrix = this._matrix;
		matrix.identity();

		if (flipX)
		{
			matrix.scale(-1, 1);
			matrix.translate(width, 0);
		}

		if (flipY)
		{
			matrix.scale(1, -1);
			matrix.translate(0, height);
		}

		matrix.translate(-origin.x, -origin.y);
		matrix.scale(scale.x, scale.y);

		if (bakedRotationAngle <= 0)
		{
			updateTrig();
			if (angle != 0)
				matrix.rotateWithTrig(_cosAngle, _sinAngle);
		}

		updateSkewMatrix();
		_matrix.concat(_skewMatrix);

		_point.set().subtractPoint(offset);
		_point.add(origin.x, origin.y);
		matrix.translate(_point.x, _point.y);

		// if (isPixelPerfectRender(camera)) {
		// 	matrix.tx = Math.floor(matrix.tx);
		// 	matrix.ty = Math.floor(matrix.ty);
		// }

		for (c in 0...vc)
		{
			var i = c * 2;
			var x = vertex[i];
			var y = vertex[i + 1];

			vertex[i] = matrix.transformX(x, y);
			vertex[i + 1] = matrix.transformY(x, y);
		}
		}

		final identityColor = colorTransform.redMultiplier == 1 && colorTransform.greenMultiplier == 1
			&& colorTransform.blueMultiplier == 1 && colorTransform.alphaMultiplier == 1
			&& colorTransform.redOffset == 0 && colorTransform.greenOffset == 0
			&& colorTransform.blueOffset == 0 && colorTransform.alphaOffset == 0;
		if (!identityColor && cmd.color != null)
		{
			cmd.color.concat(colorTransform);
			cmd.isColored = cmd.color.hasRGBMultipliers() || cmd.color.alphaMultiplier != 1;
			cmd.hasColorOffsets = cmd.color.hasRGBAOffsets();
		}
		else if (!identityColor && cmd.colors != null)
		{
			for (transform in cmd.colors)
			{
				if (transform == null)
					continue;
				transform.concat(colorTransform);
				if (transform.hasRGBMultipliers() || transform.alphaMultiplier != 1)
					cmd.isColored = true;
				if (transform.hasRGBAOffsets())
					cmd.hasColorOffsets = true;
			}
		}

		if (blend != null)
			cmd.blend = blend;
		if (shader != null)
			cmd.shader = shader;

		return cmd;
	}

	function updateSkewMatrix():Void
	{
		_skewMatrix.identity();

		if (skew.x != 0 || skew.y != 0)
		{
			_skewMatrix.b = Math.tan(skew.y * FlxAngle.TO_RAD);
			_skewMatrix.c = Math.tan(skew.x * FlxAngle.TO_RAD);
		}
	}

	private inline function __makePathCacheKey(pos:Vector3, data:ArrowData, posDiff:Float, allowVis:Bool, allowPos:Bool, transformMode:Int):Int
	{
		var hash = 17;
		hash = __mixPathHash(hash, state.frameId);
		hash = __mixPathHash(hash, __quantizePathFloat(pos.x));
		hash = __mixPathHash(hash, __quantizePathFloat(pos.y));
		hash = __mixPathHash(hash, __quantizePathFloat(pos.z));
		hash = __mixPathHash(hash, __quantizePathFloat(data.hitTime));
		hash = __mixPathHash(hash, __quantizePathFloat(data.distance));
		hash = __mixPathHash(hash, __quantizePathFloat(data.sourceTime));
		hash = __mixPathHash(hash, data.lane);
		hash = __mixPathHash(hash, data.player);
		hash = __mixPathHash(hash, data.isTapArrow ? 1 : 0);
		hash = __mixPathHash(hash, data.straightHolds ? 1 : 0);
		hash = __mixPathHash(hash, data.isHoldBody ? 1 : 0);
		hash = __mixPathHash(hash, __quantizePathFloat(posDiff));
		hash = __mixPathHash(hash, allowVis ? 1 : 0);
		hash = __mixPathHash(hash, allowPos ? 1 : 0);
		hash = __mixPathHash(hash, Std.int(transformMode));
		return hash;
	}

	private inline function __mixPathHash(hash:Int, value:Int):Int
		return (hash * 31) ^ value;

	private inline function __quantizePathFloat(value:Float):Int
		return Std.int(value * 1000);
}

