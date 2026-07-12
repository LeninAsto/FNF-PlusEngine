package modchart.backend.graphics.renderers;

import flixel.math.FlxMath;

using flixel.util.FlxColorTransformUtil;

final matrix:Matrix = new Matrix();
final fMatrix:FlxMatrix = new FlxMatrix();
final rotationVector = new Vector3();
final helperVector = new Vector3();

#if !openfl_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end
final class ArrowRenderer extends BaseRenderer<FlxSprite> {
	// Pre-allocated members to avoid per-call heap allocations
	final _planeVerts:NativeVector<Float> = new NativeVector<Float>(8);
	final _projZ:NativeVector<Float> = new NativeVector<Float>(4);

	// Arrow quad indices are always [0,1,2, 1,3,2] — share one instance across all DrawCommands
	static final _sharedArrowIdx:openfl.Vector<Int> = {
		var v = new openfl.Vector<Int>(6, true);
		v[0] = 0; v[1] = 1; v[2] = 2;
		v[3] = 1; v[4] = 3; v[5] = 2;
		v;
	};

	inline private function getGraphicVertices(planeWidth:Float, planeHeight:Float, flipX:Bool, flipY:Bool):NativeVector<Float> {
		var x1 = flipX ? planeWidth : -planeWidth;
		var x2 = flipX ? -planeWidth : planeWidth;
		var y1 = flipY ? planeHeight : -planeHeight;
		var y2 = flipY ? -planeHeight : planeHeight;

		// top left
		_planeVerts[0] = x1;
		_planeVerts[1] = y1;
		// top right
		_planeVerts[2] = x2;
		_planeVerts[3] = y1;
		// bottom left
		_planeVerts[4] = x1;
		_planeVerts[5] = y2;
		// bottom right
		_planeVerts[6] = x2;
		_planeVerts[7] = y2;
		return _planeVerts;
	}

	var __lastOrient:Float = 0;
	var __lastC2:Float = 0;
	var __lastPlayer:Int = -1;

	override public function prepare(arrow:FlxSprite):Null<DrawCommand> {
		if (arrow == null || arrow.graphic == null || arrow.frame == null || arrow.alpha <= 0)
			return null;

		final arrowPosition = helperVector;

		final player = Adapter.instance.getPlayerFromArrow(arrow);
		final sourceTime = Adapter.instance.getTimeFromArrow(arrow);

		// setup the position
		var arrowTime = sourceTime;
		var songPos = Adapter.instance.getSongPosition();
		var arrowDiff = arrowTime - songPos;

		final canUseLast = player == __lastPlayer;

		final centered2 = canUseLast ? __lastC2 : (__lastC2 = parent.getPercent('centered2', player));
		final orient = canUseLast ? __lastOrient : (__lastOrient = parent.getPercent('orient', player));

		// apply centered 2 (aka centered path)
		if (Adapter.instance.isTapNote(arrow)) {
			arrowDiff += FlxG.height * 0.25 * centered2;
		} else {
			arrowTime = songPos + (FlxG.height * 0.25 * centered2);
			arrowDiff = arrowTime - songPos;
		}
		var arrowData:ArrowData = {
			hitTime: arrowTime,
			distance: arrowDiff,
			sourceTime: sourceTime,
			lane: Adapter.instance.getLaneFromArrow(arrow),
			player: player,
			isTapArrow: Adapter.instance.isTapNote(arrow)
		};

		arrowPosition.setTo(Adapter.instance.getDefaultReceptorX(arrowData.lane, arrowData.player) + Manager.ARROW_SIZEDIV2,
			Adapter.instance.getDefaultReceptorY(arrowData.lane, arrowData.player) + Manager.ARROW_SIZEDIV2, 0);

		final output = parent.modifiers.getPath(arrowPosition, arrowData);
		arrowPosition.setTo(output.rawX, output.rawY, output.rawZ);

		// internal mods
		if (orient != 0) {
			final nextOutput = parent.modifiers.getPath(new Vector3(Adapter.instance.getDefaultReceptorX(arrowData.lane, arrowData.player)
				+ Manager.ARROW_SIZEDIV2,
				Adapter.instance.getDefaultReceptorY(arrowData.lane, arrowData.player)
				+ Manager.ARROW_SIZEDIV2),
				arrowData, 1, false, true);
			final thisPos = output.pos;
			final nextPos = nextOutput.pos;

			output.visuals.angleZ += FlxAngle.wrapAngle((-90 + (Math.atan2(nextPos.y - thisPos.y, nextPos.x - thisPos.x) * FlxAngle.TO_DEG)) * orient);
		}

		__lastPlayer = player;

		// prepare the instruction for drawing
		final projectionDepth = arrowPosition.z;
		final depth = projectionDepth;

		var planeWidth = arrow.frame.frame.width * arrow.scale.x * .5;
		var planeHeight = arrow.frame.frame.height * arrow.scale.y * .5;

		arrow._z = (output.pos.z - 1) * 1000;

		var planeVertices = getGraphicVertices(planeWidth, planeHeight, arrow.flipX, arrow.flipY);
		// reuse pre-allocated 4-element buffer instead of allocating per call
		final projectionZ = _projZ;

		var vertPointer = 0;
		final distAbs = Math.abs(arrowData.distance);
		// Very soft far-distance compensation to keep angles close to target value
		// while still avoiding extreme over-tilt on very distant notes.
		final farRatio = FlxMath.bound((distAbs - 600.0) / 2600.0, 0, 1);
		final perspectiveDamp = 1.0 - (farRatio * 0.15);
		final visualAngleX = output.visuals.angleX * perspectiveDamp;
		final visualAngleY = output.visuals.angleY * perspectiveDamp;
		@:privateAccess do {
			rotationVector.setTo(planeVertices[vertPointer], planeVertices[vertPointer + 1], 0);

			// The result of the vert rotation
			var rotation = ModchartUtil.rotate3DVector(rotationVector, visualAngleX, visualAngleY,
				ModchartUtil.getFrameAngle(arrow) + output.visuals.angleZ + arrow.angle);

			// apply skewness
			if (output.visuals.skewX != 0 || output.visuals.skewY != 0) {
				matrix.identity();

				matrix.b = ModchartUtil.tan(output.visuals.skewY * FlxAngle.TO_RAD);
				matrix.c = ModchartUtil.tan(output.visuals.skewX * FlxAngle.TO_RAD);

				rotation.x = matrix.__transformX(rotation.x, rotation.y);
				rotation.y = matrix.__transformY(rotation.x, rotation.y);
			}
			rotation.x = rotation.x * output.visuals.scaleX;
			rotation.y = rotation.y * output.visuals.scaleY;

			var view = new Vector3(rotation.x + arrowPosition.x, rotation.y + arrowPosition.y,
				(rotation.z * 0.001 * Config.Z_SCALE) + arrowPosition.z);

			// The result of the perspective projection of rotation
			final projection = this.view.transformVector(view);

			planeVertices[vertPointer] = projection.x;
			planeVertices[vertPointer + 1] = projection.y;

			// stores depth from this vert to use it for perspective correction on uv's
			projectionZ[Math.floor(vertPointer / 2)] = Math.max(0.0001, projection.z);

			vertPointer = vertPointer + 2;
		} while (vertPointer < planeVertices.length);

		// @formatter:off
		// build directly as openfl.Vector to avoid conversion at render time
		var vertices = new openfl.Vector<Float>(8, true);
		// top left
		vertices[0] = planeVertices[0];
		vertices[1] = planeVertices[1];
		// top right
		vertices[2] = planeVertices[2];
		vertices[3] = planeVertices[3];

		// botton left
		vertices[4] = planeVertices[4];
		vertices[5] = planeVertices[5];
		// bottom right
		vertices[6] = planeVertices[6];
		vertices[7] = planeVertices[7];

		final uvRectangle = arrow.frame.uv;
		// build UVs as openfl.Vector to avoid conversion at render time
		var uvData = new openfl.Vector<Float>(12, true);
		var k = 0;

		#if (flixel == "6.1.0")
		// top left
		uvData[k++] = uvRectangle.left;
		uvData[k++] = uvRectangle.right;
		uvData[k++] = 1 / projectionZ[0];
		// top right
		uvData[k++] = uvRectangle.top;
		uvData[k++] = uvRectangle.right;
		uvData[k++] = 1 / projectionZ[1];
		// bottom left
		uvData[k++] = uvRectangle.top;
		uvData[k++] = uvRectangle.bottom;
		uvData[k++] = 1 / projectionZ[2];
		// bottom right
		uvData[k++] = uvRectangle.left;
		uvData[k++] = uvRectangle.bottom;
		uvData[k++] = 1 / projectionZ[3];
		#elseif (flixel >= "6.1.1")
		// top left
		uvData[k++] = uvRectangle.left;
		uvData[k++] = uvRectangle.top;
		uvData[k++] = 1 / projectionZ[0];
		// top right
		uvData[k++] = uvRectangle.right;
		uvData[k++] = uvRectangle.top;
		uvData[k++] = 1 / projectionZ[1];
		// bottom left
		uvData[k++] = uvRectangle.left;
		uvData[k++] = uvRectangle.bottom;
		uvData[k++] = 1 / projectionZ[2];
		// bottom right
		uvData[k++] = uvRectangle.right;
		uvData[k++] = uvRectangle.bottom;
		uvData[k++] = 1 / projectionZ[3];
		#else
		// top left
		uvData[k++] = uvRectangle.x;
		uvData[k++] = uvRectangle.y;
		uvData[k++] = 1 / projectionZ[0];
		// top right
		uvData[k++] = uvRectangle.width;
		uvData[k++] = uvRectangle.y;
		uvData[k++] = 1 / projectionZ[1];
		// bottom left
		uvData[k++] = uvRectangle.x;
		uvData[k++] = uvRectangle.height;
		uvData[k++] = 1 / projectionZ[2];
		// bottom right
		uvData[k++] = uvRectangle.width;
		uvData[k++] = uvRectangle.height;
		uvData[k++] = 1 / projectionZ[3];
		#end

		// @formatter:on
		final absGlow = output.visuals.glow * 255;
		final negGlow = 1 - output.visuals.glow;

		if ((arrow.alpha * output.visuals.alpha) <= 0)
			return null;

		var color = new ColorTransform(negGlow, negGlow, negGlow, arrow.alpha * output.visuals.alpha, Math.round(output.visuals.glowR * absGlow),
			Math.round(output.visuals.glowG * absGlow), Math.round(output.visuals.glowB * absGlow));

		// make the instruction
		var dc:DrawCommand = {
			parent: arrow,
			graphic: arrow.graphic,
			antialiasing: arrow.antialiasing,
			blend: arrow.blend,
			cameras: ModchartUtil.resolveCameras(parent, arrow),
			shader: arrow.shader,

			vertices: vertices,
			indices: _sharedArrowIdx,
			uvs: uvData,
			color: color,
			isColored: color.hasRGBMultipliers() || color.alphaMultiplier != 1,
			hasColorOffsets: color.hasRGBAOffsets()
		};
		return dc;
	}
}