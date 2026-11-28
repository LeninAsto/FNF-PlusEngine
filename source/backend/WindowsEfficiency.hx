package backend;

#if (cpp && windows)
@:cppFileCode('
#include <windows.h>

namespace plus_efficiency {
    struct PowerState { ULONG version; ULONG controlMask; ULONG stateMask; };
    typedef BOOL (WINAPI *GetInfo)(HANDLE, int, LPVOID, DWORD);
    typedef BOOL (WINAPI *SetInfo)(HANDLE, int, LPVOID, DWORD);
    static const int powerThrottling = 4;
    static const ULONG executionSpeed = 1;
    static PowerState original = {1, 0, 0};
    static DWORD originalPriority = 0;
    static bool policyChanged = false;
    static bool priorityChanged = false;
    static bool active = false;

    static bool restore(HANDLE process, GetInfo getInfo, SetInfo setInfo) {
        bool success = true;
        if (priorityChanged) {
            DWORD priority = GetPriorityClass(process);
            if (!priority) success = false;
            else if (priority != IDLE_PRIORITY_CLASS || SetPriorityClass(process, originalPriority))
                priorityChanged = false;
            else success = false;
        }
        if (policyChanged) {
            PowerState current = {1, 0, 0};
            if (!getInfo(process, powerThrottling, &current, sizeof(current))) success = false;
            else if (!(current.controlMask & executionSpeed) || !(current.stateMask & executionSpeed))
                policyChanged = false;
            else {
                current.controlMask = (current.controlMask & ~executionSpeed) | (original.controlMask & executionSpeed);
                current.stateMask = (current.stateMask & ~executionSpeed) | (original.stateMask & executionSpeed);
                if (setInfo(process, powerThrottling, &current, sizeof(current))) policyChanged = false;
                else success = false;
            }
        }
        if (!priorityChanged && !policyChanged) active = false;
        return success;
    }

    static bool update(bool background) {
        HMODULE kernel = GetModuleHandleW(L"kernel32.dll");
        if (!kernel) return false;
        GetInfo getInfo = reinterpret_cast<GetInfo>(GetProcAddress(kernel, "GetProcessInformation"));
        SetInfo setInfo = reinterpret_cast<SetInfo>(GetProcAddress(kernel, "SetProcessInformation"));
        if (!getInfo || !setInfo) return false;
        HANDLE process = GetCurrentProcess();

        if (!background) return restore(process, getInfo, setInfo);
        if (active) return true;

        PowerState current = {1, 0, 0};
        if (!getInfo(process, powerThrottling, &current, sizeof(current))) return false;
        originalPriority = GetPriorityClass(process);
        if (!originalPriority) return false;
        original = current;

        if (!(current.controlMask & executionSpeed) || !(current.stateMask & executionSpeed)) {
            current.controlMask |= executionSpeed;
            current.stateMask |= executionSpeed;
            if (!setInfo(process, powerThrottling, &current, sizeof(current))) return false;
            policyChanged = true;
        }
        if (originalPriority != IDLE_PRIORITY_CLASS) {
            if (!SetPriorityClass(process, IDLE_PRIORITY_CLASS)) {
                active = policyChanged;
                restore(process, getInfo, setInfo);
                return false;
            }
            priorityChanged = true;
        }
        active = true;
        return true;
    }
}
')
#end
class WindowsEfficiency
{
    static var reportedFailure:Bool = false;

    public static function setBackground(background:Bool):Bool
    {
        #if (cpp && windows)
        var success:Bool = untyped __cpp__('plus_efficiency::update({0})', background);
        if (!success && !reportedFailure)
        {
            reportedFailure = true;
            trace('Windows could not update the background efficiency policy.');
        }
        return success;
        #else
        return false;
        #end
    }
}
