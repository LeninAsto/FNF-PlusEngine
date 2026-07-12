package debug;

import flixel.FlxG;
import openfl.Lib;
import haxe.Timer;
import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.system.System as OpenFlSystem;
import lime.system.System as LimeSystem;
import openfl.events.KeyboardEvent;
import openfl.ui.Keyboard;
import openfl.display.Graphics;
import openfl.display.Shape;
import openfl.display.Sprite;
import haxe.Http;
import haxe.Json;
import states.MainMenuState;
#if windows
import slushithings.windows.WindowsCPP;
#end

/**
	The FPS class provides an easy-to-use monitor to display
	the current frame rate of an OpenFL project
**/
#if cpp
#if windows
@:cppFileCode('#include <windows.h>')
#elseif (ios || mac)
@:cppFileCode('#include <mach-o/arch.h>')
#else
@:headerInclude('sys/utsname.h')
#end
#end
class FPSCounter extends Sprite
{
	/**
		The current frame rate, expressed using frames-per-second
	**/
	public var currentFPS(default, null):Int;

	/**
		The current memory usage (WARNING: this is NOT your total program memory usage, rather it shows the garbage collector memory)
	**/
	public var memoryMegas(get, never):Float;

	/**
		Task Memory (Windows only) - Actual process memory shown in Task Manager
	**/
	public var taskMemory(get, never):Float;

	/**
		Peak memory usage tracking
	**/
	public var memoryPeak(default, null):Float = 0;

	/**
		Smooth memory display (interpolated for smooth animation)
	**/
	private var displayedMemory:Float = 0;

	private var displayedMemoryPeak:Float = 0;
	private var memoryLerpSpeed:Float = 0.1; // Speed of memory interpolation (0.1 = smooth, 1.0 = instant)

	/**
		Debug level for FPS counter (0: normal without bg, 1: normal with bg, 2: basic debug, 3: extended debug)
	**/
	public var debugLevel:Int = 0;

	/**
		Mod author text that can be set from Lua scripts
	**/
	public var modAuthor:String = "";

	/**
		Charting info from PlayState (Step, Beat, Section)
	**/
	public var currentStep:Int = 0;

	public var currentBeat:Int = 0;
	public var currentSection:Int = 0;

	/**
		Debug info from PlayState (Speed, BPM, Health)
	**/
	public var songSpeed:Float = 1.0;

	public var currentBPM:Int = 0;
	public var playerHealth:Float = 1.0;

	/**
		Rating and Combo from PlayState
	**/
	public var lastRating:String = "None";

	public var comboCount:Int = 0;

	/**
		Background shape for debug mode
	**/
	private var bgShape:Shape;

	/**
		Text display field
	**/
	private var textDisplay:TextField;

	/**
		Last GitHub commit info
	**/
	private var lastCommit:String = "Loading...";

	private var commitTime:String = ""; // Commit time
	private var commitDate:String = ""; // Commit date

	/**
		Script statistics from PlayState
	**/
	public var luaScriptsLoaded:Int = 0;

	public var luaScriptsFailed:Int = 0;
	public var hscriptsLoaded:Int = 0;
	public var hscriptsFailed:Int = 0;
	public var sscriptsErrors:Int = 0;

	/**
		Singleton instance for global access.
	**/
	public static var instance:FPSCounter;

	/**
		CPU and GPU usage tracking - ELIMINADO para optimización
	**/
	// Variables eliminadas para mejor rendimiento
	/**
		Note and sprite counters - ELIMINADO para optimización  
	**/
	// Variables eliminadas para mejor rendimiento

	/**
		Runtime tracking
	**/
	private var startTime:Float = 0.0;

	/**
		Cached values for minimal operations
	**/
	private var cachedCurrentState:String = "Unknown";

	private var lastCacheUpdateTime:Float = 0.0;

	/**
		Text update throttling to reduce overhead in debug mode.
	**/
	private var lastTextUpdateTime:Float = 0.0;

	private var textUpdateInterval:Float = 0.5; // Refresh static text every 500ms.
	private var cachedStaticText:String = ""; // Cached static text (OS, commit, etc.).

	/**
		Frame timing used to track delay and stutter.
	**/
	private var lastFrameTime:Float = 0.0;

	private var frameTimeMs:Float = 0.0;
	private var frameTimesArray:Array<Float> = [];
	private var avgFrameTimeMs:Float = 0.0;

	@:noCompletion private var times:Array<Float>;
	@:noCompletion private var updateTime:Int;
	@:noCompletion private var framesCount:Int;
	@:noCompletion private var prevTime:Int;

	public var os:String = '';

	public function new(x:Float = 10, y:Float = 10, color:Int = 0x000000)
	{
		super();

		// Assign singleton instance.
		instance = this;

		// Load the persisted debug level.
		#if (ClientPrefs && ClientPrefs.data)
		if (Reflect.hasField(ClientPrefs.data, "fpsDebugLevel"))
		{
			debugLevel = ClientPrefs.data.fpsDebugLevel;
		}
		#end

		#if officialBuild
		if (LimeSystem.platformName == LimeSystem.platformVersion || LimeSystem.platformVersion == null)
			os = '\nOS: ${LimeSystem.platformName}' #if cpp + ' ${getArch() != 'Unknown' ? getArch() : ''}' #end;
		else
			os = '\nOS: ${LimeSystem.platformName}' #if cpp + ' ${getArch() != 'Unknown' ? getArch() : ''}' #end + ' - ${LimeSystem.platformVersion}';
		#end

		positionFPS(x, y);

		currentFPS = 0;

		// Create text display field (normal size)
		textDisplay = new TextField();
		textDisplay.selectable = false;
		textDisplay.mouseEnabled = false;
		textDisplay.defaultTextFormat = new TextFormat('Monsterrat', 14, color);
		textDisplay.antiAliasType = openfl.text.AntiAliasType.NORMAL;
		textDisplay.sharpness = 100;
		textDisplay.width = 350;
		textDisplay.height = 550;
		textDisplay.x = 2;
		textDisplay.y = 1;
		textDisplay.multiline = true;
		textDisplay.text = "FPS";
		textDisplay.wordWrap = false;
		textDisplay.autoSize = openfl.text.TextFieldAutoSize.LEFT;
		addChild(textDisplay);

		times = [];
		prevTime = Lib.getTimer();
		updateTime = prevTime + 500;

		// Initialize frame time measurement
		lastFrameTime = Timer.stamp();
		frameTimesArray = [];

		// Create background for debug mode
		bgShape = new Shape();
		addChildAt(bgShape, 0); // Add background behind text

		// Add listener for F2
		if (FlxG.stage != null)
		{
			FlxG.stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
		}

		// Get latest commit info
		getLastCommit();

		// Initialize runtime tracking
		startTime = haxe.Timer.stamp();
		lastCacheUpdateTime = startTime;

		// Initialize minimal cache
		cachedCurrentState = "Unknown";
	}

	public dynamic function updateText():Void // so people can override it in hscript
	{
		// Get current real memory
		var currentMemory = memoryMegas;

		// Update peak memory
		if (currentMemory > memoryPeak)
		{
			memoryPeak = currentMemory;
		}

		// Smooth interpolation for displayed memory (lerp)
		// This makes the memory counter animate smoothly instead of jumping
		if (displayedMemory == 0)
		{
			// First time initialization
			displayedMemory = currentMemory;
			displayedMemoryPeak = memoryPeak;
		}
		else
		{
			// Lerp towards target values
			displayedMemory += (currentMemory - displayedMemory) * memoryLerpSpeed;
			displayedMemoryPeak += (memoryPeak - displayedMemoryPeak) * memoryLerpSpeed;
		}

		// Format displayed memory (smoothed values)
		var currentMemoryStr = flixel.util.FlxStringUtil.formatBytes(displayedMemory);
		var peakMemoryStr = flixel.util.FlxStringUtil.formatBytes(displayedMemoryPeak);

		// White or red color based on FPS
		var targetFPS = #if (ClientPrefs && ClientPrefs.data && ClientPrefs.data.framerate) ClientPrefs.data.framerate #else FlxG.stage.window.frameRate #end;
		var halfFPS = targetFPS * 0.5;
		var textColorValue:Int;

		if (currentFPS >= halfFPS)
		{
			textColorValue = 0xFFFFFF; // White
		}
		else
		{
			textColorValue = 0xFF0000; // Red
		}
		textDisplay.defaultTextFormat = new TextFormat('Monsterrat', 14, textColorValue);
		textDisplay.setTextFormat(textDisplay.defaultTextFormat);

		// Update counters for extended debug mode without extra throttling.
		if (debugLevel == 3)
		{
			updateCountersOptimized();
		}

		var displayText:String = "";

		switch (debugLevel)
		{
			case 0:
				// Normal mode - FPS + Delay + Memory WITHOUT background
				displayText = '' + Std.string(currentFPS) + ' FPS';
				displayText += '\n' + formatFloat(frameTimeMs, 1) + ' / ' + formatFloat(avgFrameTimeMs, 1) + ' ms';
				displayText += '\n' + currentMemoryStr + ' / ' + peakMemoryStr;

				// Add mod author text if available
				if (modAuthor != null && modAuthor.length > 0)
				{
					displayText += '\n' + modAuthor;
				}

			case 1:
				// Normal mode WITH background
				displayText = '' + Std.string(currentFPS) + ' FPS';
				displayText += '\n' + formatFloat(frameTimeMs, 1) + ' / ' + formatFloat(avgFrameTimeMs, 1) + ' ms';
				displayText += '\n' + currentMemoryStr + ' / ' + peakMemoryStr;

				// Add mod author text if available
				if (modAuthor != null && modAuthor.length > 0)
				{
					displayText += '\n' + modAuthor;
				}

			case 2:
				// Basic debug mode - with background and basic data
				displayText = '' + Std.string(currentFPS) + ' FPS';
				displayText += '\nDelay: ' + formatFloat(frameTimeMs, 1) + ' ms';
				displayText += '\nAvg: ' + formatFloat(avgFrameTimeMs, 1) + ' ms';
				displayText += '\nGC Heap: ' + currentMemoryStr;
				displayText += '\nPeak: ' + peakMemoryStr;
				if (backend.MemoryUtil.supportsTaskMem())
				{
					displayText += '\nTask Memory: ' + flixel.util.FlxStringUtil.formatBytes(taskMemory);
				}
				displayText += '\n\n' + os.substring(1);
				displayText += '\nCommit: ' + lastCommit;

			case 3:
				// Extended debug mode - optimized for better performance
				var currentTime = Timer.stamp();

				// Update static text only every textUpdateInterval seconds
				if (cachedStaticText == "" || (currentTime - lastTextUpdateTime) >= textUpdateInterval)
				{
					lastTextUpdateTime = currentTime;

					// Build static text (that doesn't change frequently)
					cachedStaticText = os.substring(1);
					cachedStaticText += '\nLast Commit: ' + lastCommit;

					// Show commit date and time if available
					if (commitDate != null && commitDate.length > 0)
					{
						cachedStaticText += '\nDate: ' + commitDate;
					}
					if (commitTime != null && commitTime.length > 0)
					{
						cachedStaticText += '\nTime: ' + commitTime + ' UTC';
					}

					cachedStaticText += '\nUptime: ' + getUptime();
					cachedStaticText += '\nState: ' + cachedCurrentState;

					// Script information (updated infrequently)
					var totalScripts = luaScriptsLoaded + hscriptsLoaded;
					var totalFailed = luaScriptsFailed + hscriptsFailed;
					cachedStaticText += '\n\nScripts: ' + totalScripts;
					if (totalFailed > 0)
					{
						cachedStaticText += ' (Failed: ' + totalFailed + ')';
					}
					if (sscriptsErrors > 0)
					{
						cachedStaticText += ' (SScript Errors: ' + sscriptsErrors + ')';
					}
					if (totalScripts > 0)
					{
						cachedStaticText += '\n  Lua: ' + luaScriptsLoaded + ' | HScript: ' + hscriptsLoaded;
					}
				}

				// Build dynamic text (updated every frame for modders)
				displayText = '' + Std.string(currentFPS) + ' FPS';
				displayText += '\nDelay: ' + formatFloat(frameTimeMs, 1) + ' ms';
				displayText += '\nAvg: ' + formatFloat(avgFrameTimeMs, 1) + ' ms';
				displayText += '\nGC Heap: ' + currentMemoryStr;
				displayText += '\nPeak: ' + peakMemoryStr;

				// Add Task Memory if supported on this platform
				if (backend.MemoryUtil.supportsTaskMem())
				{
					displayText += '\nTask Memory: ' + flixel.util.FlxStringUtil.formatBytes(taskMemory);
				}

				displayText += '\n\n' + cachedStaticText;

				// Critical information for modders - ALWAYS updated in real time
				// Step, Beat and Section
				displayText += '\n\nStep: ' + currentStep;
				displayText += '\nBeat: ' + currentBeat;
				displayText += '\nSection: ' + currentSection;

				// PlayState debug info
				var healthPercent = Math.floor((playerHealth / 2) * 100);
				displayText += '\n\nSpeed: ' + formatFloat(songSpeed, 2) + 'x';
				displayText += '\nBPM: ' + currentBPM;
				displayText += '\nHealth: ' + healthPercent + '%';

				displayText += '\n\nPlus Engine v' + MainMenuState.plusEngineVersion;
				displayText += '\nPsych v' + MainMenuState.psychEngineVersion;
		}

		// Use simple text
		textDisplay.text = displayText;

		// Update the background
		updateBackground();
	}

	var deltaTimeout:Float = 0.0;

	private override function __enterFrame(deltaTime:Float):Void
	{
		// Compute frame time (delay).
		var currentFrameTime = Timer.stamp();
		frameTimeMs = (currentFrameTime - lastFrameTime) * 1000.0; // Convert to milliseconds
		lastFrameTime = currentFrameTime;

		// Keep a moving average for the last 10 frames.
		frameTimesArray.push(frameTimeMs);
		if (frameTimesArray.length > 10)
		{
			frameTimesArray.shift();
		}

		// Compute average.
		var sum:Float = 0.0;
		for (time in frameTimesArray)
		{
			sum += time;
		}
		avgFrameTimeMs = sum / frameTimesArray.length;

		if (ClientPrefs.data.fpsRework)
		{
			// Flixel can reset this to 60 on focus gained, so keep the draw cap aligned.
			if (FlxG.stage.window.frameRate != ClientPrefs.data.framerate && FlxG.stage.window.frameRate != FlxG.game.focusLostFramerate)
				FlxG.stage.window.frameRate = ClientPrefs.data.framerate;

			var currentTime = openfl.Lib.getTimer();
			framesCount++;

			if (currentTime >= updateTime)
			{
				var elapsed = currentTime - prevTime;
				// Use round instead of ceil for more accurate FPS display
				currentFPS = Math.round((framesCount * 1000) / elapsed);
				framesCount = 0;
				prevTime = currentTime;
				updateTime = currentTime + 500;
			}
		}
		else
		{
			// Improved standard FPS calculation for a more responsive value.
			final now:Float = haxe.Timer.stamp() * 1000;
			times.push(now);
			while (times[0] < now - 1000)
				times.shift();

			// Update more frequently for better accuracy.
			if (deltaTimeout < 33)
			{
				deltaTimeout += deltaTime;
				return;
			}

			// Show actual FPS instead of clamping to the configured update rate.
			currentFPS = times.length;
			deltaTimeout = 0.0;
		}

		var targetFPS:Int = Std.int(FlxG.stage.window.frameRate);
		targetFPS = ClientPrefs.data.framerate;

		updateText();
	}

	// Handle the F2 key event.
	private function onKeyDown(event:KeyboardEvent):Void
	{
		if (event.keyCode == Keyboard.F2)
		{
			debugLevel = (debugLevel + 1) % 4; // Cycle: 0, 1, 2, 3
			#if (ClientPrefs && ClientPrefs.data)
			ClientPrefs.data.fpsDebugLevel = debugLevel;
			ClientPrefs.save();
			#end
			updateBackground();
			// Force an immediate text/background refresh.
			updateText();
		}
	}

	// Función para actualizar el fondo
	private function updateBackground():Void
	{
		if (bgShape == null)
			return;

		var g:Graphics = bgShape.graphics;
		g.clear();

		if (debugLevel >= 1)
		{
			// Calculate background size based on text
			var lines = switch (debugLevel)
			{
				case 1: 1.8; // Normal with bg: FPS, Delay, Memory, (optional modAuthor)
				case 2: 8; // Basic debug info
				case 3: 27; // Extended debug info
				default: 0;
			}

			var wd = switch (debugLevel)
			{
				case 1: 8; // Normal with bg: FPS, Delay, Memory, (optional modAuthor)
				case 2: 17; // Basic debug info
				case 3: 17; // Extended debug info
				default: 0;
			}

			final INNER_DIFF:Int = 3;
			var bgWidth = wd * 18 + 20;
			var bgHeight = lines * 18 + 20;

			// Outer rectangle (border color) with 50% opacity
			g.beginFill(0x3d3f41, 0.5);
			g.drawRect(0, 0, bgWidth + (INNER_DIFF * 2), bgHeight + (INNER_DIFF * 2));
			g.endFill();

			// Inner rectangle (main background) with 50% opacity
			g.beginFill(0x2c2f30, 0.5);
			g.drawRect(INNER_DIFF, INNER_DIFF, bgWidth, bgHeight);
			g.endFill();

			// Background visible
			bgShape.visible = true;
		}
		else
		{
			// Hide background for mode 0 (normal without bg)
			bgShape.visible = false;
		}
	}

	// Función para obtener información del último commit
	private function getLastCommit():Void
	{
		#if sys
		// Intentar obtener información desde la API de GitHub
		var http = new Http('https://api.github.com/repos/Psych-Plus-Team/FNF-PlusEngine/commits?per_page=1');
		http.addHeader('User-Agent', 'FNF-PlusEngine');

		http.onData = function(data:String)
		{
			try
			{
				var commits:Array<Dynamic> = Json.parse(data);
				if (commits != null && commits.length > 0)
				{
					var latestCommit = commits[0];
					var sha:String = latestCommit.sha.substr(0, 7);
					var message:String = latestCommit.commit.message;

					// Obtener la fecha y hora del commit
					var commitDateRaw:String = latestCommit.commit.author.date; // Formato ISO 8601

					// Tomar solo la primera línea del mensaje
					if (message.indexOf('\n') != -1)
					{
						message = message.substr(0, message.indexOf('\n'));
					}

					// Limitar longitud del mensaje
					if (message.length > 30)
					{
						message = message.substring(0, 30) + "...";
					}

					// Formatear la fecha y hora del commit
					if (commitDateRaw != null && commitDateRaw.length > 0)
					{
						// Formato: 2024-11-02T15:30:45Z
						var parts = commitDateRaw.split('T');
						if (parts.length >= 2)
						{
							// Extraer fecha (2024-11-02)
							commitDate = parts[0];

							// Extraer hora (15:30:45Z -> 15:30)
							var timePart = parts[1];
							if (timePart != null)
							{
								commitTime = timePart.substr(0, 5); // "15:30"
							}
						}
					}

					lastCommit = sha + " " + message;
				}
				else
				{
					lastCommit = "Build version";
					commitTime = "";
					commitDate = "";
				}
			}
			catch (e:Dynamic)
			{
				lastCommit = "Build version";
				commitTime = "";
				commitDate = "";
			}
		};

		http.onError = function(error:String)
		{
			lastCommit = "Build version";
		};

		http.request(false);
		#else
		lastCommit = "Build version";
		#end
	}

	// Función para obtener tiempo de ejecución
	private function getUptime():String
	{
		var uptime = haxe.Timer.stamp() - startTime;
		var hours = Math.floor(uptime / 3600);
		var minutes = Math.floor((uptime % 3600) / 60);
		var seconds = Math.floor(uptime % 60);

		if (hours > 0)
		{
			return '${hours}h ${minutes}m ${seconds}s';
		}
		else if (minutes > 0)
		{
			return '${minutes}m ${seconds}s';
		}
		else
		{
			return '${seconds}s';
		}
	}

	// Función para formatear números flotantes
	private function formatFloat(value:Float, decimals:Int):String
	{
		var multiplier = Math.pow(10, decimals);
		var rounded = Math.round(value * multiplier) / multiplier;
		var str = Std.string(rounded);

		// Asegurar que tenga el número correcto de decimales
		if (str.indexOf('.') == -1)
		{
			str += '.';
		}

		var parts = str.split('.');
		if (parts.length > 1)
		{
			while (parts[1].length < decimals)
			{
				parts[1] += '0';
			}
			return parts[0] + '.' + parts[1];
		}

		return str + StringTools.lpad('', '0', decimals);
	}

	// Función para obtener draw calls aproximados
	private function getDrawCalls():Int
	{
		// Estimación basada en objetos visibles
		return FlxG.state.members.length * 2; // Aproximación
	}

	// Función para obtener estadísticas del recolector de basura
	private function getGCStats():String
	{
		#if cpp
		try
		{
			// Obtener información de memoria del GC
			var totalMem = cpp.vm.Gc.memInfo64(cpp.vm.Gc.MEM_INFO_RESERVED);
			var usedMem = cpp.vm.Gc.memInfo64(cpp.vm.Gc.MEM_INFO_USAGE);
			var freeMem = totalMem - usedMem;

			var freePercentage = Math.round((freeMem / totalMem) * 100);
			return '${freePercentage}% free';
		}
		catch (e:Dynamic)
		{
			return 'N/A';
		}
		#else
		return 'N/A';
		#end
	}

	// Returns the current state name
	private function getCurrentState():String
	{
		if (FlxG.state == null)
			return "null";

		var stateName = Type.getClassName(Type.getClass(FlxG.state));

		// Strip package prefix
		if (stateName.indexOf('.') > -1)
		{
			var parts = stateName.split('.');
			stateName = parts[parts.length - 1];
		}

		// Show the script name when running inside a ScriptableState
		#if (HSCRIPT_ALLOWED && sys)
		if (FlxG.state is backend.ScriptableState)
		{
			var sName:String = (cast FlxG.state : backend.ScriptableState).stateName;
			if (sName != null)
				stateName = 'ScriptableState($sName)';
		}
		#end

		// Check for active substate
		if (FlxG.state.subState != null)
		{
			var subStateName = Type.getClassName(Type.getClass(FlxG.state.subState));
			if (subStateName.indexOf('.') > -1)
			{
				var parts = subStateName.split('.');
				subStateName = parts[parts.length - 1];
			}
			return '${stateName} -> ${subStateName}';
		}

		return stateName;
	}

	// Función para obtener el idioma actual
	private function getCurrentLanguage():String
	{
		#if TRANSLATIONS_ALLOWED
		try
		{
			// Obtener el código del idioma desde ClientPrefs
			var langCode = ClientPrefs.data.language;

			// Obtener el nombre del idioma desde Language.hx
			var langName = Language.getPhrase('language_name');
			if (langName != null && langName.length > 0)
			{
				return '${langName} (${langCode})';
			}
			else
			{
				return langCode;
			}
		}
		catch (e:Dynamic)
		{
			return 'Unknown';
		}
		#else
		return 'English (US)'; // Default cuando las traducciones están deshabilitadas
		#end
	}

	// Función para actualizar contadores de rendimiento (ultra-optimizada)
	private function updateCountersOptimized():Void
	{
		var currentTime = haxe.Timer.stamp();

		// Actualizar cache de datos mínimos cada 0.5 segundos para mejor respuesta
		if (currentTime - lastCacheUpdateTime >= 0.5)
		{
			lastCacheUpdateTime = currentTime;
			cachedCurrentState = getCurrentState();
		}
	}

	// Función optimizada para contar notas sin reflection costosa
	// ELIMINADA - Ya no se usa para mejor rendimiento

	inline function get_memoryMegas():Float
		return cpp.vm.Gc.memInfo64(cpp.vm.Gc.MEM_INFO_USAGE);

	inline function get_taskMemory():Float
	{
		return backend.MemoryUtil.getTaskMemory();
	}

	public inline function positionFPS(X:Float, Y:Float, ?scale:Float = 1)
	{
		// Mantener siempre el mismo tamaño, ignorar el parámetro scale
		scaleX = scaleY = 1.0;

		// Solo reposicionamiento, sin escalado
		x = X;
		y = Y;

		// Actualizar posición del fondo también para que siga al texto
		updateBackground();
	}

	// Clean up resources
	public function destroy():Void
	{
		if (FlxG.stage != null)
		{
			FlxG.stage.removeEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
		}

		if (bgShape != null && bgShape.parent != null)
		{
			removeChild(bgShape);
		}

		if (textDisplay != null && textDisplay.parent != null)
		{
			removeChild(textDisplay);
		}
	}

	// Funciones para obtener uso real de CPU y GPU
	// ELIMINADAS - Ya no se usan para mejor rendimiento
	// Funciones de estimación como fallback
	// ELIMINADAS - Ya no se usan para mejor rendimiento
	#if cpp
	#if windows
	@:functionCode('
		SYSTEM_INFO osInfo;

		GetSystemInfo(&osInfo);

		switch(osInfo.wProcessorArchitecture)
		{
			case 9:
				return ::String("x86_64");
			case 5:
				return ::String("ARM");
			case 12:
				return ::String("ARM64");
			case 6:
				return ::String("IA-64");
			case 0:
				return ::String("x86");
			default:
				return ::String("Unknown");
		}
	')
	#elseif (ios || mac)
	@:functionCode('
		const NXArchInfo *archInfo = NXGetLocalArchInfo();
    	return ::String(archInfo == NULL ? "Unknown" : archInfo->name);
	')
	#else
	@:functionCode('
		struct utsname osInfo{};
		uname(&osInfo);
		return ::String(osInfo.machine);
	')
	#end
	@:noCompletion
	private function getArch():String
	{
		return "Unknown";
	}
	#end
}

