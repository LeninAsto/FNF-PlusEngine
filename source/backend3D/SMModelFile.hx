package backend3D;

import backend.AssetLoader;
import backend3D.SM3DData.SM3DColor;
import backend3D.SM3DData.SM3DMaterial;
import openfl.utils.AssetType;

using StringTools;

class SMModelFile
{
	public static function load(path:String):SM3DModel
	{
		var text = AssetLoader.loadText(path);
		if (text == null)
			throw '[SM3D] Model file not found: $path';
		return parse(text, path);
	}

	public static function parse(data:String, ?sourcePath:String):SM3DModel
	{
		var descriptor = parseDescriptor(data, sourcePath);
		var model = new SM3DModel(sourcePath, descriptor);

		if (descriptor.meshesPath != null && descriptor.meshesPath.length > 0)
		{
			var meshPath = SM3DPath.resolveSibling(sourcePath, descriptor.meshesPath);
			var meshText = AssetLoader.loadText(meshPath);
			if (meshText == null)
				throw '[SM3D] Mesh file not found: $meshPath';

			model.meshPath = meshPath;
			model.meshData = MilkShapeAsciiParser.parse(meshText, meshPath);
		}

		if (descriptor.materialsPath != null && descriptor.materialsPath.length > 0)
		{
			var materialPath = SM3DPath.resolveSibling(sourcePath, descriptor.materialsPath);
			var materialText = AssetLoader.loadText(materialPath);
			if (materialText != null)
			{
				model.materialsPath = materialPath;
				model.materials = SMModelMaterialParser.parse(materialText, materialPath);
			}
		}

		if (model.materials.length == 0 && model.meshData != null)
			model.materials = model.meshData.materials;

		if (descriptor.bonesPath != null && descriptor.bonesPath.length > 0)
			model.bonesPath = SM3DPath.resolveSibling(sourcePath, descriptor.bonesPath);

		return model;
	}

	public static function loadMesh(path:String):SM3DData
	{
		var text = AssetLoader.loadText(path);
		if (text == null)
			throw '[SM3D] Mesh file not found: $path';
		return MilkShapeAsciiParser.parse(text, path);
	}

	public static function exists(path:String):Bool
	{
		return AssetLoader.exists(path, AssetType.TEXT);
	}

	static function parseDescriptor(data:String, ?sourcePath:String):SMModelDescriptor
	{
		var descriptor = new SMModelDescriptor();
		if (data == null)
			return descriptor;

		var section = "";
		var rawLines = data.replace("\r", "").split("\n");
		for (raw in rawLines)
		{
			var line = stripComment(raw).trim();
			if (line.length == 0)
				continue;

			if (line.startsWith("[") && line.endsWith("]"))
			{
				section = line.substr(1, line.length - 2).trim().toLowerCase();
				continue;
			}

			var equals = line.indexOf("=");
			if (equals < 0)
				continue;

			var key = line.substr(0, equals).trim().toLowerCase();
			var value = line.substr(equals + 1).trim();
			switch (section + "." + key)
			{
				case "model.meshes":
					descriptor.meshesPath = value;
				case "model.materials":
					descriptor.materialsPath = value;
				case "model.bones":
					descriptor.bonesPath = value;
				case "animatedtexture.frame0000":
					descriptor.animatedTexture = value;
				case "animatedtexture.texvelocityx":
					descriptor.texVelocityX = parseFloatOr(value, 0);
				case "animatedtexture.texvelocityy":
					descriptor.texVelocityY = parseFloatOr(value, 0);
				case "animatedtexture.texoffsetx":
					descriptor.texOffsetX = parseFloatOr(value, 0);
				case "animatedtexture.texoffsety":
					descriptor.texOffsetY = parseFloatOr(value, 0);
				default:
			}
		}

		return descriptor;
	}

	static function parseFloatOr(value:String, fallback:Float):Float
	{
		var parsed = Std.parseFloat(value);
		return Math.isNaN(parsed) ? fallback : parsed;
	}

	static function stripComment(line:String):String
	{
		var comment = line.indexOf("//");
		return comment >= 0 ? line.substr(0, comment) : line;
	}
}

class SM3DModel
{
	public var sourcePath:String;
	public var descriptor:SMModelDescriptor;
	public var meshPath:String;
	public var materialsPath:String;
	public var bonesPath:String;
	public var meshData:SM3DData;
	public var materials:Array<SM3DMaterial> = [];

	public function new(?sourcePath:String, ?descriptor:SMModelDescriptor)
	{
		this.sourcePath = sourcePath;
		this.descriptor = descriptor == null ? new SMModelDescriptor() : descriptor;
	}

	public inline function hasMeshData():Bool
	{
		return meshData != null && meshData.meshes.length > 0;
	}
}

class SMModelDescriptor
{
	public var meshesPath:String = "";
	public var materialsPath:String = "";
	public var bonesPath:String = "";
	public var animatedTexture:String = "";
	public var texVelocityX:Float = 0;
	public var texVelocityY:Float = 0;
	public var texOffsetX:Float = 0;
	public var texOffsetY:Float = 0;

	public function new() {}
}

class SMModelMaterialParser
{
	static var WHITESPACE:EReg = ~/[ \t]+/g;

	public static function parse(data:String, ?sourcePath:String):Array<SM3DMaterial>
	{
		var materials:Array<SM3DMaterial> = [];
		var lines = cleanLines(data);
		var index = 0;

		if (lines.length == 0 || !lines[0].startsWith("Materials:"))
			return materials;

		var count = Std.parseInt(lines[0].substr("Materials:".length).trim());
		if (count == null)
			return materials;

		index = 1;
		for (_ in 0...count)
		{
			if (index + 7 >= lines.length)
				break;

			var material = new SM3DMaterial(unquote(lines[index++]));
			material.ambient = parseColor(lines[index++]);
			material.diffuse = parseColor(lines[index++]);
			material.specular = parseColor(lines[index++]);
			material.emissive = parseColor(lines[index++]);
			material.shininess = parseFloatOr(lines[index++], 0);
			material.transparency = parseFloatOr(lines[index++], 1);
			material.colorMap = unquote(lines[index++]);
			material.alphaMap = index < lines.length ? unquote(lines[index++]) : "";
			materials.push(material);
		}

		return materials;
	}

	static function cleanLines(data:String):Array<String>
	{
		if (data == null)
			return [];

		var cleaned:Array<String> = [];
		for (raw in data.replace("\r", "").split("\n"))
		{
			var line = raw;
			var comment = line.indexOf("//");
			if (comment >= 0)
				line = line.substr(0, comment);
			line = line.trim();
			if (line.length > 0)
				cleaned.push(line);
		}
		return cleaned;
	}

	static function parseColor(line:String):SM3DColor
	{
		var parts = WHITESPACE.split(line.trim());
		return new SM3DColor(parseFloatOr(parts[0], 1), parseFloatOr(parts[1], 1), parseFloatOr(parts[2], 1), parseFloatOr(parts[3], 1));
	}

	static function parseFloatOr(value:String, fallback:Float):Float
	{
		var parsed = Std.parseFloat(value);
		return Math.isNaN(parsed) ? fallback : parsed;
	}

	static function unquote(value:String):String
	{
		value = value.trim();
		if (value.length >= 2 && value.charAt(0) == '"' && value.charAt(value.length - 1) == '"')
			return value.substr(1, value.length - 2);
		return value;
	}
}
