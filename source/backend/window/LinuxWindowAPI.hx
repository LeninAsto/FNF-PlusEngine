package backend.window;

/** Linux session detection is conservative: a Wayland session may use XWayland. */
class LinuxWindowAPI {
 public static function backend():String {
  #if linux
  var driver = Sys.getEnv("SDL_VIDEODRIVER");
  if (driver != null && driver != "") {
   driver = driver.toLowerCase();
   if (driver == "x11") return "x11";
   if (driver == "wayland") return "wayland";
   return "unknown";
  }
  var session = Sys.getEnv("XDG_SESSION_TYPE");
  if (session != null && session.toLowerCase() == "wayland") return "wayland-or-xwayland";
  if (session != null && session.toLowerCase() == "x11") return "x11";
  return "unknown";
  #else
  return "unknown";
  #end
 }
 public static function supports(feature:String):Bool return switch (feature) {
  case "move": backend() == "x11";
  case "resize", "title", "fullscreen", "borderless", "secondary": true;
  // Compositors can ignore opacity and always-on-top requests.
  case "opacity", "alwaysOnTop": backend() == "x11";
  default: false;
 }
}
