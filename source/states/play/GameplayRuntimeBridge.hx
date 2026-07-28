package states.play;

import debug.FPSCounter;

class GameplayRuntimeBridge
{
	public var counter(default, null):FPSCounter;

	public inline function new(counter:FPSCounter)
	{
		this.counter = counter;
	}

	public inline function sync(step:Int, beat:Int, section:Int, speed:Float, bpm:Float, health:Float, rating:String, combo:Int):Void
	{
		if (counter == null)
			return;

		counter.currentStep = step;
		counter.currentBeat = beat;
		counter.currentSection = section;
		counter.songSpeed = speed;
		counter.currentBPM = Std.int(bpm);
		counter.playerHealth = health;
		counter.lastRating = rating;
		counter.comboCount = combo;
	}
}
