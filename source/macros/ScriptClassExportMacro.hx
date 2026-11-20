package macros;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr.Position;
import sys.FileSystem;
import sys.io.File;

class ScriptClassExportMacro {
	static final EXPORTS:Array<ExportEntry> = [
		{
			source: 'source/states',
			target: 'assets/shared/scripts/classes/states',
			pack: 'states',
			files: [
				'TitleState',
				'MainMenuState',
				'FreeplayState',
			]
		},
		{
			source: 'source/substates',
			target: 'assets/shared/scripts/classes/substates',
			pack: 'substates',
			files: [
				'PauseSubState'
			]
		}
	];

	public static function syncCoreStates():Void {
		if (!Context.defined('HSCRIPT_ALLOWED'))
			return;

		var pos:Position = Context.currentPos();
		var copied:Int = 0;

		for (entry in EXPORTS)
			copied += syncDirectory(entry);

		Context.info('ScriptClassExportMacro: synced $copied core script class file(s)', pos);
	}

	static function syncDirectory(entry:ExportEntry):Int {
		if (!FileSystem.exists(entry.source) || !FileSystem.isDirectory(entry.source))
			return 0;

		ensureDirectory(entry.target);
		pruneTarget(entry);
		var exportTarget:String = exportMirrorTarget(entry.target);
		if (exportTarget != null) {
			ensureDirectory(exportTarget);
			pruneTarget({source: entry.source, target: exportTarget, pack: entry.pack, files: entry.files});
		}
		var copied:Int = 0;

		for (className in entry.files) {
			var sourcePath:String = entry.source + '/' + className + '.hx';
			if (!FileSystem.exists(sourcePath)) {
				Context.warning('ScriptClassExportMacro: missing allowlisted core script "$sourcePath"', Context.currentPos());
				continue;
			}

			var targetPath:String = entry.target + '/' + className + '.hx';
			var content:String = wrapperContent(entry.pack, className);
			if (saveIfChanged(targetPath, content))
				copied++;
			if (exportTarget != null)
				saveIfChanged(exportTarget + '/' + className + '.hx', content);
		}

		return copied;
	}

	static function exportMirrorTarget(target:String):String {
		#if windows
		return 'export/release/windows/bin/' + target;
		#else
		return null;
		#end
	}

	static function pruneTarget(entry:ExportEntry):Void {
		if (!FileSystem.exists(entry.target) || !FileSystem.isDirectory(entry.target))
			return;

		for (name in FileSystem.readDirectory(entry.target)) {
			var targetPath:String = entry.target + '/' + name;
			if (!FileSystem.isDirectory(targetPath) && StringTools.endsWith(name, '.hx') && !entry.files.contains(scriptClassName(name)))
				FileSystem.deleteFile(targetPath);
		}
	}

	static function scriptClassName(fileName:String):String {
		if (!StringTools.endsWith(fileName, '.hx'))
			return '';
		return fileName.substr(0, fileName.length - '.hx'.length);
	}

	static function saveIfChanged(targetPath:String, content:String):Bool {
		if (FileSystem.exists(targetPath)) {
			var current:String = File.getContent(targetPath);
			if (current == content)
				return false;
		}

		File.saveContent(targetPath, content);
		return true;
	}

	static function wrapperContent(pack:String, className:String):String {
		var alias:String = 'Hardcoded$className';
		return 'package $pack;\n\nimport $pack.$className as $alias;\n\nclass $className extends $alias\n{\n}\n';
	}

	static function ensureDirectory(path:String):Void {
		var normalized:String = StringTools.replace(path, '\\', '/');
		var parts:Array<String> = normalized.split('/');
		var current:String = '';

		for (part in parts) {
			if (part == null || part.length == 0)
				continue;

			current = current.length == 0 ? part : current + '/' + part;
			if (!FileSystem.exists(current))
				FileSystem.createDirectory(current);
		}
	}
}

typedef ExportEntry = {
	var source:String;
	var target:String;
	var pack:String;
	var files:Array<String>;
}
#end
