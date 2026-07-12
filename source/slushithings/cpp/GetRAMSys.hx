package slushithings.cpp;

import cpp.ConstCharStar;
import cpp.Native;
import cpp.UInt64;

#if cpp
#if linux
@:headerCode('
#include <stdio.h>
')
#elseif windows
@:headerCode('
#include <Windows.h>
#include <cstdio>
#include <iostream>
#include <tchar.h>
#include <dwmapi.h>
#include <winuser.h>
#undef TRUE
#undef FALSE
#undef BOOLEAN
#undef ERROR
#undef NO_ERROR
#undef DELETE
#undef OPTIONS
#undef IN
#undef OUT
#undef ALTERNATE
#undef OPTIONAL
#undef DOUBLE_CLICK
#undef DIFFERENCE
#undef POINT
#undef RECT
#undef OVERFLOW
#undef UNDERFLOW
#undef DOMAIN
#undef TRANSPARENT
#undef CONST
#undef CopyFile
#undef COLOR_HIGHLIGHT
#undef __valid
')
#elseif macos
@:cppFileCode('
#include <sys/sysctl.h>
')
#end
#end
/**
 * Cross-platform RAM detection system
 * Detects the TOTAL PHYSICAL RAM installed in the system
 * 
 * Based on Slushi Engine implementation
 * 
 * Supports:
 * - Windows (via GetPhysicallyInstalledSystemMemory)
 * - Linux (via /proc/meminfo)
 * - macOS (via sysctl)
 */
class GetRAMSys
{
	#if cpp
	#if linux
	@:functionCode('
		FILE *meminfo = fopen("/proc/meminfo", "r");

		if(meminfo == NULL)
			return -1;

		char line[256];
		while(fgets(line, sizeof(line), meminfo))
		{
			int ram;
			if(sscanf(line, "MemTotal: %d kB", &ram) == 1)
			{
				fclose(meminfo);
				return (ram / 1024);
			}
		}

		fclose(meminfo);
		return -1;
	')
	#elseif windows
	@:functionCode('
		unsigned long long allocatedRAM = 0;
		GetPhysicallyInstalledSystemMemory(&allocatedRAM);
		return (allocatedRAM / 1024);
	')
	#elseif macos
	@:functionCode('
	int mib [] = { CTL_HW, HW_MEMSIZE };
	int64_t value = 0;
	size_t length = sizeof(value);

	if(-1 == sysctl(mib, 2, &value, &length, NULL, 0))
		return -1; // An error occurred

	return value / 1024 / 1024;
	')
	#end
	/**
	 * Obtains the total physical RAM installed in the system
	 * @return Total RAM in Megabytes (MB), or -1 if error
	 */
	public static function obtainRAM():UInt64
	{
		return 0;
	}
	#end
}