package mobile.backend;

import lime.system.System as LimeSystem;
import haxe.Timer;
import haxe.io.Path;
import openfl.utils.Assets as OpenFLAssets;
import haxe.io.Bytes;

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
		final directories = [
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

		if (!allDirectoriesCreated) {
			final errorMsg = Language.getPhrase('create_directory_error', 
				'Failed to create the following directories:\n{1}\n' +
				'Please check storage permissions or available space.\n' +
				'The app may not function correctly without these directories.',
				[failedDirectories.join('\n')]);
			
			CoolUtil.showPopUp(errorMsg, Language.getPhrase('mobile_warning', "Warning!"));
		}
		else
		{
			#if android
			Timer.delay(function() {
				if (hasModsOrSMAssets())
				{
					trace('Starting automatic asset copy for mods and sm...');
					var failed = copyModsAndSMAssets();
					if (failed.length > 0)
					{
						trace('Asset copy completed with ${failed.length} failures.');
					}
					else
					{
						trace('Asset copy completed successfully!');
					}
				}
				else
				{
					trace('No mods or sm assets found to copy.');
				}
			}, 500);
			#end
		}
	}

	public static function copyModsAndSMAssets():Array<String>
	{
		var failedFiles:Array<String> = [];
		var successCount:Int = 0;
		var totalCount:Int = 0;

		try
		{
			var allAssets:Array<String> = OpenFLAssets.list();

			var modsAssets:Array<String> = allAssets.filter(function(assetPath:String):Bool
			{
				return assetPath.startsWith('mods/') || assetPath.startsWith('sm/');
			});

			totalCount = modsAssets.length;

			if (totalCount == 0)
			{
				trace('No mods or sm assets found in OpenFL assets.');
				return [];
			}

			trace('Found $totalCount assets to copy (mods and sm folders)');

			var internalModsDir:String = getScopedModsDirectory();
			var externalModsDir:String = getPublicModsDirectory();
			var internalSMDir:String = getSMDirectory();
			var externalSMDir:String = Path.join([getPublicStorageDirectory(), 'sm']);

			ensureDirectory(externalSMDir);

			for (assetPath in modsAssets)
			{
				try
				{
					var isModsAsset:Bool = assetPath.startsWith('mods/');
					var isSMAsset:Bool = assetPath.startsWith('sm/');
					
					if (!isModsAsset && !isSMAsset)
						continue;

					var relativePath:String = '';
					var targetDir:String = '';
					var externalTargetDir:String = '';

					if (isModsAsset)
					{
						relativePath = assetPath.substring('mods/'.length);
						targetDir = internalModsDir;
						externalTargetDir = externalModsDir;
					}
					else if (isSMAsset)
					{
						relativePath = assetPath.substring('sm/'.length);
						targetDir = internalSMDir;
						externalTargetDir = externalSMDir;
					}

					if (relativePath == '' || relativePath == '/')
						continue;

					if (!OpenFLAssets.exists(assetPath))
					{
						failedFiles.push('$assetPath (Asset does not exist in OpenFL)');
						continue;
					}

					var internalSuccess:Bool = copyAssetToDirectory(assetPath, targetDir, relativePath);
					if (!internalSuccess)
					{
						failedFiles.push('$assetPath (Failed to copy to internal storage)');
					}

					if (useExternalModsStorage())
					{
						var externalSuccess:Bool = copyAssetToDirectory(assetPath, externalTargetDir, relativePath);
						if (!externalSuccess && !failedFiles.contains('$assetPath (Failed to copy to internal storage)'))
						{
							failedFiles.push('$assetPath (Failed to copy to external storage)');
						}
					}

					successCount++;
				}
				catch (e:Dynamic)
				{
					failedFiles.push('$assetPath (${Std.string(e)})');
					trace('Failed to copy asset $assetPath: ${Std.string(e)}');
				}
			}

			if (failedFiles.length > 0)
			{
				trace('Copied ${successCount - failedFiles.length}/$totalCount assets. ${failedFiles.length} failed.');
			}
			else
			{
				trace('Successfully copied all $successCount assets to storage directories.');
			}
		}
		catch (e:Dynamic)
		{
			trace('Error during asset copy process: ${Std.string(e)}');
			failedFiles.push('Global error: ${Std.string(e)}');
		}

		return failedFiles;
	}

	private static function copyAssetToDirectory(assetPath:String, targetDir:String, relativePath:String):Bool
	{
		try
		{
			if (!ensureDirectory(targetDir))
			{
				trace('Failed to create target directory: $targetDir');
				return false;
			}

			var fullPath:String = Path.join([targetDir, relativePath]);
			var fileDir:String = Path.directory(fullPath);

			if (!ensureDirectory(fileDir))
			{
				trace('Failed to create file directory: $fileDir');
				return false;
			}

			if (FileSystem.exists(fullPath))
			{
				trace('File already exists: $fullPath, skipping...');
				return true;
			}

			var extension:String = Path.extension(assetPath).toLowerCase();
			var textExtensions:Array<String> = ['ini', 'txt', 'xml', 'hxs', 'hx', 'lua', 'json', 'frag', 'vert'];

			if (textExtensions.contains(extension))
			{
				var fileData:String = OpenFLAssets.getText(assetPath);
				if (fileData == null)
					fileData = '';
				File.saveContent(fullPath, fileData);
			}
			else
			{
				var bytes:Bytes = OpenFLAssets.getBytes(assetPath);
				if (bytes == null)
				{
					trace('Failed to get bytes for asset: $assetPath');
					return false;
				}
				File.saveBytes(fullPath, bytes);
			}

			return true;
		}
		catch (e:Dynamic)
		{
			trace('Error copying asset $assetPath to $targetDir: ${Std.string(e)}');
			return false;
		}
	}

	public static function hasModsOrSMAssets():Bool
	{
		try
		{
			var allAssets:Array<String> = OpenFLAssets.list();
			for (asset in allAssets)
			{
				if (asset.startsWith('mods/') || asset.startsWith('sm/'))
					return true;
			}
		}
		catch (e:Dynamic)
		{
			trace('Error checking for mods/sm assets: ${Std.string(e)}');
		}
		return false;
	}

	public static function getModsAndSMAssetCount():Int
	{
		try
		{
			var allAssets:Array<String> = OpenFLAssets.list();
			var count:Int = 0;
			for (asset in allAssets)
			{
				if (asset.startsWith('mods/') || asset.startsWith('sm/'))
					count++;
			}
			return count;
		}
		catch (e:Dynamic)
		{
			trace('Error counting mods/sm assets: ${Std.string(e)}');
			return 0;
		}
	}

	public static function copyModsAndSMAssetsWithProgress(onProgress:(Int, Int) -> Void):Array<String>
	{
		var failedFiles:Array<String> = [];
		
		try
		{
			var allAssets:Array<String> = OpenFLAssets.list();
			var modsAssets:Array<String> = allAssets.filter(function(assetPath:String):Bool
			{
				return assetPath.startsWith('mods/') || assetPath.startsWith('sm/');
			});

			var total:Int = modsAssets.length;
			var current:Int = 0;

			if (total == 0)
			{
				trace('No mods or sm assets found in OpenFL assets.');
				onProgress(0, 0);
				return [];
			}

			trace('Found $total assets to copy with progress tracking');

			var internalModsDir:String = getScopedModsDirectory();
			var externalModsDir:String = getPublicModsDirectory();
			var internalSMDir:String = getSMDirectory();
			var externalSMDir:String = Path.join([getPublicStorageDirectory(), 'sm']);

			ensureDirectory(externalSMDir);

			for (assetPath in modsAssets)
			{
				current++;
				try
				{
					var isModsAsset:Bool = assetPath.startsWith('mods/');
					var isSMAsset:Bool = assetPath.startsWith('sm/');
					
					if (!isModsAsset && !isSMAsset)
					{
						onProgress(current, total);
						continue;
					}

					var relativePath:String = '';
					var targetDir:String = '';
					var externalTargetDir:String = '';

					if (isModsAsset)
					{
						relativePath = assetPath.substring('mods/'.length);
						targetDir = internalModsDir;
						externalTargetDir = externalModsDir;
					}
					else if (isSMAsset)
					{
						relativePath = assetPath.substring('sm/'.length);
						targetDir = internalSMDir;
						externalTargetDir = externalSMDir;
					}

					if (relativePath == '' || relativePath == '/')
					{
						onProgress(current, total);
						continue;
					}

					if (!OpenFLAssets.exists(assetPath))
					{
						failedFiles.push('$assetPath (Asset does not exist)');
						onProgress(current, total);
						continue;
					}

					var internalSuccess:Bool = copyAssetToDirectory(assetPath, targetDir, relativePath);
					if (!internalSuccess)
					{
						failedFiles.push('$assetPath (Internal copy failed)');
					}

					if (useExternalModsStorage())
					{
						var externalSuccess:Bool = copyAssetToDirectory(assetPath, externalTargetDir, relativePath);
						if (!externalSuccess && !failedFiles.contains('$assetPath (Internal copy failed)'))
						{
							failedFiles.push('$assetPath (External copy failed)');
						}
					}
				}
				catch (e:Dynamic)
				{
					failedFiles.push('$assetPath (${Std.string(e)})');
				}

				onProgress(current, total);
			}

			if (failedFiles.length > 0)
			{
				trace('Completed with ${failedFiles.length} failures.');
			}
			else
			{
				trace('Successfully copied all $total assets.');
			}
		}
		catch (e:Dynamic)
		{
			trace('Error during asset copy process: ${Std.string(e)}');
			failedFiles.push('Global error: ${Std.string(e)}');
		}

		return failedFiles;
	}

	public static function verifyModsAndSMAssets():Array<String>
	{
		var missingFiles:Array<String> = [];
		
		try
		{
			var allAssets:Array<String> = OpenFLAssets.list();
			var modsAssets:Array<String> = allAssets.filter(function(assetPath:String):Bool
			{
				return assetPath.startsWith('mods/') || assetPath.startsWith('sm/');
			});

			if (modsAssets.length == 0)
			{
				trace('No mods or sm assets to verify.');
				return [];
			}

			var internalModsDir:String = getScopedModsDirectory();
			var externalModsDir:String = getPublicModsDirectory();
			var internalSMDir:String = getSMDirectory();
			var externalSMDir:String = Path.join([getPublicStorageDirectory(), 'sm']);

			var missingCount:Int = 0;

			for (assetPath in modsAssets)
			{
				var isModsAsset:Bool = assetPath.startsWith('mods/');
				var isSMAsset:Bool = assetPath.startsWith('sm/');
				
				if (!isModsAsset && !isSMAsset)
					continue;

				var relativePath:String = '';
				var internalTargetDir:String = '';
				var externalTargetDir:String = '';

				if (isModsAsset)
				{
					relativePath = assetPath.substring('mods/'.length);
					internalTargetDir = internalModsDir;
					externalTargetDir = externalModsDir;
				}
				else if (isSMAsset)
				{
					relativePath = assetPath.substring('sm/'.length);
					internalTargetDir = internalSMDir;
					externalTargetDir = externalSMDir;
				}

				if (relativePath == '' || relativePath == '/')
					continue;

				var internalPath:String = Path.join([internalTargetDir, relativePath]);
				var externalPath:String = Path.join([externalTargetDir, relativePath]);

				var internalExists:Bool = FileSystem.exists(internalPath);
				var externalExists:Bool = FileSystem.exists(externalPath);

				if (!internalExists && !externalExists)
				{
					missingFiles.push(assetPath);
					missingCount++;
				}
			}

			if (missingCount > 0)
			{
				trace('Found $missingCount missing assets.');
			}
			else
			{
				trace('All ${modsAssets.length} assets verified successfully.');
			}
		}
		catch (e:Dynamic)
		{
			trace('Error verifying mods/sm assets: ${Std.string(e)}');
		}

		return missingFiles;
	}

	#end
	#end
}