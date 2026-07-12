package;

import debug.FPSCounter;
import debug.TraceDisplay;
import debug.TraceButton;
import debug.DebugButton;
import backend.ClientPrefs;
import backend.Screenshot;
import objects.MaterialVolumeTray;
import flixel.FlxGame;
import flixel.FlxState;
import openfl.Lib;
import openfl.display.Sprite;
import openfl.display.Bitmap;
import openfl.display.BitmapData;
import openfl.display.StageScaleMode;
import lime.app.Application;
import states.TitleState;
#if HSCRIPT_ALLOWED
import crowplexus.iris.Iris;
import psychlua.HScript.HScriptInfos;
#end
import openfl.events.KeyboardEvent;
import flixel.util.FlxTimer;

#if (linux || mac)
import lime.graphics.Image;
#end
import backend.Highscore;
import lime.system.System as LimeSystem;

import slushithings.windows.WindowsAPI;

// NATIVE API STUFF, YOU CAN IGNORE THIS AND SCROLL //
#if (linux && !debug)
@:cppInclude('./external/gamemode_client.h')
@:cppFileCode('#define GAMEMODE_AUTO')
#end

// // // // // // // // //
class Main extends Sprite
{
	public static final game = {
		width: 1280, // WINDOW width
		height: 720, // WINDOW height
		initialState: TitleState, // initial game state
		framerate: 60, // default framerate
		skipSplash: true, // if the default flixel splash screen should be skipped
		startFullscreen: false // if the game should start at fullscreen mode
	};

	public static var fpsVar:FPSCounter;
	public static var traceDisplay:TraceDisplay;
	public static var traceButton:TraceButton;
	public static var debugButton:DebugButton;
	public static var materialVolumeTray:MaterialVolumeTray;

	public static final platform:String = #if mobile "Phones" #else "PCs" #end;
	public static var watermarkSprite:Sprite = null;
	public static var watermark:Bitmap = null;

	// Window focus management
	public static var focused:Bool = true;
	var oldVol:Float = 1.0;
	var newVol:Float = 0.2;
	var focusStateTimer:FlxTimer;
	var windowHasFocus:Bool = true;
	var restoringFocusVolume:Bool = false;
	var lastReportedVolume:Float = 1.0;
	public static var focusMusicTween:FlxTween;

	// You can pretty much ignore everything from here on - your code should go in your states.

	public static function main():Void
	{
		Lib.current.addChild(new Main());
		#if cpp
		cpp.NativeGc.enable(true);
		#elseif hl
		hl.Gc.enable(true);
		#end
	}

	public function new()
	{
		super();
		#if mobile
		#if android
		ClientPrefs.loadStorageTypeEarly();
		StorageUtil.requestPermissions();
		#end
		Sys.setCwd(StorageUtil.getStorageDirectory());
		#if android
		backend.Language.reloadPhrases();
		#end
		#end
		backend.CrashHandler.init();

		#if (cpp && windows)
		backend.Native.fixScaling();
		// Initialize window transparency support
		WindowsAPI.setWindowLayered();
		// Set window border color to purple (128, 41, 182)
		WindowsAPI.setWindowBorderColor(128, 41, 182);
		#end

		#if VIDEOS_ALLOWED
		hxvlc.util.Handle.init(#if (hxvlc >= "1.8.0")  ['--no-lua'] #end);
		#end

		#if LUA_ALLOWED
		Mods.pushGlobalMods();
		#end
		Mods.loadTopMod();

		FlxG.save.bind('funkin', CoolUtil.getSavePath());
		Highscore.load();

		#if HSCRIPT_ALLOWED
		Iris.warn = function(x, ?pos:haxe.PosInfos) {
			Iris.logLevel(WARN, x, pos);
			var newPos:HScriptInfos = cast pos;
			if (newPos.showLine == null) newPos.showLine = true;
			var msgInfo:String = (newPos.funcName != null ? '(${newPos.funcName}) - ' : '')  + '${newPos.fileName}:';
			#if LUA_ALLOWED
			if (newPos.isLua == true) {
				msgInfo += 'HScript:';
				newPos.showLine = false;
			}
			#end
			if (newPos.showLine == true) {
				msgInfo += '${newPos.lineNumber}:';
			}
			msgInfo += ' $x';
			if (PlayState.instance != null)
				PlayState.instance.addTextToDebug('WARNING: $msgInfo', FlxColor.YELLOW);
		}
		Iris.error = function(x, ?pos:haxe.PosInfos) {
			Iris.logLevel(ERROR, x, pos);
			var newPos:HScriptInfos = cast pos;
			if (newPos.showLine == null) newPos.showLine = true;
			var msgInfo:String = (newPos.funcName != null ? '(${newPos.funcName}) - ' : '')  + '${newPos.fileName}:';
			#if LUA_ALLOWED
			if (newPos.isLua == true) {
				msgInfo += 'HScript:';
				newPos.showLine = false;
			}
			#end
			if (newPos.showLine == true) {
				msgInfo += '${newPos.lineNumber}:';
			}
			msgInfo += ' $x';
			if (PlayState.instance != null)
				PlayState.instance.addTextToDebug('ERROR: $msgInfo', FlxColor.RED);
		}
		Iris.fatal = function(x, ?pos:haxe.PosInfos) {
			Iris.logLevel(FATAL, x, pos);
			var newPos:HScriptInfos = cast pos;
			if (newPos.showLine == null) newPos.showLine = true;
			var msgInfo:String = (newPos.funcName != null ? '(${newPos.funcName}) - ' : '')  + '${newPos.fileName}:';
			#if LUA_ALLOWED
			if (newPos.isLua == true) {
				msgInfo += 'HScript:';
				newPos.showLine = false;
			}
			#end
			if (newPos.showLine == true) {
				msgInfo += '${newPos.lineNumber}:';
			}
			msgInfo += ' $x';
			if (PlayState.instance != null)
				PlayState.instance.addTextToDebug('FATAL: $msgInfo', 0xFFBB0000);
		}
		#end

		#if LUA_ALLOWED Lua.set_callbacks_function(cpp.Callable.fromStaticFunction(psychlua.CallbackHandler.call)); #end
		Controls.instance = new Controls();
		ClientPrefs.loadDefaultKeys();
		#if ACHIEVEMENTS_ALLOWED Achievements.load(); #end

		#if mobile
		FlxG.signals.postGameStart.addOnce(() -> {
			FlxG.scaleMode = new mobile.backend.MobileScaleMode();
		});
		#end
		
		addChild(new FlxGame(game.width, game.height, game.initialState, game.framerate, game.framerate, game.skipSplash, game.startFullscreen));
		initializeMaterialVolumeTray();
		backend.RenderInterpolation.install();

		fpsVar = new FPSCounter(10, 3, 0xFFFFFF);
		addChild(fpsVar);
		
		traceDisplay = new TraceDisplay(10, 100, 0xFFFFFF);
		addChild(traceDisplay);
		
		// Agregar los botones de TraceDisplay y Debug para móvil
		#if mobile
		traceButton = new TraceButton();
		addChild(traceButton);
		
		debugButton = new DebugButton();
		addChild(debugButton);
		#end
		
		Lib.current.stage.align = "tl";
		Lib.current.stage.scaleMode = StageScaleMode.NO_SCALE;
		   if(fpsVar != null) {
			   // Posicionamiento inicial con márgenes constantes
			   var marginX = 10;
			   var marginY = 3;
			   #if mobile
			   fpsVar.positionFPS(FlxG.game.x + marginX, FlxG.game.y + marginY, 1.0);
			   #else
			   fpsVar.positionFPS(marginX, marginY, 1.0);
			   #end
		   }

		#if (linux || mac) // fix the app icon not showing up on the Linux Panel / Mac Dock
		var icon = Image.fromFile("icon.png");
		Lib.current.stage.window.setIcon(icon);
		#end

		#if html5
		FlxG.autoPause = false;
		FlxG.mouse.visible = false;
		#end

		FlxG.fixedTimestep = true;
		FlxG.game.focusLostFramerate = #if mobile 30 #else 60 #end;
		#if web
		FlxG.keys.preventDefaultKeys.push(TAB);
		#else
		FlxG.keys.preventDefaultKeys = [TAB];
		#end

		#if DISCORD_ALLOWED
		DiscordClient.prepare();
		#end
		
		#if desktop 
		FlxG.stage.addEventListener(KeyboardEvent.KEY_UP, toggleFullScreen);
		Screenshot.init(); // Initialize screenshot folder
		#end

		#if mobile
		#if android FlxG.android.preventDefaultKeys = [BACK]; #end
		LimeSystem.allowScreenTimeout = ClientPrefs.data.screensaver;
		#end

		Application.current.window.vsync = ClientPrefs.data.vsync;

		#if (cpp && windows)
		// Add window close handler for fade out effect
		Application.current.window.onClose.add(onWindowClose);
		// Add window focus handlers
		Application.current.window.onFocusIn.add(onWindowFocusIn);
		Application.current.window.onFocusOut.add(onWindowFocusOut);
		#end

		// shader coords fix
		var resizeDebounceTimer:FlxTimer = null;
		function handleGameResized():Void {
			ClientPrefs.applyFramePacing();
			backend.RenderInterpolation.syncAllCameras();

			// Only reposition the FPS counter, no scaling.
			if(fpsVar != null) {
				var marginX = 10;
				var marginY = 3;
				#if mobile
				fpsVar.positionFPS(FlxG.game.x + marginX, FlxG.game.y + marginY, 1.0);
				#else
				fpsVar.positionFPS(marginX, marginY, 1.0);
				#end
			}
			
			// Reposition TraceDisplay button.
			#if mobile
			if(traceButton != null) {
				traceButton.updatePosition();
			}
			if(debugButton != null) {
				debugButton.updatePosition();
			}
			#end
			
			// Only reposition the watermark, no scaling.
			positionWatermark();
			
			if (FlxG.cameras != null) {
				for (cam in FlxG.cameras.list) {
					if (cam != null && cam.filters != null)
						resetSpriteCache(cam.flashSprite);
				}
			}

			if (FlxG.game != null)
				resetSpriteCache(FlxG.game);
		}

		FlxG.signals.gameResized.add(function (w, h) {
			if(resizeDebounceTimer == null) {
				resizeDebounceTimer = new FlxTimer();
			}
			resizeDebounceTimer.start(0.05, function(_) {
				handleGameResized();
			});
		});

		setupGame();
	}

	function initializeMaterialVolumeTray():Void
	{
		if (FlxG.game == null || Lib.current == null || Lib.current.stage == null)
			return;

		FlxG.sound.soundTrayEnabled = false;
		lastReportedVolume = FlxG.sound.muted ? 0 : FlxG.sound.volume;

		if (materialVolumeTray == null)
			materialVolumeTray = new MaterialVolumeTray();

		if (materialVolumeTray.parent != Lib.current.stage)
		{
			if (materialVolumeTray.parent != null)
				materialVolumeTray.parent.removeChild(materialVolumeTray);
			Lib.current.stage.addChild(materialVolumeTray);
		}
		Lib.current.stage.setChildIndex(materialVolumeTray, Lib.current.stage.numChildren - 1);

		var self = this;
		FlxG.sound.volumeHandler = function(volume:Float)
		{
			self.onVolumeChanged(volume);
		};
	}

	function onVolumeChanged(volume:Float):Void
	{
		if (materialVolumeTray == null)
			return;

		lastReportedVolume = volume;
		materialVolumeTray.showVolume(volume);
	}

	function preserveSavedMasterVolume(targetVolume:Float, ?flush:Bool = false):Void
	{
		if (FlxG.save == null)
			return;

		FlxG.save.data.volume = targetVolume;
		FlxG.save.data.mute = FlxG.sound.muted;
		if (flush)
			FlxG.save.flush();
	}

	static function resetSpriteCache(sprite:Sprite):Void {
		@:privateAccess {
		        sprite.__cacheBitmap = null;
			sprite.__cacheBitmapData = null;
		}
	}

	function toggleFullScreen(event:KeyboardEvent) {
		if (Controls.instance.justReleased('fullscreen'))
			backend.WindowMode.toggleFullscreen();
	}

	function positionWatermark():Void {
		if (watermarkSprite != null && watermark != null) {
			var marginX = 10;
			var marginY = 10;
			var stageW = openfl.Lib.current.stage.stageWidth;
			watermarkSprite.x = stageW - watermark.width * Math.abs(watermark.scaleX) - marginX;
			watermarkSprite.y = marginY;
		}
		if (watermark != null && watermark.parent == this) {
			var stageW = Lib.current.stage.stageWidth;
			var stageH = Lib.current.stage.stageHeight;
			watermark.x = stageW - watermark.width * Math.abs(watermark.scaleX) + 110;
			watermark.y = stageH - watermark.height * Math.abs(watermark.scaleY) - 30;
		}
	}

	#if (cpp && windows)
	function onWindowClose():Void
	{
		WindowsAPI.fadeOutAndExit();
	}

	function onWindowFocusOut():Void
	{
		focused = false;

		oldVol = FlxG.sound.volume;
		if (oldVol > 0.3)
		{
			newVol = 0.3;
		}
		else
		{
			if (oldVol > 0.1)
			{
				newVol = 0.1;
			}
			else
			{
				newVol = 0;
			}
		}

		if (focusMusicTween != null) focusMusicTween.cancel();
		focusMusicTween = FlxTween.tween(FlxG.sound, {volume: newVol}, 0.5);
	}

	function onWindowFocusIn():Void
	{
		new FlxTimer().start(0.2, function(tmr:FlxTimer) {
			focused = true;
		});

		// Normal global volume when focused
		if (focusMusicTween != null) focusMusicTween.cancel();

		focusMusicTween = FlxTween.tween(FlxG.sound, {volume: oldVol}, 0.5);
	}
	#end

	private function setupGame():Void
	{
		shaders.ShaderCompatibility.init();
		
		trace('\n\n' + backend.Native.buildSystemInfo());
		
		#if hxvlc
		try {
			hxvlc.util.Handle.init();
			trace('hxvlc initialized successfully');
		} catch(e:Dynamic) {
			trace('hxvlc initialization failed: $e');
		}
		#end
		
		var flxGraphic = backend.Paths.image("marca");
		if (flxGraphic != null) {
			var bmpData:openfl.display.BitmapData = flxGraphic.bitmap;
			if (watermarkSprite != null && watermarkSprite.parent != null) {
				watermarkSprite.parent.removeChild(watermarkSprite);
			}
			watermark = new openfl.display.Bitmap(bmpData);
			watermark.smoothing = true;
			watermarkSprite = new openfl.display.Sprite();
			watermarkSprite.addChild(watermark);
			var scale:Float = 0.85;
			watermark.scaleX = scale;
			watermark.scaleY = scale;
			positionWatermark();
			watermarkSprite.alpha = 0.5;
			watermarkSprite.visible = ClientPrefs.data.showWatermark;
			openfl.Lib.current.stage.addChild(watermarkSprite);
		} else {
			trace('No se pudo cargar la marca de agua con backend.Paths.image("marca").');
		}

		var imagePath = backend.Paths.getPath('images/marca.png', IMAGE);
		if (sys.FileSystem.exists(imagePath)) {
		    if (watermark != null && watermark.parent != null)
		        removeChild(watermark);
			var bmpData = openfl.display.BitmapData.fromFile(imagePath);
			watermark = new openfl.display.Bitmap(bmpData);
			var scale = 0.85;
			watermark.scaleX = -scale;
			watermark.scaleY = scale;
			watermark.alpha = 0.5;
			addChild(watermark);
			positionWatermark();
			Lib.current.stage.addEventListener(openfl.events.Event.RESIZE, function(_) positionWatermark());
		}
		if (watermark != null) {
		    watermark.visible = ClientPrefs.data.showWatermark;
		}
	}
}

