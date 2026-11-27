package modchart.engine.modifiers.list.psych_noteTween;

import states.PlayState;
//import funkin.ui.debug.modcharting.ModchartEditorState;
import objects.StrumNote;
import modchart.engine.modifiers.Modifier;
import modchart.backend.core.ModifierParameters;
import modchart.backend.core.VisualParameters;

class NoteTweenAngle extends Modifier {

	override public function visuals(data:VisualParameters, params:ModifierParameters):VisualParameters {
		var player = params.player;
		var lane = params.lane;

		var strumNote:StrumNote = getStrumFromInfo(lane, player);

		if (strumNote != null) {
			var currentAngle = strumNote.angle;

			data.angleZ += currentAngle;
		}

		return data;
	}

	override public function shouldRun(params:ModifierParameters):Bool {
		return true;
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
