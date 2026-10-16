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

	public function new(strumTime:Float, column:Int, sustainLength:Float, noteType:String, gottaHit:Bool, gfNote:Bool, altAnim:Bool,
		stepCrochet:Float)
	{
		this.strumTime = strumTime;
		this.column = column;
		this.sustainLength = sustainLength;
		this.noteType = noteType;
		this.gottaHit = gottaHit;
		this.gfNote = gfNote;
		this.altAnim = altAnim;
		this.stepCrochet = stepCrochet;
	}
}

/** Pure chart data prepared off the render thread before PlayState starts. */
class SongLoadPlan
{
	public static var current(default, null):SongLoadPlan;
	static var plans:Map<String, SongLoadPlan> = [];

	public final source:SwagSong;
	public final cacheKey:String;
	public final notes:Array<PreparedChartNote> = [];
	public var tapCount(default, null):Int = 0;
	public var sustainCount(default, null):Int = 0;
	public var compileMs(default, null):Float = 0;
	public var cacheHit(default, null):Bool = false;

	public function new(song:SwagSong, cacheKey:String, ?columns:Int = 4)
	{
		source = song;
		this.cacheKey = cacheKey;
		var started:Float = Timer.stamp();
		var bpm:Float = song.bpm;
		if (song.notes == null)
			return;

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
				var column:Int = Std.int(rawColumn % columns);
				var sustain:Float = raw[2];
				if (Math.isNaN(sustain))
					sustain = 0;
				var type:String = Std.isOfType(raw[3], String) ? raw[3] : Note.defaultNoteTypes[raw[3]];
				if (type == null)
					type = '';
				var gottaHit:Bool = rawColumn < columns;
				var gf:Bool = section.gfSection == true && gottaHit == section.mustHitSection;
				var alt:Bool = section.altAnim == true && !gottaHit;
				notes.push(new PreparedChartNote(strumTime, column, sustain, type, gottaHit, gf, alt, stepCrochet));
				tapCount++;
				sustainCount += Std.int(Math.max(0, Math.round(sustain / stepCrochet)));
			}
		}
		compileMs = (Timer.stamp() - started) * 1000;
	}

	public static function prepare(song:SwagSong):SongLoadPlan
	{
		var key:String = makeCacheKey(song);
		var cached:SongLoadPlan = plans.get(key);
		if (cached != null)
		{
			cached.cacheHit = true;
			current = cached;
			SongLoadMetrics.recordPlan(current);
			return current;
		}

		current = new SongLoadPlan(song, key);
		plans.set(key, current);
		SongLoadMetrics.recordPlan(current);
		return current;
	}

	public static function get(song:SwagSong):SongLoadPlan
	{
		if (current == null || current.cacheKey != makeCacheKey(song))
			return prepare(song);
		return current;
	}

	public static function clear():Void
	{
		current = null;
		plans.clear();
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
