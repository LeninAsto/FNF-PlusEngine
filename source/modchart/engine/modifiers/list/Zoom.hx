package modchart.engine.modifiers.list;

import flixel.FlxG;
import modchart.backend.core.TransformMode;

class Zoom extends Modifier {
	var __curPercent:Null<Float> = -1;
	var __localPercent:Null<Float> = -1;

	override public function render(curPos:Vector3, params:ModifierParameters) {
		updatePercent(params);

		// center zoom
		if (__curPercent != 1)
			__applyZoom(curPos, FlxG.width * .5, FlxG.height * .5, __curPercent);
		if (__localPercent != 1)
			__applyZoom(curPos, getReceptorX(Math.round(getKeyCount(params.player) * .5), params.player), FlxG.height * .5, __localPercent);
		return curPos;
	}

	inline function __applyZoom(pos:Vector3, originX:Float, originY:Float, amount:Float):Void {
		pos.x = (pos.x - originX) * amount + originX;
		pos.y = (pos.y - originY) * amount + originY;
		pos.z *= amount;
	}

	override public function visuals(data:VisualParameters, params:ModifierParameters):VisualParameters {
		if (__curPercent == null)
			updatePercent(params);

		data.scaleX = data.scaleX * (__curPercent * __localPercent);
		data.scaleY = data.scaleY * (__curPercent * __localPercent);

		__curPercent = __localPercent = null;

		return data;
	}

	inline function updatePercent(params:ModifierParameters) {
		__curPercent = 1 + ((-getPercent('zoom', params.player) + getPercent('mini', params.player)) * 0.5);
		__localPercent = 1 + ((-getPercent('localZoom', params.player) + getPercent('localMini', params.player)) * 0.5);
	}

	override public function shouldRun(params:ModifierParameters):Bool
		return true;

	override public function isActive(player:Int):Bool
		return getPercent('zoom', player) != 0 || getPercent('mini', player) != 0
			|| getPercent('localZoom', player) != 0 || getPercent('localMini', player) != 0;

	override public function transformMode():TransformMode
		return TransformMode.FIELD;
}
