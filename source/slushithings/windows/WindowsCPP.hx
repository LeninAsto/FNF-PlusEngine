package slushithings.windows;

/**
 * Windows API for Screenshot Capture
 * Based on Slushi Engine implementation
 */
@:buildXml('
<compilerflag value="/DelayLoad:ComCtl32.dll"/>

<target id="haxe">
    <lib name="dwmapi.lib" if="windows" />
    <lib name="shell32.lib" if="windows" />
    <lib name="gdi32.lib" if="windows" />
    <lib name="user32.lib" if="windows" />
    <lib name="psapi.lib" if="windows" />
</target>
')
#if windows
@:cppFileCode('
#ifndef SCREENSHOT_CPP_INCLUDED
#define SCREENSHOT_CPP_INCLUDED

#include <Windows.h>
#include <windowsx.h>
#include <cstdio>
#include <iostream>
#include <tchar.h>
#include <wingdi.h>
#include <winuser.h>
#include <dwmapi.h>
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

#include <chrono>
#include <thread>
#include <sysinfoapi.h>
#include <psapi.h>

#define UNICODE

#pragma comment(lib, "Dwmapi")
#pragma comment(lib, "ntdll.lib")
#pragma comment(lib, "user32.lib")
#pragma comment(lib, "Shell32.lib")
#pragma comment(lib, "gdi32.lib")
#pragma comment(lib, "psapi.lib")

// This is so that all window-related functions ALWAYS apply to the engine window.
static std::string globalWindowTitle = "Friday Night Funkin\': Plus Engine";

// Get the active window handle
static HWND GET_WINDOW() {
    return GetForegroundWindow();
}

// Get the engine window by title
static HWND GET_ENGINE_WINDOW() {
	HWND hwnd = GetForegroundWindow();
    char windowTitle[256];

    GetWindowTextA(hwnd, windowTitle, sizeof(windowTitle));

    if (globalWindowTitle == windowTitle) {
        return hwnd;
    }

    return FindWindowA(NULL, globalWindowTitle.c_str());
}

//////////////////////////////////////////////////////////////////////////////////////////////////////

static BOOL SaveToFile(HBITMAP hBitmap3, LPCTSTR lpszFileName)
{   
	HDC hDC;
	int iBits;
	WORD wBitCount;
	DWORD dwPaletteSize=0, dwBmBitsSize=0, dwDIBSize=0, dwWritten=0;
	BITMAP Bitmap0;
	BITMAPFILEHEADER bmfHdr;
	BITMAPINFOHEADER bi;
	LPBITMAPINFOHEADER lpbi;
	HANDLE fh, hDib, hPal,hOldPal2=NULL;
	hDC = CreateDC("DISPLAY", NULL, NULL, NULL);
	iBits = GetDeviceCaps(hDC, BITSPIXEL) * GetDeviceCaps(hDC, PLANES);
	DeleteDC(hDC);
	if (iBits <= 1)
		wBitCount = 1;
	else if (iBits <= 4)
		wBitCount = 4;
	else if (iBits <= 8)
		wBitCount = 8;
	else
		wBitCount = 24; 
	GetObject(hBitmap3, sizeof(Bitmap0), (LPSTR)&Bitmap0);
	bi.biSize = sizeof(BITMAPINFOHEADER);
	bi.biWidth = Bitmap0.bmWidth;
	bi.biHeight =-Bitmap0.bmHeight;
	bi.biPlanes = 1;
	bi.biBitCount = wBitCount;
	bi.biCompression = BI_RGB;
	bi.biSizeImage = 0;
	bi.biXPelsPerMeter = 0;
	bi.biYPelsPerMeter = 0;
	bi.biClrImportant = 0;
	bi.biClrUsed = 256;
	dwBmBitsSize = ((Bitmap0.bmWidth * wBitCount +31) & ~31) /8
													* Bitmap0.bmHeight; 
	hDib = GlobalAlloc(GHND,dwBmBitsSize + dwPaletteSize + sizeof(BITMAPINFOHEADER));
	lpbi = (LPBITMAPINFOHEADER)GlobalLock(hDib);
	*lpbi = bi;

	hPal = GetStockObject(DEFAULT_PALETTE);
	if (hPal)
	{ 
		hDC = GetDC(NULL);
		hOldPal2 = SelectPalette(hDC, (HPALETTE)hPal, 0);
		RealizePalette(hDC);
	}


	GetDIBits(hDC, hBitmap3, 0, (UINT) Bitmap0.bmHeight, (LPSTR)lpbi + sizeof(BITMAPINFOHEADER) 
		+dwPaletteSize, (BITMAPINFO *)lpbi, DIB_RGB_COLORS);

	if (hOldPal2)
	{
		SelectPalette(hDC, (HPALETTE)hOldPal2, 1);
		RealizePalette(hDC);
		ReleaseDC(NULL, hDC);
	}

	fh = CreateFile(lpszFileName, GENERIC_WRITE,0, NULL, CREATE_ALWAYS, 
		FILE_ATTRIBUTE_NORMAL | FILE_FLAG_SEQUENTIAL_SCAN, NULL); 

	if (fh == INVALID_HANDLE_VALUE)
		return 0; 

	bmfHdr.bfType = 0x4D42; // "BM"
	dwDIBSize = sizeof(BITMAPFILEHEADER) + sizeof(BITMAPINFOHEADER) + dwPaletteSize + dwBmBitsSize;
	bmfHdr.bfSize = dwDIBSize;
	bmfHdr.bfReserved1 = 0;
	bmfHdr.bfReserved2 = 0;
	bmfHdr.bfOffBits = (DWORD)sizeof(BITMAPFILEHEADER) + (DWORD)sizeof(BITMAPINFOHEADER) + dwPaletteSize;

	WriteFile(fh, (LPSTR)&bmfHdr, sizeof(BITMAPFILEHEADER), &dwWritten, NULL);

	WriteFile(fh, (LPSTR)lpbi, dwDIBSize, &dwWritten, NULL);
	GlobalUnlock(hDib);
	GlobalFree(hDib);
	CloseHandle(fh);

	return 1;
} 

static int screenCapture(int x, int y, int w, int h, LPCSTR fname)
{
    HDC hdcSource = GetDC(NULL);
    HDC hdcMemory = CreateCompatibleDC(hdcSource);

    int capX = GetDeviceCaps(hdcSource, HORZRES);
    int capY = GetDeviceCaps(hdcSource, VERTRES);

    HBITMAP hBitmap = CreateCompatibleBitmap(hdcSource, w, h);
    HBITMAP hBitmapOld = (HBITMAP)SelectObject(hdcMemory, hBitmap);

    BitBlt(hdcMemory, 0, 0, w, h, hdcSource, x, y, SRCCOPY);
    hBitmap = (HBITMAP)SelectObject(hdcMemory, hBitmapOld);

    DeleteDC(hdcSource);
    DeleteDC(hdcMemory);

    HPALETTE hpal = NULL;
    if(SaveToFile(hBitmap, fname)) return 1;
    return 0;
}

#endif // SCREENSHOT_CPP_INCLUDED
')
#end
class WindowsCPP
{
	#if windows
	/**
	 * Detects if running under Wine (Linux/Mac emulation)
	 * @return True if running under Wine, false otherwise
	 */
	@:functionCode('
		HMODULE ntdll = GetModuleHandleA("ntdll.dll");
		if (ntdll) {
			void* wine_get_version = GetProcAddress(ntdll, "wine_get_version");
			if (wine_get_version) {
				return true;
			}
		}
		return false;
	')
	public static function detectWine():Bool
	{
		return false;
	}

	/**
	 * Shows a native Windows MessageBox
	 * @param caption Title of the message box
	 * @param message Content of the message box
	 * @param icon Icon type (MSG_ERROR, MSG_WARNING, MSG_INFORMATION, MSG_QUESTION)
	 */
	@:functionCode('
		MessageBox(GET_ENGINE_WINDOW(), message, caption, icon | MB_SETFOREGROUND);
	')
	public static function showMessageBox(caption:String, message:String, icon:MessageBoxIcon = MSG_WARNING)
	{
	}

	/**
	 * Plays a beep sound through the default audio device
	 * @param freq Frequency in Hz
	 * @param duration Duration in milliseconds
	 */
	@:functionCode('
		Beep(freq, duration);
	')
	public static function beep(freq:Int, duration:Int)
	{
	}

	/**
	 * Redefines the main window title for finding the window
	 * @param windowTitle New window title to track
	 */
	@:functionCode('
		globalWindowTitle = windowTitle;
	')
	public static function reDefineEngineWindowTitle(windowTitle:String)
	{
	}

	/**
	 * Shows or hides the main window
	 * @param show True to show, false to hide
	 */
	@:functionCode('
		HWND hwnd = GET_ENGINE_WINDOW();
		if (show) {
			ShowWindow(hwnd, SW_SHOW);
		} else {
			ShowWindow(hwnd, SW_HIDE);
		}
    ')
	public static function setWindowVisible(show:Bool)
	{
	}

	/**
	 * Checks if the application is running with administrator privileges
	 * @return True if running as admin, false otherwise
	 */
	@:functionCode('
		BOOL isAdmin = 0;
		SID_IDENTIFIER_AUTHORITY ntAuthority = SECURITY_NT_AUTHORITY;
		PSID adminGroup = nullptr;

		if (AllocateAndInitializeSid(&ntAuthority, 2,
			SECURITY_BUILTIN_DOMAIN_RID, DOMAIN_ALIAS_RID_ADMINS,
			0, 0, 0, 0, 0, 0, &adminGroup)) {

			if (!CheckTokenMembership(nullptr, adminGroup, &isAdmin)) {
				isAdmin = 0;
			}

			FreeSid(adminGroup);
		}

		return isAdmin != 0;
	')
	public static function isRunningAsAdmin():Bool
	{
		return false;
	}

	/**
	 * Captures the full screen and saves it to a file
	 * @param path The path where to save the screenshot (must be absolute path)
	 */
	@:functionCode('
		int screenWidth = GetSystemMetrics(SM_CXSCREEN);
		int screenHeight = GetSystemMetrics(SM_CYSCREEN);
		screenCapture(0, 0, screenWidth, screenHeight, path);
	')
	public static function captureFullScreen(path:String):Void
	{
	}

	/**
	 * Captures only the game window and saves it to a file
	 * @param path The path where to save the screenshot (must be absolute path)
	 */
	@:functionCode('
		HWND hwnd = GET_ENGINE_WINDOW();
		if (hwnd) {
			RECT rc;
			GetClientRect(hwnd, &rc);
			int width = rc.right - rc.left;
			int height = rc.bottom - rc.top;
			
			POINT pt = {0, 0};
			ClientToScreen(hwnd, &pt);
			
			screenCapture(pt.x, pt.y, width, height, path);
		}
	')
	public static function captureGameWindow(path:String):Void
	{
	}

	/**
	 * Sets the window as layered to enable transparency effects
	 * Must be called before using setWindowAlpha
	 */
	@:functionCode('
		
		HWND window = GET_WINDOW();
		if (window) {
			SetWindowLong(window, GWL_EXSTYLE, GetWindowLong(window, GWL_EXSTYLE) ^ WS_EX_LAYERED);
		}
	')
	public static function setWindowLayered():Void
	{
	}

	/**
	 * Sets the window opacity/transparency
	 * @param alpha Alpha value from 0.0 (fully transparent) to 1.0 (fully opaque)
	 */
	@:functionCode('
		HWND window = GET_WINDOW();
		if (window) {
			float a = alpha;

			if (alpha > 1) {
				a = 1;
			} 
			if (alpha < 0) {
				a = 0;
			}

			SetLayeredWindowAttributes(window, 0, (255 * (a * 100)) / 100, LWA_ALPHA);
		}
	')
	public static function setWindowAlpha(alpha:Float):Void
	{
	}

	/**
	 * Gets the current window opacity/transparency
	 * @return Alpha value from 0.0 (fully transparent) to 1.0 (fully opaque)
	 */
	@:functionCode('
		HWND hwnd = GET_WINDOW();
		
		DWORD exStyle = GetWindowLong(hwnd, GWL_EXSTYLE);
		BYTE alpha = 255;
		
		if (exStyle & WS_EX_LAYERED) {
			DWORD flags;
			GetLayeredWindowAttributes(hwnd, NULL, &alpha, &flags);
		}

		float alphaFloat = static_cast<float>(alpha) / 255.0f;

		return alphaFloat;
	')
	public static function getWindowAlpha():Float
	{
		return 1.0;
	}

	/**
	 * Sets the window border color (Windows 11 only)
	 * @param r Red component (0-255)
	 * @param g Green component (0-255)
	 * @param b Blue component (0-255)
	 */
	@:functionCode('
		HWND window = GET_ENGINE_WINDOW();
		if (window) {
			auto color = RGB(r, g, b);
			
			if (S_OK != DwmSetWindowAttribute(window, 35, &color, sizeof(COLORREF))) {
				DwmSetWindowAttribute(window, 35, &color, sizeof(COLORREF));
			}

			if (S_OK != DwmSetWindowAttribute(window, 34, &color, sizeof(COLORREF))) {
				DwmSetWindowAttribute(window, 34, &color, sizeof(COLORREF));
			}

			UpdateWindow(window);
		}
	')
	public static function setWindowBorderColor(r:Int, g:Int, b:Int):Void
	{
	}

	/**
	 * Sets Slushi\'s signature color to the window border (Windows 11 only)
	 */
	@:functionCode('
        HWND window = GET_ENGINE_WINDOW();
		auto color = RGB(214, 243, 222);
		
        if (S_OK != DwmSetWindowAttribute(window, 35, &color, sizeof(COLORREF))) {
            DwmSetWindowAttribute(window, 35, &color, sizeof(COLORREF));
        }

		if (S_OK != DwmSetWindowAttribute(window, 34, &color, sizeof(COLORREF))) {
            DwmSetWindowAttribute(window, 34, &color, sizeof(COLORREF));
        }

        UpdateWindow(window);
    ')
	public static function setSlushiWindowColor()
	{
	}

	// === Desktop and System Control Functions ===

	/**
	 * Hides or shows the Windows taskbar
	 * @param hide True to hide, false to show
	 */
	@:functionCode('
		bool value = hide;
		HWND hwnd = FindWindowA("Shell_traywnd", nullptr);
		HWND hwnd2 = FindWindowA("Shell_SecondaryTrayWnd", nullptr);
	
		if (value == true) {
			ShowWindow(hwnd, SW_HIDE);
			ShowWindow(hwnd2, SW_HIDE);
		} else {
			ShowWindow(hwnd, SW_SHOW);
			ShowWindow(hwnd2, SW_SHOW);
		}
    ')
	public static function hideTaskbar(hide:Bool)
	{
	}

	/**
	 * Sets the Windows desktop wallpaper
	 * @param path Absolute path to the wallpaper image
	 */
	@:functionCode('
		const char* filepath = path;
	
		int uiAction = SPIF_UPDATEINIFILE | SPIF_SENDCHANGE;
		char filepathBuffer[MAX_PATH];
		strcpy_s(filepathBuffer, filepath);
	
		SystemParametersInfoA(SPI_SETDESKWALLPAPER, 0, filepathBuffer, uiAction);	
    ')
	public static function setWallpaper(path:String)
	{
	}

	/**
	 * Hides or shows desktop icons
	 * @param hide True to hide, false to show
	 */
	@:functionCode('
		bool value = hide;
		HWND hProgman = FindWindowW (L"Progman", L"Program Manager");
		HWND hChild = GetWindow (hProgman, GW_CHILD);
		
		if (value == true) {
			ShowWindow (hChild, SW_HIDE);
		} else {
			ShowWindow (hChild, SW_SHOW);
		}
    ')
	public static function hideDesktopIcons(hide:Bool)
	{
	}

	/**
	 * Moves desktop icons horizontally
	 * @param x X position
	 */
	@:functionCode('
		HWND hd;
		hd = FindWindowA("Progman", NULL);
		hd = FindWindowEx(hd, 0, "SHELLDLL_DefView", NULL);
		hd = FindWindowEx(hd, 0, "SysListView32", NULL);
		SetWindowPos(hd, NULL, x, NULL, 0, 0, SWP_NOSIZE | SWP_NOZORDER);
    ')
	public static function moveDesktopWindowsInX(x:Int)
	{
	}

	/**
	 * Moves desktop icons vertically
	 * @param y Y position
	 */
	@:functionCode('
		HWND hd;
		hd = FindWindowA("Progman", NULL);
		hd = FindWindowEx(hd, 0, "SHELLDLL_DefView", NULL);
		hd = FindWindowEx(hd, 0, "SysListView32", NULL);
		SetWindowPos(hd, NULL, NULL, y, 0, 0, SWP_NOSIZE | SWP_NOZORDER);
    ')
	public static function moveDesktopWindowsInY(y:Int)
	{
	}

	/**
	 * Moves desktop icons to a specific position
	 * @param x X position
	 * @param y Y position
	 */
	@:functionCode('
		HWND hd;
		hd = FindWindowA("Progman", NULL);
		hd = FindWindowEx(hd, 0, "SHELLDLL_DefView", NULL);
		hd = FindWindowEx(hd, 0, "SysListView32", NULL);
		SetWindowPos(hd, NULL, x, y, 0, 0, SWP_NOSIZE | SWP_NOZORDER);
    ')
	public static function moveDesktopWindowsInXY(x:Int, y:Int)
	{
	}

	/**
	 * Gets the X position of desktop icons
	 * @return X position
	 */
	@:functionCode('
		HWND hd;
		hd = FindWindowA("Progman", NULL);
		hd = FindWindowEx(hd, 0, "SHELLDLL_DefView", NULL);
		hd = FindWindowEx(hd, 0, "SysListView32", NULL);
		RECT rect;
		GetWindowRect(hd, &rect);
		int x = rect.left;
		return x;
	')
	public static function getDesktopWindowsXPos():Int
	{
		return 0;
	}

	/**
	 * Gets the Y position of desktop icons
	 * @return Y position
	 */
	@:functionCode('
		HWND hd;
		hd = FindWindowA("Progman", NULL);
		hd = FindWindowEx(hd, 0, "SHELLDLL_DefView", NULL);
		hd = FindWindowEx(hd, 0, "SysListView32", NULL);
		RECT rect;
		GetWindowRect(hd, &rect);
		int y = rect.top;
		return y;
	')
	public static function getDesktopWindowsYPos():Int
	{
		return 0;
	}

	/**
	 * Sets the transparency of desktop icons
	 * @param alpha Alpha value from 0.0 (fully transparent) to 1.0 (fully opaque)
	 */
	@:functionCode('
		HWND hProgman = FindWindowW(L"Progman", L"Program Manager");
		HWND hChild = GetWindow(hProgman, GW_CHILD);

		float a = alpha;
		if (alpha > 1) {
			a = 1;
		} 
		if (alpha < 0) {
			a = 0;
		}

       	SetLayeredWindowAttributes(hChild, 0, (255 * (a * 100)) / 100, LWA_ALPHA);
    ')
	public static function setDesktopWindowsAlpha(alpha:Float)
	{
	}

	/**
	 * Sets the transparency of the taskbar
	 * @param alpha Alpha value from 0.0 (fully transparent) to 1.0 (fully opaque)
	 */
	@:functionCode('
		HWND hwnd = FindWindowA("Shell_traywnd", nullptr);
		HWND hwnd2 = FindWindowA("Shell_SecondaryTrayWnd", nullptr);

		float a = alpha;
		if (alpha > 1) {
			a = 1;
		} 
		if (alpha < 0) {
			a = 0;
		}

       	SetLayeredWindowAttributes(hwnd, 0, (255 * (a * 100)) / 100, LWA_ALPHA);
		SetLayeredWindowAttributes(hwnd2, 0, (255 * (a * 100)) / 100, LWA_ALPHA);
    ')
	public static function setTaskBarAlpha(alpha:Float)
	{
	}

	/**
	 * Sets window layered mode for desktop or taskbar
	 * @param numberMode 0 for desktop, 1 for taskbar
	 */
	@:functionCode('
		HWND window;
		HWND window2;

		switch (numberMode) {
			case 0:
				window = FindWindowW(L"Progman", L"Program Manager");
				window = GetWindow(window, GW_CHILD);
				break;
			case 1:
				window = FindWindowA("Shell_traywnd", nullptr);
				window2 = FindWindowA("Shell_SecondaryTrayWnd", nullptr);
				break;
		}

		if (numberMode != 1) {
			SetWindowLong(window, GWL_EXSTYLE, GetWindowLong(window, GWL_EXSTYLE) ^ WS_EX_LAYERED);
		}
		else {
			SetWindowLong(window, GWL_EXSTYLE, GetWindowLong(window, GWL_EXSTYLE) ^ WS_EX_LAYERED);
			SetWindowLong(window2, GWL_EXSTYLE, GetWindowLong(window2, GWL_EXSTYLE) ^ WS_EX_LAYERED);
		}
	')
	public static function setWindowLayeredMode(numberMode:Int)
	{
	}

	/**
	 * Gets the actual screen width using GetSystemMetrics (DPI-aware and accurate)
	 * @return Screen width in pixels
	 */
	@:functionCode('
		return GetSystemMetrics(SM_CXSCREEN);
	')
	public static function getScreenWidth():Int
	{
		return 0;
	}

	/**
	 * Gets the actual screen height using GetSystemMetrics (DPI-aware and accurate)
	 * @return Screen height in pixels
	 */
	@:functionCode('
		return GetSystemMetrics(SM_CYSCREEN);
	')
	public static function getScreenHeight():Int
	{
		return 0;
	}

	/**
	 * Gets the work area width (screen minus taskbar)
	 * @return Work area width in pixels
	 */
	@:functionCode('
		RECT rect;
		SystemParametersInfo(SPI_GETWORKAREA, 0, &rect, 0);
		return rect.right - rect.left;
	')
	public static function getWorkAreaWidth():Int
	{
		return 0;
	}

	/**
	 * Gets the work area height (screen minus taskbar)
	 * @return Work area height in pixels
	 */
	@:functionCode('
		RECT rect;
		SystemParametersInfo(SPI_GETWORKAREA, 0, &rect, 0);
		return rect.bottom - rect.top;
	')
	public static function getWorkAreaHeight():Int
	{
		return 0;
	}

	/**
	 * Gets the actual window client area width (excluding borders)
	 * @return Client width in pixels
	 */
	@:functionCode('
		HWND window = GET_WINDOW();
		RECT rect;
		if (GetClientRect(window, &rect)) {
			return rect.right - rect.left;
		}
		return 0;
	')
	public static function getWindowClientWidth():Int
	{
		return 0;
	}

	/**
	 * Gets the actual window client area height (excluding borders and title bar)
	 * @return Client height in pixels
	 */
	@:functionCode('
		HWND window = GET_WINDOW();
		RECT rect;
		if (GetClientRect(window, &rect)) {
			return rect.bottom - rect.top;
		}
		return 0;
	')
	public static function getWindowClientHeight():Int
	{
		return 0;
	}

	/**
	 * Gets the total window width (including borders and decorations)
	 * @return Window width in pixels
	 */
	@:functionCode('
		HWND window = GET_WINDOW();
		RECT rect;
		if (GetWindowRect(window, &rect)) {
			return rect.right - rect.left;
		}
		return 0;
	')
	public static function getWindowWidth():Int
	{
		return 0;
	}

	/**
	 * Gets the total window height (including borders, title bar and decorations)
	 * @return Window height in pixels
	 */
	@:functionCode('
		HWND window = GET_WINDOW();
		RECT rect;
		if (GetWindowRect(window, &rect)) {
			return rect.bottom - rect.top;
		}
		return 0;
	')
	public static function getWindowHeight():Int
	{
		return 0;
	}

	/**
	 * Gets the window X position on screen
	 * @return Window X coordinate in pixels
	 */
	@:functionCode('
		HWND window = GET_WINDOW();
		RECT rect;
		if (GetWindowRect(window, &rect)) {
			return rect.left;
		}
		return 0;
	')
	public static function getWindowX():Int
	{
		return 0;
	}

	/**
	 * Gets the window Y position on screen
	 * @return Window Y coordinate in pixels
	 */
	@:functionCode('
		HWND window = GET_WINDOW();
		RECT rect;
		if (GetWindowRect(window, &rect)) {
			return rect.top;
		}
		return 0;
	')
	public static function getWindowY():Int
	{
		return 0;
	}

	// === Memory Information Functions ===

	/**
	 * Gets the total physical RAM installed in the system (in MB)
	 * NOW USES: GetPhysicallyInstalledSystemMemory for more accurate detection
	 * @return Total RAM in megabytes
	 * @deprecated Use slushithings.cpp.CPPInterface.getRAM() instead
	 */
	public static function getTotalSystemRAM():Int
	{
		#if cpp
		return Std.int(slushithings.cpp.CPPInterface.getRAM());
		#else
		return 0;
		#end
	}

	/**
	 * Gets the available (free) physical RAM (in MB)
	 * @return Available RAM in megabytes
	 */
	@:functionCode('
		MEMORYSTATUSEX memInfo;
		memInfo.dwLength = sizeof(MEMORYSTATUSEX);
		
		if (GlobalMemoryStatusEx(&memInfo)) {
			DWORDLONG availPhysMem = memInfo.ullAvailPhys;
			// Convert bytes to MB
			return (int)(availPhysMem / 1024 / 1024);
		}
		
		return 0;
	')
	public static function getAvailableSystemRAM():Int
	{
		return 0;
	}

	/**
	 * Gets the memory load percentage (0-100)
	 * @return Memory usage percentage
	 */
	@:functionCode('
		MEMORYSTATUSEX memInfo;
		memInfo.dwLength = sizeof(MEMORYSTATUSEX);
		
		if (GlobalMemoryStatusEx(&memInfo)) {
			return (int)memInfo.dwMemoryLoad;
		}
		
		return 0;
	')
	public static function getMemoryLoadPercentage():Int
	{
		return 0;
	}

	/**
	 * Gets the number of CPU cores
	 * @return Number of logical processors
	 */
	@:functionCode('
		SYSTEM_INFO sysInfo;
		GetSystemInfo(&sysInfo);
		return (int)sysInfo.dwNumberOfProcessors;
	')
	public static function getCPUCoreCount():Int
	{
		return 0;
	}

	/**
	 * Gets the current process memory usage (Working Set) in bytes.
	 * This is the "Task Memory" shown in Task Manager.
	 * Same as WinAPI.getProcessMemoryWorkingSetSize() in official Funkin.
	 * @return Process memory usage in bytes as Float
	 */
	@:functionCode('
		PROCESS_MEMORY_COUNTERS_EX pmc;
		pmc.cb = sizeof(PROCESS_MEMORY_COUNTERS_EX);
		
		if (GetProcessMemoryInfo(GetCurrentProcess(), (PROCESS_MEMORY_COUNTERS*)&pmc, sizeof(pmc))) {
			// WorkingSetSize is the current working set (Task Memory)
			SIZE_T workingSetSize = pmc.WorkingSetSize;
			// Return as bytes (double for precision)
			return (double)workingSetSize;
		}
		
		return 0.0;
	')
	public static function getProcessMemoryUsage():Float
	{
		return 0.0;
	}

	// === Dynamic Library Loading Functions (for LuaJIT FFI support) ===

	/**
	 * Loads a dynamic library (DLL) into the process address space.
	 * This can be used with LuaJIT FFI to load native libraries.
	 * @param libraryPath Path to the DLL file (absolute or relative)
	 * @return Handle to the loaded library (as Float/double for precision), or 0.0 if failed
	 */
	@:functionCode('
		HMODULE hModule = LoadLibraryA(libraryPath);
		return (double)(uintptr_t)hModule;
	')
	public static function loadLibrary(libraryPath:String):Float
	{
		return 0.0;
	}

	/**
	 * Gets the address of an exported function from a loaded library.
	 * Use with loadLibrary to call native functions.
	 * @param libraryHandle Handle returned by loadLibrary
	 * @param functionName Name of the exported function
	 * @return Address of the function (as Float/double), or 0.0 if not found
	 */
	@:functionCode('
		HMODULE hModule = (HMODULE)(uintptr_t)libraryHandle;
		FARPROC funcAddr = GetProcAddress(hModule, functionName);
		return (double)(uintptr_t)funcAddr;
	')
	public static function getProcAddress(libraryHandle:Float, functionName:String):Float
	{
		return 0.0;
	}

	/**
	 * Frees a loaded library from memory.
	 * @param libraryHandle Handle returned by loadLibrary
	 * @return True if successfully freed, false otherwise
	 */
	@:functionCode('
		HMODULE hModule = (HMODULE)(uintptr_t)libraryHandle;
		return FreeLibrary(hModule) != 0;
	')
	public static function freeLibrary(libraryHandle:Float):Bool
	{
		return false;
	}

	/**
	 * Gets the handle of an already loaded module by name.
	 * @param moduleName Name of the module (e.g., "kernel32.dll"), or NULL for current executable
	 * @return Handle to the module (as Float/double), or 0.0 if not found
	 */
	@:functionCode('
		const char* name = (moduleName != null() && moduleName.length > 0) ? moduleName : NULL;
		HMODULE hModule = GetModuleHandleA(name);
		return (double)(uintptr_t)hModule;
	')
	public static function getModuleHandle(moduleName:String = null):Float
	{
		return 0.0;
	}

	/**
	 * Gets the full path of a loaded module.
	 * @param moduleHandle Handle of the module (from loadLibrary or getModuleHandle), or 0.0 for current exe
	 * @return Full path to the module file, or empty string if failed
	 */
	@:functionCode('
		HMODULE hModule = (HMODULE)(uintptr_t)moduleHandle;
		char path[MAX_PATH];
		
		if (GetModuleFileNameA(hModule, path, MAX_PATH) > 0) {
			return String(path);
		}
		
		return String("");
	')
	public static function getModulePath(moduleHandle:Float = 0.0):String
	{
		return "";
	}

	/**
	 * Sets the window opacity/alpha
	 * @param alpha Opacity value (0.0 = fully transparent, 1.0 = fully opaque)
	 */
	@:functionCode('
		HWND hwnd = GET_ENGINE_WINDOW();
		if (!hwnd) return;
		
		// Get current window style
		LONG_PTR exStyle = GetWindowLongPtr(hwnd, GWL_EXSTYLE);
		
		// Add WS_EX_LAYERED if not already set
		if (!(exStyle & WS_EX_LAYERED)) {
			SetWindowLongPtr(hwnd, GWL_EXSTYLE, exStyle | WS_EX_LAYERED);
		}
		
		// Convert alpha (0.0-1.0) to byte (0-255)
		BYTE alphaValue = (BYTE)(alpha * 255.0);
		
		// Set the layered window attributes
		SetLayeredWindowAttributes(hwnd, 0, alphaValue, LWA_ALPHA);
	')
	public static function setWindowOpacity(alpha:Float):Void
	{
	}

	/**
	 * Gets the current window opacity/alpha
	 * @return Current opacity value (0.0 - 1.0)
	 */
	@:functionCode('
		HWND hwnd = GET_ENGINE_WINDOW();
		if (!hwnd) return 1.0;
		
		BYTE alphaValue = 255;
		DWORD flags = 0;
		COLORREF colorKey = 0;
		
		// Try to get the current alpha value
		if (GetLayeredWindowAttributes(hwnd, &colorKey, &alphaValue, &flags)) {
			// Convert byte (0-255) to float (0.0-1.0)
			return (double)alphaValue / 255.0;
		}
		
		// Default to fully opaque if we can\'t get the value
		return 1.0;
	')
	public static function getWindowOpacity():Float
	{
		return 1.0;
	}

	/**
	 * Makes the window fully transparent (click-through)
	 * @param transparent True to enable transparency, false to disable
	 */
	@:functionCode('
		HWND hwnd = GET_ENGINE_WINDOW();
		if (!hwnd) return;
		
		LONG_PTR exStyle = GetWindowLongPtr(hwnd, GWL_EXSTYLE);
		
		if (transparent) {
			// Enable layered window with transparency
			SetWindowLongPtr(hwnd, GWL_EXSTYLE, exStyle | WS_EX_LAYERED | WS_EX_TRANSPARENT);
			SetLayeredWindowAttributes(hwnd, RGB(0, 0, 0), 0, LWA_COLORKEY);
		} else {
			// Disable transparency
			SetWindowLongPtr(hwnd, GWL_EXSTYLE, exStyle & ~WS_EX_TRANSPARENT);
			SetLayeredWindowAttributes(hwnd, 0, 255, LWA_ALPHA);
		}
	')
	public static function setWindowTransparent(transparent:Bool):Void
	{
	}
	#end
}

/**
 * MessageBox icon types for showMessageBox function
 */
enum abstract MessageBoxIcon(Int)
{
	var MSG_ERROR = 0x00000010;
	var MSG_QUESTION = 0x00000020;
	var MSG_WARNING = 0x00000030;
	var MSG_INFORMATION = 0x00000040;
}