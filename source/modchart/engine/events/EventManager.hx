package modchart.engine.events;

import haxe.ds.StringMap;
import haxe.ds.Vector;
import modchart.backend.util.ModchartUtil;
import modchart.engine.PlayField;
import modchart.engine.events.types.*;

#if !openfl_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end
@:allow(modchart.engine.events.Event)
class EventManager {
	private var table:StringMap<Array<Vector<Event>>> = new StringMap();
	private var eventList:Vector<Event> = new Vector<Event>(256);
	private var eventCount:Int = 0;
	public var totalEvents(get, never):Int;
	inline function get_totalEvents():Int return eventCount;
	private var activeEvents:Array<Event> = [];
	private var nextEventIndex:Int = 0;
	private var lastBeat:Float = Math.NEGATIVE_INFINITY;

	private var pf:PlayField;

	public function new(pf:PlayField) {
		this.pf = pf;
	}

	public function add(event:Event) {
		if (event.name != null) {
			final lwr = event.name.toLowerCase();
			var player = event.player;

			var entry = table.get(lwr);
			if (entry == null) {
				entry = [];
				table.set(lwr, entry);
			}
			if (entry[player] == null) {
				entry[player] = new Vector<Event>(256);
				event.prev = null;
			} else {
				var len = getVectorLength(entry[player]);
				if (len > 0)
					event.prev = entry[player][len - 1];
			}
			insertSorted(entry[player], event);
		}

		insertSorted(eventList, event, true);
		eventCount++;

		if (lastBeat != Math.NEGATIVE_INFINITY && event.beat <= lastBeat && !event.fired)
		{
			if (!event.active)
			{
				event.active = true;
				activeEvents.push(event);
			}
			nextEventIndex = getNextEventIndex(lastBeat);
		}
	}

	public function update(curBeat:Float) {
		if (curBeat < lastBeat)
			resetTimelineState();
		lastBeat = curBeat;

		while (nextEventIndex < eventCount) {
			var ev = eventList[nextEventIndex];
			if (ev == null || ev.beat > curBeat)
				break;
			ev.active = true;
			activeEvents.push(ev);
			nextEventIndex++;
		}

		var index = 0;
		while (index < activeEvents.length) {
			var ev = activeEvents[index];
			if (ev == null || ev.fired) {
				if (ev != null)
					ev.active = false;
				activeEvents.splice(index, 1);
				continue;
			}

			ev.active = true;
			ev.update(curBeat);
			if (ev.fired) {
				ev.active = false;
				activeEvents.splice(index, 1);
			} else {
				index++;
			}
		}
	}

	public function getLastEventBefore(event:Event):Event {
		return event.prev;
	}

	public inline function setModPercent(name:String, value:Float, player:Int):Void {
		pf.setPercent(name, value, player);
	}

	public inline function getModPercent(name:String, player:Int):Float {
		return pf.getPercent(name, player);
	}

	private function insertSorted(vec:Vector<Event>, event:Event, resize:Bool = false) {
		var len = getVectorLength(vec);
		if (len >= vec.length) {
			if (!resize)
				return;
			var newVec = new Vector<Event>(vec.length + 64);

			Vector.blit(vec, 0, newVec, 0, vec.length);
			vec = newVec;
			// only applies to main list
			eventList = vec;
		}

		// insert already sorted
		var pos = len;
		while (pos > 0 && cmpBeat(event, vec[pos - 1]) < 0) {
			vec[pos] = vec[pos - 1];
			pos--;
		}
		vec[pos] = event;
	}

	private inline function cmpBeat(a:Event, b:Event):Int {
		return a.beat < b.beat ? -1 : (a.beat > b.beat ? 1 : 0);
	}

	private inline function getVectorLength(vec:Vector<Event>):Int {
		var len = vec.length;
		for (i in 0...len) {
			if (vec[i] == null) {
				len = i;
				break;
			}
		}
		return len;
	}

	private function getNextEventIndex(curBeat:Float):Int {
		var index = 0;
		while (index < eventCount) {
			var ev = eventList[index];
			if (ev == null || ev.beat > curBeat)
				break;
			index++;
		}
		return index;
	}

	private function resetTimelineState():Void {
		nextEventIndex = 0;
		activeEvents.resize(0);
		for (i in 0...eventCount) {
			var ev = eventList[i];
			if (ev == null)
				continue;
			ev.active = false;
			ev.fired = false;
		}
	}
}
