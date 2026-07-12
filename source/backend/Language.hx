package backend;

// Importar todos los idiomas
import backend.languages.*;

class Language
{
	public static var defaultLangName:String = 'English (US)'; //en-US
	#if TRANSLATIONS_ALLOWED
	private static var phrases:Map<String, String> = [];
    // ← NUEVO CACHE PARA KEYS FORMATEADAS
    private static var keyCache:Map<String, String> = [];
    #end

    // ← NUEVO: Lista de idiomas hardcodeados disponibles
    private static var hardcodedLanguages:Array<Class<Dynamic>> = [
        EnUS,    // Inglés (Estados Unidos)
        EsLA,    // Español (Latinoamérica)
        EsES,    // Español (España)
        PtBR,    // Português (Brasil)
        FrFR,    // Français (France)
        ItIT,    // Italiano (Italia)
        DeDE,    // Deutsch (Deutschland)
        NlNL,    // Nederlands (Nederland)
        //ZhCN,    // Chinese (Mainland) - needs more support
        //ZhHK,    // Chinese (Hong Kong) - needs more support
        //JpJP,     // Japanese (Japan) - needs more support
		IdID      // Indonesian (Bahasa Indonesia)
    ];

	public static function reloadPhrases()
	{
		#if TRANSLATIONS_ALLOWED
		var langFile:String = ClientPrefs.data.language;
		phrases.clear();
        keyCache.clear(); // ← LIMPIAR CACHE DE KEYS AL RECARGAR
		var hasPhrases:Bool = false;
        
        // ← NUEVO: Intentar cargar desde archivos .hx hardcodeados primero
        for (langClass in hardcodedLanguages) {
            // "9-Code-Name" wow cool word uh
            var languageCode:String = Reflect.field(langClass, 'languageCode');
            var languageName:String = Reflect.field(langClass, 'languageName');
            var translations:Map<String, String> = Reflect.field(langClass, 'translations');
            
            if (languageCode == langFile && translations != null) {
                // Cargar nombre del idioma
                phrases.set('language_name', languageName);
                
                // Cargar todas las traducciones
                for (key => value in translations) {
                    phrases.set(key.toLowerCase(), value);
                }
                hasPhrases = true;
                break;
            }
        }
        
        // ← FALLBACK: Si no se encuentra hardcodeado, intentar cargar desde archivo .lang
        if (!hasPhrases) {
            var loadedText:Array<String> = Mods.mergeAllTextsNamed('data/$langFile.lang');
            
		for (num => phrase in loadedText)
		{
			phrase = phrase.trim();
			if(num < 1 && !phrase.contains(':'))
			{
				phrases.set('language_name', phrase.trim());
				continue;
			}

			if(phrase.length < 4 || phrase.startsWith('//')) continue; 

			var n:Int = phrase.indexOf(':');
			if(n < 0) continue;

			var key:String = phrase.substr(0, n).trim().toLowerCase();

			var value:String = phrase.substr(n);
			n = value.indexOf('"');
			if(n < 0) continue;

			phrases.set(key, value.substring(n+1, value.lastIndexOf('"')).replace('\\n', '\n'));
			hasPhrases = true;
		}
        }

		if(!hasPhrases) ClientPrefs.data.language = ClientPrefs.defaultData.language;
		
		var alphaPath:String = getFileTranslation('images/alphabet');
		if(alphaPath.startsWith('images/')) alphaPath = alphaPath.substr('images/'.length);
		var pngPos:Int = alphaPath.indexOf('.png');
		if(pngPos > -1) alphaPath = alphaPath.substring(0, pngPos);
		AlphaCharacter.loadAlphabetData(alphaPath);
		#else
		AlphaCharacter.loadAlphabetData();
		#end
	}

    // ← NUEVO: Función para obtener idiomas disponibles
    public static function getAvailableLanguages():Array<{code:String, name:String}> {
        var languages:Array<{code:String, name:String}> = [];
        
        #if TRANSLATIONS_ALLOWED
        // Agregar idiomas hardcodeados
        for (langClass in hardcodedLanguages) {
            var code:String = Reflect.field(langClass, 'languageCode');
            var name:String = Reflect.field(langClass, 'languageName');
            if (code != null && name != null) {
                languages.push({code: code, name: name});
            }
        }
        #else
        languages.push({code: "en-US", name: defaultLangName});
        #end
        
        return languages;
    }

    // ← NUEVA FUNCIÓN OPTIMIZADA PARA MÚLTIPLES TRADUCCIONES
    public static function getPhrases(keys:Array<String>, defaultPhrases:Array<String> = null):Array<String> {
        var results:Array<String> = [];
        
        #if TRANSLATIONS_ALLOWED
        for (i in 0...keys.length) {
            var key = keys[i];
            var defaultPhrase = (defaultPhrases != null && i < defaultPhrases.length) ? defaultPhrases[i] : null;
            
            var formattedKey:String = keyCache.get(key);
            if (formattedKey == null) {
                formattedKey = formatKey(key);
                keyCache.set(key, formattedKey);
            }
            
            var str:String = phrases.get(formattedKey);
            if(str == null) str = defaultPhrase;
            if(str == null) str = key;
            
            results.push(str);
        }
        #else
        for (i in 0...keys.length) {
            var defaultPhrase = (defaultPhrases != null && i < defaultPhrases.length) ? defaultPhrases[i] : keys[i];
            results.push(defaultPhrase);
        }
        #end
        
        return results;
    }

    // ← NUEVA FUNCIÓN PARA CACHE ESPECÍFICO (usado por JudCounter)
    public static function cacheSpecificPhrases(keys:Array<String>, defaults:Array<String>):Array<String> {
        var cached:Array<String> = [];
        for (i in 0...keys.length) {
            var defaultPhrase = (i < defaults.length) ? defaults[i] : keys[i];
            cached.push(getPhrase(keys[i], defaultPhrase));
        }
        return cached;
    }

	inline public static function getPhrase(key:String, ?defaultPhrase:String, values:Array<Dynamic> = null):String
	{
		#if TRANSLATIONS_ALLOWED
        // ← OPTIMIZACIÓN: Cache de keys formateadas para evitar formatKey() repetitivo
        var formattedKey:String = keyCache.get(key);
        if (formattedKey == null) {
            formattedKey = formatKey(key);
            keyCache.set(key, formattedKey);
        }
        
        var str:String = phrases.get(formattedKey);
		if(str == null) str = defaultPhrase;
		#else
		var str:String = defaultPhrase;
		#end

		if(str == null)
			str = key;
		
        // ← OPTIMIZACIÓN: Solo procesar valores si realmente existen
        if(values != null && values.length > 0)
			for (num => value in values)
				str = str.replace('{${num+1}}', value);

		return str;
	}

	// More optimized for file loading
	inline public static function getFileTranslation(key:String)
	{
		#if TRANSLATIONS_ALLOWED
        // ← OPTIMIZACIÓN: Cache directo para file translations (más comunes)
        var lowerKey = key.trim().toLowerCase();
        var str:String = phrases.get(lowerKey);
		if(str != null) key = str;
		#end
		return key;
	}
	
	#if TRANSLATIONS_ALLOWED
    // ← OPTIMIZACIÓN: Regex como variable estática para evitar recrearlo
    static final hideCharsRegex = ~/[~&\\\/;:<>#.,'"%?!]/g;
    
	inline static private function formatKey(key:String)
	{
        return hideCharsRegex.replace(key.replace(' ', '_'), '').toLowerCase().trim();
	}
	#end

	// Función para obtener introTexts localizados
	public static function getLocalizedIntroTexts():Array<Array<String>>
	{
		#if TRANSLATIONS_ALLOWED
		var langFile:String = ClientPrefs.data.language;
		
		// Buscar en idiomas hardcodeados
		for (langClass in hardcodedLanguages) {
			var languageCode:String = Reflect.field(langClass, 'languageCode');
			if (languageCode == langFile) {
				var introTexts:Array<Array<String>> = Reflect.field(langClass, 'introTexts');
				if (introTexts != null && introTexts.length > 0) {
					return introTexts;
				}
				break;
			}
		}
		#end
		
		// Si no hay introTexts localizados, devolver null para usar el archivo default
		return null;
	}

	#if LUA_ALLOWED
	public static function addLuaCallbacks(lua:State) {
		Lua_helper.add_callback(lua, "getTranslationPhrase", function(key:String, ?defaultPhrase:String, ?values:Array<Dynamic> = null) {
			return getPhrase(key, defaultPhrase, values);
		});

		Lua_helper.add_callback(lua, "getFileTranslation", function(key:String) {
			return getFileTranslation(key);
		});
	}
	#end
}
