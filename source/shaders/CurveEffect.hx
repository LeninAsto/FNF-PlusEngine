package shaders;

// Made by TheLeerName - Hardcoded by Assistant
class CurveEffect
{
	public var shader(default, null):CurveShader = new CurveShader();
	public var curveX(default, set):Float = 0;
	public var curveY(default, set):Float = 0;

	public function new():Void
	{
		shader.curveX.value = [0];
		shader.curveY.value = [0];
	}

	function set_curveX(v:Float):Float
	{
		curveX = v;
		shader.curveX.value = [curveX];
		return v;
	}

	function set_curveY(v:Float):Float
	{
		curveY = v;
		shader.curveY.value = [curveY];
		return v;
	}
}

class CurveShader extends FlxShader
{
	@:glFragmentSource('
		#pragma header

		uniform float curveX;
		uniform float curveY;

		float wiggle(float u) {
			return 27.0*(1.0 - 2.0*u); 
		}

		void main() {
			// wtf the matrix 3 revolutions reference?!??!?!?!?!
			mat3 matrix = mat3(
				1., 0., wiggle( 0.5 + curveX / 10. ),
				0., 1., wiggle( 0.5 + curveY / 10. ),
				0., 0., 1.
			);

			// haha funny 3d perspective
			vec3 uv3 = matrix * vec3(openfl_TextureCoordv - 0.5, 1.0);
			vec2 uv = uv3.xy / uv3.z + 0.5;

			gl_FragColor = flixel_texture2D(bitmap, uv);
			gl_FragColor = mix(vec4(0.0), gl_FragColor, vec4(step(0.0, uv3.z))); // remove pixels behind viewer
		}')
	public function new()
	{
		super();
	}
}
