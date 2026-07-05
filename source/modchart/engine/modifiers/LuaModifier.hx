package modchart.engine.modifiers;

import modchart.backend.core.ModifierParameters;
import modchart.backend.core.TransformMode;
import modchart.backend.core.VisualParameters;
import modchart.backend.math.Vector3;
import modchart.engine.PlayField;
import openfl.geom.Vector3D;
import psychlua.FunkinLua;
import psychlua.LuaUtils;

using StringTools;

/**
 * Modifier backed by callbacks inside the owning FunkinLua script.
 *
 * Lua can either mutate the incoming `pos` / `visuals` objects and return them,
 * or return a table like `{x = pos.x + 10, y = pos.y, z = pos.z}`.
 */
class LuaModifier extends Modifier {
	public var modifierName(default, null):String;
	public var funk(default, null):FunkinLua;
	public var renderCallback:String;
	public var visualsCallback:String;
	public var shouldRunCallback:String;
	public var allowStraightHoldsCallback:String;
	public var transformModeValue:TransformMode = TransformMode.ALL;
	public var alwaysRun:Bool = false;
	public var nullSafety:Bool = true;
	public var allowStraightHoldsValue:Bool = true;

	var __skipRender:Bool = false;
	var __skipVisuals:Bool = false;
	var __skipShouldRun:Bool = false;
	var __skipStraightHolds:Bool = false;

	public function new(pf:PlayField, modifierName:String, funk:FunkinLua, ?options:Dynamic) {
		super(pf);

		this.modifierName = modifierName;
		this.funk = funk;

		if (Std.isOfType(options, String)) {
			renderCallback = Std.string(options);
		} else {
			renderCallback = readString(options, ['render', 'getPos', 'pos', 'func'], modifierName + 'Render');
			visualsCallback = readString(options, ['visuals', 'getVisuals', 'visual'], modifierName + 'Visuals');
			shouldRunCallback = readString(options, ['shouldRun', 'active', 'enabled'], modifierName + 'ShouldRun');
			allowStraightHoldsCallback = readString(options, ['allowOnStraightHoldsFunc', 'allowStraightHoldsFunc'], null);
			alwaysRun = readBool(options, ['alwaysRun', 'forceRun'], false);
			nullSafety = readBool(options, ['nullSafety', 'safe'], true);
			allowStraightHoldsValue = readBool(options, ['allowOnStraightHolds', 'allowStraightHolds'], true);
			transformModeValue = readTransformMode(readDynamic(options, ['transformMode', 'mode', 'target']), TransformMode.ALL);
		}
	}

	override public function transformMode():TransformMode
		return transformModeValue;

	override public function allowOnStraightHolds():Bool {
		if (__skipStraightHolds || allowStraightHoldsCallback == null)
			return allowStraightHoldsValue;

		final ret = funk.call(allowStraightHoldsCallback, [modifierName]);
		if (ret == LuaUtils.Function_Continue)
			return allowStraightHoldsValue;

		if (Std.isOfType(ret, Bool))
			return cast ret;

		__skipStraightHolds = true;
		return allowStraightHoldsValue;
	}

	override public function shouldRun(params:ModifierParameters):Bool {
		if (alwaysRun)
			return true;

		if (!__skipShouldRun && shouldRunCallback != null) {
			final ret = funk.call(shouldRunCallback, [Reflect.copy(params), modifierName]);
			if (ret != LuaUtils.Function_Continue) {
				if (Std.isOfType(ret, Bool))
					return cast ret;
				if (Std.isOfType(ret, Float) || Std.isOfType(ret, Int))
					return toFloat(ret) != 0;

				__skipShouldRun = true;
			}
		}

		return getPercent(modifierName, params.player) != 0;
	}

	override public function render(position:Vector3, params:ModifierParameters):Vector3 {
		if (__skipRender || renderCallback == null)
			return position;

		final safePos:Vector3 = nullSafety ? position.clone() : position;
		final safeParams:Dynamic = nullSafety ? Reflect.copy(params) : params;
		final ret = funk.call(renderCallback, [safePos, safeParams, modifierName]);

		if (ret == LuaUtils.Function_Continue)
			return position;

		final resolved = vectorFromDynamic(ret, safePos);
		if (resolved == null) {
			if (nullSafety) {
				trace('[FunkinModchart::LuaModifier] Failed to parse render return for "' + modifierName + '". Disabling render callback.');
				__skipRender = true;
			}
			return position;
		}

		return resolved;
	}

	override public function visuals(data:VisualParameters, params:ModifierParameters):VisualParameters {
		if (__skipVisuals || visualsCallback == null)
			return data;

		final safeData:VisualParameters = nullSafety ? Reflect.copy(data) : data;
		final safeParams:Dynamic = nullSafety ? Reflect.copy(params) : params;
		final ret = funk.call(visualsCallback, [safeData, safeParams, modifierName]);

		if (ret == LuaUtils.Function_Continue)
			return data;

		final resolved = visualsFromDynamic(ret, safeData);
		if (resolved == null) {
			if (nullSafety) {
				trace('[FunkinModchart::LuaModifier] Failed to parse visuals return for "' + modifierName + '". Disabling visuals callback.');
				__skipVisuals = true;
			}
			return data;
		}

		return resolved;
	}

	static function vectorFromDynamic(value:Dynamic, fallback:Vector3):Null<Vector3> {
		if (value == null)
			return fallback;
		if (Std.isOfType(value, Vector3D))
			return cast value;

		if (Std.isOfType(value, Array)) {
			final arr:Array<Dynamic> = cast value;
			return new Vector3(
				toFloat(arr.length > 0 ? arr[0] : null, fallback.x),
				toFloat(arr.length > 1 ? arr[1] : null, fallback.y),
				toFloat(arr.length > 2 ? arr[2] : null, fallback.z),
				toFloat(arr.length > 3 ? arr[3] : null, fallback.w)
			);
		}

		if (Reflect.hasField(value, 'x') || Reflect.hasField(value, 'y') || Reflect.hasField(value, 'z')) {
			fallback.x = toFloat(Reflect.field(value, 'x'), fallback.x);
			fallback.y = toFloat(Reflect.field(value, 'y'), fallback.y);
			fallback.z = toFloat(Reflect.field(value, 'z'), fallback.z);
			fallback.w = toFloat(Reflect.field(value, 'w'), fallback.w);
			return fallback;
		}

		return null;
	}

	static function visualsFromDynamic(value:Dynamic, fallback:VisualParameters):Null<VisualParameters> {
		if (value == null)
			return fallback;

		final fields = ['scaleX', 'scaleY', 'alpha', 'glow', 'glowR', 'glowG', 'glowB', 'angleX', 'angleY', 'angleZ', 'skewX', 'skewY'];
		var copied = false;
		for (field in fields) {
			if (!Reflect.hasField(value, field))
				continue;
			Reflect.setField(fallback, field, toFloat(Reflect.field(value, field), Reflect.field(fallback, field)));
			copied = true;
		}

		return copied || Reflect.fields(value).length > 0 ? fallback : null;
	}

	static function readDynamic(options:Dynamic, names:Array<String>):Dynamic {
		if (options == null || Std.isOfType(options, String))
			return null;
		for (name in names) {
			if (Reflect.hasField(options, name))
				return Reflect.field(options, name);
		}
		return null;
	}

	static function readString(options:Dynamic, names:Array<String>, fallback:Null<String>):Null<String> {
		final value = readDynamic(options, names);
		if (value == null)
			return fallback;
		final text = Std.string(value).trim();
		return text.length > 0 ? text : fallback;
	}

	static function readBool(options:Dynamic, names:Array<String>, fallback:Bool):Bool {
		final value = readDynamic(options, names);
		if (value == null)
			return fallback;
		if (Std.isOfType(value, Bool))
			return cast value;
		final text = Std.string(value).toLowerCase().trim();
		return text == 'true' || text == '1' || text == 'yes' || text == 'on';
	}

	static function readTransformMode(value:Dynamic, fallback:TransformMode):TransformMode {
		if (value == null)
			return fallback;
		if (Std.isOfType(value, Int) || Std.isOfType(value, Float))
			return cast Std.int(value);

		var out:Int = 0;
		final parts = Std.string(value).toLowerCase().replace('|', ',').replace('+', ',').split(',');
		for (part in parts) {
			switch (part.trim()) {
				case 'all':
					out |= TransformMode.ALL;
				case 'field':
					out |= TransformMode.FIELD;
				case 'note', 'notes':
					out |= TransformMode.NOTE;
				case 'receptor', 'receptors', 'strum', 'strums':
					out |= TransformMode.RECEPTOR;
				case 'splash', 'splashes':
					out |= TransformMode.SPLASH;
				case 'none':
					out |= TransformMode.NONE;
			}
		}
		return out != 0 ? cast out : fallback;
	}

	static function toFloat(value:Dynamic, fallback:Float = 0):Float {
		if (value == null)
			return fallback;
		if (Std.isOfType(value, Float) || Std.isOfType(value, Int))
			return value;
		final parsed = Std.parseFloat(Std.string(value));
		return Math.isNaN(parsed) ? fallback : parsed;
	}
}
