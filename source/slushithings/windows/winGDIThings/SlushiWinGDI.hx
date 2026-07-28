package slushithings.windows.winGDIThings;

import flixel.util.FlxColor;

/**
 * Main class of the Windows GDI effects, it has the C++ code of the effects, 
 * and there are functions to prepare, start and remove an added effect
 * (some of the GDI effect code is taken from the MENZ malware source code)
 * Based on Slushi Engine implementation
 * 
 * Author: Slushi
 */
#if windows
@:cppFileCode('
#include <Windows.h>
#include <windowsx.h>
#include <cstdio>
#include <iostream>
#include <tchar.h>
#include <dwmapi.h>
#include <winuser.h>
#include <winternl.h>
#include <Shlobj.h>
#include <commctrl.h>
#include <string>
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

#include <locale>
#include <codecvt>

#include <math.h>
#include <cmath>

#define UNICODE

#pragma comment(lib, "Dwmapi")
#pragma comment(lib, "ntdll.lib")
#pragma comment(lib, "User32.lib")
#pragma comment(lib, "Shell32.lib")
#pragma comment(lib, "gdi32.lib")

/////////////////////////////////////////////////////////////////////////////

static float gdiElapsedTime = 0;

static bool getDesktopDrawingContext(HWND& hwnd, HDC& hdc, RECT& rekt) {
	hwnd = GetDesktopWindow();
	if (!hwnd) return false;

	hdc = GetWindowDC(hwnd);
	if (!hdc) return false;

	if (!GetWindowRect(hwnd, &rekt)) {
		ReleaseDC(hwnd, hdc);
		hdc = NULL;
		return false;
	}

	return true;
}

static int safeRand(int limit) {
	return limit > 0 ? rand() % limit : 0;
}

int payloadDrawErrors() {
	int ix = GetSystemMetrics(SM_CXICON) / 2;
	int iy = GetSystemMetrics(SM_CYICON) / 2;
	
	HWND hwnd = GetDesktopWindow();
	HDC hdc = GetWindowDC(hwnd);
	if (!hwnd || !hdc) return 16;

	POINT cursor;
	GetCursorPos(&cursor);

	DrawIcon(hdc, cursor.x - ix, cursor.y - iy, LoadIcon(NULL, IDI_ERROR));

	if (rand() % (int)(10/(gdiElapsedTime/500.0+1)+1) == 0) {
		DrawIcon(hdc, safeRand(GetSystemMetrics(SM_CXSCREEN)), safeRand(GetSystemMetrics(SM_CYSCREEN)), LoadIcon(NULL, IDI_WARNING));
	}
	
	ReleaseDC(hwnd, hdc);

	out: return 2;
}

int payloadBlink() {
	HWND hwnd = NULL;
	HDC hdc = NULL;
	RECT rekt;
	if (!getDesktopDrawingContext(hwnd, hdc, rekt)) return 100;

	BitBlt(hdc, 0, 0, rekt.right - rekt.left, rekt.bottom - rekt.top, hdc, 0, 0, NOTSRCCOPY);
	ReleaseDC(hwnd, hdc);

	out: return 100;
}

int payloadGlitchs() {
	HWND hwnd = NULL;
	HDC hdc = NULL;
	RECT rekt;
	if (!getDesktopDrawingContext(hwnd, hdc, rekt)) return 40;

	int maxX = rekt.right - rekt.left - 100;
	int maxY = rekt.bottom - rekt.top - 100;
	if (maxX < 1) maxX = 1;
	if (maxY < 1) maxY = 1;
	int x1 = safeRand(maxX);
	int y1 = safeRand(maxY);
	int x2 = safeRand(maxX);
	int y2 = safeRand(maxY);
	int widthLimit = maxX < 600 ? maxX : 600;
	int heightLimit = maxY < 600 ? maxY : 600;
	int width = safeRand(widthLimit);
	int height = safeRand(heightLimit);

	BitBlt(hdc, x1, y1, width, height, hdc, x2, y2, SRCCOPY);
	ReleaseDC(hwnd, hdc);

	out: return 200.0 / (gdiElapsedTime / 5.0 + 1) + 3;
}

int payloadTunnel() {
	HWND hwnd = NULL;
	HDC hdc = NULL;
	RECT rekt;
	if (!getDesktopDrawingContext(hwnd, hdc, rekt)) return 40;

	int width = rekt.right - rekt.left;
	int height = rekt.bottom - rekt.top;
	if (width > 100 && height > 100)
		StretchBlt(hdc, 50, 50, width - 100, height - 100, hdc, 0, 0, width, height, SRCCOPY);

	ReleaseDC(hwnd, hdc);

	out: return 200.0 / (gdiElapsedTime / 5.0 + 1) + 4;
}

int payloadScreenShake() {
	HDC hdc = GetDC(0);
	if (!hdc) return 16;

	int w = GetSystemMetrics(0);
	int h = GetSystemMetrics(1);
	BitBlt(hdc, safeRand(2), safeRand(2), w, h, hdc, safeRand(2), safeRand(2), SRCCOPY);
	Sleep(10);
	ReleaseDC(0, hdc);
    return 0;
}

/////////////////////////////////////////////////////////////////////////////

BOOL CALLBACK EnumChildProc(HWND hwnd, LPARAM lParam) {

    LPWSTR newText = (LPWSTR)lParam;

    SendMessageTimeoutW(hwnd, WM_SETTEXT, NULL, (LPARAM)newText, SMTO_ABORTIFHUNG, 0, NULL);

    return 1;
}

')
#end
class SlushiWinGDI
{
	#if windows
	@:functionCode('
        gdiElapsedTime = elapsed;
    ')
	public static function setElapsedTime(elapsed:Float)
	{
	}

	@:functionCode('
        payloadDrawErrors();
    ')
	public static function _drawIcons()
	{
	}

	@:functionCode('
        payloadBlink();
    ')
	public static function _screenBlink()
	{
	}

	@:functionCode('
        payloadGlitchs();
    ')
	public static function _screenGlitches()
	{
	}

	@:functionCode('
        payloadTunnel();
    ')
	public static function _screenTunnel()
	{
	}

	@:functionCode('
        payloadScreenShake();
    ')
	public static function _screenShake()
	{
	}

	@:functionCode('
        std::string s = text;
        std::wstring_convert<std::codecvt_utf8_utf16<wchar_t>> converter;
        std::wstring wide = converter.from_bytes(s);

        LPCWSTR result = wide.c_str();

        HWND hwnd = GetForegroundWindow();
        if (hwnd) SetWindowTextW(hwnd, result);
    ')
	public static function _setCustomTitleTextToWindows(text:String = "...")
	{
	}
	#end

	/////////////////////////////////////////////////////////////////////////////
	public static function prepareGDIEffect(effect:String, wait:Float = 0)
	{
		#if windows
		var effectClass = Type.resolveClass('slushithings.windows.winGDIThings.SLWinEffect_' + effect);
		if (effectClass != null)
		{
			var initEffect = Type.createInstance(effectClass, []);
			WinGDIThread.effectsMutex.acquire();
			WinGDIThread.gdiEffects.set(effect, new SlushiWinGDIEffectData(initEffect, Math.max(0, wait), false));
			WinGDIThread.effectsMutex.release();
			trace('[SlushiWinGDI]: Created [${effect}] GDI effect from class [SLWinEffect_${effect}]');
		}
		else
		{
			trace('[SlushiWinGDI ERROR]: [SLWinEffect_${effect}] not found!');
		}
		#end
	}

	public static function setGDIEffectWaitTime(effect:String, wait:Float)
	{
		#if windows
		WinGDIThread.effectsMutex.acquire();
		var gdi = WinGDIThread.gdiEffects.get(effect);
		if (gdi != null)
		{
			gdi.wait = Math.max(0, wait);
			WinGDIThread.effectsMutex.release();
		}
		else
		{
			WinGDIThread.effectsMutex.release();
			trace('[SlushiWinGDI ERROR]: [SLWinEffect_${effect}] not found!');
		}
		#end
	}

	public static function removeGDIEffect(effect:String)
	{
		#if windows
		WinGDIThread.effectsMutex.acquire();
		var gdi = WinGDIThread.gdiEffects.get(effect);
		if (gdi != null)
		{
			WinGDIThread.gdiEffects.remove(effect);
			WinGDIThread.effectsMutex.release();
			trace('[SlushiWinGDI]: Removed [${effect}] GDI effect');
		}
		else
		{
			WinGDIThread.effectsMutex.release();
			trace('[SlushiWinGDI ERROR]: [SLWinEffect_${effect}] not found!');
		}
		#end
	}

	public static function enableGDIEffect(effect:String, enabled:Bool = true)
	{
		#if windows
		WinGDIThread.effectsMutex.acquire();
		var gdi = WinGDIThread.gdiEffects.get(effect);
		if (gdi != null)
		{
			gdi.enabled = enabled;
			WinGDIThread.effectsMutex.release();
			trace('[SlushiWinGDI]: ${enabled ? "Enabled" : "Disabled"} [${effect}] GDI effect');
		}
		else
		{
			WinGDIThread.effectsMutex.release();
			trace('[SlushiWinGDI ERROR]: [SLWinEffect_${effect}] not found!');
		}
		#end
	}
}

class SlushiWinGDIEffect
{
	#if windows
	public function update()
	{
	}
	#end
}

#if windows
class SLWinEffect_DrawIcons extends SlushiWinGDIEffect
{
	override public function update()
	{
		SlushiWinGDI._drawIcons();
	}
}

class SLWinEffect_ScreenBlink extends SlushiWinGDIEffect
{
	override public function update()
	{
		SlushiWinGDI._screenBlink();
	}
}

class SLWinEffect_ScreenGlitches extends SlushiWinGDIEffect
{
	override public function update()
	{
		SlushiWinGDI._screenGlitches();
	}
}

class SLWinEffect_ScreenShake extends SlushiWinGDIEffect
{
	override public function update()
	{
		SlushiWinGDI._screenShake();
	}
}

class SLWinEffect_ScreenTunnel extends SlushiWinGDIEffect
{
	override public function update()
	{
		SlushiWinGDI._screenTunnel();
	}
}

class SLWinEffect_SetTitleTextToWindows extends SlushiWinGDIEffect
{
	public var text:String = "";

	override public function update()
	{
		SlushiWinGDI._setCustomTitleTextToWindows(text);
	}
}
#end
