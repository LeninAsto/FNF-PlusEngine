package states.play;

import backend.Paths;
import backend.ui.md3.MaterialWavyProgressIndicator;
import backend.ui.md3.MaterialWavyProgressIndicator.WavyProgressType;
import flixel.FlxState;
import flixel.FlxCamera;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.text.FlxText.FlxTextBorderStyle;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import objects.Note;
import objects.StrumNote;
import options.OptionsMenuTheme;

class BreakTimerHud
{
	public var text(default, null):FlxText;
	public var indicator(default, null):MaterialWavyProgressIndicator;

	var noteTimes:Array<Float> = [];
	var noteIndex:Int = 0;
	var nextNoteTime:Float = -1;
	var lastNoteTime:Float = -1;
	var lastDisplayValue:Int = -1;

	final minGapMs:Float;

	public function new(camera:FlxCamera, ?minGapMs:Float = 2000, ?textSize:Int = 28, ?indicatorSize:Float = 64)
	{
		this.minGapMs = minGapMs;

		indicator = new MaterialWavyProgressIndicator(0, 0, WavyProgressType.CIRCULAR, indicatorSize);
		indicator.cameras = [camera];
		indicator.scrollFactor.set();
		indicator.circularEdgeGap = 0.12;
		indicator.circularTrackRadiusOffset = 0;
		indicator.circularTrackThicknessScale = 1;
		indicator.visible = false;
		indicator.value = 0;

		text = new FlxText(0, 0, 0, "", textSize);
		text.setFormat(Paths.font("vcr.ttf"), textSize, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		text.cameras = [camera];
		text.scrollFactor.set();
		text.borderSize = 3;
		text.visible = false;

		refreshVisualStyle();
	}

	public function addTo(state:FlxState):Void
	{
		state.add(indicator);
		state.add(text);
	}

	public function destroyFrom(state:FlxState):Void
	{
		if (text != null)
		{
			state.remove(text);
			text.destroy();
			text = null;
		}

		if (indicator != null)
		{
			state.remove(indicator);
			indicator.destroy();
			indicator = null;
		}
	}

	public function cacheNotes(unspawnNotes:Array<Note>):Void
	{
		noteTimes = [];
		noteIndex = 0;
		nextNoteTime = -1;
		lastNoteTime = -1;
		lastDisplayValue = -1;

		if (unspawnNotes == null)
			return;

		for (note in unspawnNotes)
		{
			if (note != null && note.mustPress && !note.isSustainNote)
				noteTimes.push(note.strumTime);
		}

		noteTimes.sort(function(a:Float, b:Float):Int
		{
			return a < b ? -1 : (a > b ? 1 : 0);
		});

		if (noteTimes.length > 0)
			nextNoteTime = noteTimes[0];
	}

	public inline function hasUpcomingNote():Bool
	{
		return nextNoteTime > 0;
	}

	public function refreshVisualStyle():Void
	{
		if (indicator == null)
			return;

		OptionsMenuTheme.syncAccent();

		var trackRgb:Int = OptionsMenuTheme.loadingOverlayTrackColor();
		var waveRgb:Int = OptionsMenuTheme.loadingOverlayWaveColor();
		var outlineRgb:Int = OptionsMenuTheme.loadingOverlayOutlineColor();
		var trackAlpha:Int = Std.int(0.22 * 255);
		var trackColor:Int = (trackAlpha << 24) | (trackRgb & 0x00FFFFFF);

		indicator.resetThemeColors();
		indicator.setTrackColor(trackColor);
		indicator.setWaveColor(waveRgb);

		if (text != null)
		{
			text.color = waveRgb;
			text.borderColor = outlineRgb;
		}
	}

	public function updateDisplay(songPosition:Float, startingSong:Bool, playerStrums:FlxTypedGroup<StrumNote>, downScroll:Bool,
		getCenterX:StrumNote->Float, getTopY:StrumNote->Float):Void
	{
		if (text == null || indicator == null || playerStrums == null || playerStrums.length <= 0)
			return;

		syncNotes(songPosition);

		var gapStart:Float = lastNoteTime >= 0 ? lastNoteTime : 0;
		var totalGap:Float = nextNoteTime > 0 ? (nextNoteTime - gapStart) : -1;
		var timeUntilNext:Float = (nextNoteTime - songPosition) / 1000;

		if (!startingSong && nextNoteTime > 0 && totalGap >= minGapMs && timeUntilNext > 0)
		{
			var displayValue:Int = Math.ceil(timeUntilNext);
			if (displayValue >= 1)
			{
				text.visible = true;
				indicator.visible = true;
				text.text = Std.string(displayValue);

				var countdownDuration = Math.max(0.001, totalGap / 1000);
				indicator.value = FlxMath.bound(timeUntilNext / countdownDuration, 0, 1);

				var centerX:Float = 0;
				var centerY:Float = 0;
				var strumCount:Int = 0;
				for (strum in playerStrums)
				{
					if (strum == null)
						continue;

					centerX += getCenterX(strum);
					centerY += getTopY(strum);
					strumCount++;
				}

				if (strumCount <= 0)
				{
					clearDisplay();
					return;
				}

				centerX /= strumCount;
				centerY /= strumCount;

				var indicatorY = centerY + (downScroll ? -164 : 100);
				var indicatorSize = indicator.getIndicatorHeight();
				indicator.x = centerX - indicatorSize / 2;
				indicator.y = indicatorY;
				text.x = centerX - text.width / 2;
				text.y = indicatorY + Math.max(0, (indicatorSize - text.height) * 0.5) - 3;

				if (lastDisplayValue != displayValue)
				{
					text.scale.set(1.5, 1.5);
					indicator.scale.set(1.1, 1.1);
					FlxTween.tween(text.scale, {x: 1, y: 1}, 0.2, {ease: FlxEase.circOut});
					FlxTween.tween(indicator.scale, {x: 1, y: 1}, 0.2, {ease: FlxEase.circOut});
					lastDisplayValue = displayValue;
				}
				return;
			}
		}

		clearDisplay();
	}

	function syncNotes(songPosition:Float):Void
	{
		if (noteTimes == null || noteTimes.length == 0)
		{
			noteIndex = 0;
			lastNoteTime = -1;
			nextNoteTime = -1;
			return;
		}

		if (lastNoteTime > songPosition)
		{
			noteIndex = 0;
			lastNoteTime = -1;
		}

		while (noteIndex < noteTimes.length && songPosition >= noteTimes[noteIndex])
		{
			lastNoteTime = noteTimes[noteIndex];
			noteIndex++;
		}

		nextNoteTime = noteIndex < noteTimes.length ? noteTimes[noteIndex] : -1;
	}

	function clearDisplay():Void
	{
		if (text != null)
		{
			text.visible = false;
			text.scale.set(1, 1);
		}

		if (indicator != null)
		{
			indicator.visible = false;
			indicator.value = 0;
			indicator.scale.set(1, 1);
		}

		lastDisplayValue = -1;
	}
}
