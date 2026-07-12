package modchart.engine.events.types;

import flixel.math.FlxMath;
import flixel.tweens.FlxEase.EaseFunction;
import flixel.tweens.FlxEase;

class EaseEvent extends Event {
	public var startBeat:Float;
	public var endBeat:Float;

	public var beatLength:Float;
	public var ease:EaseFunction;

	public function new(mod:String, beat:Float, len:Float, target:Float, ease:EaseFunction, player:Int, parent:EventManager) {
		this.name = mod;
		this.player = player;

		this.startBeat = beat;
		this.endBeat = beat + len;
		this.beatLength = len;
		this.ease = ease != null ? ease : FlxEase.linear;

		this.target = target;

		super(beat, (_) -> {}, parent, true);

		type = EASE;
	}

	var entryPerc:Null<Float> = null;

	override function update(curBeat:Float) {
		if (fired)
			return;

		if (curBeat < endBeat) {
			if (entryPerc == null)
				entryPerc = ModchartUtil.findEntryFrom(this);

			var progress = (curBeat - startBeat) / (endBeat - startBeat);
			// maybe we should make it use bound?
			var out = FlxMath.lerp(entryPerc, target, ease(progress));
			setModPercent(name, out, player);
			fired = false;
		} else if (curBeat >= endBeat) {
			fired = true;

			// we're using the ease function bc it may dont return 1
			setModPercent(name, ease(1) * target, player);
		}
	}
}
