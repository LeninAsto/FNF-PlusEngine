package backend.window;

/** Capabilities available through Lime on macOS. */
class MacWindowAPI {
 public static function backend():String return "macos";
 public static function supports(feature:String):Bool return switch (feature) {
  case "move", "resize", "title", "fullscreen", "borderless", "opacity", "secondary", "alwaysOnTop": true;
  default: false;
 }
}
