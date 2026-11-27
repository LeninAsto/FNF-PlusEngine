package scripting;

import flixel.graphics.frames.FlxFrame;
import flixel.system.FlxAssets.FlxShader;
import haxe.ds.ObjectMap;
import objects.Note;
import shaders.ColorSwap.ColorSwapShader;
import shaders.RGBPalette.RGBPaletteShader;
import shaders.ErrorHandledShader.ErrorHandledRuntimeShader;
import states.PlayState;

@:keep
class NoteShaderBatch {
    final state:PlayState;
    final shaderName:String;
    final entries:ObjectMap<Note, NoteShaderEntry> = new ObjectMap();
    final caches:ObjectMap<FlxShader, ObjectMap<FlxFrame, NoteShaderSlot>> = new ObjectMap();
    final plainCache:ObjectMap<FlxFrame, NoteShaderSlot> = new ObjectMap();
    final activeSlots:Array<NoteShaderSlot> = [];
    final expired:Array<Note> = [];
    var cleanupBeat:Float = Math.NEGATIVE_INFINITY;
    var active:Bool = false;
    var frameId:Int = 0;

    public function new(state:PlayState, shaderName:String) {
        this.state = state;
        this.shaderName = shaderName;
    }

    public function update(enabled:Bool, mode:Float, amp:Float, beat:Float, shuffle:Bool):Void {
        if (!enabled) {
            if (active) restore();
            return;
        }
        active = true;
        frameId++;
        activeSlots.resize(0);
        if (beat >= cleanupBeat || beat < cleanupBeat - 1) {
            cleanupBeat = beat + 0.5;
            expired.resize(0);
            for (note in entries.keys()) {
                final entry = entries.get(note);
                if (!note.exists || !note.alive || note.shader != entry.slot.shader) expired.push(note);
            }
            for (note in expired) restoreNote(note);
        }
        for (note in state.notes.members) {
            if (note == null || !note.exists || !note.alive || note.frame == null) continue;
            var entry = entries.get(note);
            if (entry != null && note.shader != entry.slot.shader) {
                entries.remove(note);
                entry = null;
            }
            if (entry == null) {
                final original = note.shader;
                if (original != null && !Std.isOfType(original, RGBPaletteShader) && !Std.isOfType(original, ColorSwapShader)) continue;
                if (Std.isOfType(original, ColorSwapShader)) {
                    final hsv:ColorSwapShader = cast original;
                    if (hsv.awesomeOutline.value != null && hsv.awesomeOutline.value[0]) continue;
                }
                final slot = getSlot(original, note.frame);
                if (slot == null) continue;
                entry = {original: original, frame: note.frame, slot: slot};
                entries.set(note, entry);
                note.shader = slot.shader;
            } else if (entry.frame != note.frame) {
                final slot = getSlot(entry.original, note.frame);
                if (slot == null) continue;
                entry.frame = note.frame;
                entry.slot = slot;
                note.shader = slot.shader;
            }
            if (entry.slot.lastFrame != frameId) {
                entry.slot.lastFrame = frameId;
                activeSlots.push(entry.slot);
            }
        }
        final seed = Math.floor(beat * 5);
        for (slot in activeSlots) {
            final shader = slot.shader;
            shader.setFloat('effectMode', mode);
            shader.setFloat('effectAmp', amp);
            shader.setFloat('effectTime', beat);
            shader.setFloat('effectSeed', seed);
            shader.setFloat('shuffleEnabled', shuffle ? 1 : 0);
            if (Std.isOfType(slot.original, RGBPaletteShader)) {
                final rgb:RGBPaletteShader = cast slot.original;
                shader.setFloatArray('paletteR', rgb.r.value);
                shader.setFloatArray('paletteG', rgb.g.value);
                shader.setFloatArray('paletteB', rgb.b.value);
                if (rgb.mult.value != null && rgb.mult.value.length > 0) shader.setFloat('paletteMix', rgb.mult.value[0]);
            } else if (Std.isOfType(slot.original, ColorSwapShader)) {
                final hsv:ColorSwapShader = cast slot.original;
                shader.setFloatArray('hsvValue', hsv.uTime.value);
            }
        }
    }

    function getSlot(original:FlxShader, frame:FlxFrame):NoteShaderSlot {
        var cache = original == null ? plainCache : caches.get(original);
        if (cache == null) {
            cache = new ObjectMap();
            caches.set(original, cache);
        }
        var slot = cache.get(frame);
        if (slot != null) return slot;
        final shader = state.createRuntimeShader(shaderName);
        if (shader == null) return null;
        final uv = frame.uv;
        shader.setFloatArray('noteBounds', [uv.left, uv.top, uv.right, uv.bottom]);
        shader.setFloat('paletteEnabled', Std.isOfType(original, RGBPaletteShader) ? 1 : 0);
        shader.setFloat('hsvEnabled', Std.isOfType(original, ColorSwapShader) ? 1 : 0);
        slot = {shader: shader, original: original, lastFrame: -1};
        cache.set(frame, slot);
        return slot;
    }

    function restoreNote(note:Note):Void {
        final entry = entries.get(note);
        if (entry == null) return;
        if (note.shader == entry.slot.shader) note.shader = entry.original;
        entries.remove(note);
    }

    public function restore():Void {
        expired.resize(0);
        for (note in entries.keys()) expired.push(note);
        for (note in expired) restoreNote(note);
        active = false;
    }
}

private typedef NoteShaderSlot = {
    var shader:ErrorHandledRuntimeShader;
    var original:FlxShader;
    var lastFrame:Int;
}

private typedef NoteShaderEntry = {
    var original:FlxShader;
    var frame:FlxFrame;
    var slot:NoteShaderSlot;
}
