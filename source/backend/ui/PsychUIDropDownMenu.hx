package backend.ui;

import backend.ui.PsychUIBox.UIStyleData;
import options.OptionsMenuTheme;
import flixel.math.FlxPoint;
import flixel.FlxCamera;

class PsychUIDropDownMenu extends PsychUIInputText
{
	public static final CLICK_EVENT = "dropdown_click";
	static var _pointerOwner:PsychUIDropDownMenu = null;

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
	var _listDragging:Bool = false;
	var _listDragStartY:Float = 0;
	var _listDragStartIndex:Int = 0;
	var _suppressItemRelease:Bool = false;
	var _ignoreNextUnfocus:Bool = false;
	var _lastScrollbarTheme:String = null;

	var _scrollUpBtn:FlxSprite;
	var _scrollDownBtn:FlxSprite;
	var _scrollTrack:FlxSprite;
	var _scrollThumb:FlxSprite;
	
	static inline var SCROLLBAR_W:Int = 16;
	static inline var SCROLL_BTN_H:Int = 18;
	static inline var ITEM_H:Int = 20;
	static inline var DRAG_DEADZONE:Float = 6;
	
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
			if (_ignoreNextUnfocus)
			{
				_ignoreNextUnfocus = false;
				return;
			}
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

	function refreshScrollbarTheme(force:Bool = false):Void
	{
		var signature:String = OptionsMenuTheme.signature();
		if (!force && _lastScrollbarTheme == signature)
			return;

		_lastScrollbarTheme = signature;
		drawScrollButton(_scrollUpBtn, true);
		drawScrollButton(_scrollDownBtn, false);

		if (_scrollTrack != null && _scrollTrack.height > 0)
			_scrollTrack.makeGraphic(SCROLLBAR_W, Std.int(_scrollTrack.height), OptionsMenuTheme.cardFill(false));
		if (_scrollThumb != null && _scrollThumb.height > 0)
			_scrollThumb.makeGraphic(SCROLLBAR_W - 2, Std.int(_scrollThumb.height), OptionsMenuTheme.current().accent);
	}
	
	function drawScrollButton(s:FlxSprite, up:Bool):Void
	{
		if (s == null)
			return;

		var buttonColor:Int = OptionsMenuTheme.difficultyCardFill(OptionsMenuTheme.current().accent, false);
		var arrowColor:Int = OptionsMenuTheme.readableTextOn(buttonColor);
		s.makeGraphic(SCROLLBAR_W, SCROLL_BTN_H, buttonColor, true);
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
					s.pixels.setPixel32(px, py, arrowColor);
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
		var totalItems:Int = getVisibleSourceLength();
		var visibleCount:Int = Std.int(Math.min(totalItems, _maxVisibleItems));
		var maxScroll:Int = Std.int(Math.max(0, totalItems - visibleCount));
		var newIndex:Int = Std.int(Math.max(0, Math.min(maxScroll, _scrollIndex + delta)));
		if (newIndex != _scrollIndex)
		{
			_scrollIndex = newIndex;
			showDropDown(true, _scrollIndex, _curFilter);
		}
	}

	function getVisibleSourceLength():Int
	{
		return _curFilter != null ? _curFilter.length : list.length;
	}

	function mouseOverVisibleList(cam:FlxCamera):Bool
	{
		for (item in _items)
		{
			if (item != null && item.visible && FlxG.mouse.overlaps(item.bg, cam))
				return true;
		}
		return false;
	}

	function mouseOverScrollbar(cam:FlxCamera):Bool
	{
		return _hasScrollbar
			&& (mouseOverSpriteScreenRect(_scrollUpBtn, cam)
				|| mouseOverSpriteScreenRect(_scrollDownBtn, cam)
				|| mouseOverSpriteScreenRect(_scrollTrack, cam)
				|| mouseOverSpriteScreenRect(_scrollThumb, cam));
	}

	function mouseOverDropdownSurface(cam:FlxCamera):Bool
	{
		return mouseOverVisibleList(cam) || mouseOverScrollbar(cam);
	}

	function blocksOtherDropDownInput():Bool
	{
		var cam:FlxCamera = camera != null ? camera : FlxG.camera;
		return PsychUIInputText.focusOn == this && (mouseOverDropdownSurface(cam) || _scrollDragging || _listDragging);
	}

	function blockedByOpenDropDown():Bool
	{
		if (_pointerOwner != null && _pointerOwner != this && (FlxG.mouse.pressed || FlxG.mouse.justPressed || FlxG.mouse.justReleased))
			return true;

		if (Std.isOfType(PsychUIInputText.focusOn, PsychUIDropDownMenu))
		{
			var openDropDown:PsychUIDropDownMenu = cast PsychUIInputText.focusOn;
			if (openDropDown != this && FlxG.mouse.justPressed && openDropDown.blocksOtherDropDownInput())
			{
				_pointerOwner = openDropDown;
				return true;
			}
		}

		return false;
	}

	function handleScrollbarInput(cam:FlxCamera):Bool
	{
		if (!_hasScrollbar || (PsychUIInputText.focusOn != this && !_scrollDragging))
			return false;

		if (FlxG.mouse.justPressed)
		{
			_tmpMouse = FlxG.mouse.getScreenPosition(cam);
			var visibleCount:Int = Std.int(Math.min(getVisibleSourceLength(), _maxVisibleItems));

			if (mouseOverSpriteScreenRect(_scrollUpBtn, cam))
			{
				_pointerOwner = this;
				_suppressItemRelease = true;
				scrollListBy(-1);
				return true;
			}
			else if (mouseOverSpriteScreenRect(_scrollDownBtn, cam))
			{
				_pointerOwner = this;
				_suppressItemRelease = true;
				scrollListBy(1);
				return true;
			}
			else if (mouseOverSpriteScreenRect(_scrollThumb, cam))
			{
				_pointerOwner = this;
				_suppressItemRelease = true;
				_scrollDragging = true;
				_scrollDragStartY = _tmpMouse.y;
				_scrollDragStartIndex = _scrollIndex;
				return true;
			}
			else if (mouseOverSpriteScreenRect(_scrollTrack, cam))
			{
				_pointerOwner = this;
				_suppressItemRelease = true;
				scrollListBy(_tmpMouse.y < _scrollThumb.y ? -visibleCount : visibleCount);
				return true;
			}
		}

		if (_scrollDragging)
		{
			_pointerOwner = this;
			_suppressItemRelease = true;
			if (FlxG.mouse.pressed)
			{
				var totalItems:Int = getVisibleSourceLength();
				var visibleCount:Int = Std.int(Math.min(totalItems, _maxVisibleItems));
				var maxScroll:Int = Std.int(Math.max(0, totalItems - visibleCount));
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
			return true;
		}

		return false;
	}

	function bringScrollbarToFront():Void
	{
		if (_scrollUpBtn == null)
			return;

		remove(_scrollUpBtn, true);
		remove(_scrollDownBtn, true);
		remove(_scrollTrack, true);
		remove(_scrollThumb, true);
		add(_scrollTrack);
		add(_scrollUpBtn);
		add(_scrollDownBtn);
		add(_scrollThumb);
	}
	
	function updateScrollbar():Void
	{
		refreshScrollbarTheme();

		if (!_hasScrollbar || _scrollUpBtn == null)
		{
			if (_scrollUpBtn != null) _scrollUpBtn.visible = false;
			if (_scrollDownBtn != null) _scrollDownBtn.visible = false;
			if (_scrollTrack != null) _scrollTrack.visible = false;
			if (_scrollThumb != null) _scrollThumb.visible = false;
			return;
		}
		
		var totalItems:Int = getVisibleSourceLength();
		var visibleCount:Int = Std.int(Math.min(totalItems, _maxVisibleItems));
		var listHeight:Int = Std.int(Math.max(visibleCount * ITEM_H, SCROLL_BTN_H * 2 + 10));

		var scrollX:Float = behindText.x + _itemWidth + 1;
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
		_scrollTrack.makeGraphic(SCROLLBAR_W, Std.int(Math.max(1, listHeight - SCROLL_BTN_H * 2)), OptionsMenuTheme.cardFill(false));
		_scrollTrack.visible = true;
		_scrollTrack.active = true;
		
		var maxScroll:Int = Std.int(Math.max(0, totalItems - visibleCount));
		var trackH:Float = _scrollTrack.height;
		var thumbH:Float = totalItems > 0 ? Math.max(10, trackH * (visibleCount / totalItems)) : trackH;
		
		if (Std.int(_scrollThumb.height) != Std.int(thumbH))
			_scrollThumb.makeGraphic(SCROLLBAR_W - 2, Std.int(thumbH), OptionsMenuTheme.current().accent);
			
		var ratio:Float = maxScroll > 0 ? _scrollIndex / maxScroll : 0;
		_scrollThumb.x = scrollX + 1;
		_scrollThumb.y = _scrollTrack.y + ratio * (trackH - thumbH);
		_scrollThumb.visible = true;
		_scrollThumb.active = true;
		bringScrollbarToFront();
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
		if (_pointerOwner != null && !FlxG.mouse.pressed && !FlxG.mouse.justPressed && !FlxG.mouse.justReleased)
			_pointerOwner = null;
		if (blockedByOpenDropDown())
			return;

		var cam = camera != null ? camera : FlxG.camera;
		var lastFocus = PsychUIInputText.focusOn;
		var keepFocusFromDropdown:Bool = PsychUIInputText.focusOn == this && FlxG.mouse.justPressed && (mouseOverVisibleList(cam) || mouseOverScrollbar(cam));
		var handledScrollbarInput:Bool = handleScrollbarInput(cam);

		if (keepFocusFromDropdown || handledScrollbarInput)
			_ignoreNextUnfocus = true;

		super.update(elapsed);

		if (keepFocusFromDropdown || handledScrollbarInput)
			PsychUIInputText.focusOn = this;
		
		if(FlxG.mouse.justPressed)
		{
			var mouseOverButton = FlxG.mouse.overlaps(button, camera);
			var mouseOverDropdown = false;
			var overScrollbar = false;

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

				if (!mouseOverDropdown)
					overScrollbar = mouseOverScrollbar(cam);
			}
			
			if(mouseOverButton || mouseOverDropdown || overScrollbar)
			{
				button.animation.play('pressed', true);

				if(mouseOverButton || mouseOverDropdown || overScrollbar)
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
			if (_hasScrollbar && FlxG.mouse.justPressed && !handledScrollbarInput)
			{
				_tmpMouse = FlxG.mouse.getScreenPosition(cam);
				if (mouseOverVisibleList(cam))
				{
					_pointerOwner = this;
					_listDragging = true;
					_listDragStartY = _tmpMouse.y;
					_listDragStartIndex = _scrollIndex;
					_suppressItemRelease = false;
				}
			}

			var wheel:Int = FlxG.mouse.wheel;
			if(FlxG.keys.justPressed.UP) wheel++;
			if(FlxG.keys.justPressed.DOWN) wheel--;
			
			if(wheel != 0) 
			{
				scrollListBy(-wheel);
			}

			if (_listDragging)
			{
				if (!FlxG.mouse.pressed)
				{
					_listDragging = false;
				}
				else if (_hasScrollbar)
				{
					_tmpMouse = FlxG.mouse.getScreenPosition(cam);
					var dy:Float = _tmpMouse.y - _listDragStartY;
					if (Math.abs(dy) > DRAG_DEADZONE)
					{
						_suppressItemRelease = true;
						var totalItems:Int = getVisibleSourceLength();
						var visibleCount:Int = Std.int(Math.min(totalItems, _maxVisibleItems));
						var maxScroll:Int = Std.int(Math.max(0, totalItems - visibleCount));
						var newIndex:Int = Std.int(Math.max(0, Math.min(maxScroll, Math.round(_listDragStartIndex - dy / ITEM_H))));
						if (newIndex != _scrollIndex)
						{
							_scrollIndex = newIndex;
							showDropDown(true, _scrollIndex, _curFilter);
						}
					}
				}
			}

			if (FlxG.mouse.justReleased)
			{
				if (_pointerOwner == this)
					_pointerOwner = null;
				_scrollDragging = false;
				_listDragging = false;
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
			if (_pointerOwner == this)
				_pointerOwner = null;
			text = selectedLabel;
			_curFilter = null;
			_scrollDragging = false;
			_listDragging = false;
			_suppressItemRelease = false;

			if (_scrollUpBtn != null) _scrollUpBtn.visible = false;
			if (_scrollDownBtn != null) _scrollDownBtn.visible = false;
			if (_scrollTrack != null) _scrollTrack.visible = false;
			if (_scrollThumb != null) _scrollThumb.visible = false;
		}

		var totalForScroll:Int = onlyAllowed != null ? onlyAllowed.length : list.length;
		var maxScroll:Int = Std.int(Math.max(0, totalForScroll - _maxVisibleItems));
		curScroll = Std.int(Math.max(0, Math.min(maxScroll, scroll)));
		_scrollIndex = curScroll;
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
			var itemHeight:Float = ITEM_H;

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

	public function shouldSuppressItemRelease():Bool
	{
		return _suppressItemRelease || _scrollDragging || _listDragging;
	}

	function addOption(option:String)
	{
		@:bypassAccessor list.push(option);
		var curID:Int = list.length - 1;
		var item:PsychUIDropDownItem = cast recycle(PsychUIDropDownItem, () -> new PsychUIDropDownItem(1, 1, this._itemWidth), true);
		item.parentDropDown = this;
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
		if (_pointerOwner == this)
			_pointerOwner = null;

		if (_scrollUpBtn != null) _scrollUpBtn.destroy();
		if (_scrollDownBtn != null) _scrollDownBtn.destroy();
		if (_scrollTrack != null) _scrollTrack.destroy();
		if (_scrollThumb != null) _scrollThumb.destroy();
	}
}

class PsychUIDropDownItem extends FlxSpriteGroup
{
	public var parentDropDown:PsychUIDropDownMenu;
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
		if(FlxG.mouse.justMoved || FlxG.mouse.justPressed || FlxG.mouse.justReleased || forceNextUpdate)
		{
			var overlapped:Bool = (FlxG.mouse.overlaps(bg, camera));

			var style = overlapped ? hoverStyle : normalStyle;
			bg.color = style.bgColor;
			text.color = style.textColor;
			bg.alpha = style.bgAlpha;
			forceNextUpdate = false;

			if(overlapped && FlxG.mouse.justReleased && (parentDropDown == null || !parentDropDown.shouldSuppressItemRelease()))
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
