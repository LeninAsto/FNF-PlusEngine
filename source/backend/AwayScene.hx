package backend;

import away3d.containers.View3D;
import away3d.events.Stage3DEvent;
import away3d.entities.Mesh;
import away3d.core.base.Geometry;
import away3d.core.base.SubGeometry;
import openfl.Vector;
import away3d.materials.TextureMaterial;
import away3d.textures.BitmapTexture;
import openfl.display.BitmapData;
import openfl.geom.Rectangle;
import openfl.geom.ColorTransform;
import openfl.display.BlendMode;
import away3d.cameras.lenses.PerspectiveLens;
import away3d.primitives.PlaneGeometry;
import away3d.primitives.SphereGeometry;
import away3d.primitives.WireframeCube;
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
    var debugX:Float = 0;
    var debugY:Float = 0;
    var debugZ:Float = 0;
    var debugPitch:Float = 0;
    var debugYaw:Float = 0;
    var planeOffsetX:Float = 0;
    var planeOffsetY:Float = 0;
    var planeOffsetZ:Float = 0;
    var cubes:Array<WireframeCube> = [];
    var stars:Array<Mesh> = [];
    var arrowMeshes:Array<Mesh> = [];
    var arrowGeometries:Array<Geometry> = [];
    var arrowMaterials:Array<TextureMaterial> = [];
    var arrowTextures:Array<BitmapTexture> = [];
    var starGeometry:PlaneGeometry;
    var starPixels:BitmapData;
    var starTexture:BitmapTexture;
    var starMaterial:TextureMaterial;
    var starMaterials:Array<TextureMaterial> = [];
    var sphere:Mesh;
    var sphereGeometry:SphereGeometry;
    var starsVisible:Bool = false;
    var cubesVisible:Bool = false;
    var lastFlashIndex:Int = -1;
    var lastBackgroundColor:Int = -1;

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
        plane = new PlaneGeometry(4800, 6000, 1, 1, true, true);
        pixels = new BitmapData(64, 64, false, 0x071A10);
        pixels.fillRect(new Rectangle(0, 0, 64, 2), 0x2CA65C);
        pixels.fillRect(new Rectangle(0, 0, 2, 64), 0x2CA65C);
        texture = new BitmapTexture(pixels);
        material = new TextureMaterial(texture, true, true);
        material.bothSides = true;
        plane.scaleUV(18.75, 23.4375);
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
            flashPlane.scaleUV(24, 24);
            flashMaterial = new TextureMaterial(flashTextures[0], false, true);
            flashMaterial.bothSides = true;
            flashMaterial.blendMode = BlendMode.ADD;
            flashMaterial.alpha = 0;
            flashMesh = new Mesh(flashPlane, flashMaterial);
            flashMesh.y = floor.y + 2;
            flashMesh.z = floor.z;
            flashMesh.visible = false;
            view.scene.addChild(flashMesh);
        }
        for (i in 0...8) for (side in [-1, 1]) {
            var cube = new WireframeCube(128, 180, 128, 0x22BB55, 1);
            cube.x = side * 192;
            cube.z = i * 256;
            cube.visible = false;
            view.scene.addChild(cube);
            cubes.push(cube);
        }
        try {
            var modelText = Paths.getTextFromFile('models/line-arrow.json');
            var model:Array<Dynamic> = modelText == null ? [] : haxe.Json.parse(modelText);
            for (group in 0...model.length) {
                var image = Paths.image(group == 0 ? 'line/4th-shell' : 'line/4th-texture', null, false);
                if (image == null || image.bitmap == null) continue;
                var sub = new SubGeometry();
                var vertices:Array<Float> = cast model[group].vertices;
                var uvs:Array<Float> = cast model[group].uv;
                var indices:Array<UInt> = cast model[group].indices;
                sub.updateVertexData(Vector.ofArray(vertices));
                sub.updateUVData(Vector.ofArray(uvs));
                sub.updateIndexData(Vector.ofArray(indices));
                var geometry = new Geometry();
                geometry.addSubGeometry(sub);
                arrowGeometries.push(geometry);
                var tex = new BitmapTexture(image.bitmap);
                arrowTextures.push(tex);
                var mat = new TextureMaterial(tex, true, true);
                mat.bothSides = true;
                arrowMaterials.push(mat);
                var positions = [[-1100,2600,-7500],[-600,2700,-9200],[-1500,2600,-9500],[200,3400,-10000],[400,3000,-9000],[500,2800,-8000]];
                for (i in 0...positions.length) {
                    var arrow = new Mesh(geometry, mat);
                    arrow.x = positions[i][0] * 0.45;
                    arrow.y = -350 + (positions[i][1] - 2000) * 0.45;
                    arrow.z = -positions[i][2] * 0.45;
                    arrow.scale(3);
                    arrow.rotationY = (i % 2 == 0 ? 30 : -30);
                    arrow.rotationZ = (i % 3 == 0 ? 30 : -30);
                    arrow.visible = false;
                    view.scene.addChild(arrow);
                    arrowMeshes.push(arrow);
                }
            }
        } catch (e:Dynamic) trace('Line arrow mesh: ' + Std.string(e));
        var starGraphic = Paths.image('line/tex3', null, false);
        starPixels = starGraphic != null && starGraphic.bitmap != null ? starGraphic.bitmap.clone() : new BitmapData(16, 16, true, 0xFFFFFFFF);
        starTexture = new BitmapTexture(starPixels);
        starMaterial = new TextureMaterial(starTexture, true, false, false);
        starMaterial.bothSides = true;
        starMaterial.alphaBlending = true;
        starGeometry = new PlaneGeometry(64, 32, 1, 1, false, true);
        var colors = [[1.0, 0.45, 0.65], [0.45, 0.75, 1.0], [0.75, 0.55, 1.0],
            [1.0, 0.85, 0.45], [0.45, 1.0, 0.8], [1.0, 1.0, 1.0]];
        for (color in colors) {
            var starColor = new TextureMaterial(starTexture, true, false, false);
            starColor.bothSides = true;
            starColor.alphaBlending = true;
            starColor.colorTransform = new ColorTransform(color[0], color[1], color[2]);
            starMaterials.push(starColor);
        }
        for (i in 0...32) {
            var star = new Mesh(starGeometry, starMaterials[Std.random(starMaterials.length)]);
            star.visible = false;
            view.scene.addChild(star);
            stars.push(star);
        }
        sphereGeometry = new SphereGeometry(65, 12, 8);
        sphere = new Mesh(sphereGeometry, starMaterial);
        sphere.visible = false;
        view.scene.addChild(sphere);
        view.visible = false;
        Lib.current.stage.addChildAt(view, 0);
        if (view.stage3DProxy != null) view.stage3DProxy.visible = false;
    }

    public function setCameraAdjustment(x:Float, y:Float, z:Float, pitch:Float, yaw:Float, fov:Float):Void {
        debugX = x; debugY = y; debugZ = z; debugPitch = pitch; debugYaw = yaw;
        if (view != null && Std.isOfType(view.camera.lens, PerspectiveLens))
            cast(view.camera.lens, PerspectiveLens).fieldOfView = Math.max(20, Math.min(120, fov));
    }

    public function setPlaneAdjustment(x:Float, y:Float, z:Float):Void {
        if (planeOffsetX == x && planeOffsetY == y && planeOffsetZ == z) return;
        planeOffsetX = x; planeOffsetY = y; planeOffsetZ = z;
        for (i in 0...cubes.length) {
            cubes[i].x = (i % 2 == 0 ? -192 : 192) + x;
            cubes[i].z = Std.int(i / 2) * 256 + z;
        }
    }

    public function update(beat:Float, active:Bool, x:Float, y:Float, z:Float, pitch:Float, yaw:Float, roll:Float):Bool {
        if (view == null) return false;
        view.visible = active && !failed;
        if (view.stage3DProxy != null) view.stage3DProxy.visible = active && !failed;
        if (!active || failed) return false;
        if (view.width != Lib.current.stage.stageWidth) view.width = Lib.current.stage.stageWidth;
        if (view.height != Lib.current.stage.stageHeight) view.height = Lib.current.stage.stageHeight;
        var second = beat >= 454;
        var color = second ? 0xCC3333 : 0x2CA65C;
        if (color != floorColor) {
            floorColor = color;
            pixels.fillRect(new Rectangle(0, 0, 64, 64), 0x07100C);
            pixels.fillRect(new Rectangle(0, 0, 64, 2), color);
            pixels.fillRect(new Rectangle(0, 0, 2, 64), color);
            texture.invalidateContent();
        }
        // Retain the original scene travel scale; modchart path coordinates
        // cover a much larger range than the Away3D scenery.
        view.camera.x = x * 0.22 + debugX;
        view.camera.y = 350 - y * 0.12 + debugY;
        view.camera.z = -1000 - z * 0.22 + debugZ;
        var heading = (yaw + debugYaw) * Math.PI / 180;
        var tilt = (pitch + debugPitch) * Math.PI / 180;
        var horizontal = Math.cos(tilt);
        target.setTo(view.camera.x + Math.sin(heading) * horizontal * 1000,
            view.camera.y - Math.sin(tilt) * 1000,
            view.camera.z + Math.cos(heading) * horizontal * 1000);
        view.camera.lookAt(target);
        view.camera.rotationZ = roll;
        floor.x = Math.floor(view.camera.x / 256) * 256 + planeOffsetX;
        floor.y = -350 + planeOffsetY;
        floor.z = Math.floor(view.camera.z / 256) * 256 + 1500 + planeOffsetZ;
        var cubeVisible = beat >= 198 && beat < 246;
        var phase = beat - Math.floor(beat);
        var bump = Math.max(0.9 - phase, 0);
        var cubeHeight = 0.5 + 0.6 * bump * bump;
        if (cubeVisible != cubesVisible) {
            cubesVisible = cubeVisible;
            for (cube in cubes) cube.visible = cubeVisible;
        }
        if (cubeVisible) for (i in 0...cubes.length) {
            var cube = cubes[i];
            {
                cube.scaleY = cubeHeight;
                cube.y = floor.y + 90 * cubeHeight;
            }
        }
        if (flashMesh != null) {
            flashMesh.x = floor.x;
            flashMesh.y = floor.y + 2;
            flashMesh.z = floor.z;
            var elapsed = beat - 190.95;
            var phase = elapsed >= 0 ? elapsed % 16 : 99;
            var opacity = !second && phase >= 0 && phase < 3 ? (phase < 2.66 ? 0.65 : (3 - phase) / 0.34 * 0.65) : 0;
            var showFlash = opacity > 0;
            if (flashMesh.visible != showFlash) flashMesh.visible = showFlash;
            if (showFlash) {
                var index = phase < 1 || (phase >= 1.66 && phase < 2) ? 0 : 1;
                if (index != lastFlashIndex) {
                    flashMaterial.texture = flashTextures[index];
                    lastFlashIndex = index;
                }
                flashMaterial.alpha = opacity;
            }
        }
        var background = !second ? (beat < 214 ? 0x08160E : 0x080D1B) : (beat < 486 ? 0x1A080D : 0x130819);
        if (background != lastBackgroundColor) {
            view.backgroundColor = background;
            lastBackgroundColor = background;
        }
        var showArrows = beat >= 230 && beat < 255;
        for (i in 0...arrowMeshes.length) {
            var arrow = arrowMeshes[i];
            if (arrow.visible != showArrows) arrow.visible = showArrows;
            if (showArrows) arrow.rotationY = (i % 2 == 0 ? 30 : -30) + 20 * Math.sin(beat * Math.PI * 2 / 3);
        }
        var showStars = (beat >= 198 && beat < 246) || (beat >= 470 && beat < 518);
        if (showStars != starsVisible) {
            starsVisible = showStars;
            for (star in stars) star.visible = showStars;
        }
        if (showStars) {
            var sx = Math.sin(heading), cx = Math.cos(heading);
            var st = Math.sin(tilt), ct = horizontal;
            for (i in 0...stars.length) {
                var star = stars[i];
                var side = ((i * 337 - beat * 45) % 1800 + 1800) % 1800 - 900;
                var up = (i * 197) % 1000 - 400;
                var depth = 400 + (i * 173) % 2500;
                star.x = view.camera.x + sx * ct * depth + cx * side + sx * st * up;
                star.y = view.camera.y - st * depth + ct * up;
                star.z = view.camera.z + cx * ct * depth - sx * side + cx * st * up;
                star.rotationY = yaw;
            }
            var showSphere = (beat >= 214 && beat < 230) || (beat >= 486 && beat < 502);
            if (sphere.visible != showSphere) sphere.visible = showSphere;
            if (showSphere) {
                var side = 400 * Math.sin(beat * 0.18);
                sphere.x = view.camera.x + sx * ct * 1750 + cx * side;
                sphere.y = view.camera.y - st * 1750 + 250 * ct;
                sphere.z = view.camera.z + cx * ct * 1750 - sx * side;
                sphere.rotationY = beat * 5;
            }
        } else if (sphere.visible) sphere.visible = false;
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
        for (cube in cubes) {
            clean(() -> view.scene.removeChild(cube));
            clean(() -> cube.dispose());
        }
        cubes.resize(0);
        for (arrow in arrowMeshes) clean(() -> view.scene.removeChild(arrow));
        arrowMeshes.resize(0);
        for (geometry in arrowGeometries) clean(() -> geometry.dispose());
        arrowGeometries.resize(0);
        for (mat in arrowMaterials) clean(() -> mat.dispose());
        arrowMaterials.resize(0);
        for (tex in arrowTextures) clean(() -> tex.dispose());
        arrowTextures.resize(0);
        for (star in stars) {
            clean(() -> view.scene.removeChild(star));
            clean(() -> star.dispose());
        }
        stars.resize(0);
        clean(() -> view.scene.removeChild(sphere));
        clean(() -> sphere.dispose());
        clean(() -> sphereGeometry.dispose());
        clean(() -> starGeometry.dispose());
        for (starColor in starMaterials) clean(() -> starColor.dispose());
        starMaterials.resize(0);
        clean(() -> starMaterial.dispose());
        clean(() -> starTexture.dispose());
        clean(() -> starPixels.dispose());
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
        // Away3D normally dispatches this after Context3D.dispose(), when
        // OpenFL has already cleared gl. Release its cached programs first.
        var proxy = view.stage3DProxy;
        if (proxy != null && proxy.context3D != null && @:privateAccess proxy.context3D.gl != null)
            clean(() -> proxy.dispatchEvent(new Stage3DEvent(Stage3DEvent.CONTEXT3D_DISPOSED)));
        if (proxy != null) clean(() -> view.dispose());
        if (view.parent != null) clean(() -> view.parent.removeChild(view));
        floor = null;
        view = null;
    }
}
