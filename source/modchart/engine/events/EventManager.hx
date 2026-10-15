package modchart.engine.events;

import haxe.ds.StringMap;
import modchart.engine.PlayField;
import modchart.engine.events.types.*;

#if !openfl_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end
@:allow(modchart.engine.events.Event)
class EventManager {
	private var table:StringMap<Array<Array<Event>>> = new StringMap();
	private var eventList:Array<Event> = [];
	public var totalEvents(get, never):Int;
	inline function get_totalEvents():Int return eventList.length;
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
			if (entry[player] == null)
				entry[player] = [];

			final position = insertSorted(entry[player], event);
			event.prev = position > 0 ? entry[player][position - 1] : null;
			if (position + 1 < entry[player].length)
				entry[player][position + 1].prev = event;
		}

		insertSorted(eventList, event);

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

	public function hasRenderableEvents():Bool {
		for (i in 0...eventList.length) {
			final event = eventList[i];
			if (event == null)
				continue;
			if (event.name == null || event.name.toLowerCase() != 'spawntime')
				return true;
		}
		return false;
	}

	public function update(curBeat:Float) {
		if (curBeat < lastBeat)
			resetTimelineState();
		lastBeat = curBeat;

		while (nextEventIndex < eventList.length) {
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

	public function cancelActiveModEvents(player:Int = -1):Void {
		for (event in activeEvents) {
			if (event == null || event.name == null)
				continue;
			if (player != -1 && event.player != player)
				continue;

			event.active = false;
			event.fired = true;
			event.callback = null;
		}
	}

	private function insertSorted(vec:Array<Event>, event:Event):Int {
		var low = 0;
		var high = vec.length;
		while (low < high) {
			final mid = (low + high) >> 1;
			if (cmpBeat(event, vec[mid]) < 0)
				high = mid;
			else
				low = mid + 1;
		}
		vec.insert(low, event);
		return low;
	}

	private inline function cmpBeat(a:Event, b:Event):Int {
		return a.beat < b.beat ? -1 : (a.beat > b.beat ? 1 : 0);
	}

	private function getNextEventIndex(curBeat:Float):Int {
		var index = 0;
		while (index < eventList.length) {
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
		for (i in 0...eventList.length) {
			var ev = eventList[i];
			if (ev == null)
				continue;
			ev.reset();
		}
	}
}
