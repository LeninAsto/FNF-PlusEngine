package psychlua;

class Mesh3DFunctions
{
	public static function implement(funk:FunkinLua):Void
	{
		var lua:State = funk.lua;

		Lua_helper.add_callback(lua, "is3DMeshAvailable", function()
		{
			return Mesh3DRenderer.available();
		});

		#if AWAY3D_ALLOWED
		var owner:String = funk.scriptName;

		Lua_helper.add_callback(lua, "makeMatrixCity", function(tag:String, x:Float = 0, y:Float = 0, width:Int = 1280, height:Int = 720,
				?camera:String = 'hud')
		{
			tag = tag.replace('.', '');
			LuaUtils.destroyObject(tag);

			var city = new MatrixCitySprite(x, y, width, height);
			city.cameras = [LuaUtils.cameraFromString(camera)];
			MusicBeatState.getVariables().set(tag, city);
			return true;
		});

		Lua_helper.add_callback(lua, "clearMatrixCity", function(tag:String)
		{
			var city = getMatrixCity(tag);
			if (city == null)
				return false;

			city.clearBuildings();
			return true;
		});

		Lua_helper.add_callback(lua, "addMatrixCityCube", function(tag:String, id:String, x:Float = 0, y:Float = 0, z:Float = 0,
				width:Float = 128, height:Float = 400, depth:Float = 128, yaw:Float = 0)
		{
			var city = getMatrixCity(tag);
			if (city == null)
				return false;

			city.addBuilding(id, x, y, z, width, height, depth, yaw);
			return true;
		});

		Lua_helper.add_callback(lua, "setMatrixCityCamera", function(tag:String, x:Float = 0, y:Float = -140, z:Float = 620,
				pitch:Float = 18, yaw:Float = 0, roll:Float = 0, zoom:Float = 1)
		{
			var city = getMatrixCity(tag);
			if (city == null)
				return false;

			city.setCamera(x, y, z, pitch, yaw, roll, zoom);
			return true;
		});

		Lua_helper.add_callback(lua, "setMatrixCityWorld", function(tag:String, x:Float = 0, y:Float = 0, z:Float = 0)
		{
			var city = getMatrixCity(tag);
			if (city == null)
				return false;

			city.setWorld(x, y, z);
			return true;
		});

		Lua_helper.add_callback(lua, "setMatrixCityOrigin", function(tag:String, x:Float = 640, y:Float = 520)
		{
			var city = getMatrixCity(tag);
			if (city == null)
				return false;

			city.originX = x;
			city.originY = y;
			return true;
		});

		Lua_helper.add_callback(lua, "setMatrixCityStyle", function(tag:String, lineColor:Int = 0x00FF3C, fillColor:Int = 0x0A271A,
				roadColor:Int = 0x182339, lineAlpha:Float = 0.9, fillAlpha:Float = 0.035, roadAlpha:Float = 0.5, edgeThickness:Float = 2)
		{
			var city = getMatrixCity(tag);
			if (city == null)
				return false;

			city.setStyle(lineColor, fillColor, roadColor, lineAlpha, fillAlpha, roadAlpha, edgeThickness);
			return true;
		});

		Lua_helper.add_callback(lua, "setMatrixCityFloor", function(tag:String, widthNear:Float = 1450, widthFar:Float = 4200,
				nearZ:Float = -80, farZ:Float = -2300, horizontalLines:Int = 30, verticalLines:Int = 34)
		{
			var city = getMatrixCity(tag);
			if (city == null)
				return false;

			city.setFloor(widthNear, widthFar, nearZ, farZ, horizontalLines, verticalLines);
			return true;
		});

		Lua_helper.add_callback(lua, "setMatrixCityPulse", function(tag:String, value:Float = 0)
		{
			var city = getMatrixCity(tag);
			if (city == null)
				return false;

			city.pulse = value;
			return true;
		});

		Lua_helper.add_callback(lua, "setMatrixCityScrollSpeed", function(tag:String, value:Float = 1.1)
		{
			var city = getMatrixCity(tag);
			if (city == null)
				return false;

			city.floorScrollSpeed = value;
			return true;
		});

		Lua_helper.add_callback(lua, "beatMatrixCity", function(tag:String, strength:Float = 1, duration:Float = 0.2, ?ease:String = 'quadOut')
		{
			var city = getMatrixCity(tag);
			if (city == null)
				return null;

			city.pulse = strength;
			FlxTween.cancelTweensOf(city, ['pulse']);
			var tweenTag = LuaUtils.formatVariable('matrixCity_' + tag);
			var tween = FlxTween.tween(city, {pulse: 0}, duration, {
				ease: LuaUtils.getTweenEaseByString(ease),
				onComplete: function(twn:FlxTween)
				{
					LuaUtils.removeTween(tweenTag);
					if (PlayState.instance != null)
						PlayState.instance.callOnLuas('onTweenCompleted', [tweenTag, tag]);
				}
			});
			return LuaUtils.storeTween(tweenTag, tween);
		});

		Lua_helper.add_callback(lua, "makeMatrixGridFloor", function(tag:String, x:Float = 0, y:Float = 0, width:Int = 1280, height:Int = 720,
				?camera:String = 'hud')
		{
			tag = tag.replace('.', '');
			LuaUtils.destroyObject(tag);

			var floor = new MatrixGridFloorSprite(x, y, width, height);
			floor.cameras = [LuaUtils.cameraFromString(camera)];
			MusicBeatState.getVariables().set(tag, floor);
			return true;
		});

		Lua_helper.add_callback(lua, "setMatrixGridFloorStyle", function(tag:String, lineColor:Int = 0x00FF3C, horizonColor:Int = 0x00FF3C,
				roadColor:Int = 0x192435, lineAlpha:Float = 0.58, horizonAlpha:Float = 0.95, roadAlpha:Float = 0.5)
		{
			var floor = getMatrixGridFloor(tag);
			if (floor == null)
				return false;

			floor.setStyle(lineColor, horizonColor, roadColor, lineAlpha, horizonAlpha, roadAlpha);
			return true;
		});

		Lua_helper.add_callback(lua, "setMatrixGridFloorSpeed", function(tag:String, speed:Float = 0.85)
		{
			var floor = getMatrixGridFloor(tag);
			if (floor == null)
				return false;

			floor.scrollSpeed = speed;
			return true;
		});

		Lua_helper.add_callback(lua, "makeMatrixCube", function(tag:String, x:Float = 0, y:Float = 0, width:Int = 360, height:Int = 360,
				size:Float = 120, ?camera:String = 'hud')
		{
			tag = tag.replace('.', '');
			LuaUtils.destroyObject(tag);

			var cube = new MatrixCubeSprite(x, y, width, height, size);
			cube.cameras = [LuaUtils.cameraFromString(camera)];
			MusicBeatState.getVariables().set(tag, cube);
			return true;
		});

		Lua_helper.add_callback(lua, "beatMatrixCube", function(tag:String, stretch:Float = 1.65, duration:Float = 0.18, ?ease:String = 'quadOut')
		{
			var cube = getMatrixCube(tag);
			if (cube == null)
				return null;

			cube.pulse(stretch);
			FlxTween.cancelTweensOf(cube, ['heightScale']);
			var tweenTag = LuaUtils.formatVariable('matrixCube_' + tag);
			var tween = FlxTween.tween(cube, {heightScale: 1}, duration, {
				ease: LuaUtils.getTweenEaseByString(ease),
				onComplete: function(twn:FlxTween)
				{
					LuaUtils.removeTween(tweenTag);
					if (PlayState.instance != null)
						PlayState.instance.callOnLuas('onTweenCompleted', [tweenTag, tag]);
				}
			});
			return LuaUtils.storeTween(tweenTag, tween);
		});

		Lua_helper.add_callback(lua, "setMatrixCubeRotation", function(tag:String, x:Float = -18, y:Float = 36, z:Float = 0)
		{
			var cube = getMatrixCube(tag);
			if (cube == null)
				return false;

			cube.setRotation3D(x, y, z);
			return true;
		});

		Lua_helper.add_callback(lua, "setMatrixCubeSpin", function(tag:String, x:Float = 12, y:Float = 34, z:Float = 0)
		{
			var cube = getMatrixCube(tag);
			if (cube == null)
				return false;

			cube.setSpin(x, y, z);
			return true;
		});

		Lua_helper.add_callback(lua, "setMatrixCubeStyle", function(tag:String, wireframe:Bool = true, edgeColor:Int = 0x00FF3C,
				fillAlpha:Float = 0.08, lineAlpha:Float = 0.95, edgeThickness:Float = 2)
		{
			var cube = getMatrixCube(tag);
			if (cube == null)
				return false;

			cube.setStyle(wireframe, edgeColor, fillAlpha, lineAlpha, edgeThickness);
			return true;
		});

		Lua_helper.add_callback(lua, "setMatrixCubeFloorAnchored", function(tag:String, value:Bool = true)
		{
			var cube = getMatrixCube(tag);
			if (cube == null)
				return false;

			cube.floorAnchored = value;
			return true;
		});

		Lua_helper.add_callback(lua, "setMatrixCubeHeightScale", function(tag:String, value:Float = 1)
		{
			var cube = getMatrixCube(tag);
			if (cube == null)
				return false;

			cube.heightScale = value;
			return true;
		});

		Lua_helper.add_callback(lua, "setMatrixCubeAutoRotate", function(tag:String, value:Bool)
		{
			var cube = getMatrixCube(tag);
			if (cube == null)
				return false;

			cube.autoRotate = value;
			return true;
		});

		Lua_helper.add_callback(lua, "init3DMeshView", function(?visible:Bool = true)
		{
			return Mesh3DRenderer.ensureView(visible);
		});

		Lua_helper.add_callback(lua, "set3DViewVisible", function(visible:Bool)
		{
			return Mesh3DRenderer.setViewVisible(visible);
		});

		Lua_helper.add_callback(lua, "set3DViewBackground", function(color:Int = 0x000000, alpha:Float = 0)
		{
			return Mesh3DRenderer.setViewBackground(color, alpha);
		});

		Lua_helper.add_callback(lua, "make3DPlane", function(tag:String, width:Float = 100, height:Float = 100, color:Int = 0xFFFFFF,
				alpha:Float = 1, ?yUp:Bool = false)
		{
			return Mesh3DRenderer.makePlane(tag, width, height, color, alpha, owner, yUp);
		});

		Lua_helper.add_callback(lua, "make3DCube", function(tag:String, width:Float = 100, height:Float = 100, depth:Float = 100,
				color:Int = 0xFFFFFF, alpha:Float = 1)
		{
			return Mesh3DRenderer.makeCube(tag, width, height, depth, color, alpha, owner);
		});

		Lua_helper.add_callback(lua, "remove3DMesh", function(tag:String)
		{
			return Mesh3DRenderer.remove(tag);
		});

		Lua_helper.add_callback(lua, "clear3DMeshes", function()
		{
			Mesh3DRenderer.clear();
		});

		Lua_helper.add_callback(lua, "set3DMeshTexture", function(tag:String, image:String, ?smooth:Bool = true)
		{
			return Mesh3DRenderer.setTexture(tag, image, smooth);
		});

		Lua_helper.add_callback(lua, "set3DMeshPosition", function(tag:String, x:Float = 0, y:Float = 0, z:Float = 0)
		{
			return Mesh3DRenderer.setPosition(tag, x, y, z);
		});

		Lua_helper.add_callback(lua, "set3DMeshRotation", function(tag:String, x:Float = 0, y:Float = 0, z:Float = 0)
		{
			return Mesh3DRenderer.setRotation(tag, x, y, z);
		});

		Lua_helper.add_callback(lua, "set3DMeshScale", function(tag:String, x:Float = 1, y:Float = 1, z:Float = 1)
		{
			return Mesh3DRenderer.setScale(tag, x, y, z);
		});

		Lua_helper.add_callback(lua, "set3DMeshVisible", function(tag:String, visible:Bool)
		{
			return Mesh3DRenderer.setVisible(tag, visible);
		});

		Lua_helper.add_callback(lua, "set3DMeshAlpha", function(tag:String, alpha:Float)
		{
			return Mesh3DRenderer.setAlpha(tag, alpha);
		});

		Lua_helper.add_callback(lua, "set3DMeshColor", function(tag:String, color:Int)
		{
			return Mesh3DRenderer.setColor(tag, color);
		});

		Lua_helper.add_callback(lua, "set3DMeshProperty", function(tag:String, property:String, value:Dynamic)
		{
			return Mesh3DRenderer.setProperty(tag, property, value);
		});

		Lua_helper.add_callback(lua, "get3DMeshProperty", function(tag:String, property:String)
		{
			return Mesh3DRenderer.getProperty(tag, property);
		});

		Lua_helper.add_callback(lua, "get3DViewInfo", function()
		{
			return Mesh3DRenderer.getViewInfo();
		});

		Lua_helper.add_callback(lua, "set3DCameraPosition", function(x:Float = 0, y:Float = 0, z:Float = -1000)
		{
			return Mesh3DRenderer.setCameraPosition(x, y, z);
		});

		Lua_helper.add_callback(lua, "lookAt3D", function(x:Float = 0, y:Float = 0, z:Float = 0)
		{
			return Mesh3DRenderer.lookAt(x, y, z);
		});

		Lua_helper.add_callback(lua, "doTween3DMeshProperty", function(tag:String, meshTag:String, property:String, value:Float, duration:Float,
				?ease:String = 'linear')
		{
			var target:Dynamic = Mesh3DRenderer.getTweenTarget(meshTag, property);
			var tweenProperty:String = Mesh3DRenderer.normalizeTweenProperty(property);
			if (target == null || tweenProperty == null)
				return null;

			var values:Dynamic = {};
			Reflect.setField(values, tweenProperty, value);
			var originalTag:String = LuaUtils.formatVariable(tag);
			var tween:FlxTween = FlxTween.tween(target, values, duration, {
				ease: LuaUtils.getTweenEaseByString(ease),
				onComplete: function(twn:FlxTween)
				{
					LuaUtils.removeTween(originalTag);
					if (PlayState.instance != null)
						PlayState.instance.callOnLuas('onTweenCompleted', [originalTag, meshTag]);
				}
			});
			return LuaUtils.storeTween(originalTag, tween);
		});
		#else
		Lua_helper.add_callback(lua, "init3DMeshView", function(?visible:Bool = true) return false);
		#end
	}

	#if AWAY3D_ALLOWED
	static function getMatrixCube(tag:String):MatrixCubeSprite
	{
		var object:Dynamic = MusicBeatState.getVariables().get(tag);
		return Std.downcast(object, MatrixCubeSprite);
	}

	static function getMatrixGridFloor(tag:String):MatrixGridFloorSprite
	{
		var object:Dynamic = MusicBeatState.getVariables().get(tag);
		return Std.downcast(object, MatrixGridFloorSprite);
	}

	static function getMatrixCity(tag:String):MatrixCitySprite
	{
		var object:Dynamic = MusicBeatState.getVariables().get(tag);
		return Std.downcast(object, MatrixCitySprite);
	}
	#end
}
