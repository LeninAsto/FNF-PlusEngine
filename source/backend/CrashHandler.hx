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
	private static var initialized:Bool = false;
	private static var handlingCrash:Bool = false;
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

	static inline function phrase(key:String, fallback:String, ?values:Array<Dynamic>):String
	{
		try
		{
			return Language.getPhrase('errors.crash_handler.$key', fallback, values);
		}
		catch (_:Dynamic)
		{
			return fallback;
		}
	}

	/**
	 * Adds a funny prefix to null-related error messages
	 */
	static function funnyNullMessage(originalMessage:String):String
	{
		if (originalMessage == null)
			return phrase('null_error_message', "Null error message (ironic, isn't it?)");

		var lowerMsg = originalMessage.toLowerCase();
		var isNullError = lowerMsg.contains("null")
			|| lowerMsg.contains("object reference")
			|| lowerMsg.contains("null pointer")
			|| lowerMsg.contains("null object");

		if (isNullError)
		{
			var index:Int = Std.random(NULL_ERROR_MESSAGES.length);
			var funnyMsg = phrase('null_messages.$index', NULL_ERROR_MESSAGES[index]);
			return phrase('original_error', '{1}\n\nOriginal error: {2}', [funnyMsg, originalMessage]);
		}

		return originalMessage;
	}

	public static function init():Void
	{
		if (initialized)
			return;
		initialized = true;

		if (openfl.Lib.current != null && openfl.Lib.current.loaderInfo != null)
			openfl.Lib.current.loaderInfo.uncaughtErrorEvents.addEventListener(UncaughtErrorEvent.UNCAUGHT_ERROR, onUncaughtError);
		#if cpp
		untyped __global__.__hxcpp_set_critical_error_handler(onError);
		#elseif hl
		hl.Api.setErrorHandler(onError);
		#end
	}

	private static function onUncaughtError(e:UncaughtErrorEvent):Void
	{
		if (!beginCrashHandling())
			return;

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
					stackLabelArr.push(phrase('stack.non_haxe_function', 'Non-Haxe (C) Function'));
				case Module(c):
					stackLabelArr.push(phrase('stack.module', 'Module {1}', [c]));
				case FilePos(parent, file, line, col):
					switch (parent)
					{
						case Method(cla, func):
							stackLabelArr.push(phrase('stack.source_line', '{1}.{2}() [line {3}]', [file.replace('.hx', ''), func, line]));
						case _:
							stackLabelArr.push(phrase('stack.file_line', '{1} [line {2}]', [file.replace('.hx', ''), line]));
					}
				case LocalFunction(v):
					stackLabelArr.push(phrase('stack.local_function', 'Local Function {1}', [v]));
				case Method(cl, m):
					stackLabelArr.push(phrase('stack.method', '{1} - {2}', [cl, m]));
			}
		}
		stackLabel = stackLabelArr.join('\r\n');

		var errorMsg = formatCrashText(phrase('kinds.hardcoded', 'Hardcoded Error'), m, stackLabel, [
			phrase('tips.hardcoded_origin', 'This crashed outside hxscript, so it is probably engine/source code or a compiled library path.'),
			phrase('tips.first_source_line', 'Check the first source line in the stack before the engine loop; that is usually the useful culprit.'),
			phrase('tips.rebuild_assets', 'If this only happens after editing scripts/classes, rebuild and make sure the exported assets are not stale.')
		]);

		// Display the error in the console/terminal
		trace('\n\n$errorMsg');

		#if sys
		saveErrorMessage(errorMsg);
		#end

		#if DISCORD_ALLOWED DiscordClient.shutdown(); #end
		showCrashAndExit(errorMsg, phrase('titles.error', 'Error!'));
	}

	#if (cpp || hl)
	private static function onError(message:Dynamic):Void
	{
		if (!beginCrashHandling())
			return;

		var crashMessage:String = phrase('unknown_critical_error', 'Unknown critical error');
		if (message != null && Std.string(message).length > 0)
		{
			// Add funny message for null errors
			crashMessage = funnyNullMessage(Std.string(message));
		}

		var errorLog = formatCrashText(phrase('kinds.critical_hardcoded', 'Critical Hardcoded Error'), crashMessage,
			haxe.CallStack.toString(haxe.CallStack.exceptionStack(true)), [
			phrase('tips.native_crash', 'This is a native/critical crash path, so the app could not recover cleanly.'),
			phrase('tips.close_running_build', 'If this appeared during build testing, close every running PlusEngine.exe before rebuilding.'),
			phrase('tips.disable_mod_scripts', 'If mods are enabled, retry with scripts disabled to separate engine crashes from mod-side crashes.')
		]);

		// Display the error in the console/terminal
		trace('=== CRITICAL ERROR ===');
		trace(errorLog);
		trace('======================');
		trace(phrase('help_inline', 'For help, visit: {1}', [HELP_LINK]));

		#if sys
		saveErrorMessage(errorLog);
		#end

		#if DISCORD_ALLOWED DiscordClient.shutdown(); #end
		showCrashAndExit(errorLog, phrase('titles.critical_error', 'Critical Error!'));
	}
	#end

	private static function beginCrashHandling():Bool
	{
		if (handlingCrash)
		{
			trace(phrase('recursive_handler', 'Crash handler was invoked again while already handling an error.'));
			return false;
		}
		handlingCrash = true;
		return true;
	}

	private static function showCrashAndExit(message:String, title:String):Void
	{
		#if android
		// The Android bridge starts a recovery Activity in a separate process and
		// terminates this broken game process after that Activity has had time to open.
		if (showAndroidCrash(message, title))
			return;
		#end

		CoolUtil.showPopUp(message, title);
		lime.system.System.exit(1);
	}

	private static function formatCrashText(kind:String, message:String, stack:String, tips:Array<String>):String
	{
		var out:Array<String> = [];
		out.push(phrase('format.error_kind', 'ERROR: {1}', [kind]));
		out.push('');
		out.push(phrase('format.message', 'Message:'));
		out.push(message == null || message.length < 1 ? phrase('unknown_error', 'Unknown error') : message);

		if (stack != null && stack.trim().length > 0)
		{
			out.push('');
			out.push(phrase('format.trace', 'Trace:'));
			out.push(stack);
		}

		if (tips != null && tips.length > 0)
		{
			out.push('');
			out.push(phrase('format.tips', 'Tips:'));
			for (tip in tips)
				out.push('- ' + tip);
		}

		out.push('');
		out.push(phrase('format.need_help', 'Need help? Visit:'));
		out.push(HELP_LINK);
		return out.join('\n');
	}

	#if android
	private static function showAndroidCrash(message:String, title:String):Bool
	{
		try
		{
			return lime.system.JNI.createStaticMethod('com/leninasto/plusengine/EngineAndroidBridge', 'showHaxeCrash',
				'(Ljava/lang/String;Ljava/lang/String;)Z', false, true)(title, message);
		}
		catch (e:Dynamic)
		{
			trace(phrase('android_dispatch_failed', 'Android crash activity dispatch failed: {1}', [e]));
		}
		return false;
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

			var fullLog = message + '\n\n========================\n' + phrase('help_inline', 'For help, visit: {1}', [HELP_LINK]) + '\n========================';
			File.saveContent(folder + Date.now().toString().replace(' ', '-').replace(':', "'") + '.txt', fullLog);
		}
		catch (e:haxe.Exception)
			trace(phrase('save_failed', 'Couldn\'t save error message. ({1})', [e.message]));
	}
	#end
}

