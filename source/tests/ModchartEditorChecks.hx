package tests;

#if debug
import backend.Song;
import backend.SongLoadPlan;
import modchart.Manager;
import modchart.backend.standalone.adapters.psych.ModchartEditorPreviewContext;
import states.editors.content.ModchartTimeline;
import states.editors.content.ModchartLuaImporter;
import states.editors.content.ModchartScenePreview;

/** Run a debug build with --modchart-self-test. Uses the real Lua VM and Manager. */
class ModchartEditorChecks
{
	public static var report:String = '';
	static function check(value:Bool, message:String):Void
	{
		if (!value) throw message;
	}
	static function fixture(time:Float = 100):SwagSong
	{
		return {song: 'regression', notes: [{sectionNotes: [[time, 0, 0, '']], sectionBeats: 4, mustHitSection: true}],
			events: [], bpm: 120, speed: 1, needsVoices: false, offset: 0, player1: 'bf', player2: 'dad', gfVersion: 'gf', stage: 'stage', format: 'psych_v1'};
	}
	public static function run():Void
	{
		SongLoadPlan.clear();
		Song.chartPath = null;
		report = 'chart plans';
		var original = fixture();
		var first = SongLoadPlan.prepare(original);
		var edited = fixture(900);
		var second = SongLoadPlan.get(edited);
		check(second != first && second.source == edited && second.notes[0].strumTime == 900, 'Stale plan reused for edited chart');
		var large = fixture();
		for (i in 0...21000) large.notes[0].sectionNotes.push([i * 0.01, i % 4, 0, '']);
		large.notes[0].sectionNotes.push([300, -1, 0, '']);
		var plan = SongLoadPlan.prepare(large);
		check(plan.denseChart, 'Dense chart path not selected');
		check(large.notes[0].sectionNotes.length == 21002, 'Preparing a plan mutated source notes');
		var weight = 0;
		for (note in plan.notes) { check(note.column >= 0 && note.column < 4, 'Invalid negative lane'); weight += note.density; }
		check(weight == 21001, 'Dense packing lost note weight');
		SongLoadPlan.clear();

		report = 'basic Lua';
		var model = ModchartLuaImporter.parse('function onCreatePost()\n'
			+ 'addModifier("drunk")\nfor i=0,7 do queueSet(i*4,"drunk",i/10) end\n'
			+ 'manager:ease("drunk",32,4,1,"linear",1)\nManager.set("drunk",40,0)\nend');
		check(model.events.length == 10 && model.events[7].beat == 28, 'Lua loops or Manager method parsing failed');
		report = 'complex Lua loops';
		var loops = ModchartLuaImporter.parse('\uFEFFlocal names={"drunk","tipsy"}\nfunction onInitModchart()\n'
			+ 'for index,name in ipairs(names) do for i=3,0,-1 do manager:queueSet(i*2,name..i,index/10) end end\n'
			+ 'Manager:queueEase(8,12,"reverse",1,"linear",1,0,0)\nend');
		check(loops.events.length == 10 && loops.events[8].field == 0 && loops.events[8].value == 0,
			'Nested/ipairs loops, BOM, or queueEase startValue import failed');
		report = 'advanced Lua fallback';
		var advanced = ModchartLuaImporter.parse('function onInitModchart() addModifier("drunk","ghost"); '
			+ 'addPlayfield("ghost"); set("drunk",1,1,-1,"ghost"); set("tipsy",2,1) end');
		check(advanced.events.length == 1 && advanced.modifiers.contains('drunk') && advanced.warnings.length >= 2,
			'Advanced playfield calls blocked compatible modifiers/events');
		report = 'Lua roundtrip';
		var roundtrip = ModchartLuaImporter.parse(model.toLua());
		check(roundtrip.toJson() == model.toJson(), 'Lua export/import changed schedule');
		check(ModchartTimeline.fromJson(model.toJson()).toLua() == model.toLua(), 'Project roundtrip changed schedule');
		report = 'field import';
		var fields = ModchartLuaImporter.parse('addPlayfield(); set("drunk",4,1,1,1)');
		check(ModchartLuaImporter.parse(fields.toLua()).fieldCount == 2, 'Lua roundtrip lost playfields');
		report = 'negative beat import';
		var negative = ModchartLuaImporter.parse('function onInitModchart() set("xmod",-5,2.5); ease({invert=1,flip=0.5},-4,1,"quadOut",1) end');
		check(negative.events.length == 3 && negative.events[0].beat == -5 && negative.events[1].player == 1, 'Negative beats/table easing lost');
		report = 'scene import';
		var scene = ModchartLuaImporter.parse('function onCreate() makeLuaSprite("panel","",10,20); makeGraphic("panel",100,50,"FF0000"); '
			+ 'setProperty("panel.alpha",0.8); setObjectCamera("panel","hud"); addLuaSprite("panel") end '
			+ 'function onSongStart() doTweenAlpha("fade","panel",0,1,"linear") end function onInitModchart() set("xmod",-5,1) end');
		report = 'scene construction';
		var groups = [new FlxTypedGroup<FlxSprite>(), new FlxTypedGroup<FlxSprite>(), new FlxTypedGroup<FlxSprite>()];
		var stage = new ModchartScenePreview(scene.scene, [], groups, FlxG.camera, FlxG.camera);
		check(groups[2].length == 1 && groups[0].length == 0, 'Lua HUD sprite assigned to wrong camera');
		report = 'scene forward';
		stage.update(500); check(Math.abs(groups[2].members[0].alpha - 0.4) < 0.0001, 'Lua scene tween seek failed');
		report = 'scene rewind';
		stage.update(-1000); check(Math.abs(groups[2].members[0].alpha - 0.8) < 0.0001, 'Lua scene rewind failed'); stage.destroy();
		report = 'scene roundtrip';
		check(ModchartLuaImporter.parse(scene.toLua()).scene.length == scene.scene.length, 'Scene Lua export lost operations');
		report = 'localization';
		check(Language.getPhraseForLanguage('en-US', 'editors.modchart.save', '') == 'Save', 'Missing English editor bundle');
		check(Language.getPhraseForLanguage('es-LA', 'editors.modchart.save', '') == 'Guardar', 'Missing Spanish editor bundle');
		var anomalySummary = '';
		#if sys
		var anomaly = Sys.getEnv('PLUS_MODCHART_TEST_MOD');
		if (anomaly != null && sys.FileSystem.exists(anomaly))
		{
			var imported = 0;
			var details:Array<String> = [];
			function walk(folder:String):Void
			{
				for (name in sys.FileSystem.readDirectory(folder))
				{
					var path = folder + '/' + name;
					if (sys.FileSystem.isDirectory(path)) { walk(path); continue; }
					if (!name.endsWith('.lua')) continue;
					var text = sys.io.File.getContent(path);
					if (text.indexOf('function onInitModchart') < 0) continue;
					report = 'Anomaly import: ' + path;
					var parsed = ModchartLuaImporter.parse(text);
					check(parsed.events.length > 0, 'Anomaly script produced an empty timeline: ' + path);
					if (text.indexOf('createModifier(') != -1)
						check(parsed.warnings.length > 0, 'Custom modifier was not reported as ignored: ' + path);
					report = 'Anomaly roundtrip: ' + path;
					var exported = ModchartLuaImporter.parse(parsed.toLua());
					check(exported.events.length == parsed.events.length && exported.scene.length == parsed.scene.length, 'Anomaly roundtrip lost content: ' + path);
					imported++; details.push(path + ': ' + parsed.events.length + ' events, ' + parsed.scene.length + ' scene operations');
				}
			}
			walk(anomaly); check(imported >= 9, 'Expected at least nine supported Anomaly scripts');
			anomalySummary = '\nAnomaly: ' + imported + ' schedules imported.\n' + details.join('\n');
		}
		#end
		var dynamicModel = ModchartLuaImporter.parse('function onUpdate() end');
		check(dynamicModel.warnings.length > 0, 'Ignored dynamic callback was not reported');
		var refused = false;
		try ModchartLuaImporter.parse('while true do end') catch (_:Dynamic) refused = true;
		check(refused, 'Lua instruction limit failed');

		ModchartEditorPreviewContext.active = {currentBeat: 0, songPosition: 0, scrollSpeed: 0.45, camera: FlxG.camera,
			strumLineNotes: new FlxTypedGroup<objects.StrumNote>(), opponentStrums: new FlxTypedGroup<objects.StrumNote>(),
			playerStrums: new FlxTypedGroup<objects.StrumNote>(), notes: new FlxTypedGroup<objects.Note>(), noteSplashes: new FlxTypedGroup<objects.NoteSplash>()};
		report = 'submodifier parent install';
		var submods = ModchartLuaImporter.parse('set("beatMult",0,2); set("drunkSpeed",0,3); set("bumpyY",0,1); set("x0",0,100); '
			+ 'set("shrinkToMin",0,0.5); set("noteSkewX",0,0.2); set("mini0",0,0.1); set("schmovinArrowShapeOffset",0,24)');
		var parentManager = new Manager();
		submods.install(parentManager);
		var parentMods = parentManager.playfields[0].modifiers.modifiers;
		check(parentMods.exists('beat') && parentMods.exists('drunk') && parentMods.exists('bumpy') && parentMods.exists('transform')
			&& parentMods.exists('shrink') && parentMods.exists('skew') && parentMods.exists('scale')
			&& parentMods.exists('schmovinarrowshape'),
			'Submodifier did not auto-install its compiled parent');
		parentManager.setPercent('pulseSpeed', 2);
		check(parentMods.exists('pulse'), 'Immediate submodifier did not auto-install its compiled parent');
		parentManager.destroy();
		var schedule = ModchartLuaImporter.parse('set("drunk",4,0.5); ease("drunk",8,4,1,"linear")');
		function sample(beat:Float):Float
		{
			ModchartEditorPreviewContext.active.currentBeat = beat;
			ModchartEditorPreviewContext.active.songPosition = beat * 500;
			var manager = new Manager(); schedule.install(manager); manager.update(0);
			var value = manager.getPercent('drunk', 0); manager.destroy(); return value;
		}
		check(Math.abs(sample(10) - 0.75) < 0.0001, 'Seek into ease failed');
		check(Math.abs(sample(20) - 1) < 0.0001, 'Forward seek failed');
		check(Math.abs(sample(2)) < 0.0001, 'Rewind did not restore defaults');
		check(Math.abs(sample(10) - 0.75) < 0.0001, 'Seek result depends on previous position');
		ModchartEditorPreviewContext.active = null;
		report = '\nSubmodifier parent auto-install: PASS' + anomalySummary;
	}
}
#end
