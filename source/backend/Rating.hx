package backend;

import backend.ClientPrefs;

class Rating
{
	public var name:String = '';
	public var image:String = '';
	public var hitWindow:Null<Float> = 0.0; //ms
	
	// NOTE: ratingMod is no longer used with the Wife3 Accuracy system
    // Wife3 calculates accuracy based on timing deviation (ms) rather than fixed values
    // This value is retained for compatibility with scripts and the old system (commented out)
	public var ratingMod:Float = 1;
	
	public var score:Int = 500;
	public var noteSplash:Bool = true;
	public var hits:Int = 0;

	public function new(name:String)
	{
		this.name = name;
		this.image = name;
		this.hitWindow = 0;

		var window:String = name + 'Window';
		try
		{
			this.hitWindow = Reflect.field(ClientPrefs.data, window);
		}
		catch(e) FlxG.log.error(e);
	}

	public static function loadDefault():Array<Rating>
	{
		var ratingsData:Array<Rating> = [new Rating('flawless')]; // flawlesss first

		var isCodenameSystem:Bool = (ClientPrefs.data.systemScoreMultiplier == 'Codename'); // Check if it the System Score Multiplier was Codename

		var rating:Rating = new Rating('sick');
		rating.ratingMod = 0.9;
		rating.score = isCodenameSystem ? 300 : 350;
		rating.noteSplash = true;
		ratingsData.push(rating);

		var rating:Rating = new Rating('good');
		rating.ratingMod = 0.67;
		rating.score = 200;
		rating.noteSplash = false;
		ratingsData.push(rating);

		var rating:Rating = new Rating('bad');
		rating.ratingMod = 0.34;
		rating.score = 100;
		rating.noteSplash = false;
		ratingsData.push(rating);

		var rating:Rating = new Rating('shit');
		rating.ratingMod = 0;
		rating.score = 50;
		rating.noteSplash = false;
		ratingsData.push(rating);

		return ratingsData;
	}
}
