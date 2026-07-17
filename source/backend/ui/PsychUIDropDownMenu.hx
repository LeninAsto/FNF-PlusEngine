package backend.ui;

import backend.ui.PsychUIBox.UIStyleData;
import options.OptionsMenuTheme;
import flixel.math.FlxPoint;
import flixel.FlxCamera;

class PsychUIDropDownMenu extends PsychUIInputText
{
	public static final CLICK_EVENT = "dropdown_click";

	public var list(default, set):Array<String> = [];
	public var button:FlxSprite;
	public var onSelect:Int->String->Void;

	public var selectedIndex(default, set):Int = -1;
	public var selectedLabel(default, set):String = null;

	var _curFilter:Array<String>;
	var _itemWidth:Float = 0;

	var _maxVisibleItems:Int = 6;
	var _hasScrollbar:Bool = false;
	var _scrollIndex:Int = 0;
	var _scrollDragging:Bool = false;
	var _scrollDragStartY:Float = 0;
	var _scrollDragStartIndex:Int = 0;

	var _scrollUpBtn:FlxSprite;
	var _scrollDownBtn:FlxSprite;
	var _scrollTrack:FlxSprite;
	var _scrollThumb:FlxSprite;
	
	static inline var SCROLLBAR_W:Int = 16;
	static inline var SCROLL_BTN_H:Int = 18;
	
	var _tmpMouse:FlxPoint = new FlxPoint();
	var _tmpBg:FlxPoint = new FlxPoint();

	var _items:Array<PsychUIDropDownItem> = [];
	public var curScroll:Int = 0;

	public function new(x:Float, y:Float, list:Array<String>, callback:Int->String->Void, ?width:Float = 100, ?maxVisibleItems:Int = 6)
	{
		super(x, y);
		if(list == null) list = [];
		
		_maxVisibleItems = maxVisibleItems;
		_itemWidth = width - 2;
		setGraphicSize(width, 20);
		updateHitbox();
		textObj.y += 2;

		button = new FlxSprite(behindText.width + 1, 0).loadGraphic(Paths.image('psych-ui/dropdown_button', 'embed'), true, 20, 20);
		button.animation.add('normal', [0], false);
		button.animation.add('pressed', [1], false);
		button.animation.play('normal', true);
		add(button);

		onSelect = callback;

		onChange = function(old:String, cur:String)
		{
			if(old != cur)
			{
				_curFilter = this.list.filter(function(str:String) return str.startsWith(cur));
				showDropDown(true, 0, _curFilter);
			}
		}
		unfocus = function()
		{
			showDropDownClickFix();
			showDropDown(false);
		}

		for (option in list)
			addOption(option);

		selectedIndex = 0;
		showDropDown(false);

		createScrollbarElements();
	}

	function createScrollbarElements():Void
	{
		_scrollUpBtn = new FlxSprite(0, 0);
		drawScrollButton(_scrollUpBtn, true);
		_scrollUpBtn.visible = false;
		_scrollUpBtn.active = false;
		add(_scrollUpBtn);
		
		_scrollDownBtn = new FlxSprite(0, 0);
		drawScrollButton(_scrollDownBtn, false);
		_scrollDownBtn.visible = false;
		_scrollDownBtn.active = false;
		add(_scrollDownBtn);
		
		_scrollTrack = new FlxSprite(0, 0);
		_scrollTrack.makeGraphic(SCROLLBAR_W, 1, FlxColor.GRAY);
		_scrollTrack.visible = false;
		_scrollTrack.active = false;
		add(_scrollTrack);
		
		_scrollThumb = new FlxSprite(0, 0);
		_scrollThumb.makeGraphic(SCROLLBAR_W - 2, 10, FlxColor.WHITE);
		_scrollThumb.visible = false;
		_scrollThumb.active = false;
		add(_scrollThumb);
	}
	
	function drawScrollButton(s:FlxSprite, up:Bool):Void
	{
		s.makeGraphic(SCROLLBAR_W, SCROLL_BTN_H, FlxColor.GRAY, true);
		var cx:Int = Std.int(SCROLLBAR_W / 2);
		var cy:Int = Std.int(SCROLL_BTN_H / 2);
		var dir:Int = up ? 1 : -1;
		for (row in 0...3)
		{
			for (col in 0...(row * 2 + 1))
			{
				var px:Int = cx - row + col;
				var py:Int = cy + dir * (row - 1);
				if (px >= 0 && px < SCROLLBAR_W && py >= 0 && py < SCROLL_BTN_H)
					s.pixels.setPixel32(px, py, FlxColor.WHITE);
			}
		}
	}
	
	function mouseOverSpriteScreenRect(s:FlxSprite, cam:FlxCamera):Bool
	{
		if (s == null || !s.visible)
			return false;
			
		_tmpMouse = FlxG.mouse.getScreenPosition(cam);
		s.getScreenPosition(_tmpBg, cam);
		
		return _tmpMouse.x >= _tmpBg.x
			&& _tmpMouse.x < _tmpBg.x + s.width
			&& _tmpMouse.y >= _tmpBg.y
			&& _tmpMouse.y < _tmpBg.y + s.height;
	}
	
	function getHoveredIndexOnList(cam:FlxCamera):Int
	{
		if (!FlxG.mouse.overlaps(bg, cam))
			return -1;
			
		_tmpMouse = FlxG.mouse.getScreenPosition(cam);
		bg.getScreenPosition(_tmpBg, cam);
		
		var localX:Float = _tmpMouse.x - _tmpBg.x;
		var localY:Float = _tmpMouse.y - _tmpBg.y;

		if (_hasScrollbar && localX >= _itemWidth - SCROLLBAR_W)
			return -1;
			
		var idx:Int = _scrollIndex + Std.int(localY / 20);
		return (idx >= 0 && idx < list.length) ? idx : -1;
	}
	
	function ensureSelectedVisible():Void
	{
		if (list == null || list.length == 0)
		{
			_scrollIndex = 0;
			return;
		}
		
		var visibleCount:Int = Std.int(Math.min(list.length, _maxVisibleItems));
		if (visibleCount <= 0)
		{
			_scrollIndex = 0;
			return;
		}
		
		var maxScroll:Int = Std.int(Math.max(0, list.length - visibleCount));
		if (selectedIndex < _scrollIndex)
			_scrollIndex = selectedIndex;
		else if (selectedIndex >= _scrollIndex + visibleCount)
			_scrollIndex = selectedIndex - visibleCount + 1;
			
		if (_scrollIndex < 0)
			_scrollIndex = 0;
		if (_scrollIndex > maxScroll)
			_scrollIndex = maxScroll;
	}
	
	function scrollListBy(delta:Int):Void
	{
		var visibleCount:Int = Std.int(Math.min(list.length, _maxVisibleItems));
		var maxScroll:Int = Std.int(Math.max(0, list.length - visibleCount));
		var newIndex:Int = Std.int(Math.max(0, Math.min(maxScroll, _scrollIndex + delta)));
		if (newIndex != _scrollIndex)
		{
			_scrollIndex = newIndex;
			showDropDown(true, _scrollIndex, _curFilter);
		}
	}
	
	function updateScrollbar():Void
	{
		if (!_hasScrollbar || _scrollUpBtn == null)
		{
			if (_scrollUpBtn != null) _scrollUpBtn.visible = false;
			if (_scrollDownBtn != null) _scrollDownBtn.visible = false;
			if (_scrollTrack != null) _scrollTrack.visible = false;
			if (_scrollThumb != null) _scrollThumb.visible = false;
			return;
		}
		
		var visibleCount:Int = Std.int(Math.min(list.length, _maxVisibleItems));
		var listHeight:Int = visibleCount * 20;

		var scrollX:Float = x + _itemWidth - SCROLLBAR_W;
		var scrollY:Float = behindText.y + behindText.height + 1;
		
		_scrollUpBtn.x = scrollX;
		_scrollUpBtn.y = scrollY;
		_scrollUpBtn.visible = true;
		_scrollUpBtn.active = true;
		
		_scrollDownBtn.x = scrollX;
		_scrollDownBtn.y = scrollY + listHeight - SCROLL_BTN_H;
		_scrollDownBtn.visible = true;
		_scrollDownBtn.active = true;
		
		_scrollTrack.x = scrollX;
		_scrollTrack.y = scrollY + SCROLL_BTN_H;
		_scrollTrack.makeGraphic(SCROLLBAR_W, listHeight - SCROLL_BTN_H * 2, FlxColor.GRAY);
		_scrollTrack.visible = true;
		_scrollTrack.active = true;
		
		var maxScroll:Int = Std.int(Math.max(0, list.length - visibleCount));
		var trackH:Float = _scrollTrack.height;
		var thumbH:Float = Math.max(10, trackH * (visibleCount / list.length));
		
		if (Std.int(_scrollThumb.height) != Std.int(thumbH))
			_scrollThumb.makeGraphic(SCROLLBAR_W - 2, Std.int(thumbH), FlxColor.WHITE);
			
		var ratio:Float = maxScroll > 0 ? _scrollIndex / maxScroll : 0;
		_scrollThumb.x = scrollX + 1;
		_scrollThumb.y = _scrollTrack.y + ratio * (trackH - thumbH);
		_scrollThumb.visible = true;
		_scrollThumb.active = true;
	}

	function set_selectedIndex(v:Int)
	{
		selectedIndex = v;
		if(selectedIndex < 0 || selectedIndex >= list.length) selectedIndex = -1;

		@:bypassAccessor selectedLabel = list[selectedIndex];
		text = (selectedLabel != null) ? selectedLabel : '';

		if (selectedIndex >= 0)
			ensureSelectedVisible();
			
		return selectedIndex;
	}

	function set_selectedLabel(v:String)
	{
		var id:Int = list.indexOf(v);
		if(id >= 0)
		{
			@:bypassAccessor selectedIndex = id;
			selectedLabel = v;
			text = selectedLabel;
			ensureSelectedVisible();
		}
		else
		{
			@:bypassAccessor selectedIndex = -1;
			selectedLabel = null;
			text = '';
		}
		return selectedLabel;
	}

	override function update(elapsed:Float)
	{
		var lastFocus = PsychUIInputText.focusOn;
		super.update(elapsed);
		
		if(FlxG.mouse.justPressed)
		{
			var mouseOverButton = FlxG.mouse.overlaps(button, camera);
			var mouseOverDropdown = false;
			var mouseOverScrollbar = false;

			if(PsychUIInputText.focusOn == this)
			{
				for(item in _items)
				{
					if(item.visible && FlxG.mouse.overlaps(item.bg, camera))
					{
						mouseOverDropdown = true;
						break;
					}
				}

				if (!mouseOverDropdown && _hasScrollbar)
				{
					var cam = camera != null ? camera : FlxG.camera;
					
					if (mouseOverSpriteScreenRect(_scrollUpBtn, cam) ||
						mouseOverSpriteScreenRect(_scrollDownBtn, cam) ||
						mouseOverSpriteScreenRect(_scrollTrack, cam) ||
						mouseOverSpriteScreenRect(_scrollThumb, cam))
					{
						mouseOverScrollbar = true;
					}
				}
			}
			
			if(mouseOverButton || mouseOverDropdown || mouseOverScrollbar)
			{
				button.animation.play('pressed', true);

				if(mouseOverButton || mouseOverDropdown || mouseOverScrollbar)
				{
					PsychUIInputText.focusOn = this;
				}

				if(mouseOverButton && lastFocus == this)
				{
					PsychUIInputText.focusOn = null;
				}
			}
			else if(PsychUIInputText.focusOn == this && !FlxG.mouse.overlaps(this, camera))
			{
				var cam = camera != null ? camera : FlxG.camera;
				if (!mouseOverSpriteScreenRect(_scrollUpBtn, cam) &&
					!mouseOverSpriteScreenRect(_scrollDownBtn, cam) &&
					!mouseOverSpriteScreenRect(_scrollTrack, cam) &&
					!mouseOverSpriteScreenRect(_scrollThumb, cam))
				{
					PsychUIInputText.focusOn = null;
				}
			}
		}
		else if(FlxG.mouse.released && button.animation.curAnim != null && button.animation.curAnim.name != 'normal') 
		{
			button.animation.play('normal', true);
		}

		if(lastFocus != PsychUIInputText.focusOn)
		{
			showDropDown(PsychUIInputText.focusOn == this);
		}
		else if(PsychUIInputText.focusOn == this)
		{
			var wheel:Int = FlxG.mouse.wheel;
			if(FlxG.keys.justPressed.UP) wheel++;
			if(FlxG.keys.justPressed.DOWN) wheel--;
			
			if(wheel != 0) 
			{
				scrollListBy(-wheel);
			}

			if (_scrollDragging)
			{
				if (!FlxG.mouse.pressed)
				{
					_scrollDragging = false;
				}
				else if (_hasScrollbar)
				{
					var cam = camera != null ? camera : FlxG.camera;
					var visibleCount:Int = Std.int(Math.min(list.length, _maxVisibleItems));
					var maxScroll:Int = Std.int(Math.max(0, list.length - visibleCount));
					var usable:Float = _scrollTrack.height - _scrollThumb.height;
					
					if (usable > 0 && maxScroll > 0)
					{
						_tmpMouse = FlxG.mouse.getScreenPosition(cam);
						var dy:Float = _tmpMouse.y - _scrollDragStartY;
						var newIndex:Int = Std.int(Math.round(_scrollDragStartIndex + dy / usable * maxScroll));
						newIndex = Std.int(Math.max(0, Math.min(maxScroll, newIndex)));
						if (newIndex != _scrollIndex)
						{
							_scrollIndex = newIndex;
							showDropDown(true, _scrollIndex, _curFilter);
						}
					}
				}
			}
		}
	}

	private function showDropDownClickFix()
	{
		if(FlxG.mouse.justPressed)
		{
			for (item in _items) //extra update to fix a little bug where it wouldnt click on any option if another input text was behind the drop down
				if(item != null && item.active && item.visible)
					item.update(0);
		}
	}

	public function showDropDown(vis:Bool = true, scroll:Int = 0, onlyAllowed:Array<String> = null)
	{
		if(!vis)
		{
			text = selectedLabel;
			_curFilter = null;
			_scrollDragging = false;

			if (_scrollUpBtn != null) _scrollUpBtn.visible = false;
			if (_scrollDownBtn != null) _scrollDownBtn.visible = false;
			if (_scrollTrack != null) _scrollTrack.visible = false;
			if (_scrollThumb != null) _scrollThumb.visible = false;
		}

		curScroll = Std.int(Math.max(0, Math.min(onlyAllowed != null ? (onlyAllowed.length - 1) : (list.length - 1), scroll)));
		if(vis)
		{
			var n:Int = 0;
			var visibleCount:Int = 0;
			var totalItems:Int = onlyAllowed != null ? onlyAllowed.length : list.length;

			_hasScrollbar = totalItems > _maxVisibleItems;
			var startIdx:Int = _hasScrollbar ? curScroll : 0;
			var endIdx:Int = _hasScrollbar ? Std.int(Math.min(startIdx + _maxVisibleItems, totalItems)) : totalItems;

			for (item in _items)
			{
				item.active = false;
				item.visible = false;
			}

			var shownCount:Int = 0;
			var itemIndex:Int = 0;
			for (item in _items)
			{
				var shouldShow:Bool = false;
				if (onlyAllowed != null)
				{
					if (onlyAllowed.contains(item.label))
					{
						shouldShow = (itemIndex >= startIdx && itemIndex < endIdx);
						itemIndex++;
					}
				}
				else
				{
					shouldShow = (itemIndex >= startIdx && itemIndex < endIdx);
					itemIndex++;
				}
				
				if (shouldShow)
				{
					item.active = true;
					item.visible = true;
					shownCount++;
				}
			}

			var txtY:Float = behindText.y + behindText.height + 1;
			var itemHeight:Float = 20;

			var shownNum:Int = 0;
			for (item in _items)
			{
				if(!item.visible) continue;
				item.x = behindText.x;
				item.y = txtY;
				txtY += itemHeight;
				item.forceNextUpdate = true;
				shownNum++;
			}

			var listHeight:Float = shownNum * itemHeight;
			bg.scale.y = listHeight + 2;
			bg.updateHitbox();

			if (_hasScrollbar)
			{
				updateScrollbar();
			}
			else
			{
				if (_scrollUpBtn != null) _scrollUpBtn.visible = false;
				if (_scrollDownBtn != null) _scrollDownBtn.visible = false;
				if (_scrollTrack != null) _scrollTrack.visible = false;
				if (_scrollThumb != null) _scrollThumb.visible = false;
			}
		}
		else
		{
			for (item in _items)
				item.active = item.visible = false;

			bg.scale.y = 20;
			bg.updateHitbox();
		}
	}

	public var broadcastDropDownEvent:Bool = true;
	function clickedOn(num:Int, label:String)
	{
		selectedIndex = num;
		showDropDown(false);
		if(onSelect != null) onSelect(num, label);
		if(broadcastDropDownEvent) PsychUIEventHandler.event(CLICK_EVENT, this);
	}

	public function isMouseOverDropdown():Bool
	{
		if(FlxG.mouse.overlaps(button, camera))
			return true;
			
		if(PsychUIInputText.focusOn == this)
		{
			for(item in _items)
			{
				if(item.visible && FlxG.mouse.overlaps(item.bg, camera))
					return true;
			}
		}
		
		return false;
	}

	function addOption(option:String)
	{
		@:bypassAccessor list.push(option);
		var curID:Int = list.length - 1;
		var item:PsychUIDropDownItem = cast recycle(PsychUIDropDownItem, () -> new PsychUIDropDownItem(1, 1, this._itemWidth), true);
		item.cameras = cameras;
		item.label = option;
		item.visible = item.active = false;
		item.onClick = function() clickedOn(curID, option);
		item.forceNextUpdate = true;
		_items.push(item);
		insert(1, item);
	}

	function set_list(v:Array<String>)
	{
		var selected:String = selectedLabel;
		showDropDown(false);

		for (item in _items)
			item.kill();

		_items = [];
		list = [];
		for (option in v)
			addOption(option);

		if(selectedLabel != null) selectedLabel = selected;
		_hasScrollbar = list.length > _maxVisibleItems;
		return v;
	}

	override function destroy()
	{
		super.destroy();

		if (_scrollUpBtn != null) _scrollUpBtn.destroy();
		if (_scrollDownBtn != null) _scrollDownBtn.destroy();
		if (_scrollTrack != null) _scrollTrack.destroy();
		if (_scrollThumb != null) _scrollThumb.destroy();
	}
}

class PsychUIDropDownItem extends FlxSpriteGroup
{
	public var hoverStyle:UIStyleData = {
		bgColor: 0xFF0066FF,
		textColor: FlxColor.WHITE,
		bgAlpha: 1
	};
	public var normalStyle:UIStyleData = {
		bgColor: FlxColor.WHITE,
		textColor: FlxColor.BLACK,
		bgAlpha: 1
	};

	public var bg:FlxSprite;
	public var text:FlxText;
	public function new(x:Float = 0, y:Float = 0, width:Float = 100)
	{
		super(x, y);
		refreshStyles();

		bg = new FlxSprite().makeGraphic(1, 1, FlxColor.WHITE);
		bg.setGraphicSize(width, 20);
		bg.updateHitbox();
		add(bg);

		text = new FlxText(0, 0, width, 8);
		text.color = normalStyle.textColor;
		add(text);
	}

	function refreshStyles():Void
	{
		hoverStyle = {
			bgColor: OptionsMenuTheme.current().accent,
			textColor: OptionsMenuTheme.readableTextOn(OptionsMenuTheme.current().accent),
			bgAlpha: 1
		};
		normalStyle = {
			bgColor: OptionsMenuTheme.cardFill(false),
			textColor: OptionsMenuTheme.readableTextOn(OptionsMenuTheme.cardFill(false)),
			bgAlpha: OptionsMenuTheme.isDark() ? 0.96 : 1
		};
	}

	public var onClick:Void->Void;
	public var forceNextUpdate:Bool = false;
	override function update(elapsed:Float)
	{
		super.update(elapsed);
		if(FlxG.mouse.justMoved || FlxG.mouse.justPressed || forceNextUpdate)
		{
			var overlapped:Bool = (FlxG.mouse.overlaps(bg, camera));

			var style = overlapped ? hoverStyle : normalStyle;
			bg.color = style.bgColor;
			text.color = style.textColor;
			bg.alpha = style.bgAlpha;
			forceNextUpdate = false;

			if(overlapped && FlxG.mouse.justPressed)
				onClick();
		}
		
		text.x = bg.x;
		text.y = bg.y + bg.height/2 - text.height/2;
	}

	public var label(default, set):String;
	function set_label(v:String)
	{
		label = v;
		text.text = v;
		bg.scale.y = text.height + 6;
		bg.updateHitbox();
		return v;
	}
}