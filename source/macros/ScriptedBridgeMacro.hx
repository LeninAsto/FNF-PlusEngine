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
		{base: 'backend.MusicBeatState'},
		{base: 'backend.MusicBeatSubstate'},
		{base: 'states.PlayState'},
		{base: 'substates.PauseSubState'},
		{base: 'substates.GameOverSubstate'},
		{base: 'objects.Character'},
		{base: 'objects.NoteSplash'},
		{base: 'backend.BaseStage'},
		{base: 'objects.Alphabet'},
		{base: 'objects.Bar'},
		{base: 'objects.HealthIcon'},
		{base: 'psychlua.ModchartSprite'}
	];

	static inline var PACK:String = 'scripting.bridges';

	public static function generate():Void {
		if (!Context.defined('HSCRIPT_ALLOWED'))
			return;

		var pos:Position = Context.currentPos();
		var pack:Array<String> = PACK.split('.');
		var bridgeRefs:Array<Expr> = [];
		var basePaths:Array<Expr> = [];

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
				fields: []
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
}

typedef BridgeEntry = {
	var base:String;
}
#end
