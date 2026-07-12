package modchart.engine.events.types;

class RepeaterEvent extends Event {
	var end:Float;

	public function new(beat:Float, length:Float, callback:Event->Void, parent:EventManager) {
		super(beat, callback, parent);

		end = beat + length;
		type = REPEATER;
	}

	override function update(curBeat:Float):Void {
		if (fired)
			return;

		if (curBeat < end) {
			callback(this);
			fired = false;
		} else if (curBeat >= end) {
			fired = true;
		}
	}
}
