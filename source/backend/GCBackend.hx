package backend;

/** Runtime capabilities. Resource lifetime policy stays in MemoryManager. */
class GCBackend
{
	public static inline function name():String
	{
		#if cpp
		return 'hxcpp';
		#elseif hl
		return 'HashLink';
		#elseif js
		return 'JavaScript (automatic)';
		#else
		return 'automatic runtime';
		#end
	}

	public static inline function canCollect():Bool
	{
		#if (cpp || hl)
		return true;
		#else
		return false;
		#end
	}

	public static inline function hasHeapStats():Bool
		return canCollect();

	public static inline function canCompact():Bool
	{
		#if cpp
		return true;
		#else
		return false;
		#end
	}

	public static function enable(enabled:Bool):Bool
	{
		#if cpp
		cpp.NativeGc.enable(enabled);
		#elseif hl
		hl.Gc.enable(enabled);
		#else
		return false;
		#end
		return true;
	}

	public static function collect(major:Bool):Bool
	{
		#if cpp
		cpp.NativeGc.run(major);
		#elseif hl
		hl.Gc.major();
		#else
		return false;
		#end
		return true;
	}

	public static function compact():Bool
	{
		#if cpp
		cpp.NativeGc.compact();
		return true;
		#else
		return false;
		#end
	}

	/** -1 means unavailable, rather than an empty heap. */
	public static function currentMemory():Float
	{
		#if cpp
		return cpp.vm.Gc.memInfo64(cpp.vm.Gc.MEM_INFO_CURRENT);
		#elseif hl
		return hl.Gc.stats().currentMemory;
		#else
		return -1;
		#end
	}
}
