package mobile.backend;

import lime.system.System as LimeSystem;
import haxe.io.Path;

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

		return Path.addTrailingSlash(path);
	}

	public static function getInternalStorageDirectory():String
	{
		final path = AndroidContext.getExternalFilesDir();
		return (path != null && path.length > 0) ? path : getForcedInternalStorageDirectory();
	}

	private static function getForcedInternalStorageDirectory():String
	{
		return '/storage/emulated/0/Android/data/$androidPackageName/files';
	}

	public static function getPublicStorageDirectory():String
	{
		var basePath = AndroidEnvironment.getExternalStorageDirectory();
		if (basePath == null || basePath == '')
			basePath = '/storage/emulated/0';

		return Path.join([basePath, publicFolderName]);
	}

	private static function getForcedPublicStorageDirectory():String
	{
		return '/storage/emulated/0/$publicFolderName';
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
		return Path.addTrailingSlash(Path.join([getPublicStorageDirectory(), 'mods']));
	}

	public static function getScopedModsDirectory():String
	{
		return Path.addTrailingSlash(Path.join([getInternalStorageDirectory(), 'mods']));
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

		if (!hasRequiredPermissions()) {
			CoolUtil.showPopUp(
				Language.getPhrase('permissions_message', 
					'Storage permissions are required for public mods and external saves.\n' +
					'Please grant the requested permissions when prompted.'),
				Language.getPhrase('mobile_notice', "Notice!")
			);
		}

		initializeStorageDirectories();
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
	}
	#end
	#end
}
