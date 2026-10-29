package macros;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;

class ScriptedBridgeMacro {
	static final BASES:Array<BridgeEntry> = [
		{base: 'flixel.FlxBasic'},
		{base: 'flixel.FlxObject'},
		{base: 'flixel.FlxSprite'},
		{base: 'flixel.group.FlxGroup'},
		{base: 'flixel.group.FlxSpriteGroup'},
		{base: 'flixel.text.FlxText'},
		{base: 'backend.MusicBeatState', state: true},
		{base: 'backend.MusicBeatSubstate'},
		{base: 'states.TitleState', state: true},
		{base: 'states.MainMenuState', state: true},
		{base: 'states.FreeplayState', state: true},
		{base: 'states.FreeplayState_Psych', state: true},
		{base: 'states.PlayState', state: true},
		{base: 'substates.PauseSubState'},
		{base: 'substates.GameOverSubstate'},
		{base: 'objects.Character'},
		{base: 'objects.NoteSplash'},
		{base: 'backend.BaseStage'},
		{base: 'objects.Alphabet'},
		#if (haxe_ver < 5.0)
		{base: 'objects.Bar'},
		#end
		{base: 'objects.HealthIcon'},
		{base: 'psychlua.backend.ModchartSprite'}
	];

	static inline var PACK:String = 'scripting.bridges';

	public static function generate():Void {
		#if (haxe_ver >= 5.0)
		// Haxe 5 restricts type-dependent work in init macros, but generated
		// bridge modules must still exist before the engine's source is typed.
		Context.onAfterInitMacros(() -> generateNow());
		#else
		generateNow();
		#end
	}

	static function generateNow():Void {
		if (!Context.defined('HSCRIPT_ALLOWED'))
			return;

		var pos:Position = Context.currentPos();
		var pack:Array<String> = PACK.split('.');
		var bridgeRefs:Array<Expr> = [];
		var basePaths:Array<Expr> = [];
		#if (haxe_ver >= 5.0)
		// Force bridge bases to finish typing before their generated subclasses are
		// introduced. Haxe 5 keeps these class references lazy by default.
		for (entry in BASES)
			Context.getType(entry.base);
		#end

		for (entry in BASES) {
			var superPath:TypePath = toTypePath(entry.base);
			var name:String = 'Scripted' + superPath.name;
			var interfaces:Array<TypePath> = [{pack: ['hxscript'], name: 'IScripted'}];

			Context.defineModule('$PACK.$name', [{
				pack: pack,
				name: name,
				pos: pos,
				meta: [{name: ':keep', pos: pos}],
				kind: TDClass(superPath, interfaces, false, false, false),
				fields: entry.state == true ? [stateTryUpdateField(pos)] : []
			}]);

			bridgeRefs.push(macro $p{pack.concat([name])});
			basePaths.push(macro $v{entry.base});
		}

		Context.defineModule('$PACK.Bridges', [{
			pack: pack,
			name: 'Bridges',
			pos: pos,
			meta: [{name: ':keep', pos: pos}],
			kind: TDClass(null, [], false, false, false),
			fields: [
				{
					name: 'all',
					access: [APublic, AStatic],
					pos: pos,
					kind: FVar(macro :Array<Class<Dynamic>>, {expr: EArrayDecl(bridgeRefs), pos: pos})
				},
				{
					name: 'bases',
					access: [APublic, AStatic],
					pos: pos,
					kind: FVar(macro :Array<String>, {expr: EArrayDecl(basePaths), pos: pos})
				}
			]
		}]);

		Context.info('ScriptedBridgeMacro: generated ${BASES.length} hxscript bridge(s)', pos);
	}

	static function toTypePath(path:String):TypePath {
		var parts:Array<String> = path.split('.');
		var name:String = parts.pop();
		return {pack: parts, name: name};
	}

	static function stateTryUpdateField(pos:Position):Field {
		return {
			name: 'tryUpdate',
			access: [AOverride],
			pos: pos,
			kind: FFun({
				args: [{name: 'elapsed', type: macro :Float}],
				ret: macro :Void,
				expr: macro {
					@:privateAccess
					{
						if (!persistentUpdate && subState != null)
						{
							if (_requestSubStateReset)
							{
								_requestSubStateReset = false;
								resetSubState();
							}
							if (subState != null)
								subState.tryUpdate(elapsed);
							return;
						}
					}
					super.tryUpdate(elapsed);
				}
			})
		};
	}
}

typedef BridgeEntry = {
	var base:String;
	@:optional var state:Bool;
}
#end
