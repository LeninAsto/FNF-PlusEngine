package mobile.backend;

import lime.system.System as LimeSystem;
import haxe.Timer;
import haxe.io.Path;
import lime.utils.Assets;

/**
 * A storage class for mobile.
 * @author Karim Akra and Homura Akemi (HomuHomu833)
 */
class StorageUtil
{
	#if sys
	private static final rootDir:String = LimeSystem.applicationStorageDirectory;
	private static final publicFolderName:String = '.PlusEngine';
	private static final legacyPublicFolderName:String = 'PlusEngine';
	private static final androidPackageName:String = 'com.leninasto.plusengine';

	private static function ensureDirectory(path:String):Bool
	{
		if (path == null || path.length == 0)
			return false;

		try
		{
			if (!FileSystem.exists(path)) {
				FileSystem.createDirectory(path);
				trace('Created directory: $path');
			}
			return true;
		}
		catch (e:Dynamic)
		{
			trace('Failed to create directory $path: ${Std.string(e)}');
			return false;
		}
	}

	public static function getStorageDirectory(?force:Bool = false):String
	{
		return #if android
			resolveStorageDirectory(force)
		#elseif ios 
			lime.system.System.documentsDirectory 
		#else 
			Sys.getCwd() 
		#end;
	}

	public static function getModsListPath():String
	{
		return Path.join([getStorageDirectory(), 'modsList.txt']);
	}

	public static function getSavesDirectory():String
	{
		return Path.addTrailingSlash(Path.join([getStorageDirectory(), 'saves']));
	}

	public static function getLogsDirectory():String
	{
		return Path.addTrailingSlash(Path.join([getStorageDirectory(), 'logs']));
	}

	public static function getSMDirectory():String
	{
		final baseDir = #if android 
			getStorageDirectory()
		#else 
			'./' 
		#end;
		return Path.join([baseDir, 'sm']);
	}

	public static function saveContent(fileName:String, fileData:String, ?alert:Bool = true):Void
	{
		final folder = getSavesDirectory();
		final filePath = Path.join([folder, fileName]);
		
		try
		{
			if (!FileSystem.exists(folder))
				FileSystem.createDirectory(folder);

			File.saveContent(filePath, fileData);
			if (alert)
				CoolUtil.showPopUp(Language.getPhrase('file_save_success', '{1} has been saved.', [fileName]), Language.getPhrase('mobile_success', "Success!"));
		}
		catch (e:Dynamic)
		{
			final errorMsg = Std.string(e);
			if (alert)
				CoolUtil.showPopUp(Language.getPhrase('file_save_fail', '{1} couldn\'t be saved.\n({2})', [fileName, errorMsg]), Language.getPhrase('mobile_error', "Error!"));
			else
				trace('$fileName couldn\'t be saved. ($errorMsg)');
		}
	}

	public static function copyAssetsToStorage(sourcePath:String, targetPath:String, ?overwrite:Bool = false):Bool
	{
		try
		{
			ensureDirectory(targetPath);

			var assetFiles:Array<String> = Assets.list();
			var filesCopied = 0;

			var normalizedSourcePath = sourcePath.replace('\\', '/');
			if (normalizedSourcePath.startsWith('/'))
				normalizedSourcePath = normalizedSourcePath.substring(1);
			if (!normalizedSourcePath.endsWith('/'))
				normalizedSourcePath += '/';

			for (asset in assetFiles)
			{
				var normalizedAsset = asset.replace('\\', '/');
				if (normalizedAsset.startsWith(normalizedSourcePath))
				{
					var relativePath = normalizedAsset.substring(normalizedSourcePath.length);
					if (relativePath == '' || relativePath == null)
						continue;
					
					var targetFile = Path.join([targetPath, relativePath]);
					var targetDir = Path.directory(targetFile);

					ensureDirectory(targetDir);

					if (FileSystem.exists(targetFile) && !overwrite)
						continue;

					var content = Assets.getText(asset);
					if (content != null)
					{
						File.saveContent(targetFile, content);
						filesCopied++;
					}
					else
					{
						var bytes = Assets.getBytes(asset);
						if (bytes != null)
						{
							File.saveBytes(targetFile, bytes);
							filesCopied++;
						}
						else
						{
							trace('Failed to read asset: $asset');
						}
					}
				}
			}
			
			if (filesCopied > 0)
				trace('Copied $filesCopied files from $sourcePath to $targetPath');
			else
				trace('No files found to copy from $sourcePath');
			
			return true;
		}
		catch (e:Dynamic)
		{
			trace('Failed to copy assets from $sourcePath to $targetPath: ${Std.string(e)}');
			return false;
		}
	}

	public static function copyAllAssetsToStorage():Void
	{
		var storageDir = getStorageDirectory();

		var foldersToCopy = [
			{ source: "assets/mods", target: Path.join([storageDir, "mods"]) },
			{ source: "assets/sm", target: Path.join([storageDir, "sm"]) }
		];
		
		trace("Copying assets to storage...");
		
		for (folder in foldersToCopy)
		{
			var hasContent = false;
			try {
				if (FileSystem.exists(folder.target)) {
					var contents = FileSystem.readDirectory(folder.target);
					hasContent = contents.length > 0;
				}
			} catch (e:Dynamic) {
				hasContent = false;
			}

			if (!hasContent)
			{
				copyAssetsToStorage(folder.source, folder.target, false);
			}
			else
			{
				trace('Folder already has content, skipping copy: ${folder.target}');
			}
		}
	}

	public static function copyAssetFolderToStorage(assetPath:String, storagePath:String, ?overwrite:Bool = false):Bool
	{
		return copyAssetsToStorage(assetPath, storagePath, overwrite);
	}

	#if android
	private static function getStorageTypeFilePath():String
	{
		return Path.join([rootDir, 'storagetype.txt']);
	}

	private static function normalizeStorageType(storageType:String):String
	{
		return switch (storageType)
		{
			case null, '', 'EXTERNAL_DATA': 'INTERNAL';
			case 'EXTERNAL': 'EXTERNAL';
			default: 'INTERNAL';
		}
	}

	private static function readStorageType():String
	{
		final storageTypePath = getStorageTypeFilePath();
		var storageType = normalizeStorageType(ClientPrefs.data.storageType);

		try
		{
			ensureDirectory(rootDir);

			if (!FileSystem.exists(storageTypePath))
			{
				File.saveContent(storageTypePath, storageType);
			}
			else
			{
				storageType = normalizeStorageType(File.getContent(storageTypePath));
			}

			if (ClientPrefs.data.storageType != storageType)
			{
				ClientPrefs.data.storageType = storageType;
				File.saveContent(storageTypePath, storageType);
			}
		}
		catch (e:Dynamic)
		{
			trace('Failed to read storage type, using current preference: ${Std.string(e)}');
		}

		return storageType;
	}

	public static function saveStorageTypePreference(storageType:String):Void
	{
		final normalizedStorageType = normalizeStorageType(storageType);
		try
		{
			ensureDirectory(rootDir);
			File.saveContent(getStorageTypeFilePath(), normalizedStorageType);
			ClientPrefs.data.storageType = normalizedStorageType;
		}
		catch (e:Dynamic)
		{
			trace('Failed to save storage type preference: ${Std.string(e)}');
		}
	}

	private static function resolveStorageDirectory(force:Bool = false):String
	{
		final storageType = readStorageType();
		final path = if (storageType == 'EXTERNAL')
		{
			force ? getForcedPublicStorageDirectory() : getPublicStorageDirectory();
		}
		else
		{
			force ? getForcedInternalStorageDirectory() : getInternalStorageDirectory();
		}

		ensureDirectory(path);
		return Path.addTrailingSlash(path);
	}

	public static function getInternalStorageDirectory():String
	{
		final path = AndroidContext.getExternalFilesDir();
		if (path != null && path.length > 0) {
			ensureDirectory(path);
			return path;
		}
		return getForcedInternalStorageDirectory();
	}

	private static function getForcedInternalStorageDirectory():String
	{
		final forced = '/storage/emulated/0/Android/data/$androidPackageName/files';
		ensureDirectory(forced);
		return forced;
	}

	public static function getPublicStorageDirectory():String
	{
		var basePath = AndroidEnvironment.getExternalStorageDirectory();
		if (basePath == null || basePath == '')
			basePath = '/storage/emulated/0';

		final dir = Path.join([basePath, publicFolderName]);
		ensureDirectory(dir);
		return dir;
	}

	private static function getForcedPublicStorageDirectory():String
	{
		final forced = '/storage/emulated/0/$publicFolderName';
		ensureDirectory(forced);
		return forced;
	}

	public static function getExternalStorageDirectory():String
	{
		return getPublicStorageDirectory();
	}

	public static function useExternalModsStorage():Bool
	{
		return readStorageType() == 'EXTERNAL';
	}

	public static function getPublicModsDirectory():String
	{
		final dir = Path.join([getPublicStorageDirectory(), 'mods']);
		ensureDirectory(dir);
		return Path.addTrailingSlash(dir);
	}

	public static function getScopedModsDirectory():String
	{
		final dir = Path.join([getInternalStorageDirectory(), 'mods']);
		ensureDirectory(dir);
		return Path.addTrailingSlash(dir);
	}

	public static function getPublicModsDirectoryCandidates():Array<String>
	{
		var roots:Array<String> = [];

		addModsDirectoryCandidate(roots, getPublicModsDirectory());

		var basePath = AndroidEnvironment.getExternalStorageDirectory();
		if (basePath == null || basePath == '')
			basePath = '/storage/emulated/0';

		addModsDirectoryCandidate(roots, Path.join([basePath, legacyPublicFolderName, 'mods']));
		addModsDirectoryCandidate(roots, Path.join([basePath, publicFolderName, 'mods']));
		addModsDirectoryCandidate(roots, getScopedModsDirectory());

		return roots;
	}

	private static function addModsDirectoryCandidate(list:Array<String>, path:String):Void
	{
		if (path == null || path.length == 0)
			return;

		var normalizedPath = path.replace('\\', '/');
		if (!normalizedPath.endsWith('/'))
			normalizedPath += '/';

		if (!list.contains(normalizedPath))
			list.push(normalizedPath);
	}

	// The ensureDirectory function has been moved outside this block
	
	public static function hasRequiredPermissions():Bool
	{
		if (readStorageType() == 'INTERNAL')
			return true;

		final granted = AndroidPermissions.getGrantedPermissions();
		
		if (AndroidVersion.SDK_INT >= AndroidVersionCode.TIRAMISU) {
			return AndroidEnvironment.isExternalStorageManager();
		} else {
			return granted.contains('android.permission.READ_EXTERNAL_STORAGE') ||
				   granted.contains('android.permission.WRITE_EXTERNAL_STORAGE');
		}
	}

	public static function requestPermissions():Void
	{
		if (useExternalModsStorage())
		{
			if (AndroidVersion.SDK_INT < AndroidVersionCode.TIRAMISU)
			{
				AndroidPermissions.requestPermissions([
					'READ_EXTERNAL_STORAGE',
					'WRITE_EXTERNAL_STORAGE'
				]);
			}

			if (AndroidVersion.SDK_INT >= AndroidVersionCode.R &&
				!AndroidEnvironment.isExternalStorageManager())
			{
				AndroidSettings.requestSetting('MANAGE_APP_ALL_FILES_ACCESS_PERMISSION');
			}
		}

		Timer.delay(function() {
			var attempts = 0;
			var maxAttempts = 15;

			function checkAndCreate():Void
			{
				if (hasRequiredPermissions())
				{
					initializeStorageDirectories();
					return;
				}
				attempts++;
				if (attempts < maxAttempts)
				{
					Timer.delay(checkAndCreate, 1000);
				}
				else
				{
					CoolUtil.showPopUp(
						Language.getPhrase('permission_timeout',
							'Permissions were not granted. Please grant them manually and restart the app.'),
						Language.getPhrase('mobile_error', 'Error!')
					);
				}
			}
			checkAndCreate();
		}, 2000);
	}

	public static function getPermissionStatus():String
	{
		if (readStorageType() == 'INTERNAL')
			return 'INTERNAL storage: no extra permission required.';

		if (AndroidVersion.SDK_INT >= AndroidVersionCode.TIRAMISU)
			return AndroidEnvironment.isExternalStorageManager()
				? 'EXTERNAL storage: all-files access granted.'
				: 'EXTERNAL storage: all-files access required.';

		final granted = AndroidPermissions.getGrantedPermissions();
		final hasLegacyPermission = granted.contains('android.permission.READ_EXTERNAL_STORAGE')
			|| granted.contains('android.permission.WRITE_EXTERNAL_STORAGE');

		return hasLegacyPermission
			? 'EXTERNAL storage: legacy storage permission granted.'
			: 'EXTERNAL storage: legacy storage permission required.';
	}

	private static function initializeStorageDirectories():Void
	{
		var directories = [
			rootDir,
			getStorageDirectory(),
			getScopedModsDirectory(),
			getSavesDirectory(),
			getLogsDirectory(),
			getSMDirectory()
		];

		if (useExternalModsStorage())
		{
			directories.push(getPublicStorageDirectory());
			directories.push(getPublicModsDirectory());
		}

		var allDirectoriesCreated = true;
		var failedDirectories:Array<String> = [];
		
		for (dir in directories) {
			if (!ensureDirectory(dir)) {
				allDirectoriesCreated = false;
				failedDirectories.push(dir);
			}
		}

		if (allDirectoriesCreated)
		{
			#if android
			Timer.delay(function() {
				copyAllAssetsToStorage();
			}, 100);
			#end
		}
		else
		{
			var errorMsg = Language.getPhrase('create_directory_error', 
				'Failed to create the following directories:\n{1}\n' +
				'Please check storage permissions or available space.\n' +
				'The app may not function correctly without these directories.',
				[failedDirectories.join('\n')]);
			
			CoolUtil.showPopUp(errorMsg, Language.getPhrase('mobile_warning', "Warning!"));
		}
	}
	#end
	#end
}