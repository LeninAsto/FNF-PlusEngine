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
	// Help link/repository to display in the event of a crash
	public static final HELP_LINK:String = "https://github.com/Psych-Plus-Team/FNF-PlusEngine";

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
		if (originalMessage == null)
			return "Null error message (ironic, isn't it?)";

		var lowerMsg = originalMessage.toLowerCase();
		var isNullError = lowerMsg.contains("null")
			|| lowerMsg.contains("object reference")
			|| lowerMsg.contains("null pointer")
			|| lowerMsg.contains("null object");

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

		var errorMsg = formatCrashText("Hardcoded Error", m, stackLabel, [
			"This crashed outside hxscript, so it is probably engine/source code or a compiled library path.",
			"Check the first source line in the stack before the engine loop; that is usually the useful culprit.",
			"If this only happens after editing scripts/classes, rebuild and make sure the exported assets are not stale."
		]);

		// Display the error in the console/terminal
		trace('\n\n$errorMsg');

		#if sys
		saveErrorMessage(errorMsg);
		#end

		#if android
		showAndroidCrash(errorMsg, "Error!");
		#else
		CoolUtil.showPopUp(errorMsg, "Error!");
		#end
		#if DISCORD_ALLOWED DiscordClient.shutdown(); #end
		lime.system.System.exit(1);
	}

	#if (cpp || hl)
	private static function onError(message:Dynamic):Void
	{
		var crashMessage:String = "Unknown critical error";
		if (message != null && message.length > 0)
		{
			// Add funny message for null errors
			crashMessage = funnyNullMessage(Std.string(message));
		}

		var errorLog = formatCrashText("Critical Hardcoded Error", crashMessage, haxe.CallStack.toString(haxe.CallStack.exceptionStack(true)), [
			"This is a native/critical crash path, so the app could not recover cleanly.",
			"If this appeared during build testing, close every running PlusEngine.exe before rebuilding.",
			"If mods are enabled, retry with scripts disabled to separate engine crashes from mod-side crashes."
		]);

		// Display the error in the console/terminal
		trace('=== CRITICAL ERROR ===');
		trace(errorLog);
		trace('======================');
		trace('For help, visit: $HELP_LINK');

		#if sys
		saveErrorMessage(errorLog);
		#end

		#if android
		showAndroidCrash(errorLog, "Critical Error!");
		#else
		CoolUtil.showPopUp(errorLog, "Critical Error!");
		#end
		#if DISCORD_ALLOWED DiscordClient.shutdown(); #end
		lime.system.System.exit(1);
	}
	#end

	private static function formatCrashText(kind:String, message:String, stack:String, tips:Array<String>):String
	{
		var out:Array<String> = [];
		out.push('ERROR: $kind');
		out.push('');
		out.push('Message:');
		out.push(message == null || message.length < 1 ? 'Unknown error' : message);

		if (stack != null && stack.trim().length > 0)
		{
			out.push('');
			out.push('Trace:');
			out.push(stack);
		}

		if (tips != null && tips.length > 0)
		{
			out.push('');
			out.push('Tips:');
			for (tip in tips)
				out.push('- ' + tip);
		}

		out.push('');
		out.push('Need help? Visit:');
		out.push(HELP_LINK);
		return out.join('\n');
	}

	#if android
	private static function showAndroidCrash(message:String, title:String):Void
	{
		try
		{
			lime.system.JNI.createStaticMethod('com/leninasto/plusengine/EngineAndroidBridge', 'showHaxeCrash',
				'(Ljava/lang/String;Ljava/lang/String;)V', false, true)(title, message);
		}
		catch (e:Dynamic)
		{
			trace('Android crash activity dispatch failed: $e');
			CoolUtil.showPopUp(message, title);
		}
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

