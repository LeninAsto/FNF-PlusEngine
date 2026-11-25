package psychlua;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.group.FlxSpriteGroup;
import objects.StrumNote;

/** Applies a receptor's projected orientation to popup sprites at their normal position. */
@:keep
class Combo3DFollower {
    var group:FlxSpriteGroup;
    var receptors:FlxTypedGroup<StrumNote>;
    var field:Int;
    final frame:Dynamic = {x: 0.0, y: 0.0, scaleX: 1.0, scaleY: 1.0, angle: 0.0};
    final transformed:Array<FlxSprite> = [];
    var pivotX:Float = 0;
    var pivotY:Float = 0;
    var scaleX:Float = 1;
    var scaleY:Float = 1;
    var cosine:Float = 1;
    var sine:Float = 0;
    var angle:Float = 0;

    public function new(group:FlxSpriteGroup, receptors:FlxTypedGroup<StrumNote>, field:Int = 0) {
        this.group = group;
        this.receptors = receptors;
        this.field = field;
    }

    /** Call before the sprites update or are recycled. Safe to call more than once. */
    public function reset():Void {
        for (sprite in transformed) {
            if (sprite == null || sprite.scale == null) continue;
            final dx = sprite.x - pivotX;
            final dy = sprite.y - pivotY;
            sprite.x = pivotX + (cosine * dx + sine * dy) / scaleX;
            sprite.y = pivotY + (-sine * dx + cosine * dy) / scaleY;
            sprite.scale.x /= scaleX;
            sprite.scale.y /= scaleY;
            sprite.angle -= angle;
        }
        transformed.resize(0);
    }

    /** Call after modchart updates; returns false when there is nothing to transform. */
    public function update(lane:Int):Bool {
        reset();
        if (group == null || receptors == null || lane < 0 || lane >= receptors.members.length) return false;
        var anyVisible = false;
        for (sprite in group.members) {
            if (sprite != null && sprite.exists && sprite.visible && sprite.alpha > 0) {
                anyVisible = true;
                break;
            }
        }
        if (!anyVisible) return false;
        final receptor = receptors.members[lane];
        if (receptor == null || !ModchartFunctions.getRenderedStrumFrame(receptor, field, frame)) return false;
        scaleX = frame.scaleX;
        scaleY = frame.scaleY;
        angle = frame.angle;
        final radians = angle * Math.PI / 180;
        cosine = Math.cos(radians);
        sine = Math.sin(radians);
        // The default popup layout is centered around this point; don't follow the receptor position.
        pivotX = group.x + FlxG.width * 0.35;
        pivotY = group.y + FlxG.height * 0.5;
        for (sprite in group.members) {
            if (sprite == null || !sprite.exists || !sprite.visible) continue;
            final dx = (sprite.x - pivotX) * scaleX;
            final dy = (sprite.y - pivotY) * scaleY;
            sprite.x = pivotX + cosine * dx - sine * dy;
            sprite.y = pivotY + sine * dx + cosine * dy;
            sprite.scale.x *= scaleX;
            sprite.scale.y *= scaleY;
            sprite.angle += angle;
            transformed.push(sprite);
        }
        return true;
    }

    public function destroy():Void {
        reset();
        group = null;
        receptors = null;
    }
}
