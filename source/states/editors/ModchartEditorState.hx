package states.editors;

import backend.Song;
import backend.StageData;
import objects.Character;
import objects.Note;
import objects.NoteSplash;
import objects.StrumNote;
import modchart.Manager;
import modchart.backend.standalone.adapters.psych.ModchartEditorPreviewContext;
import states.editors.content.ChartEditorTiming;
import states.editors.content.ModchartTimeline;
import states.editors.content.ModchartTimeline.ModchartTimelineEvent;
import states.editors.content.ModchartLuaImporter;
import states.editors.content.ModchartScenePreview;
import lime.system.Clipboard;
import openfl.net.FileReference;
import openfl.net.FileFilter;
import openfl.events.Event;

private typedef PreviewNoteData = {
 var strumTime:Float;
 var lane:Int;
 var mustPress:Bool;
 var sustain:Float;
 var step:Float;
 var head:Int;
 var end:Bool;
}

/** Stage preview and beat timeline backed by the gameplay modchart renderer. */
class ModchartEditorState extends MusicBeatState
{
	var timeline = new ModchartTimeline();
	var manager:Manager;
	var song:SwagSong;
	var previewCamera:FlxCamera;
	var stageCamera:FlxCamera;
	var uiCamera:FlxCamera;
	var stageGroup = new FlxTypedGroup<FlxSprite>();
	var luaFront = new FlxTypedGroup<FlxSprite>();
	var luaHUD = new FlxTypedGroup<FlxSprite>();
	var luaScene:ModchartScenePreview;
	var countdown = new FlxTypedGroup<FlxSprite>();
	var countdownText:FlxText;
	var countdownBeat:Int = -100;
	var receptors = new FlxTypedGroup<StrumNote>();
	var opponent = new FlxTypedGroup<StrumNote>();
	var player = new FlxTypedGroup<StrumNote>();
	var notes = new FlxTypedGroup<Note>();
	var splashes = new FlxTypedGroup<NoteSplash>();
	var allNotes:Array<PreviewNoteData> = [];
	var liveHeads:Map<Int, Note> = [];
	var nextNote:Int = 0;
	var characters:Array<Character> = [];
	var inst:FlxSound;
	var position:Float = 0;
	var duration:Float = 60000;
	var playing:Bool = false;
	var selected:ModchartTimelineEvent;
	var dirty:Bool = false;
	var viewBeat:Float = -5;
	var pixelsPerBeat:Float = 36;
	var rowOffset:Int = 0;
	var rows:Array<String> = [];
	var timelineGroup = new FlxTypedGroup<FlxSprite>();
	var playhead:FlxSprite;
	var playheadHandle:FlxSprite;
	var scrollTrack:FlxSprite;
	var scrollThumb:FlxSprite;
	var rowScrollTrack:FlxSprite;
	var rowScrollThumb:FlxSprite;
	var panning:Bool = false;
	var panOffset:Float = 0;
	var rowPanning:Bool = false;
	var rowPanOffset:Float = 0;
	var seekInput:PsychUIInputText;
	var zoomText:FlxText;
	var status:FlxText;
	var clock:FlxText;
	var songInput:PsychUIInputText;
	var modInput:PsychUIInputText;
	var kindInput:PsychUIInputText;
	var beatInput:PsychUIInputText;
	var lengthInput:PsychUIInputText;
	var valueInput:PsychUIInputText;
	var easeInput:PsychUIInputText;
	var playerInput:PsychUIInputText;
	var fieldInput:PsychUIInputText;
	var file:FileReference;
	var dragging:ModchartTimelineEvent;
	var dragStart:Float;
	var dragBeat:Float;
	var scrubbing:Bool = false;
	var exitPending:Bool = false;
	var lastDance:Int = -1;
	static inline var GRID_X:Int = 160;
	static inline var GRID_Y:Int = 544;
	static inline var GRID_W:Int = 1090;
	static inline var ROW_H:Int = 25;
	static inline var VISIBLE_ROWS:Int = 4;
	static inline var GRID_H:Int = 24 + VISIBLE_ROWS * ROW_H;
	static inline var SCROLL_Y:Int = GRID_Y + GRID_H + 5;
	static inline var ROW_SCROLL_X:Int = GRID_X + GRID_W + 6;
	static inline var ROW_SCROLL_Y:Int = GRID_Y + 24;
	static inline var ROW_SCROLL_H:Int = VISIBLE_ROWS * ROW_H;

	override function create():Void
	{
		uiCamera = initPsychCamera();
		uiCamera.bgColor = 0xFF111722;
		stageCamera = new FlxCamera(16, 62, 1280, 720, 0.62);
		stageCamera.bgColor = 0xFF202738;
		previewCamera = new FlxCamera(16, 62, 1280, 720, 0.62);
		previewCamera.bgColor.alpha = 0;
		FlxG.cameras.add(stageCamera, false);
		FlxG.cameras.add(previewCamera, false);
		// UI remains above both preview cameras, with a transparent preview cutout.
		FlxG.cameras.remove(uiCamera, false);
		FlxG.cameras.add(uiCamera, true);
		uiCamera.bgColor.alpha = 0;
		add(new FlxSprite().makeGraphic(FlxG.width, 60, 0xFF111722));
		add(new FlxSprite(820, 60).makeGraphic(460, 460, 0xFF111722));
		add(new FlxSprite(0, 510).makeGraphic(1280, 210, 0xFF111722));
		stageGroup.cameras = [stageCamera]; add(stageGroup);
		luaFront.cameras = [stageCamera]; add(luaFront);
		luaHUD.cameras = [previewCamera]; add(luaHUD);
		receptors.cameras = [previewCamera]; add(receptors);
		notes.cameras = [previewCamera]; add(notes);
		splashes.cameras = [previewCamera]; add(splashes);
		countdown.cameras = [previewCamera]; add(countdown);
		countdownText = new FlxText(0, 275, 1280, '', 80);
		countdownText.alignment = CENTER; countdownText.cameras = [previewCamera]; add(countdownText);
		add(timelineGroup);
		buildUI();
		playhead = new FlxSprite(GRID_X, GRID_Y).makeGraphic(2, GRID_H, 0xFFFFD166); add(playhead);
		playheadHandle = new FlxSprite(GRID_X - 5, GRID_Y - 1).makeGraphic(12, 12, 0xFFFFD166); add(playheadHandle);
		scrollTrack = new FlxSprite(GRID_X, SCROLL_Y).makeGraphic(GRID_W, 16, 0xFF293449); add(scrollTrack);
		scrollThumb = new FlxSprite(GRID_X, SCROLL_Y + 2).makeGraphic(1, 12, 0xFF7AA2F7); add(scrollThumb);
		rowScrollTrack = new FlxSprite(ROW_SCROLL_X, ROW_SCROLL_Y).makeGraphic(14, ROW_SCROLL_H, 0xFF293449); add(rowScrollTrack);
		rowScrollThumb = new FlxSprite(ROW_SCROLL_X + 2, ROW_SCROLL_Y).makeGraphic(10, 1, 0xFF7AA2F7); add(rowScrollThumb);
		FlxG.mouse.visible = true;
		if (FlxG.sound.music != null) FlxG.sound.music.stop();
		super.create();
		if (PlayState.SONG == null)
		{
			try { PlayState.SONG = Song.loadFromJson('tutorial', 'tutorial'); }
			catch (_:Dynamic) {}
		}
		if (PlayState.SONG != null) loadSong(PlayState.SONG);
		else message(tr('load_first', "Load a chart JSON to get started."));
	}

	static inline function tr(key:String, fallback:String, ?values:Array<Dynamic>):String
		return Language.getPhrase('editors.modchart.' + key, fallback, values);

	function label(x:Float, y:Float, text:String, size:Int = 14, width:Int = 410):FlxText
	{
		var result = new FlxText(x, y, width, text, size);
		result.setFormat(Paths.font('vcr.ttf'), size, FlxColor.WHITE);
		add(result); return result;
	}
	function button(x:Float, y:Float, text:String, action:Void->Void, width:Int = 104):Void
		add(new PsychUIButton(x, y, text, action, width, 24));
	function input(x:Float, y:Float, title:String, value:String, width:Int = 178):PsychUIInputText
	{
		label(x, y, title, 13, width);
		var result = new PsychUIInputText(x, y + 19, width, value, 15); add(result); return result;
	}
	function buildUI():Void
	{
		label(16, 9, tr('title', "MODCHART EDITOR"), 24, 290);
		button(320, 12, tr('play_pause', "Play / Pause"), togglePlayback, 120);
		button(450, 12, tr('start', "|< Start"), () -> seekBeat(-5));
		button(564, 12, tr('open_chart', "Open chart"), openChart);
		button(678, 12, tr('open_project', "Project"), openProject);
		button(792, 12, tr('save', "Save"), saveProject);
		button(906, 12, tr('import_lua', "Import Lua"), importLua, 112);
		button(1028, 12, tr('export_lua', "Export Lua"), exportLua, 112);
		button(1150, 12, tr('exit', "Exit"), leave, 95);
		clock = label(16, 39, '', 15, 285);
		var experimentalWarning = label(310, 42,
			tr('experimental_warning', 'EXPERIMENTAL: subject to changes and bugs; not classified as stable or unstable yet.'), 11, 930);
		experimentalWarning.color = 0xFFFFC857;
		songInput = input(840, 62, tr('song', "Song (current chart by default)"), '', 300);
		button(1150, 82, tr('load', "Load"), loadSongByName, 90);
		modInput = input(840, 116, tr('modifier', "Modifier"), 'drunk');
		kindInput = input(1040, 116, tr('kind', "Type: set / ease / add"), 'ease', 200);
		beatInput = input(840, 172, tr('beat', "Beat"), '0');
		lengthInput = input(1040, 172, tr('length', "Duration in beats"), '4', 200);
		valueInput = input(840, 228, tr('value', "Value"), '1');
		easeInput = input(1040, 228, tr('easing', "Easing"), 'sineInOut', 200);
		playerInput = input(840, 284, tr('player', "Player: -1 both, 0 opponent, 1 BF"), '-1');
		fieldInput = input(1040, 284, tr('field', "Playfield (-1 all)"), '-1', 200);
		button(840, 343, tr('new', "New"), () -> applyEvent(false));
		button(954, 343, tr('apply', "Apply"), () -> applyEvent(true));
		button(1068, 343, tr('duplicate', "Duplicate"), duplicate);
		button(1182, 343, tr('delete', "Delete"), deleteEvent, 65);
		button(840, 380, tr('paste_lua', "Paste Lua"), () -> importText(Clipboard.text), 120);
		button(970, 380, tr('copy_lua', "Copy Lua"), () -> { Clipboard.text = timeline.toLua(); message(tr('copied', "Lua copied.")); }, 120);
		status = label(840, 415, tr('ready', "Ready"), 14, 400);
		status.autoSize = false; status.fieldHeight = 42;
		seekInput = input(840, 461, tr('seek_beat', 'Seek to beat'), '-5', 106);
		button(958, 481, tr('go', 'Go'), () -> {
			var beat = Std.parseFloat(seekInput.text);
			if (Math.isFinite(beat)) { PsychUIInputText.focusOn = null; seekBeat(beat); }
		}, 55);
		button(1023, 481, tr('back', '<< Back'), () -> stepTime(-4), 100);
		button(1133, 481, tr('forward', 'Forward >>'), () -> stepTime(4), 110);
		label(16, 514, tr('timeline', "TIMELINE"), 17, 140);
		label(160, 514, tr('help', "Space: play | Arrows: seek | Shift: 4 beats | Wheel: pan | Ctrl+wheel: zoom | Drag: move event"), 12, 760);
		button(930, 513, tr('zoom_out', "Zoom -"), () -> zoomTimeline(1 / 1.2), 72);
		zoomText = label(1007, 516, '', 12, 68);
		zoomText.alignment = CENTER;
		button(1080, 513, tr('zoom_in', "Zoom +"), () -> zoomTimeline(1.2), 72);
		button(1157, 513, tr('zoom_reset', "Reset"), () -> setTimelineZoom(36), 88);
		label(16, 699, tr('footer', "Drag playhead: seek | Scrollbar: pan | Right click: add | Alt+wheel: rows | Ctrl+S: save | Esc: exit"), 12, 1240);
	}

	function loadSongByName():Void
	{
		try { var name = Paths.formatToSongPath(songInput.text.trim()); loadSong(Song.loadFromJson(name, name)); }
		catch (error:Dynamic) message(tr('load_error', "Could not load: {1}", [error]));
	}
	function loadSong(data:SwagSong):Void
	{
		if (data == null) throw tr('invalid_chart', "Invalid or missing chart");
		playing = false;
		if (inst != null) { FlxG.sound.list.remove(inst); inst.destroy(); inst = null; }
		song = ChartEditorTiming.ensureSongBasics(data);
		PlayState.SONG = song;
		ChartEditorTiming.syncConductor(song);
		songInput.text = song.song;
		var stage = StageData.getStageFile(song.stage);
		PlayState.stageUI = stage.stageUI == null || stage.stageUI.length == 0 ? (stage.isPixelStage == true ? 'pixel' : 'normal') : stage.stageUI;
		buildStage();
		buildNotes();
		try { inst = new FlxSound().loadEmbedded(Paths.inst(song.song)); FlxG.sound.list.add(inst); }
		catch (error:Dynamic) message(tr('audio_error', "Preview without audio: {1}", [error]));
		duration = inst != null && inst.length > 0 ? inst.length : 60000;
		if (allNotes.length > 0) duration = Math.max(duration, allNotes[allNotes.length - 1].strumTime + 3000);
		ModchartEditorPreviewContext.active = {currentBeat: 0, songPosition: 0, scrollSpeed: song.speed * 0.45,
			camera: previewCamera, strumLineNotes: receptors, opponentStrums: opponent, playerStrums: player, notes: notes, noteSplashes: splashes, renderer: timeline.renderer};
		buildLuaStage(); buildCountdown(); viewBeat = -5;
		seek(Conductor.beatToSeconds(-5));
		message(tr('chart_loaded', "Chart: {1}. Import Lua or create events.", [song.song]));
	}

	function buildStage():Void
	{
		if (luaScene != null) { luaScene.destroy(); luaScene = null; }
		for (item in stageGroup.members) if (item != null) item.destroy();
		stageGroup.clear(); characters = [];
		var data = StageData.getStageFile(song.stage);
		Paths.setCurrentLevel(data.directory == null || data.directory.length == 0 ? 'shared' : data.directory);
		var gf = new Character(data.girlfriend[0], data.girlfriend[1], song.gfVersion == null ? 'gf' : song.gfVersion);
		var dad = new Character(data.opponent[0], data.opponent[1], song.player2);
		var bf = new Character(data.boyfriend[0], data.boyfriend[1], song.player1, true);
		characters = [gf, dad, bf];
		for (character in characters) { character.x += character.positionArray[0]; character.y += character.positionArray[1]; }
		gf.visible = !data.hide_girlfriend;
		if (data.objects == null || data.objects.length == 0)
		{
			// Classic stages use Haxe instead of JSON objects. Provide the familiar
			// stage as a preview backdrop without running gameplay stage scripts.
			for (asset in [
				{image: 'stageback', x: -600, y: -200, scale: 1.0},
				{image: 'stagefront', x: -650, y: 600, scale: 1.1}])
			{
				if (!Paths.fileExists('images/' + asset.image + '.png', IMAGE)) continue;
				var sprite = new FlxSprite(asset.x, asset.y).loadGraphic(Paths.image(asset.image));
				sprite.scrollFactor.set(0.9, 0.9); sprite.scale.set(asset.scale, asset.scale);
				sprite.updateHitbox(); sprite.antialiasing = ClientPrefs.data.antialiasing;
				stageGroup.add(sprite);
			}
		}
		var loaded = StageData.addObjectsToState(data.objects == null ? [] : data.objects, gf, dad, bf, stageGroup);
		for (i => name in ['gf', 'dad', 'boyfriend']) if (!loaded.exists(name)) stageGroup.add(characters[i]);
		stageGroup.cameras = [stageCamera];
		stageCamera.zoom = 0.62 * data.defaultZoom;
		stageCamera.scroll.set(300, 100);
		receptors.forEach(strum -> strum.destroy()); receptors.clear(); opponent.clear(); player.clear();
		for (side in 0...2) for (lane in 0...4)
		{
			var strum = new StrumNote(92 + side * 640 + lane * Note.swagWidth, ClientPrefs.data.downScroll ? 570 : 50, lane, side);
			strum.downScroll = ClientPrefs.data.downScroll;
			receptors.add(strum); (side == 0 ? opponent : player).add(strum);
		}
	}
	function buildLuaStage():Void
	{
		if (manager != null && manager.rendererStats != null) manager.rendererStats.restoreSuppressedVisibility();
		if (luaScene != null) luaScene.destroy();
		var targets:Map<String, FlxSprite> = [];
		for (i => name in ['gf', 'dad', 'boyfriend']) if (i < characters.length) targets.set(name, characters[i]);
		for (i => strum in receptors.members) if (strum != null) targets.set('strumLineNotes' + i, strum);
		luaScene = new ModchartScenePreview(timeline.scene, targets, [stageGroup, luaFront, luaHUD], stageCamera, previewCamera);
		if (ModchartEditorPreviewContext.active != null) ModchartEditorPreviewContext.active.renderer = timeline.renderer;
	}
	function buildCountdown():Void
	{
		countdown.forEach(sprite -> sprite.destroy()); countdown.clear();
		var assets = PlayState.isPixelStage ? ['pixelUI/ready-pixel', 'pixelUI/set-pixel', 'pixelUI/date-pixel'] : ['ready', 'set', 'go'];
		for (asset in assets)
		{
			var sprite = new FlxSprite();
			if (Paths.fileExists('images/' + asset + '.png', IMAGE)) sprite.loadGraphic(Paths.image(asset));
			else sprite.makeGraphic(1, 1, FlxColor.TRANSPARENT);
			if (PlayState.isPixelStage) { sprite.scale.set(PlayState.daPixelZoom, PlayState.daPixelZoom); sprite.updateHitbox(); }
			sprite.setPosition((1280 - sprite.width) / 2, (720 - sprite.height) / 2);
			sprite.antialiasing = !PlayState.isPixelStage && ClientPrefs.data.antialiasing;
			countdown.add(sprite);
		}
	}
	function updateCountdown(sound:Bool):Void
	{
		var beat = Conductor.getBeat(position);
		var tick = Math.floor(beat);
		for (i => sprite in countdown.members) {
			sprite.visible = tick == i - 3;
			sprite.alpha = 1 - (beat - tick);
		}
		countdownText.text = tick == -4 ? '3' : '';
		if (sound && tick != countdownBeat && tick >= -4 && tick <= -1)
		{
			var asset = ['intro3', 'intro2', 'intro1', 'introGo'][tick + 4] + (PlayState.isPixelStage ? '-pixel' : '');
			try FlxG.sound.play(Paths.sound(asset), 0.6) catch (_:Dynamic) {}
		}
		countdownBeat = tick;
	}
	function minBeat():Float return timeline.events.length > 0 ? Math.min(-5, timeline.events[0].beat) : -5;
	function endBeat():Float
	{
		var end = song == null ? 128 : Conductor.getBeat(duration);
		for (event in timeline.events) end = Math.max(end, event.beat + event.length);
		return end + 4;
	}
	function clampView():Void
		viewBeat = FlxMath.bound(viewBeat, minBeat(), Math.max(minBeat(), endBeat() - GRID_W / pixelsPerBeat));
	function setTimelineZoom(value:Float, anchorX:Float = -1):Void
	{
		if (anchorX < GRID_X || anchorX > GRID_X + GRID_W) anchorX = GRID_X + GRID_W / 2;
		var localX = anchorX - GRID_X;
		var anchorBeat = viewBeat + localX / pixelsPerBeat;
		pixelsPerBeat = FlxMath.bound(value, 8, 180);
		viewBeat = anchorBeat - localX / pixelsPerBeat;
		drawTimeline();
	}
	inline function zoomTimeline(factor:Float, anchorX:Float = -1):Void
		setTimelineZoom(pixelsPerBeat * factor, anchorX);
	function updateScrollBar():Void
	{
		var total = Math.max(1, endBeat() - minBeat());
		var width = FlxMath.bound(GRID_W * (GRID_W / pixelsPerBeat) / total, 24, GRID_W);
		scrollThumb.scale.x = width; scrollThumb.updateHitbox();
		var range = Math.max(1, endBeat() - GRID_W / pixelsPerBeat - minBeat());
		scrollThumb.x = GRID_X + (viewBeat - minBeat()) / range * (GRID_W - width);
	}
	function updateRowScrollBar():Void
	{
		var maxOffset = Math.max(0, rows.length - VISIBLE_ROWS);
		var height = maxOffset == 0 ? ROW_SCROLL_H : FlxMath.bound(ROW_SCROLL_H * VISIBLE_ROWS / rows.length, 18, ROW_SCROLL_H);
		rowScrollThumb.scale.y = height;
		rowScrollThumb.updateHitbox();
		rowScrollThumb.y = ROW_SCROLL_Y + (maxOffset == 0 ? 0 : rowOffset / maxOffset * (ROW_SCROLL_H - height));
		rowScrollThumb.alpha = maxOffset == 0 ? 0.35 : 1;
	}
	function seekBeat(beat:Float):Void
	{
		seek(Conductor.beatToSeconds(beat));
		var current = Conductor.getBeat(position);
		if (current < viewBeat || current > viewBeat + GRID_W / pixelsPerBeat) { viewBeat = current - GRID_W / pixelsPerBeat / 2; drawTimeline(); }
	}
	function stepTime(beats:Float):Void
		if (song != null) seekBeat(Conductor.getBeat(position) + beats);

	function clearPreviewNotes():Void
	{
		for (note in notes.members) if (note != null && note.isSustainNote) note.destroy();
		notes.clear();
		for (head in liveHeads) head.destroy();
		liveHeads.clear();
	}
	function buildNotes():Void
	{
		clearPreviewNotes(); allNotes = [];
		for (section in song.notes) for (entry in section.sectionNotes)
		{
			if (entry == null || entry.length < 3) continue;
			var raw:Int = Std.int(entry[1]);
			if (raw < 0 || !Math.isFinite(entry[0])) continue;
			var mustPress = section.mustHitSection;
			if (raw > 3) mustPress = !mustPress;
			var time:Float = entry[0];
			var sustain:Float = Math.isFinite(entry[2]) ? Math.max(0, entry[2]) : 0;
			var step = Conductor.getCrotchetAtTime(time) / 4;
			var head = allNotes.length;
			allNotes.push({strumTime: time, lane: raw % 4, mustPress: mustPress, sustain: sustain, step: step, head: -1, end: false});
			var count = Math.round(sustain / step);
			for (i in 0...count)
				allNotes.push({strumTime: time + step * i, lane: raw % 4, mustPress: mustPress, sustain: 0, step: step, head: head, end: i == count - 1});
		}
		// Holds refer to head descriptors, not sprite instances. Remap after sorting.
		var original = allNotes.copy();
		haxe.ds.ArraySort.sort(allNotes, (a, b) -> a.strumTime < b.strumTime ? -1 : (a.strumTime > b.strumTime ? 1 : 0));
		var indices = new haxe.ds.ObjectMap<Dynamic, Int>();
		for (i => item in allNotes) indices.set(item, i);
		for (item in allNotes) if (item.head >= 0) item.head = indices.get(original[item.head]);
	}
	function createHead(index:Int):Note
	{
		var head = liveHeads.get(index);
		if (head != null) return head;
		var data = allNotes[index];
		head = new Note(data.strumTime, data.lane, null, false, true);
		head.mustPress = data.mustPress; head.sustainLength = data.sustain; head.active = false;
		liveHeads.set(index, head); return head;
	}

	function rebuildManager():Void
	{
		if (manager != null) { remove(manager, true); manager.destroy(); }
		manager = new Manager();
		timeline.install(manager);
		// Draw the modchart renderer before the native arrow groups. It suppresses
		// their regular Flixel draw, preventing receptors/notes from appearing twice.
		insert(members.indexOf(receptors), manager);
	}
	function seek(time:Float, rebuild:Bool = true):Void
	{
		if (song == null) return;
		position = FlxMath.bound(time, Conductor.beatToSeconds(minBeat()), duration);
		if (inst != null) { inst.pause(); inst.time = FlxMath.bound(position, 0, inst.length); if (playing && position >= 0 && position < inst.length) inst.resume(); }
		Conductor.songPosition = position;
		var preview = ModchartEditorPreviewContext.active;
		preview.songPosition = position; preview.currentBeat = Conductor.getBeat(position);
		// Recreate the manager from the immutable schedule. This restores defaults,
		// fired events and ease entry values even before the first event after rewind.
		if (rebuild) rebuildManager();
		receptors.forEach(strum -> { strum.playAnim('static', true); strum.resetAnim = 0; });
		clearPreviewNotes();
		// Binary search keeps seeking independent of the number of earlier notes.
		var low = 0; var high = allNotes.length;
		while (low < high) { var mid = (low + high) >> 1; if (allNotes[mid].strumTime < position - 250) low = mid + 1; else high = mid; }
		nextNote = low;
		if (luaScene != null) luaScene.update(position);
		preview.downScroll = receptors.members.length > 0 ? receptors.members[0].downScroll : ClientPrefs.data.downScroll;
		if (manager != null) manager.update(0);
		updateNotes();
		updateCountdown(false);
		drawTimeline();
		lastDance = -1;
	}
	function updateNotes():Void
	{
		var fallback = Math.max(3000, 1800 / Math.max(0.05, song.speed * 0.45));
		var window = manager == null ? fallback : Math.max(manager.getNoteSpawnTime(0, fallback), manager.getNoteSpawnTime(1, fallback));
		while (nextNote < allNotes.length && allNotes[nextNote].strumTime <= position + window)
		{
			var index = nextNote++;
			var data = allNotes[index];
			var note:Note;
			if (data.head < 0) note = createHead(index);
			else {
				var head = createHead(data.head);
				note = new Note(data.strumTime, data.lane, head, true, true);
				note.parent = head; note.mustPress = data.mustPress; note.isSustainEnd = data.end;
				if (!data.end) {
					note.animation.play(Note.colArray[data.lane] + 'hold');
					note.scale.y *= data.step / 100 * 1.05 * song.speed;
					if (!PlayState.isPixelStage) note.scale.y *= Note.SUSTAIN_SIZE / note.frameHeight;
					note.updateHitbox();
				}
				note.correctionOffset = ClientPrefs.data.downScroll ? 0 : head.height / 2;
			}
			note.active = false; notes.add(note);
		}
		var expired:Array<Note> = [];
		for (note in notes.members)
		{
			if (note == null) continue;
			if (note.strumTime < position - 250) { expired.push(note); continue; }
			var strum = (note.mustPress ? player : opponent).members[note.noteData];
			note.wasGoodHit = position >= note.strumTime;
			note.followStrumNote(strum, Conductor.getCrotchetAtTime(note.strumTime), song.speed);
			if (note.wasGoodHit && !note.isSustainNote) note.visible = false;
			if (playing && Math.abs(position - note.strumTime) < 65) { strum.playAnim('confirm', true); strum.resetAnim = 0.12; }
		}
		for (note in expired) { notes.remove(note, true); if (note.isSustainNote) note.destroy(); }
		var expiredHeads:Array<Int> = [];
		for (index => head in liveHeads) if (head.strumTime + head.sustainLength < position - 250) expiredHeads.push(index);
		for (index in expiredHeads) { liveHeads.get(index).destroy(); liveHeads.remove(index); }
	}
	function togglePlayback():Void
	{
		if (song == null) return;
		playing = !playing;
		if (playing && position >= duration) seek(Conductor.beatToSeconds(-5));
		if (inst != null) { if (playing && position >= 0) { inst.play(); inst.time = position; } else inst.pause(); }
	}

	function applyEvent(edit:Bool):Void
	{
		try
		{
			var target:ModchartTimelineEvent = {kind: kindInput.text.trim().toLowerCase(), mod: modInput.text.trim(),
				beat: Std.parseFloat(beatInput.text), length: Std.parseFloat(lengthInput.text), value: Std.parseFloat(valueInput.text),
				ease: easeInput.text.trim(), player: parseInteger(playerInput.text), field: parseInteger(fieldInput.text)};
			timeline.validate(target);
			if (edit && selected != null) timeline.events[timeline.events.indexOf(selected)] = target;
			else timeline.events.push(target);
			selected = target; changed();
		}
		catch (error:Dynamic) message(Std.string(error));
	}
	function parseInteger(text:String):Int
	{
		var value = Std.parseFloat(text);
		if (!Math.isFinite(value) || value != Math.floor(value)) throw tr('integer_fields', "Player and field must be integers");
		return Std.int(value);
	}
	function select(event:ModchartTimelineEvent):Void
	{
		selected = event;
		modInput.text = event.mod; kindInput.text = event.kind; beatInput.text = Std.string(event.beat);
		lengthInput.text = Std.string(event.length); valueInput.text = Std.string(event.value);
		easeInput.text = event.ease; playerInput.text = Std.string(event.player); fieldInput.text = Std.string(event.field);
		drawTimeline();
	}
	function duplicate():Void
	{
		if (selected == null) return;
		var copy:ModchartTimelineEvent = Reflect.copy(selected); copy.beat += 1;
		timeline.events.push(copy); select(copy); changed();
	}
	function deleteEvent():Void
	{
		if (selected == null) return;
		timeline.events.remove(selected); selected = null; changed();
	}
	function changed():Void
	{
		dirty = true; exitPending = false; timeline.sort();
		try { seek(position); message(tr('unsaved', "Unsaved changes.")); }
		catch (error:Dynamic) message(tr('preview_error', "Preview error: {1}", [error]));
		drawTimeline();
	}
	function message(text:String):Void { status.text = text; }
	function rowKey(event:ModchartTimelineEvent):String return event.mod + ' P' + event.player + ' F' + event.field;
	function drawTimeline():Void
	{
		clampView();
		for (item in timelineGroup.members) if (item != null) item.destroy();
		timelineGroup.clear(); rows = [];
		for (event in timeline.events) { var key = rowKey(event); if (!rows.contains(key)) rows.push(key); }
		if (rows.length == 0) rows.push(tr('empty', "No events"));
		rowOffset = Std.int(FlxMath.bound(rowOffset, 0, Math.max(0, rows.length - VISIBLE_ROWS)));
		function rect(x:Float, y:Float, width:Int, height:Int, color:FlxColor):Void
			timelineGroup.add(new FlxSprite(x, y).makeGraphic(Std.int(Math.max(1, width)), height, color));
		function text(x:Float, y:Float, width:Int, value:String, size:Int):Void
			timelineGroup.add(new FlxText(x, y, width, value, size));
		rect(GRID_X, GRID_Y, GRID_W, GRID_H, 0xFF202A3A);
		for (row in 0...VISIBLE_ROWS)
		{
			var index = row + rowOffset;
			if (index < rows.length) text(16, GRID_Y + 24 + row * ROW_H, 140, rows[index], 12);
			rect(GRID_X, GRID_Y + 24 + row * ROW_H, GRID_W, 1, 0xFF364256);
		}
		for (i in 0...Std.int(GRID_W / pixelsPerBeat + 2))
		{
			var beat = Math.floor(viewBeat) + i;
			var x = GRID_X + (beat - viewBeat) * pixelsPerBeat;
			if (x < GRID_X || x > GRID_X + GRID_W) continue;
			rect(x, GRID_Y, 1, GRID_H, beat % 4 == 0 ? 0xFF64748B : 0xFF364256);
			text(x + 3, GRID_Y + 2, 60, Std.string(beat), 12);
		}
		for (event in timeline.events)
		{
			var row = rows.indexOf(rowKey(event)) - rowOffset;
			if (row < 0 || row >= VISIBLE_ROWS) continue;
			var start = GRID_X + (event.beat - viewBeat) * pixelsPerBeat;
			var end = start + Math.max(10, event.length * pixelsPerBeat);
			if (end < GRID_X || start > GRID_X + GRID_W) continue;
			var x = Math.max(GRID_X, start);
			var width = Std.int(Math.min(GRID_X + GRID_W, end) - x);
			rect(x, GRID_Y + 26 + row * ROW_H, width, 20, selected == event ? 0xFFFFD166 : (event.kind == 'set' ? 0xFF6EE7B7 : 0xFF7AA2F7));
			if (width > 36) text(x + 3, GRID_Y + 27 + row * ROW_H, width - 3, event.kind + ' ' + event.value, 11);
		}
		if (scrollThumb != null) updateScrollBar();
		if (rowScrollThumb != null) updateRowScrollBar();
		if (zoomText != null) zoomText.text = Std.int(Math.round(pixelsPerBeat / 36 * 100)) + '%';
	}

	function importText(text:String):Void
	{
		try {
			var imported = ModchartLuaImporter.parse(text); timeline = imported; selected = null;
			buildLuaStage(); viewBeat = minBeat(); changed(); seek(Conductor.beatToSeconds(-5));
			var warnings = timeline.warnings.concat(luaScene.warnings);
			message(warnings.length == 0 ? tr('imported', 'Lua imported: {1} events.', [timeline.events.length])
				: tr('import_warnings', 'Imported {1} events. Preview limits: {2}', [timeline.events.length, warnings.join('; ')]));
		}
		catch (error:Dynamic) message(tr('import_error', "Import cancelled: {1}", [error]));
	}
	function browse(action:String->Void, filters:Array<FileFilter>):Void
	{
		playing = false; if (inst != null) inst.pause();
		file = new FileReference();
		file.addEventListener(Event.SELECT, function(_) {
			file.addEventListener(Event.COMPLETE, function(_) {
				try { action(file.data.toString()); } catch (error:Dynamic) message(tr('open_error', "Could not open: {1}", [error]));
			}); file.load();
		});
		file.browse(filters);
	}
	function openChart():Void
		browse(text -> { loadSong(Song.parseJSON(text)); }, [new FileFilter('Chart JSON', '*.json')]);
	function openProject():Void
		browse(text -> { timeline = ModchartTimeline.fromJson(text); selected = null; buildLuaStage(); changed(); dirty = false; message(tr('project_loaded', "Project loaded.")); }, [new FileFilter('Modchart JSON', '*.json')]);
	function importLua():Void browse(importText, [new FileFilter('Lua Manager', '*.lua')]);
	function saveProject():Void
	{
		file = new FileReference();
		file.addEventListener(Event.COMPLETE, (_) -> { dirty = false; message(tr('project_saved', "Project saved.")); });
		file.save(timeline.toJson(), 'modchart-project.json');
	}
	function exportLua():Void
	{
		try { file = new FileReference(); file.save(timeline.toLua(), 'modchart.lua'); message(tr('export_hint', "Save the Lua in data/<song>/ to use it in gameplay.")); }
		catch (error:Dynamic) message(Std.string(error));
	}
	function leave():Void
	{
		if (dirty && !exitPending) { playing = false; if (inst != null) inst.pause(); exitPending = true; message(tr('discard', "Unsaved changes. Save or press Exit/Esc again to discard.")); return; }
		MusicBeatState.switchState(new MasterEditorMenu());
	}

	override function update(elapsed:Float):Void
	{
		if (song != null)
		{
			if (playing)
			{
				var before = position;
				position = inst != null && inst.playing ? inst.time : position + elapsed * 1000;
				if (before < 0 && position >= 0 && inst != null) { inst.play(); inst.time = position; }
				if (position >= duration) { position = duration; playing = false; if (inst != null) inst.pause(); }
			}
			Conductor.songPosition = position;
			var preview = ModchartEditorPreviewContext.active;
			preview.songPosition = position; preview.currentBeat = Conductor.getBeat(position);
			if (luaScene != null) luaScene.update(position);
			preview.downScroll = receptors.members.length > 0 ? receptors.members[0].downScroll : ClientPrefs.data.downScroll;
			updateNotes();
			updateCountdown(playing && !scrubbing);
			var beat = Math.floor(preview.currentBeat);
			if (beat != lastDance) { lastDance = beat; for (character in characters) character.dance(); }
			clock.text = (dirty ? '* ' : '') + song.song + '  |  ' + FlxMath.roundDecimal(position / 1000, 2) + 's / '
				+ FlxMath.roundDecimal(duration / 1000, 2) + 's  |  Beat ' + FlxMath.roundDecimal(preview.currentBeat, 3)
				+ '  ' + (playing ? tr('play', "PLAY") : tr('paused', "PAUSE"));
			var headX = GRID_X + (preview.currentBeat - viewBeat) * pixelsPerBeat;
			playhead.x = headX; playhead.visible = headX >= GRID_X && headX <= GRID_X + GRID_W;
			playheadHandle.x = headX - 5; playheadHandle.visible = playhead.visible;
			if (playing && !panning && !scrubbing && headX > GRID_X + GRID_W) { viewBeat = preview.currentBeat - 2; drawTimeline(); }
		}
		if (PsychUIInputText.focusOn == null)
		{
			if (FlxG.keys.justPressed.SPACE) togglePlayback();
			if (FlxG.keys.justPressed.ESCAPE) leave();
			if (FlxG.keys.justPressed.DELETE) deleteEvent();
			if (FlxG.keys.pressed.CONTROL && FlxG.keys.justPressed.S) saveProject();
			if (song != null && (FlxG.keys.justPressed.LEFT || FlxG.keys.justPressed.RIGHT))
				stepTime((FlxG.keys.justPressed.LEFT ? -1 : 1) * (FlxG.keys.pressed.SHIFT ? 4 : 0.25));
			if (FlxG.keys.justPressed.HOME) seekBeat(-5);
			if (FlxG.keys.justPressed.MINUS) zoomTimeline(1 / 1.2);
			if (FlxG.keys.justPressed.PLUS) zoomTimeline(1.2);
		}
		var mouse = FlxG.mouse.getWorldPosition(uiCamera);
		if (FlxG.mouse.justPressed && mouse.y >= SCROLL_Y && mouse.y <= SCROLL_Y + 16 && mouse.x >= GRID_X && mouse.x <= GRID_X + GRID_W)
		{
			PsychUIInputText.focusOn = null; panning = true;
			panOffset = mouse.x >= scrollThumb.x && mouse.x <= scrollThumb.x + scrollThumb.width ? mouse.x - scrollThumb.x : scrollThumb.width / 2;
		}
		if (panning && FlxG.mouse.pressed)
		{
			var fraction = FlxMath.bound((mouse.x - GRID_X - panOffset) / Math.max(1, GRID_W - scrollThumb.width), 0, 1);
			viewBeat = minBeat() + fraction * Math.max(0, endBeat() - GRID_W / pixelsPerBeat - minBeat()); drawTimeline();
		}
		if (FlxG.mouse.justPressed && mouse.x >= ROW_SCROLL_X && mouse.x <= ROW_SCROLL_X + 14
			&& mouse.y >= ROW_SCROLL_Y && mouse.y <= ROW_SCROLL_Y + ROW_SCROLL_H)
		{
			PsychUIInputText.focusOn = null;
			rowPanning = rows.length > VISIBLE_ROWS;
			rowPanOffset = mouse.y >= rowScrollThumb.y && mouse.y <= rowScrollThumb.y + rowScrollThumb.height
				? mouse.y - rowScrollThumb.y : rowScrollThumb.height / 2;
		}
		if (rowPanning && FlxG.mouse.pressed)
		{
			var maxOffset = Math.max(0, rows.length - VISIBLE_ROWS);
			var fraction = FlxMath.bound((mouse.y - ROW_SCROLL_Y - rowPanOffset)
				/ Math.max(1, ROW_SCROLL_H - rowScrollThumb.height), 0, 1);
			rowOffset = Math.round(fraction * maxOffset);
			drawTimeline();
		}
		if (FlxG.mouse.wheel != 0 && mouse.x >= 16 && mouse.x < GRID_X
			&& mouse.y >= ROW_SCROLL_Y && mouse.y <= ROW_SCROLL_Y + ROW_SCROLL_H)
		{
			rowOffset -= FlxG.mouse.wheel;
			drawTimeline();
		}
		if (mouse.y >= GRID_Y && mouse.y < GRID_Y + GRID_H && mouse.x >= GRID_X && mouse.x <= GRID_X + GRID_W)
		{
			var beat = viewBeat + (mouse.x - GRID_X) / pixelsPerBeat;
			if (FlxG.mouse.wheel != 0)
			{
				if (FlxG.keys.pressed.CONTROL) zoomTimeline(FlxG.mouse.wheel > 0 ? 1.2 : 1 / 1.2, mouse.x);
				else if (FlxG.keys.pressed.ALT) rowOffset -= FlxG.mouse.wheel;
				else viewBeat -= FlxG.mouse.wheel * 2;
				if (!FlxG.keys.pressed.CONTROL) drawTimeline();
			}
			if (FlxG.mouse.justPressed)
			{
				PsychUIInputText.focusOn = null;
				if (mouse.y < GRID_Y + 24 || (playhead.visible && Math.abs(mouse.x - playhead.x) <= 6)) { scrubbing = true; }
				else
				{
					var row = Std.int((mouse.y - GRID_Y - 24) / ROW_H) + rowOffset;
					var found:ModchartTimelineEvent = null;
					for (event in timeline.events) if (row < rows.length && rowKey(event) == rows[row]
						&& beat >= event.beat && beat <= event.beat + Math.max(10 / pixelsPerBeat, event.length)) found = event;
					if (found != null) { select(found); dragging = found; dragStart = mouse.x; dragBeat = found.beat; }
					else scrubbing = true;
				}
			}
			if (FlxG.mouse.justPressedRight) { beatInput.text = Std.string(Math.round(beat * 4) / 4); applyEvent(false); }
		}
		if (scrubbing && FlxG.mouse.pressed)
		{
			if (mouse.x < GRID_X || mouse.x > GRID_X + GRID_W) { viewBeat += (mouse.x < GRID_X ? -1 : 1) * elapsed * 400 / pixelsPerBeat; drawTimeline(); }
			var beat = viewBeat + (FlxMath.bound(mouse.x, GRID_X, GRID_X + GRID_W) - GRID_X) / pixelsPerBeat;
			seek(Conductor.beatToSeconds(beat));
		}
		if (dragging != null && FlxG.mouse.pressed && Math.abs(mouse.x - dragStart) > 3)
		{
			dragging.beat = Math.round((dragBeat + (mouse.x - dragStart) / pixelsPerBeat) * 4) / 4;
			beatInput.text = Std.string(dragging.beat); drawTimeline();
		}
		if (FlxG.mouse.justReleased) { if (dragging != null && dragging.beat != dragBeat) changed(); dragging = null; scrubbing = false; panning = false; rowPanning = false; }
		mouse.put();
		super.update(elapsed);
	}

	override function destroy():Void
	{
		if (luaScene != null) luaScene.destroy();
		ModchartEditorPreviewContext.active = null;
		if (inst != null) { FlxG.sound.list.remove(inst); inst.destroy(); }
		clearPreviewNotes(); allNotes = [];
		// The side groups reference receptors owned and destroyed by the state.
		opponent.clear(); player.clear();
		super.destroy();
	}
}
