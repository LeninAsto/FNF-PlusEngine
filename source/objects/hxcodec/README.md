# hxCodec Compatibility Wrappers for hxvlc

This directory contains complete compatibility wrappers that emulate **all versions** of **hxCodec** using **hxvlc 2.2.5** internally.

## 📁 Directory Structure

```
wrappers/
├── legacy/          # Modern hxCodec (FlxVideo, FlxVideoSprite)
│   ├── FlxVideo.hx
│   ├── FlxVideoSprite.hx
│   ├── Video.hx
│   └── README.md
├── v2/              # hxCodec 2.x (VideoHandler, VideoSprite)
│   ├── VideoHandler.hx
│   └── VideoSprite.hx
├── v3/              # hxCodec 3.x (MP4Handler, MP4Sprite)
│   ├── MP4Handler.hx
│   └── MP4Sprite.hx
├── MP4Handler.hx    # Legacy wrapper (deprecated, use v3/)
├── VideoHandler.hx  # Legacy wrapper (deprecated, use v2/)
└── README.md        # This file
```

## 🎯 Which Version Should I Use?

### For SScript (Psych 0.7.3 Compatibility Mode)

**All versions are automatically available** when using SScript. Your mod can use any API:

```haxe
// Modern API (recommended for new content)
var video = new FlxVideoSprite(0, 0);
video.play('videos/cutscene.mp4', false);

// hxCodec 2.x API (intermediate mods)
var handler = new VideoHandler();
handler.playVideo('videos/video.mp4', false, true);

// hxCodec 3.x API (oldest mods)
var mp4 = new MP4Handler();
mp4.playVideo('videos/intro.mp4', false, true);
```

### For HScript (Modern hscript-iris Mode)

Use native **hxvlc** classes directly:

```haxe
import hxvlc.flixel.FlxVideoSprite;

var video = new FlxVideoSprite(0, 0);
if (video.load('videos/cutscene.mp4'))
    video.resume();
```

## 📚 API Reference

### Legacy (Modern hxCodec)

#### FlxVideo
Direct video playback using OpenFL display.

```haxe
var video = new FlxVideo();
video.autoResize = true;
video.play('path.mp4', loop); // Returns Bool

// Events
video.onOpening.add(function() { trace('Opening'); });
video.onEndReached.add(function() { trace('Ended'); });
video.onFormatSetup.add(function() { trace('Ready'); });

// Methods
video.pause();
video.resume();
video.stop();
video.dispose();
```

#### FlxVideoSprite
Video playback as a FlxSprite.

```haxe
var sprite = new FlxVideoSprite(x, y);
sprite.play('path.mp4', loop); // Returns Bool
add(sprite);

// Access internal video
sprite.bitmap.volume = 50; // 0-100
sprite.bitmap.isPlaying; // Bool
```

---

### v2 (hxCodec 2.x)

#### VideoHandler
VLCBitmap-based video handler.

```haxe
var handler = new VideoHandler(IndexModifier);
handler.canSkip = true;
handler.skipKeys = [FlxKey.SPACE];
handler.canUseSound = true;
handler.canUseAutoResize = true;

handler.openingCallback = function() { trace('Opening'); };
handler.finishCallback = function() { trace('Finished'); };

handler.playVideo(path, loop, pauseMusic);

// Properties
handler.isPlaying; // Bool
handler.isDisplaying; // Bool
handler.videoWidth; // Int
handler.videoHeight; // Int
handler.volume; // Int (0-100)

// Methods
handler.pause();
handler.resume();
handler.dispose();
```

#### VideoSprite
Sprite wrapper for VideoHandler.

```haxe
var sprite = new VideoSprite(x, y);
sprite.canvasWidth = 1280;
sprite.canvasHeight = 720;

sprite.openingCallback = function() { };
sprite.graphicLoadedCallback = function() { };
sprite.finishCallback = function() { };

sprite.playVideo(path, loop, pauseMusic);
add(sprite);

// Access handler
sprite.bitmap.pause();
sprite.bitmap.resume();
```

---

### v3 (hxCodec 3.x - Oldest)

#### MP4Handler
Original VLC-based video handler.

```haxe
var mp4 = new MP4Handler(width, height, autoScale);

mp4.readyCallback = function() { trace('Ready'); };
mp4.finishCallback = function() { trace('Done'); };

mp4.playVideo(path, repeat, pauseMusic);
mp4.repeat = -1; // Infinite loop (-1), once (0), or n times (>0)

// Methods
mp4.pause();
mp4.resume();
mp4.finishVideo(); // Force finish
mp4.dispose();
```

#### MP4Sprite
Sprite wrapper for MP4Handler.

```haxe
var sprite = new MP4Sprite(x, y, width, height, autoScale);

sprite.readyCallback = function() { };
sprite.finishCallback = function() { };

sprite.playVideo(path, repeat, pauseMusic);
add(sprite);

// Methods
sprite.pause();
sprite.resume();
```

## 🔄 Version Comparison

| Feature | Legacy (FlxVideo) | v2 (VideoHandler) | v3 (MP4Handler) |
|---------|-------------------|-------------------|-----------------|
| **Base Class** | hxvlc.openfl.Video | hxvlc.openfl.Video | hxvlc.openfl.Video |
| **Skip Support** | ❌ No | ✅ Yes (keyboard) | ✅ Yes (SPACE/ENTER) |
| **Auto Resize** | ✅ Yes | ✅ Yes | ⚠️ Manual | 
| **Loop Method** | Boolean | Boolean | Int (-1=infinite) |
| **Events** | onOpening, onEndReached, onFormatSetup | Callbacks | Callbacks |
| **Return Type** | `play():Bool` | `playVideo():Void` | `playVideo():Void` |
| **Volume Range** | 0-100 | 0-100 | 0-100 |
| **Canvas Size** | Auto | calcSize() | Constructor params |

## 🚀 Usage Examples

### Example 1: Simple Cutscene (Modern API)

```haxe
function onCreate() {
    var cutscene = new FlxVideoSprite(0, 0);
    cutscene.play('videos/intro.mp4', false);
    
    cutscene.bitmap.onEndReached.add(function() {
        startCountdown();
    });
    
    add(cutscene);
}
```

### Example 2: Background Video (v2 API)

```haxe
function onCreate() {
    var bg = new VideoSprite(0, 0);
    bg.canvasWidth = 1280;
    bg.canvasHeight = 720;
    
    bg.finishCallback = function() {
        remove(bg);
    };
    
    bg.playVideo('videos/background.mp4', true, false);
    insert(0, bg); // Behind everything
}
```

### Example 3: Skippable Intro (v2 API)

```haxe
function onCreate() {
    var handler = new VideoHandler();
    handler.canSkip = true;
    handler.skipKeys = [FlxKey.SPACE, FlxKey.ENTER];
    
    handler.finishCallback = function() {
        startCountdown();
    };
    
    handler.playVideo('videos/intro.mp4', false, true);
}
```

### Example 4: Looping Video (v3 API)

```haxe
function onCreate() {
    var mp4 = new MP4Sprite(0, 0, 1280, 720);
    mp4.readyCallback = function() {
        debugPrint('Video ready!');
    };
    
    mp4.playVideo('videos/loop.mp4', true, false);
    add(mp4);
}
```

## 🔧 Integration with SScript

All wrappers are automatically exposed in **SScript** ([SScript.hx](../psychlua/SScript.hx#L124-L135)):

```haxe
// Modern hxCodec API (FlxVideo/FlxVideoSprite)
set('FlxVideo', objects.wrappers.legacy.FlxVideo);
set('FlxVideoSprite', objects.wrappers.legacy.FlxVideoSprite);

// hxCodec 2.x API (VideoHandler/VideoSprite)
set('VideoHandler', objects.wrappers.v2.VideoHandler);
set('VideoSprite', objects.wrappers.v2.VideoSprite);

// hxCodec 3.x API (MP4Handler/MP4Sprite)
set('MP4Handler', objects.wrappers.v3.MP4Handler);
set('MP4Sprite', objects.wrappers.v3.MP4Sprite);
```

## ⚠️ Important Notes

### Skip Functionality
- **Legacy (FlxVideo/FlxVideoSprite)**: Skip disabled by default
- **v2 (VideoHandler)**: Fully configurable with `canSkip` and `skipKeys`
- **v3 (MP4Handler)**: Hardcoded to SPACE/ENTER

### Volume Handling
All wrappers sync with FlxG.sound.volume automatically:
```haxe
// Internal volume calculation
volume = Std.int(FlxG.sound.volume * 100);
```

### Memory Management
Always call `dispose()` or let `finishCallback` handle cleanup:
```haxe
handler.finishCallback = function() {
    handler.dispose();
    // Continue game logic
};
```

### Path Resolution
All wrappers automatically check `Sys.getCwd() + path`:
```haxe
// These are equivalent:
video.play('videos/test.mp4');
video.play(Sys.getCwd() + 'videos/test.mp4');
```

## 🐛 Troubleshooting

### Video doesn't play
1. Check file exists: `FileSystem.exists(path)`
2. Verify hxvlc is installed: `#if hxvlc`
3. Check console for error messages

### Video plays but no sound
1. Check `FlxG.sound.muted` is false
2. Verify `canUseSound = true` (v2)
3. Check FlxG.sound.volume > 0

### Video loops incorrectly
- **Legacy/v2**: Use boolean `loop` parameter
- **v3**: Set `mp4.repeat = -1` for infinite loop

### Skip doesn't work
- **Legacy**: Skip is disabled by design
- **v2**: Check `canSkip = true` and `skipKeys` array
- **v3**: Only SPACE/ENTER supported

## 📝 License

These wrappers are part of FNF-PlusEngine and follow the same license.

---

**Made with ❤️ for Psych Engine mod compatibility**
