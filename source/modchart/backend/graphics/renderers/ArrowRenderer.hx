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
	final _arrowData:ArrowData = {
		hitTime: 0,
		distance: 0,
		sourceTime: 0,
		lane: 0,
		player: 0,
		isTapArrow: true,
		isHoldBody: false
	};
	final _orientInput:Vector3 = new Vector3();
	final _rotated:Vector3 = new Vector3();
	final _viewInput:Vector3 = new Vector3();
	final _outputPos:Vector3 = new Vector3();
	final _outputVisuals:VisualParameters = {};
	final _output:ModifierOutput;
	final _orientPos:Vector3 = new Vector3();
	final _orientVisuals:VisualParameters = {};
	final _orientOutput:ModifierOutput;
	var _slots:Array<ArrowRenderSlot> = [];
	var _slotIndex:Int = 0;

	public function new(parent:PlayField) {
		super(parent);
		_output = {pos: _outputPos, visuals: _outputVisuals};
		_orientOutput = {pos: _orientPos, visuals: _orientVisuals};
	}

	/** Reuses command and geometry storage after the previous frame was submitted. */
	public inline function beginFrame():Void
	{
		_slotIndex = 0;
	}

	inline function nextSlot():ArrowRenderSlot
	{
		if (_slotIndex >= _slots.length)
			_slots.push(new ArrowRenderSlot());
		return _slots[_slotIndex++];
	}

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
		var songPos = parent.state.songPosition;
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
		final arrowData = _arrowData;
		arrowData.hitTime = arrowTime;
		arrowData.distance = arrowDiff;
		arrowData.sourceTime = sourceTime;
		arrowData.lane = Adapter.instance.getLaneFromArrow(arrow);
		arrowData.player = player;
		arrowData.isTapArrow = Adapter.instance.isTapNote(arrow);
		arrowData.isHoldBody = false;

		arrowPosition.setTo(Adapter.instance.getDefaultReceptorX(arrowData.lane, arrowData.player) + Manager.ARROW_SIZEDIV2,
			Adapter.instance.getDefaultReceptorY(arrowData.lane, arrowData.player) + Manager.ARROW_SIZEDIV2, 0);

		final output = parent.getNotePathInto(arrowPosition, arrowData, _output, _outputPos, _outputVisuals);
		arrowPosition.setTo(output.rawX, output.rawY, output.rawZ);
		var visualAngleZ = output.visuals.angleZ;

		// internal mods
		if (orient != 0) {
			_orientInput.setTo(Adapter.instance.getDefaultReceptorX(arrowData.lane, arrowData.player) + Manager.ARROW_SIZEDIV2,
				Adapter.instance.getDefaultReceptorY(arrowData.lane, arrowData.player) + Manager.ARROW_SIZEDIV2, 0);
			final nextOutput = parent.getNotePathInto(_orientInput, arrowData, _orientOutput, _orientPos, _orientVisuals, 1, false, true);
			final thisPos = output.pos;
			final nextPos = nextOutput.pos;

			final orientAngle = FlxAngle.wrapAngle((-90 + (Math.atan2(nextPos.y - thisPos.y, nextPos.x - thisPos.x) * FlxAngle.TO_DEG)) * orient);
			visualAngleZ += orientAngle;
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
			var rotation = ModchartUtil.rotate3DVectorInto(rotationVector, visualAngleX, visualAngleY,
				ModchartUtil.getFrameAngle(arrow) + visualAngleZ + arrow.angle, _rotated);

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

			_viewInput.setTo(rotation.x + arrowPosition.x, rotation.y + arrowPosition.y,
				(rotation.z * 0.001 * Config.Z_SCALE) + arrowPosition.z);

			// The result of the perspective projection of rotation
			final projection = this.view.transformVector(_viewInput);

			planeVertices[vertPointer] = projection.x;
			planeVertices[vertPointer + 1] = projection.y;

			// stores depth from this vert to use it for perspective correction on uv's
			projectionZ[Math.floor(vertPointer / 2)] = Math.max(0.0001, projection.z);

			vertPointer = vertPointer + 2;
		} while (vertPointer < planeVertices.length);

		// @formatter:off
		// build directly as openfl.Vector to avoid conversion at render time
		final slot = nextSlot();
		final vertices = slot.vertices;
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
		final uvData = slot.uvs;
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

		final color = slot.color;
		color.redMultiplier = negGlow;
		color.greenMultiplier = negGlow;
		color.blueMultiplier = negGlow;
		color.alphaMultiplier = arrow.alpha * output.visuals.alpha;
		color.redOffset = Math.round(output.visuals.glowR * absGlow);
		color.greenOffset = Math.round(output.visuals.glowG * absGlow);
		color.blueOffset = Math.round(output.visuals.glowB * absGlow);
		color.alphaOffset = 0;

		// make the instruction
		final dc = slot.command;
		dc.parent = arrow;
		dc.graphic = arrow.graphic;
		dc.antialiasing = arrow.antialiasing;
		dc.blend = arrow.blend;
		dc.cameras = ModchartUtil.resolveCameras(parent, arrow, slot.cameras);
		dc.shader = arrow.shader;
		dc.vertices = vertices;
		dc.indices = _sharedArrowIdx;
		dc.uvs = uvData;
		dc.color = color;
		dc.colors = null;
		dc.isColored = color.hasRGBMultipliers() || color.alphaMultiplier != 1;
		dc.hasColorOffsets = color.hasRGBAOffsets();
		dc.zIndex = 0;
		return dc;
	}
}

private class ArrowRenderSlot
{
	public final vertices:openfl.Vector<Float>;
	public final uvs:openfl.Vector<Float>;
	public final color:ColorTransform;
	public final cameras:Array<FlxCamera>;
	public final command:DrawCommand;

	public function new()
	{
		vertices = new openfl.Vector<Float>(8, true);
		uvs = new openfl.Vector<Float>(12, true);
		color = new ColorTransform();
		cameras = [];
		command = {
			parent: null,
			graphic: null,
			antialiasing: false,
			blend: null,
			shader: null,
			cameras: cameras,
			vertices: vertices,
			uvs: uvs,
			indices: null,
			isColored: false,
			hasColorOffsets: false,
			color: color,
			colors: null,
			zIndex: 0
		};
	}
}
