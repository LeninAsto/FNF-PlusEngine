package funkin.modding;

import polymod.Polymod.PolymodError;
import funkin.plus.VSliceDebugLog;

@:nullSafety
class PolymodErrorHandler
{
  public static function onPolymodError(error:PolymodError):Void
  {
    // Perform an action based on the error code.
    switch (error.code)
    {
      //
      // Mod Metadata Parsing Errors
      //

      case "directory_missing":
        // A mod directory was included in the list of mods to load, but it isn't installed.
        trace(' WARNING '.warning() + 'Tried to load a mod that was not installed: ${error.message}');
        VSliceDebugLog.warning('Mod Load Error', error.message);

      case "missing_mod":
        // A mod ID was included in the list of mods to load, but it isn't installed.
        trace(' WARNING '.warning() + ' Tried to load a mod that was not installed: ${error.message}');
        VSliceDebugLog.warning('Mod Load Error', error.message);

      case "missing_meta":
        // A mod ID was included in the list of mods to load, but the mod folder doesn't have metadata.
        trace(' ERROR '.error() + ' Tried to load a mod with no metadata: ${error.message}');
        VSliceDebugLog.error('Mod Load Error', error.message);

      case "parse_mod_meta":
        // Polymod tries to load the mod's metadata, but it could not be parsed.
        trace(' ERROR '.error() + ' Failed to parse mod metadata: ${error.message}');
        VSliceDebugLog.error('Mod Metadata Parse Error', error.message);

      case "parse_mod_version":
        // Polymod tries to load the mod's version, but it could not be parsed.
        trace(' ERROR '.error() + ' Failed to parse mod version: ${error.message}');
        VSliceDebugLog.error('Mod Version Parse Error', error.message);

      case "parse_mod_api_version":
        // Polymod tries to load the mod's API version, but it could not be parsed.
        trace(' ERROR '.error() + ' Failed to parse mod API version: ${error.message}');
        VSliceDebugLog.error('Mod API Version Parse Error', error.message);

      case "missing_icon":
        // A mod is missing an icon.
        trace(' WARNING '.warning() + ' A mod is missing an icon: ${error.message}');

      //
      // Mod Loading Errors
      //

      case "version_conflict_api":
        // Polymod tried to load a mod but failed because it has the wrong API version.
        // This is an important issue that requires user attention so it can be resolved by the mod developer.
        trace(' WARNING '.warning() + ' Failed to load mod - ${error.message}');

        var regex:EReg = ~/Mod "([-_a-zA-Z0-9]+)" is not compatible with API version "(.*?)", got "(.*?)"/;
        if (regex.match(error.message))
        {
          // Notify the user via formatted popup.
          var modId:String = regex.matched(1);
          // var apiVersion:String = regex.matched(2);
          var modVersion:String = regex.matched(3);

          var message:String = 'Installed mod "$modId" was built for modding version "v$modVersion". It is not compatible with game version ${Constants.GENERATED_BY}, and must be skipped.'
            + '\n\nPlease inform the mod developer that "$modId" must be updated for compatibility.';

          VSliceDebugLog.warning('Mod Outdated', message);
        }
        else
        {
          VSliceDebugLog.warning('Mod Outdated', error.message);
        }

      case MOD_LOAD_FAILED:
        // Polymod failed to load a mod. A different error would have already been logged.
        trace(' WARNING '.warning() + ' Failed to load mod - ${error.message}');

      case MOD_LOAD_DONE:
        trace(' INFO '.info() + ' Loaded mod - ${error.message}');

      //
      // Mod Dependency Errors
      //

      case "optional_dependency_unmet":
        // Polymod looked at the list of available mods, and one of them was missing an optional dependency.
        trace(' INFO '.info() + ' Installed mod is missing an optional dependency: ${error.message}');

      case "dependency_unmet":
        switch (error.origin)
        {
          case SCAN:
            // Polymod looked at the list of available mods, and one of them was missing a dependency.
            // This is an important warning that should be shown to the user.
            trace(' WARNING '.warning() + ' Installed mod is missing a dependency: ${error.message}');
            VSliceDebugLog.warning('Mod Dependency Error', error.message);
          default:
            // Polymod tried to load a mod, but failed because it has a dependency that wasn't met.
            // This is a major error that should be shown to the user.
            trace(' ERROR '.error() + ' Failed to load mod due to missing dependency: ${error.message}');
            VSliceDebugLog.error('Mod Dependency Error', error.message);
        }

      case "dependency_version_mismatch":
        switch (error.origin)
        {
          case SCAN:
            // Polymod looked at the list of available mods, and one of them has a dependency on a different mod,
            // but the mod has the wrong version.
            // This is an important warning that should be shown to the user.
            trace(' WARNING '.warning() + ' Installed mod has a mismatched dependency: ${error.message}');
            VSliceDebugLog.warning('Mod Dependency Error', error.message);
          default:
            // Polymod tried to load a mod, but failed because one of its dependencies was the wrong version.
            // This is a major error that should be shown to the user.
            trace(' ERROR '.error() + ' Failed to load mod due to mismatched dependency: ${error.message}');
            VSliceDebugLog.error('Mod Dependency Error', error.message);
        }

      case "dependency_cyclical":
        // Polymod tried to load a mod, but failed because one of its dependencies depends on that mod.
        // This is a major error that should be shown to the user.
        trace(' ERROR '.error() + ' Failed to load mod due to cyclical dependency: ${error.message}');
        VSliceDebugLog.error('Mod Dependency Error', error.message);

      //
      // Script Parsing Errors
      //

      case "script_parse_error":
        // A syntax error when parsing a script.
        trace(' ERROR '.error() + ' ' + error.message);
        VSliceDebugLog.error('Script Parsing Error', error.message);

      case SCRIPT_RUNTIME_EXCEPTION:
        // A runtime error when running a script.
        trace(' ERROR '.error() + ' ' + error.message);
        VSliceDebugLog.error('Script Exception', error.message);

      case "script_class_not_registered":
        // Polymod attempted to initialize a scripted class, but it wasn't registered.
        trace(' ERROR '.error() + ' ' + error.message);
        VSliceDebugLog.error('Script Parsing Error', error.message);

      case "script_class_already_registered":
        // Polymod attempted to register a scripted class, but one with the same name and package already exists.
        trace(' ERROR '.error() + ' ' + error.message);
        VSliceDebugLog.error('Script Parsing Error', error.message);

      case "script_class_module_already_imported":
        // A scripted class imported a module that's already imported.
        trace(' WARNING '.warning() + ' ' + error.message);

      case "script_class_module_not_found":
        // A scripted class tried to import a module that doesn't exist.
        trace(' ERROR '.error() + ' ' + error.message);
        VSliceDebugLog.error('Script Import Error', error.message);

      case "script_class_module_blacklisted":
        // A scripted class tried to import a module that's blacklisted.
        trace(' ERROR '.error() + ' ' + error.message);
        VSliceDebugLog.error('Script Blacklist Violation', error.message);

      case "script_class_field_blacklisted":
        // A scripted class tried to access a field that's blacklisted.
        trace(' ERROR '.error() + ' ' + error.message);
        VSliceDebugLog.error('Script Blacklist Violation', error.message);

      //
      // Other Errors
      //

      case "framework_init", "dependency_check_skipped", "script_parsing", "script_parsed":
        // Unimportant messages that we don't need to log.
        return;

      default:
        // Log the message based on its severity.
        switch (Std.string(error.severity))
        {
          case "ERROR":
            trace(' ERROR '.error() + ' ' + error.message);
          case "WARNING":
            trace(' WARNING '.warning() + ' ' + error.message);
          case "INFO", "NOTICE":
            trace(' INFO '.info() + ' ' + error.message);
          case "DEBUG":
            // trace(' DEBUG '.debug() + error.message);
          default:
            trace(' INFO '.info() + ' ' + error.message);
        }
    }
  }
}
