package modchart.backend.core;

@:structInit
final class ArrowData {
	public var hitTime:Float = 0;
	public var distance:Float = 0;
	public var sourceTime:Float = 0;

	public var lane:Int = 0;
	public var player:Int = 0;

	public var hitten:Bool = false;
	public var isTapArrow:Bool = false;
	public var straightHolds:Bool = false;

	public function toString() {
		return 'ModifierParameters(hitTime: $hitTime, distance: $distance, sourceTime: $sourceTime, lane: $lane, player: $player, hitten: $hitten, isTapArrow: $isTapArrow, straightHolds: $straightHolds)';
	}
}
