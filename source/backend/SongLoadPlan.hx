package backend;

import backend.Song.SwagSong;
import objects.Note;
import haxe.Timer;

class PreparedChartNote
{
	public final strumTime:Float;
	public final column:Int;
	public final sustainLength:Float;
	public final noteType:String;
	public final gottaHit:Bool;
	public final gfNote:Bool;
	public final altAnim:Bool;
	public final stepCrochet:Float;
	/** Number of sub-frame taps represented by this runtime note. */
	public var density:Int;

	public function new(strumTime:Float, column:Int, sustainLength:Float, noteType:String, gottaHit:Bool, gfNote:Bool, altAnim:Bool,
		stepCrochet:Float, ?density:Int = 1)
	{
		this.strumTime = strumTime;
		this.column = column;
		this.sustainLength = sustainLength;
		this.noteType = noteType;
		this.gottaHit = gottaHit;
		this.gfNote = gfNote;
		this.altAnim = altAnim;
		this.stepCrochet = stepCrochet;
		this.density = density;
	}
}

/** Pure chart data prepared off the render thread before PlayState starts. */
class SongLoadPlan
{
	public static inline final DENSE_CHART_THRESHOLD:Int = 20000;
	public static inline final EXTREME_CHART_THRESHOLD:Int = 250000;
	public static inline final ULTRA_DENSE_CHART_THRESHOLD:Int = 1000000;
	static inline final MAX_CACHED_PLANS:Int = 3;

	public static var current(default, null):SongLoadPlan;
	static var plans:Map<String, SongLoadPlan> = [];
	static var planOrder:Array<String> = [];

	public final source:SwagSong;
	public final cacheKey:String;
	public final notes:Array<PreparedChartNote> = [];
	public var tapCount(default, null):Int = 0;
	public var sustainCount(default, null):Int = 0;
	public var compileMs(default, null):Float = 0;
	public var cacheHit(default, null):Bool = false;
	public var denseChart(default, null):Bool = false;
	public var ultraDenseChart(default, null):Bool = false;
	public var sourceNoteCount(default, null):Int = 0;

	public function new(song:SwagSong, cacheKey:String, ?columns:Int = 4)
	{
		source = song;
		this.cacheKey = cacheKey;
		var started:Float = Timer.stamp();
		var bpm:Float = Math.isFinite(song.bpm) && song.bpm > 0 ? song.bpm : 100;
		if (song.notes == null)
			return;

		for (section in song.notes)
			if (section != null && section.sectionNotes != null)
				sourceNoteCount += section.sectionNotes.length;
		denseChart = sourceNoteCount >= DENSE_CHART_THRESHOLD;
		ultraDenseChart = sourceNoteCount >= ULTRA_DENSE_CHART_THRESHOLD;
		var tapBucketMs:Float = 1000 / (ultraDenseChart ? 30 : (sourceNoteCount >= EXTREME_CHART_THRESHOLD ? 60 : 120));
		var denseTaps:Map<Int, Array<PreparedChartNote>> = denseChart ? [] : null;

		for (section in song.notes)
		{
			if (section == null)
				continue;
			if (section.changeBPM == true && section.bpm != null && section.bpm > 0)
				bpm = section.bpm;
			if (section.sectionNotes == null)
				continue;

			var stepCrochet:Float = 60 / bpm * 1000 / 4;
			for (raw in section.sectionNotes)
			{
				if (raw == null || raw.length < 3)
					continue;
				var strumTime:Float = raw[0];
				var rawColumn:Int = Std.int(raw[1]);
				if (rawColumn < 0 || !Math.isFinite(strumTime)) continue;
				var column:Int = Std.int(rawColumn % columns);
				var sustain:Float = raw[2];
				if (!Math.isFinite(sustain) || sustain < 0)
					sustain = 0;
				var type:String = Std.isOfType(raw[3], String) ? raw[3] : Note.defaultNoteTypes[raw[3]];
				if (type == null)
					type = '';
				var gottaHit:Bool = section.mustHitSection == true;
				if (rawColumn >= columns)
					gottaHit = !gottaHit;
				var gf:Bool = section.gfSection == true && gottaHit == section.mustHitSection;
				var alt:Bool = section.altAnim == true && !gottaHit;
				if (denseChart && sustain <= 0)
				{
					// Several taps in this window occupy the same screen pixel/input frame.
					// Keep one sprite and retain their gameplay weight in density.
					var bucket:Int = Math.floor(strumTime / tapBucketMs);
					var bucketNotes:Array<PreparedChartNote> = denseTaps.get(bucket);
					if (bucketNotes == null)
					{
						bucketNotes = [];
						denseTaps.set(bucket, bucketNotes);
					}
					var packed:PreparedChartNote = null;
					for (candidate in bucketNotes)
						if (candidate.column == column && candidate.gottaHit == gottaHit && candidate.gfNote == gf && candidate.altAnim == alt
							&& candidate.noteType == type)
						{
							packed = candidate;
							break;
						}
					if (packed == null)
					{
						packed = new PreparedChartNote(strumTime, column, sustain, type, gottaHit, gf, alt, stepCrochet);
						bucketNotes.push(packed);
						notes.push(packed);
					}
					else
						packed.density++;
				}
				else
					notes.push(new PreparedChartNote(strumTime, column, sustain, type, gottaHit, gf, alt, stepCrochet));
				tapCount++;
				sustainCount += Std.int(Math.max(0, Math.round(sustain / stepCrochet)));
			}
		}
		notes.sort(function(a:PreparedChartNote, b:PreparedChartNote):Int
			return a.strumTime < b.strumTime ? -1 : (a.strumTime > b.strumTime ? 1 : 0));
		compileMs = (Timer.stamp() - started) * 1000;
	}

	public static function prepare(song:SwagSong):SongLoadPlan
	{
		if (current != null && current.source == song)
		{
			current.cacheHit = true;
			SongLoadMetrics.recordPlan(current);
			return current;
		}
		if (current != null && current.ultraDenseChart)
		{
			plans.remove(current.cacheKey);
			planOrder.remove(current.cacheKey);
		}
		var key:String = makeCacheKey(song);
		var cached:SongLoadPlan = plans.get(key);
		if (cached != null && cached.source == song)
		{
			cached.cacheHit = true;
			touch(key);
			current = cached;
			SongLoadMetrics.recordPlan(current);
			return current;
		}

		current = new SongLoadPlan(song, key);
		plans.set(key, current);
		touch(key);
		while (planOrder.length > MAX_CACHED_PLANS)
			plans.remove(planOrder.shift());
		SongLoadMetrics.recordPlan(current);
		return current;
	}

	public static function get(song:SwagSong):SongLoadPlan
	{
		if (current != null && current.source == song)
			return current;
		if (current == null || current.source != song)
			return prepare(song);
		return current;
	}

	public static function clear():Void
	{
		current = null;
		plans.clear();
		planOrder.resize(0);
	}


	static function touch(key:String):Void
	{
		planOrder.remove(key);
		planOrder.push(key);
	}

	static function makeCacheKey(song:SwagSong):String
	{
		var path:String = Song.chartPath == null ? '' : Song.chartPath;
		var version:String = CompiledChartCache.sourceVersion(path);
		if (version.length > 0)
			return '$path|$version';

		var sections:Int = song.notes == null ? 0 : song.notes.length;
		var entries:Int = 0;
		if (song.notes != null)
			for (section in song.notes)
				if (section != null && section.sectionNotes != null)
					entries += section.sectionNotes.length;
		return '$path|${song.song}|${song.bpm}|$sections|$entries';
	}
}
