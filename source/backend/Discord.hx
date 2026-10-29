package backend;

#if DISCORD_ALLOWED
import haxe.Int64;
import hxdiscordsocial.Discord as SocialDiscord;
import hxdiscordsocial.DiscordEvent;
import hxdiscordsocial.DiscordResult;
import hxdiscordsocial.Presence;
import lime.app.Application;

/** Plus Engine adapter for the backend-independent hxDiscordSocial API. */
class DiscordClient
{
	public static var isInitialized(default, null):Bool = false;
	private inline static final _defaultID:String = "1449954550134870079";
	public static var clientID(default, set):String = _defaultID;

	private static var presence:Presence = new Presence({});
	private static var listenerRegistered:Bool = false;
	private static var pollingRegistered:Bool = false;

	public static function check():Void
	{
		if (ClientPrefs.data.discordRPC)
			initialize();
		else if (isInitialized)
			shutdown();
	}

	public static function prepare():Void
	{
		registerEvents();
		if (!pollingRegistered && Application.current != null)
		{
			Application.current.onUpdate.add(poll);
			pollingRegistered = true;
		}

		if (!isInitialized && ClientPrefs.data.discordRPC)
			initialize();

		if (Application.current != null && Application.current.window != null)
		{
			Application.current.window.onClose.add(function()
			{
				if (isInitialized)
					shutdown();
			});
		}
	}

	public static function initialize(?applicationId:String):Bool
	{
		registerEvents();
		if (applicationId != null && applicationId.length > 0)
			clientID = applicationId;
		if (isInitialized)
			return true;

		var result = SocialDiscord.initialize(clientID);
		if (!accepted(result))
		{
			traceRejected("initialize", result);
			return false;
		}

		isInitialized = true;
		changePresence();
		trace('Discord Social SDK initialization requested for $clientID');
		return true;
	}

	public static function shutdown():Void
	{
		if (!isInitialized)
			return;

		SocialDiscord.clearPresence();
		SocialDiscord.shutdown();
		SocialDiscord.poll();
		isInitialized = false;
		trace("Discord Client shutdown");
	}

	public static function changePresence(details:String = "In the Menus", ?state:String, ?smallImageKey:String, ?hasStartTimestamp:Bool, ?endTimestamp:Float,
			largeImageKey:String = "icon"):Bool
	{
		var nowSeconds = Date.now().getTime() / 1000;
		var start:Null<Int64> = hasStartTimestamp == true ? Int64.fromFloat(nowSeconds) : null;
		var end:Null<Int64> = endTimestamp != null && endTimestamp > 0 ? Int64.fromFloat(nowSeconds + endTimestamp / 1000) : null;

		return submitPresence(new Presence({
			name: "Friday Night Funkin': Plus Engine",
			details: details,
			state: state,
			smallImage: smallImageKey,
			largeImage: largeImageKey,
			largeText: "Plus Engine v" + states.MainMenuState.plusEngineVersion,
			startTimestamp: start,
			endTimestamp: end
		}));
	}

	/** Sets Presence with absolute Unix timestamps in seconds for scripts and new integrations. */
	public static function setPresence(details:String = "In the Menus", ?state:String, ?smallImageKey:String, ?startTimestamp:Float, ?endTimestamp:Float,
			largeImageKey:String = "icon"):Bool
	{
		return submitPresence(new Presence({
			name: "Friday Night Funkin': Plus Engine",
			details: details,
			state: state,
			smallImage: smallImageKey,
			largeImage: largeImageKey,
			largeText: "Plus Engine v" + states.MainMenuState.plusEngineVersion,
			startTimestamp: unixTimestamp(startTimestamp),
			endTimestamp: unixTimestamp(endTimestamp)
		}));
	}

	public static function updatePresence():Bool
	{
		return submitPresence(presence);
	}

	public static function clearPresence():Bool
	{
		if (!isInitialized)
			return false;
		var result = SocialDiscord.clearPresence();
		if (!accepted(result))
			traceRejected("clearPresence", result);
		return accepted(result);
	}

	public static inline function resetClientID():Void
	{
		clientID = _defaultID;
	}

	private static function set_clientID(newID:String):String
	{
		if (newID == null || newID.length == 0)
			newID = _defaultID;
		var changed = clientID != newID;
		clientID = newID;

		if (changed && isInitialized)
		{
			var result = SocialDiscord.changeApplication(clientID);
			if (!accepted(result))
				traceRejected("changeApplication", result);
		}
		return newID;
	}

	#if MODS_ALLOWED
	public static function loadModRPC():Void
	{
		var pack:Dynamic = Mods.getPack();
		var applicationId:Dynamic = pack == null ? null : Reflect.field(pack, "discordApplicationId");
		if (applicationId != null && Std.isOfType(applicationId, String) && applicationId != clientID)
			clientID = applicationId;
	}
	#end

	#if LUA_ALLOWED
	public static function addLuaCallbacks(lua:State):Void
	{
		Lua_helper.add_callback(lua, "discordInitialize", function(?applicationId:String) return initialize(applicationId));
		Lua_helper.add_callback(lua, "discordSetPresence", setPresence);
		Lua_helper.add_callback(lua, "discordClearPresence", clearPresence);
		Lua_helper.add_callback(lua, "discordShutdown", function()
		{
			shutdown();
			return true;
		});
	}
	#end

	private static function submitPresence(value:Presence):Bool
	{
		if (!isInitialized && !initialize())
			return false;
		presence = value.copy();
		var result = SocialDiscord.setPresence(presence);
		if (!accepted(result))
			traceRejected("setPresence", result);
		return accepted(result);
	}

	private static function registerEvents():Void
	{
		if (listenerRegistered)
			return;
		SocialDiscord.addListener(onDiscordEvent);
		listenerRegistered = true;
	}

	private static function poll(_deltaTime:Int):Void
	{
		if (isInitialized)
			SocialDiscord.poll();
	}

	private static function onDiscordEvent(event:DiscordEvent):Void
	{
		switch (event)
		{
			case Ready(id):
				trace('Discord Social SDK ready ($id)');
			case PresenceUpdated(_):
			case PresenceCleared:
			case Disconnected(error):
				trace('Discord disconnected: $error');
			case Error(operation, error):
				trace('Discord $operation error: $error');
			case Shutdown:
		}
	}

	private static function unixTimestamp(value:Null<Float>):Null<Int64>
	{
		return value != null && value > 0 ? Int64.fromFloat(value) : null;
	}

	private static function accepted(result:DiscordResult):Bool
	{
		return switch (result)
		{
			case Accepted: true;
			case Rejected(_): false;
		};
	}

	private static function traceRejected(operation:String, result:DiscordResult):Void
	{
		switch (result)
		{
			case Accepted:
			case Rejected(error):
				trace('Discord $operation rejected: $error');
		}
	}
}
#end
