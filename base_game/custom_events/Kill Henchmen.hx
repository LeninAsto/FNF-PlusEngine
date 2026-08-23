/**
	Fires "Kill Henchmen" 280ms early so the kill sound lands on the beat it was charted against.

	This offset was hardcoded in `PlayState.eventEarlyTrigger`, which meant the engine carried one
	base-game event's timing for every chart ever made. An event's own script is the right place for
	it: `custom_events/<name>.hx` is loaded whenever a chart contains that event.
**/
function eventEarlyTrigger(name:String, value1:String, value2:String, strumTime:Float) {
	if (name == 'Kill Henchmen')
		return 280;
	return 0;
}
