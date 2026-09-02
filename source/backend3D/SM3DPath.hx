package backend3D;

using StringTools;

class SM3DPath
{
	static var DRIVE_PATH:EReg = ~/^[A-Za-z]:[\/\\]/;

	public static function normalize(path:String):String
	{
		if (path == null)
			return null;

		var normalized = path.replace("\\", "/");
		while (normalized.indexOf("//") != -1)
			normalized = normalized.replace("//", "/");
		return normalized;
	}

	public static function directory(path:String):String
	{
		path = normalize(path);
		if (path == null || path.length == 0)
			return "";

		var slash = path.lastIndexOf("/");
		if (slash < 0)
			return "";
		return path.substr(0, slash);
	}

	public static function fileName(path:String):String
	{
		path = normalize(path);
		if (path == null || path.length == 0)
			return "";

		var slash = path.lastIndexOf("/");
		if (slash < 0)
			return path;
		return path.substr(slash + 1);
	}

	public static function isAbsolute(path:String):Bool
	{
		path = normalize(path);
		return path != null && path.length > 0 && (path.startsWith("/") || DRIVE_PATH.match(path));
	}

	public static function join(base:String, relative:String):String
	{
		if (relative == null || relative.length == 0)
			return normalize(base);

		relative = normalize(relative);
		if (isAbsolute(relative))
			return relative;

		base = normalize(base);
		if (base == null || base.length == 0)
			return relative;
		if (base.endsWith("/"))
			return base + relative;
		return base + "/" + relative;
	}

	public static function resolveSibling(ownerPath:String, relative:String):String
	{
		return join(directory(ownerPath), relative);
	}
}
