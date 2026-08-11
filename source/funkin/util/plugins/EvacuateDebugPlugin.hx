package funkin.util.plugins;

import flixel.FlxBasic;

/**
 * Legacy evac plugin.
 *
 * F4 is reserved by Plus Engine's TraceDisplay, so this plugin intentionally
 * does not bind any keyboard shortcuts in the integrated runtime.
 */
@:nullSafety
class EvacuateDebugPlugin extends FlxBasic
{
  public function new()
  {
    super();
  }

  public static function initialize():Void
  {
    FlxG.plugins.addPlugin(new EvacuateDebugPlugin());
  }

  public override function update(elapsed:Float):Void
  {
    super.update(elapsed);
  }

  public override function destroy():Void
  {
    super.destroy();
  }
}
