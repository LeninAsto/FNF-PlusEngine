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

int payloadDrawErrors() {
	int ix = GetSystemMetrics(SM_CXICON) / 2;
	int iy = GetSystemMetrics(SM_CYICON) / 2;
	
	HWND hwnd = GetDesktopWindow();
	HDC hdc = GetWindowDC(hwnd);

	POINT cursor;
	GetCursorPos(&cursor);

	DrawIcon(hdc, cursor.x - ix, cursor.y - iy, LoadIcon(NULL, IDI_ERROR));

	if (rand() % (int)(10/(gdiElapsedTime/500.0+1)+1) == 0) {
		DrawIcon(hdc, rand()%GetSystemMetrics(SM_CXSCREEN), rand()%GetSystemMetrics(SM_CYSCREEN), LoadIcon(NULL, IDI_WARNING));
	}
	
	ReleaseDC(hwnd, hdc);

	out: return 2;
}

int payloadBlink() {
	HWND hwnd = GetDesktopWindow();
	HDC hdc = GetWindowDC(hwnd);
	RECT rekt;
	GetWindowRect(hwnd, &rekt);
	BitBlt(hdc, 0, 0, rekt.right - rekt.left, rekt.bottom - rekt.top, hdc, 0, 0, NOTSRCCOPY);
	ReleaseDC(hwnd, hdc);

	out: return 100;
}

int payloadGlitchs() {
	HWND hwnd = GetDesktopWindow();
	HDC hdc = GetWindowDC(hwnd);
	RECT rekt;
	GetWindowRect(hwnd, &rekt);

	int x1 = rand() % (rekt.right - 100);
	int y1 = rand() % (rekt.bottom - 100);
	int x2 = rand() % (rekt.right - 100);
	int y2 = rand() % (rekt.bottom - 100);
	int width = rand() % 600;
	int height = rand() % 600;

	BitBlt(hdc, x1, y1, width, height, hdc, x2, y2, SRCCOPY);
	ReleaseDC(hwnd, hdc);

	out: return 200.0 / (gdiElapsedTime / 5.0 + 1) + 3;
}

int payloadTunnel() {
	HWND hwnd = GetDesktopWindow();
	HDC hdc = GetWindowDC(hwnd);
	RECT rekt;
	GetWindowRect(hwnd, &rekt);
	StretchBlt(hdc, 50, 50, rekt.right - 100, rekt.bottom - 100, hdc, 0, 0, rekt.right, rekt.bottom, SRCCOPY);
	ReleaseDC(hwnd, hdc);

	out: return 200.0 / (gdiElapsedTime / 5.0 + 1) + 4;
}

int payloadScreenShake() {
	HDC hdc = GetDC(0);
	int x = SM_CXSCREEN;
	int y = SM_CYSCREEN;
	int w = GetSystemMetrics(0);
	int h = GetSystemMetrics(1);
	BitBlt(hdc, rand() % 2, rand() % 2, w, h, hdc, rand() % 2, rand() % 2, SRCCOPY);
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

        EnumChildWindows(GetDesktopWindow(), EnumChildProc, (LPARAM)result);
    ')
	public static function _setCustomTitleTextToWindows(text:String = "...")
	{
	}
	#end

	/////////////////////////////////////////////////////////////////////////////
	public static function prepareGDIEffect(effect:String, wait:Float = 0)
	{
		#if windows
		var effectClass = Type.resolveClass('lenin.slushithings.windows.winGDIThings.SLWinEffect_' + effect);
		if (effectClass != null)
		{
			var initEffect = Type.createInstance(effectClass, []);
			WinGDIThread.gdiEffects.set(effect, new SlushiWinGDIEffectData(initEffect, wait, false));
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
		var gdi = WinGDIThread.gdiEffects.get(effect);
		if (gdi != null)
		{
			gdi.wait = wait;
		}
		else
		{
			trace('[SlushiWinGDI ERROR]: [SLWinEffect_${effect}] not found!');
		}
		#end
	}

	public static function removeGDIEffect(effect:String)
	{
		#if windows
		var gdi = WinGDIThread.gdiEffects.get(effect);
		if (gdi != null)
		{
			WinGDIThread.gdiEffects.remove(effect);
			trace('[SlushiWinGDI]: Removed [${effect}] GDI effect');
		}
		else
		{
			trace('[SlushiWinGDI ERROR]: [SLWinEffect_${effect}] not found!');
		}
		#end
	}

	public static function enableGDIEffect(effect:String, enabled:Bool = true)
	{
		#if windows
		var gdi = WinGDIThread.gdiEffects.get(effect);
		if (gdi != null)
		{
			gdi.enabled = enabled;
			trace('[SlushiWinGDI]: ${enabled ? "Enabled" : "Disabled"} [${effect}] GDI effect');
		}
		else
		{
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