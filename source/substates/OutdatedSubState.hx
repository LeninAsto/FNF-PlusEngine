package substates;

import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import haxe.Http;

import states.MainMenuState;

class OutdatedSubState extends MusicBeatSubstate
{
    public static var updateVersion:String = ""; // Agregar esta variable estática
    
	public var leftState:Bool = false;
    public var changelogLoaded:Bool = false;
    public var changelog:String = "";

	public var bg:FlxSprite;
    public var titleText:FlxText;
    public var versionText:FlxText;
    public var changelogText:FlxText;
    public var controlsText:FlxText;

	override function create()
	{
		controls.isInSubstate = true;
		final enter:String = (controls.mobileC) ? 'A' : 'ENTER';
		final back:String = (controls.mobileC) ? 'B' : 'BACK';

		super.create();

		bg = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		bg.scrollFactor.set();
		bg.alpha = 0.0;
		add(bg);

        // Title text - "Update Available!"
        titleText = new FlxText(0, 50, FlxG.width, 
            Language.getPhrase('update_available_title', "Update Available!")
        );
        titleText.setFormat(Paths.font('vcr.ttf'), 48, FlxColor.YELLOW, CENTER);
        titleText.scrollFactor.set();
        titleText.alpha = 0.0;
        add(titleText);

        // Version comparison text
        versionText = new FlxText(0, 120, FlxG.width,
            Language.getPhrase('version_comparison', "Current Version: {1} => New Version: {2}", 
                [MainMenuState.plusEngineVersion, updateVersion])
        );
        versionText.setFormat(Paths.font('vcr.ttf'), 24, FlxColor.WHITE, CENTER);
        versionText.scrollFactor.set();
        versionText.alpha = 0.0;
        add(versionText);

        // Changelog text (will be loaded from GitHub)
        changelogText = new FlxText(50, 180, FlxG.width - 100,
            Language.getPhrase('loading_changelog', "Loading changelog...")
        );
        changelogText.setFormat(Paths.font('vcr.ttf'), 22, FlxColor.CYAN, LEFT);
        changelogText.scrollFactor.set();
        changelogText.alpha = 0.0;
        add(changelogText);

        // Controls text - Diferentes instrucciones para móvil y PC
        #if mobile
        controlsText = new FlxText(0, FlxG.height - 120, FlxG.width,
            Language.getPhrase('update_controls_mobile',
                "Press A to update to the latest version\nPress B if you're on the correct engine version\nYou can disable this warning in Options Menu"
            )
        );
        #else
        controlsText = new FlxText(0, FlxG.height - 120, FlxG.width,
            Language.getPhrase('update_controls',
                "Press ENTER to update to the latest version\nPress ESCAPE if you're on the correct engine version\nYou can disable this warning in Options Menu"
            )
        );
        #end
        controlsText.setFormat(Paths.font('vcr.ttf'), 20, FlxColor.WHITE, CENTER);
        controlsText.scrollFactor.set();
        controlsText.alpha = 0.0;
        add(controlsText);

        // TouchPad para dispositivos móviles con animación visible
        #if mobile
        addTouchPad("NONE", "A_B");
        touchPad.alpha = 1.0;
        #end

		// Start animations
		FlxTween.tween(bg, { alpha: 0.8 }, 0.6, { ease: FlxEase.sineIn });
        FlxTween.tween(titleText, { alpha: 1.0 }, 0.6, { ease: FlxEase.sineIn });
        FlxTween.tween(versionText, { alpha: 1.0 }, 0.8, { ease: FlxEase.sineIn });
        FlxTween.tween(changelogText, { alpha: 1.0 }, 1.0, { ease: FlxEase.sineIn });
        FlxTween.tween(controlsText, { alpha: 1.0 }, 1.2, { ease: FlxEase.sineIn });

        // Load changelog from GitHub
        loadChangelog();
    }

    function loadChangelog():Void
    {
        var http = new Http("https://raw.githubusercontent.com/LeninAsto/FNF-PlusEngine/refs/heads/main/gitChangelog.txt");
        
        http.onData = function(data:String) {
            changelog = data;
            changelogLoaded = true;
            updateChangelogDisplay();
        };
        
        http.onError = function(error:String) {
            changelog = Language.getPhrase('changelog_error', "Error loading changelog: {1}", [error]);
            changelogLoaded = true;
            updateChangelogDisplay();
        };
        
        http.request();
    }

    function updateChangelogDisplay():Void
    {
        if (changelogLoaded && changelogText != null) {
            changelogText.text = Language.getPhrase('changelog_title', "What's New:\n{1}", [changelog]);
        }
	}

	override function update(elapsed:Float)
	{
		if(!leftState) {
			if (controls.ACCEPT) {
				leftState = true;
                CoolUtil.browserLoad("https://github.com/LeninAsto/FNF-PlusEngine/releases");
			}
			else if(controls.BACK) {
				leftState = true;
			}
			if(leftState)
			{
				FlxG.sound.play(Paths.sound('cancelMenu'));
				
				// Animar touchPad para que desaparezca en móviles
				#if mobile
				if (touchPad != null) {
					FlxTween.tween(touchPad, { alpha: 0.0 }, 0.5, { ease: FlxEase.sineOut });
				}
				#end
				
				FlxTween.tween(bg, { alpha: 0.0 }, 0.9, { ease: FlxEase.sineOut });
                FlxTween.tween(titleText, {alpha: 0}, 1, { ease: FlxEase.sineOut });
                FlxTween.tween(versionText, {alpha: 0}, 1, { ease: FlxEase.sineOut });
                FlxTween.tween(changelogText, {alpha: 0}, 1, { ease: FlxEase.sineOut });
                FlxTween.tween(controlsText, {alpha: 0}, 1, {
					ease: FlxEase.sineOut,
					onComplete: function (twn:FlxTween) {
						FlxG.state.persistentUpdate = true;
						controls.isInSubstate = false;
						close();
					}
				});
			}
		}
		super.update(elapsed);
	}
}
