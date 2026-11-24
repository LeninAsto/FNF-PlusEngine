package backend;

import away3d.containers.View3D;
import away3d.entities.Mesh;
import away3d.materials.TextureMaterial;
import away3d.textures.BitmapTexture;
import openfl.display.BitmapData;
import openfl.geom.Rectangle;
import openfl.display.BlendMode;
import away3d.cameras.lenses.PerspectiveLens;
import away3d.primitives.PlaneGeometry;
import flixel.FlxG;
import openfl.geom.Vector3D;
import openfl.Lib;

@:keep
class AwayScene {
    var view:View3D;
    var floor:Mesh;
    var plane:PlaneGeometry;
    var material:TextureMaterial;
    var texture:BitmapTexture;
    var pixels:BitmapData;
    var flashMesh:Mesh;
    var flashPlane:PlaneGeometry;
    var flashMaterial:TextureMaterial;
    var flashTextures:Array<BitmapTexture> = [];
    final target:Vector3D = new Vector3D(0, 0, 800);
    var failed:Bool = false;
    var floorColor:Int = -1;

    public function new() {
        view = new View3D();
        view.width = Lib.current.stage.stageWidth;
        view.height = Lib.current.stage.stageHeight;
        view.backgroundColor = 0x080817;
        view.backgroundAlpha = 1;
        view.camera.lens = new PerspectiveLens(60);
        view.camera.z = -1000;
        view.camera.y = 500;
        view.camera.lookAt(target);
        plane = new PlaneGeometry(4800, 6000, 24, 24, true, true);
        pixels = new BitmapData(64, 64, false, 0x071A10);
        pixels.fillRect(new Rectangle(0, 0, 64, 2), 0x2CA65C);
        pixels.fillRect(new Rectangle(0, 0, 2, 64), 0x2CA65C);
        texture = new BitmapTexture(pixels);
        material = new TextureMaterial(texture, true, true);
        material.bothSides = true;
        plane.scaleUV(20, 24);
        floor = new Mesh(plane, material);
        floor.y = -350;
        floor.z = 1600;
        view.scene.addChild(floor);
        for (name in ['line/aya1', 'line/aya2']) {
            var graphic = Paths.image(name, null, false);
            if (graphic != null && graphic.bitmap != null) flashTextures.push(new BitmapTexture(graphic.bitmap));
        }
        if (flashTextures.length == 2) {
            flashPlane = new PlaneGeometry(4800, 6000, 1, 1, true, true);
            flashPlane.scaleUV(16, 16);
            flashMaterial = new TextureMaterial(flashTextures[0], false, true);
            flashMaterial.bothSides = true;
            flashMaterial.blendMode = BlendMode.ADD;
            flashMaterial.alpha = 0;
            flashMesh = new Mesh(flashPlane, flashMaterial);
            flashMesh.y = floor.y + 2;
            flashMesh.z = floor.z;
            view.scene.addChild(flashMesh);
        }
        view.visible = false;
        Lib.current.stage.addChildAt(view, 0);
        if (view.stage3DProxy != null) view.stage3DProxy.visible = false;
    }

    public function update(beat:Float, active:Bool, x:Float, y:Float, z:Float, pitch:Float, yaw:Float, roll:Float):Bool {
        if (view == null) return false;
        view.visible = active && !failed;
        if (view.stage3DProxy != null) view.stage3DProxy.visible = active && !failed;
        if (!active || failed) return false;
        view.width = Lib.current.stage.stageWidth;
        view.height = Lib.current.stage.stageHeight;
        var second = beat >= 454;
        var color = second ? 0xCC3333 : 0x2CA65C;
        if (color != floorColor) {
            floorColor = color;
            pixels.fillRect(new Rectangle(0, 0, 64, 64), 0x07100C);
            pixels.fillRect(new Rectangle(0, 0, 64, 2), color);
            pixels.fillRect(new Rectangle(0, 0, 2, 64), color);
            texture.invalidateContent();
        }
        view.camera.x = x * 0.35;
        view.camera.y = 350 - y * 0.18;
        view.camera.z = -1000 - z * 0.35;
        var heading = yaw * Math.PI / 180;
        var tilt = pitch * Math.PI / 180;
        target.setTo(view.camera.x + Math.sin(heading) * 1000,
            view.camera.y - Math.sin(tilt) * 1000, view.camera.z + Math.cos(heading) * 1000);
        view.camera.lookAt(target);
        view.camera.rotationZ = -roll;
        floor.x = Math.floor(view.camera.x / 240) * 240;
        floor.z = Math.floor(view.camera.z / 250) * 250 + 1500;
        if (flashMesh != null) {
            flashMesh.x = floor.x;
            flashMesh.z = floor.z;
            var elapsed = beat - 190.95;
            var phase = elapsed >= 0 ? elapsed % 16 : 99;
            var opacity = !second && phase >= 0 && phase < 3 ? (phase < 2.66 ? 0.65 : (3 - phase) / 0.34 * 0.65) : 0;
            var index = phase < 1 || (phase >= 1.66 && phase < 2) ? 0 : 1;
            flashMaterial.texture = flashTextures[index];
            flashMaterial.alpha = opacity;
            flashMesh.visible = opacity > 0;
        }
        try {
            if (view.stage3DProxy == null || view.stage3DProxy.context3D == null) return false;
            view.render();
            return true;
        } catch (e:Dynamic) {
            failed = true;
            view.visible = false;
            if (view.stage3DProxy != null) view.stage3DProxy.visible = false;
            trace('AwayScene: ' + Std.string(e));
            return false;
        }
    }

    static function clean(action:Void->Void):Void {
        try action() catch (e:Dynamic) trace('AwayScene cleanup: ' + Std.string(e));
    }

    public function destroy():Void {
        if (view == null) return;
        if (view.stage3DProxy != null) view.stage3DProxy.visible = false;
        if (flashMesh != null) clean(() -> view.scene.removeChild(flashMesh));
        if (floor != null) clean(() -> view.scene.removeChild(floor));
        if (flashMaterial != null) clean(() -> flashMaterial.dispose());
        clean(() -> material.dispose());
        if (flashPlane != null) clean(() -> flashPlane.dispose());
        clean(() -> plane.dispose());
        for (flash in flashTextures) clean(() -> flash.dispose());
        flashTextures.resize(0);
        clean(() -> texture.dispose());
        clean(() -> pixels.dispose());
        if (view.stage3DProxy != null) clean(() -> view.dispose());
        if (view.parent != null) clean(() -> view.parent.removeChild(view));
        floor = null;
        view = null;
    }
}
