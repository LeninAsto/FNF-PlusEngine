package modchart.backend.core;

@:publicFields
@:structInit
final class ModifierParameters {
	var songTime:Float;
	var hitTime:Float;
	var distance:Float;
	var sourceTime:Float;
	var strumTime:Float = 0;
	var sampleTime:Float = 0;
	var isPath:Bool = false;
	var curBeat:Float;

	var lane:Int = 0;
	var player:Int = 0;
	var isTapArrow:Bool = false;
	var straightHolds:Bool = false;
	var isHoldBody:Bool = false;

	public function copy():ModifierParameters {
		return {songTime: songTime, hitTime: hitTime, distance: distance, sourceTime: sourceTime, strumTime: strumTime,
			sampleTime: sampleTime, isPath: isPath, curBeat: curBeat, lane: lane, player: player,
			isTapArrow: isTapArrow, straightHolds: straightHolds, isHoldBody: isHoldBody};
	}

	public function toString() {
		return 'ModifierParameters(songTime: $songTime, hitTime: $hitTime, distance: $distance, sourceTime: $sourceTime, curBeat: $curBeat, lane: $lane, player: $player, straightHolds: $straightHolds, isHoldBody: $isHoldBody)';
	}
}
