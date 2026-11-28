package deprecations;

import backend.ClientPrefs;
import flixel.util.FlxColor;
import states.PlayState;

class HaxeLibDeprecations
{
	static final warned:Map<String, Bool> = new Map();

	public static inline function isTrackedMember(field:String):Bool
		return switch (field) {
			case 'screenX' | 'screenY' | 'deltaScreenX' | 'deltaScreenY' | 'getPositionInCameraView' | 'getScreenPosition'
				| 'finishCallback' | 'callback' | 'loadEmbedded' | 'addPoint' | 'subtractPoint' | 'copyFromFlash'
				| 'transformWorldToPixels' | 'transformWorldToPixelsSimple' | 'transformScreenToPixels' | 'shadowOffset'
				| 'load' | 'volumeHandler' | 'fastSin' | 'fastCos' | 'colors' | 'colorsPosition' | 'callbackFunction': true;
			default: false;
		};

	public static function checkMember(object:Dynamic, field:String, ?scriptOwner:String):Void
	{
		if (object == null || field == null || !isTrackedMember(field)) return;
		var replacement:String = null;
		var owner:String = null;
		if (object == flixel.math.FlxMath)
		{
			owner = 'flixel.math.FlxMath';
			replacement = switch (field) {
				case 'fastSin': 'Math.sin';
				case 'fastCos': 'Math.cos';
				default: null;
			};
		}
		else if (Std.isOfType(object, flixel.input.FlxPointer))
		{
			owner = 'flixel.input.FlxPointer';
			replacement = switch (field) {
				case 'screenX': 'viewX';
				case 'screenY': 'viewY';
				case 'deltaScreenX': 'deltaViewX';
				case 'deltaScreenY': 'deltaViewY';
				case 'getPositionInCameraView': 'getViewPosition';
				case 'getScreenPosition': 'getViewPosition';
				default: null;
			};
		}
		else if (Std.isOfType(object, flixel.animation.FlxAnimationController))
		{
			owner = 'flixel.animation.FlxAnimationController';
			replacement = switch (field) {
				case 'finishCallback': 'onFinish.add';
				case 'callback': 'onFrameChange.add';
				default: null;
			};
		}
		else if (Std.isOfType(object, flixel.sound.FlxSound) && field == 'loadEmbedded')
		{
			owner = 'flixel.sound.FlxSound';
			replacement = 'load';
		}
		else if (Std.isOfType(object, flixel.system.frontEnds.SoundFrontEnd))
		{
			owner = 'flixel.system.frontEnds.SoundFrontEnd';
			replacement = switch (field) {
				case 'load': 'create(assetId).setup(...) or createFromURL()';
				case 'volumeHandler': 'onVolumeChange';
				default: null;
			};
		}
		else if (Std.isOfType(object, flixel.system.debug.log.FlxLogStyle) && field == 'callbackFunction')
		{
			owner = 'flixel.system.debug.log.FlxLogStyle';
			replacement = 'onLog.add(callback)';
		}
		else if (Std.isOfType(object, flixel.graphics.tile.FlxDrawTrianglesItem))
		{
			owner = 'flixel.graphics.tile.FlxDrawTrianglesItem';
			replacement = switch (field) {
				case 'colors': 'colorMultipliers and colorOffsets';
				case 'colorsPosition': 'the color transform buffers';
				default: null;
			};
		}
		else if (Std.isOfType(object, flixel.math.FlxPoint.FlxBasePoint))
		{
			owner = 'flixel.math.FlxPoint';
			replacement = switch (field) {
				case 'addPoint': 'add(point)';
				case 'subtractPoint': 'subtract(point)';
				case 'copyFromFlash': 'copyFrom';
				default: null;
			};
		}
		else if (Std.isOfType(object, flixel.FlxSprite))
		{
			owner = 'flixel.FlxSprite';
			replacement = switch (field) {
				case 'transformWorldToPixels': 'worldToFramePosition';
				case 'transformWorldToPixelsSimple': 'worldToFramePositionSimple';
				case 'transformScreenToPixels': 'screenToFramePosition';
				default: null;
			};
			if (field == 'shadowOffset' && Std.isOfType(object, flixel.text.FlxText))
			{
				owner = 'flixel.text.FlxText';
				replacement = 'setBorderStyle(SHADOW_XY(offsetX, offsetY))';
			}
		}
		if (replacement != null)
			warnMessage('$owner.$field', '$field is deprecated, use $replacement, instead', scriptOwner);
	}

	public static function warnLegacyStateCall(api:String, state:Dynamic, ?scriptOwner:String):Void
	{
		if (!Std.isOfType(state, flixel.FlxState)) return;
		var replacement = api.indexOf('MusicBeatState') >= 0
			? 'MusicBeatState.switchStateFactory(() -> new MyState(), MyState)'
			: 'FlxG.switchState(() -> new MyState())';
		warnMessage(api + '.instance', '$api with a state instance is deprecated, use $replacement instead', scriptOwner);
	}

	public static function warn(oldApi:String, replacement:String):Void
	{
		warnMessage(oldApi, '$oldApi is deprecated; use $replacement instead.');
	}

	public static function warnMessage(oldApi:String, text:String, ?scriptOwner:String):Void
	{
		if (ClientPrefs.data != null && !ClientPrefs.data.scriptWarns) return;
		var owner = scriptOwner == null ? '' : scriptOwner;
		#if LUA_ALLOWED
		if (scriptOwner == null && psychlua.backend.FunkinLua.lastCalledScript != null)
			owner = psychlua.backend.FunkinLua.lastCalledScript.scriptName;
		#end
		final key = owner + '|' + oldApi;
		if (warned.exists(key)) return;
		warned.set(key, true);
		final message = '[WDeprecated] $text';
		trace(message);
		if (PlayState.instance != null)
			PlayState.instance.addTextToDebug(message, FlxColor.fromRGB(90, 170, 255));
		else
			backend.MusicBeatState.addScriptTextToDebug(message, FlxColor.fromRGB(90, 170, 255));
	}
}
