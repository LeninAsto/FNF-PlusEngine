package scripting.hscript;

#if HSCRIPT_ALLOWED
import hxscript.error.ErrorKind;
import hxscript.runtime.Interp;

@:access(hxscript.runtime.Interp)
class PsychInterp extends Interp {
	public var parentInstance(default, set):Dynamic = null;
	var instanceFields:Map<String, Bool> = new Map();

	public function new(?environment:hxscript.Environment, ?parent:Dynamic) {
		super(environment, parent);
	}

	override function get(o:Dynamic, field:String, maybe:Bool = false):Dynamic {
		if (field == 'setFilters') {
			var legacyMethod = deprecations.LegacyCamera.resolveMember(o, field, posInfos().fileName);
			if (legacyMethod != null) return legacyMethod;
		}
		if (deprecations.HaxeLibDeprecations.isTrackedMember(field))
			deprecations.HaxeLibDeprecations.checkMember(o, field, posInfos().fileName);
		return super.get(o, field, maybe);
	}

	override function set(o:Dynamic, field:String, value:Dynamic):Dynamic {
		if (deprecations.HaxeLibDeprecations.isTrackedMember(field))
			deprecations.HaxeLibDeprecations.checkMember(o, field, posInfos().fileName);
		return super.set(o, field, value);
	}

	override function call(o:Dynamic, f:Dynamic, args:Array<Dynamic>):Dynamic {
		if (args != null && args.length > 0) {
			if (o == flixel.FlxG && Reflect.compareMethods(f, Reflect.field(flixel.FlxG, 'switchState')))
				deprecations.HaxeLibDeprecations.warnLegacyStateCall('FlxG.switchState', args[0], posInfos().fileName);
			else if ((o == backend.MusicBeatState || o == backend.BaseMusicBeatState) && Reflect.compareMethods(f, Reflect.field(o, 'switchState')))
				deprecations.HaxeLibDeprecations.warnLegacyStateCall('MusicBeatState.switchState', args[0], posInfos().fileName);
		}
		return super.call(o, f, args);
	}

	function set_parentInstance(inst:Dynamic):Dynamic {
		parentInstance = inst;
		instanceFields = new Map();

		if (inst != null) {
			var cls:Class<Dynamic> = Type.getClass(inst);
			if (cls != null)
				for (field in Type.getInstanceFields(cls))
					instanceFields.set(field, true);
		}

		return inst;
	}

	override public function isResolvable(id:String):Bool
		return super.isResolvable(id) || (parentInstance != null && instanceFields.exists(id));

	override function setVar(name:String, v:Dynamic):Dynamic {
		if (!imports.exists(name) && !variables.exists(name) && parentInstance != null && instanceFields.exists(name)) {
			Reflect.setProperty(parentInstance, name, v);
			return v;
		}
		return super.setVar(name, v);
	}

	override public function resolve(id:String):Dynamic {
		if (imports.exists(id)) {
			var v:Dynamic = imports.get(id);
			if (v == null)
				error(ECustom('Module $id does not define type $id'));
			return resolveMirror(v);
		}

		if (variables.exists(id))
			return resolveMirror(variables.get(id));

		if (parentInstance != null && instanceFields.exists(id))
			return Reflect.getProperty(parentInstance, id);

		error(EUnknownVariable(id));
		return null;
	}
}
#end
