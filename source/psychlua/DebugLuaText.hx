package psychlua;

import backend.ui.md3.MD3ShapeTools;
import backend.ui.md3.MD3Theme;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.text.FlxText;
import flixel.text.FlxText.FlxTextAlign;
import flixel.text.FlxText.FlxTextBorderStyle;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;

typedef DebugLuaEntry =
{
	var text:String;
	var color:FlxColor;
	var count:Int;
	var time:Float;
}

class DebugLuaText extends FlxSpriteGroup
{
	static inline var PANEL_MARGIN:Float = 28;
	static inline var MIN_PANEL_WIDTH:Int = 220;
	static inline var MIN_PANEL_HEIGHT:Int = 74;
	static inline var MAX_PANEL_HEIGHT:Int = 270;
	static inline var PADDING:Int = 14;
	static inline var TITLE_Y:Float = 8;
	static inline var TITLE_GAP:Float = 10;
	static inline var ROW_GAP:Int = 4;
	static inline var MESSAGE_TIME:Float = 6;
	static inline var MAX_STORED_ENTRIES:Int = 80;
	static inline var TWEEN_TIME:Float = 0.22;
	static inline var MAX_ROWS:Int = 16;
	static inline var BACKGROUND_ALPHA:Float = 0.5;

	public var disableTime:Float = MESSAGE_TIME;

	var background:FlxSprite;
	var titleText:FlxText;
	var rows:Array<FlxText> = [];
	var entries:Array<DebugLuaEntry> = [];
	var panelHeight:Int = MIN_PANEL_HEIGHT;
	var panelWidth:Int = MIN_PANEL_WIDTH;
	var panelX:Float = 0;
	var panelY:Float = 0;
	var showTween:FlxTween;
	var hideTween:FlxTween;
	var hiding:Bool = false;

	public function new()
	{
		super(0, 0);
		scrollFactor.set();

		background = new FlxSprite();
		background.antialiasing = ClientPrefs.data.antialiasing;
		background.alpha = BACKGROUND_ALPHA;
		add(background);

		titleText = new FlxText(PADDING, TITLE_Y, 10000, 'Debug', 16);
		titleText.setFormat(Paths.font('NotoSans-Medium.ttf'), 16, MD3Theme.onSurface, FlxTextAlign.CENTER, FlxTextBorderStyle.NONE);
		titleText.fieldWidth = 10000;
		titleText.antialiasing = ClientPrefs.data.antialiasing;
		add(titleText);

		for (i in 0...MAX_ROWS)
		{
			var row = new FlxText(PADDING, messageStartY(), maxTextWidth(), '', 15);
			row.setFormat(Paths.font('vcr.ttf'), 15, FlxColor.WHITE, FlxTextAlign.CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
			row.fieldWidth = maxTextWidth();
			row.wordWrap = true;
			row.borderSize = 1;
			row.antialiasing = ClientPrefs.data.antialiasing;
			row.visible = false;
			rows.push(row);
			add(row);
		}

		redrawPanel();
		kill();
	}

	public function pushMessage(text:String, color:FlxColor):Void
	{
		if (text == null)
			text = '';

		text = text.trim();
		if (text.length == 0)
			return;

		disableTime = MESSAGE_TIME;
		var shouldShow = !exists || !visible || hiding;

		var entry = findEntry(text, color);
		if (entry != null)
		{
			entry.count++;
			entry.time = MESSAGE_TIME;
		}
		else
		{
			entries.push({
				text: text,
				color: color,
				count: 1,
				time: MESSAGE_TIME
			});
			if (entries.length > MAX_STORED_ENTRIES)
				entries.shift();
		}

		layoutEntries();
		if (shouldShow)
			showPanel();
		else
		{
			alpha = 1;
			updatePanelTargetPosition();
		}
	}

	function findEntry(text:String, color:FlxColor):DebugLuaEntry
	{
		for (entry in entries)
		{
			if (entry.text == text && entry.color == color)
				return entry;
		}
		return null;
	}

	override function update(elapsed:Float):Void
	{
		super.update(elapsed);

		if (entries.length == 0)
		{
			startHide();
			return;
		}

		disableTime = Math.max(0, disableTime - elapsed);
		if (disableTime <= 0)
		{
			startHide();
			return;
		}

		layoutEntries();
	}

	function layoutEntries():Void
	{
		var availableTextWidth = maxTextWidth();
		for (row in rows)
		{
			row.fieldWidth = availableTextWidth;
			row.wordWrap = true;
		}

		var chosen:Array<DebugLuaEntry> = [];
		var usedHeight:Float = messageStartY() + PADDING;
		var i = entries.length - 1;
		while (i >= 0 && chosen.length < rows.length)
		{
			var entry = entries[i];
			var probe = rows[chosen.length];
			probe.text = displayEntry(entry);
			var rowHeight = measuredRowHeight(probe);
			if (chosen.length > 0 && usedHeight + rowHeight + ROW_GAP > MAX_PANEL_HEIGHT)
				break;

			chosen.unshift(entry);
			usedHeight += rowHeight + (chosen.length > 1 ? ROW_GAP : 0);
			i--;
		}

		for (i in 0...rows.length)
		{
			var row = rows[i];
			if (i >= chosen.length)
			{
				row.visible = false;
				continue;
			}

			var entry = chosen[i];
			row.visible = true;
			row.color = entry.color;
			row.alpha = 1;
			row.text = displayEntry(entry);
		}

		var nextHeight = Std.int(Math.min(MAX_PANEL_HEIGHT, Math.max(MIN_PANEL_HEIGHT, Math.ceil(usedHeight))));
		var nextWidth = calculatePanelWidth();
		if (nextHeight != panelHeight || nextWidth != panelWidth)
		{
			panelHeight = nextHeight;
			panelWidth = nextWidth;
			redrawPanel();
		}
		else
			background.alpha = BACKGROUND_ALPHA;
		updatePanelTargetPosition();

		var yPos:Float = messageStartY();
		var finalTextWidth = Math.max(80, panelWidth - PADDING * 2);
		background.x = panelX;
		background.y = panelY;
		titleText.x = panelX + PADDING;
		titleText.y = panelY + TITLE_Y;
		titleText.fieldWidth = finalTextWidth;
		for (row in rows)
		{
			if (!row.visible)
				continue;

			row.x = panelX + PADDING;
			row.fieldWidth = finalTextWidth;
			row.y = panelY + yPos;
			yPos += measuredRowHeight(row) + ROW_GAP;
		}
	}

	function calculatePanelWidth():Int
	{
		var widest:Float = titleText.textField != null ? titleText.textField.textWidth : titleText.width;
		for (row in rows)
		{
			if (row != null && row.visible)
			{
				var rowWidth:Float = row.textField != null ? row.textField.textWidth : row.width;
				if (rowWidth > widest)
					widest = rowWidth;
			}
		}
		return Std.int(Math.min(viewWidth() - PANEL_MARGIN * 2, Math.max(MIN_PANEL_WIDTH, Math.ceil(widest + PADDING * 2 + 14))));
	}

	function maxTextWidth():Int
	{
		return Std.int(Math.max(120, viewWidth() - PANEL_MARGIN * 2 - PADDING * 2));
	}

	function displayEntry(entry:DebugLuaEntry):String
	{
		return entry.count > 1 ? '${entry.text} x${entry.count}' : entry.text;
	}

	function measuredRowHeight(row:FlxText):Float
	{
		if (row == null)
			return 20;
		return Math.max(20, (row.textField != null ? row.textField.textHeight : row.height) + 6);
	}

	function measuredTitleHeight():Float
	{
		if (titleText == null)
			return 20;
		return Math.max(18, (titleText.textField != null ? titleText.textField.textHeight : titleText.height) + 2);
	}

	function messageStartY():Float
	{
		return TITLE_Y + measuredTitleHeight() + TITLE_GAP;
	}

	function showPanel():Void
	{
		if (hideTween != null)
			hideTween.cancel();
		if (showTween != null)
			showTween.cancel();

		hiding = false;
		revive();
		visible = true;
		active = true;
		alpha = 0;
		x = 0;
		y = 0;
		panelX = targetX();
		panelY = enterY();
		showTween = FlxTween.tween(this, {panelY: targetY(), alpha: 1}, TWEEN_TIME, {
			ease: FlxEase.quadOut,
			onUpdate: function(_) layoutEntries()
		});
		layoutEntries();
	}

	function startHide():Void
	{
		if (hiding || !visible)
			return;

		if (showTween != null)
			showTween.cancel();
		if (hideTween != null)
			hideTween.cancel();

		hiding = true;
		hideTween = FlxTween.tween(this, {panelY: exitY(), alpha: 0}, TWEEN_TIME, {
			ease: FlxEase.quadIn,
			onUpdate: function(_) layoutEntries(),
			onComplete: function(_)
			{
				entries.resize(0);
				for (row in rows)
					row.visible = false;
				hiding = false;
				kill();
			}
		});
	}

	function redrawPanel():Void
	{
		MD3ShapeTools.fillAndStrokeRoundRect(background, panelWidth, panelHeight, 22, 2, MD3Theme.surfaceContainerHigh, MD3Theme.outlineVariant);
		background.alpha = BACKGROUND_ALPHA;
	}

	inline function targetX():Float
		return (viewWidth() - panelWidth) * 0.5;

	inline function targetY():Float
		return ClientPrefs.data.downScroll ? PANEL_MARGIN : viewHeight() - panelHeight - PANEL_MARGIN;

	inline function enterY():Float
		return ClientPrefs.data.downScroll ? -panelHeight - PANEL_MARGIN : viewHeight() + PANEL_MARGIN;

	inline function exitY():Float
		return ClientPrefs.data.downScroll ? -panelHeight - PANEL_MARGIN : viewHeight() + PANEL_MARGIN;

	inline function viewWidth():Float
		return cameras != null && cameras.length > 0 && cameras[0] != null ? cameras[0].width : FlxG.width;

	inline function viewHeight():Float
		return cameras != null && cameras.length > 0 && cameras[0] != null ? cameras[0].height : FlxG.height;

	function updatePanelTargetPosition():Void
	{
		if (!visible || hiding || showTween != null && !showTween.finished)
			return;

		panelX = targetX();
		panelY = targetY();
	}

	override function destroy():Void
	{
		if (showTween != null)
			showTween.cancel();
		if (hideTween != null)
			hideTween.cancel();
		super.destroy();
	}
}

