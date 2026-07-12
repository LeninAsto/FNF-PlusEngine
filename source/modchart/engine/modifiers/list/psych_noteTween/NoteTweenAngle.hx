package modchart.engine.modifiers.list.psych_noteTween;

import states.PlayState;
//import funkin.ui.debug.modcharting.ModchartEditorState;
import objects.StrumNote;
import modchart.engine.modifiers.Modifier;
import modchart.backend.core.ModifierParameters;
import modchart.backend.core.VisualParameters;

/**
 * Modifier que actúa como puente entre noteTweenAngle del engine y el sistema de modcharts.
 * Lee el valor angle actual del StrumNote (modificado por noteTweenAngle) y lo aplica 
 * como rotación visual (angleZ) tanto a los receptores como a las notas.
 */
class NoteTweenAngle extends Modifier {

	override public function visuals(data:VisualParameters, params:ModifierParameters):VisualParameters {
		var player = params.player;
		var lane = params.lane;

		// Obtener el StrumNote específico para este lane y player
		var strumNote:StrumNote = getStrumFromInfo(lane, player);

		if (strumNote != null) {
			// Leer el angle actual del StrumNote (modificado por noteTweenAngle)
			var currentAngle = strumNote.angle;

			// Aplicar al sistema de visuals del modchart como rotación visual
			// Ahora afecta tanto a receptores como a notas
			data.angleZ += currentAngle;
		}

		return data;
	}

	override public function shouldRun(params:ModifierParameters):Bool {
		// Ejecutar tanto en receptores como en notas
		return true;
	}
	
	// Función helper para obtener el StrumNote específico
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
