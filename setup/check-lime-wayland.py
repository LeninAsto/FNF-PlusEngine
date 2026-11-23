import ctypes
import sys


def main():
    if len(sys.argv) != 2:
        raise SystemExit("Usage: python3 check-lime-wayland.py PATH_TO_LIME_NDLL")
    sdl = ctypes.CDLL(sys.argv[1])
    sdl.SDL_GetError.restype = ctypes.c_char_p
    sdl.SDL_GetCurrentVideoDriver.restype = ctypes.c_char_p
    sdl.SDL_CreateWindow.argtypes = [ctypes.c_char_p, ctypes.c_int, ctypes.c_int, ctypes.c_int, ctypes.c_int, ctypes.c_uint]
    sdl.SDL_CreateWindow.restype = ctypes.c_void_p
    sdl.SDL_GL_CreateContext.argtypes = [ctypes.c_void_p]
    sdl.SDL_GL_CreateContext.restype = ctypes.c_void_p
    sdl.SDL_GL_DeleteContext.argtypes = [ctypes.c_void_p]
    sdl.SDL_DestroyWindow.argtypes = [ctypes.c_void_p]
    if sdl.SDL_Init(0x20) != 0:
        raise SystemExit(sdl.SDL_GetError().decode())
    window = None
    context = None
    try:
        driver = sdl.SDL_GetCurrentVideoDriver()
        if driver != b"wayland":
            raise SystemExit(f"Expected wayland, got {driver!r}")
        window = sdl.SDL_CreateWindow(b"Plus Engine Wayland check", 0, 0, 640, 480, 0x2 | 0x8)
        if not window:
            raise SystemExit(sdl.SDL_GetError().decode())
        context = sdl.SDL_GL_CreateContext(window)
        if not context:
            raise SystemExit(sdl.SDL_GetError().decode())
        print("Lime SDL: Wayland window and OpenGL context created")
    finally:
        if context:
            sdl.SDL_GL_DeleteContext(context)
        if window:
            sdl.SDL_DestroyWindow(window)
        sdl.SDL_Quit()


if __name__ == "__main__":
    main()
