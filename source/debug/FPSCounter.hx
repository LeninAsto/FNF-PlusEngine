package debug;

import flixel.FlxG;
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
import backend.BuildInfo;
import backend.MemoryUtil.MemoryStats;
import backend.Native;
import backend.ThreadUtil;
import backend.ui.md3.NetworkCheckToast;
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

	/**
		Debug level for FPS counter (0: hidden, 1: normal without bg, 2: normal with bg, 3: basic debug, 4: extended debug)
	**/
	public var debugLevel:Int = #if mobile 0 #else 2 #end;

	/**
		Mod author text that can be set from Lua scripts
	**/
	public var modAuthor:String = "";

	private var metricBoxes:Array<FPSCounterBox> = [];

	/**
		Last GitHub commit info
	**/
	private var lastCommit:String = "Loading...";

	private var commitTime:String = ""; // Commit time
	private var commitDate:String = ""; // Commit date

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
	private var cachedMemoryStats:Null<MemoryStats> = null;
	private var lastMemoryStatsUpdateTime:Float = -9999.0;
	private var gcCollectionsPerSecond:Float = 0.0;
	private var gcTimePercent:Float = 0.0;

	/**
		Text update throttling to reduce overhead in debug mode.
	**/
	private var cachedStaticText:String = ""; // Cached static text (OS, commit, etc.).
	private var graphicsLabel:String = "OpenGL Unknown";
	private var audioLabel:String = "Unable to detect";

	/**
		Frame timing used to track delay and stutter.
	**/
	private var lastFrameTime:Float = 0.0;

	private var frameTimeMs:Float = 0.0;
	private var frameTimesArray:Array<Float> = [];
	private var avgFrameTimeMs:Float = 0.0;

	@:noCompletion private static inline var TIMES_CAPACITY:Int = 1024;
	@:noCompletion private static inline var FRAME_TIMES_CAPACITY:Int = 10;

	@:noCompletion private var times:Array<Float>;
	@:noCompletion private var timesHead:Int = 0;
	@:noCompletion private var timesCount:Int = 0;
	@:noCompletion private var frameTimesHead:Int = 0;
	@:noCompletion private var frameTimesCount:Int = 0;
	@:noCompletion private var frameTimesTotal:Float = 0;
	@:noCompletion private var deltaTimeout:Float = 0.0;
	@:noCompletion private static inline final TEXT_UPDATE_MS:Float = 125.0;
	@:noCompletion private static inline final MEMORY_STATS_UPDATE_SECONDS:Float = 0.25;

	public var os:String = '';

	private var lastTextColorValue:Int = 0xFFFFFF;
	private var pendingLayoutRefresh:Bool = true;
	private var realtimeMemoryLabel:String = '';
	private var lastRealtimeFPS:Int = -1;
	private var lastRealtimeDelay:Int = -1;
	private var lastRealtimeAverage:Int = -1;
	private var lastRealtimeLevel:Int = -1;
	private var lastRealtimeMemory:String = '';

	public function new(x:Float = 10, y:Float = 10, color:Int = 0x000000)
	{
		super();

		// Assign singleton instance.
		instance = this;

		applyPrefs(false);

		#if officialBuild
		if (LimeSystem.platformName == LimeSystem.platformVersion || LimeSystem.platformVersion == null)
			os = '\nOS: ${LimeSystem.platformName}' #if cpp + ' ${getArch() != 'Unknown' ? getArch() : ''}' #end;
		else
			os = '\nOS: ${LimeSystem.platformName}' #if cpp + ' ${getArch() != 'Unknown' ? getArch() : ''}' #end + ' - ${LimeSystem.platformVersion}';
		#end

		positionFPS(x, y);

		currentFPS = 0;
		graphicsLabel = Native.getOpenGLLabel();
		audioLabel = Native.getOpenALSoftVersion();

		for (i in 0...8)
		{
			var box = new FPSCounterBox(color);
			box.visible = false;
			metricBoxes.push(box);
			addChild(box);
		}

		times = [for (i in 0...TIMES_CAPACITY) 0];

		// Initialize frame time measurement
		lastFrameTime = Timer.stamp();
		frameTimesArray = [for (i in 0...FRAME_TIMES_CAPACITY) 0];

		// Add listener for F2
		if (FlxG.stage != null)
		{
			FlxG.stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
		}

		// Get build/commit info without touching the network in normal builds.
		getLastCommit();

		// Initialize runtime tracking
		startTime = haxe.Timer.stamp();
		lastCacheUpdateTime = startTime;

		// Initialize minimal cache
		cachedCurrentState = "Unknown";
	}

	public dynamic function updateText():Void // so people can override it in hscript
	{
		applyPrefs(false);
		if (debugLevel <= 0)
		{
			hideUnusedBoxes(0);
			layoutBoxes();
			return;
		}

		// Get current real memory
		var currentMemory = memoryMegas;

		// Update peak memory
		if (currentMemory > memoryPeak)
		{
			memoryPeak = currentMemory;
		}

		displayedMemory = currentMemory;
		displayedMemoryPeak = memoryPeak;

		// Format displayed memory (smoothed values)
		var currentMemoryStr = flixel.util.FlxStringUtil.formatBytes(displayedMemory);
		var peakMemoryStr = flixel.util.FlxStringUtil.formatBytes(displayedMemoryPeak);
		realtimeMemoryLabel = currentMemoryStr + ' / ' + peakMemoryStr;

		// White or red color based on FPS
		var targetFPS = ClientPrefs.data.framerate;
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
		if (textColorValue != lastTextColorValue)
		{
			lastTextColorValue = textColorValue;
			for (box in metricBoxes)
				box.setTextColor(textColorValue);
		}

		// Update counters for debug modes without extra throttling.
		if (debugLevel >= 3)
		{
			updateCountersOptimized();
		}

		var index:Int = 0;
		var showBackground:Bool = debugLevel >= 2;
		var showCounter:Bool = debugLevel > 0;

		if (showCounter)
		{
			updateRealtimeText();
			index++;

			if (modAuthor != null && modAuthor.length > 0)
				setBox(index++, modAuthor, showBackground);
		}

		if (debugLevel >= 3)
		{
			var memoryStats:MemoryStats = getCachedMemoryStats();
			var memoryDebug:String = 'GC Live: ' + currentMemoryStr + '\nGC Current: '
				+ formatMemoryStat(memoryStats.gcCurrent)
				+ '\nPeak Live: ' + peakMemoryStr;
			if (backend.MemoryUtil.supportsTaskMem())
				memoryDebug += '\nTask Memory: ' + flixel.util.FlxStringUtil.formatBytes(memoryStats.taskMemory);
			setBox(index++, memoryDebug, true);

			if (debugLevel >= 4)
			{
				var gcDebug:String = memoryStats.rootGCStatsAvailable
					? 'GC Runs: ' + memoryStats.gcCollections
						+ '\nPause last/max: ' + formatFloat(memoryStats.gcLastDurationMs, 2)
						+ ' / ' + formatFloat(memoryStats.gcMaxDurationMs, 2) + ' ms'
						+ '\nThread wait last/max: ' + formatFloat(memoryStats.gcLastThreadWaitMs, 2)
						+ ' / ' + formatFloat(memoryStats.gcMaxThreadWaitMs, 2) + ' ms'
						+ '\nTotal GC: ' + formatFloat(memoryStats.gcTotalDurationMs, 1) + ' ms'
						+ '\nRate/load: ' + formatFloat(gcCollectionsPerSecond, 2) + '/s / '
						+ formatFloat(gcTimePercent, 2) + '%'
						+ '\nLast GC: ' + formatGCType(memoryStats.gcLastFlags)
						+ ' | freed ' + flixel.util.FlxStringUtil.formatBytes(memoryStats.gcLastReclaimedBytes)
						+ '\nFreed total: ' + flixel.util.FlxStringUtil.formatBytes(memoryStats.gcTotalReclaimedBytes)
					: 'GC runtime stats: unavailable';
				gcDebug += '\nRuntime: ' + memoryStats.runtime
					+ ' | Manual GC: ' + (memoryStats.manualCollectionAvailable ? 'available' : 'automatic only');
				gcDebug += '\nReserved: ' + formatMemoryStat(memoryStats.gcReserved)
					+ ' | Large: ' + formatMemoryStat(memoryStats.gcLarge)
					+ '\nHeap growth: ' + flixel.util.FlxStringUtil.formatBytes(memoryStats.allocationGrowth);
				gcDebug += '\nGC Policy: ' + backend.MemoryManager.lastCollectionDecision
					+ '\nScheduler backoff: x' + backend.MemoryManager.collectionBackoff;
				if (backend.MemoryManager.collectionPending)
					gcDebug += '\nPending: ' + backend.MemoryManager.pendingCollectionReason
						+ ' (' + backend.MemoryManager.pendingReleasedAssets + ' assets)';
				setBox(index++, gcDebug, true);
			}

			var commitText:String = BuildInfo.githubDevBuild && BuildInfo.commit.length > 0 ? BuildInfo.shortCommit() : lastCommit;
			var buildDebug:String = os.substring(1) + '\nCommit: ' + commitText;
			if (BuildInfo.githubDevBuild && BuildInfo.runId.length > 0)
				buildDebug += '\nBuild: #' + BuildInfo.runId;
			buildDebug += '\nState: ' + cachedCurrentState;
			if (debugLevel >= 4)
			{
				if (commitDate != null && commitDate.length > 0)
					buildDebug += '\nDate: ' + commitDate;
				if (commitTime != null && commitTime.length > 0)
					buildDebug += '\nTime: ' + commitTime + ' UTC';
				buildDebug += '\nUptime: ' + getUptime();
			}
			setBox(index++, buildDebug, true);
		}

		if (debugLevel >= 4)
			setBox(index++, 'OpenFL - ' + graphicsLabel
				+ '\n' + audioLabel
				+ '\nPlus Engine v' + MainMenuState.plusEngineVersion
				+ '\nPsych v' + MainMenuState.psychEngineVersion, true);

		hideUnusedBoxes(index);
		layoutBoxes();
	}

	private override function __enterFrame(deltaTime:Float):Void
	{
		super.__enterFrame(Std.int(deltaTime));
		// Compute frame time (delay).
		var currentFrameTime = Timer.stamp();
		frameTimeMs = (currentFrameTime - lastFrameTime) * 1000.0; // Convert to milliseconds
		lastFrameTime = currentFrameTime;

		frameTimesTotal -= frameTimesArray[frameTimesHead];
		frameTimesArray[frameTimesHead] = frameTimeMs;
		frameTimesTotal += frameTimeMs;
		frameTimesHead = (frameTimesHead + 1) % FRAME_TIMES_CAPACITY;
		if (frameTimesCount < FRAME_TIMES_CAPACITY)
			frameTimesCount++;
		avgFrameTimeMs = frameTimesCount > 0 ? frameTimesTotal / frameTimesCount : frameTimeMs;

		final now:Float = currentFrameTime * 1000;
		final cap:Int = TIMES_CAPACITY;

		if (timesCount < cap)
		{
			times[(timesHead + timesCount) % cap] = now;
			timesCount++;
		}
		else
		{
			times[timesHead] = now;
			timesHead = (timesHead + 1) % cap;
		}

		final cutoff:Float = now - 1000;
		while (timesCount > 0 && times[timesHead] < cutoff)
		{
			timesHead = (timesHead + 1) % cap;
			timesCount--;
		}

		currentFPS = timesCount < FlxG.drawFramerate ? timesCount : FlxG.drawFramerate;

		deltaTimeout += Math.max(0, deltaTime);
		if (deltaTimeout >= TEXT_UPDATE_MS)
		{
			updateText();
			deltaTimeout = 0;
		}
		if (debugLevel > 0)
		{
			updateRealtimeText();
			layoutBoxes();
		}
		animateBoxes(Math.min(deltaTime / 1000, 0.1));
	}

	/** Runs each display frame; only changed, rounded values rebuild the text. */
	public dynamic function updateRealtimeText():Void
	{
		var delay = Math.round(frameTimeMs * 10);
		var average = Math.round(avgFrameTimeMs * 10);
		var color = currentFPS >= ClientPrefs.data.framerate * 0.5 ? 0xFFFFFF : 0xFF0000;
		if (color != lastTextColorValue)
		{
			lastTextColorValue = color;
			for (box in metricBoxes) box.setTextColor(color);
		}
		if (currentFPS == lastRealtimeFPS && delay == lastRealtimeDelay && average == lastRealtimeAverage
			&& debugLevel == lastRealtimeLevel && realtimeMemoryLabel == lastRealtimeMemory)
			return;
		lastRealtimeFPS = currentFPS;
		lastRealtimeDelay = delay;
		lastRealtimeAverage = average;
		lastRealtimeLevel = debugLevel;
		lastRealtimeMemory = realtimeMemoryLabel;
		setBox(0, currentFPS + ' FPS - Delay: ' + (delay / 10) + ' / ' + (average / 10)
			+ ' ms - GC: ' + realtimeMemoryLabel, debugLevel >= 2);
	}

	// Handle the F2 key event.
	private function onKeyDown(event:KeyboardEvent):Void
	{
		if (event.keyCode == Keyboard.F2)
		{
			debugLevel = (debugLevel + 1) % 5; // Cycle: hidden, no bg, bg, basic debug, extended debug
			ClientPrefs.data.fpsDebugLevel = debugLevel;
			ClientPrefs.data.fpsCounterMode = modeFromLevel(debugLevel);
			ClientPrefs.saveSettings();
			visible = debugLevel > 0;
			updateText();
		}
	}

	// Función para actualizar el fondo
	public function applyPrefs(?refresh:Bool = true):Void
	{
		ClientPrefs.normalizeFPSCounterPrefs();
		var newLevel:Int = ClientPrefs.data.fpsDebugLevel;
		if (newLevel != debugLevel)
		{
			debugLevel = newLevel;
			pendingLayoutRefresh = true;
		}
		visible = debugLevel > 0;

		if (refresh)
			updateText();
	}

	private function setBox(index:Int, text:String, showBackground:Bool):Void
	{
		if (index < 0 || index >= metricBoxes.length)
			return;

		var wasHidden:Bool = !metricBoxes[index].targetShown;
		var contentChanged:Bool = metricBoxes[index].setContent(text, showBackground);
		if (wasHidden || contentChanged)
			pendingLayoutRefresh = true;
		metricBoxes[index].targetShown = true;
	}

	private function hideUnusedBoxes(fromIndex:Int):Void
	{
		for (i in fromIndex...metricBoxes.length)
		{
			if (metricBoxes[i].targetShown)
				pendingLayoutRefresh = true;
			metricBoxes[i].targetShown = false;
		}
	}

	private function layoutBoxes():Void
	{
		if (!pendingLayoutRefresh)
			return;

		var nextY:Float = 0;
		for (box in metricBoxes)
		{
			box.baseX = 0;
			box.baseY = nextY;
			if (box.targetShown)
				nextY += box.boxHeight + 4;
		}
		pendingLayoutRefresh = false;
	}

	private function animateBoxes(elapsed:Float):Void
	{
		for (box in metricBoxes)
			box.animate(elapsed);
	}

	private function modeFromLevel(level:Int):String
	{
		return switch (level)
		{
			case 0: 'Hidden';
			case 1: 'Visible No Background';
			case 2: 'Visible with Background';
			case 3: 'Basic Debug';
			case 4: 'Extended Debug';
			default: 'Visible with Background';
		}
	}

	// Función para obtener información del último commit
	private function getLastCommit():Void
	{
		if (BuildInfo.githubDevBuild && BuildInfo.commit.length > 0)
		{
			lastCommit = BuildInfo.shortCommit();
			return;
		}

		#if (sys && debug)
		NetworkCheckToast.requestShow('Checking commit');
		#if (target.threaded && sys)
		ThreadUtil.execAsync(loadLastCommitBlocking);
		#else
		loadLastCommitBlocking();
		#end
		#else
		lastCommit = "Build version";
		#end
	}

	private function loadLastCommitBlocking():Void
	{
		#if sys
		var loaded:Bool = false;
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
					loaded = true;
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

		try
		{
			http.request(false);
		}
		catch (e:Dynamic)
		{
			lastCommit = "Build version";
			commitTime = "";
			commitDate = "";
		}
		NetworkCheckToast.requestDone(loaded ? 'Obtenido' : 'Sin conexion');
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

		var stateName = formatStateClassName(Type.getClassName(Type.getClass(FlxG.state)));

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
			var subStateName = formatStateClassName(Type.getClassName(Type.getClass(FlxG.state.subState)));
			return '${stateName} -> ${subStateName}';
		}

		return stateName;
	}

	private function formatStateClassName(fullName:String):String
	{
		if (fullName == null || fullName.length <= 0)
			return "Unknown";

		var stateName = fullName;
		if (stateName.indexOf('.') > -1)
		{
			var parts = stateName.split('.');
			stateName = parts[parts.length - 1];
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

	private function getCachedMemoryStats():MemoryStats
	{
		var now:Float = Timer.stamp();
		var previous:Null<MemoryStats> = cachedMemoryStats;
		var elapsed:Float = now - lastMemoryStatsUpdateTime;
		if (previous == null || elapsed >= MEMORY_STATS_UPDATE_SECONDS)
		{
			var next:MemoryStats = backend.MemoryUtil.getMemoryStats();
			if (previous != null && next.rootGCStatsAvailable && elapsed > 0)
			{
				var collectionDelta:Int = next.gcCollections - previous.gcCollections;
				var durationDelta:Float = next.gcTotalDurationMs - previous.gcTotalDurationMs;
				gcCollectionsPerSecond = Math.max(0, collectionDelta / elapsed);
				gcTimePercent = Math.max(0, durationDelta / (elapsed * 1000.0) * 100.0);
			}
			else
			{
				gcCollectionsPerSecond = 0;
				gcTimePercent = 0;
			}

			cachedMemoryStats = next;
			lastMemoryStatsUpdateTime = now;
			return next;
		}

		return previous;
	}

	private static function formatGCType(flags:Int):String
	{
		if ((flags & 8) != 0)
			return 'compact';
		if ((flags & 4) != 0)
			return 'generational';
		if ((flags & 1) != 0)
			return 'major';
		if ((flags & 2) != 0)
			return 'full';
		return flags == 0 ? 'none yet' : 'minor';
	}

	// Función optimizada para contar notas sin reflection costosa
	// ELIMINADA - Ya no se usa para mejor rendimiento

	private static inline function formatMemoryStat(bytes:Float):String
		return bytes < 0 ? 'unavailable' : flixel.util.FlxStringUtil.formatBytes(bytes);

	inline function get_memoryMegas():Float
		return Math.max(0, backend.MemoryUtil.getGCMemory());

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
		pendingLayoutRefresh = true;
	}

	// Clean up resources
	public function destroy():Void
	{
		if (FlxG.stage != null)
		{
			FlxG.stage.removeEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
		}

		for (box in metricBoxes)
		{
			if (box != null && box.parent != null)
				removeChild(box);
		}
		metricBoxes = [];
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

private class FPSCounterBox extends Sprite
{
	public var targetShown:Bool = false;
	public var baseX:Float = 0;
	public var baseY:Float = 0;
	public var boxHeight(default, null):Float = 24;

	private var bgShape:Shape;
	private var textDisplay:TextField;
	private var shownAmount:Float = 0;
	private var hasBackground:Bool = false;
	private var boxWidth:Float = 48;
	private var lastColor:Int = -1;
	private var textFormat:TextFormat;

	private static inline var PADDING_X:Float = 8;
	private static inline var PADDING_Y:Float = 5;
	private static inline var INNER_DIFF:Int = 3;

	public function new(color:Int)
	{
		super();

		bgShape = new Shape();
		addChild(bgShape);

		textDisplay = new TextField();
		textDisplay.selectable = false;
		textDisplay.mouseEnabled = false;
		textFormat = new TextFormat('Monsterrat', 14, color);
		textDisplay.defaultTextFormat = textFormat;
		textDisplay.antiAliasType = openfl.text.AntiAliasType.NORMAL;
		textDisplay.sharpness = 100;
		textDisplay.multiline = true;
		textDisplay.wordWrap = false;
		textDisplay.autoSize = openfl.text.TextFieldAutoSize.LEFT;
		textDisplay.x = PADDING_X + INNER_DIFF;
		textDisplay.y = PADDING_Y + INNER_DIFF - 2;
		addChild(textDisplay);
	}

	public function setTextColor(color:Int):Void
	{
		if (lastColor == color)
			return;

		lastColor = color;
		textFormat.color = color;
		textDisplay.defaultTextFormat = textFormat;
		textDisplay.setTextFormat(textFormat);
	}

	public function setContent(text:String, showBackground:Bool):Bool
	{
		if (textDisplay.text == text && hasBackground == showBackground)
			return false;

		if (textDisplay.text != text) textDisplay.text = text;
		// Keep a stable width for changing digits. Background commands are reused
		// by the renderer instead of being cleared/rebuilt on every new frame time.
		var nextWidth = Math.max(boxWidth, Math.ceil((textDisplay.textWidth + (PADDING_X * 2) + (INNER_DIFF * 2) + 6) / 16) * 16);
		var nextHeight = Math.max(24, textDisplay.textHeight + (PADDING_Y * 2) + (INNER_DIFF * 2));
		var geometryChanged = nextWidth != boxWidth || nextHeight != boxHeight || hasBackground != showBackground;
		boxWidth = nextWidth;
		boxHeight = nextHeight;
		hasBackground = showBackground;
		if (geometryChanged) drawBackground();
		return geometryChanged;
	}

	public function animate(elapsed:Float):Void
	{
		var target:Float = targetShown ? 1 : 0;
		if (shownAmount == target && x == baseX - ((1 - target) * 14) && y == baseY)
			return;
		var speed:Float = Math.min(1, elapsed * 12);
		shownAmount += (target - shownAmount) * speed;
		if (Math.abs(target - shownAmount) < 0.01)
			shownAmount = target;

		visible = shownAmount > 0.001;
		alpha = shownAmount;
		x = baseX - ((1 - shownAmount) * 14);
		y = baseY;
	}

	private function drawBackground():Void
	{
		var g:Graphics = bgShape.graphics;
		g.clear();
		bgShape.visible = hasBackground;
		if (!hasBackground)
			return;

		g.beginFill(0x3d3f41, 0.5);
		g.drawRect(0, 0, boxWidth, boxHeight);
		g.endFill();

		g.beginFill(0x2c2f30, 0.5);
		g.drawRect(INNER_DIFF, INNER_DIFF, boxWidth - (INNER_DIFF * 2), boxHeight - (INNER_DIFF * 2));
		g.endFill();
	}
}

