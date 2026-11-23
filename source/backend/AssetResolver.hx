package backend;

import sys.FileSystem;
import sys.thread.Mutex;
import openfl.utils.AssetType;
import openfl.utils.Assets as OpenFlAssets;

/**
 * Centralized asset path resolution.
 * Inspired by the resolver-based asset pipeline used in P-Slice.
 */
class AssetResolver
{
	static final diagnosticMutex:Mutex = new Mutex();
	static final diagnosticSeen:Map<String, Bool> = [];
	static var pendingDiagnostics:Array<String> = [];

	public static function queueDiagnostic(message:String):Void
	{
		diagnosticMutex.acquire();
		if (!diagnosticSeen.exists(message))
		{
			diagnosticSeen.set(message, true);
			pendingDiagnostics.push(message);
		}
		diagnosticMutex.release();
	}

	public static function flushDiagnostics():Void
	{
		diagnosticMutex.acquire();
		var diagnostics:Array<String> = pendingDiagnostics;
		pendingDiagnostics = [];
		diagnosticMutex.release();
		for (message in diagnostics)
			trace(message);
	}

	public static function reportStageImageFallback(image:String):Void
	{
		if (Paths.currentLevel == null || Paths.currentLevel == 'shared')
			return;
		var file:String = image.startsWith('images/') ? image : 'images/$image';
		if (!file.endsWith('.png'))
			file += '.png';
		var sharedPath:String = Paths.getSharedPath(file);
		if (resolvePath(file, IMAGE) == sharedPath)
			queueDiagnostic('Stage asset fallback: "$file" was not found in "${Paths.currentLevel}"; using shared');
	}

	public static function resolvePath(file:String, ?type:AssetType = TEXT, ?parentFolder:String, ?modsAllowed:Bool = true):String
	{
		#if MODS_ALLOWED
		if (modsAllowed)
		{
			var customFile:String = file;
			if (parentFolder != null)
				customFile = '$parentFolder/$file';

			var modded:String = Paths.modFolders(customFile);
			try
			{
				if (FileSystem.exists(modded))
					return modded;
			}
			catch (_:Dynamic)
			{
			}
		}
		#end

		if (parentFolder == "mobile")
			return Paths.getSharedPath('mobile/$file');

		if (parentFolder != null)
		{
			var folderPath:String = Paths.getFolderPath(file, parentFolder);
			if (OpenFlAssets.exists(folderPath, type))
				return folderPath;
			return folderPath;
		}

		if (Paths.currentLevel != null && Paths.currentLevel != 'shared')
		{
			var levelPath:String = Paths.getFolderPath(file, Paths.currentLevel);
			if (OpenFlAssets.exists(levelPath, type))
				return levelPath;
		}

		var sharedPath:String = Paths.getSharedPath(file);
		if (OpenFlAssets.exists(sharedPath, type))
			return sharedPath;

		return sharedPath;
	}
}

