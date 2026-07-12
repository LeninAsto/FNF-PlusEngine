package modchart.engine.modifiers.list.psych_noteTween;

import states.PlayState;
//import funkin.ui.debug.modcharting.ModchartEditorState;
import objects.StrumNote;
import modchart.engine.modifiers.list.Reverse;
import modchart.backend.core.ModifierParameters;
import modchart.backend.math.Vector3;

/**
 * Modifier que actúa como puente entre noteTweenDirection del engine y el sistema de modcharts.
 * Hereda de Reverse para usar el sistema scrollAngleZ ya implementado.
 * Lee el valor direction actual del StrumNote y lo convierte en scrollAngleZ.
 */
class NoteTweenDirection extends Reverse {

	override public function render(curPos:Vector3, params:ModifierParameters) {
		var player = params.player;
		var lane = params.lane;

		// Obtener el StrumNote específico para este lane y player
		var strumNote:StrumNote = getStrumFromInfo(lane, player);

		if (strumNote != null) {
			// Leer el direction actual del StrumNote (modificado por noteTweenDirection)
			var currentDirection = strumNote.direction;

			// Convertir direction a scrollAngleZ (90 grados por defecto = 0 scrollAngleZ)
			var additionalScrollAngleZ = currentDirection - 90;

			// Aplicar el scrollAngleZ temporal para este render
			var originalScrollAngleZ = getPercent('scrollAngleZ', player);
			setPercent('scrollAngleZ', originalScrollAngleZ + additionalScrollAngleZ, player);

			// Llamar al render de Reverse que ya maneja scrollAngleZ correctamente
			var result = super.render(curPos, params);

			// Restaurar el valor original de scrollAngleZ
			setPercent('scrollAngleZ', originalScrollAngleZ, player);

			return result;
		}

		// Si no hay StrumNote, usar el comportamiento normal de Reverse
		return super.render(curPos, params);
	}

	override public function shouldRun(params:ModifierParameters):Bool {
		// Usar la misma lógica que Reverse (ejecuta para todas las notas)
		return super.shouldRun(params);
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

