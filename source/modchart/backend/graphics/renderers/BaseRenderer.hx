package modchart.backend.graphics.renderers;

import flixel.FlxBasic;
import flixel.FlxCamera;
import flixel.util.FlxSignal;
import flixel.util.FlxSort;

@:allow(modchart.backend.graphics.CtxRenderer)
class BaseRenderer<T:FlxBasic> extends FlxBasic {
	private var parent:Null<PlayField>;

	private var view(get, never):View3D;

	function get_view()
		return parent.view;

	public function new(parent:PlayField) {
		super();

		this.parent = parent;
	}

	// Renderer-side
	public function prepare(item:T):Null<DrawCommand> {
		return null;
	}

	public function dispose() {}
}