package psychlua;

#if AWAY3D_ALLOWED
import away3d.containers.View3D;
import away3d.core.base.Geometry;
import away3d.entities.Mesh;
import away3d.lights.DirectionalLight;
import away3d.materials.ColorMaterial;
import away3d.materials.lightpickers.StaticLightPicker;
import away3d.materials.MaterialBase;
import away3d.materials.TextureMaterial;
import away3d.primitives.ConeGeometry;
import away3d.primitives.CubeGeometry;
import away3d.primitives.CylinderGeometry;
import away3d.primitives.PlaneGeometry;
import away3d.primitives.SphereGeometry;
import away3d.primitives.TorusGeometry;
import away3d.textures.BitmapTexture;
import flixel.FlxSprite;
import openfl.display.BitmapData;
import openfl.geom.Matrix;
import openfl.geom.Vector3D;
#end

class Mesh3DRenderer
{
	#if AWAY3D_ALLOWED
	static var view:View3D;
	static var meshes:Map<String, Mesh3DRecord> = new Map<String, Mesh3DRecord>();
	static var meshCount:Int = 0;
	static var hooksRegistered:Bool = false;
	static var wantedVisible:Bool = true;
	static var lastRenderError:String = null;
	static var light:DirectionalLight;
	static var lightPicker:StaticLightPicker;

	public static function available():Bool
		return true;

	public static function ensureView(?visible:Bool = true):Bool
	{
		wantedVisible = visible;
		if (FlxG.stage == null)
			return false;

		if (view == null)
		{
			view = new View3D();
			view.mouseEnabled = false;
			view.mouseChildren = false;
			view.backgroundAlpha = 0;
			view.antiAlias = 2;
			view.camera.z = -1000;
			view.camera.lookAt(new Vector3D(0, 0, 0));
			resizeView(FlxG.stage.stageWidth, FlxG.stage.stageHeight);
		}

		if (view.parent == null)
			FlxG.stage.addChild(view);

		ensureLight();
		registerHooks();
		updateVisibility();
		return true;
	}

	static function registerHooks():Void
	{
		if (hooksRegistered)
			return;

		FlxG.signals.postDraw.add(render);
		FlxG.signals.gameResized.add(onGameResized);
		FlxG.signals.preStateSwitch.add(onPreStateSwitch);
		hooksRegistered = true;
	}

	static function unregisterHooks():Void
	{
		if (!hooksRegistered)
			return;

		FlxG.signals.postDraw.remove(render);
		FlxG.signals.gameResized.remove(onGameResized);
		FlxG.signals.preStateSwitch.remove(onPreStateSwitch);
		hooksRegistered = false;
	}

	static function render():Void
	{
		if (view == null || meshCount <= 0 || !wantedVisible || !view.visible)
			return;

		try
		{
			view.render();
			lastRenderError = null;
		}
		catch (e:Dynamic)
		{
			var message:String = Std.string(e);
			if (message != lastRenderError)
			{
				lastRenderError = message;
				trace('[3DMesh] render failed: $message');
			}
		}
	}

	static function onGameResized(width:Int, height:Int):Void
		resizeView(width, height);

	static function onPreStateSwitch():Void
	{
		clear();
		setViewVisible(false);
	}

	static function resizeView(width:Float, height:Float):Void
	{
		if (view == null)
			return;

		view.x = 0;
		view.y = 0;
		view.width = width > 0 ? width : FlxG.width;
		view.height = height > 0 ? height : FlxG.height;
	}

	static function updateVisibility():Void
	{
		if (view != null)
			view.visible = wantedVisible && meshCount > 0;
	}

	public static function setViewVisible(value:Bool):Bool
	{
		wantedVisible = value;
		updateVisibility();
		return wantedVisible;
	}

	public static function makePlane(tag:String, width:Float = 100, height:Float = 100, color:Int = 0xFFFFFF, alpha:Float = 1, ?owner:String,
			?yUp:Bool = false):Bool
	{
		if (!ensureView())
			return false;

		return putMesh(tag, new PlaneGeometry(width, height, 1, 1, yUp, true), makeColorMaterial(color, alpha), owner);
	}

	public static function makeFloor(tag:String, width:Float = 1800, depth:Float = 2200, y:Float = 280, z:Float = 300,
			color:Int = 0x202A3A, alpha:Float = 1, ?owner:String):Bool
	{
		if (!makePlane(tag, width, depth, color, alpha, owner, true))
			return false;

		setPosition(tag, 0, y, z);
		setRotation(tag, 0, 0, 0);
		return true;
	}

	public static function makeCube(tag:String, width:Float = 100, height:Float = 100, depth:Float = 100, color:Int = 0xFFFFFF, alpha:Float = 1,
			?owner:String):Bool
	{
		if (!ensureView())
			return false;

		return putMesh(tag, new CubeGeometry(width, height, depth), makeColorMaterial(color, alpha), owner);
	}

	public static function makeSphere(tag:String, radius:Float = 50, color:Int = 0xFFFFFF, alpha:Float = 1, segmentsW:Int = 16, segmentsH:Int = 12,
			?owner:String):Bool
	{
		if (!ensureView())
			return false;

		return putMesh(tag, new SphereGeometry(radius, Std.int(Math.max(3, segmentsW)), Std.int(Math.max(2, segmentsH)), true), makeColorMaterial(color, alpha), owner);
	}

	public static function makeCylinder(tag:String, radius:Float = 50, height:Float = 100, color:Int = 0xFFFFFF, alpha:Float = 1, segments:Int = 16,
			?owner:String):Bool
	{
		if (!ensureView())
			return false;

		return putMesh(tag, new CylinderGeometry(radius, radius, height, Std.int(Math.max(3, segments)), 1, true, true, true, true),
			makeColorMaterial(color, alpha), owner);
	}

	public static function makeCone(tag:String, radius:Float = 50, height:Float = 100, color:Int = 0xFFFFFF, alpha:Float = 1, segments:Int = 16,
			?owner:String):Bool
	{
		if (!ensureView())
			return false;

		return putMesh(tag, new ConeGeometry(radius, height, Std.int(Math.max(3, segments)), 1, true, true), makeColorMaterial(color, alpha), owner);
	}

	public static function makeTorus(tag:String, radius:Float = 80, tubeRadius:Float = 18, color:Int = 0xFFFFFF, alpha:Float = 1, segmentsR:Int = 24,
			segmentsT:Int = 10, ?owner:String):Bool
	{
		if (!ensureView())
			return false;

		return putMesh(tag, new TorusGeometry(radius, tubeRadius, Std.int(Math.max(3, segmentsR)), Std.int(Math.max(3, segmentsT)), true),
			makeColorMaterial(color, alpha), owner);
	}

	public static function makeSpritePlane(tag:String, image:String, width:Float = 0, height:Float = 0, x:Float = 0, y:Float = 0, z:Float = 0,
			?owner:String, ?smooth:Bool = true, ?floorAligned:Bool = false):Bool
	{
		var graphic = Paths.image(image, null, false);
		if (graphic == null || graphic.bitmap == null)
			return false;

		var planeWidth:Float = width > 0 ? width : graphic.bitmap.width;
		var planeHeight:Float = height > 0 ? height : graphic.bitmap.height;
		if (!makePlane(tag, planeWidth, planeHeight, 0xFFFFFF, 1, owner, floorAligned))
			return false;

		setPosition(tag, x, y, z);
		return setTextureFromBitmap(tag, graphic.bitmap, smooth);
	}

	static function putMesh(tag:String, geometry:Geometry, material:MaterialBase, ?owner:String):Bool
	{
		tag = normalizeTag(tag);
		if (tag == null)
			return false;

		remove(tag);

		var mesh:Mesh = new Mesh(geometry, material);
		mesh.name = tag;
		var record = new Mesh3DRecord(mesh, material, owner);
		meshes.set(tag, record);
		meshCount++;
		view.scene.addChild(mesh);
		updateVisibility();
		return true;
	}

	static function makeColorMaterial(color:Int, alpha:Float):ColorMaterial
	{
		var material = new ColorMaterial(color & 0xFFFFFF, clamp01(alpha));
		material.bothSides = true;
		material.lightPicker = lightPicker;
		return material;
	}

	static function makeTextureMaterial(source:BitmapData, smooth:Bool, alpha:Float = 1):{material:TextureMaterial, texture:BitmapTexture}
	{
		var texture = new BitmapTexture(makePowerOfTwoBitmap(source), false);
		var material = new TextureMaterial(texture, smooth, false, false);
		material.bothSides = true;
		material.lightPicker = lightPicker;
		material.alpha = clamp01(alpha);
		return {material: material, texture: texture};
	}

	public static function setTexture(tag:String, image:String, ?smooth:Bool = true):Bool
	{
		if (image == null || image.length < 1)
			return false;

		var graphic = Paths.image(image, null, false);
		if (graphic == null || graphic.bitmap == null)
			return false;

		return setTextureFromBitmap(tag, graphic.bitmap, smooth);
	}

	public static function setTextureFromBitmap(tag:String, bitmap:BitmapData, ?smooth:Bool = true):Bool
	{
		var record = getRecord(tag);
		if (record == null || bitmap == null)
			return false;

		var textured = makeTextureMaterial(bitmap, smooth, record.alpha);
		record.setMaterial(textured.material, textured.texture);
		return true;
	}

	public static function setTextureFromSprite(tag:String, spriteTag:String, ?smooth:Bool = true):Bool
	{
		if (spriteTag == null || spriteTag.length < 1)
			return false;

		var source:FlxSprite = getLuaSprite(spriteTag);
		if (source == null || source.pixels == null)
			return false;

		return setTextureFromBitmap(tag, source.pixels, smooth);
	}

	static function makePowerOfTwoBitmap(source:BitmapData):BitmapData
	{
		var width:Int = nextPowerOfTwo(source.width);
		var height:Int = nextPowerOfTwo(source.height);
		if (width == source.width && height == source.height)
			return source.clone();

		var output = new BitmapData(width, height, true, 0);
		var matrix = new Matrix();
		matrix.scale(width / source.width, height / source.height);
		output.draw(source, matrix, null, null, null, true);
		return output;
	}

	static function nextPowerOfTwo(value:Int):Int
	{
		var pot:Int = 1;
		while (pot < value)
			pot <<= 1;
		return pot;
	}

	public static function remove(tag:String):Bool
	{
		tag = normalizeTag(tag);
		if (tag == null)
			return false;

		var record = meshes.get(tag);
		if (record == null)
			return false;

		meshes.remove(tag);
		meshCount--;
		record.dispose();
		updateVisibility();
		return true;
	}

	public static function removeByOwner(owner:String):Void
	{
		if (owner == null || owner.length < 1)
			return;

		var toRemove:Array<String> = [];
		for (tag in meshes.keys())
		{
			var record = meshes.get(tag);
			if (record != null && record.owner == owner)
				toRemove.push(tag);
		}
		for (tag in toRemove)
			remove(tag);
	}

	public static function clear():Void
	{
		var toRemove:Array<String> = [];
		for (tag in meshes.keys())
			toRemove.push(tag);
		for (tag in toRemove)
			remove(tag);
	}

	static function disposeView():Void
	{
		unregisterHooks();
		if (view == null)
			return;

		if (view.parent != null)
			view.parent.removeChild(view);

		try
			view.dispose()
		catch (e:Dynamic)
			trace('[3DMesh] dispose failed: ' + Std.string(e));

		view = null;
	}

	public static function setPosition(tag:String, x:Float, y:Float, z:Float):Bool
	{
		var mesh = getMesh(tag);
		if (mesh == null)
			return false;

		mesh.x = x;
		mesh.y = y;
		mesh.z = z;
		return true;
	}

	public static function setFloorPosition(tag:String, x:Float, z:Float, y:Float = 280):Bool
		return setPosition(tag, x, y, z);

	public static function setRotation(tag:String, x:Float, y:Float, z:Float):Bool
	{
		var mesh = getMesh(tag);
		if (mesh == null)
			return false;

		mesh.rotationX = x;
		mesh.rotationY = y;
		mesh.rotationZ = z;
		return true;
	}

	public static function setScale(tag:String, x:Float, y:Float, z:Float):Bool
	{
		var mesh = getMesh(tag);
		if (mesh == null)
			return false;

		mesh.scaleX = x;
		mesh.scaleY = y;
		mesh.scaleZ = z;
		return true;
	}

	public static function setVisible(tag:String, visible:Bool):Bool
	{
		var mesh = getMesh(tag);
		if (mesh == null)
			return false;

		mesh.visible = visible;
		return true;
	}

	public static function setAlpha(tag:String, alpha:Float):Bool
	{
		var record = getRecord(tag);
		if (record == null)
			return false;

		record.setAlpha(clamp01(alpha));
		return true;
	}

	public static function setColor(tag:String, color:Int):Bool
	{
		var record = getRecord(tag);
		if (record == null)
			return false;

		var material:ColorMaterial = Std.downcast(record.material, ColorMaterial);
		if (material == null)
			return false;

		material.color = color & 0xFFFFFF;
		return true;
	}

	public static function setCameraPosition(x:Float, y:Float, z:Float):Bool
	{
		if (!ensureView())
			return false;

		view.camera.x = x;
		view.camera.y = y;
		view.camera.z = z;
		return true;
	}

	public static function setCamera(x:Float = 0, y:Float = 0, z:Float = -1000, lookX:Float = 0, lookY:Float = 0, lookZ:Float = 0):Bool
	{
		if (!setCameraPosition(x, y, z))
			return false;

		return lookAt(lookX, lookY, lookZ);
	}

	public static function lookAt(x:Float, y:Float, z:Float):Bool
	{
		if (!ensureView())
			return false;

		view.camera.lookAt(new Vector3D(x, y, z));
		return true;
	}

	public static function setViewBackground(color:Int, alpha:Float):Bool
	{
		if (!ensureView())
			return false;

		view.backgroundColor = color & 0xFFFFFF;
		view.backgroundAlpha = clamp01(alpha);
		return true;
	}

	public static function setProperty(tag:String, property:String, value:Dynamic):Bool
	{
		var record = getRecord(tag);
		if (record == null || property == null)
			return false;

		switch (property.toLowerCase().trim())
		{
			case 'x':
				record.mesh.x = cast value;
			case 'y':
				record.mesh.y = cast value;
			case 'z':
				record.mesh.z = cast value;
			case 'rotationx' | 'rotation_x' | 'rotx' | 'rot_x' | 'angle_x' | 'anglex' | 'pitch':
				record.mesh.rotationX = cast value;
			case 'rotationy' | 'rotation_y' | 'roty' | 'rot_y' | 'angle_y' | 'angley' | 'yaw':
				record.mesh.rotationY = cast value;
			case 'rotationz' | 'rotation_z' | 'rotz' | 'rot_z' | 'angle' | 'angle_z' | 'anglez' | 'roll':
				record.mesh.rotationZ = cast value;
			case 'scalex' | 'scale_x':
				record.mesh.scaleX = cast value;
			case 'scaley' | 'scale_y':
				record.mesh.scaleY = cast value;
			case 'scalez' | 'scale_z':
				record.mesh.scaleZ = cast value;
			case 'visible':
				record.mesh.visible = value == true;
			case 'alpha':
				record.setAlpha(cast value);
			case 'color':
				return setColor(tag, cast value);
			default:
				return false;
		}
		return true;
	}

	public static function getProperty(tag:String, property:String):Dynamic
	{
		var record = getRecord(tag);
		if (record == null || property == null)
			return null;

		return switch (property.toLowerCase().trim())
		{
			case 'x': record.mesh.x;
			case 'y': record.mesh.y;
			case 'z': record.mesh.z;
			case 'rotationx' | 'rotation_x' | 'rotx' | 'rot_x' | 'angle_x' | 'anglex' | 'pitch': record.mesh.rotationX;
			case 'rotationy' | 'rotation_y' | 'roty' | 'rot_y' | 'angle_y' | 'angley' | 'yaw': record.mesh.rotationY;
			case 'rotationz' | 'rotation_z' | 'rotz' | 'rot_z' | 'angle' | 'angle_z' | 'anglez' | 'roll': record.mesh.rotationZ;
			case 'scalex' | 'scale_x': record.mesh.scaleX;
			case 'scaley' | 'scale_y': record.mesh.scaleY;
			case 'scalez' | 'scale_z': record.mesh.scaleZ;
			case 'visible': record.mesh.visible;
			case 'alpha': record.alpha;
			default: null;
		}
	}

	public static function getTweenTarget(tag:String, property:String):Dynamic
	{
		var record = getRecord(tag);
		if (record == null || property == null)
			return null;

		return normalizeTweenProperty(property) == 'alpha' ? record : record.mesh;
	}

	public static function normalizeTweenProperty(property:String):String
	{
		if (property == null)
			return null;

		return switch (property.toLowerCase().trim())
		{
			case 'rotationx' | 'rotation_x' | 'rotx' | 'rot_x' | 'angle_x' | 'anglex' | 'pitch': 'rotationX';
			case 'rotationy' | 'rotation_y' | 'roty' | 'rot_y' | 'angle_y' | 'angley' | 'yaw': 'rotationY';
			case 'rotationz' | 'rotation_z' | 'rotz' | 'rot_z' | 'angle' | 'angle_z' | 'anglez' | 'roll': 'rotationZ';
			case 'scalex' | 'scale_x': 'scaleX';
			case 'scaley' | 'scale_y': 'scaleY';
			case 'scalez' | 'scale_z': 'scaleZ';
			case 'x' | 'y' | 'z' | 'alpha': property.toLowerCase().trim();
			default: null;
		}
	}

	public static function has(tag:String):Bool
		return getRecord(tag) != null;

	public static function getViewInfo():String
	{
		if (view == null)
			return 'view=null meshes=$meshCount visible=$wantedVisible';

		var parentIndex:Int = view.parent != null ? view.parent.getChildIndex(view) : -1;
		var parentChildren:Int = view.parent != null ? view.parent.numChildren : -1;
		var proxyInfo:String = 'stage3D=none';
		try
		{
			if (view.stage3DProxy != null)
				proxyInfo = 'stage3D=${view.stage3DProxy.stage3DIndex} driver=${view.stage3DProxy.driverInfo} proxyVisible=${view.stage3DProxy.visible}';
		}
		catch (_:Dynamic) {}

		return 'displayIndex=$parentIndex/$parentChildren viewVisible=${view.visible} wantedVisible=$wantedVisible meshes=$meshCount $proxyInfo cam=(${view.camera.x},${view.camera.y},${view.camera.z}) size=${view.width}x${view.height}';
	}

	static function ensureLight():Void
	{
		if (view == null || light != null)
			return;

		light = new DirectionalLight(-0.3, -1, 0.4);
		light.color = 0xFFFFFF;
		light.ambient = 1;
		light.diffuse = 1;
		light.specular = 0.2;
		view.scene.addChild(light);
		lightPicker = new StaticLightPicker([light]);
	}

	static function getMesh(tag:String):Mesh
	{
		var record = getRecord(tag);
		return record != null ? record.mesh : null;
	}

	static function getRecord(tag:String):Mesh3DRecord
	{
		tag = normalizeTag(tag);
		return tag != null ? meshes.get(tag) : null;
	}

	static function getLuaSprite(tag:String):FlxSprite
	{
		if (tag == null)
			return null;

		var obj:Dynamic = MusicBeatState.getVariables().get(tag);
		if (obj == null && PlayState.instance != null)
			obj = PlayState.instance.getLuaObject(tag);
		if (obj == null)
			obj = Reflect.field(MusicBeatState.getState(), tag);

		return Std.downcast(obj, FlxSprite);
	}

	static function normalizeTag(tag:String):String
	{
		if (tag == null)
			return null;
		tag = tag.trim();
		return tag.length > 0 ? tag : null;
	}

	static inline function clamp01(value:Float):Float
		return value < 0 ? 0 : (value > 1 ? 1 : value);
	#else
	public static function available():Bool
		return false;

	public static function removeByOwner(owner:String):Void {}
	#end
}

#if AWAY3D_ALLOWED
private class Mesh3DRecord
{
	public var mesh:Mesh;
	public var material:MaterialBase;
	public var texture:BitmapTexture;
	public var owner:String;
	public var alpha(get, set):Float;

	var _alpha:Float = 1;

	public function new(mesh:Mesh, material:MaterialBase, ?owner:String)
	{
		this.mesh = mesh;
		this.owner = owner;
		setMaterial(material, null);
	}

	public function setMaterial(material:MaterialBase, ?texture:BitmapTexture):Void
	{
		if (this.material != null)
			this.material.dispose();
		if (this.texture != null)
			this.texture.dispose();

		this.material = material;
		this.texture = texture;
		mesh.material = material;
		setAlpha(alpha);
	}

	function get_alpha():Float
		return _alpha;

	function set_alpha(value:Float):Float
	{
		_alpha = value < 0 ? 0 : (value > 1 ? 1 : value);
		applyAlpha();
		return _alpha;
	}

	public function setAlpha(value:Float):Void
	{
		_alpha = value < 0 ? 0 : (value > 1 ? 1 : value);
		applyAlpha();
	}

	function applyAlpha():Void
	{
		var colorMaterial:ColorMaterial = Std.downcast(material, ColorMaterial);
		if (colorMaterial != null)
		{
			colorMaterial.alpha = _alpha;
			return;
		}

		var textureMaterial:TextureMaterial = Std.downcast(material, TextureMaterial);
		if (textureMaterial != null)
			textureMaterial.alpha = _alpha;
	}

	public function dispose():Void
	{
		if (mesh != null)
			mesh.dispose();
		if (material != null)
			material.dispose();
		if (texture != null)
			texture.dispose();

		mesh = null;
		material = null;
		texture = null;
	}
}
#end
