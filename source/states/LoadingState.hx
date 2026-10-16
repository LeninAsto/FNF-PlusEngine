package states;

import backend.LoadTaskGroup;
import haxe.Json;
import lime.utils.Assets;
import openfl.display.BitmapData;
import openfl.utils.AssetType;
import openfl.utils.Assets as OpenFlAssets;
import flixel.system.FlxAssets;
import flixel.FlxState;
import flash.media.Sound;
import backend.Song;
import backend.StageData;
import backend.Rating;
import backend.SongLoadPlan;
import backend.SongLoadMetrics;
import sys.thread.Mutex;
import objects.GlobalLoadingOverlay;
import objects.Note;
import objects.NoteSplash;
#if HSCRIPT_ALLOWED
import psychlua.backend.HScript;
import crowplexus.iris.Iris;
import crowplexus.hscript.Expr.Error as IrisError;
import crowplexus.hscript.Printer;
#end

class LoadingState extends MusicBeatState
{
	public static var loaded:Int = 0;
	public static var loadMax:Int = 0;
	static var currentItem:String = '';

	static var originalBitmapKeys:Map<String, String> = [];
	static var requestedBitmaps:Map<String, BitmapData> = [];
	static var soundsToWarm:Array<Sound> = [];
	static final mutex:Mutex = new Mutex();
	static var progressMutex:Mutex = new Mutex();
	static var threadPool:LoadTaskGroup = null;

	static inline var LOAD_STALL_TIMEOUT:Float = 30.0;
	static inline var MAX_LOAD_THREADS:Int = 6;

	// Timeout system
	public static var returnState:FlxState = null; // Estado al que volver si falla la carga

	public var loadingTimer:Float = 0; // Contador de tiempo de carga
	public var timeoutWarning:FlxText; // Mensaje de advertencia
	public var canEscape:Bool = false; // Si se puede presionar ESC para salir

	static final TIMEOUT_DURATION:Float = 5.0; // 5 segundos

	function new(target:FlxState, stopMusic:Bool)
	{
		this.target = target;
		this.stopMusic = stopMusic;

		super();
	}

	inline static public function loadAndSwitchState(target:FlxState, stopMusic = false, intrusive:Bool = true)
		MusicBeatState.switchState(getNextState(target, stopMusic, intrusive));

	public var target:FlxState = null;
	public var stopMusic:Bool = false;
	public var dontUpdate:Bool = false;

	public var barGroup:FlxSpriteGroup;
	public var bar:FlxSprite;
	public var barWidth:Int = 0;
	public var intendedPercent:Float = 0;
	public var curPercent:Float = 0;
	public var stateChangeDelay:Float = 0;
	public var loadDetailText:FlxText;
	var lastLoadDetail:String = '';

	#if PSYCH_WATERMARKS
	public var logo:FlxSprite;
	public var pessy:FlxSprite;
	public var loadingText:FlxText;

	public var timePassed:Float;
	public var shakeFl:Float;
	public var shakeMult:Float = 0;

	public var isSpinning:Bool = false;
	public var spawnedPessy:Bool = false;
	public var pressedTimes:Int = 0;
	#else
	public var funkay:FlxSprite;
	#end

	#if HSCRIPT_ALLOWED
	public var hscript:HScript;
	#end

	override function create()
	{
		persistentUpdate = true;
		barGroup = new FlxSpriteGroup();
		add(barGroup);

		var barBack:FlxSprite = new FlxSprite(0, 660).makeGraphic(1, 1, FlxColor.BLACK);
		barBack.scale.set(FlxG.width - 300, 25);
		barBack.updateHitbox();
		barBack.screenCenter(X);
		barGroup.add(barBack);

		bar = new FlxSprite(barBack.x + 5, barBack.y + 5).makeGraphic(1, 1, FlxColor.WHITE);
		bar.scale.set(0, 15);
		bar.updateHitbox();
		barGroup.add(bar);
		barWidth = Std.int(barBack.width - 10);

		#if HSCRIPT_ALLOWED
		if (Mods.currentModDirectory != null && Mods.currentModDirectory.trim().length > 0)
		{
			var scriptPath:String = 'mods/${Mods.currentModDirectory}/data/LoadingScreen.hx'; // mods/My-Mod/data/LoadingScreen.hx
			if (FileSystem.exists(scriptPath))
			{
				try
				{
					hscript = new HScript(null, scriptPath);
					hscript.set('getLoaded', function() return loaded);
					hscript.set('getLoadMax', function() return loadMax);
					hscript.set('getLoadItem', getLoadItem);
					hscript.set('getLoadPercent', getLoadPercent);
					hscript.set('barBack', barBack);
					hscript.set('bar', bar);

					if (hscript.exists('onCreate'))
					{
						hscript.call('onCreate');
						trace('HScript (Psych 1.0.x) file loaded successfully: $scriptPath');
						return super.create();
					}
					else
					{
						trace('"$scriptPath" contains no \"onCreate" function, stopping script.');
					}
				}
				catch (e:IrisError)
				{
					var pos:HScriptInfos = cast {fileName: scriptPath, showLine: false};
					Iris.error(Printer.errorToString(e, false), pos);
					var hscript:HScript = cast(Iris.instances.get(scriptPath), HScript);
				}
				if (hscript != null)
					hscript.destroy();
				hscript = null;
			}
		}
		#end

		#if PSYCH_WATERMARKS // PSYCH LOADING SCREEN
		var bg = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		bg.antialiasing = ClientPrefs.data.antialiasing;
		bg.setGraphicSize(Std.int(FlxG.width));
		bg.color = 0xFFD16FFF;
		bg.updateHitbox();
		addBehindBar(bg);

		loadingText = new FlxText(520, 580, 400, Language.getPhrase('now_loading', 'Now Loading', ['...']), 32);
		loadingText.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, LEFT, OUTLINE_FAST, FlxColor.BLACK);
		loadingText.borderSize = 2;
		addBehindBar(loadingText);

		logo = new FlxSprite(0, 0).loadGraphic(Paths.image('loading_screen/icon'));
		logo.antialiasing = ClientPrefs.data.antialiasing;
		logo.scale.set(0.75, 0.75);
		logo.updateHitbox();
		logo.screenCenter();
		logo.x -= 50;
		logo.y -= 40;
		addBehindBar(logo);
		#else // BASE GAME LOADING SCREEN
		var bg = new FlxSprite().makeGraphic(1, 1, 0xFFCAFF4D);
		bg.scale.set(FlxG.width, FlxG.height);
		bg.updateHitbox();
		bg.screenCenter();
		addBehindBar(bg);

		funkay = new FlxSprite(0, 0).loadGraphic(Paths.image('funkay'));
		funkay.antialiasing = ClientPrefs.data.antialiasing;
		funkay.setGraphicSize(0, FlxG.height);
		funkay.updateHitbox();
		addBehindBar(funkay);
		#end

		loadDetailText = new FlxText(40, 625, FlxG.width - 80, '', 18);
		loadDetailText.setFormat(Paths.font('vcr.ttf'), 18, FlxColor.WHITE, CENTER, OUTLINE_FAST, FlxColor.BLACK);
		loadDetailText.borderSize = 1.5;
		addBehindBar(loadDetailText);

		// Timeout warning message
		timeoutWarning = new FlxText(0, FlxG.height - 100, FlxG.width, "", 24);
		timeoutWarning.setFormat(Paths.font("vcr.ttf"), 24, FlxColor.RED, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		timeoutWarning.borderSize = 2;
		timeoutWarning.visible = false;
		add(timeoutWarning);
		if (cancelling)
		{
			timeoutWarning.text = Language.getPhrase('loading_cancelling', 'Cancelling loading...', []);
			timeoutWarning.visible = true;
		}

		// Añadir touchpad para Android
		addTouchPad('NONE', 'B');

		super.create();
		GlobalLoadingOverlay.showPersistent();

		if (!cancelling && stateChangeDelay <= 0 && checkLoaded())
		{
			dontUpdate = true;
			onLoad();
		}
	}

	function addBehindBar(obj:flixel.FlxBasic)
	{
		insert(members.indexOf(barGroup), obj);
	}

	var transitioning:Bool = false;
	var watchLoaded:Int = -1;
	var watchInit:Bool = false;
	var stallTime:Float = 0;
	var cancelling:Bool = false;

	function cancelLoading():Void
	{
		if (cancelling)
			return;
		cancelling = true;
		SongLoadMetrics.cancel();
		if (threadPool != null)
			threadPool.cancel();
		timeoutWarning.text = Language.getPhrase('loading_cancelling', 'Cancelling loading...', []);
		timeoutWarning.visible = true;
	}

	function finishCancellation():Void
	{
		_loaded();
		transitioning = true;
		finishedLoading = true;
		var targetState:FlxState = returnState != null ? returnState : new MainMenuState();
		if (stopMusic && FlxG.sound.music != null)
			FlxG.sound.music.stop();
		FlxG.camera.fade(FlxColor.BLACK, 0.3, false, () -> MusicBeatState.switchState(targetState));
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);
		if (dontUpdate)
			return;
		GlobalLoadingOverlay.showPersistent();
		if (cancelling)
		{
			if (!transitioning && !hasPendingTasks())
				finishCancellation();
			return;
		}

		// Timeout system - incrementar el temporizador
		if (!transitioning && !finishedLoading)
		{
			loadingTimer += elapsed;

			// Si pasan más de 10 segundos, mostrar mensaje de escape
			if (loadingTimer >= TIMEOUT_DURATION && !canEscape)
			{
				canEscape = true;
				timeoutWarning.text = Language.getPhrase('loading_timeout', 'Loading is taking too long...\nPress ESC to return', []);
				timeoutWarning.visible = true;
				FlxG.sound.play(Paths.sound('cancelMenu'));
			}

			// Si se puede escapar y se presiona ESC o botón B del touchpad, volver al estado anterior
			if (canEscape && (FlxG.keys.justPressed.ESCAPE || (touchPad != null && touchPad.buttonB.justPressed)))
			{
				cancelLoading();
				FlxG.sound.play(Paths.sound('cancelMenu'));
				return;
			}
		}

		if (!transitioning)
		{
			var progressLoaded:Int = getLoadedCount();
			if (!finishedLoading && checkLoaded())
			{
				if (stateChangeDelay <= 0)
				{
					transitioning = true;
					onLoad();
					return;
				}
				else
					stateChangeDelay = Math.max(0, stateChangeDelay - elapsed);
			}
			intendedPercent = (loadMax > 0) ? progressLoaded / loadMax : 0;
			updateLoadDetail(progressLoaded);

			if (!finishedLoading)
			{
				if (loaded != watchLoaded || initialThreadCompleted != watchInit)
				{
					watchLoaded = loaded;
					watchInit = initialThreadCompleted;
					stallTime = 0;
				}
				else if ((stallTime += elapsed) >= LOAD_STALL_TIMEOUT)
				{
					logLoadTimeout();
					cancelLoading();
					return;
				}
			}
		}

		if (curPercent != intendedPercent)
		{
			if (Math.abs(curPercent - intendedPercent) < 0.001)
				curPercent = intendedPercent;
			else
				curPercent = FlxMath.lerp(intendedPercent, curPercent, Math.exp(-elapsed * 15));

			bar.scale.x = barWidth * curPercent;
			bar.updateHitbox();
		}

		#if HSCRIPT_ALLOWED
		if (hscript != null)
		{
			if (hscript.exists('onUpdate'))
				hscript.call('onUpdate', [elapsed]);
			return;
		}
		#end

		#if PSYCH_WATERMARKS // PSYCH LOADING SCREEN
		timePassed += elapsed;
		shakeFl += elapsed * 3000;
		var dots:String = '';
		switch (Math.floor(timePassed % 1 * 3))
		{
			case 0:
				dots = '.';
			case 1:
				dots = '..';
			case 2:
				dots = '...';
		}
		loadingText.text = Language.getPhrase('now_loading', 'Now Loading{1}', [dots]);

		if (!spawnedPessy)
		{
			if (!transitioning && (controls.ACCEPT || FlxG.touches.getFirst() != null && FlxG.touches.getFirst().justPressed))
			{
				shakeMult = 1;
				FlxG.sound.play(Paths.sound('cancelMenu'));
				pressedTimes++;
			}
			shakeMult = Math.max(0, shakeMult - elapsed * 5);
			logo.offset.x = Math.sin(shakeFl * Math.PI / 180) * shakeMult * 100;

			if (pressedTimes >= 5)
			{
				FlxG.camera.fade(0xAAFFFFFF, 0.5, true);
				logo.visible = false;
				spawnedPessy = true;
				stateChangeDelay = 5;
				FlxG.sound.play(Paths.sound('secret'));

				pessy = new FlxSprite(700, 140);
				pessy.frames = Paths.getSparrowAtlas('loading_screen/pessy');
				pessy.animation.addByPrefix('run', 'run', 24, true);
				pessy.animation.addByPrefix('spin', 'spin', 24, true);
				pessy.antialiasing = ClientPrefs.data.antialiasing;
				pessy.flipX = (logo.offset.x > 0);
				pessy.visible = false;

				new FlxTimer().start(0.01, function(tmr:FlxTimer)
				{
					pessy.x = FlxG.width + 200;
					pessy.velocity.x = -1100;
					if (pessy.flipX)
					{
						pessy.x = -pessy.width - 200;
						pessy.velocity.x *= -1;
					}

					pessy.visible = true;
					pessy.animation.play('run', true);
					#if ACHIEVEMENTS_ALLOWED Achievements.unlock('pessy_easter_egg'); #end

					insert(members.indexOf(loadingText), pessy);
				});
			}
		}
		else if (!isSpinning && (pessy.flipX && pessy.x > FlxG.width) || (!pessy.flipX && pessy.x < -pessy.width))
		{
			isSpinning = true;
			pessy.animation.play('spin', true);
			pessy.flipX = false;
			pessy.x = 500;
			pessy.y = FlxG.height + 500;
			pessy.velocity.x = 0;
			FlxTween.tween(pessy, {y: 10}, 0.65, {ease: FlxEase.quadOut});
		}
		#end
	}

	function updateLoadDetail(progressLoaded:Int):Void
	{
		if (loadDetailText == null)
			return;

		var item:String = getLoadItem();
		if (item.length > 88)
			item = '...' + item.substr(item.length - 85);
		var detail:String = '${getLoadPercent(progressLoaded)}%  (${progressLoaded}/${loadMax})';
		if (item.length > 0)
			detail += '  $item';

		if (detail != lastLoadDetail)
		{
			loadDetailText.text = detail;
			lastLoadDetail = detail;
		}
	}

	override function destroy()
	{
		if (!finishedLoading && threadPool != null)
		{
			threadPool.cancel();
			SongLoadMetrics.cancel();
			if (!hasPendingTasks())
				_loaded();
		}
		#if HSCRIPT_ALLOWED
		if (hscript != null)
		{
			if (hscript.exists('onDestroy'))
				hscript.call('onDestroy');
			hscript.destroy();
		}
		hscript = null;
		#end
		super.destroy();
	}

	var finishedLoading:Bool = false;

	function onLoad()
	{
		SongLoadMetrics.finish();
		Paths.retainTempFramesForNextState();
		_loaded();
		// Task bodies have finished publishing results; idle workers are exiting.
		backend.MemoryManager.runPendingCollection();
		GlobalLoadingOverlay.showPersistent();

		if (stopMusic && FlxG.sound.music != null)
			FlxG.sound.music.stop();

		FlxG.camera.visible = false;
		MusicBeatState.switchState(target);
		transitioning = true;
		finishedLoading = true;
	}

	static function _loaded()
	{
		if (hasPendingTasks())
			throw 'Cannot finish loading while tasks are still running';
		// Cancelled/unused decoded images were never handed to the asset cache.
		for (bitmap in requestedBitmaps)
			if (bitmap != null)
				bitmap.dispose();
		requestedBitmaps.clear();
		originalBitmapKeys.clear();
		soundsToWarm.resize(0);
		atlasesToPrepare.resize(0);
		loaded = 0;
		loadMax = 0;
		initialThreadCompleted = true;
		isIntrusive = false;

		FlxTransitionableState.skipNextTransIn = true;
		if (threadPool != null)
			threadPool.shutdown(); // Task bodies are already finished; wake idle workers to exit.
		threadPool = null;
		backend.MemoryManager.setLoadingBusy(false);
		setLoadItem('');
	}

	public static function hasPendingTasks():Bool
		return threadPool != null && !threadPool.isIdle();

	static function setLoadItem(item:String):Void
	{
		progressMutex.acquire();
		currentItem = item == null ? '' : item;
		progressMutex.release();
	}

	public static function getLoadItem():String
	{
		progressMutex.acquire();
		var item:String = currentItem;
		progressMutex.release();
		return item;
	}

	static function getLoadedCount():Int
	{
		progressMutex.acquire();
		var count:Int = loaded;
		progressMutex.release();
		return count;
	}

	public static function getLoadPercent(?progressLoaded:Int):Int
	{
		var count:Int = progressLoaded == null ? getLoadedCount() : progressLoaded;
		return loadMax > 0 ? Math.floor(Math.min(count / loadMax, 1) * 100) : 0;
	}

	static function logLoadTimeout()
		trace('LoadingState watchdog: no progress for ${LOAD_STALL_TIMEOUT}s at $loaded/$loadMax; cancelling incomplete load.');

	public static function checkLoaded():Bool
	{
		// Capture idle before draining results. A worker finishing during this call
		// may publish a bitmap after the drain, so that completion belongs to the next call.
		var tasksIdle:Bool = !hasPendingTasks();
		var pending:Map<String, BitmapData> = null;
		var pendingKeys:Map<String, String> = null;
		if (mutex != null)
			mutex.acquire();
		if (requestedBitmaps.keys().hasNext())
		{
			pending = requestedBitmaps;
			pendingKeys = originalBitmapKeys;
			requestedBitmaps = new Map<String, BitmapData>();
			originalBitmapKeys = new Map<String, String>();
		}
		if (mutex != null)
			mutex.release();

		if (pending != null)
		{
			for (key => bitmap in pending)
			{
				if (bitmap != null && Paths.cacheBitmap(key, null, bitmap) != null)
				{
				} // trace('finished preloading image $key');
				else
					trace('failed to cache image $key');
			}
		}

		// Atlas creation touches Flixel/OpenFL objects, so it belongs on the main thread.
		// Preparing one per frame keeps the loading screen responsive on slower phones.
		if (tasksIdle && initialThreadCompleted && getLoadedCount() >= workerLoadMax && atlasesToPrepare.length > 0)
		{
			var atlas:String = atlasesToPrepare.shift();
			setLoadItem('atlas $atlas');
			try
			{
				Paths.getSparrowAtlas(atlas);
			}
			catch (e:Dynamic)
			{
				trace('ERROR! fail on preloading atlas $atlas: $e');
			}
			progressMutex.acquire();
			loaded++;
			progressMutex.release();
		}
		if (tasksIdle && soundsToWarm.length > 0)
		{
			setLoadItem('Preparing audio playback');
			try backend.AssetLoader.warmAudio(soundsToWarm.shift())
			catch (error:Dynamic) trace('Audio warmup failed: $error');
		}
		// trace('we checked if loaded');
		return (tasksIdle && soundsToWarm.length == 0 && getLoadedCount() >= loadMax && initialThreadCompleted);
	}

	public static function loadNextDirectory()
	{
		var directory:String = 'shared';
		var weekDir:String = StageData.forceNextDirectory;
		StageData.forceNextDirectory = null;

		if (weekDir != null && weekDir.length > 0 && weekDir != '')
			directory = weekDir;

		Paths.setCurrentLevel(directory);
		trace('Setting asset folder to ' + directory);
	}

	static var isIntrusive:Bool = false;

	static function getNextState(target:FlxState, stopMusic = false, intrusive:Bool = true):FlxState
	{
		#if !SHOW_LOADING_SCREEN
		intrusive = false;
		#end

		LoadingState.isIntrusive = intrusive;
		_startPool();
		loadNextDirectory();

		if (intrusive)
			return new LoadingState(target, stopMusic);

		if (stopMusic && FlxG.sound.music != null)
			FlxG.sound.music.stop();

		var watchLoaded:Int = -1;
		var watchInit:Bool = false;
		var stallStart:Float = Sys.time();
		while (true)
		{
			if (checkLoaded())
			{
				_loaded();
				break;
			}
			if (loaded != watchLoaded || initialThreadCompleted != watchInit)
			{
				watchLoaded = loaded;
				watchInit = initialThreadCompleted;
				stallStart = Sys.time();
			}
			else if (Sys.time() - stallStart >= LOAD_STALL_TIMEOUT)
			{
				logLoadTimeout();
				SongLoadMetrics.cancel();
				threadPool.cancel();
				// Recover through an updating screen rather than freezing the caller
				// while native work drains, or returning a partially loaded song.
				var recovery = new LoadingState(target, stopMusic);
				recovery.cancelling = true;
				return recovery;
			}
			Sys.sleep(0.001);
		}
		return target;
	}

	static var imagesToPrepare:Array<String> = [];
	static var soundsToPrepare:Array<String> = [];
	static var musicToPrepare:Array<String> = [];
	static var songsToPrepare:Array<String> = [];
	static var atlasesToPrepare:Array<String> = [];
	static var workerLoadMax:Int = 0;

	public static function prepare(images:Array<String> = null, sounds:Array<String> = null, music:Array<String> = null)
	{
		if (images != null)
			imagesToPrepare = imagesToPrepare.concat(images);
		if (sounds != null)
			soundsToPrepare = soundsToPrepare.concat(sounds);
		if (music != null)
			musicToPrepare = musicToPrepare.concat(music);
	}

	static var initialThreadCompleted:Bool = true;
	static var dontPreloadDefaultVoices:Bool = false;

	static function _startPool()
	{
		if (threadPool != null)
		{
			if (!threadPool.isCancelled())
				return;
			if (hasPendingTasks())
				throw 'Previous song load is still cancelling';
			_loaded();
		}

		#if MULTITHREADED_LOADING
		// Due to the Main thread and Discord thread, we decrease it by 2.
		var threadCount:Int = Std.int(Math.max(1, CoolUtil.getCPUThreadsCount() - #if DISCORD_ALLOWED 2 #else 1 #end));
		if (threadCount > MAX_LOAD_THREADS)
			threadCount = MAX_LOAD_THREADS;
		// External flash storage gets slower when too many workers compete for it.
		#if android
		if (threadCount > 3)
			threadCount = 3;
		#end
		#else
		var threadCount:Int = 1;
		#end
		threadPool = new LoadTaskGroup(threadCount);
		backend.MemoryManager.setLoadingBusy(true);
	}

	static function collectPreloadAssets(json:Dynamic, imgs:Array<String>, snds:Array<String>, mscs:Array<String>)
	{
		for (asset in Reflect.fields(json))
		{
			var filters:Int = Reflect.field(json, asset);
			var asset:String = asset.trim();

			if (filters < 0 || StageData.validateVisibility(filters))
			{
				if (asset.startsWith('images/'))
					imgs.push(asset.substr('images/'.length));
				else if (asset.startsWith('sounds/'))
					snds.push(asset.substr('sounds/'.length));
				else if (asset.startsWith('music/'))
					mscs.push(asset.substr('music/'.length));
			}
		}
	}

	static function stageUIAsset(stageUI:String, name:String):String
	{
		if (stageUI == null || stageUI.length == 0 || stageUI == 'normal')
			return name;

		var path:String = stageUI.replace('\\', '/');
		var pixel:Bool = path == 'pixel' || path.endsWith('-pixel');
		if (path.endsWith('-pixel'))
			path = path.substr(0, path.length - 6);
		var parts:Array<String> = path.split('/');
		var last:Int = parts.length - 1;
		if (!parts[last].toUpperCase().endsWith('UI'))
			parts[last] += 'UI';
		return parts.join('/') + '/' + name + (pixel ? '-pixel' : '');
	}

	public static function prepareToSong()
	{
		if (hasPendingTasks())
			throw 'A song load is already running';
		if (threadPool != null)
			_loaded();
		setLoadItem('Preparing song data');
		if (PlayState.SONG == null)
		{
			SongLoadMetrics.cancel();
			imagesToPrepare = [];
			soundsToPrepare = [];
			musicToPrepare = [];
			songsToPrepare = [];
			atlasesToPrepare = [];
			loaded = 0;
			loadMax = 0;
			initialThreadCompleted = true;
			isIntrusive = false;
			return;
		}
		SongLoadMetrics.markLoading();

		_startPool();
		imagesToPrepare = [];
		soundsToPrepare = [];
		musicToPrepare = [];
		songsToPrepare = [];
		atlasesToPrepare = [];

		initialThreadCompleted = false;
		var song:SwagSong = PlayState.SONG;
		var folder:String = Paths.formatToSongPath(Song.loadedSongName);
		threadPool.run(() ->
		{
			try
			{
				setLoadItem('compiling chart data');
				SongLoadPlan.prepare(song);

				if (song.stage == null || song.stage.length < 1)
					song.stage = StageData.vanillaSongStage(folder);
				var stageData:StageFile = StageData.getStageFile(song.stage);
				var stageUI:String = stageData != null && stageData.stageUI != null ? stageData.stageUI.trim() : '';
				var pixelStage:Bool = stageUI == 'pixel' || stageUI.endsWith('-pixel') || (stageUI.length == 0 && stageData != null && stageData.isPixelStage == true);
				if (stageUI.length == 0)
					stageUI = pixelStage ? 'pixel' : 'normal';

				// Core gameplay UI and sounds should be cache hits by the time PlayState is created.
				imagesToPrepare.push('alphabet');
				if (!ClientPrefs.data.ghostTapping)
					for (i in 1...4)
						soundsToPrepare.push('missnote$i');
				var introSuffix:String = pixelStage ? '-pixel' : '';
				for (intro in ['intro3', 'intro2', 'intro1', 'introGo'])
					soundsToPrepare.push(intro + introSuffix);
				var pauseMusic:String = Paths.formatToSongPath(ClientPrefs.data.pauseMusic);
				if (pauseMusic != 'none')
					musicToPrepare.push(pauseMusic);

				var countdown:Array<String> = pixelStage ? ['pixelUI/ready-pixel', 'pixelUI/set-pixel', 'pixelUI/date-pixel'] :
					[stageUIAsset(stageUI, 'ready'), stageUIAsset(stageUI, 'set'), stageUIAsset(stageUI, 'go')];
				for (asset in countdown)
					imagesToPrepare.push(asset);
				for (rating in Rating.loadDefault())
					imagesToPrepare.push(stageUIAsset(stageUI, rating.image));
				for (i in 0...10)
					imagesToPrepare.push(stageUIAsset(stageUI, 'num$i'));
				for (asset in ['combo', 'miss', 'early', 'late', 'minus'])
					imagesToPrepare.push(stageUIAsset(stageUI, asset));
				imagesToPrepare.push(pixelStage ? 'pixelUI/minus-pixel' : 'minus');

				// LOAD NOTE IMAGE
				var noteSkin:String = Note.getDefaultNoteSkinPath(pixelStage);
				if (PlayState.SONG.arrowSkin != null && PlayState.SONG.arrowSkin.length > 1)
					noteSkin = PlayState.SONG.arrowSkin;
				noteSkin = Note.resolveNoteSkinPath(noteSkin, pixelStage);
				if (pixelStage)
				{
					imagesToPrepare.push('pixelUI/$noteSkin');
					imagesToPrepare.push('pixelUI/${noteSkin}ENDS');
				}
				else
				{
					imagesToPrepare.push(noteSkin);
					atlasesToPrepare.push(noteSkin);
				}
				//

				// LOAD NOTE SPLASH IMAGE
				var noteSplash:String = NoteSplash.resolveNoteSplashPath(null, pixelStage);
				if (PlayState.SONG.splashSkin != null && PlayState.SONG.splashSkin.length > 0)
					noteSplash = NoteSplash.resolveNoteSplashPath(PlayState.SONG.splashSkin, pixelStage, false);
				imagesToPrepare.push(noteSplash);
				atlasesToPrepare.push(noteSplash);

				try
				{
					var path:String = Paths.json('$folder/preload');
					var json:Dynamic = null;

					#if MODS_ALLOWED
					var moddyFile:String = Paths.modsJson('$folder/preload');
					if (FileSystem.exists(moddyFile))
						json = Json.parse(File.getContent(moddyFile));
					else
						json = Json.parse(File.getContent(path));
					#else
					json = Json.parse(Assets.getText(path));
					#end

					if (json != null)
					{
						var imgs:Array<String> = [];
						var snds:Array<String> = [];
						var mscs:Array<String> = [];
						collectPreloadAssets(json, imgs, snds, mscs);
						prepare(imgs, snds, mscs);
					}
				}
				catch (e:Dynamic)
				{
				}

				if (stageData != null)
				{
					var imgs:Array<String> = [];
					var snds:Array<String> = [];
					var mscs:Array<String> = [];
					if (stageData.preload != null)
						collectPreloadAssets(stageData.preload, imgs, snds, mscs);

					if (stageData.objects != null)
					{
						for (sprite in stageData.objects)
						{
							if (sprite.type == 'sprite' || sprite.type == 'animatedSprite')
								if ((sprite.filters < 0 || StageData.validateVisibility(sprite.filters)) && !imgs.contains(sprite.image))
									imgs.push(sprite.image);
						}
					}
					prepare(imgs, snds, mscs);
				}

				songsToPrepare.push('$folder/Inst');

				var player1:String = song.player1;
				var player2:String = song.player2;
				var gfVersion:String = song.gfVersion;
				var prefixVocals:String = song.needsVoices ? '$folder/Voices' : null;
				if (gfVersion == null)
					gfVersion = 'gf';

				dontPreloadDefaultVoices = false;
				preloadCharacter(player1, prefixVocals);
				if (!dontPreloadDefaultVoices && prefixVocals != null)
				{
					if (Paths.fileExists('$prefixVocals-Player.${Paths.SOUND_EXT}', SOUND, false, 'songs')
						&& Paths.fileExists('$prefixVocals-Opponent.${Paths.SOUND_EXT}', SOUND, false, 'songs'))
					{
						songsToPrepare.push('$prefixVocals-Player');
						songsToPrepare.push('$prefixVocals-Opponent');
					}
					else if (Paths.fileExists('$prefixVocals.${Paths.SOUND_EXT}', SOUND, false, 'songs'))
						songsToPrepare.push(prefixVocals);
				}

				if (player2 != player1)
				{
					try
					{
						preloadCharacter(player2, prefixVocals);
					}
					catch (e:Dynamic)
					{
					}
				}
				if ((stageData == null || !stageData.hide_girlfriend) && gfVersion != player2 && gfVersion != player1)
				{
					try
					{
						preloadCharacter(gfVersion);
					}
					catch (e:Dynamic)
					{
					}
				}
			}
			catch (err:Dynamic)
			{
				trace('ERROR! while preparing song: $err');
			}
			if (!threadPool.isCancelled())
			{
				clearInvalids();
				startThreads();
			}
			initialThreadCompleted = true;
		});
	}

	public static function clearInvalids()
	{
		dedupe(imagesToPrepare);
		dedupe(soundsToPrepare);
		dedupe(musicToPrepare);
		dedupe(songsToPrepare);
		dedupe(atlasesToPrepare);

		clearInvalidFrom(imagesToPrepare, 'images', '.png', IMAGE);
		clearInvalidFrom(soundsToPrepare, 'sounds', '.${Paths.SOUND_EXT}', SOUND);
		clearInvalidFrom(musicToPrepare, 'music', '.${Paths.SOUND_EXT}', SOUND);
		clearInvalidFrom(songsToPrepare, 'songs', '.${Paths.SOUND_EXT}', SOUND, 'songs');

		for (arr in [imagesToPrepare, soundsToPrepare, musicToPrepare, songsToPrepare])
			while (arr.contains(null))
				arr.remove(null);
	}

	static function dedupe(arr:Array<String>):Void
	{
		var seen:Map<String, Bool> = [];
		var i:Int = 0;
		while (i < arr.length)
		{
			var item:String = arr[i];
			var key:String = item == null ? null : item.trim();
			if (key == null || seen.exists(key))
			{
				arr.splice(i, 1);
				continue;
			}

			seen.set(key, true);
			if (key != item)
				arr[i] = key;
			i++;
		}
	}

	static function clearInvalidFrom(arr:Array<String>, prefix:String, ext:String, type:AssetType, ?parentFolder:String = null)
	{
		for (folder in arr.copy())
		{
			var nam:String = folder.trim();
			if (nam.endsWith('/'))
			{
				for (subfolder in Mods.directoriesWithFile(Paths.getSharedPath(), '$prefix/$nam'))
				{
					for (file in Paths.readDirectory(subfolder))
					{
						if (file.endsWith(ext))
						{
							var toAdd:String = nam + haxe.io.Path.withoutExtension(file);
							if (!arr.contains(toAdd))
								arr.push(toAdd);
						}
					}
				}

				// trace('Folder detected! ' + folder);
			}
		}

		var i:Int = 0;
		while (i < arr.length)
		{
			var member:String = arr[i];
			var myKey = '$prefix/$member$ext';
			if (parentFolder == 'songs')
				myKey = '$member$ext';

			// trace('attempting on $prefix: $myKey');
			var doTrace:Bool = false;
			if (member.endsWith('/') || (!Paths.fileExists(myKey, type, false, parentFolder) && (doTrace = true)))
			{
				arr.remove(member);
				if (doTrace)
					trace('Removed invalid $prefix: $member');
			}
			else
				i++;
		}
	}

	public static function startThreads()
	{
		if (threadPool != null && threadPool.isCancelled())
			return;
		workerLoadMax = imagesToPrepare.length + soundsToPrepare.length + musicToPrepare.length + songsToPrepare.length;
		loadMax = workerLoadMax + atlasesToPrepare.length;
		SongLoadMetrics.beginAssets(loadMax);
		loaded = 0;
		if (loadMax == 0)
			setLoadItem('Finishing');

		// then start threads
		_threadFunc();
	}

	static function _threadFunc()
	{
		_startPool();
		for (sound in soundsToPrepare)
			initThread(() -> preloadSound('sounds/$sound'), 'sound $sound');
		for (music in musicToPrepare)
			initThread(() -> preloadSound('music/$music'), 'music $music');
		for (song in songsToPrepare)
			initThread(() -> preloadSound(song, 'songs', true, false, true), 'song $song');

		// for images, they get to have their own thread
		for (image in imagesToPrepare)
			initThread(() -> preloadGraphic(image), 'image $image');
	}

	static function initThread(func:Void->Dynamic, traceData:String)
	{
		// trace('scheduled $func in threadPool');
		#if debug
		var threadSchedule = Sys.time();
		#end
		threadPool.run(() ->
		{
			setLoadItem(traceData);
			#if debug
			var threadStart = Sys.time();
			trace('$traceData took ${threadStart - threadSchedule}s to start preloading');
			#end

			try
			{
				if (func() != null)
				{
					#if debug
					var diff = Sys.time() - threadStart;
					trace('finished preloading $traceData in ${diff}s');
					#end
				}
				else
					trace('ERROR! fail on preloading $traceData ');
			}
			catch (e:Dynamic)
			{
				trace('ERROR! fail on preloading $traceData: $e');
			}
			progressMutex.acquire();
			loaded++;
			progressMutex.release();
		});
	}

	inline private static function preloadCharacter(char:String, ?prefixVocals:String)
	{
		try
		{
			var path:String = Paths.getPath('characters/$char.json', TEXT);
			#if MODS_ALLOWED
			if (!FileSystem.exists(path) && !Assets.exists(path, TEXT))
				return;
			var character:Dynamic = Json.parse(FileSystem.exists(path) ? File.getContent(path) : Assets.getText(path));
			#else
			if (!Assets.exists(path, TEXT))
				return;
			var character:Dynamic = Json.parse(Assets.getText(path));
			#end

			var isAnimateAtlas:Bool = false;
			var img:String = character.image;
			img = img.trim();
			#if flxanimate
			var animToFind:String = Paths.getPath('images/$img/Animation.json', TEXT);
			if (#if MODS_ALLOWED FileSystem.exists(animToFind) || #end Assets.exists(animToFind))
				isAnimateAtlas = true;
			#end

			if (!isAnimateAtlas)
			{
				var split:Array<String> = img.split(',');
				for (file in split)
				{
					imagesToPrepare.push(file.trim());
				}
			}
			#if flxanimate
			else
			{
				for (i in 0...10)
				{
					var st:String = '$i';
					if (i == 0)
						st = '';

					if (Paths.fileExists('images/$img/spritemap$st.png', IMAGE))
					{
						// trace('found Sprite PNG');
						imagesToPrepare.push('$img/spritemap$st');
						break;
					}
				}
			}
			#end

			if (prefixVocals != null && character.vocals_file != null && character.vocals_file.length > 0)
			{
				songsToPrepare.push(prefixVocals + "-" + character.vocals_file);
				if (char == PlayState.SONG.player1)
					dontPreloadDefaultVoices = true;
			}
		}
		catch (e:haxe.Exception)
		{
			trace(e.details());
		}
	}

	// thread safe sound loader
	static function preloadSound(key:String, ?path:String, ?modsAllowed:Bool = true, ?beepOnNull:Bool = true, ?stream:Bool = false):Null<Sound>
	{
		var file:String = Paths.getPath(Language.getFileTranslation(key) + '.${Paths.SOUND_EXT}', SOUND, path, modsAllowed);
		var cacheKey:String = stream ? file + '#stream' : file;

		// trace('precaching sound: $file');
		mutex.acquire();
		var needsLoad:Bool = !Paths.currentTrackedSounds.exists(cacheKey);
		mutex.release();
		if (needsLoad)
		{
			if (#if sys FileSystem.exists(file) || #end OpenFlAssets.exists(file, SOUND))
			{
				var sound:Sound = stream ? backend.AssetLoader.loadStreamedSound(file) : backend.AssetLoader.loadSound(file);
				if (sound != null)
				{
					#if funkin.vis
					var stage = PlayState.SONG != null ? PlayState.SONG.stage : null;
					if (stream && key.endsWith('/Inst') && (stage == 'phillyStreets' || stage == 'phillyBlazin'))
						backend.AssetLoader.prepareAnalyzer(sound);
					#end
					mutex.acquire();
					Paths.currentTrackedSounds.set(cacheKey, sound);
					soundsToWarm.push(sound);
					mutex.release();
				}
			}
			else if (beepOnNull)
			{
				trace('SOUND NOT FOUND: $key, PATH: $path');
				FlxG.log.error('SOUND NOT FOUND: $key, PATH: $path');
				return FlxAssets.getSound('flixel/sounds/beep');
			}
		}
		mutex.acquire();
		Paths.rememberAsset(cacheKey);
		mutex.release();

		return Paths.currentTrackedSounds.get(cacheKey);
	}

	// thread safe sound loader
	static function preloadGraphic(key:String):Null<BitmapData>
	{
		try
		{
			var requestKey:String = 'images/$key';
			#if TRANSLATIONS_ALLOWED requestKey = Language.getFileTranslation(requestKey); #end
			if (requestKey.lastIndexOf('.') < 0)
				requestKey += '.png';

			var file:String = Paths.getPath(requestKey, IMAGE);
			if (!Paths.currentTrackedAssets.exists(file))
			{
				if (#if sys FileSystem.exists(file) || #end OpenFlAssets.exists(file, IMAGE))
				{
					var bitmap:BitmapData = backend.AssetLoader.loadBitmap(file);

					if (bitmap != null)
					{
						mutex.acquire();
						requestedBitmaps.set(file, bitmap);
						originalBitmapKeys.set(file, requestKey);
						mutex.release();
						return bitmap;
					}
					trace('image failed to decode: $key');
				}
				else
					trace('no such image $key exists');
			}

			mutex.acquire();
			Paths.rememberAsset(file);
			mutex.release();
			var tracked:flixel.graphics.FlxGraphic = Paths.currentTrackedAssets.get(file);
			return (tracked != null) ? tracked.bitmap : null;
		}
		catch (e:haxe.Exception)
		{
			trace('ERROR! fail on preloading image $key');
		}

		return null;
	}
}

