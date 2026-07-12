package options;

import flixel.util.FlxColor;
import backend.ui.md3.MD3Theme;

typedef OptionsAccentPalette = {
	var name:String;
	var accent:Int;
	var strong:Int;
	var muted:Int;
	var pale:Int;
	var mist:Int;
}

class OptionsMenuTheme
{
	public static var ACCENT_CHOICES(default, null):Array<String> = ['Purple', 'Teal', 'Rose', 'Amber', 'Indigo', 'Green', 'Red', 'Black'];

	public static inline function isDark():Bool
	{
		return ClientPrefs.data.menuDarkTheme;
	}

	public static function signature():String
	{
		return normalizeAccent(ClientPrefs.data.menuAccentColor) + ':' + (isDark() ? 'dark' : 'light');
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

	public static function current():OptionsAccentPalette
	{
		return getPalette(ClientPrefs.data.menuAccentColor);
	}

	public static function getPalette(?value:String):OptionsAccentPalette
	{
		switch (normalizeAccent(value))
		{
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

	public static function syncAccent():Void
	{
		var palette = current();
		MD3Theme.setAccent(palette.accent, isDark());
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

	public static inline function backdropColor():Int
	{
		return isDark() ? 0xD0090A0C : 0xD2141020;
	}

	public static inline function menuBackgroundAlpha():Float
	{
		return isDark() ? 0.08 : 0.14;
	}

	public static inline function panelSurfaceColor():Int
	{
		return isDark() ? 0xFF111317 : 0xFFF8F4FC;
	}

	public static inline function panelHeaderColor():Int
	{
		return isDark() ? 0xFF181B20 : 0xFFFFFBFF;
	}

	public static inline function panelOutlineColor():Int
	{
		return isDark() ? 0xFF2A2E36 : 0x24FFFFFF;
	}

	public static inline function neutralOutlineColor():Int
	{
		return isDark() ? 0xFF30343C : 0xFFDCCEEB;
	}

	public static inline function panelShadowColor():Int
	{
		return isDark() ? 0x32000000 : 0x26000000;
	}

	public static inline function titleColor():Int
	{
		return isDark() ? 0xFFF5F7FA : current().strong;
	}

	public static inline function bodyTextColor():Int
	{
		return isDark() ? 0xFFC4CBD6 : current().muted;
	}

	public static inline function footerTextColor():Int
	{
		return isDark() ? 0xFF9BA1AD : 0xFF6D5F82;
	}

	public static inline function cardFill(selected:Bool):Int
	{
		var base = isDark() ? 0xFF121419 : 0xFFFCF8FF;
		return selected ? blendColor(base, current().accent, isDark() ? 0.11 : 0.09) : base;
	}

	public static inline function cardStroke(selected:Bool):Int
	{
		return selected ? current().accent : neutralOutlineColor();
	}

	public static inline function cardAccent(selected:Bool):Int
	{
		if (selected)
			return current().accent;

		return isDark() ? blendColor(0xFF3A3F48, current().accent, 0.28) : blendColor(current().pale, current().accent, 0.18);
	}

	public static inline function cardTitleColor(selected:Bool):Int
	{
		return isDark() ? (selected ? 0xFFF5F7FA : 0xFFE6EAF0) : (selected ? current().strong : 0xFF402D61);
	}

	public static inline function cardDescriptionColor(selected:Bool):Int
	{
		return isDark() ? (selected ? 0xFFC4CBD6 : 0xFF99A1AE) : (selected ? current().muted : 0xFF7B6D93);
	}

	public static inline function cardValueColor(selected:Bool):Int
	{
		return isDark() ? (selected ? current().accent : 0xFFB7BEC9) : (selected ? current().accent : 0xFF7B6D93);
	}

	public static inline function previewSurfaceColor():Int
	{
		return isDark() ? 0xFF171A1F : 0xFFF9F4FC;
	}

	public static inline function previewTitleColor():Int
	{
		return isDark() ? 0xFFF5F7FA : 0xFF2C1E48;
	}

	public static inline function previewHintColor(focused:Bool = false):Int
	{
		return focused ? titleColor() : (isDark() ? 0xFF9BA1AD : 0xFF76678B);
	}

	public static inline function accentOverlay(alpha:Float):Int
	{
		return colorWithAlpha(current().accent, alpha);
	}

	public static inline function gridAccentColor():Int
	{
		return isDark()
			? blendColor(current().accent, 0xFFE2E8F0, 0.30)
			: blendColor(current().accent, 0xFFFFFFFF, 0.20);
	}

	public static inline function loadingOverlayPanelColor():Int
	{
		return blendColor(panelSurfaceColor(), current().accent, isDark() ? 0.10 : 0.05);
	}

	public static inline function loadingOverlayOutlineColor():Int
	{
		return isDark()
			? blendColor(0xFFF1F5F9, current().accent, 0.18)
			: blendColor(0xFF6B7280, current().accent, 0.28);
	}

	public static inline function loadingOverlayTrackColor():Int
	{
		return isDark()
			? blendColor(0xFF586171, current().accent, 0.34)
			: blendColor(current().pale, current().accent, 0.38);
	}

	public static inline function loadingOverlayWaveColor():Int
	{
		return current().accent;
	}

	public static inline function interactiveFill(active:Bool, hovered:Bool = false):Int
	{
		if (active)
			return blendColor(isDark() ? 0xFF1A1E24 : 0xFFFCF8FF, current().accent, isDark() ? 0.15 : 0.11);

		if (hovered)
			return blendColor(isDark() ? 0xFF171B21 : 0xFFFFFBFF, current().accent, isDark() ? 0.08 : 0.06);

		return 0x00000000;
	}

	public static inline function optionTitleColor(selected:Bool):Int
	{
		return isDark() ? (selected ? titleColor() : 0xFFE6EAF0) : (selected ? current().strong : 0xFF45335E);
	}

	public static inline function optionDescriptionColor(selected:Bool):Int
	{
		return isDark() ? (selected ? bodyTextColor() : 0xFF99A1AE) : (selected ? current().muted : 0xFF7E6F95);
	}
}