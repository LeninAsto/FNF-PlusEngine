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
#if cpp
@:headerInclude("hx/GC.h")
#end
@:nullSafety
class MemoryUtil
{
	private static inline final GC_STAT_COLLECTIONS:Int = 0;
	private static inline final GC_STAT_TOTAL_MS:Int = 1;
	private static inline final GC_STAT_LAST_MS:Int = 2;
	private static inline final GC_STAT_MAX_MS:Int = 3;
	private static inline final GC_STAT_LAST_THREAD_WAIT_MS:Int = 4;
	private static inline final GC_STAT_MAX_THREAD_WAIT_MS:Int = 5;
	private static inline final GC_STAT_LAST_RECLAIMED_BYTES:Int = 6;
	private static inline final GC_STAT_TOTAL_RECLAIMED_BYTES:Int = 7;
	private static inline final GC_STAT_LAST_FLAGS:Int = 8;

	public static var explicitCollections(default, null):Int = 0;
	public static var lastCollectionDurationMs(default, null):Float = 0;
	public static var lastCollectionFreedBytes(default, null):Float = 0;

	public static inline function supportsManualCollection():Bool
		return GCBackend.canCollect();

	public static inline function supportsGCMem():Bool
		return GCBackend.hasHeapStats();

	public static inline function supportsCompaction():Bool
		return GCBackend.canCompact();

	/**
	 * Check if the current platform supports Task Memory retrieval.
	 * @return True if Task Memory is available on this platform
	 */
	public static function supportsTaskMem():Bool
	{
		#if ((windows && cpp) || linux || android)
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
		#elseif (linux || android)
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
		if (!supportsGCMem())
			return -1;
		return openfl.system.System.totalMemoryNumber;
	}

	public static function getGCCurrentMemory():Float
	{
		return GCBackend.currentMemory();
	}

	public static function getGCReservedMemory():Float
	{
		#if cpp
		return cpp.vm.Gc.memInfo64(cpp.vm.Gc.MEM_INFO_RESERVED);
		#else
		return -1;
		#end
	}

	public static function getGCLargeMemory():Float
	{
		#if cpp
		return cpp.vm.Gc.memInfo64(cpp.vm.Gc.MEM_INFO_LARGE);
		#else
		return -1;
		#end
	}

	public static function getRootGCStat(which:Int):Float
	{
		#if cpp
		return getNativeRootGCStat(which);
		#else
		return 0;
		#end
	}

	public static function supportsRootGCStats():Bool
	{
		#if cpp
		return nativeSupportsRootGCStats();
		#else
		return false;
		#end
	}

	public static inline function getRootGCCollectionCount():Int
	{
		return supportsRootGCStats() ? Std.int(getRootGCStat(GC_STAT_COLLECTIONS)) : -1;
	}

	#if cpp
	@:functionCode('
		#ifdef HXCPP_GC_RUNTIME_STATS
		return __hxcpp_gc_stat(which);
		#else
		return 0.0;
		#endif
	')
	private static function getNativeRootGCStat(which:Int):Float
	{
		return 0;
	}

	@:functionCode('
		#ifdef HXCPP_GC_RUNTIME_STATS
		return true;
		#else
		return false;
		#endif
	')
	private static function nativeSupportsRootGCStats():Bool
	{
		return false;
	}
	#end

	/**
	 * Enable garbage collection if it was previously disabled.
	 */
	public static function enable():Bool
	{
		return GCBackend.enable(true);
	}

	/**
	 * Disable garbage collection entirely.
	 */
	public static function disable():Bool
	{
		return GCBackend.enable(false);
	}

	/**
	 * Manually perform garbage collection once.
	 * Should only be called from the main thread.
	 * @param major `true` to perform major collection
	 */
	public static function collect(major:Bool = false):Bool
	{
		if (!supportsManualCollection())
			return false;
		var before:Float = getGCCurrentMemory();
		var start:Float = haxe.Timer.stamp();
		if (!GCBackend.collect(major))
			return false;
		lastCollectionDurationMs = (haxe.Timer.stamp() - start) * 1000;
		lastCollectionFreedBytes = Math.max(0, before - getGCCurrentMemory());
		explicitCollections++;
		return true;
	}

	/**
	 * Perform garbage collection compaction (reduces fragmentation).
	 */
	public static function compact():Bool
	{
		return GCBackend.compact();
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
		var gcMemory:Float = getGCMemory();
		var gcCurrent:Float = getGCCurrentMemory();
		var rootGCStatsAvailable:Bool = supportsRootGCStats();
		var stats:MemoryStats = {
			runtime: GCBackend.name(),
			heapStatsAvailable: supportsGCMem(),
			manualCollectionAvailable: supportsManualCollection(),
			compactionAvailable: supportsCompaction(),
			gcMemory: gcMemory,
			gcCurrent: gcCurrent,
			gcReserved: getGCReservedMemory(),
			gcLarge: getGCLargeMemory(),
			allocationGrowth: Math.max(0, gcCurrent - gcMemory),
			taskMemory: supportsTaskMem() ? getTaskMemory() : 0,
			systemRAM: getSystemRAM(),
			systemRAMGB: getSystemRAMInGB(),
			explicitCollections: explicitCollections,
			lastCollectionDurationMs: lastCollectionDurationMs,
			lastCollectionFreedBytes: lastCollectionFreedBytes,
			rootGCStatsAvailable: rootGCStatsAvailable,
			gcCollections: Std.int(getRootGCStat(GC_STAT_COLLECTIONS)),
			gcTotalDurationMs: getRootGCStat(GC_STAT_TOTAL_MS),
			gcLastDurationMs: getRootGCStat(GC_STAT_LAST_MS),
			gcMaxDurationMs: getRootGCStat(GC_STAT_MAX_MS),
			gcLastThreadWaitMs: getRootGCStat(GC_STAT_LAST_THREAD_WAIT_MS),
			gcMaxThreadWaitMs: getRootGCStat(GC_STAT_MAX_THREAD_WAIT_MS),
			gcLastReclaimedBytes: getRootGCStat(GC_STAT_LAST_RECLAIMED_BYTES),
			gcTotalReclaimedBytes: getRootGCStat(GC_STAT_TOTAL_RECLAIMED_BYTES),
			gcLastFlags: Std.int(getRootGCStat(GC_STAT_LAST_FLAGS))
		};
		return stats;
	}
}

/**
 * Memory statistics structure
 */
typedef MemoryStats =
{
	var runtime:String;
	var heapStatsAvailable:Bool;
	var manualCollectionAvailable:Bool;
	var compactionAvailable:Bool;
	/**
	 * Garbage collector memory usage (bytes)
	 */
	var gcMemory:Float;
	var gcCurrent:Float;
	var gcReserved:Float;
	var gcLarge:Float;
	/** Approximate heap growth since the last GC; it is not guaranteed garbage. */
	var allocationGrowth:Float;

	/**
	 * Task/Process memory usage (bytes) - actual RAM used by the app
	 */
	var taskMemory:Float;

	var explicitCollections:Int;
	var lastCollectionDurationMs:Float;
	var lastCollectionFreedBytes:Float;

	var rootGCStatsAvailable:Bool;
	var gcCollections:Int;
	var gcTotalDurationMs:Float;
	var gcLastDurationMs:Float;
	var gcMaxDurationMs:Float;
	var gcLastThreadWaitMs:Float;
	var gcMaxThreadWaitMs:Float;
	var gcLastReclaimedBytes:Float;
	var gcTotalReclaimedBytes:Float;
	var gcLastFlags:Int;

	/**
	 * Total system RAM (megabytes)
	 */
	var systemRAM:Float;

	/**
	 * Total system RAM (gigabytes)
	 */
	var systemRAMGB:Float;
}

