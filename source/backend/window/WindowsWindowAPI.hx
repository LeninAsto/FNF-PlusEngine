package backend.window;

/** Capabilities available through Lime on Windows. */
class WindowsWindowAPI {
 public static function backend():String return "windows";
 public static function supports(feature:String):Bool return switch (feature) {
  case "move", "resize", "title", "fullscreen", "borderless", "opacity", "secondary", "alwaysOnTop": true;
  default: false;
 }
}
