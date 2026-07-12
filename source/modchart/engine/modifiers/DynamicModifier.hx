package modchart.engine.modifiers;

/**
 * `DynamicModifier` is a subclass of `Modifier` that applies dynamic transformations
 * to the position and visuals of an arrow during the modchart rendering process.
 *
 * This type of modifier can be used for scripting, allowing you to define
 * custom functions to modify both the position and visuals of arrows
 * without the need to modify the source code.
 */
#if !openfl_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end
class DynamicModifier extends Modifier {
	/**
	 * A function that applies a transformation to the arrow's position.
	 *
	 * @param position The current position of the arrow.
	 * @param params The parameters used for rendering, such as song position, beat, etc.
	 * @return The transformed position of the arrow.
	 */
	public var renderFunc:(Vector3, ModifierParameters) -> Vector3;

	/**
	 * A function that applies transformations to the arrow's visuals.
	 *
	 * @param data The current visuals of the arrow.
	 * @param params The parameters used for rendering, such as song position, beat, etc.
	 * @return The transformed visuals of the arrow.
	 */
	public var visualsFunc:(VisualParameters, ModifierParameters) -> VisualParameters;

	/**
	 * Flag that enables or disables null safety. When enabled, the parameters are copied
	 * to avoid modifying the original data. This ensures that if the functions return `null`,
	 * the original values will not be altered, preventing unintended changes.
	 */
	public var nullSafety:Bool = true;

	private var __skipRender:Bool = false;
	private var __skipVisuals:Bool = false;

	/**
	 * Applies the position transformation defined by `renderFunc`.
	 * If `renderFunc` is `null`, the function simply returns the current position.
	 *
	 * @return The transformed position, or the original if no transformation is applied.
	 */
	override public function render(position:Vector3, params:ModifierParameters) {
		if (__skipRender || renderFunc == null)
			return position;

		final safePos = nullSafety ? position.clone() : position;
		final safeParams = nullSafety ? Reflect.copy(params) : params;

		final translation:Null<Vector3> = renderFunc(safePos, safeParams);

		if (nullSafety && translation == null) {
			trace('[FunkinModchart::DynamicModifier] Failed to run "render" function!');
			__skipRender = true;
		}

		return translation != null ? translation : position;
	}

	/**
	 * Applies the visual transformation defined by `visualsFunc`.
	 * If `visualsFunc` is `null`, the function simply returns the original visuals.
	 *
	 * @return The transformed visuals, or the original if no transformation is applied.
	 */
	override public function visuals(data:VisualParameters, params:ModifierParameters) {
		if (__skipVisuals || visualsFunc == null)
			return data;

		final safeData = nullSafety ? Reflect.copy(data) : data;
		final safeParams = nullSafety ? Reflect.copy(params) : params;

		final modifiedVisuals:Null<VisualParameters> = visualsFunc(safeData, safeParams);

		if (nullSafety && modifiedVisuals == null) {
			trace('[FunkinModchart::DynamicModifier] Failed to run "visuals" function!');
			__skipVisuals = true;
		}

		return modifiedVisuals != null ? modifiedVisuals : data;
	}

	override public function shouldRun(params:ModifierParameters):Bool {
		return true;
	}
}
