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
		var cyberSummary = '';
		#if sys
		if (Sys.getEnv('PLUS_TEST_GALAXY_NOTES') == '1') {
			report = 'Galaxy real note visuals and release';
			var previousSong = states.PlayState.SONG;
			var previousGame = states.PlayState.instance;
			var previousMod = backend.Mods.currentModDirectory;
			backend.Mods.currentModDirectory = 'In The Galaxy Port';
			var testSong = fixture();
			testSong.notes[0].sectionNotes = [[100, 10, 0], [200, 20, 0], [300, 42.02, 150], [400, 6.01, 0]];
			testSong.arrowSkin = 'galaxy/NOTE_assets';
			testSong.disableNoteRGB = true;
			states.PlayState.SONG = testSong;
			var testGame = new states.PlayState();
			states.PlayState.instance = testGame;
			var galaxyClass = scripting.IrisScriptClassImport.resolve('GalaxyNotes', 'In The Galaxy Port');
			check(galaxyClass != null, 'Galaxy scripted class did not load');
			var galaxyHelper:scripting.IrisScriptClassImport.IrisScriptClassInstance = cast galaxyClass.hnew([testGame]);
			check(galaxyHelper != null && Reflect.callMethod(galaxyHelper, galaxyHelper.hget('isReady'), []) == true,
				'Galaxy note helper did not activate');
			var converted = testSong.notes[0].sectionNotes;
			check(converted[0][1] == converted[1][1] && Math.abs(converted[2][1] - 2.02) < 0.001
				&& converted[2][3] == 'Galaxy Release Head' && Math.abs(converted[3][1] - 6.01) < 0.001,
				'Galaxy chart conversion lost random replay, side or release metadata');
			var first = new objects.Note(1000, 0); first.mustPress = true;
			var second = new objects.Note(1000, 1); second.mustPress = true;
			var head = new objects.Note(2000, 2); head.mustPress = true; head.sustainLength = 300;
			head.noteType = 'Galaxy Release Head';
			var tail = new objects.Note(2200, 2, head, true); tail.mustPress = true; tail.parent = head; tail.isSustainEnd = true;
			head.tail.push(tail);
			var near = new objects.Note(2304.6, 3); near.mustPress = true;
			var outside = new objects.Note(2305.1, 0); outside.mustPress = true;
			testGame.unspawnNotes = [first, second, head, tail, near, outside];
			Reflect.callMethod(galaxyHelper, galaxyHelper.hget('prepare'), []);
			check(Math.abs(tail.modchartHoldLength - 100) < 0.001 && !tail.isSustainEnd && testGame.totalNotes == 2,
				'Galaxy release hold did not reach its endpoint or count its segment');
			check(first.frame.name.indexOf('spurple0') == 0 && second.frame.name.indexOf('sblue0') == 0,
				'Galaxy chord did not use the yellow atlas frames');
			check(near.frame.name.indexOf('sred0') == 0 && outside.frame.name.indexOf('purple0') == 0,
				'Galaxy release synchronization did not use the strict five millisecond window');
			var release:objects.Note = null;
			for (note in testGame.unspawnNotes) if (note.noteType == 'Galaxy Release') release = note;
			check(release != null && release.blockHit && release.frame.name.indexOf('sgreen release') == 0,
				'Galaxy release note or synchronized atlas frame was not created');
			var originalScale = first.scale.x;
			Reflect.callMethod(galaxyHelper, galaxyHelper.hget('setSkin'), ['noteSkins/cyber']);
			check(first.frame.name.indexOf('spurple0') == 0 && release.frame.name.indexOf('sgreen release') == 0
				&& Math.abs(first.scale.x - originalScale) < 0.001, 'Galaxy skin change lost a special frame or resized a note');
			Reflect.callMethod(galaxyHelper, galaxyHelper.hget('setSkin'), ['galaxy/NOTE_assets']);
			testGame.notes = new FlxTypedGroup<objects.Note>();
			testGame.notes.add(tail);
			testGame.updateScore = function(?miss:Bool = false, ?bop:Bool = true) {};
			Reflect.callMethod(galaxyHelper, galaxyHelper.hget('hitHold'), [0]);
			check(testGame.songHits == 1 && testGame.combo == 1 && testGame.totalPlayed == 1
				&& testGame.totalNotesHit == 1 && testGame.songScore == 20, 'Galaxy hold segment was not scored');
			var count = testGame.unspawnNotes.length;
			Reflect.callMethod(galaxyHelper, galaxyHelper.hget('prepare'), []);
			check(testGame.unspawnNotes.length == count, 'Galaxy preparation added duplicate releases');
			Reflect.callMethod(galaxyHelper, galaxyHelper.hget('clear'), []);
			#if (LUA_ALLOWED && HSCRIPT_ALLOWED)
			var galaxyScriptPath = Sys.getEnv('PLUS_TEST_GALAXY_SCRIPT');
			if (galaxyScriptPath != null && sys.FileSystem.exists(galaxyScriptPath)) {
				var context = new psychlua.backend.LuaHostContext(psychlua.backend.LuaHostKind.NONE, 'galaxy-notes-test', testGame);
				var galaxyScript = new psychlua.backend.FunkinLua(galaxyScriptPath, context, false);
				psychlua.backend.HScript.initHaxeModule(galaxyScript);
				galaxyScript.hscript.set('game', testGame);
				galaxyScript.call('onCreate', []);
				var ready = galaxyScript.hscript.call('galaxyReady', []);
				check(ready != null && ready.returnValue == true, 'Galaxy Lua could not import or initialize its scripted class');
				var bridgedHead = new objects.Note(3000, 1); bridgedHead.mustPress = true; bridgedHead.sustainLength = 300;
				bridgedHead.noteType = 'Galaxy Release Head';
				var bridgedPeer = new objects.Note(3300, 0); bridgedPeer.mustPress = true;
				testGame.unspawnNotes.push(bridgedHead);
				testGame.unspawnNotes.push(bridgedPeer);
				galaxyScript.call('onCreatePost', []);
				check(testGame.unspawnNotes.length == count + 3 && bridgedPeer.frame.name.indexOf('spurple0') == 0,
					'Galaxy Lua did not apply its scripted note helper');
				galaxyScript.call('onDestroy', []);
				galaxyScript.stop();
			}
			#end
			for (note in testGame.unspawnNotes) if (note != null) note.destroy();
			states.PlayState.instance = previousGame;
			states.PlayState.SONG = previousSong;
			backend.Mods.currentModDirectory = previousMod;
		}
		#end
		report = '3D projection';
		var view = new modchart.backend.math.View3D();
		view.useCamera = false;
		var origin = new Vector3();
		check(Math.abs(modchart.backend.graphics.renderers.ArrowRenderer.holdDirectionAngle(0, 1, false)) < 0.001
			&& Math.abs(modchart.backend.graphics.renderers.ArrowRenderer.holdDirectionAngle(0, -1, true)) < 0.001
			&& Math.abs(modchart.backend.graphics.renderers.ArrowRenderer.holdDirectionAngle(1, 0, false) + 90) < 0.001
			&& Math.abs(modchart.backend.graphics.renderers.ArrowRenderer.holdDirectionAngle(-1, 0, true) + 90) < 0.001,
			'Hold cover direction did not follow the scroll tangent');
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
			var projectedHold = new openfl.Vector<Float>(16, true);
			for (n in 0...8) {
				var point = clipView.transformVector(new Vector3(world[n * 3], world[n * 3 + 1], world[n * 3 + 2]));
				projectedHold[n * 2] = point.x;
				projectedHold[n * 2 + 1] = point.y;
			}
			var fastVertices = new openfl.Vector<Float>(32, true);
			var fastUV = new openfl.Vector<Float>(48, true);
			for (quad in 0...2) {
				var reference = clipper.clipQuad(clipView, world, clipDistances, sourceUV, quad, clippedVertices, clippedUV, true);
				var optimized = clipper.clipHoldQuad(clipView, world, clipDistances, sourceUV, projectedHold, quad, fastVertices, fastUV);
				check(reference == optimized, 'Optimized hold clipping changed visibility');
				for (i in quad * 16...(quad + 1) * 16)
					check(Math.abs(clippedVertices[i] - fastVertices[i]) < 0.0001, 'Optimized hold clipping changed geometry');
				for (i in quad * 24...(quad + 1) * 24)
					check(Math.abs(clippedUV[i] - fastUV[i]) < 0.0001, 'Optimized hold clipping changed UVs');
			}
			for (mask in 0...16) {
				for (i in 0...4) {
					world[i * 3 + 2] = (mask & (1 << i)) != 0 ? 0 : 2;
					var point = clipView.transformVector(new Vector3(world[i * 3], world[i * 3 + 1], world[i * 3 + 2]));
					clipDistances[i] = clipView.clipDistance;
					projectedHold[i * 2] = point.x;
					projectedHold[i * 2 + 1] = point.y;
				}
				var reference = clipper.clipQuad(clipView, world, clipDistances, sourceUV, 0, clippedVertices, clippedUV, true);
				var optimized = clipper.clipHoldQuad(clipView, world, clipDistances, sourceUV, projectedHold, 0, fastVertices, fastUV);
				check(reference == optimized, 'Optimized clipping changed a near-plane case');
				for (i in 0...16) check(Math.abs(clippedVertices[i] - fastVertices[i]) < 0.0001, 'Near-plane geometry mismatch');
				for (i in 0...24) check(Math.abs(clippedUV[i] - fastUV[i]) < 0.0001, 'Near-plane UV mismatch');
			}
			for (i in 0...4) {
				world[i * 3 + 2] = i % 2 == 1 ? 2 : 0;
				clipView.transformVector(new Vector3(world[i * 3], world[i * 3 + 1], world[i * 3 + 2]));
				clipDistances[i] = clipView.clipDistance;
			}
			if (Sys.getEnv('PLUS_TEST_HOLD_BENCH') == '1') {
				var rounds = 20000;
				var start = haxe.Timer.stamp();
				for (_ in 0...rounds) clipper.clipQuad(clipView, world, clipDistances, sourceUV, 1, clippedVertices, clippedUV, true);
				var oldMs = (haxe.Timer.stamp() - start) * 1000;
				start = haxe.Timer.stamp();
				for (_ in 0...rounds) clipper.clipHoldQuad(clipView, world, clipDistances, sourceUV, projectedHold, 1, fastVertices, fastUV);
				var newMs = (haxe.Timer.stamp() - start) * 1000;
				cyberSummary += '\nVisible clipping benchmark: legacy ' + Std.int(oldMs) + ' ms; fast ' + Std.int(newMs) + ' ms / ' + rounds;
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
			check(!clipper.clipHoldQuad(clipView, world, clipDistances, sourceUV, projectedHold, 0, fastVertices, fastUV),
				'Optimized clipping retained an invisible segment');
			for (i in 0...16) check(clippedVertices[i] == fastVertices[i], 'Invisible hold geometry differs');
			for (i in 0...24) check(clippedUV[i] == fastUV[i], 'Invisible hold UVs differ');
			for (i in 0...32) {
				var a = i * 11.3 - 160;
				var b = i * 7.7 - 90;
				var left = new Vector3(17 + i, -36 + i * 0.4, 0);
				var right = new Vector3(-left.x, -left.y, 0);
				left = modchart.backend.util.ModchartUtil.rotate3DVectorInto(left, 0, a, 0, new Vector3());
				right = modchart.backend.util.ModchartUtil.rotate3DVectorInto(right, 0, a, 0, new Vector3());
				left = modchart.backend.util.ModchartUtil.rotate3DVectorInto(left, b, a * 0.3, -b, new Vector3());
				right = modchart.backend.util.ModchartUtil.rotate3DVectorInto(right, b, a * 0.3, -b, new Vector3());
				check(Math.abs(left.x + right.x) < 0.000001 && Math.abs(left.y + right.y) < 0.000001
					&& Math.abs(left.z + right.z) < 0.000001, 'Hold edge rotation lost symmetry');
			}
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
		report = 'managed receptor visibility';
		var visibilityRenderer = new modchart.backend.graphics.CtxRenderer();
		var managedStrum = new objects.StrumNote(0, 0, 0, 0);
		var extraStrum = new objects.StrumNote(0, 0, 0, 2);
		visibilityRenderer.suppressManagedReceptors([managedStrum, extraStrum], parentManager.playfields);
		@:bypassAccessor check(!managedStrum.visible && extraStrum.visible, 'Managed receptor prepass hid the wrong strumline');
		visibilityRenderer.restoreSuppressedVisibility();
		@:bypassAccessor check(managedStrum.visible && extraStrum.visible, 'Managed receptor visibility was not restored');
		managedStrum.destroy();
		extraStrum.destroy();
		#if (sys && LUA_ALLOWED && MODCHART_ALLOWED)
		var underworldPath = Sys.getEnv('PLUS_TEST_UNDERWORLD_LUA');
		if (underworldPath != null && sys.FileSystem.exists(underworldPath)) {
			report = 'Underworld skin and hexagon Lua';
			var fakeStrums = new FlxTypedGroup<FlxSprite>();
			var host = new CyberTestHost(fakeStrums);
			var context = new psychlua.backend.LuaHostContext(psychlua.backend.LuaHostKind.NONE, 'underworld-test', host);
			var script = new psychlua.backend.FunkinLua(underworldPath, context, false);
			check(script.lua != null, 'Underworld Lua failed to load');
			check(llua.LuaL.dostring(script.lua, 'function makeLuaSprite() end; function makeGraphic() end; '
				+ 'function setScrollFactor() end; function addLuaSprite() end; function setProperty() end; '
				+ 'function getObjectOrder() return 1 end; function setObjectOrder() end; function getRandomInt(a,b) return a==1 and 1 or 0 end; '
				+ 'function callOnLuas(name,args) selectedSkin=args[1] end; '
				+ 'function underworldProbe() onCreate(); onCreatePost(); curBeat=96; onBeatHit(); onUpdate(0.016); '
				+ 'local a=selectedSkin; curBeat=160; onBeatHit(); return a..":"..selectedSkin end') == 0,
				'Underworld Lua test setup failed');
			check(script.call('underworldProbe', []) == 'noteSkins/cyber:galaxy/NOTE_assets',
				'Underworld did not switch and restore the Galaxy skin');
			script.stop();
			fakeStrums.destroy();
		}
		var cyberPath = Sys.getEnv('PLUS_TEST_CYBER_LUA');
		if (cyberPath != null && sys.FileSystem.exists(cyberPath))
		{
			report = 'Cyber real Lua modifier bridge';
			var fakeStrums = new FlxTypedGroup<FlxSprite>();
			for (i in 0...8)
				fakeStrums.add(new FlxSprite((i < 4 ? 50 : 690) + (i % 4) * 112, 50));
			var fakeHost = new CyberTestHost(fakeStrums);
			var luaContext = new psychlua.backend.LuaHostContext(psychlua.backend.LuaHostKind.NONE, 'cyber-test', fakeHost);
			var lua = new psychlua.backend.FunkinLua(cyberPath, luaContext, false);
			check(lua.lua != null, 'Cyber Lua failed to load');
			check(lua.context.host == fakeHost && Reflect.field(fakeHost, 'songSpeed') == 2, 'Cyber test host was lost');
			var otherContext = new psychlua.backend.LuaHostContext(psychlua.backend.LuaHostKind.NONE, 'other-test', {songSpeed: 99});
			var otherLua = new psychlua.backend.FunkinLua('function unrelated() return true end', otherContext, false);
			check(otherLua.lua != null, 'Second Lua state failed to load');
			@:privateAccess var cyberCallbackKey = Lua_helper.callbackKey(lua.lua, 'createModifier');
			@:privateAccess var otherCallbackKey = Lua_helper.callbackKey(otherLua.lua, 'createModifier');
			check(cyberCallbackKey != otherCallbackKey, 'Different Lua states shared a callback key');
			var setup = 'downscroll=false; scrollSpeed=2; function getSongPosition() return 75000 end; '
				+ 'function cyberProbe() local a,b=pcall(getProperty,"strumLineNotes.length"); local c,d=pcall(getPropertyFromGroup,"strumLineNotes",0,"x"); return tostring(a)..":"..tostring(b).."/"..tostring(c)..":"..tostring(d) end; '
				+ 'function cyberTestUpdate() local ok,e=pcall(onUpdatePost,0.016); return tostring(ok)..":"..tostring(e) end';
			check(llua.LuaL.dostring(lua.lua, setup) == 0, 'Cyber test setup failed');
			lua.call('onCreatePost', []);
			var updateResult = lua.call('cyberTestUpdate', []);
			var beforeProbe = lua.call('cyberProbe', []);
			var targetBefore = psychlua.backend.LuaUtils.getTargetInstance() == fakeHost;
			var scriptBefore = psychlua.backend.FunkinLua.lastCalledScript == lua;
			var contextBefore = lua.context == luaContext && lua.context.host == fakeHost;
			var cyberField = parentManager.playfields[0];
			check(cyberField.modifiers.modifiers.exists('cybermotion'), 'Cyber Lua modifier did not register');
			var cyberModifier:modchart.engine.modifiers.LuaModifier = cast cyberField.modifiers.modifiers.get('cybermotion');
			check(cyberModifier.funk == lua, 'Cyber modifier was bound to a different Lua script');
			cyberField.beginFrame(75, 75000, 0);
			var cyberData:modchart.backend.core.ArrowData = {hitTime: 75500, sourceTime: 75500, strumTime: 75500,
				sampleTime: 75500, distance: 500, player: 0, lane: 0, isTapArrow: true};
			var cyberOutput = cyberField.getNotePath(new Vector3(106, 106, 0), cyberData);
			var cyberRow = 300 - Math.sin(((75000 - 70280.899) / 1348.31460674 - 0.5) * Math.PI) * 250;
			var expectedY = cyberRow + 450 * ((300 - cyberRow) / 250) + 56;
			var targetMatches = psychlua.backend.LuaUtils.getTargetInstance() == fakeHost;
			var propertyCallback:Dynamic = Lua_helper.get_callback(lua.lua, 'getProperty');
			var directProperty:Dynamic = propertyCallback == null ? 'missing' : Reflect.callMethod(null, propertyCallback, ['songSpeed']);
			check(Math.abs(cyberOutput.rawY - expectedY) < 0.1,
				'Cyber Lua modifier did not transform a real Manager note: ${cyberOutput.rawY} != $expectedY; update=$updateResult; before=$beforeProbe/$targetBefore/$scriptBefore/$contextBefore; target=$targetMatches; direct=$directProperty; probe=${lua.call("cyberProbe", [])}');
			cyberSummary += '\nCyber real Lua modifier: PASS';
			otherLua.stop();
			check(!Lua_helper.callbacksByState.exists(otherCallbackKey), 'Closed Lua state retained callbacks');
			cyberField.beginFrame(76, 75000, 0);
			cyberOutput = cyberField.getNotePath(new Vector3(106, 106, 0), cyberData);
			check(Math.abs(cyberOutput.rawY - expectedY) < 0.1, 'Closing another Lua state broke Cyber callbacks');
			report = 'Lua hold direction per sample';
			check(llua.LuaL.dostring(lua.lua, 'function testHoldVisual(v,p) if p.isHoldBody then v.holdDirection=p.lane+1 end return v end; '
				+ 'function installHoldTest() return createModifier("holdTest",{visuals="testHoldVisual",target="note",alwaysRun=true}) end') == 0,
				'Hold direction test script failed to load');
			lua.call('installHoldTest', []);
			cyberData.isHoldBody = true;
			cyberField.beginFrame(77, 75000, 0);
			cyberOutput = cyberField.getNotePath(new Vector3(106, 106, 0), cyberData);
			check(cyberOutput.visuals.holdDirection == 1, 'Lua hold direction was not preserved in cached output');
			cyberData.lane = 1;
			cyberOutput = cyberField.getNotePath(new Vector3(218, 106, 0), cyberData);
			check(cyberOutput.visuals.holdDirection == 2, 'Hold direction did not vary per lane');
			cyberData.isHoldBody = false;
			cyberField.beginFrame(78, 75000, 0);
			cyberOutput = cyberField.getNotePath(new Vector3(218, 106, 0), cyberData);
			check(cyberOutput.visuals.holdDirection == 0, 'Hold direction leaked to another sample');
			report = 'Lua modifier visual fast path';
			check(!lua.isKnownMissingHook('missingHoldVisual'), 'Unresolved hook was marked missing prematurely');
			lua.call('missingHoldVisual', []);
			check(lua.isKnownMissingHook('missingHoldVisual'), 'Missing hook was not cached');
			lua.set('missingHoldVisual', 1);
			check(!lua.isKnownMissingHook('missingHoldVisual'), 'Updating a Lua global did not invalidate its hook cache');
			check(llua.LuaL.dostring(lua.lua, 'function fastVisualProbe(v,p) return setmetatable({scaleX=2.5,alpha="0.35",holdDirection=3,planeYZ=-0.002,scaleY="invalid"}, {__index={glow=0.9}}) end; '
				+ 'function fastVisualBenchmark(v,p) v.alpha=0.75; v.planeYZ=-0.002; return v end') == 0,
				'Lua visual fast path setup failed');
			var visualFields = ['scaleX', 'scaleY', 'alpha', 'glow', 'glowR', 'glowG', 'glowB', 'angleX', 'angleY', 'angleZ',
				'fieldAngleX', 'fieldAngleY', 'fieldAngleZ', 'skewX', 'skewY', 'holdDirection', 'holdAngle', 'holdWidth', 'holdSection',
				'planeXX', 'planeXY', 'planeXZ', 'planeYX', 'planeYY', 'planeYZ'];
			var fastVisual:modchart.backend.core.VisualParameters = {};
			var probeArgs:Array<Dynamic> = [{}, {}, 'probe'];
			lua.callModifierVisuals('fastVisualProbe', probeArgs, fastVisual, visualFields);
			check(fastVisual.scaleX == 2.5 && fastVisual.scaleY == 1 && Math.abs(fastVisual.alpha - 0.35) < 0.00001
				&& fastVisual.holdDirection == 3 && fastVisual.planeYZ == -0.002 && fastVisual.glow == 0,
				'Lua visual fast path changed numeric, string, invalid or metatable handling');
			if (Sys.getEnv('PLUS_TEST_HOLD_BENCH') == '1') {
				var source:Dynamic = {};
				for (field in visualFields) Reflect.setField(source, field, 1.0);
				var benchArgs:Array<Dynamic> = [source, {songTime: 1000., distance: 100., lane: 1, player: 0}, 'bench'];
				var rounds = 10000;
				var start = haxe.Timer.stamp();
				for (_ in 0...rounds) {
					var value:Dynamic = lua.call('fastVisualBenchmark', benchArgs);
					for (field in visualFields) {
						var v = Reflect.field(value, field);
						if (v != null) Reflect.setField(fastVisual, field, v);
					}
				}
				var oldMs = (haxe.Timer.stamp() - start) * 1000;
				start = haxe.Timer.stamp();
				for (_ in 0...rounds) lua.callModifierVisuals('fastVisualBenchmark', benchArgs, fastVisual, visualFields);
				var newMs = (haxe.Timer.stamp() - start) * 1000;
				cyberSummary += '\nLua visuals benchmark: legacy ' + Std.int(oldMs) + ' ms; fast ' + Std.int(newMs) + ' ms / ' + rounds;
			}
			lua.stop();
			fakeStrums.destroy();
		}
		var destinyPath = Sys.getEnv('PLUS_TEST_DESTINY_LUA');
		if (destinyPath != null && sys.FileSystem.exists(destinyPath))
		{
			report = 'Destiny Lua phases';
			var destinyManager = parentManager;
			var strums = new FlxTypedGroup<FlxSprite>();
			for (i in 0...8) strums.add(new FlxSprite((i < 4 ? 50 : 690) + (i % 4) * 112, 50));
			var host = new CyberTestHost(strums);
			var context = new psychlua.backend.LuaHostContext(psychlua.backend.LuaHostKind.NONE, 'destiny-test', host);
			var script = new psychlua.backend.FunkinLua(destinyPath, context, false);
			check(script.lua != null, 'Destiny Lua failed to load');
			check(llua.LuaL.dostring(script.lua, 'downscroll=false; scrollSpeed=2; screenWidth=1280; screenHeight=720; '
				+ 'function getSongPosition() return 1000 end') == 0, 'Destiny test setup failed');
			script.call('onCreatePost', []);
			script.call('onUpdatePost', []);
			var field = destinyManager.playfields[0];
			check(field.modifiers.modifiers.exists('destinymotion'), 'Destiny modifier did not register');
			for (time in [1000., 18000., 30000., 45000., 70000., 100000., 120000.]) {
				field.beginFrame(Std.int(time), time, time / (60000 / 151));
				var data:modchart.backend.core.ArrowData = {hitTime: time + 300, sourceTime: time + 300, strumTime: time + 300,
					sampleTime: time + 300, distance: 300, player: 0, lane: 0, isTapArrow: true, isHoldBody: true};
				var output = field.getNotePath(new Vector3(106, 106, 0), data);
				check(Math.isFinite(output.rawX) && Math.isFinite(output.rawY) && Math.isFinite(output.rawZ),
					'Destiny produced invalid coordinates at ' + time);
				if (time == 1000)
					check(output.visuals.holdDirection == 2 && Math.abs(output.rawX - 106) > 1,
						'Destiny opening orbit or hold direction did not run');
				if (time == 30000) {
					var expected = 640 + (100 + Math.sin(30300 / (120000 / 151) * Math.PI) * 150 - 640) * 0.7;
					check(Math.abs(output.rawX - expected) < 0.01 && output.visuals.holdDirection == 1,
						'Destiny orbit did not transform the hold');
				}
			}
			field.beginFrame(999, 15500, 15500 / (60000 / 151));
			var ringData:modchart.backend.core.ArrowData = {hitTime: 15994, sourceTime: 15894.0397, strumTime: 15994,
				sampleTime: 15994, distance: 494, player: 0, lane: 0, isTapArrow: true, isHoldBody: true};
			var ring = field.getNotePath(new Vector3(106, 106, 0), ringData);
			check(ring.visuals.holdDirection == 3 && ring.visuals.holdAngle > 80 && ring.visuals.holdAngle < 100,
				'Destiny circular hold did not orient its width radially');
			check(ring.visuals.holdWidth == 90, 'Destiny circle did not cover the radius');
			ringData.player = 1;
			field.beginFrame(1001, 15500, 15500 / (60000 / 151));
			ring = field.getNotePath(new Vector3(746, 106, 0), ringData);
			check(ring.visuals.holdDirection == 3 && ring.visuals.holdWidth == 90,
				'Destiny player circular hold did not match the chart');
			ringData.isHoldBody = false;
			ringData.hitTime = ringData.sourceTime = ringData.strumTime = ringData.sampleTime = 16291.3907;
			field.beginFrame(1004, 16000, 16000 / (60000 / 151));
			var circleEnd = field.getNotePath(new Vector3(746, 106, 0), ringData);
			check(Math.abs(circleEnd.rawX - 168) < 0.001 && Math.abs(circleEnd.rawY - 150) < 0.001
				&& circleEnd.visuals.scaleX < 1, 'Destiny circular hold end used the regular scroll');
			ringData.player = 0;
			ringData.isHoldBody = true;
			ringData.strumTime = 9550;
			ringData.sourceTime = 9300;
			ringData.sampleTime = ringData.hitTime = 9520;
			ringData.distance = 520;
			field.beginFrame(1002, 9000, 9000 / (60000 / 151));
			var beforeSplit = field.getNotePath(new Vector3(106, 106, 0), ringData);
			ringData.sampleTime = ringData.hitTime = 9550;
			ringData.distance = 550;
			var afterSplit = field.getNotePath(new Vector3(106, 106, 0), ringData);
			check(beforeSplit.visuals.holdSection == 0 && afterSplit.visuals.holdSection == 1,
				'Destiny hold did not split at the trajectory change');
			check(llua.LuaL.dostring(script.lua, 'function getSongPosition() return 45000 end; function makeLuaStrumLine() return false end') == 0,
				'Destiny 3D test setup failed');
			script.call('onUpdatePost', []);
			field.beginFrame(1000, 45000, 45000 / (60000 / 151));
			ringData.hitTime = ringData.sourceTime = ringData.strumTime = ringData.sampleTime = 45300;
			ringData.isHoldBody = false;
			var plane = field.getNotePath(new Vector3(106, 106, 0), ringData).visuals;
			var nx = plane.planeXX * plane.planeXX + plane.planeXY * plane.planeXY + Math.pow(plane.planeXZ * 200, 2);
			var ny = plane.planeYX * plane.planeYX + plane.planeYY * plane.planeYY + Math.pow(plane.planeYZ * 200, 2);
			var dot = plane.planeXX * plane.planeYX + plane.planeXY * plane.planeYY + plane.planeXZ * plane.planeYZ * 40000;
			check(Math.abs(nx - 1) < 0.0001 && Math.abs(ny - 1) < 0.0001 && Math.abs(dot) < 0.0001
				&& Math.abs(plane.planeXZ) + Math.abs(plane.planeYZ) > 0.00001, 'Destiny 3D plane basis was distorted');
			check(llua.LuaL.dostring(script.lua, 'local oldGet=getProperty; local oldGroup=getPropertyFromGroup; '
				+ 'function getSongPosition() return 65000 end; function makeLuaStrumLine() return false end; '
				+ 'function makeLuaSprite() end; function setObjectCamera() end; function addLuaSprite() end; '
				+ 'function setProperty(k,v) if k=="destinyCount1.x" then counterX=v elseif k=="destinyCount1.y" then counterY=v end end; function scaleObject() end; '
				+ 'function getProperty(k) if string.find(k,"destinyCount") then '
				+ 'if string.find(k,"frameWidth") then return 100 elseif string.find(k,"frameHeight") then return 130 '
				+ 'elseif string.find(k,"origin.x") then return 50 elseif string.find(k,"origin.y") then return 65 else return 0 end end return oldGet(k) end; '
				+ 'function getPropertyFromGroup(g,i,k) if g=="notes" then if k=="strumTime" then return 65165.5629 elseif k=="mustPress" then return false end end return oldGroup(g,i,k) end; '
				+ 'function loadGraphic(tag,image) counterResult=tag..":"..image end; '
				+ 'function testDestinyCounter() local ok,e=pcall(onUpdatePost); if not ok then return tostring(e) end; goodNoteHit(0,3,"",false); return counterResult end; '
				+ 'function testCounterCenter() local beat=60000/151; local tm=65165.5629; local z=200+1050*((tm-65000)/beat)/2; local s=200/z; '
				+ 'local x=640+300*math.cos(tm/(beat*2)*math.pi); local y=360+200*math.sin(tm/(beat*2)*math.pi); '
				+ 'return math.max(math.abs(counterX+50-(640+(x-640)*s)),math.abs(counterY+65-(360+(y-360)*s))) end') == 0,
				'Destiny counter test setup failed');
			check(script.call('testDestinyCounter', []) == 'destinyCount1:num3', 'Destiny counter did not update after a hit');
			check((cast script.call('testCounterCenter', []):Float) < 0.001, 'Destiny counter was not centered on the projected note');
			field.beginFrame(1003, 65000, 65000 / (60000 / 151));
			ringData.player = 1; ringData.lane = 3; ringData.isHoldBody = false;
			ringData.hitTime = ringData.sourceTime = ringData.strumTime = ringData.sampleTime = 65165.5629;
			var groupedFirst = field.getNotePath(new Vector3(746, 106, 0), ringData);
			ringData.hitTime = ringData.sourceTime = ringData.strumTime = ringData.sampleTime = 65364.2384;
			var groupedNext = field.getNotePath(new Vector3(746, 106, 0), ringData);
			check(Math.abs(groupedFirst.rawX - groupedNext.rawX) < 0.001
				&& Math.abs(groupedFirst.rawY - groupedNext.rawY) < 0.001 && Math.abs(groupedFirst.rawZ - groupedNext.rawZ) < 0.001,
				'Destiny grouped player notes did not share their counter position and depth');
			script.stop();
			strums.destroy();
		}
		var peacePath = Sys.getEnv('PLUS_TEST_PEACE_LUA');
		if (peacePath != null && sys.FileSystem.exists(peacePath))
		{
			report = 'Peace Lua chart markers and echo';
			var savedSong = states.PlayState.SONG;
			var peaceSong = fixture(39000);
			peaceSong.notes[0].sectionNotes = [[39000, 0.01, 300, '']];
			var peaceChartPath = Sys.getEnv('PLUS_TEST_PEACE_CHART');
			var realPeaceChart = peaceChartPath != null && sys.FileSystem.exists(peaceChartPath);
			if (realPeaceChart) {
				peaceSong = Song.parseJSON(sys.io.File.getContent(peaceChartPath));
			}
			states.PlayState.SONG = peaceSong;
			var strums = new FlxTypedGroup<FlxSprite>();
			for (i in 0...8) strums.add(new FlxSprite((i < 4 ? 50 : 690) + (i % 4) * 112, 50));
			var host = new CyberTestHost(strums);
			var context = new psychlua.backend.LuaHostContext(psychlua.backend.LuaHostKind.NONE, 'peace-test', host);
			var script = new psychlua.backend.FunkinLua(peacePath, context, false);
			check(script.lua != null, 'Peace Lua failed to load');
			check(llua.LuaL.dostring(script.lua, 'difficulty=2; downscroll=false; scrollSpeed=2; screenWidth=1280; screenHeight=720; testTime=1000; '
				+ 'function getSongPosition() return testTime end; function makeLuaStrumLine() return false end') == 0,
				'Peace test setup failed');
			script.call('onCreatePost', []);
			script.call('onUpdatePost', []);
			var field = parentManager.playfields[0];
			check(field.modifiers.modifiers.exists('peacemotion'), 'Peace modifier did not register on main playfield');
			field.beginFrame(1100, 38500, 38500 / 300);
			var markerTime = realPeaceChart ? 38625. : 39000.;
			var data:modchart.backend.core.ArrowData = {hitTime: markerTime, sourceTime: markerTime, strumTime: markerTime,
				sampleTime: markerTime, distance: 500, player: realPeaceChart ? 0 : 1, lane: realPeaceChart ? 2 : 0,
				isTapArrow: true, isHoldBody: false};
			var arc = field.getNotePath(new Vector3(746, 106, 0), data);
			var expectedX = 640 + Math.cos(markerTime / 600 * Math.PI) * 500;
			check(Math.abs(arc.rawX - (640 + (expectedX - 640) * 0.7)) < 0.01,
				'Peace special chart marker did not select the arc');
			if (realPeaceChart) {
				field.beginFrame(1102, 136600, 136600 / 300);
				data.hitTime = data.sourceTime = data.strumTime = data.sampleTime = 136650;
				data.distance = 50;
				data.player = 0;
				data.lane = 1;
				var lateArc = field.getNotePath(new Vector3(746, 106, 0), data);
				var lateX = 940 - Math.cos(136650 / 600 * Math.PI) * 200;
				check(Math.abs(lateArc.rawX - (640 + (lateX - 640) * 0.7)) < 0.01,
					'Peace restored marker did not select the second late arc');
			}
			check(llua.LuaL.dostring(script.lua, 'function peacePhaseProbe() '
				+ 'for _,t in ipairs({20000,39000,50000,60000,70000,80000,96000,106000,116000,125000,135000,154000,173000}) do '
				+ 'for side=0,1 do for body=0,1 do local p={player=side,lane=2,songTime=t-100,strumTime=t,sampleTime=t,sourceTime=t-75,distance=100,isTapArrow=true,isHoldBody=body==1}; '
				+ 'local v={alpha=1,angleZ=0,scaleX=1,scaleY=1,planeXX=1,planeXY=0,planeXZ=0,planeYX=0,planeYY=1,planeYZ=0}; '
				+ 'local ok,pos=pcall(peaceRender,{x=0,y=0,z=0},p); if not ok or pos.x~=pos.x or pos.y~=pos.y or pos.z~=pos.z then return tostring(pos) end; '
				+ 'local valid,result=pcall(peaceVisuals,v,p); if not valid then return tostring(result) end end end end return true end') == 0,
				'Peace phase test setup failed');
			check(script.call('peacePhaseProbe', []) == true, 'Peace phase callback failed');
			check(llua.LuaL.dostring(script.lua, 'testTime=115400') == 0, 'Peace echo time setup failed');
			script.call('onUpdatePost', []);
			var echo = parentManager.getNamedPlayfield('peaceEcho');
			check(echo != null && echo.modifiers.modifiers.exists('peaceechomotion'), 'Peace echo playfield did not activate');
			field.beginFrame(1101, 115400, 115400 / 300);
			echo.beginFrame(1101, 115400, 115400 / 300);
			data.hitTime = data.sourceTime = data.strumTime = data.sampleTime = 116000;
			data.distance = 600;
			var mainOutput = field.getNotePath(new Vector3(746, 106, 0), data);
			var echoOutput = echo.getNotePath(new Vector3(746, 106, 0), data);
			check(Math.abs((mainOutput.rawZ - echoOutput.rawZ) - 5.6) < 0.001
				&& echoOutput.visuals.alpha > 0, 'Peace echo depth or visibility was incorrect');
			check(llua.LuaL.dostring(script.lua, 'testTime=140000') == 0, 'Peace echo end setup failed');
			script.call('onUpdatePost', []);
			check(parentManager.getNamedPlayfield('peaceEcho') == null, 'Peace echo playfield did not deactivate');
			script.stop();
			strums.destroy();
			states.PlayState.SONG = savedSong;
		}
		#end
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
		report = 'splash follows receptor modifiers';
		var attachmentField = parentManager.playfields[0];
		attachmentField.setPercent('receptorX', 123, 0);
		attachmentField.setPercent('noteX', 999, 0);
		attachmentField.beginFrame(76, 500, 1);
		var attachmentData:modchart.backend.core.ArrowData = {hitTime: 500, distance: 0, sourceTime: 500,
			player: 0, lane: 0, isTapArrow: false};
		var receptorOutput = attachmentField.getReceptorPath(new Vector3(), attachmentData);
		var splashOutput = attachmentField.getSplashPath(new Vector3(), attachmentData);
		check(Math.abs(receptorOutput.rawX - splashOutput.rawX) < 0.001 && Math.abs(splashOutput.rawX - 123) < 0.001,
			'Splash did not follow receptor or picked up note-only transforms');
		attachmentField.setPercent('receptorX', 0, 0);
		attachmentField.setPercent('noteX', 0, 0);
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
		report = '\nSubmodifier parent auto-install: PASS' + cyberSummary + anomalySummary;
	}
}

private class CyberTestHost extends flixel.FlxState
{
	public var songSpeed:Float = 2;
	public var strumLineNotes:FlxTypedGroup<FlxSprite>;
	public var camHUD:FlxCamera = new FlxCamera();
	public var camGame:FlxCamera = new FlxCamera();
	public var defaultCamZoom:Float = 1;
	public var camZooming:Bool = false;
	public var cameraBopEnabled:Bool = false;

	public function new(strums:FlxTypedGroup<FlxSprite>)
	{
		super();
		strumLineNotes = strums;
	}
}
#end
