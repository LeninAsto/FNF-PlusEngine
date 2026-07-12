package backend;

#if cpp
import slushithings.cpp.CPPInterface;
#end

/**
 * Utilities for working with memory and garbage collector.
 * 
 * Based on FunkinCrew's MemoryUtil implementation.
 * Enhanced with system RAM detection from Slushi Engine.
 * @see https://github.com/FunkinCrew/Funkin/blob/main/source/funkin/util/MemoryUtil.hx
 */
@:nullSafety
class MemoryUtil
{
	/**
	 * Check if the current platform supports Task Memory retrieval.
	 * @return True if Task Memory is available on this platform
	 */
	public static function supportsTaskMem():Bool
	{
		#if ((cpp && (windows || ios || macos)) || linux || android)
		return true;
		#else
		return false;
		#end
	}

	/**
	 * Get the current Task Memory usage (Working Set) in bytes.
	 * This is the actual RAM usage shown in Task Manager (Windows), Activity Monitor (macOS), etc.
	 * @return Memory usage in bytes as Float
	 */
	public static function getTaskMemory():Float
	{
		#if (windows && cpp)
		return slushithings.windows.WindowsCPP.getProcessMemoryUsage();
		#elseif ((ios || macos) && cpp)
		return funkin.external.apple.MemoryUtil.getCurrentProcessRss();

		// Fallback: RSS from /proc (not PSS)
		try
		{
			#if cpp
			final input:sys.io.FileInput = sys.io.File.read('/proc/${cpp.NativeSys.sys_get_pid()}/status', false);
			#else
			final input:sys.io.FileInput = sys.io.File.read('/proc/self/status', false);
			#end

			final regex:EReg = ~/^VmRSS:\s+(\d+)\s+kB/m;
			var line:String;
			do
			{
				if (input.eof())
				{
					input.close();
					return 0.0;
				}
				line = input.readLine();
			}
			while (!regex.match(line));

			input.close();

			final kb:Float = Std.parseFloat(regex.matched(1));
			if (!Math.isNaN(kb))
			{
				return kb * 1024.0;
			}
		}
		catch (e:Dynamic)
		{
			trace('Error reading memory from /proc/status: ${e}');
		}
		#elseif linux
		try
		{
			#if cpp
			final input:sys.io.FileInput = sys.io.File.read('/proc/${cpp.NativeSys.sys_get_pid()}/status', false);
			#else
			final input:sys.io.FileInput = sys.io.File.read('/proc/self/status', false);
			#end

			final regex:EReg = ~/^VmRSS:\s+(\d+)\s+kB/m;
			var line:String;
			do
			{
				if (input.eof())
				{
					input.close();
					return 0.0;
				}
				line = input.readLine();
			}
			while (!regex.match(line));

			input.close();

			final kb:Float = Std.parseFloat(regex.matched(1));

			if (!Math.isNaN(kb))
			{
				// Convert kilobytes to bytes
				return kb * 1024.0;
			}
		}
		catch (e:Dynamic)
		{
			trace('Error reading memory from /proc/status: ${e}');
		}
		#end

		return 0.0;
	}

	/**
	 * Get the Garbage Collector memory usage in bytes.
	 * This is NOT the total program memory, only memory managed by the GC.
	 * @return GC memory usage in bytes
	 */
	public static function getGCMemory():Float
	{
		return openfl.system.System.totalMemoryNumber;
	}

	/**
	 * Enable garbage collection if it was previously disabled.
	 */
	public static function enable():Void
	{
		#if cpp
		cpp.vm.Gc.enable(true);
		#else
		throw 'Not implemented!';
		#end
	}

	/**
	 * Disable garbage collection entirely.
	 */
	public static function disable():Void
	{
		#if cpp
		cpp.vm.Gc.enable(false);
		#else
		throw 'Not implemented!';
		#end
	}

	/**
	 * Manually perform garbage collection once.
	 * Should only be called from the main thread.
	 * @param major `true` to perform major collection
	 */
	public static function collect(major:Bool = false):Void
	{
		#if cpp
		cpp.vm.Gc.run(major);
		#elseif hl
		hl.Gc.major();
		#else
		throw 'Not implemented!';
		#end
	}

	/**
	 * Perform garbage collection compaction (reduces fragmentation).
	 */
	public static function compact():Void
	{
		#if cpp
		cpp.vm.Gc.compact();
		#else
		throw 'Not implemented!';
		#end
	}

	// ========================================
	// SYSTEM RAM DETECTION (from Slushi Engine)
	// ========================================

	/**
	 * Gets the total physical RAM installed in the system.
	 * Uses native C++ detection for accurate results.
	 * @return Total RAM in Megabytes (MB), or 0 if unavailable
	 */
	public static function getSystemRAM():Float
	{
		#if cpp
		return CPPInterface.getRAM();
		#else
		return 0;
		#end
	}

	/**
	 * Gets the total physical RAM installed in the system in Gigabytes.
	 * @return Total RAM in GB (with 2 decimal precision)
	 */
	public static function getSystemRAMInGB():Float
	{
		#if cpp
		return CPPInterface.getRAMInGB();
		#else
		return 0;
		#end
	}

	/**
	 * Gets a human-readable string representation of system RAM.
	 * @return String like "16.0 GB" or "8.0 GB"
	 */
	public static function getSystemRAMString():String
	{
		#if cpp
		return CPPInterface.getRAMString();
		#else
		return "Not Available";
		#end
	}

	/**
	 * Checks if the system has at least the specified amount of RAM.
	 * Useful for determining if features should be enabled/disabled.
	 * @param minimumGB Minimum RAM required in GB
	 * @return True if system has at least that much RAM
	 */
	public static function hasMinimumRAM(minimumGB:Float):Bool
	{
		#if cpp
		return CPPInterface.hasMinimumRAM(minimumGB);
		#else
		return false;
		#end
	}

	/**
	 * Gets detailed memory statistics for debugging.
	 * @return Object with memory info
	 */
	public static function getMemoryStats():MemoryStats
	{
		var stats:MemoryStats = {
			gcMemory: getGCMemory(),
			taskMemory: supportsTaskMem() ? getTaskMemory() : 0,
			systemRAM: getSystemRAM(),
			systemRAMGB: getSystemRAMInGB()
		};
		return stats;
	}
}

/**
 * Memory statistics structure
 */
typedef MemoryStats =
{
	/**
	 * Garbage collector memory usage (bytes)
	 */
	var gcMemory:Float;

	/**
	 * Task/Process memory usage (bytes) - actual RAM used by the app
	 */
	var taskMemory:Float;

	/**
	 * Total system RAM (megabytes)
	 */
	var systemRAM:Float;

	/**
	 * Total system RAM (gigabytes)
	 */
	var systemRAMGB:Float;
}

