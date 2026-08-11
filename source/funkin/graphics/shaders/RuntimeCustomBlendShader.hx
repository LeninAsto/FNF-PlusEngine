package funkin.graphics.shaders;

import funkin.Assets;
import funkin.Paths;
import openfl.display.BitmapData;
import openfl.display.BlendMode;

class RuntimeCustomBlendShader extends RuntimePostEffectShader
{
  // only different name purely for hashlink fix
  public var sourceSwag(default, set):BitmapData;

  function set_sourceSwag(value:BitmapData):BitmapData
  {
    if (available)
    {
      try
      {
        this.setBitmapData("sourceSwag", value);
      }
      catch (error) {}
    }

    return sourceSwag = value;
  }

  public var backgroundSwag(default, set):BitmapData;

  function set_backgroundSwag(value:BitmapData):BitmapData
  {
    if (available)
    {
      try
      {
        this.setBitmapData("backgroundSwag", value);
      }
      catch (error) {}
    }

    return backgroundSwag = value;
  }

  // name change make sure it's not the same variable name as whatever is in the shader file
  public var blendSwag(default, set):BlendMode;

  function set_blendSwag(value:BlendMode):BlendMode
  {
    if (available)
    {
      try
      {
        this.setInt("blendMode", cast value);
      }
      catch (error) {}
    }

    return blendSwag = value;
  }

  public function new()
  {
    super(Assets.getText(Paths.frag("customBlend")));
    validateShaderFields(["uScreenResolution", "uCameraBounds", "uFrameBounds", "sourceSwag", "backgroundSwag", "blendMode"]);
  }
}
