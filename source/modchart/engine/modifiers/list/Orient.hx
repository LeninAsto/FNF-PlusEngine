package modchart.engine.modifiers.list;

import modchart.backend.core.ModifierParameters;
import modchart.engine.modifiers.Modifier;

/**
 * Marker modifier for `orient`.
 *
 * The actual orientation math is applied in `ArrowRenderer.hx`, because it
 * needs the already-transformed path direction so other modifiers like
 * `drunk` can influence the final note/receptor rotation.
 */
class Orient extends Modifier {
	override public function shouldRun(params:ModifierParameters):Bool
		return false;
}
