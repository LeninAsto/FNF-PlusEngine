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
			return Paths.getFolderPath(file, parentFolder);

		if (Paths.currentLevel != null && Paths.currentLevel != 'shared')
		{
			var levelPath:String = Paths.getFolderPath(file, Paths.currentLevel);
			if (OpenFlAssets.exists(levelPath, type))
				return levelPath;
		}

		return Paths.getSharedPath(file);
	}
}
