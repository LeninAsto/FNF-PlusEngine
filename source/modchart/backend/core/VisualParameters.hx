package modchart.backend.core;

@:publicFields
@:structInit
final class VisualParameters {
	var scaleX:Float = 1;
	var scaleY:Float = 1;
	var alpha:Float = 1;
	var glow:Float = 0;
	var glowR:Float = 1;
	var glowG:Float = 1;
	var glowB:Float = 1;
	var angleX:Float = 0;
	var angleY:Float = 0;
	var angleZ:Float = 0;
	var fieldAngleX:Float = 0;
	var fieldAngleY:Float = 0;
	var fieldAngleZ:Float = 0;
	var skewX:Float = 0;
	var skewY:Float = 0;
	var holdDirection:Float = 0;
	var holdAngle:Float = 0;
	var holdWidth:Float = 0;
	var holdSection:Float = 0;
	var planeXX:Float = 1;
	var planeXY:Float = 0;
	var planeXZ:Float = 0;
	var planeYX:Float = 0;
	var planeYY:Float = 1;
	var planeYZ:Float = 0;

	public function copy():VisualParameters {
		return {scaleX: scaleX, scaleY: scaleY, alpha: alpha, glow: glow, glowR: glowR, glowG: glowG, glowB: glowB,
			angleX: angleX, angleY: angleY, angleZ: angleZ, fieldAngleX: fieldAngleX, fieldAngleY: fieldAngleY,
			fieldAngleZ: fieldAngleZ, skewX: skewX, skewY: skewY, holdDirection: holdDirection, holdAngle: holdAngle,
			holdWidth: holdWidth, holdSection: holdSection, planeXX: planeXX, planeXY: planeXY, planeXZ: planeXZ,
			planeYX: planeYX, planeYY: planeYY, planeYZ: planeYZ};
	}
}
