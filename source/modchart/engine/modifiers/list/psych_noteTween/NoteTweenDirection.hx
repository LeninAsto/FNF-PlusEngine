package modchart.engine.modifiers.list.psych_noteTween;

import states.PlayState;
//import funkin.ui.debug.modcharting.ModchartEditorState;
import objects.StrumNote;
import modchart.engine.modifiers.list.Reverse;
import modchart.backend.core.ModifierParameters;
import modchart.backend.math.Vector3;

class NoteTweenDirection extends Reverse {

	override public function render(curPos:Vector3, params:ModifierParameters) {
		var player = params.player;
		var lane = params.lane;

		var strumNote:StrumNote = getStrumFromInfo(lane, player);

		if (strumNote != null) {
			var currentDirection = strumNote.direction;

			var additionalScrollAngleZ = currentDirection - 90;

			var originalScrollAngleZ = getPercent('scrollAngleZ', player);
			setPercent('scrollAngleZ', originalScrollAngleZ + additionalScrollAngleZ, player);

			var result = super.render(curPos, params);

			setPercent('scrollAngleZ', originalScrollAngleZ, player);

			return result;
		}

		return super.render(curPos, params);
	}

	override public function shouldRun(params:ModifierParameters):Bool {
		return super.shouldRun(params);
	}
	
	private function getStrumFromInfo(lane:Int, player:Int):StrumNote {
		//if (ModchartEditorState.instance != null)
		//	return ModchartEditorState.instance.getModchartStrumFromInfo(lane, player);

		if (PlayState.instance == null) return null;
		
		var group = player == 0 ? PlayState.instance.opponentStrums : PlayState.instance.playerStrums;
		var strum:StrumNote = null;
		
		group.forEach(str -> {
			@:privateAccess
			if (str.noteData == lane) {
				strum = str;
			}
		});
		
		return strum;
	}
}

