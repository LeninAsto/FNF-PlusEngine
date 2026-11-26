package backend;

#if DISCORD_ALLOWED
import Sys.sleep;
import sys.thread.Thread;
import lime.app.Application;
import hxdiscord_rpc.Discord;
import hxdiscord_rpc.Types;
import flixel.util.FlxStringUtil;

class DiscordClient
{
	public static var isInitialized:Bool = false;
	private inline static final _defaultID:String = "1449954550134870079";
	public static var clientID(default, set):String = _defaultID;
	private static var presence:DiscordPresence = new DiscordPresence();
	private static var presenceState:flixel.FlxState = null;
	// hides this field from scripts and reflection in general
	@:unreflective private static var __thread:Thread;

	public static function check()
	{
		var mode = ClientPrefs.data.discordRPCMode;
		ClientPrefs.data.discordRPC = mode != 'Disabled'; // Legacy scripts and saves.
		if (mode == 'Disabled')
		{
			presenceState = null;
			if (isInitialized) { Discord.ClearPresence(); shutdown(); }
			return;
		}
		if (mode == 'Game Only' && clientID != _defaultID) clientID = _defaultID;
		if (!isInitialized) initialize();
		if (mode == 'Game Only')
			updatePresence();
		else
			ensureStatePresence(flixel.FlxG.state, true);
	}

	public static function prepare()
	{
		if (!isInitialized && ClientPrefs.data.discordRPCMode != 'Disabled')
			initialize();

		Application.current.window.onClose.add(function()
		{
			if (isInitialized)
				shutdown();
		});
	}

	public dynamic static function shutdown()
	{
		isInitialized = false;
		Discord.Shutdown();
		trace("Discord Client shutdown");
	}

	private static function onReady(request:cpp.RawConstPointer<DiscordUser>):Void
	{
		final user = cast(request[0].username, String);
		final discriminator = cast(request[0].discriminator, String);

		var message = '(Discord) Connected to User ';
		if (discriminator != '0') // Old discriminators
			message += '($user#$discriminator)';
		else // New Discord IDs/Discriminator system
			message += '($user)';

		trace(message);
		updatePresence();
	}

	private static function onError(errorCode:Int, message:cpp.ConstCharStar):Void
	{
		trace('Discord: Error ($errorCode: ${cast (message, String)})');
	}

	private static function onDisconnected(errorCode:Int, message:cpp.ConstCharStar):Void
	{
		trace('Discord: Disconnected ($errorCode: ${cast (message, String)})');
	}

	public static function initialize()
	{
		if (isInitialized || ClientPrefs.data.discordRPCMode == 'Disabled')
			return;
		var discordHandlers:DiscordEventHandlers = #if (hxdiscord_rpc > "1.2.4") new DiscordEventHandlers(); #else DiscordEventHandlers.create(); #end
		discordHandlers.ready = cpp.Function.fromStaticFunction(onReady);
		discordHandlers.disconnected = cpp.Function.fromStaticFunction(onDisconnected);
		discordHandlers.errored = cpp.Function.fromStaticFunction(onError);
		Discord.Initialize(clientID, cpp.RawPointer.addressOf(discordHandlers), #if (hxdiscord_rpc > "1.2.4") false #else 1 #end, null);

		if (!isInitialized)
			trace("Discord Client initialized");

		if (__thread == null)
		{
			__thread = Thread.create(() ->
			{
				while (true)
				{
					if (isInitialized)
					{
						#if DISCORD_DISABLE_IO_THREAD
						Discord.UpdateConnection();
						#end
						Discord.RunCallbacks();
					}

					// Wait 1 second until the next loop...
					Sys.sleep(1.0);
				}
			});
		}
		isInitialized = true;
	}

	public static function changePresence(details:String = 'In the Menus', ?state:String, ?smallImageKey:String, ?hasStartTimestamp:Bool, ?endTimestamp:Float,
			largeImageKey:String = 'icon')
	{
		if (ClientPrefs.data.discordRPCMode != 'Normal') return;
		presenceState = flixel.FlxG.state;
		var startTimestamp:Float = 0;
		if (hasStartTimestamp)
			startTimestamp = Date.now().getTime();
		if (endTimestamp > 0)
			endTimestamp = startTimestamp + endTimestamp;

		presence.state = state;
		presence.details = details;
		presence.smallImageKey = smallImageKey;
		presence.largeImageKey = largeImageKey;
		presence.largeImageText = "Plus Engine v" + states.MainMenuState.plusEngineVersion;
		// Obtained times are in milliseconds so they are divided so Discord can use it
		presence.startTimestamp = Std.int(startTimestamp / 1000);
		presence.endTimestamp = Std.int(endTimestamp / 1000);
		updatePresence();

		// trace('Discord RPC Updated. Arguments: $details, $state, $smallImageKey, $hasStartTimestamp, $endTimestamp, $largeImageKey');
	}

	public static function updatePresence()
	{
		if (!isInitialized || ClientPrefs.data.discordRPCMode == 'Disabled')
			return;
		if (ClientPrefs.data.discordRPCMode == 'Game Only')
		{
			presence.details = null;
			presence.state = null;
			presence.smallImageKey = null;
			presence.largeImageKey = 'icon';
			presence.largeImageText = null;
			presence.startTimestamp = 0;
			presence.endTimestamp = 0;
		}
		presence.syncStrings();
		Discord.UpdatePresence(cpp.RawConstPointer.addressOf(presence.__presence));
	}

	/** Supply a state name only when that state did not publish its own richer presence. */
	public static function ensureStatePresence(state:flixel.FlxState, force:Bool = false):Void
	{
		if (ClientPrefs.data.discordRPCMode != 'Normal' || state == null || (!force && presenceState == state)) return;
		var name = Type.getClassName(Type.getClass(state));
		if (name == null) return;
		name = name.substr(name.lastIndexOf('.') + 1);
		if (StringTools.endsWith(name, 'Plus')) name = name.substr(0, name.length - 4);
		if (StringTools.endsWith(name, 'State')) name = name.substr(0, name.length - 5);
		var words = ~/([a-z0-9])([A-Z])/g.replace(name, '$1 $2');
		var key = StringTools.replace(words.toLowerCase(), ' ', '_');
		changePresence(Language.getPhrase('states.discord.$key', words), null);
		presenceState = state;
	}

	inline public static function resetClientID()
	{
		clientID = _defaultID;
	}

	private static function set_clientID(newID:String)
	{
		if (ClientPrefs.data.discordRPCMode != 'Normal' && newID != _defaultID) return clientID;
		var change:Bool = (clientID != newID);
		clientID = newID;

		if (change && isInitialized)
		{
			shutdown();
			initialize();
			updatePresence();
		}
		return newID;
	}

	#if (MODS_ALLOWED && DISCORD_ALLOWED)
	public static function loadModRPC()
	{
		if (ClientPrefs.data.discordRPCMode != 'Normal') return;
		var pack:Dynamic = Mods.getPack();
		if (pack != null && pack.discordRPC != null && pack.discordRPC != clientID)
		{
			clientID = pack.discordRPC;
			// trace('Changing clientID! $clientID, $_defaultID');
		}
	}
	#end

	#if LUA_ALLOWED
	public static function addLuaCallbacks(lua:State)
	{
		Lua_helper.add_callback(lua, "changeDiscordPresence", changePresence);
		Lua_helper.add_callback(lua, "changeDiscordClientID", function(?newID:String)
		{
			if (newID == null)
				newID = _defaultID;
			clientID = newID;
		});
	}
	#end
}

@:allow(backend.DiscordClient)
private final class DiscordPresence
{
	public var state(get, set):String;
	public var details(get, set):String;
	public var smallImageKey(get, set):String;
	public var largeImageKey(get, set):String;
	public var largeImageText(get, set):String;
	public var startTimestamp(get, set):Int;
	public var endTimestamp(get, set):Int;

	@:noCompletion private var __presence:DiscordRichPresence;
	private var stateValue:String;
	private var detailsValue:String;
	private var smallImageKeyValue:String;
	private var largeImageKeyValue:String;
	private var largeImageTextValue:String;

	private function syncStrings():Void
	{
		__presence.state = stateValue;
		__presence.details = detailsValue;
		__presence.smallImageKey = smallImageKeyValue;
		__presence.largeImageKey = largeImageKeyValue;
		__presence.largeImageText = largeImageTextValue;
	}

	function new()
	{
		__presence = #if (hxdiscord_rpc > "1.2.4") new DiscordRichPresence(); #else DiscordRichPresence.create(); #end
	}

	public function toString():String
	{
		return FlxStringUtil.getDebugString([
			LabelValuePair.weak("state", state),
			LabelValuePair.weak("details", details),
			LabelValuePair.weak("smallImageKey", smallImageKey),
			LabelValuePair.weak("largeImageKey", largeImageKey),
			LabelValuePair.weak("largeImageText", largeImageText),
			LabelValuePair.weak("startTimestamp", startTimestamp),
			LabelValuePair.weak("endTimestamp", endTimestamp)
		]);
	}

	@:noCompletion inline function get_state():String
	{
		return stateValue;
	}

	@:noCompletion inline function set_state(value:String):String
	{
		return stateValue = value;
	}

	@:noCompletion inline function get_details():String
	{
		return detailsValue;
	}

	@:noCompletion inline function set_details(value:String):String
	{
		return detailsValue = value;
	}

	@:noCompletion inline function get_smallImageKey():String
	{
		return smallImageKeyValue;
	}

	@:noCompletion inline function set_smallImageKey(value:String):String
	{
		return smallImageKeyValue = value;
	}

	@:noCompletion inline function get_largeImageKey():String
	{
		return largeImageKeyValue;
	}

	@:noCompletion inline function set_largeImageKey(value:String):String
	{
		return largeImageKeyValue = value;
	}

	@:noCompletion inline function get_largeImageText():String
	{
		return largeImageTextValue;
	}

	@:noCompletion inline function set_largeImageText(value:String):String
	{
		return largeImageTextValue = value;
	}

	@:noCompletion inline function get_startTimestamp():Int
	{
		return __presence.startTimestamp;
	}

	@:noCompletion inline function set_startTimestamp(value:Int):Int
	{
		return __presence.startTimestamp = value;
	}

	@:noCompletion inline function get_endTimestamp():Int
	{
		return __presence.endTimestamp;
	}

	@:noCompletion inline function set_endTimestamp(value:Int):Int
	{
		return __presence.endTimestamp = value;
	}
}
#end
