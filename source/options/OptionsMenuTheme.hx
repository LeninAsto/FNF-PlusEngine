package options;

import flixel.util.FlxColor;
import backend.ui.md3.MD3Theme;
import StringTools;

typedef OptionsAccentPalette =
{
	var name:String;
	var accent:Int;
	var strong:Int;
	var muted:Int;
	var pale:Int;
	var mist:Int;
}

class OptionsMenuTheme
{
	public static var ACCENT_CHOICES(default, null):Array<String> = ['Purple', 'Teal', 'Rose', 'Amber', 'Indigo', 'Green', 'Red', 'Black', 'Custom'];

	public static inline function isDark():Bool
	{
		return ClientPrefs.data.menuDarkTheme;
	}

	public static function signature():String
	{
		var accentName = normalizeAccent(ClientPrefs.data.menuAccentColor);
		var customPart = accentName == 'Custom' ? ':' + Std.string(StringTools.hex(getCustomAccent() & 0x00FFFFFF, 6)) : '';
		return accentName + ':' + (isDark() ? 'dark' : 'light') + customPart;
	}

	public static function normalizeAccent(value:String):String
	{
		if (value == null || value.length == 0)
			return 'Purple';

		for (choice in ACCENT_CHOICES)
		{
			if (choice.toLowerCase() == value.toLowerCase())
				return choice;
		}

		return 'Purple';
	}

	public static inline function getCustomAccent():Int
	{
		return 0xFF000000 | (ClientPrefs.data.menuAccentColorCustom & 0x00FFFFFF);
	}

	public static function current():OptionsAccentPalette
	{
		return getPalette(ClientPrefs.data.menuAccentColor);
	}

	public static function getPalette(?value:String):OptionsAccentPalette
	{
		switch (normalizeAccent(value))
		{
			case 'Custom':
				return buildPaletteFromAccent(getCustomAccent(), 'Custom');
			case 'Black':
				return {
					name: 'Black',
					accent: 0xFF9098A6,
					strong: 0xFF17191D,
					muted: 0xFF606775,
					pale: 0xFFD6D9E0,
					mist: 0xFFF1F3F6
				};
			case 'Teal':
				return {
					name: 'Teal',
					accent: 0xFF1D8B91,
					strong: 0xFF155B60,
					muted: 0xFF4F7E84,
					pale: 0xFFBFE8EA,
					mist: 0xFFE9F9FA
				};
			case 'Rose':
				return {
					name: 'Rose',
					accent: 0xFFCC5F86,
					strong: 0xFF8B3456,
					muted: 0xFFA1647B,
					pale: 0xFFF2CAD8,
					mist: 0xFFFFEFF5
				};
			case 'Amber':
				return {
					name: 'Amber',
					accent: 0xFFB97819,
					strong: 0xFF7A4B00,
					muted: 0xFF9D7341,
					pale: 0xFFF0D7AC,
					mist: 0xFFFFF6E7
				};
			case 'Indigo':
				return {
					name: 'Indigo',
					accent: 0xFF5569C9,
					strong: 0xFF34418B,
					muted: 0xFF6673A8,
					pale: 0xFFD2D8F8,
					mist: 0xFFF1F3FF
				};
			case 'Green':
				return {
					name: 'Green',
					accent: 0xFF3B9A62,
					strong: 0xFF1D6A40,
					muted: 0xFF5B886D,
					pale: 0xFFCBEBD8,
					mist: 0xFFEFFAF3
				};
			case 'Red':
				return {
					name: 'Red',
					accent: 0xFFD25A52,
					strong: 0xFF8A302A,
					muted: 0xFFA66560,
					pale: 0xFFF4CBC8,
					mist: 0xFFFFF0EF
				};
			default:
				return {
					name: 'Purple',
					accent: 0xFF6F52D8,
					strong: 0xFF4D34A8,
					muted: 0xFF7F67C4,
					pale: 0xFFDCCFFB,
					mist: 0xFFF3ECFF
				};
		}
	}

	static function buildPaletteFromAccent(color:Int, name:String):OptionsAccentPalette
	{
		var accent:Int = 0xFF000000 | (color & 0x00FFFFFF);
		return {
			name: name,
			accent: accent,
			strong: blendColor(accent, 0xFF111318, 0.58),
			muted: blendColor(accent, 0xFF7C8696, 0.34),
			pale: blendColor(accent, 0xFFFFFFFF, 0.72),
			mist: blendColor(accent, 0xFFFFFFFF, 0.88)
		};
	}

	public static function syncAccent():Void
	{
		ClientPrefs.syncThemeModeFlags();
		var palette = current();
		MD3Theme.setAccent(palette.accent, true);
	}

	static inline function clamp01(value:Float):Float
	{
		return value < 0 ? 0 : (value > 1 ? 1 : value);
	}

	static inline function colorWithAlpha(color:Int, alpha:Float):Int
	{
		return (Std.int(clamp01(alpha) * 255) << 24) | (color & 0x00FFFFFF);
	}

	static inline function blendColor(base:Int, tint:Int, amount:Float):Int
	{
		var ratio = clamp01(amount);
		return FlxColor.interpolate(base, tint, ratio);
	}

	static inline function relativeLuminance(color:Int):Float
	{
		var r:Float = ((color >> 16) & 0xFF) / 255;
		var g:Float = ((color >> 8) & 0xFF) / 255;
		var b:Float = (color & 0xFF) / 255;
		return 0.2126 * r + 0.7152 * g + 0.0722 * b;
	}

	public static inline function readableTextOn(fill:Int):Int
	{
		return relativeLuminance(fill) > 0.58 ? 0xFF17191D : 0xFFF5F7FA;
	}

	public static inline function readableMetaTextOn(fill:Int):Int
	{
		return relativeLuminance(fill) > 0.58 ? 0xFF45395A : 0xFFD3D9E4;
	}

	public static inline function difficultyCardFill(color:Int, selected:Bool):Int
	{
		var base = cardFill(selected);
		return blendColor(base, color, isDark() ? (selected ? 0.18 : 0.11) : (selected ? 0.22 : 0.15));
	}

	public static inline function difficultyCardStroke(color:Int, selected:Bool):Int
	{
		return selected ? blendColor(color, current().accent, 0.4) : blendColor(color, neutralOutlineColor(), 0.28);
	}

	public static inline function difficultyTitleColor(color:Int, selected:Bool):Int
	{
		var fill = difficultyCardFill(color, selected);
		return readableTextOn(fill);
	}

	public static inline function difficultyMetaColor(color:Int, selected:Bool):Int
	{
		var fill = difficultyCardFill(color, selected);
		return readableMetaTextOn(fill);
	}

	public static inline function backdropColor():Int
	{
		return 0xC0101010;
	}

	public static inline function menuBackgroundAlpha():Float
	{
		return 0.22;
	}

	public static inline function panelSurfaceColor():Int
	{
		return 0xFF141414;
	}

	public static inline function panelHeaderColor():Int
	{
		return 0xFF1B1B1B;
	}

	public static inline function panelOutlineColor():Int
	{
		return blendColor(0xFF1A1A1A, current().accent, 0.18);
	}

	public static inline function neutralOutlineColor():Int
	{
		return 0xFF343434;
	}

	public static inline function panelShadowColor():Int
	{
		return isDark() ? 0x32000000 : 0x26000000;
	}

	public static inline function titleColor():Int
	{
		return 0xFFF5F7FA;
	}

	public static inline function bodyTextColor():Int
	{
		return 0xFFC4CBD6;
	}

	public static inline function footerTextColor():Int
	{
		return 0xFF9BA1AD;
	}

	public static inline function cardFill(selected:Bool):Int
	{
		var base = selected ? 0xFF1B1B1B : 0xFF121212;
		return selected ? blendColor(base, current().accent, 0.12) : base;
	}

	public static inline function cardStroke(selected:Bool):Int
	{
		return selected ? current().accent : neutralOutlineColor();
	}

	public static inline function cardAccent(selected:Bool):Int
	{
		if (selected)
			return current().accent;

		return blendColor(0xFF454545, current().accent, 0.20);
	}

	public static inline function cardTitleColor(selected:Bool):Int
	{
		return selected ? 0xFFF5F7FA : 0xFFE6EAF0;
	}

	public static inline function cardDescriptionColor(selected:Bool):Int
	{
		return selected ? 0xFFC4CBD6 : 0xFF99A1AE;
	}

	public static inline function cardValueColor(selected:Bool):Int
	{
		return selected ? current().accent : 0xFFB7BEC9;
	}

	public static inline function previewSurfaceColor():Int
	{
		return 0xFF181818;
	}

	public static inline function previewTitleColor():Int
	{
		return 0xFFF5F7FA;
	}

	public static inline function previewHintColor(focused:Bool = false):Int
	{
		return focused ? titleColor() : 0xFF9BA1AD;
	}

	public static inline function accentOverlay(alpha:Float):Int
	{
		return colorWithAlpha(current().accent, alpha);
	}

	public static inline function gridAccentColor():Int
	{
		return isDark() ? blendColor(current().accent, 0xFFE2E8F0, 0.30) : blendColor(current().accent, 0xFFFFFFFF, 0.20);
	}

	public static inline function loadingOverlayPanelColor():Int
	{
		return blendColor(0xFF161616, current().accent, 0.08);
	}

	public static inline function loadingOverlayOutlineColor():Int
	{
		return blendColor(0xFF6B7280, current().accent, 0.28);
	}

	public static inline function loadingOverlayTrackColor():Int
	{
		return blendColor(0xFF586171, current().accent, 0.34);
	}

	public static inline function loadingOverlayWaveColor():Int
	{
		return current().accent;
	}

	public static inline function interactiveFill(active:Bool, hovered:Bool = false):Int
	{
		if (active)
			return blendColor(0xFF202020, current().accent, 0.15);

		if (hovered)
			return blendColor(0xFF191919, current().accent, 0.08);

		return 0x00000000;
	}

	public static inline function optionTitleColor(selected:Bool):Int
	{
		return selected ? titleColor() : 0xFFE6EAF0;
	}

	public static inline function optionDescriptionColor(selected:Bool):Int
	{
		return selected ? bodyTextColor() : 0xFF99A1AE;
	}
}

