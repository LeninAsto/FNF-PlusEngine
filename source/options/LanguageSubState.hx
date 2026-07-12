package options;

import openfl.utils.Assets;

class LanguageSubState extends MusicBeatSubstate
{
	#if TRANSLATIONS_ALLOWED
	var grpLanguages:FlxTypedGroup<Alphabet> = new FlxTypedGroup<Alphabet>();
	var languages:Array<String> = [];
	var displayLanguages:Map<String, String> = [];
	var curSelected:Int = 0;
	
	// Usando el mismo sistema de descText que BaseOptionsMenu
	private var descBox:FlxSprite;
	private var descText:FlxText;
	
	public var title:String;
	public var rpcTitle:String;
	
	public function new()
	{
		title = Language.getPhrase('language_menu', 'Language');
		rpcTitle = 'Language Menu';
		
		super();

		#if DISCORD_ALLOWED
		DiscordClient.changePresence(rpcTitle, null);
		#end
		
		var bg = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		bg.color = 0xFFea71fd;
		bg.screenCenter();
		bg.antialiasing = ClientPrefs.data.antialiasing;
		add(bg);

		add(grpLanguages);

		// Crear el sistema de descripción como en BaseOptionsMenu
		descBox = new FlxSprite().makeGraphic(1, 1, FlxColor.BLACK);
		descBox.alpha = 0.6;
		add(descBox);

		var titleText:Alphabet = new Alphabet(75, 45, title, true);
		titleText.setScale(0.6);
		titleText.alpha = 0.4;
		add(titleText);

		descText = new FlxText(50, 600, 1180, "", 32);
		descText.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		descText.scrollFactor.set();
		descText.borderSize = 2.4;
		add(descText);

		// ← NUEVO: Cargar idiomas hardcodeados primero
		var hardcodedLanguages = Language.getAvailableLanguages();
		for (lang in hardcodedLanguages) {
			if (!languages.contains(lang.code)) {
				languages.push(lang.code);
				displayLanguages.set(lang.code, lang.name);
			}
		}

		// ← MANTENER: Cargar idiomas desde archivos .lang como fallback
		var directories:Array<String> = Mods.directoriesWithFile(Paths.getSharedPath(), 'data/');
		for (directory in directories)
		{
			for (file in FileSystem.readDirectory(directory))
			{
				if(file.toLowerCase().endsWith('.lang'))
				{
					var langFile:String = file.substring(0, file.length - '.lang'.length).trim();
					if(!languages.contains(langFile))
						languages.push(langFile);

					if(!displayLanguages.exists(langFile))
					{
						var path:String = '$directory/$file';
						#if MODS_ALLOWED 
						var txt:String = File.getContent(path);
						#else
						var txt:String = Assets.getText(path);
						#end

						var id:Int = txt.indexOf('\n');
						if(id > 0) //language display name shouldnt be an empty string or null
						{
							var name:String = txt.substr(0, id).trim();
							if(!name.contains(':')) displayLanguages.set(langFile, name);
						}
						else if(txt.trim().length > 0 && !txt.contains(':')) displayLanguages.set(langFile, txt.trim());
					}
				}
			}
		}

		languages.sort(function(a:String, b:String)
		{
			a = (displayLanguages.exists(a) ? displayLanguages.get(a) : a).toLowerCase();
			b = (displayLanguages.exists(b) ? displayLanguages.get(b) : b).toLowerCase();
			if (a < b) return -1;
			else if (a > b) return 1;
			return 0;
		});

		//trace(ClientPrefs.data.language);
		curSelected = languages.indexOf(ClientPrefs.data.language);
		if(curSelected < 0)
		{
			//trace('Language not found: ' + ClientPrefs.data.language);
			ClientPrefs.data.language = ClientPrefs.defaultData.language;
			curSelected = Std.int(Math.max(0, languages.indexOf(ClientPrefs.data.language)));
		}

		for (num => lang in languages)
		{
			var name:String = displayLanguages.get(lang);
			if(name == null) name = lang;

			var text:Alphabet = new Alphabet(0, 300, name, true);
			text.isMenuItem = true;
			text.targetY = num;
			text.changeX = false;
			text.distancePerItem.y = 100;
			if(languages.length < 7)
			{
				text.changeY = false;
				text.screenCenter(Y);
				text.y += (100 * (num - (languages.length / 2))) + 45;
			}
			text.screenCenter(X);
			grpLanguages.add(text);
		}
		changeSelected();
		updateExampleText();

		addTouchPad('LEFT_FULL', 'A_B');
	}

	var changedLanguage:Bool = false;
	override function update(elapsed:Float)
	{
		super.update(elapsed);

		var mult:Int = (FlxG.keys.pressed.SHIFT) ? 4 : 1;
		if(controls.UI_UP_P)
			changeSelected(-1 * mult);
		if(controls.UI_DOWN_P)
			changeSelected(1 * mult);
		if(FlxG.mouse.wheel != 0)
			changeSelected(FlxG.mouse.wheel * mult);

		if(controls.BACK)
		{
			if(changedLanguage)
			{
				FlxTransitionableState.skipNextTransIn = true;
				FlxTransitionableState.skipNextTransOut = true;
				MusicBeatState.resetState();
			}
			else close();
			FlxG.sound.play(Paths.sound('cancelMenu'));
		}

		if(controls.ACCEPT)
		{
			FlxG.sound.play(Paths.sound('confirmMenu'), 0.6);
			ClientPrefs.data.language = languages[curSelected];
			//trace(ClientPrefs.data.language);
			ClientPrefs.saveSettings();
			Language.reloadPhrases();
			changedLanguage = true;
		}
	}

	function changeSelected(change:Int = 0)
	{
		curSelected = FlxMath.wrap(curSelected + change, 0, languages.length-1);
		for (num => lang in grpLanguages)
		{
			lang.targetY = num - curSelected;
			lang.alpha = 0.6;
			if(num == curSelected) lang.alpha = 1;
		}
		updateExampleText();
		FlxG.sound.play(Paths.sound('scrollMenu'), 0.6);
	}

	function updateExampleText()
	{
		if (descText == null) return; // Verificación de seguridad
		
		if (languages.length > 0 && curSelected >= 0 && curSelected < languages.length)
		{
			var currentLang = languages[curSelected];
			var exampleString = getExampleTextForLanguage(currentLang);
			descText.text = exampleString;
			
			// Centrar el texto como en BaseOptionsMenu
			descText.screenCenter(Y);
			descText.y += 270;
			
			// Actualizar el fondo
			descBox.setPosition(descText.x - 10, descText.y - 10);
			descBox.setGraphicSize(Std.int(descText.width + 20), Std.int(descText.height + 25));
			descBox.updateHitbox();
		}
	}

	function getExampleTextForLanguage(langCode:String):String
	{
		// Definir textos de ejemplo hardcodeados para cada idioma
		var exampleTexts:Map<String, String> = [
			'en-US' => 'This is an example text in English United States language',
			'es-LA' => 'Este es un ejemplo de texto en el idioma Español Latinoamérica',
			'es-ES' => 'Este es un ejemplo de texto en el idioma Español de España',
			'fr-FR' => 'Ceci est un exemple de texte en langue Française France',
			'pt-BR' => 'Este é um exemplo de texto no idioma Português Brasil',
			'it-IT' => 'Questo è un esempio di testo nella lingua Italiana Italia',
			'de-DE' => 'Dies ist ein Beispieltext in deutscher Sprache Deutschland',
			'ja-JP' => 'これは日本語での例文テキストです',
			'nl-NL' => 'Dit is een voorbeeldtekst in de Nederlandse taal Nederland',
			'zh-CN' => '这是中文（简体）语言的示例文本',
			'zh-HK' => '這是中文（香港）語言的示例文本',
			"id-ID" => 'Ini adalah teks contoh dalam bahasa Indonesia Nusantara'
		];
		
		// Buscar por código de idioma exacto primero
		if (exampleTexts.exists(langCode))
			return exampleTexts.get(langCode);
		
		// Fallback a texto en inglés
		return 'This is an example text in the selected language';
	}
	#end
}
