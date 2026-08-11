package funkin.play.character;

import funkin.modding.events.ScriptEvent;
import funkin.play.GameOverSubState;
import funkin.play.PauseSubState;

/**
 * Source-side compatibility base for VSlice mods that import Pico's official
 * scripted base character as a regular class.
 */
class PicoPlayerBaseCharacter extends MultiAnimateAtlasCharacter
{
  public function new(characterId:String)
  {
    if (characterId == "UNKNOWN") characterId = "pico-playable";
    super(characterId);
    ignoreExclusionPref.push("shoot");
  }

  public override function onCreate(event:ScriptEvent):Void
  {
    super.onCreate(event);
    GameOverSubState.musicSuffix = '-pico';
    GameOverSubState.blueBallSuffix = '-pico';
    GameOverSubState.animationSuffix = '';
    PauseSubState.musicSuffix = '-pico';
  }

  public override function resetCharacter(resetCamera:Bool = true):Void
  {
    super.resetCharacter(resetCamera);
    GameOverSubState.musicSuffix = '-pico';
    GameOverSubState.blueBallSuffix = '-pico';
    PauseSubState.musicSuffix = '-pico';
  }
}
