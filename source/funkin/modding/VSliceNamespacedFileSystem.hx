package funkin.modding;

import haxe.io.Bytes;
import polymod.Polymod;
import polymod.PolymodConfig;
import polymod.fs.PolymodFileSystem.IFileSystem;
import thx.semver.VersionRule;

using StringTools;

/**
 * Lets VSlice mods keep using official `_merge/data/...` and `_append/data/...`
 * patches while Plus stores Funkin compatibility assets under `assets/funkin/...`.
 */
class VSliceNamespacedFileSystem implements IFileSystem
{
  final inner:IFileSystem;

  public function new(inner:IFileSystem)
  {
    this.inner = inner;
  }

  public function exists(path:String):Bool
  {
    return inner.exists(path) || inner.exists(toLegacySpecialPath(path));
  }

  public function isDirectory(path:String):Bool
  {
    var legacyPath:String = toLegacySpecialPath(path);
    if (!inner.exists(path) && inner.exists(legacyPath)) return inner.isDirectory(legacyPath);
    return inner.isDirectory(path);
  }

  public function readDirectory(path:String):Array<String>
  {
    var legacyPath:String = toLegacySpecialPath(path);
    if (!inner.exists(path) && inner.exists(legacyPath)) return inner.readDirectory(legacyPath);
    return inner.readDirectory(path);
  }

  public function readDirectoryRecursive(path:String):Array<String>
  {
    var legacyPath:String = toLegacySpecialPath(path);
    if (!inner.exists(path) && inner.exists(legacyPath)) return inner.readDirectoryRecursive(legacyPath);
    return inner.readDirectoryRecursive(path);
  }

  public function getFileContent(path:String):Null<String>
  {
    if (inner.exists(path)) return inner.getFileContent(path);

    var legacyPath:String = toLegacySpecialPath(path);
    return inner.exists(legacyPath) ? inner.getFileContent(legacyPath) : null;
  }

  public function getFileBytes(path:String):Null<Bytes>
  {
    var result:Null<Bytes> = inner.getFileBytes(path);
    if (result != null) return result;
    return inner.getFileBytes(toLegacySpecialPath(path));
  }

  public function scanMods(?apiVersionRule:VersionRule):Array<ModMetadata>
  {
    return inner.scanMods(apiVersionRule);
  }

  public function getMetadataByDir(dir:String, ?origin:PolymodErrorOrigin):Null<ModMetadata>
  {
    return inner.getMetadataByDir(dir, origin);
  }

  public function getMetadataById(modId:String, ?origin:PolymodErrorOrigin):Null<ModMetadata>
  {
    var metadata:Null<ModMetadata> = inner.getMetadataById(modId, origin);
    if (metadata != null || modId == null) return metadata;

    var normalizedId:String = modId.toLowerCase();
    for (mod in inner.scanMods())
    {
      if (mod.id.toLowerCase() == normalizedId) return mod;
    }

    return null;
  }

  static function toLegacySpecialPath(path:String):String
  {
    if (path == null) return path;

    var normalized:String = path.replace('\\', '/');
    var mergePrefix:String = '/' + PolymodConfig.mergeFolder + '/assets/funkin/';
    var appendPrefix:String = '/' + PolymodConfig.appendFolder + '/assets/funkin/';

    if (normalized.indexOf(mergePrefix) != -1)
      return replaceSpecialPrefix(path, normalized, mergePrefix, '/' + PolymodConfig.mergeFolder + '/');

    if (normalized.indexOf(appendPrefix) != -1)
      return replaceSpecialPrefix(path, normalized, appendPrefix, '/' + PolymodConfig.appendFolder + '/');

    return path;
  }

  static function replaceSpecialPrefix(original:String, normalized:String, search:String, replacement:String):String
  {
    var index:Int = normalized.indexOf(search);
    if (index == -1) return original;

    var legacy:String = normalized.substr(0, index) + replacement + normalized.substr(index + search.length);
    return original.indexOf('\\') != -1 ? legacy.replace('/', '\\') : legacy;
  }
}
