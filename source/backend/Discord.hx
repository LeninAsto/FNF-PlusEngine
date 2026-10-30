package backend;

#if DISCORD_ALLOWED
import haxe.Int64;
import hxdiscordsocial.Discord as SocialDiscord;
import hxdiscordsocial.DiscordEvent;
import hxdiscordsocial.DiscordResult;
import hxdiscordsocial.DiscordOperation;
import hxdiscordsocial.ActivityPlatform;
import hxdiscordsocial.Presence;
import hxdiscordsocial.PresenceBuilder;
import hxdiscordsocial.PresenceButton;
import lime.app.Application;

/** Plus Engine adapter for the backend-independent hxDiscordSocial API. */
class DiscordClient
{
	public static var isInitialized(default, null):Bool = false;
	private inline static final _defaultID:String = "1449954550134870079";
	private inline static final _projectURL:String = "https://github.com/LeninAsto/FNF-PlusEngine";
	private inline static final _credentialPrefix:String = "hxDiscordSocial/PlusEngine/";
	public static var clientID(default, set):String = _defaultID;

	private static var presence:Presence = new Presence({});
	private static var listenerRegistered:Bool = false;
	private static var pollingRegistered:Bool = false;
	private static var attemptedTokenRestore:Bool = false;

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
		attemptedTokenRestore = false;
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

		return submitPresence(buildPresence(details, state, smallImageKey, largeImageKey, start, end));
	}

	/** Sets Presence with absolute Unix timestamps in seconds for scripts and new integrations. */
	public static function setPresence(details:String = "In the Menus", ?state:String, ?smallImageKey:String, ?startTimestamp:Float, ?endTimestamp:Float,
			largeImageKey:String = "icon"):Bool
	{
		return submitPresence(buildPresence(details, state, smallImageKey, largeImageKey, unixTimestamp(startTimestamp), unixTimestamp(endTimestamp)));
	}

	/** Opens Discord's OAuth consent using PKCE. Requires Public Client in Developer Portal. */
	public static function authorize(?scopes:String):Bool {
		if (!isInitialized && !initialize()) return false;
		return accepted(SocialDiscord.authorize(scopes));
	}
	public static function restoreToken(accessToken:String):Bool return accepted(SocialDiscord.restoreToken(accessToken));
	public static function refreshToken(refreshToken:String):Bool return accepted(SocialDiscord.refreshToken(refreshToken));
	public static function logout():Bool {
		clearStoredCredentials();
		return isInitialized && accepted(SocialDiscord.logout());
	}
	public static function getAuthState():String return Std.string(SocialDiscord.authState);
	public static function getDiscordUserId():String return SocialDiscord.currentUser == null ? "" : SocialDiscord.currentUser.id;
	public static function getDiscordDisplayName():String return SocialDiscord.currentUser == null ? "" : SocialDiscord.currentUser.displayName;

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
			attemptedTokenRestore = false;
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
		Lua_helper.add_callback(lua, "discordAuthorize", authorize);
		Lua_helper.add_callback(lua, "discordRestoreToken", restoreToken);
		Lua_helper.add_callback(lua, "discordRefreshToken", refreshToken);
		Lua_helper.add_callback(lua, "discordLogout", logout);
		Lua_helper.add_callback(lua, "discordGetAuthState", getAuthState);
		Lua_helper.add_callback(lua, "discordGetUserId", getDiscordUserId);
		Lua_helper.add_callback(lua, "discordGetDisplayName", getDiscordDisplayName);
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

	private static function buildPresence(details:String, state:Null<String>, smallImageKey:Null<String>, largeImageKey:String,
			start:Null<Int64>, end:Null<Int64>):Presence
	{
		var showDetails = ClientPrefs.data.discordRPCDetails;
		var builder = new PresenceBuilder()
			.identity("Friday Night Funkin': Plus Engine")
			.text(details, showDetails ? state : null)
			.largeAsset(largeImageKey, "Plus Engine v" + states.MainMenuState.plusEngineVersion, _projectURL)
			.buttons([new PresenceButton("View Plus Engine", _projectURL)])
			.platforms(ActivityPlatform.Desktop | ActivityPlatform.Android);
		if (showDetails)
		{
			builder.smallAsset(smallImageKey, state);
			builder.timestamps(start, end);
		}
		return builder.build();
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
				restoreStoredSession();
			case PresenceUpdated(value):
				trace('Discord Rich Presence updated: $value');
			case PresenceCleared:
			case AuthorizationStarted:
				trace("Discord authorization opened");
			case Authenticated(token):
				var accessSaved = DiscordCredentialStorage.write(credentialKey("access"), token.accessToken);
				var refreshSaved = DiscordCredentialStorage.write(credentialKey("refresh"), token.refreshToken);
				trace(accessSaved && refreshSaved ? "Discord authorization saved securely" : "Discord authorization succeeded, but secure token storage failed");
			case AuthenticationReady(user):
				trace('Discord signed in as ${user.displayName} (${user.id})');
			case TokenRefreshRequired:
				var refresh = DiscordCredentialStorage.read(credentialKey("refresh"));
				if (refresh != null) refreshToken(refresh); else trace("Discord token needs refreshing, but no refresh token is stored");
			case LoggedOut:
				trace("Discord account disconnected");
			case Disconnected(error):
				trace('Discord disconnected: $error');
			case Error(operation, error):
				trace('Discord $operation error: $error');
				if (!error.retryable && (operation == DiscordOperation.RestoreToken || operation == DiscordOperation.RefreshToken))
					clearStoredCredentials();
			case Shutdown:
		}
	}

	private static function restoreStoredSession():Void
	{
		if (attemptedTokenRestore || !DiscordCredentialStorage.available()) return;
		attemptedTokenRestore = true;
		var access = DiscordCredentialStorage.read(credentialKey("access"));
		if (access != null && !restoreToken(access)) trace("Stored Discord session could not be restored");
	}

	private static function clearStoredCredentials():Void
	{
		DiscordCredentialStorage.remove(credentialKey("access"));
		DiscordCredentialStorage.remove(credentialKey("refresh"));
	}

	private static inline function credentialKey(kind:String):String
		return _credentialPrefix + clientID + "/" + kind;

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
