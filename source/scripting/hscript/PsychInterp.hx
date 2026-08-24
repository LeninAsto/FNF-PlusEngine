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
