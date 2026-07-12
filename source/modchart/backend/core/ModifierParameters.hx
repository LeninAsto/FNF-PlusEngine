package modchart.backend.core;

@:publicFields
@:structInit
final class ModifierParameters {
	var songTime:Float;
	var hitTime:Float;
	var distance:Float;
	var sourceTime:Float;
	var curBeat:Float;

	var lane:Int = 0;
	var player:Int = 0;
	var isTapArrow:Bool = false;
	var straightHolds:Bool = false;

	public function toString() {
		return 'ModifierParameters(songTime: $songTime, hitTime: $hitTime, distance: $distance, sourceTime: $sourceTime, curBeat: $curBeat, lane: $lane, player: $player, straightHolds: $straightHolds)';
	}
}
