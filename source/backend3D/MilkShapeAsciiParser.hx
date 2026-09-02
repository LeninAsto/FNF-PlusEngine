package backend3D;

import backend3D.SM3DData.SM3DColor;
import backend3D.SM3DData.SM3DMaterial;
import backend3D.SM3DData.SM3DMesh;
import backend3D.SM3DData.SM3DTriangle;
import backend3D.SM3DData.SM3DVec3;
import backend3D.SM3DData.SM3DVertex;

using StringTools;

class MilkShapeAsciiParser
{
	static var WHITESPACE:EReg = ~/[ \t]+/g;
	static var QUOTED:EReg = ~/^"([^"]*)"\s*(.*)$/;

	public static function parse(data:String, ?sourcePath:String):SM3DData
	{
		var parser = new MilkShapeAsciiParser(data, sourcePath);
		return parser.parseData();
	}

	var sourcePath:String;
	var lines:Array<SM3DLine> = [];
	var index:Int = 0;

	function new(data:String, ?sourcePath:String)
	{
		this.sourcePath = sourcePath;
		if (data == null)
			data = "";

		var rawLines = data.replace("\r", "").split("\n");
		for (i in 0...rawLines.length)
		{
			var line = stripComment(rawLines[i]).trim();
			if (line.length > 0)
				lines.push(new SM3DLine(i + 1, line));
		}
	}

	function parseData():SM3DData
	{
		var asset = new SM3DData(sourcePath);

		while (hasMore())
		{
			var line = next();
			if (line.text.startsWith("Frames:") || line.text.startsWith("Frame:"))
				continue;

			if (line.text.startsWith("Meshes:"))
			{
				var count = parseCount(line, "Meshes:");
				for (_ in 0...count)
					asset.meshes.push(parseMesh());
				continue;
			}

			if (line.text.startsWith("Materials:"))
			{
				var count = parseCount(line, "Materials:");
				for (_ in 0...count)
					asset.materials.push(parseMaterial());
				continue;
			}

			if (line.text.startsWith("Bones:"))
			{
				// Bones are kept out of the first pass. Static stage meshes do not need them,
				// and skipping here keeps the loader useful for malformed StepMania exports.
				break;
			}
		}

		asset.rebuildBounds();
		return asset;
	}

	function parseMesh():SM3DMesh
	{
		var header = nextRequired("mesh header");
		var meshName = parseQuotedName(header);
		var tail = parseQuotedTail(header);
		var headerParts = splitParts(tail);
		var flags = parseIntPart(headerParts, 0, 0, header);
		var materialIndex = parseIntPart(headerParts, 1, -1, header);
		var mesh = new SM3DMesh(meshName, flags, materialIndex);

		var vertexCount = parsePlainCount(nextRequired("vertex count"));
		for (_ in 0...vertexCount)
			mesh.vertices.push(parseVertex(nextRequired("vertex")));

		var normalCount = parsePlainCount(nextRequired("normal count"));
		for (_ in 0...normalCount)
			mesh.normals.push(parseNormal(nextRequired("normal")));

		var triangleCount = parsePlainCount(nextRequired("triangle count"));
		for (_ in 0...triangleCount)
			mesh.triangles.push(parseTriangle(nextRequired("triangle"), materialIndex));

		mesh.rebuildBounds();
		return mesh;
	}

	function parseVertex(line:SM3DLine):SM3DVertex
	{
		var parts = splitParts(line.text);
		requireParts(parts, 7, line, "vertex");
		return new SM3DVertex(parseInt(parts[0], line), parseFloat(parts[1], line), parseFloat(parts[2], line), parseFloat(parts[3], line),
			parseFloat(parts[4], line), parseFloat(parts[5], line), parseInt(parts[6], line));
	}

	function parseNormal(line:SM3DLine):SM3DVec3
	{
		var parts = splitParts(line.text);
		requireParts(parts, 3, line, "normal");
		return new SM3DVec3(parseFloat(parts[0], line), parseFloat(parts[1], line), parseFloat(parts[2], line));
	}

	function parseTriangle(line:SM3DLine, materialIndex:Int):SM3DTriangle
	{
		var parts = splitParts(line.text);
		requireParts(parts, 8, line, "triangle");
		return new SM3DTriangle(parseInt(parts[0], line), [parseInt(parts[1], line), parseInt(parts[2], line), parseInt(parts[3], line)],
			[parseInt(parts[4], line), parseInt(parts[5], line), parseInt(parts[6], line)], parseInt(parts[7], line), materialIndex);
	}

	function parseMaterial():SM3DMaterial
	{
		var nameLine = nextRequired("material name");
		var material = new SM3DMaterial(parseQuotedName(nameLine));
		material.ambient = parseColor(nextRequired("material ambient"));
		material.diffuse = parseColor(nextRequired("material diffuse"));
		material.specular = parseColor(nextRequired("material specular"));
		material.emissive = parseColor(nextRequired("material emissive"));
		material.shininess = parseFloat(nextRequired("material shininess").text, nameLine);
		material.transparency = parseFloat(nextRequired("material transparency").text, nameLine);
		material.colorMap = unquote(nextRequired("material color map").text);
		material.alphaMap = unquote(nextRequired("material alpha map").text);
		return material;
	}

	function parseColor(line:SM3DLine):SM3DColor
	{
		var parts = splitParts(line.text);
		requireParts(parts, 4, line, "color");
		return new SM3DColor(parseFloat(parts[0], line), parseFloat(parts[1], line), parseFloat(parts[2], line), parseFloat(parts[3], line));
	}

	function hasMore():Bool
	{
		return index < lines.length;
	}

	function next():SM3DLine
	{
		return lines[index++];
	}

	function nextRequired(context:String):SM3DLine
	{
		if (!hasMore())
			throw error(null, 'Unexpected end of file while reading $context');
		return next();
	}

	function parseCount(line:SM3DLine, prefix:String):Int
	{
		return parseInt(line.text.substr(prefix.length).trim(), line);
	}

	function parsePlainCount(line:SM3DLine):Int
	{
		return parseInt(line.text, line);
	}

	function parseQuotedName(line:SM3DLine):String
	{
		if (QUOTED.match(line.text))
			return QUOTED.matched(1);
		throw error(line, "Expected quoted name");
	}

	function parseQuotedTail(line:SM3DLine):String
	{
		if (QUOTED.match(line.text))
			return QUOTED.matched(2).trim();
		return "";
	}

	static function stripComment(line:String):String
	{
		var quoteOpen = false;
		for (i in 0...line.length - 1)
		{
			var char = line.charAt(i);
			if (char == '"')
				quoteOpen = !quoteOpen;
			if (!quoteOpen && char == "/" && line.charAt(i + 1) == "/")
				return line.substr(0, i);
		}
		return line;
	}

	static function splitParts(line:String):Array<String>
	{
		line = line.trim();
		if (line.length == 0)
			return [];
		return WHITESPACE.split(line);
	}

	static function requireParts(parts:Array<String>, count:Int, line:SM3DLine, context:String):Void
	{
		if (parts.length < count)
			throw error(line, 'Malformed $context, expected $count parts but got ${parts.length}');
	}

	static function parseIntPart(parts:Array<String>, index:Int, fallback:Int, line:SM3DLine):Int
	{
		if (index < 0 || index >= parts.length)
			return fallback;
		return parseInt(parts[index], line);
	}

	static function parseInt(value:String, line:SM3DLine):Int
	{
		var parsed = Std.parseInt(value);
		if (parsed == null)
			throw error(line, 'Invalid integer "$value"');
		return parsed;
	}

	static function parseFloat(value:String, line:SM3DLine):Float
	{
		var parsed = Std.parseFloat(value);
		if (Math.isNaN(parsed))
			throw error(line, 'Invalid float "$value"');
		return parsed;
	}

	static function unquote(value:String):String
	{
		value = value.trim();
		if (value.length >= 2 && value.charAt(0) == '"' && value.charAt(value.length - 1) == '"')
			return value.substr(1, value.length - 2);
		return value;
	}

	static function error(line:SM3DLine, message:String):String
	{
		if (line == null)
			return '[SM3D] $message';
		return '[SM3D:${line.number}] $message: ${line.text}';
	}
}

private class SM3DLine
{
	public var number:Int;
	public var text:String;

	public function new(number:Int, text:String)
	{
		this.number = number;
		this.text = text;
	}
}
