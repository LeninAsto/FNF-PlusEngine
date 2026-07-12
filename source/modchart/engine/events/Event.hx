package modchart.engine.events;

import modchart.engine.events.EventType;

class Event {
	public var name:String;
	public var target:Float;

	public var type:EventType = EMPTY;

	public var beat:Float;
	public var player:Int;

	public var prev:Event = null;

	public var callback:Event->Void;
	public var parent:EventManager;

	private var mercy:Bool = false;

	public var fired:Bool = false;

	public var active:Bool = false;

	public function new(beat:Float, callback:Event->Void, parent:EventManager, ?mercy:Bool = false) {
		this.beat = beat;
		this.callback = callback;
		this.mercy = mercy;

		this.parent = parent;
	}

	public function update(curBeat:Float) {
		if (curBeat >= beat && callback != null) {
			callback(this);

			fired = !mercy;

			if (fired)
				callback = null;
		}
	}

	public function create() {}

	public inline function setModPercent(name, value, player) {
		parent.setModPercent(name, value, player);
	}

	public inline function getModPercent(name, player):Float {
		return parent.getModPercent(name, player);
	}

	inline public function getType():EventType {
		return type;
	}
}
