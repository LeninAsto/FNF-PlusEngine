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
typedef TraceInfo = {
    var text:String;
    var color:Int;
    var type:TraceType;
    var timestamp:Float;
}

/**
 * Tipos de traces para clasificación
 */
enum TraceType {
    NORMAL;
    ERROR;
    LUA_ERROR;
    HSCRIPT_ERROR;
    SSCRIPT_ERROR;
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
    public var maxTraces:Int = 30;
    
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
        if (instance != null) {
            trace("TraceDisplay: Ya existe una instancia, destruyendo la anterior");
            instance.destroy();
        }
        
        // Configurar singleton
        instance = this;
        
        this.x = x;
        this.y = y;
        
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
        
        // Crear fondo
        backgroundShape = new Shape();
        addChildAt(backgroundShape, 0); // Add background behind text
        addChild(textDisplay); // Add text on top
        
        // Interceptar traces y errores solo si no se ha hecho antes
        if (originalTrace == null) {
            setupTraceCapture();
            setupErrorCapture();
        }
        
        // Configurar listener para F4
        if (FlxG.stage != null) {
            FlxG.stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
        }
        
        // Inicialmente oculto
        textDisplay.visible = false;
        backgroundShape.visible = false;
    }
    
    /**
     * Configurar la captura de traces
     */
    private function setupTraceCapture():Void
    {
        // Guardar la función trace original
        originalTrace = Log.trace;
        
        // Reemplazar con nuestra función personalizada
        Log.trace = function(v:Dynamic, ?infos:PosInfos):Void {
            // Formatear para la consola/terminal con estilo limpio
            if (infos != null) {
                var fileName = extractFileName(infos.fileName);
                Sys.println('[$fileName - ${infos.lineNumber}]: ${Std.string(v)}');
            } else {
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
        Iris.error = function(message:String, ?pos:Dynamic):Void {
            // Llamar al error original
            originalIrisError(message, pos);
            
            // Agregar a nuestro display
            var errorText = 'HSCRIPT ERROR: $message';
            if (pos != null && pos.fileName != null) {
                var fileName = extractFileName(pos.fileName);
                errorText = 'HSCRIPT ERROR in $fileName: $message';
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
        
        if (infos != null) {
            var fileName = extractFileName(infos.fileName);
            traceText = '($fileName - ${infos.lineNumber}): ${Std.string(value)}';
        } else {
            traceText = Std.string(value);
        }
        
        addTraceDirectly(traceText, type, color);
    }
    
    /**
     * Agregar un trace directamente sin procesar
     */
    public function addTraceDirectly(text:String, type:TraceType = NORMAL, color:Int = 0xFFFFFF):Void
    {
        var traceInfo:TraceInfo = {
            text: text,
            color: color,
            type: type,
            timestamp: haxe.Timer.stamp()
        };
        
        traces.push(traceInfo);
        
        // Limitar el número de traces
        if (traces.length > maxTraces) {
            traces.shift();
        }
        
        // Actualizar display si está visible
        if (isVisible) {
            updateDisplay();
        }
    }
    
    /**
     * Extraer nombre de archivo sin path ni extensión
     */
    private function extractFileName(fileName:String):String
    {
        if (fileName == null) return "unknown";
        
        if (fileName.indexOf("/") != -1) {
            fileName = fileName.substr(fileName.lastIndexOf("/") + 1);
        }
        if (fileName.indexOf("\\") != -1) {
            fileName = fileName.substr(fileName.lastIndexOf("\\") + 1);
        }
        if (fileName.indexOf(".") != -1) {
            fileName = fileName.substr(0, fileName.lastIndexOf("."));
        }
        
        return fileName;
    }
    
    /**
     * Función pública para agregar errores de Lua
     */
    public static function addLuaError(text:String):Void
    {
        if (instance != null) {
            instance.addTraceDirectly('LUA ERROR: $text', LUA_ERROR, 0xFF6666);
        }
    }
    
    /**
     * Función pública para agregar errores de HScript
     */
    public static function addHScriptError(text:String, ?fileName:String):Void
    {
        if (instance != null) {
            var errorText = 'HSCRIPT ERROR: $text';
            if (fileName != null) {
                var name = instance.extractFileName(fileName);
                errorText = 'HSCRIPT ERROR in $name: $text';
            }
            instance.addTraceDirectly(errorText, HSCRIPT_ERROR, 0xFF4444);
        }
    }
    
    /**
     * Función pública para agregar errores de SScript
     */
    public static function addSScriptError(text:String, ?origin:String):Void
    {
        if (instance != null) {
            var errorText = 'SSCRIPT ERROR: $text';
            if (origin != null && origin.length > 0) {
                var name = instance.extractFileName(origin);
                errorText = 'SSCRIPT ERROR in $name: $text';
            }
            instance.addTraceDirectly(errorText, SSCRIPT_ERROR, 0xFF4444);
        }
        
        // Incrementar contador en FPSCounter
        #if !flash
        try {
            if (debug.FPSCounter.instance != null) {
                debug.FPSCounter.instance.sscriptsErrors++;
            }
        } catch(e) {}
        #end
    }
    
    /**
     * Función pública para agregar warnings
     */
    public static function addWarning(text:String):Void
    {
        if (instance != null) {
            instance.addTraceDirectly('WARNING: $text', WARNING, 0xFFAA00);
        }
    }
    
    /**
     * Función pública para agregar información
     */
    public static function addInfo(text:String):Void
    {
        if (instance != null) {
            instance.addTraceDirectly('INFO: $text', INFO, 0x00AAFF);
        }
    }
    
    /**
     * Actualizar el contenido mostrado
     */
    private function updateDisplay():Void
    {
        if (!isVisible) return;
        
        var displayText:String = "=== TRACES ===\n";
        
        if (traces.length == 0) {
            displayText += "Nothing for now...";
        } else {
            for (i in 0...traces.length) {
                var trace = traces[i];
                var prefix = switch(trace.type) {
                    case ERROR: "[ERROR] ";
                    case LUA_ERROR: "[LUA-ERR] ";
                    case HSCRIPT_ERROR: "[HSC-ERR] ";
                    case SSCRIPT_ERROR: "[SSCR-ERR] ";
                    case WARNING: "[WARN] ";
                    case INFO: "[INFO] ";
                    case NORMAL: "";
                }
                displayText += prefix + trace.text;
                if (i < traces.length - 1) displayText += "\n";
            }
        }
        
        textDisplay.text = displayText;
        updateBackground();
    }
    
    /**
     * Actualizar el fondo
     */
    private function updateBackground():Void
    {
        if (!isVisible || backgroundShape == null) return;
        
        final INNER_DIFF:Int = 3;
        var bgWidth = textDisplay.textWidth + 10;
        var bgHeight = textDisplay.textHeight + 10;
        
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
        if (event.keyCode == Keyboard.F4) {
            toggleDisplay();
        }
    }
    
    /**
     * Mostrar/ocultar el display
     */
    public function toggleDisplay():Void
    {
        isVisible = !isVisible;
        textDisplay.visible = isVisible;
        backgroundShape.visible = isVisible;
        
        if (isVisible) {
            updateDisplay();
        }
    }
    
    /**
     * Mostrar el display
     */
    public function show():Void
    {
        isVisible = true;
        textDisplay.visible = true;
        backgroundShape.visible = true;
        updateDisplay();
    }
    
    /**
     * Ocultar el display
     */
    public function hide():Void
    {
        isVisible = false;
        textDisplay.visible = false;
        backgroundShape.visible = false;
    }
    
    /**
     * Limpiar todos los traces
     */
    public function clear():Void
    {
        traces = [];
        if (isVisible) {
            updateDisplay();
        }
    }
    
    /**
     * Posicionar el display
     */
    public function positionTrace(x:Float, y:Float):Void
    {
        this.x = x;
        this.y = y;
        updateBackground();
    }
    
    /**
     * Cleanup al destruir
     */
    public function destroy():Void
    {
        // Restaurar trace original
        if (originalTrace != null) {
            Log.trace = originalTrace;
        }
        
        // Restaurar error handler original
        #if HSCRIPT_ALLOWED
        if (originalIrisError != null) {
            Iris.error = originalIrisError;
        }
        #end
        
        // Limpiar singleton
        if (instance == this) {
            instance = null;
        }
        
        // Remover listener
        if (FlxG.stage != null) {
            FlxG.stage.removeEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
        }
        
        // Limpiar
        traces = null;
        
        if (backgroundShape != null && backgroundShape.parent != null) {
            removeChild(backgroundShape);
        }
        backgroundShape = null;
        
        if (textDisplay != null && textDisplay.parent != null) {
            removeChild(textDisplay);
        }
        textDisplay = null;
    }
}
