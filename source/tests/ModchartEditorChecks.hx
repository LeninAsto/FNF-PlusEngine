package tests;

#if (debug || modchart_test)
import backend.Song;
import backend.SongLoadPlan;
import modchart.Manager;
import modchart.backend.math.Vector3;
import modchart.backend.standalone.adapters.psych.ModchartEditorPreviewContext;
import modchart.engine.modifiers.list.PathModifier;
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
		report = '3D projection';
		var view = new modchart.backend.math.View3D();
		view.useCamera = false;
		var origin = new Vector3();
		var projected = view.transformVector(new Vector3(100, 50, -1), origin);
		check(Math.abs(projected.x - 50) < 0.0001 && Math.abs(projected.y - 25) < 0.0001,
			'Default projection changed');
		view.fov = Math.PI / 3;
		projected = view.transformVector(new Vector3(100, 0, 0), origin);
		check(projected.x > 170 && projected.x < 175, 'FOV did not update immediately');
		view.fov = Math.PI / 2;
		view.near = 0.5;
		projected = view.transformVector(new Vector3(100, 0, -1), origin);
		check(Math.abs(projected.x - 25) < 0.0001, 'Depth coefficients did not update immediately');
		view.near = view.far;
		check(view.near == 0.5, 'Degenerate depth range was accepted');
		view.near = 0;
		view.lookAt(new Vector3(), new Vector3(0, 0, -1), new Vector3(0, 1, 0));
		view.position.x = 10;
		view.target.x = 10;
		projected = view.transformVector(new Vector3(100, 0, 0), origin);
		check(Math.abs(projected.x - 90) < 0.0001, 'Camera position was not applied');
		view.target.x = 11;
		projected = view.transformVector(new Vector3(100, 0, 0), origin);
		check(projected.x < 2, 'Camera target changes left the basis stale');
		view.lookAt(new Vector3(), new Vector3(), new Vector3(0, 0, 1));
		projected = view.transformVector(new Vector3(100, 0, 0), origin);
		check(Math.isFinite(projected.x) && Math.isFinite(projected.y), 'Degenerate camera basis');

		report = 'triangle batch attributes';
		var batch = new flixel.graphics.tile.FlxDrawTrianglesItem();
		batch.colored = true;
		batch.hasColorOffsets = true;
		var vertices = new openfl.Vector<Float>(8, true, [0., 0., 20., 0., 0., 20., 20., 20.]);
		var indices = new openfl.Vector<Int>(6, true, [0, 1, 2, 1, 3, 2]);
		var uvs = new openfl.Vector<Float>(8, true, [0., 0., 1., 0., 0., 1., 1., 1.]);
		var transforms = new haxe.ds.Vector<openfl.geom.ColorTransform>(1);
		transforms[0] = new openfl.geom.ColorTransform(1, 1, 1, 0.25, 0, 0, 0, 0);
		batch.addGradientTriangles(vertices, indices, uvs, new flixel.math.FlxPoint(), new flixel.math.FlxRect(0, 0, 100, 100), transforms);
		transforms[0] = new openfl.geom.ColorTransform(0.5, 1, 1, 0.75, 10, 0, 0, 0);
		batch.addGradientTriangles(vertices, indices, uvs, new flixel.math.FlxPoint(), new flixel.math.FlxRect(0, 0, 100, 100), transforms);
		@:privateAccess check(batch.alphas.length == 12 && batch.colorMultipliers.length == 48 && batch.colorOffsets.length == 48,
			'Triangle attributes grew with accumulated batch size');
		@:privateAccess check(batch.alphas[0] == 0.25 && batch.alphas[6] == 0.75 && batch.colorMultipliers[24] == 0.5
			&& batch.colorOffsets[24] == 10, 'Triangle attributes lost per-command color or alpha');
		batch.addGradientTriangles(vertices, indices, uvs, new flixel.math.FlxPoint(1000, 1000), new flixel.math.FlxRect(0, 0, 100, 100), transforms);
		@:privateAccess check(batch.alphas.length == 12 && batch.indices.length == 12, 'Culled triangles left batch attributes behind');
		batch.addGradientTriangles(vertices, indices, uvs, new flixel.math.FlxPoint(1000, 1000), new flixel.math.FlxRect(0, 0, 100, 100), transforms, false);
		@:privateAccess check(batch.alphas.length == 18 && batch.indices.length == 18, 'Unculled projected geometry was discarded');
		batch.dispose();

		report = 'near plane clipping';
		{
			var clipView = new modchart.backend.math.View3D();
			clipView.useCamera = false;
			var clipper = new modchart.backend.graphics.NearPlaneClipper();
			var world = new openfl.Vector<Float>(24, true);
			var clipDistances = new openfl.Vector<Float>(8, true);
			var sourceUV = new openfl.Vector<Float>(24, true);
			var clippedVertices = new openfl.Vector<Float>(32, true);
			var clippedUV = new openfl.Vector<Float>(48, true);
			for (quad in 0...2) for (i in 0...4) {
				var n = quad * 4 + i;
				world[n * 3] = 500 + (i % 2) * 100;
				world[n * 3 + 1] = 300 + Std.int(i / 2) * 100;
				world[n * 3 + 2] = quad == 0 && i % 2 == 1 ? 2 : 0;
				sourceUV[n * 3] = i % 2;
				sourceUV[n * 3 + 1] = Std.int(i / 2);
				sourceUV[n * 3 + 2] = 1;
				clipView.transformVector(new Vector3(world[n * 3], world[n * 3 + 1], world[n * 3 + 2]));
				clipDistances[n] = clipView.clipDistance;
			}
			check(clipper.clipQuad(clipView, world, clipDistances, sourceUV, 0, clippedVertices, clippedUV, false),
				'Crossing arrow disappeared');
			var foundIntersection = false;
			for (i in 0...8) {
				check(Math.isFinite(clippedVertices[i * 2]) && Math.isFinite(clippedVertices[i * 2 + 1])
					&& Math.isFinite(clippedUV[i * 3 + 2]) && clippedUV[i * 3 + 2] > 0, 'Invalid clipped vertex');
				if (clippedUV[i * 3] > 0.49 && clippedUV[i * 3] < 0.50) foundIntersection = true;
			}
			check(foundIntersection, 'Clipped texture intersection is incorrect');
			check(clipper.clipQuad(clipView, world, clipDistances, sourceUV, 1, clippedVertices, clippedUV, true),
				'Hold segment was lost');
			for (i in 8...16) check(clippedUV[i * 3 + 2] == 1, 'Hold texture interpolation changed during clipping');
			for (i in 0...4) clipDistances[i] = -1;
			check(!clipper.clipQuad(clipView, world, clipDistances, sourceUV, 0, clippedVertices, clippedUV, true),
				'Invisible segment was retained');
		}


		SongLoadPlan.clear();
		Song.chartPath = null;
		report = 'chart plans';
		var original = fixture();
		var first = SongLoadPlan.prepare(original);
		var sides:SwagSong = {song: 'sides', notes: [
			{sectionNotes: [[100, 0, 0, ''], [200, 4, 0, '']], sectionBeats: 4, mustHitSection: false},
			{sectionNotes: [[300, 0, 0, ''], [400, 4, 0, '']], sectionBeats: 4, mustHitSection: true}
		], events: [], bpm: 120, speed: 1, needsVoices: false, offset: 0, player1: 'bf', player2: 'dad', gfVersion: 'gf', stage: 'stage',
			format: 'psych_v1'};
		var sidePlan = SongLoadPlan.prepare(sides);
		check(sidePlan.notes[0].gottaHit && !sidePlan.notes[1].gottaHit && sidePlan.notes[2].gottaHit && !sidePlan.notes[3].gottaHit,
			'psych_v1 absolute player/opponent columns were reinterpreted through mustHitSection');
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
		report = 'setAdd respects each player';
		var addManager = new Manager();
		addManager.setPercent('transformX', 10, 0);
		addManager.setPercent('transformX', 20, 1);
		addManager.setAdd('transformX', 0, 5);
		addManager.update(0);
		check(addManager.getPercent('transformX', 0) == 15 && addManager.getPercent('transformX', 1) == 25,
			'setAdd used one player value for both players');
		addManager.destroy();
		report = 'submodifier parent install';
		var submods = ModchartLuaImporter.parse('set("beatMult",0,2); set("drunkSpeed",0,3); set("bumpyY",0,1); set("x0",0,100); '
			+ 'set("shrinkToMin",0,0.5); set("noteSkewX",0,0.2); set("mini0",0,0.1); set("schmovinArrowShapeOffset",0,24)');
		var parentManager = new Manager();
		var extraField = parentManager.addPlayerPlayfield('ghost', 2);
		check(extraField != null && extraField.acceptsPlayer(2) && !extraField.acceptsPlayer(1), 'Extra StrumLine field was not isolated');
		check(parentManager.playfields[0].acceptsPlayer(0) && parentManager.playfields[0].acceptsPlayer(1)
			&& !parentManager.playfields[0].acceptsPlayer(2), 'Main field captured an extra StrumLine');
		submods.install(parentManager);
		var parentMods = parentManager.playfields[0].modifiers.modifiers;
		check(parentMods.exists('beat') && parentMods.exists('drunk') && parentMods.exists('bumpy') && parentMods.exists('transform')
			&& parentMods.exists('shrink') && parentMods.exists('skew') && parentMods.exists('scale')
			&& parentMods.exists('schmovinarrowshape'),
			'Submodifier did not auto-install its compiled parent');
		parentManager.setPercent('pulseSpeed', 2);
		check(parentMods.exists('pulse'), 'Immediate submodifier did not auto-install its compiled parent');
		report = 'modifier timing context';
		var timingField = parentManager.playfields[0];
		var timingModifier = new modchart.engine.modifiers.DynamicModifier(timingField);
		var recorded:Array<Float> = [];
		var recordedPath:Bool = false;
		timingModifier.renderFunc = function(pos, params) {
			recorded = [params.songTime, params.strumTime, params.sampleTime, params.sourceTime, params.hitTime];
			recordedPath = params.isPath;
			return pos;
		};
		timingField.addScriptedModifier('timingcheck', timingModifier);
		timingField.beginFrame(77, 500, 1);
		var timingData:modchart.backend.core.ArrowData = {hitTime: 1120, sourceTime: 1000, strumTime: 1050,
			sampleTime: 1100, distance: 620, player: 0, lane: 0, isTapArrow: true, isHoldBody: true, isPath: true};
		var timingPos = new Vector3();
		var timingVisuals:modchart.backend.core.VisualParameters = {};
		var timingOut:modchart.backend.core.ModifierOutput = {pos: timingPos, visuals: timingVisuals};
		timingField.getNotePathInto(new Vector3(), timingData, timingOut, timingPos, timingVisuals, 25);
		check(recorded.length == 5 && recorded[0] == 500 && recorded[1] == 1050 && recorded[2] == 1125
			&& recorded[3] == 1000 && recorded[4] == 1145 && recordedPath, 'Modifier timing context lost note or hold sample time');
		report = 'cached modifier timing';
		timingData.strumTime = null;
		timingData.sampleTime = null;
		timingField.getNotePath(new Vector3(), timingData);
		check(recorded[1] == 1120 && recorded[2] == 1120, 'Default note times are incorrect');
		recorded = [];
		timingData.strumTime = 0;
		timingData.sampleTime = 0;
		timingField.getNotePath(new Vector3(), timingData);
		check(recorded.length == 5 && recorded[1] == 0 && recorded[2] == 0, 'Cached default times hid explicit zero times');
		report = 'bezier path';
		parentManager.addModifier('path');
		var path:PathModifier = cast parentMods.get('path');
		check(path.loadBezier({x: 0, y: 0, z: 0}, {x: 0, y: 100, z: 0}, {x: 100, y: 100, z: 0}, {x: 100, y: 0, z: 0}, 8),
			'Bezier path was rejected');
		var midpoint = path.computePathAt(new Vector3(), 0, 750, 1, true);
		check(midpoint.x > 40 && midpoint.x < 60 && midpoint.y > 70 && midpoint.y < 80, 'Bezier path midpoint is incorrect');
		check(path.loadBezierForLane({x: 0, y: 0, z: 0}, {x: 0, y: -100, z: 0}, {x: -100, y: -100, z: 0}, {x: -100, y: 0, z: 0}, 8, 2),
			'Lane Bezier path was rejected');
		var lanePoint = path.computePathAt(new Vector3(), 2, 750, 1, true);
		check(lanePoint.x < -40 && lanePoint.y < -70, 'Lane Bezier path did not override the global path');
		check(!path.loadBezier({x: Math.NaN, y: 0, z: 0}, {x: 0, y: 0, z: 0}, {x: 0, y: 0, z: 0}, {x: 0, y: 0, z: 0}, 8),
			'Invalid Bezier path replaced a valid path');
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
