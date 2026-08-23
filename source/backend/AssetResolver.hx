package backend;

import sys.FileSystem;
import openfl.utils.AssetType;
import openfl.utils.Assets as OpenFlAssets;

/**
 * Centralized asset path resolution.
 * Inspired by the resolver-based asset pipeline used in P-Slice.
 */
class AssetResolver
{
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
			#if vslice
			var funkinFolderPath:String = getFunkinFolderPath(file, parentFolder);
			if (OpenFlAssets.exists(funkinFolderPath, type))
				return funkinFolderPath;
			#end
			return folderPath;
		}

		if (Paths.currentLevel != null && Paths.currentLevel != 'shared')
		{
			var levelPath:String = Paths.getFolderPath(file, Paths.currentLevel);
			if (OpenFlAssets.exists(levelPath, type))
				return levelPath;

			#if vslice
			var funkinLevelPath:String = getFunkinFolderPath(file, Paths.currentLevel);
			if (OpenFlAssets.exists(funkinLevelPath, type))
				return funkinLevelPath;
			#end
		}

		var sharedPath:String = Paths.getSharedPath(file);
		if (OpenFlAssets.exists(sharedPath, type))
			return sharedPath;

		#if vslice
		var funkinSharedPath:String = getFunkinSharedPath(file);
		if (OpenFlAssets.exists(funkinSharedPath, type))
			return funkinSharedPath;
		#end

		return sharedPath;
	}

	#if vslice
	static inline function getFunkinFolderPath(file:String, folder:String):String
		return 'assets/funkin/$folder/$file';

	static inline function getFunkinSharedPath(file:String):String
		return 'assets/funkin/shared/$file';
	#end
}

