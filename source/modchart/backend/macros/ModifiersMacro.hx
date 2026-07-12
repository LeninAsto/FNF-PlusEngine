package modchart.backend.macros;

#if macro
import haxe.macro.Context;
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;
#end

class ModifiersMacro {
	public static macro function get():ExprOf<Iterable<Class<Dynamic>>> {
		if (!onGenerateCallbackRegistered) {
			onGenerateCallbackRegistered = true;
			Context.onGenerate(onGenerate);
		}

		var request:String = 'package~${'modchart.engine.modifiers.list'}~recursive';

		classListsToGenerate.push(request);

		return macro modchart.backend.macros.CompiledClassList.get($v{request});
	}

	#if macro
	/**
	 * Callback executed after the typing phase but before the generation phase.
	 * Receives a list of `haxe.macro.Type` for all types in the program.
	 *
	 * Only metadata can be modified at this time, which makes it a BITCH to access the data at runtime.
	 */
	static function onGenerate(allTypes:Array<haxe.macro.Type>) {
		// Reset these, since onGenerate persists across multiple builds.
		classListsRaw = [];

		for (request in classListsToGenerate) {
			classListsRaw.set(request, []);
		}

		for (type in allTypes) {
			switch (type) {
				// Class instances
				case TInst(t, _params):
					var classType:ClassType = t.get();
					var className:String = t.toString();

					if (classType.isInterface) {
						// Ignore interfaces.
					} else {
						for (request in classListsToGenerate) {
							if (doesClassMatchRequest(classType, request)) {
								classListsRaw.get(request).push(className);
							}
						}
					}
				// Other types (things like enums)
				default:
					continue;
			}
		}

		compileClassLists();
	}

	/**
	 * At this stage in the program, `classListsRaw` is generated, but only accessible by macros.
	 * To make it accessible at runtime, we must:
	 * - Convert the String names to actual `Class<T>` instances, and store it as `classLists`
	 * - Insert the `classLists` into the metadata of the `CompiledClassList` class.
	 * `CompiledClassList` then extracts the metadata and stores it where it can be accessed at runtime.
	 */
	static function compileClassLists() {
		var compiledClassList:ClassType = getClassType("modchart.backend.macros.CompiledClassList");

		if (compiledClassList == null)
			throw "Could not find CompiledClassList class.";

		// Reset outdated metadata.
		if (compiledClassList.meta.has('classLists'))
			compiledClassList.meta.remove('classLists');

		var classLists:Array<Expr> = [];
		// Generate classLists.
		for (request in classListsToGenerate) {
			// Expression contains String, [Class<T>...]
			var classListEntries:Array<Expr> = [macro $v{request}];
			for (i in classListsRaw.get(request)) {
				// TODO: Boost performance by making this an Array<Class<T>> instead of an Array<String>
				// How to perform perform macro reificiation to types given a name?
				classListEntries.push(macro $v{i});
			}

			classLists.push(macro $a{classListEntries});
		}

		// Insert classLists into metadata.
		compiledClassList.meta.add('classLists', classLists, Context.currentPos());
	}

	static function doesClassMatchRequest(classType:ClassType, request:String):Bool {
		var splitRequest:Array<String> = request.split('~');

		var requestType:String = splitRequest[0];

		switch (requestType) {
			case 'package':
				var targetPackage:String = splitRequest[1];
				var recursive:Bool = splitRequest[2] == 'recursive';

				var classPackage:String = classType.pack.join('.');

				if (recursive) {
					return StringTools.startsWith(classPackage, targetPackage);
				} else {
					var regex:EReg = ~/^${targetPackage}(\.|$)/;
					return regex.match(classPackage);
				}
			case 'extend':
				var targetClassName:String = splitRequest[1];

				var targetClassType:ClassType = getClassType(targetClassName);

				if (implementsInterface(classType, targetClassType)) {
					return true;
				} else if (isSubclassOf(classType, targetClassType)) {
					return true;
				}

				return false;

			default:
				throw 'Unknown request type: ${requestType}';
		}
	}

	/**
	 * Retrieve a ClassType from a string name.
	 */
	static function getClassType(name:String):ClassType {
		switch (Context.getType(name)) {
			case TInst(t, _params):
				return t.get();
			default:
				throw 'Class type could not be parsed: ${name}';
		}
	}

	/**
	 * Determine whether a given ClassType is a subclass of a given superclass.
	 * @param classType The class to check.
	 * @param superClass The superclass to check for.
	 * @return Whether the class is a subclass of the superclass.
	 */
	public static function isSubclassOf(classType:ClassType, superClass:ClassType):Bool {
		if (areClassesEqual(classType, superClass))
			return true;

		if (classType.superClass != null) {
			return isSubclassOf(classType.superClass.t.get(), superClass);
		}

		return false;
	}

	static function areClassesEqual(class1:ClassType, class2:ClassType):Bool {
		return class1.pack.join('.') == class2.pack.join('.') && class1.name == class2.name;
	}

	/**
	 * Determine whether a given ClassType implements a given interface.
	 * @param classType The class to check.
	 * @param interfaceType The interface to check for.
	 * @return Whether the class implements the interface.
	 */
	public static function implementsInterface(classType:ClassType, interfaceType:ClassType):Bool {
		for (i in classType.interfaces) {
			if (areClassesEqual(i.t.get(), interfaceType)) {
				return true;
			}
		}

		if (classType.superClass != null) {
			return implementsInterface(classType.superClass.t.get(), interfaceType);
		}

		return false;
	}

	static var onGenerateCallbackRegistered:Bool = false;

	static var classListsRaw:Map<String, Array<String>> = [];
	static var classListsToGenerate:Array<String> = [];
	#end
}
