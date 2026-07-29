package backend;

#if sys
import sys.FileSystem;
#end

class ReShadeUtil
{
    public static function isInstalled():Bool
    {
        #if windows
        var path = Sys.getCwd();

        return FileSystem.exists(path + "dxgi.dll")
            || FileSystem.exists(path + "d3d11.dll")
            || FileSystem.exists(path + "ReShade.ini");
        #else
        return false;
        #end
    }
}