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
	private var __fCrochet:Float = 0;
	private var __holdSubdivisions:Int = 0;

	inline function getEditorState():Dynamic {
		return null; // ModchartEditorState.instance;
	}

	public function new() {
		try {
			setupLuaFunctions();
		} catch (e) {
			trace('[FunkinModchart Psych Adapter] Failed while adding lua functions: $e');
		}
	}

	public function onModchartingDispose() {}

	public function onModchartingInitialization() {
		__fCrochet = (Conductor.crochet + 8) / 4;
		__holdSubdivisions = 4;
	}

	private function setupLuaFunctions() {
		#if LUA_ALLOWED
		// todo
		#end
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
		return __fCrochet;

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
		var strum = getStrumFromInfo(lane, player);
		return strum != null ? strum.x : 0;
	}

	public function getDefaultReceptorY(lane:Int, player:Int):Float {
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
		return PlayState.instance.songSpeed * .45;
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

		var pspr:Array<Array<Array<FlxSprite>>> = [[[], [], [], []], [[], [], [], []]];

		@:privateAccess
		PlayState.instance.strumLineNotes.forEachAlive(strumNote -> {
			final player = resolveStrumPlayer(strumNote);
			if (pspr[player] == null)
				pspr[player] = [];

			pspr[player][0].push(strumNote);
		});
		PlayState.instance.notes.forEachAlive(strumNote -> {
			final player = Adapter.instance.getPlayerFromArrow(strumNote);
			if (pspr[player] == null)
				pspr[player] = [];

			pspr[player][strumNote.isSustainNote ? 2 : 1].push(strumNote);
		});
		PlayState.instance.grpNoteSplashes.forEachAlive(splash -> {
			@:privateAccess
			if (splash.babyArrow != null && splash.active) {
				final player = resolveSplashPlayer(splash);
				if (pspr[player] == null)
					pspr[player] = [];

				pspr[player][3].push(splash);
			}
		});

		return pspr;
	}
}
