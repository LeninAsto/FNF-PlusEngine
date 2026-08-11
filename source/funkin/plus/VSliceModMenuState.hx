package funkin.plus;

import backend.MusicBeatState;
import backend.Paths;
import flixel.FlxG;
import flixel.FlxSprite;
import funkin.PlayerSettings;
import funkin.graphics.shaders.HSVShader;
import funkin.ui.options.ModMenu;
import states.ModsManagerSelectorState;

class VSliceModMenuState extends MusicBeatState
{
  var menu:ModMenu;
  var exiting:Bool = false;

  override function create():Void
  {
    super.create();

    if (PlayerSettings.player1 == null) PlayerSettings.init();

    var menuBG = new FlxSprite().loadGraphic(funkin.Paths.image('menuBG'));
    menuBG.shader = new HSVShader(-0.6, 0.9, 3.6);
    menuBG.setGraphicSize(Std.int(FlxG.width * 1.1));
    menuBG.updateHitbox();
    menuBG.screenCenter();
    menuBG.scrollFactor.set(0, 0);
    add(menuBG);

    menu = new ModMenu();
    menu.onExit.add(saveAndExit);
    add(menu);

    addTouchPad('UP_DOWN', 'A_B');
  }

  override function update(elapsed:Float):Void
  {
    if (!exiting && controls.BACK)
    {
      saveAndExit();
      return;
    }

    super.update(elapsed);
  }

  function saveAndExit():Void
  {
    if (exiting) return;
    exiting = true;
    if (menu != null) menu.saveVSliceList();
    FlxG.sound.play(Paths.sound('cancelMenu'));
    MusicBeatState.switchState(new ModsManagerSelectorState());
  }
}
