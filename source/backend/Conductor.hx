package backend;

import backend.Song;
import objects.Note;

typedef BPMChangeEvent =
{
	var stepTime:Int;
	var songTime:Float;
	var bpm:Float;
	@:optional var stepCrochet:Float;
}

class Conductor
{
	public static var bpm(default, set):Float = 100;
	public static var crochet:Float = ((60 / bpm) * 1000); // beats in milliseconds
	public static var stepCrochet:Float = crochet / 4; // steps in milliseconds
	public static var songPosition:Float = 0;
	public static var offset:Float = 0;

	// public static var safeFrames:Int = 10;
	public static var safeZoneOffset:Float = 0; // is calculated in create(), is safeFrames in milliseconds

	public static var bpmChangeMap:Array<BPMChangeEvent> = [];

	public static function judgeNote(arr:Array<Rating>, diff:Float = 0):Rating // die
	{
		if (arr == null || arr.length == 0)
			return null;

		final last:Int = arr.length - 1;
		for (i in 0...last) // skips last window (Shit)
			if (diff <= arr[i].hitWindow)
				return arr[i];

		return arr[last];
	}

	public static function getCrotchetAtTime(time:Float)
	{
		var lastChange = getBPMFromSeconds(time);
		return lastChange.stepCrochet * 4;
	}

	public static function getBPMFromSeconds(time:Float)
	{
		var lastChange:BPMChangeEvent = {
			stepTime: 0,
			songTime: 0,
			bpm: bpm,
			stepCrochet: stepCrochet
		}
		final map = Conductor.bpmChangeMap;
		final len = map.length;
		for (i in 0...len)
		{
			final evt = map[i];
			if (time >= evt.songTime)
				lastChange = evt;
			else
				break;
		}

		return lastChange;
	}

	public static function getBPMFromStep(step:Float)
	{
		var lastChange:BPMChangeEvent = {
			stepTime: 0,
			songTime: 0,
			bpm: bpm,
			stepCrochet: stepCrochet
		}
		final map = Conductor.bpmChangeMap;
		final len = map.length;
		for (i in 0...len)
		{
			final evt = map[i];
			if (evt.stepTime <= step)
				lastChange = evt;
			else
				break;
		}

		return lastChange;
	}

	public static function beatToSeconds(beat:Float):Float
	{
		var step = beat * 4;
		var lastChange = getBPMFromStep(step);
		var stepLength:Float = lastChange.stepCrochet;
		return lastChange.songTime + ((step - lastChange.stepTime) * stepLength);
	}

	public static function getStep(time:Float)
	{
		var lastChange = getBPMFromSeconds(time);
		return lastChange.stepTime + (time - lastChange.songTime) / lastChange.stepCrochet;
	}

	public static function getStepRounded(time:Float)
	{
		var lastChange = getBPMFromSeconds(time);
		return lastChange.stepTime + Math.floor((time - lastChange.songTime) / lastChange.stepCrochet);
	}

	public static function getBeat(time:Float)
	{
		return getStep(time) / 4;
	}

	public static function getBeatRounded(time:Float):Int
	{
		return Math.floor(getStepRounded(time) / 4);
	}

	public static function mapBPMChanges(song:SwagSong)
	{
		bpmChangeMap = [];

		var curBPM:Float = song.bpm;
		var totalSteps:Int = 0;
		var totalPos:Float = 0;
		for (i in 0...song.notes.length)
		{
			if (song.notes[i].changeBPM && song.notes[i].bpm != curBPM)
			{
				curBPM = song.notes[i].bpm;
				var event:BPMChangeEvent = {
					stepTime: totalSteps,
					songTime: totalPos,
					bpm: curBPM,
					stepCrochet: calculateCrochet(curBPM) / 4
				};
				bpmChangeMap.push(event);
			}

			var deltaSteps:Int = Math.round(getSectionBeats(song, i) * 4);
			totalSteps += deltaSteps;
			totalPos += ((60 / curBPM) * 1000 / 4) * deltaSteps;
		}

		// Process BPM change events.
		if (song.events != null)
		{
			for (event in song.events)
			{
				if (event != null && event.length >= 2)
				{
					var eventTime:Float = event[0];
					var eventData:Array<Dynamic> = event[1];

					if (eventData != null && eventData.length > 0)
					{
						for (subEvent in eventData)
						{
							if (subEvent != null && subEvent.length >= 2)
							{
								var eventName:String = subEvent[0];
								var eventValue:String = subEvent[1];

								if (eventName == 'Change BPM')
								{
									var newBPM:Float = Std.parseFloat(eventValue);
									if (!Math.isNaN(newBPM) && newBPM > 0)
									{
										var stepTime:Int = 0;
										var currentTime:Float = 0;
										var currentBPM:Float = song.bpm;
										var currentSteps:Int = 0;

										for (i in 0...song.notes.length)
										{
											var deltaSteps:Int = Math.round(getSectionBeats(song, i) * 4);
											var sectionDuration:Float = ((60 / currentBPM) * 1000 / 4) * deltaSteps;

											if (currentTime + sectionDuration > eventTime)
											{
												var timeInSection:Float = eventTime - currentTime;
												var stepsInSection:Int = Math.round((timeInSection / 1000) * (currentBPM / 60) * 4);
												stepTime = currentSteps + stepsInSection;
												break;
											}

											currentTime += sectionDuration;
											currentSteps += deltaSteps;

											if (song.notes[i].changeBPM && song.notes[i].bpm != currentBPM)
											{
												currentBPM = song.notes[i].bpm;
											}
										}

										var bpmEvent:BPMChangeEvent = {
											stepTime: stepTime,
											songTime: eventTime,
											bpm: newBPM,
											stepCrochet: calculateCrochet(newBPM) / 4
										};
										bpmChangeMap.push(bpmEvent);
										trace('Added BPM change from event: ' + newBPM + ' at ' + eventTime + 'ms (step ' + stepTime + ')');
									}
								}
							}
						}
					}
				}
			}

			bpmChangeMap.sort(function(a, b)
			{
				return a.songTime < b.songTime ? -1 : (a.songTime > b.songTime ? 1 : 0);
			});
		}

		trace("new BPM map BUDDY " + bpmChangeMap);
	}

	static function getSectionBeats(song:SwagSong, section:Int)
	{
		var val:Null<Float> = null;
		if (song.notes[section] != null)
			val = song.notes[section].sectionBeats;
		return val != null ? val : 4;
	}

	inline public static function calculateCrochet(bpm:Float)
	{
		return (60 / bpm) * 1000;
	}

	public static function set_bpm(newBPM:Float):Float
	{
		bpm = newBPM;
		crochet = calculateCrochet(bpm);
		stepCrochet = crochet / 4;

		return bpm = newBPM;
	}
}

