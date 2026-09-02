package scripting;

class ScriptedStages {
	#if HSCRIPT_ALLOWED
	public static function load(stage:String):backend.BaseStage
		return ScriptRegistry.loadStage(stage);

	public static function exists(stage:String):Bool
	{
		if (stage == null || stage.length < 1)
			return false;
		for (name in candidateNames(stage))
			if (ScriptRegistry.resolveClassFile(ScriptRegistry.STAGE_PACKAGE + '.' + name) != null)
				return true;
		return false;
	}

	static function candidateNames(stage:String):Array<String> {
		var capitalized:String = stage.charAt(0).toUpperCase() + stage.substr(1);
		return capitalized == stage ? [stage] : [capitalized, stage];
	}
	#else
	public static function load(stage:String):backend.BaseStage
		return null;

	public static function exists(stage:String):Bool
		return false;
	#end
}
