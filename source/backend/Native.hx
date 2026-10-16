package backend;

import lime.app.Application;
import lime.system.Display;
import lime.system.System;
import flixel.FlxG;
import flixel.util.FlxColor;
import flixel.util.FlxStringUtil;
#if lime_openal
import lime.media.openal.AL;
#end
#if cpp
import cpp.vm.Gc;
#end

#if (cpp && windows)
@:buildXml('
<target id="haxe">
	<lib name="dwmapi.lib" if="windows"/>
	<lib name="gdi32.lib" if="windows"/>
	<lib name="user32.lib" if="windows"/>
</target>
')
@:cppFileCode('
#include <windows.h>
#include <dwmapi.h>
#include <winuser.h>
#include <wingdi.h>
#include <string>

#define attributeDarkMode 20
#define attributeDarkModeFallback 19

#define attributeCaptionColor 34
#define attributeTextColor 35
#define attributeBorderColor 36

struct HandleData {
	DWORD pid = 0;
	HWND handle = 0;
};

BOOL CALLBACK findByPID(HWND handle, LPARAM lParam) {
	DWORD targetPID = ((HandleData*)lParam)->pid;
	DWORD curPID = 0;

	GetWindowThreadProcessId(handle, &curPID);
	if (targetPID != curPID || GetWindow(handle, GW_OWNER) != (HWND)0 || !IsWindowVisible(handle)) {
		return TRUE;
	}

	((HandleData*)lParam)->handle = handle;
	return FALSE;
}

HWND curHandle = 0;
HANDLE plusEngineInstanceMutex = NULL;
static const char* PLUS_ENGINE_INSTANCE_PREFIX = "Local\\\\PlusEngine_InstanceSlot_";

void getHandle() {
	if (curHandle == (HWND)0) {
		HandleData data;
		data.pid = GetCurrentProcessId();
		EnumWindows(findByPID, (LPARAM)&data);
		curHandle = data.handle;
	}
}
')
#end
class Native
{
	public static function __init__():Void
	{
		registerDPIAware();
	}

	public static function reserveInstanceSlot(maxInstances:Int = 1):Bool
	{
		#if (cpp && windows)
		if (maxInstances < 1)
			maxInstances = 1;

		return untyped __cpp__('
			([](int slotCount) -> bool {
				if (plusEngineInstanceMutex != NULL)
					return true;

				for (int i = 1; i <= slotCount; ++i) {
					std::string mutexName = std::string(PLUS_ENGINE_INSTANCE_PREFIX) + std::to_string(i);
					HANDLE handle = CreateMutexA(NULL, TRUE, mutexName.c_str());
					if (handle == NULL)
						continue;

					if (GetLastError() != ERROR_ALREADY_EXISTS) {
						plusEngineInstanceMutex = handle;
						return true;
					}

					CloseHandle(handle);
				}

				return false;
			})((int){0})
		', maxInstances);
		#else
		return true;
		#end
	}

	public static function showInstanceLimitMessage(maxInstances:Int = 1):Void
	{
		#if (cpp && windows)
		untyped __cpp__('
			([](int slotCount) {
				std::string message = "Plus Engine is already running.\\n\\nCurrent instance limit: "
					+ std::to_string(slotCount)
					+ "\\nYou can change the maximum instance slots from Options > Legacy Settings.";

				MessageBoxA(
					NULL,
					message.c_str(),
					"Plus Engine",
					MB_OK | MB_ICONEXCLAMATION | MB_SETFOREGROUND
				);
			})((int){0})
		', maxInstances);
		#end
	}

	public static function releaseInstanceSlot():Void
	{
		#if (cpp && windows)
		untyped __cpp__('
			if (plusEngineInstanceMutex != NULL) {
				ReleaseMutex(plusEngineInstanceMutex);
				CloseHandle(plusEngineInstanceMutex);
				plusEngineInstanceMutex = NULL;
			}
		');
		#end
	}

	public static function registerDPIAware():Void
	{
		#if (cpp && windows)
		// DPI Scaling fix for windows
		// this shouldn't be needed for other systems
		// Credit to YoshiCrafter29 for finding this function
		untyped __cpp__('
			SetProcessDPIAware();	
			#ifdef DPI_AWARENESS_CONTEXT
			SetProcessDpiAwarenessContext(
				#ifdef DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE_V2
				DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE_V2
				#else
				DPI_AWARENESS_CONTEXT_SYSTEM_AWARE
				#endif
			);
			#endif
		');
		#end
	}

	private static var fixedScaling:Bool = false;

	public static function fixScaling():Void
	{
		if (fixedScaling)
			return;
		fixedScaling = true;

		#if (cpp && windows)
		final display:Null<Display> = System.getDisplay(0);
		if (display != null)
		{
			final dpiScale:Float = display.dpi / 96;
			@:privateAccess Application.current.window.width = Std.int(Main.game.width * dpiScale);
			@:privateAccess Application.current.window.height = Std.int(Main.game.height * dpiScale);

			Application.current.window.x = Std.int((Application.current.window.display.bounds.width - Application.current.window.width) / 2);
			Application.current.window.y = Std.int((Application.current.window.display.bounds.height - Application.current.window.height) / 2);
		}

		untyped __cpp__('
			getHandle();
			if (curHandle != (HWND)0) {
				HDC curHDC = GetDC(curHandle);
				RECT curRect;
				GetClientRect(curHandle, &curRect);
				FillRect(curHDC, &curRect, (HBRUSH)GetStockObject(BLACK_BRUSH));
				ReleaseDC(curHandle, curHDC);
			}
		');
		#end
	}

	/**
	 * Builds a simplified system information report.
	 * Shows the GPU, exact OpenGL runtime and OpenAL Soft runtime.
	 */
	public static function buildSystemInfo():String
	{
		var info = '';

		// GPU Detection
		var gpuName = detectGPU();

		if (gpuName != null && gpuName != 'N/A' && gpuName != 'Unknown')
		{
			info += 'GPU: ${gpuName}\n';
		}
		else
		{
			info += 'GPU: Unknown\n';
		}

		info += 'OpenGL: ${getOpenGLVersion()}\n';
		info += 'OpenAL Soft: ${getOpenALSoftVersion()}\n';

		return info;
	}

	/** Returns GL_VERSION exactly as reported by the active driver. */
	public static function getOpenGLVersion():String
	{
		#if (!flash && sys)
		try
		{
			@:privateAccess
			final gl = FlxG.stage.context3D.gl;
			if (gl != null)
			{
				final version:Dynamic = gl.getParameter(gl.VERSION);
				if (version != null && StringTools.trim(Std.string(version)) != '')
					return StringTools.trim(Std.string(version));
			}
		}
		catch (e:Dynamic) {}
		#end
		return 'Unable to detect';
	}

	/** Short runtime label used by debug overlays, e.g. OpenGL ES 3.2. */
	public static function getOpenGLLabel():String
	{
		final raw = getOpenGLVersion();
		if (raw == 'Unable to detect')
			return 'OpenGL Unknown';

		final isES = raw.toUpperCase().indexOf('OPENGL ES') != -1;
		final version = ~/([0-9]+\.[0-9]+(?:\.[0-9]+)?)/;
		return 'OpenGL${isES ? ' ES' : ''} ${version.match(raw) ? version.matched(1) : raw}';
	}

	/** Reports the active OpenAL implementation and its exact runtime version. */
	public static function getOpenALSoftVersion():String
	{
		#if lime_openal
		try
		{
			final renderer = StringTools.trim(AL.getString(AL.RENDERER));
			final version = StringTools.trim(AL.getString(AL.VERSION));
			if (renderer != '' && version != '')
				return '$renderer | $version';
			if (version != '')
				return version;
		}
		catch (e:Dynamic) {}
		#end
		return 'Unable to detect';
	}

	/**
	 * Detects GPU name using multiple methods.
	 * Priority: OpenGL GL_RENDERER > driverInfo > fallback
	 */
	private static function detectGPU():String
	{
		#if (!flash && sys)
		try
		{
			@:privateAccess
			var gl = FlxG.stage.context3D.gl;
			if (gl != null)
			{
				// Method 1: GL_RENDERER (most reliable for Android)
				var renderer = gl.getParameter(gl.RENDERER);
				if (renderer != null && renderer != '')
				{
					var parsed = parseGPUName(renderer);
					if (parsed != null && parsed != 'Unknown')
					{
						return parsed;
					}
				}

				// Method 2: GL_VENDOR + GL_RENDERER combined
				var vendor = gl.getParameter(gl.VENDOR);
				if (vendor != null && vendor != '' && renderer != null)
				{
					var combined = vendor + ' ' + renderer;
					var parsed = parseGPUName(combined);
					if (parsed != null && parsed != 'Unknown')
					{
						return parsed;
					}
				}
			}
		}
		catch (e:Dynamic)
		{
			trace('GPU detection via OpenGL failed: $e');
		}
		#end

		// Method 3: Fallback to driverInfo
		var driverInfo = FlxG?.stage?.context3D?.driverInfo ?? 'N/A';
		var parsed = parseGPUName(driverInfo);
		return parsed ?? 'Unknown';
	}

	/**
	 * Parses GPU name from driver info string.
	 * Examples: "OpenGL ES 3.0 NVIDIA GeForce RTX 3050" -> "NVIDIA GeForce RTX 3050"
	 */
	private static function parseGPUName(driverInfo:String):Null<String>
	{
		if (driverInfo == null || driverInfo == 'N/A' || driverInfo == '')
			return null;

		// Remove common prefixes
		var info = driverInfo;
		info = StringTools.replace(info, 'OpenGL ES 3.2 ', '');
		info = StringTools.replace(info, 'OpenGL ES 3.1 ', '');
		info = StringTools.replace(info, 'OpenGL ES 3.0 ', '');
		info = StringTools.replace(info, 'OpenGL ES 2.0 ', '');
		info = StringTools.replace(info, 'OpenGL ES ', '');
		info = StringTools.replace(info, 'OpenGL ', '');
		info = StringTools.trim(info);

		// Mobile GPU patterns (Android)
		if (info.indexOf('Adreno') != -1)
		{
			// Qualcomm Adreno (most common in Android)
			var pattern = ~/Adreno.*?(\d{3})/;
			if (pattern.match(info))
			{
				return 'Qualcomm Adreno ' + pattern.matched(1);
			}
			// Fallback: just return what we have
			var start = info.indexOf('Adreno');
			return info.substring(start).split(' ').slice(0, 3).join(' ');
		}

		if (info.indexOf('Mali') != -1)
		{
			// ARM Mali GPU
			var pattern = ~/Mali-([GT]\d+)/;
			if (pattern.match(info))
			{
				return 'ARM Mali-' + pattern.matched(1);
			}
			var start = info.indexOf('Mali');
			return 'ARM ' + info.substring(start).split(' ').slice(0, 2).join(' ');
		}

		if (info.indexOf('PowerVR') != -1 || info.indexOf('SGX') != -1)
		{
			// Imagination PowerVR
			var start = info.indexOf('PowerVR');
			if (start == -1)
				start = info.indexOf('SGX');
			return 'PowerVR ' + info.substring(start).split(' ').slice(0, 2).join(' ');
		}

		if (info.indexOf('Tegra') != -1)
		{
			// NVIDIA Tegra (mobile)
			return info.substring(info.indexOf('Tegra')).split('/')[0].trim();
		}

		if (info.indexOf('Vivante') != -1 || info.indexOf('GC') != -1)
		{
			// Vivante GPU
			return info.indexOf('Vivante') != -1 ? 'Vivante GPU' : info;
		}

		// Desktop GPU patterns
		if (info.indexOf('NVIDIA') != -1 || info.indexOf('GeForce') != -1 || info.indexOf('RTX') != -1 || info.indexOf('GTX') != -1)
		{
			// NVIDIA card detected
			var start = info.indexOf('NVIDIA');
			if (start == -1)
				start = info.indexOf('GeForce');
			if (start == -1)
				start = info.indexOf('RTX');
			if (start == -1)
				start = info.indexOf('GTX');
			if (start != -1)
			{
				return info.substring(start).split('/')[0].trim();
			}
		}

		if (info.indexOf('AMD') != -1 || info.indexOf('Radeon') != -1)
		{
			// AMD card detected
			var start = info.indexOf('AMD');
			if (start == -1)
				start = info.indexOf('Radeon');
			if (start != -1)
			{
				return info.substring(start).split('/')[0].trim();
			}
		}

		if (info.indexOf('Intel') != -1)
		{
			// Intel card detected
			var start = info.indexOf('Intel');
			if (start != -1)
			{
				return info.substring(start).split('/')[0].trim();
			}
		}

		// If no specific pattern matched, return cleaned info if reasonable
		if (info.length > 0 && info.length < 100)
		{
			// Remove version numbers and common suffixes
			info = StringTools.replace(info, 'v@', '');
			return info.split('/')[0].trim();
		}

		return null;
	}

	/**
	 * Checks if the system supports modern OpenGL (3.3+) or OpenGL ES (3.0+)
	 */
	private static function checkModernGLSupport(glslVersion:String):Bool
	{
		if (glslVersion == null || glslVersion == '')
			return false;

		#if lime_opengles
		// OpenGL ES - check for 3.0+
		var version_part = StringTools.replace(glslVersion, "OpenGL ES GLSL ES ", "");
		var versionNum = Std.parseInt(StringTools.replace(version_part, ".", ""));
		return versionNum != null && versionNum >= 300;
		#else
		// Desktop OpenGL - check for 3.3+
		var versionNum = Std.parseInt(glslVersion.split(" ")[0].replace(".", ""));
		return versionNum != null && versionNum >= 330;
		#end
	}

	/**
	 * Gets enhancement status based on detected GPU
	 */
	public static function getGPUEnhancements():String
	{
		var gpuName = detectGPU();

		if (gpuName == null || gpuName == 'Unknown')
			return "Unknown GPU - Using standard settings";

		var gpu = gpuName.toLowerCase();

		// Mobile GPUs (Android/iOS)
		if (gpu.indexOf('adreno') != -1)
		{
			// Qualcomm Adreno
			var modelMatch = ~/(\d{3})/;
			if (modelMatch.match(gpu))
			{
				var model = Std.parseInt(modelMatch.matched(1));
				if (model >= 700)
					return "High-end mobile GPU (Adreno 7xx+) - Full features enabled";
				if (model >= 600)
					return "Mid-range mobile GPU (Adreno 6xx) - Good performance";
				return "Entry-level mobile GPU - Consider lowering quality";
			}
			return "Qualcomm Adreno GPU detected";
		}

		if (gpu.indexOf('mali') != -1)
		{
			// ARM Mali
			if (gpu.indexOf('g7') != -1 || gpu.indexOf('g8') != -1)
			{
				return "High-end mobile GPU (Mali-G7x/G8x) - Full features enabled";
			}
			if (gpu.indexOf('g5') != -1 || gpu.indexOf('g6') != -1)
			{
				return "Mid-range mobile GPU (Mali-G5x/G6x) - Good performance";
			}
			return "ARM Mali GPU detected - Standard mobile settings";
		}

		if (gpu.indexOf('powervr') != -1 || gpu.indexOf('sgx') != -1)
		{
			return "PowerVR GPU detected - Standard mobile settings";
		}

		if (gpu.indexOf('tegra') != -1)
		{
			return "NVIDIA Tegra GPU detected - Good mobile performance";
		}

		// Desktop GPUs
		if (gpu.indexOf('rtx') != -1 || gpu.indexOf('rx 7') != -1 || gpu.indexOf('rx 6') != -1)
		{
			return "High-end GPU detected - All features enabled";
		}

		if (gpu.indexOf('gtx 16') != -1 || gpu.indexOf('gtx 10') != -1 || gpu.indexOf('rx 5') != -1 || gpu.indexOf('vega') != -1)
		{
			return "Mid-range GPU detected - Full shader support";
		}

		if (gpu.indexOf('intel') != -1 || gpu.indexOf('uhd') != -1 || gpu.indexOf('iris') != -1)
		{
			return "Integrated GPU detected - Consider lowering quality for better performance";
		}

		return "GPU detected - Standard features enabled";
	}
}

