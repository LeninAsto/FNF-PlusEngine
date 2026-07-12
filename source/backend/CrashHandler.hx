package backend;

import openfl.events.UncaughtErrorEvent;
import openfl.events.ErrorEvent;
import openfl.errors.Error;
#if sys
import sys.FileSystem;
import sys.io.File;
#end

using StringTools;
using flixel.util.FlxArrayUtil;

/**
 * Crash Handler.
 * @author YoshiCrafter29, Ne_Eo, MAJigsaw77 and Homura Akemi (HomuHomu833)
 */
class CrashHandler
{
	// Link de ayuda/repositorio para mostrar en caso de crash
	public static final HELP_LINK:String = "https://github.com/LeninAsto/FNF-PlusEngine";
	
	// Fun error messages for null references
	static final NULL_ERROR_MESSAGES:Array<String> = [
		"Oops! The code gods are not pleased... null reference found!",
		"Houston, we have a null problem!",
		"Error 404: Object not found (it's just null)",
		"Congrats! You've discovered the void! (null)",
		"The object decided to take a vacation (null)",
		"*sad trombone* null happened",
		"Null? More like... not cool!",
		"The object went to buy cigarettes and never came back (null)",
		"Achievement Unlocked: Find a null reference!",
		"Null references are stored in the balls",
		"Bruh moment: null reference detected",
		"Skill issue: you tried to use a null object",
		"The object said 'aight imma head out' (null)",
		"Error: object.exe has stopped working (null)",
		"Congratulations, you broke it! (null reference)",
		"The object is on a date with undefined (null)",
		"Null reference? In MY engine? It's more likely than you think",
		"Object not found. Did you check under the couch? (null)"
	];
	
	/**
	 * Adds a funny prefix to null-related error messages
	 */
	static function funnyNullMessage(originalMessage:String):String
	{
		if (originalMessage == null) return "Null error message (ironic, isn't it?)";
		
		var lowerMsg = originalMessage.toLowerCase();
		var isNullError = lowerMsg.contains("null") || 
		                  lowerMsg.contains("object reference") || 
		                  lowerMsg.contains("null pointer") ||
		                  lowerMsg.contains("null object");
		
		if (isNullError)
		{
			var funnyMsg = NULL_ERROR_MESSAGES[Std.random(NULL_ERROR_MESSAGES.length)];
			return '$funnyMsg';
		}
		
		return originalMessage;
	}
	
	public static function init():Void
	{
		openfl.Lib.current.loaderInfo.uncaughtErrorEvents.addEventListener(UncaughtErrorEvent.UNCAUGHT_ERROR, onUncaughtError);
		#if cpp
		untyped __global__.__hxcpp_set_critical_error_handler(onError);
		#elseif hl
		hl.Api.setErrorHandler(onError);
		#end
	}

	private static function onUncaughtError(e:UncaughtErrorEvent):Void
	{
		e.preventDefault();
		e.stopPropagation();
		e.stopImmediatePropagation();

		var m:String = e.error;
		if (Std.isOfType(e.error, Error))
		{
			var err = cast(e.error, Error);
			m = '${err.message}';
		}
		else if (Std.isOfType(e.error, ErrorEvent))
		{
			var err = cast(e.error, ErrorEvent);
			m = '${err.text}';
		}
		
		// Add funny message for null errors
		m = funnyNullMessage(m);
		
		var stack = haxe.CallStack.exceptionStack();
		var stackLabelArr:Array<String> = [];
		var stackLabel:String = "";
		for (e in stack)
		{
			switch (e)
			{
				case CFunction:
					stackLabelArr.push("Non-Haxe (C) Function");
				case Module(c):
					stackLabelArr.push('Module ${c}');
				case FilePos(parent, file, line, col):
					switch (parent)
					{
						case Method(cla, func):
							stackLabelArr.push('${file.replace('.hx', '')}.$func() [line $line]');
						case _:
							stackLabelArr.push('${file.replace('.hx', '')} [line $line]');
					}
				case LocalFunction(v):
					stackLabelArr.push('Local Function ${v}');
				case Method(cl, m):
					stackLabelArr.push('${cl} - ${m}');
			}
		}
		stackLabel = stackLabelArr.join('\r\n');

		// Mostrar error en la consola/terminal
		trace('\n\n$m\n\n$stackLabel\n======================\nFor help, visit: $HELP_LINK');
		
		#if sys
		saveErrorMessage('$m\n$stackLabel');
		#end

		// Mensaje con link de ayuda
		var errorMsg = '$m\n\n$stackLabel\n\n========================\nNeed help? Visit:\n$HELP_LINK';
		CoolUtil.showPopUp(errorMsg, "Error!");
		#if DISCORD_ALLOWED DiscordClient.shutdown(); #end
		lime.system.System.exit(1);
	}

	#if (cpp || hl)
	private static function onError(message:Dynamic):Void
	{
		final log:Array<String> = [];

		if (message != null && message.length > 0)
		{
			// Add funny message for null errors
			var funnyMessage = funnyNullMessage(Std.string(message));
			log.push(funnyMessage);
		}

		log.push(haxe.CallStack.toString(haxe.CallStack.exceptionStack(true)));
		
		var errorLog = log.join('\n');
		
		// Mostrar error en la consola/terminal
		trace('=== CRITICAL ERROR ===');
		trace(errorLog);
		trace('======================');
		trace('For help, visit: $HELP_LINK');

		#if sys
		saveErrorMessage(errorLog);
		#end

		// Mensaje con link de ayuda
		var errorMsg = '$errorLog\n\n========================\nNeed help? Visit:\n$HELP_LINK';
		CoolUtil.showPopUp(errorMsg, "Critical Error!");
		#if DISCORD_ALLOWED DiscordClient.shutdown(); #end
		lime.system.System.exit(1);
	}
	#end

	#if sys
	private static function saveErrorMessage(message:String):Void
	{
		final folder:String = #if android StorageUtil.getLogsDirectory() #else Sys.getCwd() + 'logs/' #end;

		try
		{
			if (!FileSystem.exists(folder))
				FileSystem.createDirectory(folder);

			var fullLog = message + '\n\n========================\nFor help, visit: $HELP_LINK\n========================';
			File.saveContent(folder + Date.now().toString().replace(' ', '-').replace(':', "'") + '.txt', fullLog);
		}
		catch (e:haxe.Exception)
			trace('Couldn\'t save error message. (${e.message})');
	}
	#end
}
