package options;

import backend.LanguagePackManager;
import backend.LanguagePackManager.LanguageSyncResult;
import backend.ThreadUtil;

/** JSON language selection and OTA package updates, using the standard options UI. */
class LanguageSubState extends BaseOptionsMenu
{
	#if TRANSLATIONS_ALLOWED
	var languageCodes:Array<String> = [];
	var languageNames:Array<String> = [];
	var syncing:Bool = false;
	var pendingSync:LanguageSyncResult = null;

	public function new()
	{
		title = Language.getPhrase('options.menus.language.title', 'Language');
		rpcTitle = Language.getPhrase('options.menus.language.presence', 'Language Menu');
		buildOptions();
		super();
	}

	function buildOptions():Void
	{
		languageCodes = [];
		languageNames = [];
		for (entry in Language.getAvailableLanguages())
		{
			if (languageCodes.contains(entry.code))
				continue;
			languageCodes.push(entry.code);
			languageNames.push(entry.name);
		}

		var order:Array<Int> = [for (i in 0...languageCodes.length) i];
		order.sort(function(a:Int, b:Int):Int
		{
			var left:String = languageNames[a].toLowerCase();
			var right:String = languageNames[b].toLowerCase();
			return left < right ? -1 : (left > right ? 1 : 0);
		});
		languageCodes = [for (i in order) languageCodes[i]];
		languageNames = [for (i in order) languageNames[i]];

		var languageOption = new Option(
			Language.getPhrase('options.language.selector.name', 'Language'),
			Language.getPhrase('options.language.selector.description', 'Choose an installed language pack.'),
			'language', STRING, languageNames, 'language_selector');
		languageOption.getValue = function():Dynamic
		{
			var index:Int = languageCodes.indexOf(ClientPrefs.data.language);
			return index >= 0 ? languageNames[index] : ClientPrefs.data.language;
		};
		languageOption.setValue = function(value:Dynamic):Dynamic
		{
			var index:Int = languageNames.indexOf(Std.string(value));
			if (index >= 0)
				ClientPrefs.data.language = languageCodes[index];
			return value;
		};
		var defaultIndex:Int = languageCodes.indexOf(ClientPrefs.defaultData.language);
		languageOption.defaultValue = languageNames[Std.int(Math.max(0, defaultIndex))];
		languageOption.curOption = Std.int(Math.max(0, languageCodes.indexOf(ClientPrefs.data.language)));
		languageOption.onChange = applyLanguage;
		addOption(languageOption);

		var syncOption = new Option(
			Language.getPhrase('options.language.sync.name', 'Download or update languages'),
			Language.getPhrase('options.language.sync.description', 'Checks the official catalog and safely installs new or updated language packs.'),
			'', ACTION, null, 'language_sync');
		syncOption.onChange = startSync;
		addOption(syncOption);
	}

	function applyLanguage():Void
	{
		ClientPrefs.saveSettings();
		Language.reloadPhrases();
		new FlxTimer().start(0.01, function(_)
		{
			title = Language.getPhrase('options.menus.language.title', 'Language');
			setMenuTitle(title);
			rebuildMenuOptions();
		});
	}

	function rebuildMenuOptions():Void
	{
		setOptionsList([]);
		buildOptions();
		setOptionsList(getOptionsCopy());
	}

	function startSync():Void
	{
		if (syncing)
			return;
		syncing = true;
		pendingSync = null;
		#if (target.threaded && sys)
		ThreadUtil.execAsync(function() pendingSync = LanguagePackManager.syncAll());
		#else
		pendingSync = LanguagePackManager.syncAll();
		#end
	}

	override function update(elapsed:Float):Void
	{
		super.update(elapsed);
		if (!syncing || pendingSync == null)
			return;

		var result:LanguageSyncResult = pendingSync;
		pendingSync = null;
		syncing = false;
		if (result.success)
			rebuildMenuOptions();

		var popupTitle:String = result.success
			? Language.getPhrase('options.language.sync.success_title', 'Languages updated')
			: Language.getPhrase('options.language.sync.error_title', 'Language update failed');
		var message:String = result.success
			? Language.getPhrase('options.language.sync.success', 'Installed: {1}. Already current: {2}.', [result.installed, result.skipped])
			: Language.getPhrase('options.language.sync.error', 'Could not update language packs:\n{1}', [result.message]);
		CoolUtil.showPopUp(message, popupTitle);
	}
	#else
	public function new()
	{
		title = 'Language';
		super();
	}
	#end
}
