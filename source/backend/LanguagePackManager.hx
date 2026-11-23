package backend;

#if sys
import haxe.Json;
import haxe.io.Bytes;
import haxe.io.Path;
import sys.FileSystem;
import sys.io.File;

typedef LanguageSyncResult =
{
	var success:Bool;
	var installed:Int;
	var skipped:Int;
	var message:String;
}

/** Downloads validated JSON language packs into mods/languages/. */
class LanguagePackManager
{
	public static var remoteIndexUrl:String =
		'https://raw.githubusercontent.com/Psych-Plus-Team/FNF-PlusEngine/main/assets/shared/languages/index.json';

	static inline var MAX_INDEX_BYTES:Int = 256 * 1024;
	static inline var MAX_MANIFEST_BYTES:Int = 256 * 1024;
	static inline var MAX_BUNDLE_BYTES:Int = 1024 * 1024;
	static inline var MAX_ASSET_BYTES:Int = 16 * 1024 * 1024;
	static inline var MAX_ASSET_TOTAL_BYTES:Int = 64 * 1024 * 1024;
	static inline var MAX_LANGUAGES:Int = 64;
	static inline var MAX_BUNDLES:Int = 128;
	static final VALID_CODE:EReg = ~/^[A-Za-z]{2,3}(?:-[A-Za-z0-9]{2,8})*$/;

	public static function syncAll():LanguageSyncResult
	{
		try
		{
			var rawIndex:String = downloadText(remoteIndexUrl, MAX_INDEX_BYTES);
			var index:Dynamic = Json.parse(Paths.stripBOM(rawIndex));
			var rawEntries:Dynamic = Reflect.field(index, 'languages');
			if (!Std.isOfType(rawEntries, Array))
				throw 'The remote index has no languages array.';

			var entries:Array<Dynamic> = cast rawEntries;
			if (entries.length > MAX_LANGUAGES)
				throw 'The remote index contains too many languages.';

			var installed:Int = 0;
			var skipped:Int = 0;
			var downloadedEntries:Array<Dynamic> = readDownloadedIndex();
			for (entry in entries)
			{
				var code:String = cleanString(Reflect.field(entry, 'code'));
				if (!isValidCode(code))
					continue;

				var remoteVersion:Int = readVersion(entry);
				if (getInstalledVersion(code) >= remoteVersion)
				{
					skipped++;
					continue;
				}

				installEntry(entry, code, remoteVersion);
				mergeIndexEntry(downloadedEntries, {
					code: code,
					name: cleanString(Reflect.field(entry, 'name')),
					version: remoteVersion
				});
				installed++;
			}

			writeDownloadedIndex(downloadedEntries);
			return {
				success: true,
				installed: installed,
				skipped: skipped,
				message: installed > 0 ? 'Language packages updated.' : 'Language packages are already current.'
			};
		}
		catch (e:Dynamic)
		{
			return {success: false, installed: 0, skipped: 0, message: Std.string(e)};
		}
	}

	static function installEntry(entry:Dynamic, code:String, remoteVersion:Int):Void
	{
		var manifestUrl:String = cleanString(Reflect.field(entry, 'manifest'));
		if (manifestUrl.length == 0)
			manifestUrl = joinUrl(directoryUrl(remoteIndexUrl), '$code/manifest.json');
		else if (!manifestUrl.startsWith('https://'))
			manifestUrl = joinUrl(directoryUrl(remoteIndexUrl), manifestUrl);
		if (!manifestUrl.startsWith('https://'))
			throw 'Language manifests must use HTTPS.';

		var rawManifest:String = downloadText(manifestUrl, MAX_MANIFEST_BYTES);
		var manifest:Dynamic = Json.parse(Paths.stripBOM(rawManifest));
		var manifestCode:String = cleanString(Reflect.field(manifest, 'code'));
		if (manifestCode != code)
			throw 'Manifest code "$manifestCode" does not match "$code".';

		var rawBundles:Dynamic = Reflect.field(manifest, 'bundles');
		if (!Std.isOfType(rawBundles, Array))
			throw 'Manifest "$code" has no bundles array.';
		var bundles:Array<Dynamic> = cast rawBundles;
		if (bundles.length == 0 || bundles.length > MAX_BUNDLES)
			throw 'Manifest "$code" has an invalid bundle count.';

		var downloaded:Map<String, String> = [];
		var downloadedAssets:Map<String, Bytes> = [];
		var manifestBase:String = directoryUrl(manifestUrl);
		for (rawBundle in bundles)
		{
			var bundle:String = cleanString(rawBundle).replace('\\', '/');
			if (!isSafeRelativePath(bundle))
				throw 'Unsafe bundle path in "$code": $bundle';
			var data:String = downloadText(joinUrl(manifestBase, bundle), MAX_BUNDLE_BYTES);
			var parsed:Dynamic = Json.parse(Paths.stripBOM(data));
			if (parsed == null || !Reflect.hasField(parsed, "$namespace"))
				throw 'Bundle "$bundle" has no namespace.';
			downloaded.set(bundle, data);
		}

		var rawAssets:Dynamic = Reflect.field(manifest, 'assets');
		if (rawAssets != null)
		{
			if (!Std.isOfType(rawAssets, Array))
				throw 'Manifest "$code" has an invalid assets list.';
			var assetEntries:Array<Dynamic> = cast rawAssets;
			if (assetEntries.length > MAX_BUNDLES)
				throw 'Manifest "$code" has too many localized assets.';
			var totalAssetBytes:Int = 0;
			for (assetEntry in assetEntries)
			{
				var source:String = cleanString(Reflect.field(assetEntry, 'source')).replace('\\', '/');
				var target:String = cleanString(Reflect.field(assetEntry, 'target')).replace('\\', '/');
				if (!isSafeRelativePath(target))
					throw 'Unsafe localized asset target in "$code": $target';
				if (source.length == 0)
					throw 'Localized asset "$target" has no source.';
				if (!source.startsWith('https://') && !isSafeRelativePath(source))
					throw 'Unsafe localized asset source in "$code": $source';
				var sourceUrl:String = source.startsWith('https://') ? source : joinUrl(manifestBase, source);
				var bytes:Bytes = downloadBytes(sourceUrl, MAX_ASSET_BYTES);
				totalAssetBytes += bytes.length;
				if (totalAssetBytes > MAX_ASSET_TOTAL_BYTES)
					throw 'Localized assets for "$code" exceeded the allowed total size.';
				downloadedAssets.set(target, bytes);
			}
		}

		Reflect.setField(manifest, 'version', remoteVersion);
		var languageRoot:String = Path.join([downloadRoot(), code]);
		ensureDirectory(languageRoot);
		for (bundle => data in downloaded)
			atomicWrite(Path.join([languageRoot, bundle]), data);
		for (target => bytes in downloadedAssets)
			atomicWriteBytes(Path.join([Paths.getPrimaryModsRoot(), target]), bytes);
		// The manifest is committed last, so an interrupted download is never selected.
		atomicWrite(Path.join([languageRoot, 'manifest.json']), Json.stringify(manifest, null, '  '));
	}

	static function getInstalledVersion(code:String):Int
	{
		var best:Int = -1;
		for (path in Mods.directoriesWithFile(Paths.getSharedPath(), 'languages/$code/manifest.json'))
		{
			try
			{
				var data:Dynamic = Json.parse(Paths.stripBOM(AssetLoader.loadText(path)));
				best = Std.int(Math.max(best, readVersion(data)));
			}
			catch (_:Dynamic) {}
		}
		return best;
	}

	static function readDownloadedIndex():Array<Dynamic>
	{
		var path:String = Path.join([downloadRoot(), 'index.json']);
		if (!FileSystem.exists(path))
			return [];
		try
		{
			var data:Dynamic = Json.parse(Paths.stripBOM(File.getContent(path)));
			var entries:Dynamic = Reflect.field(data, 'languages');
			return Std.isOfType(entries, Array) ? cast entries : [];
		}
		catch (_:Dynamic)
			return [];
	}

	static function writeDownloadedIndex(entries:Array<Dynamic>):Void
	{
		ensureDirectory(downloadRoot());
		atomicWrite(Path.join([downloadRoot(), 'index.json']), Json.stringify({schemaVersion: 1, languages: entries}, null, '  '));
	}

	static function mergeIndexEntry(entries:Array<Dynamic>, fresh:Dynamic):Void
	{
		var code:String = Reflect.field(fresh, 'code');
		for (i in 0...entries.length)
			if (cleanString(Reflect.field(entries[i], 'code')) == code)
			{
				entries[i] = fresh;
				return;
			}
		entries.push(fresh);
	}

	static function downloadText(url:String, maxBytes:Int):String
	{
		if (url == null || !url.startsWith('https://'))
			throw 'Only HTTPS language sources are allowed.';
		var data:String = haxe.Http.requestUrl(url);
		if (data == null || data.trim().length == 0)
			throw 'Empty response from $url';
		if (data.length > maxBytes)
			throw 'Download exceeded the allowed size: $url';
		return data;
	}

	static function downloadBytes(url:String, maxBytes:Int):Bytes
	{
		if (url == null || !url.startsWith('https://'))
			throw 'Only HTTPS language assets are allowed.';
		var result:Bytes = null;
		var failure:String = null;
		var request = new haxe.Http(url);
		request.onBytes = function(data:Bytes) result = data;
		request.onError = function(error:String) failure = error;
		request.request(false);
		if (failure != null)
			throw 'Could not download $url: $failure';
		if (result == null || result.length == 0)
			throw 'Empty response from $url';
		if (result.length > maxBytes)
			throw 'Download exceeded the allowed size: $url';
		return result;
	}

	static function atomicWrite(path:String, data:String):Void
	{
		ensureDirectory(Path.directory(path));
		var temporary:String = path + '.download';
		File.saveContent(temporary, data);
		if (FileSystem.exists(path))
			FileSystem.deleteFile(path);
		FileSystem.rename(temporary, path);
	}

	static function atomicWriteBytes(path:String, data:Bytes):Void
	{
		ensureDirectory(Path.directory(path));
		var temporary:String = path + '.download';
		File.saveBytes(temporary, data);
		if (FileSystem.exists(path))
			FileSystem.deleteFile(path);
		FileSystem.rename(temporary, path);
	}

	static function ensureDirectory(path:String):Void
	{
		if (path == null || path.length == 0 || FileSystem.exists(path))
			return;
		var parent:String = Path.directory(path);
		if (parent != path)
			ensureDirectory(parent);
		FileSystem.createDirectory(path);
	}

	static inline function downloadRoot():String
		return Path.join([Paths.getPrimaryModsRoot(), 'languages']);

	static function isSafeRelativePath(path:String):Bool
		return path.length > 0 && !path.startsWith('/') && path.indexOf(':') == -1 && path.split('/').indexOf('..') == -1;

	static function isValidCode(code:String):Bool
		return code != null && VALID_CODE.match(code);

	static function readVersion(data:Dynamic):Int
	{
		var value:Dynamic = Reflect.field(data, 'version');
		var parsed:Null<Int> = value == null ? null : Std.parseInt(Std.string(value));
		return parsed == null || parsed < 1 ? 1 : parsed;
	}

	static function cleanString(value:Dynamic):String
		return value == null ? '' : Std.string(value).trim();

	static function directoryUrl(url:String):String
		return url.substr(0, url.lastIndexOf('/') + 1);

	static function joinUrl(base:String, relative:String):String
		return base + relative.split('/').map(StringTools.urlEncode).join('/');
}
#else
typedef LanguageSyncResult =
{
	var success:Bool;
	var installed:Int;
	var skipped:Int;
	var message:String;
}

class LanguagePackManager
{
	public static function syncAll():LanguageSyncResult
		return {success: false, installed: 0, skipped: 0, message: 'Language downloads are unavailable on this target.'};
}
#end
