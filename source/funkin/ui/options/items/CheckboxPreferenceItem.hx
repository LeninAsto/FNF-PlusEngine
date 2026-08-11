package funkin.ui.options.items;

import flixel.FlxSprite.FlxSprite;
import flixel.util.FlxColor;

class CheckboxPreferenceItem extends FlxSprite
{
  public var currentValue(default, set):Bool;
  var fallbackGraphic:Bool = false;

  public function new(x:Float, y:Float, defaultValue:Bool = false, available:Bool = true)
  {
    super(x, y);

    frames = Paths.getSparrowAtlas('checkboxThingie');
    if (frames != null)
    {
      animation.addByPrefix('static', 'Check Box unselected', 24, false);
      animation.addByPrefix('checked', 'Check Box selecting animation', 24, false);
    }

    if (frames == null || !animation.exists('static') || !animation.exists('checked'))
    {
      frames = Paths.getSparrowAtlas('checkboxanim');
      if (frames != null)
      {
        animation.addByPrefix('static', 'checkbox0', 24, false);
        animation.addByPrefix('checked', 'checkbox finish', 24, false);
      }
    }

    fallbackGraphic = (frames == null || !animation.exists('static') || !animation.exists('checked'));
    if (fallbackGraphic)
      makeFallbackGraphic(defaultValue);
    else
      setGraphicSize(Std.int(width * 0.7));
    updateHitbox();

    if (!available) this.alpha = 0.5;

    this.currentValue = defaultValue;
  }

  override function update(elapsed:Float):Void
  {
    super.update(elapsed);

    if (fallbackGraphic || animation.curAnim == null)
      return;

    switch (animation.curAnim.name)
    {
      case 'static':
        offset.set();
      case 'checked':
        offset.set(17, 70);
    }
  }

  function set_currentValue(value:Bool):Bool
  {
    if (fallbackGraphic)
    {
      makeFallbackGraphic(value);
      updateHitbox();
      return currentValue = value;
    }

    if (value)
    {
      animation.play('checked', true);
    }
    else
    {
      animation.play('static');
    }

    return currentValue = value;
  }

  function makeFallbackGraphic(value:Bool):Void
  {
    makeGraphic(58, 58, value ? 0xFF6EEB83 : 0xFF222832);
    color = FlxColor.WHITE;
  }
}
