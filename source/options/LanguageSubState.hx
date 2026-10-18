package options;

import backend.LanguagePackManager;
import backend.LanguagePackManager.LanguageSyncResult;
import backend.ThreadUtil;

/** JSON language selection and OTA package updates, using the standard options UI. */
class LanguageSubState extends BaseOptionsMenu
{
	#if TRANSLATIONS_ALLOWED
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
		var available = Language.getAvailableLanguages();
		available.sort(function(a, b):Int
		{
			var left:String = a.name.toLowerCase();
			var right:String = b.name.toLowerCase();
			return left < right ? -1 : (left > right ? 1 : 0);
		});

		for (entry in available)
		{
			var code:String = entry.code;
			var active:Bool = code == ClientPrefs.data.language;
			var label:String = active
				? Language.getPhrase('options.language.selector.active', '{1} (Active)', [entry.name])
				: entry.name;
			var languageOption = new Option(label,
				Language.getPhrase('options.language.selector.description', 'Apply the {1} language pack.', [entry.name]),
				'', ACTION, null, 'language_${Option.normalizeTranslationKey(code)}');
			languageOption.selectable = !active;
			languageOption.onChange = function() applyLanguage(code);
			addOption(languageOption);
		}

		var syncOption = new Option(
			Language.getPhrase('options.language.sync.name', 'Download or update languages'),
			Language.getPhrase('options.language.sync.description', 'Checks the official catalog and safely installs new or updated language packs.'),
			'', ACTION, null, 'language_sync');
		syncOption.onChange = startSync;
		addOption(syncOption);
	}

	function applyLanguage(code:String):Void
	{
		ClientPrefs.data.language = code;
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
