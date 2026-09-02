package psychlua;

#if VIDEOS_ALLOWED
import hxvlc.flixel.FlxVideoSprite;
#end

class LuaVideo
{
	#if LUA_ALLOWED
	private static var activeVideos:Map<String, FlxVideoSprite> = new Map();
	private static var videoVolumes:Map<String, Float> = new Map();
	private static var videoFronts:Map<String, Bool> = new Map();

	private static var isDestroyed:Map<String, Bool> = new Map();
	private static var allowDestroy:Map<String, Bool> = new Map();

	public static function implement(funk:FunkinLua)
	{
		var lua = funk.lua;

		#if VIDEOS_ALLOWED
		Lua_helper.add_callback(lua, "precacheLuaVideoSprite",
			function(tag:String, path:String, ?x:Float = 0, ?y:Float = 0, ?volumeOrFront:Dynamic = 1.0, ?front:Bool = false)
			{
				if (tag == null || tag.trim() == '')
				{
					FunkinLua.luaTrace('precacheLuaVideoSprite: tag cannot be empty!', false, false, FlxColor.RED);
					return;
				}

				if (path == null || path.trim() == '')
				{
					FunkinLua.luaTrace('precacheLuaVideoSprite: path cannot be empty!', false, false, FlxColor.RED);
					return;
				}

				var options = parseLuaVideoArgs(volumeOrFront, front);
				forceRemoveLuaVideo(tag);
				createLuaVideo(tag, path, x, y, options.volume, options.front, funk, false);
			});

		Lua_helper.add_callback(lua, "playLuaVideoSprite",
			function(tag:String, ?path:String = null, ?x:Float = 0, ?y:Float = 0, ?volumeOrFront:Dynamic = 1.0, ?front:Bool = false)
			{
				if (tag == null || tag.trim() == '')
				{
					FunkinLua.luaTrace('playLuaVideoSprite: tag cannot be empty!', false, false, FlxColor.RED);
					return;
				}

				var variables = MusicBeatState.getVariables();
				var existingVideo = variables.get(tag);
				var options = parseLuaVideoArgs(volumeOrFront, front);

				if (existingVideo != null && Std.isOfType(existingVideo, FlxVideoSprite))
				{
					var videoSprite:FlxVideoSprite = cast existingVideo;
					var playFront:Bool = videoFronts.exists(tag) ? videoFronts.get(tag) : options.front;
					if (path != null && path.trim() != '')
					{
						videoVolumes.set(tag, options.volume);
						videoFronts.set(tag, options.front);
						videoSprite.x = x;
						videoSprite.y = y;
						playFront = options.front;
					}
					playStoredLuaVideo(tag, videoSprite, playFront);
					return;
				}

				if (path == null || path.trim() == '')
				{
					FunkinLua.luaTrace('playLuaVideoSprite: path cannot be empty!', false, false, FlxColor.RED);
					return;
				}

				if (existingVideo != null)
				{
					forceRemoveLuaVideo(tag);
				}

				createLuaVideo(tag, path, x, y, options.volume, options.front, funk, true);
			});

		Lua_helper.add_callback(lua, "pauseLuaVideo", function(tag:String)
		{
			var video = getLuaVideo(tag);
			if (video != null)
			{
				video.pause();
			}
		});

		Lua_helper.add_callback(lua, "resumeLuaVideo", function(tag:String)
		{
			var video = getLuaVideo(tag);
			if (video != null)
			{
				video.resume();
			}
		});

		Lua_helper.add_callback(lua, "removeLuaVideo", function(tag:String)
		{
			removeLuaVideo(tag);
		});

		Lua_helper.add_callback(lua, "forceRemoveLuaVideo", function(tag:String)
		{
			if (allowDestroy.exists(tag))
			{
				allowDestroy.set(tag, true); // Permitir destrucción inmediata
			}
			removeLuaVideo(tag);
		});

		Lua_helper.add_callback(lua, "luaVideoExists", function(tag:String):Bool
		{
			return getLuaVideo(tag) != null;
		});

		Lua_helper.add_callback(lua, "isLuaVideoPlaying", function(tag:String):Bool
		{
			var video = getLuaVideo(tag);
			if (video != null)
			{
				return video.bitmap.isPlaying;
			}
			return false;
		});

		Lua_helper.add_callback(lua, "setLuaVideoVolume", function(tag:String, volume:Float)
		{
			setLuaVideoVolume(tag, volume);
		});

		Lua_helper.add_callback(lua, "getLuaVideoVolume", function(tag:String):Float
		{
			return getLuaVideoVolume(tag);
		});

		Lua_helper.add_callback(lua, "getLuaVideoDuration", function(tag:String):Float
		{
			var video = getLuaVideo(tag);
			if (video != null)
			{
				return haxe.Int64.toInt(video.bitmap.duration) / 1000.0;
			}
			return 0;
		});

		Lua_helper.add_callback(lua, "getLuaVideoTime", function(tag:String):Float
		{
			var video = getLuaVideo(tag);
			if (video != null)
			{
				return haxe.Int64.toInt(video.bitmap.time) / 1000.0;
			}
			return 0;
		});
		#else
		Lua_helper.add_callback(lua, "playLuaVideoSprite",
			function(tag:String, path:String, ?x:Float = 0, ?y:Float = 0, ?volume:Float = 1.0, ?front:Bool = false)
			{
				FunkinLua.luaTrace('playLuaVideoSprite: Video support is not enabled!', false, false, FlxColor.RED);
			});
		#end
	}

	#if VIDEOS_ALLOWED
	private static function parseLuaVideoArgs(volumeOrFront:Dynamic, front:Bool):Dynamic
	{
		var volume:Float = 1.0;
		if (Std.isOfType(volumeOrFront, Bool))
		{
			front = cast volumeOrFront;
		}
		else if (volumeOrFront != null)
		{
			volume = Std.parseFloat(Std.string(volumeOrFront));
			if (Math.isNaN(volume))
				volume = 1.0;
		}

		return {volume: clampVideoVolume(volume), front: front};
	}

	private static function createLuaVideo(tag:String, path:String, x:Float, y:Float, volume:Float, front:Bool, funk:FunkinLua, autoPlay:Bool):Void
	{
		isDestroyed.set(tag, false);
		allowDestroy.set(tag, false);
		videoVolumes.set(tag, volume);
		videoFronts.set(tag, front);

		var videoSprite:FlxVideoSprite = new FlxVideoSprite();
		videoSprite.active = false;
		videoSprite.visible = autoPlay;
		videoSprite.antialiasing = ClientPrefs.data.antialiasing;
		videoSprite.cameras = [PlayState.instance.camHUD];
		videoSprite.x = x;
		videoSprite.y = y;

		videoSprite.bitmap.onFormatSetup.add(function()
		{
			videoSprite.updateHitbox();
			videoSprite.x = x;
			videoSprite.y = y;
			applyStoredLuaVideoVolume(tag, videoSprite);
			trace('Video "$tag" loaded successfully');
		});

		videoSprite.bitmap.onPlaying.add(function()
		{
			pulseLuaVideoVolume(tag, videoSprite);
		});

		videoSprite.bitmap.onEndReached.add(function()
		{
			funk.call('onVideoFinished', [tag]);
			removeLuaVideo(tag);
		});

		var videoOptions:Array<String> = [
			':drop-late-frames',
			':skip-frames',
			':avcodec-fast',
			':avcodec-skiploopfilter=4'
		];
		if (volume <= 0)
		{
			videoOptions.push(':no-audio');
		}

		if (!videoSprite.load(backend.Paths.video(path), videoOptions))
		{
			FunkinLua.luaTrace('LuaVideo: could not load video "$path"', false, false, FlxColor.RED);
			videoSprite.destroy();
			isDestroyed.remove(tag);
			allowDestroy.remove(tag);
			videoVolumes.remove(tag);
			videoFronts.remove(tag);
			return;
		}
		applyStoredLuaVideoVolume(tag, videoSprite);

		new flixel.util.FlxTimer().start(2.0, function(tmr:flixel.util.FlxTimer)
		{
			allowDestroy.set(tag, true);
		});

		var variables = MusicBeatState.getVariables();
		variables.set(tag, videoSprite);
		activeVideos.set(tag, videoSprite);

		if (autoPlay)
		{
			playStoredLuaVideo(tag, videoSprite, front);
		}
	}

	private static function playStoredLuaVideo(tag:String, videoSprite:FlxVideoSprite, front:Bool):Void
	{
		if (videoSprite == null || videoSprite.bitmap == null)
			return;

		videoSprite.visible = true;
		addLuaVideoToState(videoSprite, front);
		applyStoredLuaVideoVolume(tag, videoSprite);

		new flixel.util.FlxTimer().start(0.001, function(tmr:flixel.util.FlxTimer)
		{
			if (videoSprite != null && videoSprite.bitmap != null)
			{
				videoSprite.play();
				pulseLuaVideoVolume(tag, videoSprite);
			}
		});
	}

	private static function addLuaVideoToState(videoSprite:FlxVideoSprite, front:Bool):Void
	{
		if (PlayState.instance == null || PlayState.instance.members == null)
			return;
		if (PlayState.instance.members.contains(videoSprite))
			return;

		if (front)
		{
			PlayState.instance.add(videoSprite);
		}
		else
		{
			var position:Int = PlayState.instance.members.indexOf(PlayState.instance.gfGroup);
			if (PlayState.instance.members.indexOf(PlayState.instance.boyfriendGroup) < position)
				position = PlayState.instance.members.indexOf(PlayState.instance.boyfriendGroup);
			if (PlayState.instance.members.indexOf(PlayState.instance.dadGroup) < position)
				position = PlayState.instance.members.indexOf(PlayState.instance.dadGroup);

			PlayState.instance.insert(position, videoSprite);
		}
	}

	private static function forceRemoveLuaVideo(tag:String):Void
	{
		if (allowDestroy.exists(tag))
		{
			allowDestroy.set(tag, true);
		}
		removeLuaVideo(tag);
	}

	private static function getLuaVideo(tag:String):FlxVideoSprite
	{
		var variables = MusicBeatState.getVariables();
		var sprite = variables.get(tag);
		if (sprite != null && Std.isOfType(sprite, FlxVideoSprite))
		{
			return cast sprite;
		}

		if (sprite == null)
		{
			FunkinLua.luaTrace('getLuaVideo: Video "$tag" does not exist!', false, false, FlxColor.RED);
		}
		else
		{
			FunkinLua.luaTrace('getLuaVideo: "$tag" is not a video!', false, false, FlxColor.RED);
		}

		return null;
	}

	private static function removeLuaVideo(tag:String):Void
	{
		if (isDestroyed.exists(tag) && isDestroyed.get(tag))
		{
			return;
		}

		if (allowDestroy.exists(tag) && !allowDestroy.get(tag))
		{
			trace('LuaVideo: Cannot destroy "$tag" yet (not ready)');
			return;
		}

		var variables = MusicBeatState.getVariables();
		var video = variables.get(tag);

		if (video == null || !Std.isOfType(video, FlxVideoSprite))
		{
			videoVolumes.remove(tag);
			videoFronts.remove(tag);
			return;
		}

		isDestroyed.set(tag, true);

		var videoSprite:FlxVideoSprite = cast video;

		variables.remove(tag);
		activeVideos.remove(tag);
		videoVolumes.remove(tag);
		videoFronts.remove(tag);

		if (videoSprite.bitmap != null)
		{
			videoSprite.bitmap.onEndReached.removeAll();
			videoSprite.bitmap.onFormatSetup.removeAll();
			videoSprite.bitmap.onPlaying.removeAll();
		}

		if (PlayState.instance != null && PlayState.instance.members != null)
		{
			if (PlayState.instance.members.contains(videoSprite))
			{
				PlayState.instance.remove(videoSprite);
			}
		}

		videoSprite.destroy();

		isDestroyed.remove(tag);
		allowDestroy.remove(tag);

		trace('Video "$tag" destroyed');
	}

	private static function setLuaVideoVolume(tag:String, volume:Float):Void
	{
		var video = getLuaVideo(tag);
		if (video != null)
		{
			volume = clampVideoVolume(volume);
			videoVolumes.set(tag, volume);
			pulseLuaVideoVolume(tag, video);
			if (volume <= 0)
			{
				if (video.bitmap != null && video.bitmap.isPlaying)
				{
					video.pause();
					video.resume();
					pulseLuaVideoVolume(tag, video);
				}
				FunkinLua.luaTrace('setLuaVideoVolume: "$tag" muted. For safest silence, use playLuaVideoSprite("'
					+ tag
					+ '", "videoName", x, y, 0) so VLC loads without audio.',
					false, false, FlxColor.YELLOW);
			}
		}
	}

	private static function getLuaVideoVolume(tag:String):Float
	{
		var video = getLuaVideo(tag);
		if (video != null)
		{
			if (videoVolumes.exists(tag))
				return videoVolumes.get(tag);
			if (video.bitmap != null)
				return clampVideoVolume(video.bitmap.volumeAdjust);
		}
		return 0;
	}

	private static function applyStoredLuaVideoVolume(tag:String, video:FlxVideoSprite):Void
	{
		applyLuaVideoVolume(video, videoVolumes.exists(tag) ? videoVolumes.get(tag) : 1);
	}

	private static function pulseLuaVideoVolume(tag:String, video:FlxVideoSprite):Void
	{
		applyStoredLuaVideoVolume(tag, video);

		new flixel.util.FlxTimer().start(0.05, function(tmr:flixel.util.FlxTimer)
		{
			if (video == null || video.bitmap == null || !videoVolumes.exists(tag))
			{
				tmr.cancel();
				return;
			}
			applyStoredLuaVideoVolume(tag, video);
		}, 20);
	}

	private static function applyLuaVideoVolume(video:FlxVideoSprite, volume:Float):Void
	{
		if (video == null || video.bitmap == null)
			return;

		volume = clampVideoVolume(volume);
		video.bitmap.volumeAdjust = volume;
		video.bitmap.volume = (flixel.FlxG.sound.muted ? 0 : flixel.FlxG.sound.volume) * volume;

		if (volume <= 0)
		{
			video.bitmap.audioTrack = -1;
		}
		else if (video.bitmap.audioTrack < 0 && video.bitmap.audioTrackCount > 0)
		{
			video.bitmap.audioTrack = 1;
		}
	}

	private static function clampVideoVolume(volume:Float):Float
	{
		if (Math.isNaN(volume))
			return 1;
		return Math.max(0, Math.min(1, volume));
	}

	public static function pauseAll():Void
	{
		#if VIDEOS_ALLOWED
		for (tag => video in activeVideos)
		{
			if (video != null && video.bitmap.isPlaying)
			{
				video.pause();
			}
		}
		#end
	}

	public static function resumeAll():Void
	{
		#if VIDEOS_ALLOWED
		for (tag => video in activeVideos)
		{
			if (video != null && !video.bitmap.isPlaying)
			{
				video.resume();
			}
		}
		#end
	}

	public static function clearAll():Void
	{
		#if VIDEOS_ALLOWED
		var tags:Array<String> = [];
		for (tag in activeVideos.keys())
		{
			tags.push(tag);
		}

		for (tag in tags)
		{
			removeLuaVideo(tag);
		}

		activeVideos.clear();
		videoVolumes.clear();
		videoFronts.clear();
		#end
	}
	#end
	#end
}

