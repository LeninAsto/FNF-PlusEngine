package funkin.graphics.shaders;

import flixel.addons.display.FlxRuntimeShader;
import funkin.Assets;
import funkin.Paths;
import openfl.display.BitmapData;
import openfl.display.ShaderInput;

@:nullSafety
class BlendModesShader extends FlxRuntimeShader
{
  public var camera:Null<ShaderInput<BitmapData>>;
  public var cameraData:Null<BitmapData>;

  public function new()
  {
    super(Assets.getText(Paths.frag('blendModes')));
  }

  public function setCamera(cameraData:BitmapData):Void
  {
    this.cameraData = cameraData;

    setBitmapDataSafe('camera', this.cameraData);
  }

  function setBitmapDataSafe(name:String, value:BitmapData):Void
  {
    try
    {
      final input:Dynamic = data == null ? null : Reflect.field(data, name);
      if (input != null) input.input = value;
    }
    catch (error) {}
  }
}
