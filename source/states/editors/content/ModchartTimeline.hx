package states.editors.content;

import haxe.Json;
import modchart.Manager;
import psychlua.backend.LuaUtils;

typedef ModchartTimelineEvent = {
	var kind:String;
	var mod:String;
	var beat:Float;
	var length:Float;
	var value:Float;
	var ease:String;
	var player:Int;
	var field:Int;
}

/** Editable, serializable calls to the same Manager used in gameplay. */
class ModchartTimeline
{
	public var events:Array<ModchartTimelineEvent> = [];
	public var modifiers:Array<String> = [];
	public var fieldCount:Int = 1;
	public var scene:Array<Dynamic> = [];
	public var renderer:Dynamic = {};
	public var warnings:Array<String> = [];
	public function new() {}

	static inline function tr(key:String, fallback:String):String
		return Language.getPhrase('editors.modchart.' + key, fallback);

	public function validate(event:ModchartTimelineEvent):Void
	{
		if (event == null || !['set', 'ease', 'add'].contains(event.kind)) throw tr('event_type', "Unsupported event type");
		if (event.mod == null || event.mod.trim().length == 0) throw tr('missing_modifier', "A modifier is required");
		if (!Math.isFinite(event.beat) || !Math.isFinite(event.length) || event.length < 0
			|| !Math.isFinite(event.value)) throw tr('invalid_numbers', "Beat, duration and value must be finite numbers");
		if (event.player < -1 || event.player > 1 || event.field < -1 || event.field > 15) throw tr('invalid_target', "Player: -1/0/1. Field: -1 to 15");
		if (event.kind != 'set' && event.length <= 0) throw tr('positive_duration', "Ease/Add duration must be greater than zero");
	}

	public function sort():Void
	{
		// Stable order matters when multiple calls share a beat.
		haxe.ds.ArraySort.sort(events, (a, b) -> a.beat < b.beat ? -1 : (a.beat > b.beat ? 1 : 0));
	}

	public function install(manager:Manager):Void
	{
		sort();
		var maxField = fieldCount - 1;
		for (event in events) { validate(event); maxField = Std.int(Math.max(maxField, event.field)); }
		while (manager.playfields.length <= maxField) manager.addPlayfield();
		for (name in modifiers) manager.addModifier(name);
		for (event in events)
		{
			manager.addModifier(event.mod, event.field);
			switch (event.kind)
			{
				case 'set': manager.set(event.mod, event.beat, event.value, event.player, event.field);
				case 'ease': manager.ease(event.mod, event.beat, event.length, event.value,
					LuaUtils.getTweenEaseByString(event.ease), event.player, event.field);
				case 'add': manager.add(event.mod, event.beat, event.length, event.value,
					LuaUtils.getTweenEaseByString(event.ease), event.player, event.field);
			}
		}
		manager.requestRender();
		if (Reflect.hasField(renderer, 'holdSubdivisions'))
			modchart.backend.standalone.Adapter.instance.setHoldSubdivisions(Std.int(FlxMath.bound(renderer.holdSubdivisions, 1, 64)));
	}

	public function toJson():String
		return Json.stringify({version: 1, modifiers: modifiers, fieldCount: fieldCount, events: events, scene: scene, renderer: renderer, warnings: warnings}, null, '\t');

	public static function fromJson(text:String):ModchartTimeline
	{
		var data:Dynamic = Json.parse(text);
		if (data.version != 1 || !Std.isOfType(data.events, Array)) throw tr('invalid_project', "Unsupported modchart project");
		var result = new ModchartTimeline();
		if (data.fieldCount != null) result.fieldCount = data.fieldCount;
		if (result.fieldCount < 1 || result.fieldCount > 16) throw tr('invalid_fields', "Unsupported playfield count");
		result.events = data.events;
		if (data.modifiers != null) result.modifiers = data.modifiers;
		if (data.scene != null) result.scene = data.scene;
		if (data.renderer != null) result.renderer = data.renderer;
		if (data.warnings != null) result.warnings = data.warnings;
		for (event in result.events) result.validate(event);
		result.sort();
		return result;
	}

	public function toLua():String
	{
		sort();
		var lines = ['-- Plus Engine Modchart Editor. Timing is in beats.'];
		for (phase in ['create', 'start'])
		{
			var calls = [];
			for (op in scene) if (op.phase == phase)
			{
				var args:Array<Dynamic> = op.args.copy();
				while (args.length > 0 && args[args.length - 1] == null) args.pop();
				calls.push('\t' + op.kind + '(' + [for (arg in args) arg == null ? 'nil' : Json.stringify(arg)].join(', ') + ')');
			}
			if (calls.length > 0) { lines.push('function ' + (phase == 'create' ? 'onCreate' : 'onSongStart') + '()'); lines = lines.concat(calls); lines.push('end\n'); }
		}
		lines.push('function onInitModchart()');
		if (Reflect.hasField(renderer, 'holdSubdivisions')) lines.push('\tsetHoldSubdivisions(' + renderer.holdSubdivisions + ')');
		var rendererKeys = [for (key in Reflect.fields(renderer)) key + ' = ' + Json.stringify(Reflect.field(renderer, key))];
		if (rendererKeys.length > 0) lines.push('\tif configureModchartRenderer then configureModchartRenderer({' + rendererKeys.join(', ') + '}) end');
		var count = fieldCount;
		for (event in events) count = Std.int(Math.max(count, event.field + 1));
		for (_ in 1...count) lines.push('\taddPlayfield()');
		for (name in modifiers) lines.push('\taddModifier(' + Json.stringify(name) + ')');
		var added = modifiers.copy();
		for (event in events)
		{
			validate(event);
			if (!added.contains(event.mod)) { added.push(event.mod); lines.push('\taddModifier(' + Json.stringify(event.mod) + ')'); }
		}
		for (event in events)
		{
			var args = [Json.stringify(event.mod), Std.string(event.beat)];
			if (event.kind != 'set') args.push(Std.string(event.length));
			args.push(Std.string(event.value));
			if (event.kind != 'set') args.push(Json.stringify(event.ease));
			args.push(Std.string(event.player));
			args.push(Std.string(event.field));
			lines.push('\t' + event.kind + '(' + args.join(', ') + ')');
		}
		lines.push('end\n');
		return lines.join('\n');
	}
}
