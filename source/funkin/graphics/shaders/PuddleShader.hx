package funkin.graphics.shaders;

import flixel.addons.display.FlxRuntimeShader;
import funkin.Assets;
import funkin.Paths;

@:nullSafety
class PuddleShader extends FlxRuntimeShader
{
  public function new()
  {
    super(Assets.getText(Paths.frag('puddle')));
  }
}
