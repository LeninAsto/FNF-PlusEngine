# hxCodec Compatibility Wrappers for hxvlc

This folder contains compatibility wrappers that emulate the **hxCodec** API using **hxvlc 2.2.5** internally.

## Purpose

These wrappers allow **Psych Engine 0.7.3** mods that used hxCodec to work seamlessly with hxvlc without requiring code changes. They are automatically available when using **SScript (legacy mode)** in PlusEngine.

## Available Classes

### FlxVideo
Emulates `hxcodec.flixel.FlxVideo` - Direct video playback using FlxG display.

**Usage (legacy mods):**
```haxe
var video = new FlxVideo();
video.play('videos/myVideo.mp4', false); // path, shouldLoop
video.autoResize = true;
```

### FlxVideoSprite
Emulates `hxcodec.flixel.FlxVideoSprite` - Video playback as a FlxSprite.

**Usage (legacy mods):**
```haxe
var videoSprite = new FlxVideoSprite(0, 0);
videoSprite.play('videos/myVideo.mp4', false);
add(videoSprite);
```

### Video
Internal wrapper for `hxvlc.openfl.Video` with hxCodec-compatible API.

## Key Differences from hxCodec

### Method Signatures
- **hxCodec**: `play(path:String, shouldLoop:Bool):Int`
- **Wrapper**: `play(location:String, shouldLoop:Bool):Bool`

The wrapper returns `Bool` to indicate success/failure, matching modern expectations.

### Events
- **hxCodec**: `onOpening`, `onTextureSetup`, `onEndReached`
- **hxvlc 2.2.5**: `onOpening`, `onFormatSetup`, `onEndReached`

The wrapper handles `onFormatSetup` (hxvlc) internally, which is equivalent to `onTextureSetup` (hxCodec).

### Volume
- **hxCodec**: `volume:Int` (0-100) 
- **hxvlc**: `volume:Int` (0-100)

Both use the same scale, no conversion needed.

### Playback Flow
**hxCodec:**
```haxe
video.play('path.mp4'); // Loads and plays immediately
```

**hxvlc (internal):**
```haxe
video.load('path.mp4'); // Loads media
video.resume();         // Starts playback
```

The wrapper handles this automatically - calling `play()` will load and start playback.

## Legacy Mod Compatibility

These wrappers are automatically exposed in **SScript** mode (`ClientPrefs.data.useSScriptCompat = true`):

```haxe
// In SScript.hx preset():
set('FlxVideo', objects.wrappers.legacy.FlxVideo);
set('FlxVideoSprite', objects.wrappers.legacy.FlxVideoSprite);
```

Old Psych 0.7.3 mods can use these classes without modification.

## Modern Alternative

For new mods using **HScript** (hscript-iris), use the native hxvlc classes instead:

```haxe
// Modern approach (HScript mode)
import hxvlc.flixel.FlxVideoSprite; // Native hxvlc

var video = new FlxVideoSprite(0, 0);
if (video.load('videos/myVideo.mp4'))
    video.resume();
```

## Implementation Notes

### Thread Safety
- Uses `location` property to track current video path for loop functionality
- Properly cleans up event listeners on dispose

### Auto-pause Support
- Respects `FlxG.autoPause` setting
- Automatically pauses/resumes on focus lost/gained

### Loop Implementation
```haxe
if (shouldLoop) {
    bitmap.onEndReached.add(function() {
        bitmap.stop();
        haxe.Timer.delay(function() {
            if (bitmap != null && bitmap.location != null) {
                bitmap.load(bitmap.location);
                bitmap.resume();
            }
        }, 50);
    });
}
```

The 50ms delay prevents race conditions when restarting video playback.

## Backward Compatibility with Old Wrappers

The legacy wrappers `MP4Handler` and `VideoHandler` (located in parent `wrappers` folder) are also exposed in SScript for maximum compatibility:

```haxe
set('MP4Handler', objects.wrappers.MP4Handler);
set('VideoHandler', objects.wrappers.VideoHandler);
```

These older wrappers internally use **hxvlc** but have different APIs tailored to specific Psych Engine versions.

---

**Summary:** These wrappers provide seamless hxCodec → hxvlc migration for legacy Psych 0.7.3 mods while maintaining modern hxvlc for new content.
