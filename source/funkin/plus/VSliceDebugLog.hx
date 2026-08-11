package funkin.plus;

import flixel.util.FlxColor;

using StringTools;

/**
 * Routes VSlice/Polymod runtime errors to the in-game debug overlay instead of
 * blocking gameplay with native alert dialogs.
 */
class VSliceDebugLog
{
  public static function error(title:String, message:String):Void
  {
    report(title, message, FlxColor.RED);
  }

  public static function warning(title:String, message:String):Void
  {
    report(title, message, FlxColor.YELLOW);
  }

  public static function info(title:String, message:String):Void
  {
    report(title, message, FlxColor.CYAN);
  }

  public static function report(title:String, message:String, color:FlxColor):Void
  {
    var text:String = format(title, message);

    #if (LUA_ALLOWED || HSCRIPT_ALLOWED)
    if (states.PlayState.instance != null && states.PlayState.instance.exists)
    {
      try
      {
        states.PlayState.instance.addTextToDebug(text, color);
      }
      catch (e:Dynamic)
      {
        trace('Failed to send VSlice log to PlayState debug overlay: ${Std.string(e)}');
      }
    }
    #end

    debug.TraceDisplay.addDebugText(text, color);
    #if sys
    Sys.println(text);
    #else
    trace(text);
    #end
  }

  static function format(title:String, message:String):String
  {
    if (title == null || title.trim().length == 0) title = 'VSlice';
    if (message == null) message = '';

    message = message.trim();
    if (message.length > 360) message = message.substr(0, 357) + '...';

    return '[$title] $message';
  }
}
