package modchart.backend.standalone.adapters.psych;

import states.stages.objects.DadBattleFog;
import backend.Conductor;
//import funkin.ui.debug.modcharting.ModchartEditorState;
import objects.Note;
import objects.NoteSplash;
import objects.StrumNote as Strum;
import states.PlayState;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxSprite;
import modchart.backend.standalone.IAdapter;

class Psych implements IAdapter {
	private var holdStepLength:Float = 0;
	private var __holdSubdivisions:Int = 0;
	private var __cachedFrame:Int = -1;
	private var __cachedScrollSpeed:Float = 0;
	private var __receptorX:Array<Array<Float>> = [[0, 0, 0, 0], [0, 0, 0, 0]];
	private var __receptorY:Array<Array<Float>> = [[0, 0, 0, 0], [0, 0, 0, 0]];
	private var arrowItemsByPlayer:Array<Array<Array<FlxSprite>>> = [
		[[], [], [], []],
		[[], [], [], []]
	];

	inline function getEditorState():Dynamic {
		return null; // ModchartEditorState.instance;
	}

	public function new() {}

	public function onModchartingDispose() {}

	public function beginModchartFrame(frameId:Int):Void {
		if (__cachedFrame == frameId)
			return;
		__cachedFrame = frameId;
		if (PlayState.instance == null)
			return;

		__cachedScrollSpeed = PlayState.instance.songSpeed * .45;
		cacheReceptors(PlayState.instance.opponentStrums, 0);
		cacheReceptors(PlayState.instance.playerStrums, 1);
	}

	private function cacheReceptors(group:Dynamic, player:Int):Void {
		if (group == null || group.members == null)
			return;
		final xs = __receptorX[player];
		final ys = __receptorY[player];
		final members:Array<Dynamic> = group.members;
		for (i in 0...members.length) {
			final strum:Strum = cast members[i];
			if (strum == null || !strum.exists)
				continue;
			@:privateAccess final lane = strum.noteData;
			if (lane < 0)
				continue;
			while (xs.length <= lane) { xs.push(0); ys.push(0); }
			xs[lane] = strum.x;
			ys[lane] = getDownscroll() ? FlxG.height - strum.y - Note.swagWidth : strum.y;
		}
	}

	public function onModchartingInitialization() {
		holdStepLength = (Conductor.crochet + 8) / 4;
		__holdSubdivisions = 4;
	}

	public function isTapNote(sprite:FlxSprite) {
		return sprite is Note;
	}

	// Song related
	public function getSongPosition():Float {
		var editorState = getEditorState();
		if (editorState != null)
			return editorState.getModchartSongPosition();
		if (ModchartEditorPreviewContext.active != null)
			return ModchartEditorPreviewContext.active.songPosition;
		return Conductor.songPosition;
	}

	public function getCurrentBeat():Float {
		var editorState = getEditorState();
		if (editorState != null)
			return editorState.getModchartCurrentBeat();
		/*
		if (ModchartEditorPreviewContext.active != null)
			return ModchartEditorPreviewContext.active.currentBeat;
		 */
		if (PlayState.instance != null) {
			@:privateAccess
			return PlayState.instance.curDecBeat;
		}
		return 0;
	}

	public function getCurrentCrochet():Float {
		return Conductor.crochet;
	}

	public function getBeatFromStep(step:Float)
		return step * .25;

	public function arrowHit(arrow:FlxSprite) {
		if (arrow is Note)
			return cast(arrow, Note).wasGoodHit;
		return false;
	}

	public function isHoldEnd(arrow:FlxSprite) {
		if (arrow is Note) {
			final castedNote = cast(arrow, Note);

			if (castedNote.isSustainEnd)
				return true;
			// Old/runtime-created notes may not have the explicit flag. The active
			// animation is a safer fallback than relying only on chart order.
			if (castedNote.isSustainNote && castedNote.animation != null
				&& castedNote.animation.curAnim != null
				&& castedNote.animation.curAnim.name.endsWith('holdend'))
				return true;
			if (castedNote.nextNote != null)
				return !castedNote.nextNote.isSustainNote;
		}
		return false;
	}

	public function getLaneFromArrow(arrow:FlxSprite) {
		if (arrow is Note)
			return cast(arrow, Note).noteData;
		else if (arrow is Strum) @:privateAccess
			return cast(arrow, Strum).noteData;
		if (arrow is NoteSplash) @:privateAccess
			return cast(arrow, NoteSplash).babyArrow.noteData;

		return 0;
	}

	public function getPlayerFromArrow(arrow:FlxSprite) {
		if (arrow is Note)
			return cast(arrow, Note).mustPress ? 1 : 0;
		if (arrow is Strum)
			return resolveStrumPlayer(cast arrow);
		if (arrow is NoteSplash)
			return resolveSplashPlayer(cast arrow);
		return 0;
	}

	private inline function groupContainsStrum(group:Dynamic, strum:Strum):Bool {
		if (group == null || strum == null)
			return false;

		final members:Array<Dynamic> = group.members;
		return members != null && members.indexOf(strum) != -1;
	}

	private function resolveStrumPlayer(strum:Strum):Int {
		if (strum == null)
			return 0;

		/*
		if (ModchartEditorPreviewContext.active != null) {
			if (groupContainsStrum(ModchartEditorPreviewContext.active.opponentStrums, strum))
				return 0;
			if (groupContainsStrum(ModchartEditorPreviewContext.active.playerStrums, strum))
				return 1;
		}
					 */

		if (PlayState.instance != null) {
			if (groupContainsStrum(PlayState.instance.opponentStrums, strum))
				return 0;
			if (groupContainsStrum(PlayState.instance.playerStrums, strum))
				return 1;
		}

		@:privateAccess return strum.player;
	}

	private inline function resolveSplashPlayer(splash:NoteSplash):Int {
		@:privateAccess
		if (splash != null && splash.babyArrow != null)
			return resolveStrumPlayer(splash.babyArrow);
		return 0;
	}

	public function getKeyCount(?player:Int = 0):Int {
		return 4;
	}

	public function getPlayerCount():Int {
		return 2;
	}

	private function ensurePlayerItems(items:Array<Array<Array<FlxSprite>>>, player:Int):Array<Array<FlxSprite>> {
		if (player < 0)
			player = 0;

		while (items.length <= player)
			items.push([[], [], [], []]);

		var playerItems = items[player];
		if (playerItems == null)
		{
			playerItems = [[], [], [], []];
			items[player] = playerItems;
		}

		while (playerItems.length < 4)
			playerItems.push([]);

		for (i in 0...4)
			if (playerItems[i] == null)
				playerItems[i] = [];

		return playerItems;
	}

	public function getTimeFromArrow(arrow:FlxSprite) {
		if (arrow is Note)
			return cast(arrow, Note).strumTime;

		return 0;
	}

	public function getHoldSubdivisions(hold:FlxSprite):Int {
		return __holdSubdivisions;
	}

	public function setHoldSubdivisions(value:Int):Void {
		__holdSubdivisions = value;
	}

	public function getHoldLength(item:FlxSprite):Float
		return holdStepLength;

	public function getHoldParentTime(arrow:FlxSprite) {
		final note:Note = cast arrow;
		if (note.parent == null) {
			return note.strumTime;
		}
		return note.parent.strumTime;
	}

	public function getDownscroll():Bool {
		return ClientPrefs.data.downScroll;
	}

	inline function getStrumFromInfo(lane:Int, player:Int) {
		var editorState = getEditorState();
		if (editorState != null)
			return editorState.getModchartStrumFromInfo(lane, player);

		/*
		if (ModchartEditorPreviewContext.active != null)
		{
			var previewGroup = player == 0 ? ModchartEditorPreviewContext.active.opponentStrums : ModchartEditorPreviewContext.active.playerStrums;
			var previewStrum = null;
			previewGroup.forEachAlive(str -> {
				@:privateAccess
				if (str.noteData == lane)
					previewStrum = str;
			});
			return previewStrum;
		}
			*/

		var group = player == 0 ? PlayState.instance.opponentStrums : PlayState.instance.playerStrums;
		var strum = null;
		group.forEach(str -> {
			@:privateAccess
			if (str.noteData == lane)
				strum = str;
		});
		return strum;
	}

	public function getDefaultReceptorX(lane:Int, player:Int):Float {
		if (__cachedFrame >= 0 && player >= 0 && player < __receptorX.length && lane >= 0 && lane < __receptorX[player].length)
			return __receptorX[player][lane];
		var strum = getStrumFromInfo(lane, player);
		return strum != null ? strum.x : 0;
	}

	public function getDefaultReceptorY(lane:Int, player:Int):Float {
		if (__cachedFrame >= 0 && player >= 0 && player < __receptorY.length && lane >= 0 && lane < __receptorY[player].length)
			return __receptorY[player][lane];
		var strum = getStrumFromInfo(lane, player);
		if (strum == null) return 0;
		var editorState = getEditorState();
		if (editorState != null)
		{
			var cameras = editorState.getModchartArrowCamera();
			var camHeight = (cameras != null && cameras.length > 0 && cameras[0] != null) ? cameras[0].height : FlxG.height;
			return getDownscroll() ? camHeight - strum.y - Note.swagWidth : strum.y;
		}
		//if (ModchartEditorPreviewContext.active != null)
		//{
		//	var camHeight = ModchartEditorPreviewContext.active.camera.height;
		//	return getDownscroll() ? camHeight - strum.y - Note.swagWidth : strum.y;
		//}
		return getDownscroll() ? FlxG.height - strum.y - Note.swagWidth : strum.y;
	}

	public function getArrowCamera():Array<FlxCamera>
	{
		var editorState = getEditorState();
		if (editorState != null)
			return editorState.getModchartArrowCamera();
		//if (ModchartEditorPreviewContext.active != null)
		//	return [ModchartEditorPreviewContext.active.camera];
		return [PlayState.instance.camHUD];
	}

	public function getCurrentScrollSpeed():Float {
		var editorState = getEditorState();
		if (editorState != null)
			return editorState.getModchartScrollSpeed();
		//if (ModchartEditorPreviewContext.active != null)
		//	return ModchartEditorPreviewContext.active.scrollSpeed;
		return __cachedFrame >= 0 ? __cachedScrollSpeed : PlayState.instance.songSpeed * .45;
	}

	// 0 receptors
	// 1 tap arrows
	// 2 hold arrows
	public function getArrowItems() {
		var editorState = getEditorState();
		if (editorState != null)
			return editorState.getModchartArrowItems();

		/*
		if (ModchartEditorPreviewContext.active != null)
		{
			var preview:Array<Array<Array<FlxSprite>>> = [[[], [], [], []], [[], [], [], []]];

			@:privateAccess
			ModchartEditorPreviewContext.active.strumLineNotes.forEachAlive(strumNote -> {
				final player = resolveStrumPlayer(strumNote);
				if (preview[player] == null)
					preview[player] = [];

				preview[player][0].push(strumNote);
			});

			ModchartEditorPreviewContext.active.notes.forEachAlive(strumNote -> {
				final player = Adapter.instance.getPlayerFromArrow(strumNote);
				if (preview[player] == null)
					preview[player] = [];

				preview[player][strumNote.isSustainNote ? 2 : 1].push(strumNote);
			});

			ModchartEditorPreviewContext.active.noteSplashes.forEachAlive(splash -> {
				@:privateAccess
				if (splash.babyArrow != null && splash.active)
				{
					final player = resolveSplashPlayer(splash);
					if (preview[player] == null)
						preview[player] = [];

					preview[player][3].push(splash);
				}
			});

			return preview;
		}
	     */

		var pspr = arrowItemsByPlayer;
		for (playerItems in pspr)
		{
			if (playerItems == null)
				continue;
			for (bucket in playerItems)
				if (bucket != null)
					bucket.resize(0);
		}

		@:privateAccess final strums = PlayState.instance.strumLineNotes.members;
		for (i in 0...strums.length) {
			final strumNote = strums[i];
			if (strumNote == null || !strumNote.exists || !strumNote.alive)
				continue;
			final player = resolveStrumPlayer(strumNote);
			ensurePlayerItems(pspr, player)[0].push(strumNote);
		}
		final notes = PlayState.instance.notes.members;
		for (i in 0...notes.length) {
			final note = notes[i];
			if (note == null || !note.exists || !note.alive || note.frame == null || note.graphic == null)
				continue;
			final player = note.mustPress ? 1 : 0;
			ensurePlayerItems(pspr, player)[note.isSustainNote ? 2 : 1].push(note);
		}
		final splashes = PlayState.instance.grpNoteSplashes.members;
		for (i in 0...splashes.length) {
			final splash = splashes[i];
			@:privateAccess if (splash == null || !splash.exists || !splash.alive || splash.babyArrow == null || !splash.active)
				continue;
			final player = resolveSplashPlayer(splash);
			ensurePlayerItems(pspr, player)[3].push(splash);
		}

		return pspr;
	}
}
