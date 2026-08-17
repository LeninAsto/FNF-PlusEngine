package debug;

import flixel.FlxG;
import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.events.KeyboardEvent;
import openfl.ui.Keyboard;
import openfl.display.Shape;
import openfl.display.Sprite;
import haxe.Log;
import haxe.PosInfos;
#if HSCRIPT_ALLOWED
import crowplexus.iris.Iris;
#end

/**
 * Estructura para almacenar información de traces con colores
 */
typedef TraceInfo =
{
	var text:String;
	var color:Int;
	var type:TraceType;
	var timestamp:Float;
	var count:Int;
}

/**
 * Tipos de traces para clasificación
 */
enum TraceType
{
	NORMAL;
	ERROR;
	LUA_ERROR;
	HSCRIPT_ERROR;
	WARNING;
	INFO;
}

/**
 * TraceDisplay - Sistema para mostrar traces/logs dentro del juego
 * Se activa/desactiva con F4 y muestra los últimos traces en pantalla
 */
class TraceDisplay extends Sprite
{
	/**
	 * Lista de traces almacenados con información de color y tipo
	 */
	public var traces:Array<TraceInfo> = [];

	/**
	 * Máximo número de traces a mostrar
	 */
	public var maxTraces:Int = 80;

	public var maxStoredLines:Int = 80;
	public var maxVisibleLines:Int = 18;

	private static inline final TEXT_PADDING:Int = 8;

	/**
	 * Si el display está visible o no
	 */
	public var isVisible:Bool = false;

	/**
	 * TextField para mostrar el texto
	 */
	private var textDisplay:TextField;

	/**
	 * Fondo semi-transparente para mejor legibilidad
	 */
	private var backgroundShape:Shape;

	private var baseX:Float = 0;
	private var baseY:Float = 0;
	private var shownAmount:Float = 0;

	/**
	 * Referencia al trace original de Haxe
	 */
	private var originalTrace:Dynamic;

	/**
	 * Referencia al handler de errores original de Iris/HScript
	 */
	#if HSCRIPT_ALLOWED
	private var originalIrisError:Dynamic;
	#end

	/**
	 * Instancia singleton para acceso global
	 */
	public static var instance:TraceDisplay;

	public function new(x:Float = 10, y:Float = 50, textColor:Int = 0xFFFFFF)
	{
		super();

		// Verificar singleton - solo permitir una instancia
		if (instance != null)
		{
			trace("TraceDisplay: Ya existe una instancia, destruyendo la anterior");
			instance.destroy();
		}

		// Configurar singleton
		instance = this;

		this.x = x;
		this.y = y;
		baseX = x;
		baseY = y;

		// Create text display field
		textDisplay = new TextField();
		textDisplay.selectable = false;
		textDisplay.mouseEnabled = false;
		textDisplay.defaultTextFormat = new TextFormat('Monsterrat', 14, textColor);
		textDisplay.antiAliasType = openfl.text.AntiAliasType.NORMAL;
		textDisplay.sharpness = 100;
		textDisplay.autoSize = openfl.text.TextFieldAutoSize.LEFT;
		textDisplay.multiline = true;
		textDisplay.wordWrap = false;
		textDisplay.x = TEXT_PADDING;
		textDisplay.y = TEXT_PADDING;

		// Crear fondo
		backgroundShape = new Shape();
		addChildAt(backgroundShape, 0); // Add background behind text
		addChild(textDisplay); // Add text on top

		// Interceptar traces y errores solo si no se ha hecho antes
		if (originalTrace == null)
		{
			setupTraceCapture();
			setupErrorCapture();
		}

		// Configurar listener para F4
		if (FlxG.stage != null)
		{
			FlxG.stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
		}

		// Inicialmente oculto
		textDisplay.visible = true;
		backgroundShape.visible = true;
		alpha = 0;
		visible = false;
	}

	/**
	 * Configurar la captura de traces
	 */
	private function setupTraceCapture():Void
	{
		// Guardar la función trace original
		originalTrace = Log.trace;

		// Reemplazar con nuestra función personalizada
		Log.trace = function(v:Dynamic, ?infos:PosInfos):Void
		{
			// Formatear para la consola/terminal con estilo limpio
			if (infos != null)
			{
				var sourceLabel = formatSourceLabel(infos.fileName);
				Sys.println('[$sourceLabel - ${infos.lineNumber}]: ${Std.string(v)}');
			}
			else
			{
				Sys.println(Std.string(v));
			}

			// Agregar a nuestro display
			addTrace(v, infos, NORMAL, 0xFFFFFF);
		};
	}

	/**
	 * Configurar la captura de errores de scripts
	 */
	private function setupErrorCapture():Void
	{
		#if HSCRIPT_ALLOWED
		// Interceptar errores de HScript/Iris
		originalIrisError = Iris.error;
		Iris.error = function(message:String, ?pos:Dynamic):Void
		{
			// Llamar al error original
			originalIrisError(message, pos);

			// Agregar a nuestro display
			var errorText = 'HSCRIPT ERROR: $message';
			if (pos != null && pos.fileName != null)
			{
				var sourceLabel = formatSourceLabel(pos.fileName);
				errorText = 'HSCRIPT ERROR in $sourceLabel: $message';
			}
			addTraceDirectly(errorText, HSCRIPT_ERROR, 0xFF4444);
		};
		#end
	}

	/**
	 * Agregar un trace a la lista
	 */
	private function addTrace(value:Dynamic, ?infos:PosInfos, type:TraceType = NORMAL, color:Int = 0xFFFFFF):Void
	{
		var traceText:String;

		if (infos != null)
		{
			var sourceLabel = formatSourceLabel(infos.fileName);
			traceText = '$sourceLabel - ${infos.lineNumber}: ${Std.string(value)}';
		}
		else
		{
			traceText = Std.string(value);
		}

		addTraceDirectly(traceText, type, color);
	}

	/**
	 * Agregar un trace directamente sin procesar
	 */
	public function addTraceDirectly(text:String, type:TraceType = NORMAL, color:Int = 0xFFFFFF):Void
	{
		for (trace in traces)
		{
			if (trace.text == text && trace.type == type && trace.color == color)
			{
				trace.count++;
				trace.timestamp = haxe.Timer.stamp();
				if (isVisible)
				{
					updateDisplay();
				}
				return;
			}
		}

		var traceInfo:TraceInfo = {
			text: text,
			color: color,
			type: type,
			timestamp: haxe.Timer.stamp(),
			count: 1
		};

		traces.push(traceInfo);
		enforceTraceLimits();

		// Actualizar display si está visible
		if (isVisible)
		{
			updateDisplay();
		}
	}

	/**
	 * Extraer nombre de archivo sin path ni extensión
	 */
	private function extractFileName(fileName:String):String
	{
		if (fileName == null)
			return "unknown";

		if (fileName.indexOf("/") != -1)
		{
			fileName = fileName.substr(fileName.lastIndexOf("/") + 1);
		}
		if (fileName.indexOf("\\") != -1)
		{
			fileName = fileName.substr(fileName.lastIndexOf("\\") + 1);
		}
		if (fileName.indexOf(".") != -1)
		{
			fileName = fileName.substr(0, fileName.lastIndexOf("."));
		}

		return fileName;
	}

	private function formatSourceLabel(fileName:String):String
	{
		var label = extractFileName(fileName);
		return isFunkinSource(fileName) ? '(funkin) ' + label : label;
	}

	private function isFunkinSource(fileName:String):Bool
	{
		if (fileName == null)
			return false;

		var normalized = fileName.split("\\").join("/");
		return normalized.indexOf("/funkin/") != -1
			|| normalized.indexOf("source/funkin/") == 0
			|| normalized.indexOf("assets/funkin/") == 0
			|| normalized.indexOf("/assets/funkin/") != -1
			|| normalized.indexOf("funkin/") == 0;
	}

	/**
	 * Función pública para agregar errores de Lua
	 */
	public static function addLuaError(text:String):Void
	{
		if (instance != null)
		{
			instance.addTraceDirectly('LUA ERROR: $text', LUA_ERROR, 0xFF6666);
		}
	}

	/**
	 * Funcion publica para agregar traces de Lua, incluyendo warnings y deprecated.
	 */
	public static function addLuaTrace(text:String, color:Int = 0xFFFFFF, deprecated:Bool = false):Void
	{
		if (instance != null)
		{
			var type = instance.typeFromColorAndText(color, text, deprecated);
			var prefix = deprecated ? 'LUA DEPRECATED: ' : 'LUA: ';
			if (type == LUA_ERROR)
				prefix = 'LUA ERROR: ';
			else if (type == WARNING)
				prefix = deprecated ? 'LUA DEPRECATED: ' : 'LUA WARNING: ';
			instance.addTraceDirectly(prefix + text, type, instance.displayColorForType(type, color));
		}
	}

	/**
	 * Funcion publica para reflejar el panel debug del juego en TraceDisplay.
	 */
	public static function addDebugText(text:String, color:Int = 0xFFFFFF):Void
	{
		if (instance != null)
		{
			var type = instance.typeFromColorAndText(color, text, false);
			instance.addTraceDirectly(Std.string(text), type, instance.displayColorForType(type, color));
		}
	}

	/**
	 * Función pública para agregar errores de HScript
	 */
	public static function addHScriptError(text:String, ?fileName:String):Void
	{
		if (instance != null)
		{
			var errorText = 'HSCRIPT ERROR: $text';
			if (fileName != null)
			{
				var sourceLabel = instance.formatSourceLabel(fileName);
				errorText = 'HSCRIPT ERROR in $sourceLabel: $text';
			}
			instance.addTraceDirectly(errorText, HSCRIPT_ERROR, 0xFF4444);
		}
	}

	/**
	 * Función pública para agregar warnings
	 */
	public static function addWarning(text:String):Void
	{
		if (instance != null)
		{
			instance.addTraceDirectly('WARNING: $text', WARNING, 0xFFAA00);
		}
	}

	/**
	 * Función pública para agregar información
	 */
	public static function addInfo(text:String):Void
	{
		if (instance != null)
		{
			instance.addTraceDirectly('INFO: $text', INFO, 0x00AAFF);
		}
	}

	private function typeFromColorAndText(color:Int, text:String, deprecated:Bool):TraceType
	{
		var rgb = color & 0x00FFFFFF;
		var lower = Std.string(text).toLowerCase();
		if (rgb == 0xFF0000 || lower.indexOf('error') != -1 || lower.indexOf('fatal') != -1)
			return LUA_ERROR;
		if (deprecated || rgb == 0xFFFF00 || rgb == 0xFFAA00 || lower.indexOf('warning') != -1 || lower.indexOf('warn') != -1
			|| lower.indexOf('deprecated') != -1)
			return WARNING;
		if (rgb == 0x00FF00 || rgb == 0x00AAFF || lower.indexOf('loaded') != -1 || lower.indexOf('success') != -1)
			return INFO;
		return NORMAL;
	}

	private function displayColorForType(type:TraceType, color:Int):Int
	{
		return switch (type)
		{
			case LUA_ERROR | ERROR: 0xFF6666;
			case HSCRIPT_ERROR: 0xFF4444;
			case WARNING: 0xFFAA00;
			case INFO: 0x00AAFF;
			case NORMAL: color & 0x00FFFFFF;
		};
	}

	private function enforceTraceLimits():Void
	{
		while (traces.length > maxTraces)
			traces.shift();

		var totalLines = 0;
		for (trace in traces)
			totalLines += getTraceLineCount(trace);

		while (traces.length > 0 && totalLines > maxStoredLines)
			totalLines -= getTraceLineCount(traces.shift());
	}

	private function getTraceLineCount(trace:TraceInfo):Int
	{
		if (trace == null || trace.text == null || trace.text.length <= 0)
			return 1;
		return trace.text.split("\n").length;
	}

	private function formatTraceLine(trace:TraceInfo):String
	{
		var prefix = switch (trace.type)
		{
			case ERROR: "[ERROR] ";
			case LUA_ERROR: "[LUA-ERR] ";
			case HSCRIPT_ERROR: "[HSC-ERR] ";
			case WARNING: "[WARN] ";
			case INFO: "[INFO] ";
			case NORMAL: "";
		}

		var text = prefix + trace.text;
		if (trace.count > 1)
			text += ' x${trace.count}';
		return text;
	}

	private function getVisibleTraceLines():Array<String>
	{
		final lines:Array<String> = [];
		var traceIndex = traces.length - 1;

		while (traceIndex >= 0 && lines.length < maxVisibleLines)
		{
			final traceLines = formatTraceLine(traces[traceIndex]).split("\n");
			var lineIndex = traceLines.length - 1;
			while (lineIndex >= 0 && lines.length < maxVisibleLines)
			{
				lines.unshift(traceLines[lineIndex]);
				lineIndex--;
			}
			traceIndex--;
		}

		return lines;
	}

	/**
	 * Actualizar el contenido mostrado
	 */
	private function updateDisplay():Void
	{
		if (!isVisible)
			return;

		var displayText:String = "=== TRACES ===\n";

		if (traces.length == 0)
		{
			displayText += "Nothing for now...";
		}
		else
		{
			displayText += getVisibleTraceLines().join("\n");
		}

		textDisplay.text = displayText;
		updateBackground();
	}

	/**
	 * Actualizar el fondo
	 */
	private function updateBackground():Void
	{
		if (!isVisible || backgroundShape == null)
			return;

		final INNER_DIFF:Int = 3;
		var bgWidth = textDisplay.textWidth + (TEXT_PADDING * 2);
		var bgHeight = textDisplay.textHeight + (TEXT_PADDING * 2);

		backgroundShape.graphics.clear();

		// Outer rectangle (border color) with 50% opacity
		backgroundShape.graphics.beginFill(0x3d3f41, 0.5);
		backgroundShape.graphics.drawRect(0, 0, bgWidth + (INNER_DIFF * 2), bgHeight + (INNER_DIFF * 2));
		backgroundShape.graphics.endFill();

		// Inner rectangle (main background) with 50% opacity
		backgroundShape.graphics.beginFill(0x2c2f30, 0.5);
		backgroundShape.graphics.drawRect(INNER_DIFF, INNER_DIFF, bgWidth, bgHeight);
		backgroundShape.graphics.endFill();
	}

	/**
	 * Toggle del display con F4
	 */
	private function onKeyDown(event:KeyboardEvent):Void
	{
		if (event.keyCode == Keyboard.F4)
		{
			toggleDisplay();
		}
	}

	/**
	 * Mostrar/ocultar el display
	 */
	public function toggleDisplay():Void
	{
		isVisible = !isVisible;

		if (isVisible)
		{
			visible = true;
			updateDisplay();
		}
	}

	/**
	 * Mostrar el display
	 */
	public function show():Void
	{
		isVisible = true;
		visible = true;
		updateDisplay();
	}

	/**
	 * Ocultar el display
	 */
	public function hide():Void
	{
		isVisible = false;
	}

	/**
	 * Limpiar todos los traces
	 */
	public function clear():Void
	{
		traces = [];
		if (isVisible)
		{
			updateDisplay();
		}
	}

	/**
	 * Posicionar el display
	 */
	public function positionTrace(x:Float, y:Float):Void
	{
		baseX = x;
		baseY = y;
		this.x = baseX - (1 - shownAmount) * 18;
		this.y = baseY;
		updateBackground();
	}

	private override function __enterFrame(deltaTime:Float):Void
	{
		var target = isVisible ? 1.0 : 0.0;
		var elapsed = Math.max(0, deltaTime / 1000);
		shownAmount += (target - shownAmount) * Math.min(1, elapsed * 12);

		if (Math.abs(target - shownAmount) < 0.002)
			shownAmount = target;

		alpha = shownAmount;
		x = baseX - (1 - shownAmount) * 18;
		y = baseY;

		if (!isVisible && shownAmount <= 0)
			visible = false;
		else if (isVisible)
			visible = true;
	}

	/**
	 * Cleanup al destruir
	 */
	public function destroy():Void
	{
		// Restaurar trace original
		if (originalTrace != null)
		{
			Log.trace = originalTrace;
		}

		// Restaurar error handler original
		#if HSCRIPT_ALLOWED
		if (originalIrisError != null)
		{
			Iris.error = originalIrisError;
		}
		#end

		// Limpiar singleton
		if (instance == this)
		{
			instance = null;
		}

		// Remover listener
		if (FlxG.stage != null)
		{
			FlxG.stage.removeEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
		}

		// Limpiar
		traces = null;

		if (backgroundShape != null && backgroundShape.parent != null)
		{
			removeChild(backgroundShape);
		}
		backgroundShape = null;

		if (textDisplay != null && textDisplay.parent != null)
		{
			removeChild(textDisplay);
		}
		textDisplay = null;
	}
}

