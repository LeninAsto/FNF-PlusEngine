#if android
package mobile.states;

import backend.ClientPrefs;
import backend.Language;
import backend.ui.PsychUIButton;
import mobile.backend.StorageUtil;
import states.TitleState;

class AndroidPermissionsState extends MusicBeatState
{
	var titleText:FlxText;
	var statusText:FlxText;
	var subtitleText:FlxText;

	override function create():Void
	{
		Paths.clearStoredMemory();
		super.create();
		Paths.clearUnusedMemory();

		var bg = new FlxSprite().makeGraphic(1, 1, 0xFF151515);
		bg.scale.set(FlxG.width, FlxG.height);
		bg.updateHitbox();
		add(bg);

		titleText = new FlxText(40, 36, FlxG.width - 80, Language.getPhrase('android_tools_title', 'ANDROID TOOLS'), 28);
		titleText.setFormat(Paths.font('vcr.ttf'), 28, FlxColor.WHITE, CENTER);
		titleText.scrollFactor.set();
		add(titleText);

		subtitleText = new FlxText(40, 120, FlxG.width - 80,
			Language.getPhrase('android_tools_subtitle', 'Here you can request permissions or reload the alphabet without wrestling the system.'),
			24);
		subtitleText.setFormat(Paths.font('vcr.ttf'), 24, FlxColor.WHITE, CENTER);
		subtitleText.scrollFactor.set();
		add(subtitleText);

		statusText = new FlxText(40, 220, FlxG.width - 80, '', 22);
		statusText.setFormat(Paths.font('vcr.ttf'), 22, FlxColor.WHITE, LEFT);
		statusText.scrollFactor.set();
		add(statusText);

		var requestButton = new PsychUIButton(60, FlxG.height - 180, Language.getPhrase('android_tools_request', 'REQUEST PERMISSIONS'), function()
		{
			StorageUtil.requestPermissions();
			refreshStatus();
		}, 220, 48);
		add(requestButton);

		var reloadAlphabetButton = new PsychUIButton(60, FlxG.height - 120, Language.getPhrase('android_tools_reload', 'RELOAD ALPHABET'), function()
		{
			Language.reloadPhrases();
			CoolUtil.showPopUp(
				Language.getPhrase('android_tools_reload_popup', 'Alphabet reloaded successfully. If the cache was weird, it is now refreshed.'),
				Language.getPhrase('android_tools_popup_title', 'Android Tools')
			);
			refreshStatus();
		}, 220, 48);
		add(reloadAlphabetButton);

		var backButton = new PsychUIButton(60, FlxG.height - 60, Language.getPhrase('back', 'BACK'), goBack, 140, 40);
		add(backButton);

		refreshStatus();
		addTouchPad('NONE', 'A_B');
		addTouchPadCamera();
	}

	function refreshStatus():Void
	{
		statusText.text = Language.getPhrase('android_tools_storage_mode', 'Storage mode') + ': ${ClientPrefs.data.storageType}\n' + StorageUtil.getPermissionStatus();
	}

	function goBack():Void
	{
		FlxTransitionableState.skipNextTransIn = true;
		FlxTransitionableState.skipNextTransOut = true;
		MusicBeatState.switchState(new TitleState());
	}

	override function update(elapsed:Float):Void
	{
		if (controls.BACK #if android || FlxG.android.justReleased.BACK #end)
		{
			goBack();
			return;
		}

		super.update(elapsed);
	}
}
#else
package mobile.states;

class AndroidPermissionsState extends MusicBeatState {}
#end
