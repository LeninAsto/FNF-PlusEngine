package modchart.engine.modifiers.list;

class Expand extends Modifier {
	override public function shouldRun(params:modchart.backend.core.ModifierParameters):Bool return false;
	override public function isActive(player:Int):Bool return false;
}
