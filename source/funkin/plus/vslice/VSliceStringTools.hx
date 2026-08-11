package funkin.plus.vslice;

/**
 * Null-safe static StringTools bridge for VSlice HScript mods.
 */
class VSliceStringTools
{
  public static inline function startsWith(value:Null<String>, start:Null<String>):Bool
  {
    if (value == null || start == null) return false;
    return StringTools.startsWith(value, start);
  }

  public static inline function endsWith(value:Null<String>, end:Null<String>):Bool
  {
    if (value == null || end == null) return false;
    return StringTools.endsWith(value, end);
  }

  public static inline function contains(value:Null<String>, needle:Null<String>):Bool
  {
    if (value == null || needle == null) return false;
    return value.indexOf(needle) != -1;
  }

  public static inline function trim(value:Null<String>):String
  {
    return value == null ? "" : StringTools.trim(value);
  }

  public static inline function ltrim(value:Null<String>):String
  {
    return value == null ? "" : StringTools.ltrim(value);
  }

  public static inline function rtrim(value:Null<String>):String
  {
    return value == null ? "" : StringTools.rtrim(value);
  }

  public static inline function replace(value:Null<String>, sub:Null<String>, by:Null<String>):String
  {
    if (value == null) return "";
    if (sub == null || sub.length == 0) return value;
    return StringTools.replace(value, sub, by ?? "");
  }

  public static inline function hex(n:Int, digits:Int = 0):String
  {
    return StringTools.hex(n, digits);
  }

  public static inline function lpad(value:Null<String>, pad:Null<String>, length:Int):String
  {
    return StringTools.lpad(value ?? "", pad ?? " ", length);
  }

  public static inline function rpad(value:Null<String>, pad:Null<String>, length:Int):String
  {
    return StringTools.rpad(value ?? "", pad ?? " ", length);
  }

  public static inline function isSpace(value:Null<String>, pos:Int):Bool
  {
    if (value == null) return false;
    return StringTools.isSpace(value, pos);
  }

  public static inline function fastCodeAt(value:Null<String>, index:Int):Int
  {
    if (value == null) return -1;
    return StringTools.fastCodeAt(value, index);
  }
}
