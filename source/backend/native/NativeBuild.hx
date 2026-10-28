package backend.native;

#if macro
import haxe.io.Path;
import haxe.macro.Context;
import haxe.macro.Expr;
import sys.FileSystem;

/** Resolves native paths at compile time, so Windows and Android builds stay portable. */
class NativeBuild
{
	public static macro function configure():Array<Field>
	{
		var cppPath = Path.normalize(FileSystem.fullPath(Context.resolvePath('backend/native/cpp/PlusNativeMath.cpp')));
		var geometryPath = Path.normalize(FileSystem.fullPath(Context.resolvePath('backend/native/cpp/PlusNativeGeometry.cpp')));
		var audioPath = Path.normalize(FileSystem.fullPath(Context.resolvePath('backend/native/cpp/PlusNativeAudio.cpp')));
		var notesPath = Path.normalize(FileSystem.fullPath(Context.resolvePath('backend/native/cpp/PlusNativeNotes.cpp')));
		if (!FileSystem.exists(cppPath))
			Context.fatalError('Missing native source: $cppPath', Context.currentPos());
		if (!FileSystem.exists(geometryPath))
			Context.fatalError('Missing native source: $geometryPath', Context.currentPos());
		if (!FileSystem.exists(audioPath))
			Context.fatalError('Missing native source: $audioPath', Context.currentPos());
		if (!FileSystem.exists(notesPath))
			Context.fatalError('Missing native source: $notesPath', Context.currentPos());

		cppPath = xmlPath(cppPath);
		geometryPath = xmlPath(geometryPath);
		audioPath = xmlPath(audioPath);
		notesPath = xmlPath(notesPath);
		var xml = '<files id="plus-native">'
			+ '<file name="$cppPath"/>'
			+ '<file name="$geometryPath"/>'
			+ '<file name="$audioPath"/>'
			+ '<file name="$notesPath"/>'
			+ '</files>'
			+ '<target id="haxe">'
			+ '<files id="plus-native"/>'
			+ '</target>';

		Context.getLocalClass().get().meta.add(':buildXml', [macro $v{xml}], Context.currentPos());
		return Context.getBuildFields();
	}

	static function xmlPath(value:String):String
	{
		value = StringTools.replace(value, '\\', '/');
		value = StringTools.replace(value, '&', '&amp;');
		return StringTools.replace(value, '"', '&quot;');
	}
}
#end
