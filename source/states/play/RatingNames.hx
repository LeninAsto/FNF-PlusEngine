package states.play;

class RatingNames
{
	public static function list():Array<Dynamic>
	{
		var ranks:Array<Dynamic> = [
			[Language.getPhrase('rating_terrible', 'Terrible'), 0],
			[Language.getPhrase('rating_you_suck', 'You Suck!'), 0.2],
			[Language.getPhrase('rating_shit', 'Shit'), 0.4],
			[Language.getPhrase('rating_bad', 'Bad'), 0.5],
			[Language.getPhrase('rating_bruh', 'Bruh'), 0.6],
			[Language.getPhrase('rating_meh', 'Meh'), 0.69],
			[Language.getPhrase('rating_nice', 'Nice'), 0.7],
			[Language.getPhrase('rating_good', 'Good'), 0.8],
			[Language.getPhrase('rating_great', 'Great'), 0.9],
			[Language.getPhrase('rating_sick', 'Sick!'), ClientPrefs.data.useFlawlessRating ? 0.95 : 1]
		];

		if (ClientPrefs.data.useFlawlessRating)
			ranks.push([Language.getPhrase('rating_flawless', 'Flawless!!'), 1]);

		if (ClientPrefs.data.overAccuracy)
		{
			ranks.push([Language.getPhrase('rating_perfect', 'Perfect!!!'), 1.25]);
			ranks.push([Language.getPhrase('rating_marvelous', 'MARVELOUS!!!!'), 1.75]);
			ranks.push([Language.getPhrase('rating_legendary', '* LEGENDARY *'), 2.01]);
		}

		return ranks;
	}
}
