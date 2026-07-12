package backend.stepmania;

import backend.Song;
#if !(mac || ios)
import moonchart.formats.StepMania;
import moonchart.formats.fnf.legacy.FNFPsych;
import moonchart.formats.BasicFormat;
import moonchart.backend.FormatData;
import moonchart.backend.Timing;
#end

/**
 * Wrapper para cargar archivos StepMania usando la librería Moonchart
 * Mantiene compatibilidad con la interfaz anterior pero usa Moonchart internamente
 */
class SMFile {
	public var header:SMHeader;
	public var difficulties:Array<SMDifficulty> = [];
	public var isValid:Bool = true;
	
	// Moonchart objects
	#if !(mac || ios)
	private var moonchartSM:StepMania;
	#end
	private var smFilePath:String;
	
	public function new(data:String, ?filePath:String = null) {
		this.smFilePath = filePath;
		parseFile(data);
	}
	
	public static function loadFile(path:String):SMFile {
		#if sys
		if (!sys.FileSystem.exists(path)) {
			trace('SM file not found: ' + path);
			return null;
		}
		
		var content = sys.io.File.getContent(path);
		return new SMFile(content, path);
		#else
		trace('SM files not supported on this platform');
		return null;
		#end
	}
	
	function parseFile(data:String):Void {
		#if !(mac || ios)
		try {
			// Inicializar Moonchart si no está inicializado
			moonchart.Moonchart.init();
			
			// Parsear el archivo SM usando Moonchart
			moonchartSM = new StepMania();
			moonchartSM.fromStepMania(data);
			
			// Extraer información del header
			var basicChart = moonchartSM.toBasicFormat();
			var meta = basicChart.meta;
			
			// Crear el header compatible con la implementación anterior
			header = new SMHeader("");
			header.TITLE = meta.title ?? "Unknown";
			header.ARTIST = cast(meta.extraData.get("SONG_ARTIST"), String) ?? "Unknown";
			header.MUSIC = cast(meta.extraData.get("AUDIO_FILE"), String) ?? "audio.ogg";
			header.OFFSET = Std.string(meta.offset ?? 0.0);
			
			// Construir string de BPMS a partir de los cambios de BPM
			var bpmsArray:Array<String> = [];
			var totalBeats:Float = 0;
			for (i in 0...meta.bpmChanges.length) {
				var bpmChange = meta.bpmChanges[i];
				
				if (i > 0) {
					var prevChange = meta.bpmChanges[i - 1];
					var timeDiff = bpmChange.time - prevChange.time;
					var beatsInPeriod = (timeDiff / 1000.0) * (prevChange.bpm / 60.0);
					totalBeats += beatsInPeriod;
				}
				
				bpmsArray.push('$totalBeats=${bpmChange.bpm}');
			}
			header.BPMS = bpmsArray.join(',');
			
			// Reconstruir los bpmChanges para el header
			header.parseBPMChanges();
			
			// Validar que el archivo de música sea .ogg
			if (!header.MUSIC.toLowerCase().endsWith('.ogg')) {
				trace('WARNING: Music file is not .ogg format: ${header.MUSIC}');
				// No marcar como inválido, solo advertir
			}
			
			// Extraer dificultades del formato Moonchart
			var smData:Dynamic = moonchartSM.data;
			if (smData != null && smData.NOTES != null) {
				var notesMap:Map<String, Dynamic> = smData.NOTES;
				
				for (diffName in notesMap.keys()) {
					var diffData:Dynamic = notesMap.get(diffName);
					
					// Determinar si es double basado en el tipo de danza
					var isDouble = false;
					if (Reflect.hasField(diffData, 'dance')) {
						var danceType:String = Reflect.field(diffData, 'dance');
						isDouble = (danceType == 'dance-double');
					}
					
					difficulties.push({
						name: diffName,
						isDouble: isDouble,
						measures: [] // Las measures no son necesarias con Moonchart
					});
				}
			}
			
			if (difficulties.length == 0) {
				trace('ERROR: No valid difficulties found in SM file');
				isValid = false;
				return;
			}
			
			trace('Successfully parsed SM file with ${difficulties.length} difficulties using Moonchart');
			
		} catch (e:Dynamic) {
			trace('Error parsing SM file with Moonchart: ' + e);
			trace(haxe.CallStack.toString(haxe.CallStack.exceptionStack()));
			isValid = false;
		}
		#else
		trace('StepMania files not supported on macOS/iOS');
		isValid = false;
		#end
	}
	
	/**
	 * Convert the SMFile to a FNF SwagSong format using Moonchart
	 * @param songName 
	 * @param difficultyIndex 
	 */
	public function convertToFNF(songName:String, difficultyIndex:Int = 0):SwagSong {
		#if !(mac || ios)
		if (!isValid) {
			trace('Cannot convert invalid SM file');
			return null;
		}
		
		if (songName == null || songName.trim() == "") {
			trace('Invalid song name for conversion');
			return null;
		}
		
		if (header == null) {
			trace('No header data available for conversion');
			return null;
		}
		
		if (difficultyIndex < 0 || difficultyIndex >= difficulties.length) {
			trace('Invalid difficulty index: $difficultyIndex (total: ${difficulties.length})');
			return null;
		}
		
		try {
			// Obtener el nombre de la dificultad
			var diffName = difficulties[difficultyIndex].name;
			
			// Convertir usando Moonchart: SM -> BasicFormat -> Psych
			var basicChart = moonchartSM.toBasicFormat();
			
			// Crear el convertidor de Psych
			var psychConverter = new FNFPsych();
			
			// Convertir de BasicFormat a Psych
			psychConverter.fromBasicFormat(basicChart, diffName);
			
			// Obtener los datos en formato Psych
			var psychData = psychConverter.data;
			
			if (psychData == null || psychData.song == null) {
				trace('Failed to convert to Psych format');
				return null;
			}
			
			// Convertir de PsychJsonFormat a SwagSong
			var psychSong = psychData.song;
			
			var song:SwagSong = {
				song: songName,
				notes: [],
				events: [],
				bpm: psychSong.bpm,
				needsVoices: false,
				player1: 'bf',
				player2: 'dad',
				gfVersion: psychSong.gfVersion ?? 'gf',
				speed: psychSong.speed,
				stage: psychSong.stage ?? 'notitg',
				format: 'psych_v1',
				offset: 0,
				disableNoteRGB: false
			};
			
			// Convertir las secciones
			if (psychSong.notes != null) {
				for (section in psychSong.notes) {
					var swagSection:SwagSection = {
						sectionNotes: [],
						sectionBeats: 4, // Psych usa lengthInSteps, convertir o usar default
						mustHitSection: section.mustHitSection,
						gfSection: false, // FNFLegacySection no tiene este campo en Moonchart
						bpm: section.bpm ?? 0,
						changeBPM: section.changeBPM ?? false,
						altAnim: section.altAnim ?? false
					};
					
					// Copiar las notas
					if (section.sectionNotes != null) {
						for (note in section.sectionNotes) {
							swagSection.sectionNotes.push(note);
						}
					}
					
					song.notes.push(swagSection);
				}
			}
			
			// Convertir los eventos
			if (psychSong.events != null) {
				for (event in psychSong.events) {
					song.events.push(event);
				}
			}
			
			trace('Successfully converted ${diffName} to FNF format using Moonchart');
			return song;
			
		} catch (e:Dynamic) {
			trace('Error converting SM to FNF format: ' + e);
			trace(haxe.CallStack.toString(haxe.CallStack.exceptionStack()));
			return null;
		}
		#else
		trace('StepMania conversion not supported on macOS/iOS');
		return null;
		#end
	}
	
	function createNewSection(isDouble:Bool = false):SwagSection {
		return {
			sectionNotes: [],
			sectionBeats: 4,
			mustHitSection: !isDouble,
			gfSection: false,
			bpm: 0,
			changeBPM: false,
			altAnim: false
		};
	}
}

typedef SMDifficulty = {
	var name:String;
	var isDouble:Bool;
	var measures:Array<SMMeasure>;
}

/**
 * TimingStruct - Mantiene compatibilidad con código anterior
 * Ahora es solo una cáscara, Moonchart maneja el timing internamente
 */
class TimingStruct {
	public static var allTimings:Array<TimingData> = [];
	
	public static function clearTimings():Void {
		allTimings = [];
	}
	
	public static function addTiming(startBeat:Float, bpm:Float, endBeat:Float, offset:Float):Void {
		allTimings.push({
			startBeat: startBeat,
			bpm: bpm,
			endBeat: endBeat,
			startTime: offset,
			length: 0
		});
	}
	
	public static function getTimingAtBeat(beat:Float):TimingData {
		for (timing in allTimings) {
			if (beat >= timing.startBeat && beat < timing.endBeat) {
				return timing;
			}
		}
		return allTimings.length > 0 ? allTimings[0] : {
			startBeat: 0,
			bpm: 100,
			endBeat: 999999,
			startTime: 0,
			length: 0
		};
	}
}

typedef TimingData = {
	var startBeat:Float;
	var bpm:Float;
	var endBeat:Float;
	var startTime:Float;
	var length:Float;
}
