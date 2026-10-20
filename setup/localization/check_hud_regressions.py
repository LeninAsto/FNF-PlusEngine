"""Exercise the real HealthIconHud class with headless sprite stand-ins."""
from pathlib import Path
import shutil
import subprocess

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / 'export/localization-hud-check'
files = {
    'flixel/math/FlxMath.hx': '''package flixel.math;
class FlxMath {
 public static function lerp(a:Float, b:Float, t:Float):Float return a + t * (b - a);
 public static function bound(v:Float, lo:Float, hi:Float):Float return Math.max(lo, Math.min(hi, v));
}''',
    'objects/HealthIcon.hx': '''package objects;
class HealthIcon {
 public var baseScale:Float = 1;
 public var visible:Bool = true;
 public var alpha:Float = 1;
 public var width:Float = 150;
 public var x:Float = 0;
 public var isAnimated:Bool = false;
 public var frames:Dynamic = {frames: [0, 1, 2]};
 public var animation:Dynamic = {curAnim: {curFrame: 0}};
 public var scale:Scale = new Scale();
 public function new() {}
 public function updateHitbox():Void {}
 public function updateIconState(value:Float):Void {}
 public function setGraphicSize(value:Int):Void {width = value;}
}
class Scale {
 public var x:Float = 1;
 public var y:Float = 1;
 public function new() {}
 public function set(x:Float, y:Float):Void {this.x = x; this.y = y;}
}''',
    'objects/Bar.hx': '''package objects;
class Bar {
 public var enabled:Bool = true;
 public var percent:Float = 50;
 public var barCenter:Float = 0;
 public function new() {}
}''',
    'states/play/ClientPrefs.hx': '''package states.play;
class ClientPrefs {public static var data = {iconBounceType: 'Codename'};}''',
    'states/play/CoolUtil.hx': '''package states.play;
class CoolUtil {public static function boundTo(v:Float, a:Float, b:Float):Float return Math.max(a, Math.min(b, v));}''',
    'HudCheck.hx': '''import objects.HealthIcon;
import states.play.HealthIconHud;
class HudCheck {
 static function near(a:Float, b:Float, label:String):Void {
  if (Math.abs(a - b) > 0.000001) throw label + ': ' + a + ' != ' + b;
 }
 static function simulate(fps:Int):Float {
  var icon = new HealthIcon(); icon.scale.set(1.2, 1.2);
  for (i in 0...fps) HealthIconHud.scale(1.0 / fps, 1, icon, null, null);
  return icon.scale.x;
 }
 static function main():Void {
  var icon = new HealthIcon(); icon.scale.set(1.2, 1.2);
  HealthIconHud.scale(0, 1, icon, null, null);
  near(icon.scale.x, 1.2, 'zero elapsed must preserve scale');
  HealthIconHud.scale(1 / 60, 0, icon, null, null);
  near(icon.scale.x, 1.2, 'zero rate must preserve scale');
  HealthIconHud.scale(1 / 60, 1, icon, null, null);
  near(icon.scale.x, 1.134, 'one 60Hz tick closes 33 percent of the gap');
  near(icon.scale.x, icon.scale.y, 'uniform scale');
  near(simulate(30), simulate(60), '30/60Hz equivalence');
  near(simulate(60), simulate(144), '60/144Hz equivalence');
  icon.baseScale = 0.5; icon.scale.set(0.6, 0.6);
  HealthIconHud.scale(10, 1, icon, null, null);
  near(icon.scale.x, 0.5, 'custom icon returns to its base scale');
  icon.visible = false; icon.scale.set(0.6, 0.6);
  HealthIconHud.scale(1, 1, icon, null, null);
  near(icon.scale.x, 0.6, 'hidden icon is unchanged');
  trace('OK: 8 HealthIconHud regression assertions');
 }
}''',
}
for relative, content in files.items():
    path = OUT / relative
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(content, encoding='utf-8')
shutil.copyfile(ROOT / 'source/states/play/HealthIconHud.hx', OUT / 'states/play/HealthIconHud.hx')
subprocess.run(['haxe', '-cp', str(OUT), '-main', 'HudCheck', '--interp'], check=True, cwd=OUT)


# Run the actual receptor layout method against predictable 1280x720 fixtures.
def extract_method(text, signature):
    start = text.index(signature)
    opening = text.index('{', start)
    depth = 1
    end = opening + 1
    while depth:
        depth += (text[end] == '{') - (text[end] == '}')
        end += 1
    return text[start:end]

layout = extract_method((ROOT / 'source/states/PlayState.hx').read_text('utf-8'), 'private function generateStaticArrows(')
position = extract_method((ROOT / 'source/objects/StrumNote.hx').read_text('utf-8'), 'public function playerPosition(')
fixture = r"""class LayoutCheck {
 static var STRUM_X:Float = 42;
 static var STRUM_X_MIDDLESCROLL:Float = -278;
 var playOpponent:Bool = false;
 var isStoryMode:Bool = true;
 var skipArrowStartTween:Bool = true;
 var modes:Modes = new Modes();
 var playerStrums:Group = new Group();
 var opponentStrums:Group = new Group();
 var strumLineNotes:Group = new Group();
 function new() {}
 METHOD
 static function main() {
  var checks = 0;
  for (middle in [false, true]) for (opponent in [false, true]) {
   var test = new LayoutCheck();
   test.playOpponent = opponent; test.modes.opponent = opponent;
   ClientPrefs.data.middleScroll = middle;
   test.generateStaticArrows(0); test.generateStaticArrows(1);
   for (side in 0...2) {
    var controlled = opponent ? side == 0 : side == 1;
    var expected = !middle ? (side == 0 ? [92.,204.,316.,428.] : [732.,844.,956.,1068.])
     : (controlled ? [412.,524.,636.,748.] : [82.,194.,971.,1083.]);
    for (column in 0...4) {
     var arrow = test.strumLineNotes.members[side * 4 + column];
     if (Math.abs(arrow.x - expected[column]) > 0.00001) throw 'column position: ' + middle + '/' + opponent + '/' + side + '/' + column;
     var expectedAlpha = middle && !controlled ? 0.35 : 1;
     if (Math.abs(arrow.alpha - expectedAlpha) > 0.00001) throw 'wrong opponent dimming';
     checks += 2;
    }
   }
   if (test.playerStrums.members.length != 4 || test.opponentStrums.members.length != 4) throw 'strum ownership';
   checks++;
  }
  trace('OK: ' + checks + ' receptor layout/opacity/ownership assertions');
 }
}
class StrumNote {
 public var x:Float;
 public var alpha:Float = 1;
 public var downScroll:Bool = false;
 public var player:Int;
 public var noteData:Int;
 public function new(x:Float,y:Float,note:Int,player:Int) {this.x=x;noteData=note;this.player=player;}
 POSITION
}
class Group {
 public var members:Array<StrumNote> = [];
 public function new() {}
 public function add(arrow:StrumNote):Void {members.push(arrow);}
}
class Modes {
 public var opponent:Bool = false;
 public function new() {}
 public function playerStrum(player:Int):Bool return opponent ? player == 0 : player == 1;
}
class ClientPrefs {public static var data = {middleScroll:false,downScroll:false,opponentStrums:true};}
class Note {public static var swagWidth:Float = 112;}
class FlxG {public static var width:Float = 1280;}
class HudSafeZone {
 public static function y():Float return 0;
 public static function width():Float return 1280;
 public static function height():Float return 720;
}
class FlxTween {public static function tween(a:Dynamic,b:Dynamic,c:Float,d:Dynamic):Void {}}
class FlxEase {public static var circOut:Float = 0;}
"""
(OUT / 'LayoutCheck.hx').write_text(fixture.replace('METHOD', layout).replace('POSITION', position), encoding='utf-8')
subprocess.run(['haxe', '-cp', str(OUT), '-main', 'LayoutCheck', '--interp'], check=True, cwd=OUT)
