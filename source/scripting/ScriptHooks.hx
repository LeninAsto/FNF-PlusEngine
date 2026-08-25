package scripting;

#if HSCRIPT_ALLOWED
class ScriptHooks {
	public static inline var CREATE:String = 'onCreate';
	public static inline var CREATE_POST:String = 'onCreatePost';
	public static inline var DESTROY:String = 'onDestroy';
	public static inline var UPDATE:String = 'onUpdate';
	public static inline var UPDATE_POST:String = 'onUpdatePost';
	public static inline var BEAT_HIT:String = 'onBeatHit';
	public static inline var STEP_HIT:String = 'onStepHit';
	public static inline var SECTION_HIT:String = 'onSectionHit';

	public static inline var GOOD_NOTE_HIT:String = 'goodNoteHit';
	public static inline var GOOD_NOTE_HIT_PRE:String = 'goodNoteHitPre';
	public static inline var OPPONENT_NOTE_HIT:String = 'opponentNoteHit';
	public static inline var OPPONENT_NOTE_HIT_PRE:String = 'opponentNoteHitPre';
	public static inline var NOTE_MISS:String = 'noteMiss';
	public static inline var NOTE_MISS_PRESS:String = 'noteMissPress';
	public static inline var NOTES_GENERATED:String = 'notesGenerated';
	public static inline var EVENT_EARLY_TRIGGER:String = 'eventEarlyTrigger';
	public static inline var UPDATE_SCORE_PRE:String = 'preUpdateScore';
	public static inline var GAME_OVER_START:String = 'onGameOverStart';
	public static inline var GAME_OVER_CONFIRM:String = 'onGameOverConfirm';
	public static inline var SONG_EXIT:String = 'onSongExit';

	public static final ALIASES:Map<String, String> = [
		'onGoodNoteHit' => GOOD_NOTE_HIT,
		'onGoodNoteHitPre' => GOOD_NOTE_HIT_PRE,
		'onOpponentNoteHit' => OPPONENT_NOTE_HIT,
		'onOpponentNoteHitPre' => OPPONENT_NOTE_HIT_PRE,
		'onNoteMiss' => NOTE_MISS,
		'onNoteMissPress' => NOTE_MISS_PRESS,
		'onEventEarlyTrigger' => EVENT_EARLY_TRIGGER,
		'onUpdateScorePre' => UPDATE_SCORE_PRE,
		'onPreUpdateScore' => UPDATE_SCORE_PRE
	];

	public static function bindHScript(variables:hxscript.runtime.Bindings):Void {
		if (variables == null)
			return;

		for (alias => canonical in ALIASES) {
			if (variables.exists(canonical))
				continue;

			var func:Dynamic = variables.get(alias);
			if (func != null && Reflect.isFunction(func))
				variables.set(canonical, func);
		}
	}
}
#end
