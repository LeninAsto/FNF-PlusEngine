package modchart.engine.modifiers;

import flixel.FlxG;
import modchart.Manager;
import modchart.backend.core.ModifierParameters;
import modchart.backend.core.VisualParameters;
import modchart.engine.PlayField;

using StringTools;

#if !openfl_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end
class Modifier {
	private var pf:PlayField;

	public function new(pf:PlayField) {
		this.pf = pf;
	}

	public function render(curPos:Vector3, params:ModifierParameters) {
		return curPos;
	}

	public function visuals(data:VisualParameters, params:ModifierParameters):VisualParameters {
		return data;
	}

	public function shouldRun(params:ModifierParameters):Bool
		return false;

	public function allowOnStraightHolds():Bool
		return true;

	public inline function findID(name:String):Int {
		@:privateAccess return pf.modifiers.percents.__hashKey(name.toLowerCase());
	}

	public inline function getUnsafe(id:Int, player:Int)
		return @:privateAccess pf.modifiers.__getUnsafe(id, player);

	public inline function setUnsafe(id:Int, value:Float, player:Int = -1)
		return @:privateAccess pf.modifiers.__setUnsafe(id, value, player);

	public inline function setPercent(name:String, value:Float, player:Int = -1) {
		pf.setPercent(name, value, player);
	}

	public inline function getPercent(name:String, player:Int):Float {
		return pf.getPercent(name, player);
	}

	private inline function getKeyCount(player:Int = 0):Int {
		return Adapter.instance.getKeyCount();
	}

	private inline function getPlayerCount():Int {
		return Adapter.instance.getPlayerCount();
	}

	// Helpers Functions
	private inline function getScrollSpeed():Float
		return Adapter.instance.getCurrentScrollSpeed();

	public inline function getReceptorY(lane:Int, player:Int)
		return Adapter.instance.getDefaultReceptorY(lane, player);

	public inline function getReceptorX(lane:Int, player:Int)
		return Adapter.instance.getDefaultReceptorX(lane, player);

	private var WIDTH:Float = FlxG.width;
	private var HEIGHT:Float = FlxG.height;
	private var ARROW_SIZE(get, never):Float;
	private var ARROW_SIZEDIV2(get, never):Float;

	private inline function get_ARROW_SIZE():Float
		return Manager.ARROW_SIZE;

	private inline function get_ARROW_SIZEDIV2():Float
		return Manager.ARROW_SIZEDIV2;

	private inline function sin(rad:Float):Float
		return ModchartUtil.sin(rad);

	private inline function cos(rad:Float):Float
		return ModchartUtil.cos(rad);

	private inline function tan(rad:Float):Float
		return ModchartUtil.tan(rad);

	public function toString():String {
		var classn:String = Type.getClassName(Type.getClass(this));
		classn = classn.substring(classn.lastIndexOf('.') + 1);
		return 'Modifier[$classn]';
	}
}
