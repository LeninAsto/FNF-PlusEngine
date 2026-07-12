package modchart.backend.standalone.adapters.psych;

import flixel.FlxCamera;
import flixel.group.FlxGroup.FlxTypedGroup;
import objects.Note;
import objects.NoteSplash;
import objects.StrumNote;

typedef ModchartEditorPreviewData = {
	var currentBeat:Float;
	var songPosition:Float;
	var scrollSpeed:Float;
	var camera:FlxCamera;
	var strumLineNotes:FlxTypedGroup<StrumNote>;
	var opponentStrums:FlxTypedGroup<StrumNote>;
	var playerStrums:FlxTypedGroup<StrumNote>;
	var notes:FlxTypedGroup<Note>;
	var noteSplashes:FlxTypedGroup<NoteSplash>;
}

class ModchartEditorPreviewContext
{
	public static var active:ModchartEditorPreviewData = null;
}
