package backend;

// Import all languages
import backend.languages.*;

class Language
{
	public static var defaultLangName:String = 'English (US)'; // en-US
	#if TRANSLATIONS_ALLOWED
	private static inline var DEFAULT_LANGUAGE_CODE:String = 'en-US';
	private static inline var JSON_LANGUAGE_ROOT:String = 'languages';
	private static var phrases:Map<String, String> = [];
	private static var runtimePhrases:Map<String, String> = [];
	public static var revision(default, null):Int = 0;
	// ← NEW CACHE FOR FORMATTED KEYS
	private static var keyCache:Map<String, String> = [];
	#end

	// ← NEW: List of available hardcoded languages
	private static var hardcodedLanguages:Array<Class<Dynamic>> = [
		EnUS, // English (United States)
		EsLA, // Español (Latin America)
		EsES, // Español (España)
		PtBR, // Português (Brasil)
		FrFR, // Français (France)
		ItIT, // Italiano (Italia)
		DeDE, // Deutsch (Deutschland)
		NlNL, // Nederlands (Nederland)
		ZhCN, // Chinese (Mainland)
		ZhHK, // Chinese (Hong Kong)
		JpJP, // Japanese (Japan)
		IdID // Indonesian (Bahasa Indonesia)
	];

	public static function reloadPhrases()
	{
		#if TRANSLATIONS_ALLOWED
		var langFile:String = ClientPrefs.data.language;
		if (langFile == null || langFile.trim().length == 0)
			langFile = DEFAULT_LANGUAGE_CODE;

		phrases.clear();
		runtimePhrases.clear();
		keyCache.clear(); // ← CLEAR THE KEY CACHE WHEN RECHARGING
		revision++;

		// English is always the final offline fallback. Existing hardcoded maps stay
		// usable while screens are migrated to namespaced JSON bundles.
		loadHardcodedLanguage(DEFAULT_LANGUAGE_CODE, phrases);
		loadJsonLanguage(DEFAULT_LANGUAGE_CODE, phrases);

		var selectedLoaded:Bool = langFile == DEFAULT_LANGUAGE_CODE;
		if (langFile != DEFAULT_LANGUAGE_CODE)
		{
			selectedLoaded = loadHardcodedLanguage(langFile, phrases);
			if (!selectedLoaded)
				selectedLoaded = loadLegacyLanguage(langFile, phrases);
			if (loadJsonLanguage(langFile, phrases))
				selectedLoaded = true;
		}

		if (!selectedLoaded)
		{
			ClientPrefs.data.language = DEFAULT_LANGUAGE_CODE;
			langFile = DEFAULT_LANGUAGE_CODE;
		}

		var alphaPath:String = getFileTranslation('images/alphabet');
		if (alphaPath.startsWith('images/'))
			alphaPath = alphaPath.substr('images/'.length);
		var pngPos:Int = alphaPath.indexOf('.png');
		if (pngPos > -1)
			alphaPath = alphaPath.substring(0, pngPos);
		AlphaCharacter.loadAlphabetData(alphaPath);
		#else
		AlphaCharacter.loadAlphabetData();
		#end
	}

	// ← NEW: Function to retrieve available languages
	public static function getAvailableLanguages():Array<{code:String, name:String}>
	{
		var languages:Array<{code:String, name:String}> = [];

		#if TRANSLATIONS_ALLOWED
		// Add hard-coded languages
		for (langClass in hardcodedLanguages)
		{
			var code:String = Reflect.field(langClass, 'languageCode');
			var name:String = Reflect.field(langClass, 'languageName');
			if (code != null && name != null)
			{
				languages.push({code: code, name: name});
			}
		}

		// JSON packs can add languages without compiling another Haxe class.
		for (path in Mods.directoriesWithFile(Paths.getSharedPath(), '$JSON_LANGUAGE_ROOT/index.json'))
		{
			try
			{
				var raw:String = AssetLoader.loadText(path);
				if (raw == null || raw.trim().length == 0)
					continue;
				var index:Dynamic = haxe.Json.parse(Paths.stripBOM(raw));
				var entries:Dynamic = Reflect.field(index, 'languages');
				if (!Std.isOfType(entries, Array))
					continue;

				for (entry in (cast entries:Array<Dynamic>))
				{
					var code:String = Reflect.field(entry, 'code');
					var name:String = Reflect.field(entry, 'name');
					if (code == null || code.trim().length == 0)
						continue;
					if (name == null || name.trim().length == 0)
						name = code;

					var found:Bool = false;
					for (language in languages)
					{
						if (language.code == code)
						{
							language.name = name;
							found = true;
							break;
						}
					}
					if (!found)
						languages.push({code: code, name: name});
				}
			}
			catch (e:Dynamic)
			{
				trace('Could not read language index "$path": $e');
			}
		}
		#else
		languages.push({code: "en-US", name: defaultLangName});
		#end

		return languages;
	}

	// ← NEW OPTIMIZED FEATURE FOR MULTIPLE TRANSLATIONS
	public static function getPhrases(keys:Array<String>, defaultPhrases:Array<String> = null):Array<String>
	{
		var results:Array<String> = [];

		#if TRANSLATIONS_ALLOWED
		for (i in 0...keys.length)
		{
			var key = keys[i];
			var defaultPhrase = (defaultPhrases != null && i < defaultPhrases.length) ? defaultPhrases[i] : null;

			var formattedKey:String = keyCache.get(key);
			if (formattedKey == null)
			{
				formattedKey = formatKey(key);
				keyCache.set(key, formattedKey);
			}

			var str:String = runtimePhrases.get(formattedKey);
			if (str == null)
				str = phrases.get(formattedKey);
			if (str == null)
				str = defaultPhrase;
			if (str == null)
				str = key;

			results.push(str);
		}
		#else
		for (i in 0...keys.length)
		{
			var defaultPhrase = (defaultPhrases != null && i < defaultPhrases.length) ? defaultPhrases[i] : keys[i];
			results.push(defaultPhrase);
		}
		#end

		return results;
	}

	// Gets a phrase from a specific language cache.
	public static function cacheSpecificPhrases(keys:Array<String>, defaults:Array<String>):Array<String>
	{
		var cached:Array<String> = [];
		for (i in 0...keys.length)
		{
			var defaultPhrase = (i < defaults.length) ? defaults[i] : keys[i];
			cached.push(getPhrase(keys[i], defaultPhrase));
		}
		return cached;
	}

	inline public static function getPhrase(key:String, ?defaultPhrase:String, values:Array<Dynamic> = null):String
	{
		#if TRANSLATIONS_ALLOWED
		// ← OPTIMIZATION: Cache of formatted keys to avoid repetitive calls to formatKey()
		var formattedKey:String = keyCache.get(key);
		if (formattedKey == null)
		{
			formattedKey = formatKey(key);
			keyCache.set(key, formattedKey);
		}

		var str:String = runtimePhrases.get(formattedKey);
		if (str == null)
			str = phrases.get(formattedKey);
		if (str == null)
			str = defaultPhrase;
		#else
		var str:String = defaultPhrase;
		#end

		if (str == null)
			str = key;

		// ← OPTIMIZATION: Process values only if they actually exist
		if (values != null && values.length > 0)
			for (num => value in values)
				str = str.replace('{${num + 1}}', value);

		return str;
	}

	public static function getPhraseForLanguage(langCode:String, key:String, ?defaultPhrase:String, values:Array<Dynamic> = null):String
	{
		#if TRANSLATIONS_ALLOWED
		var formattedKey:String = formatKey(key);
		var languagePhrases:Map<String, String> = [];
		loadHardcodedLanguage(DEFAULT_LANGUAGE_CODE, languagePhrases);
		loadJsonLanguage(DEFAULT_LANGUAGE_CODE, languagePhrases);
		if (langCode != DEFAULT_LANGUAGE_CODE)
		{
			var loaded:Bool = loadHardcodedLanguage(langCode, languagePhrases);
			if (!loaded)
				loadLegacyLanguage(langCode, languagePhrases);
			loadJsonLanguage(langCode, languagePhrases);
		}

		var str:String = languagePhrases.get(formattedKey);
		if (str == null)
			str = defaultPhrase;
		if (str == null)
			str = key;

		if (values != null && values.length > 0)
			for (num => value in values)
				str = str.replace('{${num + 1}}', value);
		return str;
		#end

		return getPhrase(key, defaultPhrase, values);
	}

	// More optimized for file loading
	inline public static function getFileTranslation(key:String)
	{
		#if TRANSLATIONS_ALLOWED
		// ← OPTIMIZATION: Direct cache for file translations (most common)
		var lowerKey = key.trim().toLowerCase();
		var str:String = runtimePhrases.get(lowerKey);
		if (str == null)
			str = phrases.get(lowerKey);
		if (str != null)
			key = str;
		#end
		return key;
	}

	/** Overrides a phrase until the next reloadPhrases() call. */
	public static function setPhrase(key:String, value:String):Bool
	{
		#if TRANSLATIONS_ALLOWED
		if (key == null || key.trim().length == 0 || value == null)
			return false;
		runtimePhrases.set(formatKey(key), value);
		revision++;
		return true;
		#else
		return false;
		#end
	}

	public static function removePhrase(key:String):Bool
	{
		#if TRANSLATIONS_ALLOWED
		if (key == null)
			return false;
		var formattedKey:String = formatKey(key);
		if (!runtimePhrases.exists(formattedKey))
			return false;
		runtimePhrases.remove(formattedKey);
		revision++;
		return true;
		#else
		return false;
		#end
	}

	public static function clearPhrases():Void
	{
		#if TRANSLATIONS_ALLOWED
		if (runtimePhrases.keys().hasNext())
		{
			runtimePhrases.clear();
			revision++;
		}
		#end
	}

	public static function hasPhrase(key:String):Bool
	{
		#if TRANSLATIONS_ALLOWED
		if (key == null)
			return false;
		var formattedKey:String = formatKey(key);
		return runtimePhrases.exists(formattedKey) || phrases.exists(formattedKey);
		#else
		return false;
		#end
	}

	#if TRANSLATIONS_ALLOWED
	// ← OPTIMIZATION: Use a regex as a static variable to avoid recreating it
	// Dots are intentionally preserved for namespaced keys such as
	// "playstate.hud.score" and "editor.charting.tabs.song".
	static final hideCharsRegex = ~/[~&\\\/;:<>#,'"%?!]/g;

	inline static private function formatKey(key:String)
	{
		return hideCharsRegex.replace(key.replace(' ', '_'), '').toLowerCase().trim();
	}

	private static function loadHardcodedLanguage(langCode:String, target:Map<String, String>):Bool
	{
		for (langClass in hardcodedLanguages)
		{
			var languageCode:String = Reflect.field(langClass, 'languageCode');
			if (languageCode != langCode)
				continue;

			var languageName:String = Reflect.field(langClass, 'languageName');
			var translations:Map<String, String> = Reflect.field(langClass, 'translations');
			if (languageName != null)
				target.set('language_name', languageName);
			if (translations != null)
				for (key => value in translations)
					target.set(formatKey(key), value);
			return translations != null;
		}
		return false;
	}

	private static function loadLegacyLanguage(langCode:String, target:Map<String, String>):Bool
	{
		var loadedText:Array<String> = Mods.mergeAllTextsNamed('data/$langCode.lang');
		var loaded:Bool = false;
		for (num => phrase in loadedText)
		{
			phrase = phrase.trim();
			if (num < 1 && !phrase.contains(':'))
			{
				target.set('language_name', phrase);
				continue;
			}
			if (phrase.length < 4 || phrase.startsWith('//'))
				continue;

			var separator:Int = phrase.indexOf(':');
			if (separator < 0)
				continue;
			var quoteStart:Int = phrase.indexOf('"', separator);
			var quoteEnd:Int = phrase.lastIndexOf('"');
			if (quoteStart < 0 || quoteEnd <= quoteStart)
				continue;

			var key:String = formatKey(phrase.substr(0, separator));
			var value:String = phrase.substring(quoteStart + 1, quoteEnd).replace('\\n', '\n');
			target.set(key, value);
			loaded = true;
		}
		return loaded;
	}

	private static function loadJsonLanguage(langCode:String, target:Map<String, String>):Bool
	{
		var loaded:Bool = false;
		var manifestRelative:String = '$JSON_LANGUAGE_ROOT/$langCode/manifest.json';
		for (manifestPath in Mods.directoriesWithFile(Paths.getSharedPath(), manifestRelative))
		{
			try
			{
				var rawManifest:String = AssetLoader.loadText(manifestPath);
				if (rawManifest == null || rawManifest.trim().length == 0)
					continue;
				var manifest:Dynamic = haxe.Json.parse(Paths.stripBOM(rawManifest));
				var languageName:String = Reflect.field(manifest, 'name');
				if (languageName != null && languageName.trim().length > 0)
					target.set('language_name', languageName);

				var bundles:Dynamic = Reflect.field(manifest, 'bundles');
				if (!Std.isOfType(bundles, Array))
					continue;

				var manifestFolder:String = haxe.io.Path.directory(manifestPath).replace('\\', '/');
				for (bundleEntry in (cast bundles:Array<Dynamic>))
				{
					var bundle:String = Std.string(bundleEntry).replace('\\', '/');
					if (bundle.length == 0 || bundle.startsWith('/') || bundle.indexOf('..') != -1)
						continue;
					var bundlePath:String = '$manifestFolder/$bundle';
					var rawBundle:String = AssetLoader.loadText(bundlePath);
					if (rawBundle == null || rawBundle.trim().length == 0)
						continue;

					var bundleData:Dynamic = haxe.Json.parse(Paths.stripBOM(rawBundle));
					var namespace:String = Reflect.field(bundleData, "$namespace");
					if (namespace == null)
						namespace = '';
					if (addJsonPhrases(bundleData, namespace, target) > 0)
						loaded = true;
				}
			}
			catch (e:Dynamic)
			{
				trace('Could not load JSON language manifest "$manifestPath": $e');
			}
		}
		return loaded;
	}

	private static function addJsonPhrases(data:Dynamic, prefix:String, target:Map<String, String>):Int
	{
		if (data == null)
			return 0;

		var added:Int = 0;
		for (field in Reflect.fields(data))
		{
			if (field.startsWith('$'))
				continue;
			var value:Dynamic = Reflect.field(data, field);
			var key:String = prefix == null || prefix.length == 0 ? field : '$prefix.$field';
			if (Std.isOfType(value, String))
			{
				target.set(formatKey(key), cast value);
				added++;
			}
			else if (value != null && !Std.isOfType(value, Array))
				added += addJsonPhrases(value, key, target);
		}
		return added;
	}
	#end

	// Function to retrieve localized introTexts
	public static function getLocalizedIntroTexts():Array<Array<String>>
	{
		#if TRANSLATIONS_ALLOWED
		var langFile:String = ClientPrefs.data.language;

		// Search in hard-coded languages
		for (langClass in hardcodedLanguages)
		{
			var languageCode:String = Reflect.field(langClass, 'languageCode');
			if (languageCode == langFile)
			{
				var introTexts:Array<Array<String>> = Reflect.field(langClass, 'introTexts');
				if (introTexts != null && introTexts.length > 0)
				{
					return introTexts;
				}
				break;
			}
		}
		#end

		// If there are no localized introTexts, return null to use the default file
		return null;
	}

	#if LUA_ALLOWED
	public static function addLuaCallbacks(lua:State)
	{
		Lua_helper.add_callback(lua, "getTranslationPhrase", function(key:String, ?defaultPhrase:String, ?values:Array<Dynamic> = null)
		{
			return getPhrase(key, defaultPhrase, values);
		});

		Lua_helper.add_callback(lua, "getFileTranslation", function(key:String)
		{
			return getFileTranslation(key);
		});

		Lua_helper.add_callback(lua, "setTranslationPhrase", function(key:String, value:String)
		{
			return setPhrase(key, value);
		});

		Lua_helper.add_callback(lua, "removeTranslationPhrase", function(key:String)
		{
			return removePhrase(key);
		});

		Lua_helper.add_callback(lua, "hasTranslationPhrase", function(key:String)
		{
			return hasPhrase(key);
		});

		Lua_helper.add_callback(lua, "clearTranslationPhrases", function()
		{
			clearPhrases();
		});

		Lua_helper.add_callback(lua, "getCurrentLanguage", function()
		{
			return ClientPrefs.data.language;
		});
	}
	#end
}

