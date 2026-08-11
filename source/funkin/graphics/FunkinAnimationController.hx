package funkin.graphics;

import animate.FlxAnimateController;

@:access(funkin.graphics.FunkinSprite)
class FunkinAnimationController extends FlxAnimateController
{
  /**
   * The sprite that this animation controller is attached to.
   */
  var _parentSprite:FunkinSprite;

  public function new(sprite:FunkinSprite)
  {
    super(sprite);
    _parentSprite = sprite;
  }

  override function set_frameIndex(frame:Int):Int
  {
    _parentSprite._renderTextureDirty = true;
    return super.set_frameIndex(frame);
  }

  /**
   * We override `FlxAnimationController`'s `play` method to account for texture atlases.
   */
  public override function play(animName:String, force = false, reversed = false, frame = 0):Void
  {
    if (animName == null || animName == '') animName = _parentSprite.getDefaultSymbol();

    if (!_parentSprite.hasAnimation(animName))
    {
      final fallbackAnim:String = getMissingAnimationFallback(animName);
      if (fallbackAnim == null)
      {
        // Skip if the animation doesn't exist and there is nothing safe to play.
        trace('Animation ${animName} does not exist!');
        return;
      }

      trace('Animation ${animName} does not exist! Falling back to ${fallbackAnim}.');
      animName = fallbackAnim;
    }

    super.play(animName, force, reversed, frame);
  }

  function getMissingAnimationFallback(animName:String):Null<String>
  {
    final preferredFallbacks:Array<String> = switch (animName)
    {
      case 'idle': ['still', 'idle_unselected', 'idle_selected'];
      case 'selected': ['idle_selected', 'idle', 'still'];
      case 'unselected': ['idle_unselected', 'idle', 'still'];
      default: ['idle', 'still'];
    }

    for (name in preferredFallbacks)
    {
      if (_parentSprite.hasAnimation(name)) return name;
    }

    final names:Array<String> = getNameList();
    return names.length > 0 ? names[0] : null;
  }
}
