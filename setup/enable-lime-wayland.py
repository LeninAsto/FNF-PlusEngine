import sys
from pathlib import Path


def main():
    if len(sys.argv) != 2:
        raise SystemExit("Usage: python3 enable-lime-wayland.py LIME_ROOT")
    build = Path(sys.argv[1]) / "project" / "Build.xml"
    text = build.read_text(encoding="utf-8")
    bundled = '<files id="native-toolkit-sdl" if="LIME_SDL" unless="emscripten" />'
    linux = '<section if="linux">\n\n\t\t\t\t<lib name="-lpthread" />'
    if text.count(bundled) != 1 or text.count(linux) != 1:
        raise SystemExit("Unsupported Lime Build.xml; SDL link points were not found exactly once")
    cpp11 = '<set name="HXCPP_CPP11" value="1" />'
    if text.count(cpp11) != 1:
        raise SystemExit("Unsupported Lime Build.xml; C++ standard setting was not found")
    text = text.replace(cpp11, '<set name="HXCPP_CPP11" value="1" unless="plus_system_sdl" />')
    text = text.replace(bundled, '<files id="native-toolkit-sdl" if="LIME_SDL" unless="emscripten || plus_system_sdl" />')
    text = text.replace(linux, '<section if="linux">\n\n\t\t\t\t<lib name="-lSDL2" if="plus_system_sdl" />\n\t\t\t\t<lib name="-lpthread" />')
    build.write_text(text, encoding="utf-8")


if __name__ == "__main__":
    main()
