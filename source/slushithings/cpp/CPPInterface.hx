package slushithings.cpp;

/**
 * Safe interface for C++ functionality
 * Prevents compiler errors when directly interacting with CPP files
 * 
 * Based on Slushi Engine implementation
 * This is a wrapper to avoid compilation issues
 */
class CPPInterface
{
	/**
	 * Gets the total physical RAM installed in the system
	 * @return RAM in Megabytes (MB) as Float for cross-platform compatibility
	 */
	public static function getRAM():Float
	{
		#if cpp
		return cast GetRAMSys.obtainRAM();
		#else
		return 0;
		#end
	}

	/**
	 * Gets the total physical RAM in Gigabytes
	 * @return RAM in GB (with 2 decimal precision)
	 */
	public static function getRAMInGB():Float
	{
		#if cpp
		var ramMB:Float = cast getRAM();
		return Math.round((ramMB / 1024) * 100) / 100; // 2 decimal places
		#else
		return 0;
		#end
	}

	/**
	 * Checks if the system has at least the specified amount of RAM
	 * @param minimumGB Minimum RAM in GB
	 * @return True if system has at least that much RAM
	 */
	public static function hasMinimumRAM(minimumGB:Float):Bool
	{
		#if cpp
		return getRAMInGB() >= minimumGB;
		#else
		return false;
		#end
	}

	/**
	 * Gets a human-readable string of the system RAM
	 * @return String like "16.0 GB" or "8.0 GB"
	 */
	public static function getRAMString():String
	{
		#if cpp
		var gb:Float = getRAMInGB();
		if (gb <= 0)
			return "Unknown";
		return gb + " GB";
		#else
		return "Not Available";
		#end
	}
}
