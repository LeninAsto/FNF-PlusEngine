package modchart.backend.standalone;

import haxe.macro.Compiler;
import modchart.backend.standalone.adapters.psych.Psych;

class Adapter {
	public static var instance:IAdapter;
	private static var ENGINE_NAME:String = Compiler.getDefine("FM_ENGINE");

	public static function init() {
		if (instance != null)
			return;

		trace('[FunkinModchart] Initializing adapter for engine: $ENGINE_NAME');
		
		// Direct instantiation instead of reflection
		var adapter:IAdapter = null;
		
		switch (ENGINE_NAME.toLowerCase()) {
			case "psych":
				adapter = new Psych();
			default:
				throw 'Adapter not found for engine: $ENGINE_NAME';
		}
		
		if (adapter == null)
			throw 'Adapter could not be instantiated for $ENGINE_NAME';

		trace('[FunkinModchart] Adapter initialized successfully');

		instance = adapter;
	}
}
