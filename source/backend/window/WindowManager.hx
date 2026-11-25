package backend.window;

import lime.app.Application;
import lime.ui.Window;
import openfl.text.TextField;
import openfl.text.TextFormat;
import flixel.tweens.FlxTween;
import psychlua.backend.LuaUtils;

/** Desktop windows controlled by scripts. Secondary windows belong to their creator. */
class WindowManager {
 static var windows:Map<String, Window> = [];
 static var owners:Map<String, Dynamic> = [];
 static var labels:Map<String, TextField> = [];
 static var tweens:Map<String, FlxTween> = [];

 public static function backend():String {
  #if windows
  return WindowsWindowAPI.backend();
  #elseif linux
  return LinuxWindowAPI.backend();
  #elseif mac
  return MacWindowAPI.backend();
  #else
  return "unsupported";
  #end
 }
 public static function supports(feature:String):Bool {
  #if windows
  return WindowsWindowAPI.supports(feature);
  #elseif linux
  return LinuxWindowAPI.supports(feature);
  #elseif mac
  return MacWindowAPI.supports(feature);
  #else
  return false;
  #end
 }
 public static function get(id:String):Window {
  if (id == "main") return Application.current == null ? null : Application.current.window;
  return windows.get(id);
 }
 public static function create(id:String, width:Int, height:Int, title:String, alwaysOnTop:Bool, owner:Dynamic):Bool {
  #if desktop
  if (id == null || id == "" || id == "main" || id.indexOf(":") != -1 || windows.exists(id) || width <= 0 || height <= 0 || Application.current == null) return false;
  if (alwaysOnTop && !supports("alwaysOnTop")) return false;
  try {
   var window = Application.current.createWindow({width: width, height: height, title: title, resizable: true, alwaysOnTop: alwaysOnTop, context: {background: 0x15151d}});
   if (window == null) return false;
   if (window.id == -1 || window.stage == null) { window.close(); return false; }
   windows.set(id, window);
   owners.set(id, owner);
   var label = new TextField();
   label.defaultTextFormat = new TextFormat("_sans", 24, 0xffffff);
   label.multiline = true;
   label.wordWrap = true;
   label.selectable = false;
   label.width = width;
   label.height = height;
   window.stage.addChild(label);
   labels.set(id, label);
   window.onResize.add(function(w:Int, h:Int) { label.width = w; label.height = h; });
   window.onClose.add(function() { cancelWindowTweens(id); windows.remove(id); owners.remove(id); labels.remove(id); });
   return true;
  } catch (e:Dynamic) { trace('Could not create window: $e'); return false; }
  #else
  return false;
  #end
 }
 public static function setText(id:String, text:String):Bool {
  var label = labels.get(id);
  if (label == null) return false;
  label.text = text == null ? "" : text;
  return true;
 }
 public static function move(id:String, x:Int, y:Int):Bool {
  var w = get(id);
  if (w == null || !supports("move")) return false;
  w.move(x, y);
  return true;
 }
 public static function resize(id:String, width:Int, height:Int):Bool {
  var w = get(id);
  if (w == null || width <= 0 || height <= 0 || !supports("resize")) return false;
  w.resize(width, height);
  return true;
 }
 public static function setOpacity(id:String, value:Float):Bool {
  var w = get(id);
  if (w == null || !supports("opacity") || Math.isNaN(value)) return false;
  w.opacity = Math.max(0, Math.min(1, value));
  return true;
 }
 public static function tween(id:String, property:String, target:Float, duration:Float, ease:String):Bool {
  var w = get(id);
  if (w == null || Math.isNaN(target) || Math.isNaN(duration) || duration <= 0) return false;
  var start:Float = switch (property) {
   case "x": if (!supports("move")) return false; w.x;
   case "y": if (!supports("move")) return false; w.y;
   case "width": if (!supports("resize") || target <= 0) return false; w.width;
   case "height": if (!supports("resize") || target <= 0) return false; w.height;
   case "opacity": if (!supports("opacity")) return false; w.opacity;
   default: return false;
  };
  var key = id + ":" + property;
  var old = tweens.get(key);
  if (old != null) old.cancel();
  var tween = FlxTween.num(start, target, duration, {ease: LuaUtils.getTweenEaseByString(ease), onComplete: function(_) tweens.remove(key)});
  tweens.set(key, tween);
  tween.onUpdate = function(_) {
   if (get(id) != w) { tween.cancel(); tweens.remove(key); return; }
   switch (property) {
    case "x": w.move(Std.int(tween.value), w.y);
    case "y": w.move(w.x, Std.int(tween.value));
    case "width": w.resize(Std.int(Math.max(1, tween.value)), w.height);
    case "height": w.resize(w.width, Std.int(Math.max(1, tween.value)));
    case "opacity": setOpacity(id, tween.value);
   }
  };
  return true;
 }
 static function cancelWindowTweens(id:String):Void {
  for (property in ["x", "y", "width", "height", "opacity"]) {
   var key = id + ":" + property;
   var tween = tweens.get(key);
   if (tween != null) tween.cancel();
   tweens.remove(key);
  }
 }
 public static function close(id:String):Bool {
  if (id == "main") return false;
  var w = windows.get(id);
  if (w == null) return false;
  w.close();
  return !windows.exists(id);
 }
 public static function closeOwned(owner:Dynamic):Void {
  var ids = [for (id in owners.keys()) if (owners.get(id) == owner) id];
  for (id in ids) close(id);
 }
}
