package modchart.engine.events.types;

import flixel.math.FlxMath;
import flixel.tweens.FlxEase;

class AddEvent extends EaseEvent {
	public var addAmount:Float = 0.;

	public function new(mod:String, beat:Float, len:Float, addition:Float, ease:EaseFunction, player:Int, parent:EventManager) {
		super(mod, beat, len, addAmount = addition, ease, player, parent);

		type = ADD;
	}

	override function update(curBeat:Float) {
		if (fired)
			return;

		if (curBeat < endBeat) {
			if (entryPerc == null)
				entryPerc = ModchartUtil.findEntryFrom(this);

			var progress = (curBeat - startBeat) / (endBeat - startBeat);
			// maybe we should make it use bound?
			var out = FlxMath.lerp(entryPerc, entryPerc + addAmount, ease(progress));
			setModPercent(name, out, player);
			fired = false;
		} else if (curBeat >= endBeat) {
			fired = true;

			// we're using the ease function bc it may dont return 1
			setModPercent(name, entryPerc + ease(1) * addAmount, player);
		}
	}
}
