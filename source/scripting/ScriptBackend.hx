package scripting;

#if HSCRIPT_ALLOWED
import hxscript.types.TypeCollection;

class ScriptBackend {
	public static var initialized(default, null):Bool = false;

	public static function setup():Void {
		if (initialized)
			return;

		initialized = true;
		scripting.hscript.HScript.setupConfig();

		var totalTypes:Int = 0;
		var typeMap = TypeCollection.main.types;
		if (typeMap != null && typeMap.all != null)
			totalTypes = typeMap.all.length;

		var bridgeCount:Int = 0;
		try
			bridgeCount = scripting.bridges.Bridges.bases.length
		catch (e:Dynamic)
			bridgeCount = 0;

		trace('[ScriptBackend] hxscript ready; compiledTypes=$totalTypes bridges=$bridgeCount globals=${ScriptGlobals.registeredCount}');
	}
}
#end
