package backend;

import openfl.utils.AssetType;
import backend.Song.SwagSong;
import backend.Song.SwagSection;

enum abstract SongCheckSeverity(Int) from Int to Int
{
	var INFO = 0;
	var WARNING = 1;
	var ERROR = 2;
}

class SongCheckIssue
{
	public final severity:SongCheckSeverity;
	public final code:String;
	public final message:String;
	public final path:Null<String>;

	public function new(severity:SongCheckSeverity, code:String, message:String, ?path:String)
	{
		this.severity = severity;
		this.code = code;
		this.message = message;
		this.path = path;
	}
}

class SongCheckReport
{
	public final chartName:String;
	public final songFolder:String;
	public var chartPath:Null<String>;
	public final issues:Array<SongCheckIssue> = [];

	public var hasErrors(get, never):Bool;
	public var warningCount(get, never):Int;

	public function new(chartName:String, songFolder:String)
	{
		this.chartName = chartName;
		this.songFolder = songFolder;
	}

	function get_hasErrors():Bool
	{
		for (issue in issues)
			if (issue.severity == ERROR)
				return true;
		return false;
	}

	function get_warningCount():Int
	{
		var count:Int = 0;
		for (issue in issues)
			if (issue.severity == WARNING)
				count++;
		return count;
	}

	public function add(severity:SongCheckSeverity, code:String, message:String, ?path:String):Void
		issues.push(new SongCheckIssue(severity, code, message, path));

	public function displayText(?limit:Int = 10):String
	{
		var lines:Array<String> = ['SONG CHECKER'];
		var shown:Int = 0;
		for (issue in issues)
		{
			if (shown >= limit)
				break;
			var prefix:String = issue.severity == ERROR ? '[ERROR]' : issue.severity == WARNING ? '[WARN]' : '[FIX]';
			lines.push('$prefix ${issue.message}');
			if (issue.path != null && issue.path.length > 0)
				lines.push('  ${issue.path}');
			shown++;
		}
		if (issues.length > shown)
			lines.push('...and ${issues.length - shown} more.');
		return lines.join('\n');
	}
}

/**
 * Lightweight Psych-compatible preflight. It blocks only data that would
 * crash PlayState; recoverable omissions remain warnings or safe repairs.
 */
class SongChecker
{
	public static function inspectRequest(chartName:String, songFolder:String):SongCheckReport
	{
		var report = new SongCheckReport(chartName, songFolder);
		report.chartPath = Song.resolveChartPath(chartName, songFolder);
		if (report.chartPath == null)
			report.add(ERROR, 'missing-chart', 'Chart not found for this difficulty.', Song.expectedChartPath(chartName, songFolder));
		return report;
	}

	public static function inspectSong(report:SongCheckReport, song:SwagSong):SongCheckReport
	{
		if (song == null)
		{
			report.add(ERROR, 'invalid-chart', 'The chart exists but could not be parsed.', report.chartPath);
			return report;
		}

		if (song.song == null || song.song.trim().length == 0)
		{
			song.song = report.songFolder;
			report.add(INFO, 'repaired-song-name', 'Missing song name was restored from its folder.');
		}
		if (song.notes == null)
			report.add(ERROR, 'missing-notes', 'Chart has no notes array.', report.chartPath);
		else
			validateSections(report, song.notes);

		if (song.events == null)
		{
			song.events = [];
			report.add(INFO, 'repaired-events', 'Missing events array was replaced with an empty one.');
		}
		if (Math.isNaN(song.bpm) || song.bpm <= 0)
			report.add(ERROR, 'invalid-bpm', 'BPM must be greater than zero.', report.chartPath);
		if (Math.isNaN(song.speed) || song.speed <= 0)
		{
			song.speed = 1;
			report.add(INFO, 'repaired-speed', 'Invalid scroll speed was restored to 1.');
		}

		if (song.gfVersion == null || song.gfVersion.trim().length == 0)
		{
			song.gfVersion = 'gf';
			report.add(INFO, 'repaired-gf', 'Missing girlfriend character was restored to "gf".');
		}

		var audioFolder:String = Paths.formatToSongPath(song.song);
		var inst:String = '$audioFolder/Inst.${Paths.SOUND_EXT}';
		if (!Paths.fileExists(inst, AssetType.SOUND, false, 'songs'))
			report.add(ERROR, 'missing-inst', 'Instrumental audio is missing.', inst);

		if (song.needsVoices)
		{
			var voices:String = '$audioFolder/Voices.${Paths.SOUND_EXT}';
			var playerVoices:String = '$audioFolder/Voices-Player.${Paths.SOUND_EXT}';
			var opponentVoices:String = '$audioFolder/Voices-Opponent.${Paths.SOUND_EXT}';
			var hasVoices:Bool = Paths.fileExists(voices, AssetType.SOUND, false, 'songs') ||
				(Paths.fileExists(playerVoices, AssetType.SOUND, false, 'songs') && Paths.fileExists(opponentVoices, AssetType.SOUND, false, 'songs'));
			if (!hasVoices)
				report.add(WARNING, 'missing-voices', 'Voices are enabled, but no default or split vocal files were found.', voices);
		}

		return report;
	}

	static function validateSections(report:SongCheckReport, sections:Array<SwagSection>):Void
	{
		for (sectionIndex in 0...sections.length)
		{
			var section:SwagSection = sections[sectionIndex];
			if (section == null || section.sectionNotes == null)
			{
				report.add(ERROR, 'invalid-section', 'Section $sectionIndex has no note list.', report.chartPath);
				continue;
			}

			for (noteIndex in 0...section.sectionNotes.length)
			{
				var note:Dynamic = section.sectionNotes[noteIndex];
				if (!Std.isOfType(note, Array) || (cast note:Array<Dynamic>).length < 3)
				{
					report.add(ERROR, 'invalid-note', 'Malformed note at section $sectionIndex, index $noteIndex.', report.chartPath);
					continue;
				}
				var values:Array<Dynamic> = cast note;
				if (!isNumber(values[0]) || !isNumber(values[1]) || !isNumber(values[2]))
					report.add(ERROR, 'invalid-note-values', 'Non-numeric note data at section $sectionIndex, index $noteIndex.', report.chartPath);
			}
		}
	}

	static inline function isNumber(value:Dynamic):Bool
		return Std.isOfType(value, Int) || Std.isOfType(value, Float);
}
