package modchart.engine.modifiers.list;

import flixel.FlxG;

class Zoom extends Modifier {
	var __curPercent:Null<Float> = -1;
	var __localPercent:Null<Float> = -1;

	override public function render(curPos:Vector3, params:ModifierParameters) {
		updatePercent(params);

		// center zoom
		if (__curPercent != 1)
			curPos = __applyZoom(curPos, new Vector3(FlxG.width * .5, FlxG.height * .5), __curPercent);
		if (__localPercent != 1)
			curPos = __applyZoom(curPos, new Vector3(getReceptorX(Math.round(getKeyCount(params.player) * .5), params.player), FlxG.height * .5),
				__localPercent);
		return curPos;
	}

	inline function __applyZoom(pos:Vector3, origin:Vector3, amount:Float) {
		var diff = pos.subtract(origin);
		diff.scaleBy(amount);
		return diff.add(origin);
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
}
