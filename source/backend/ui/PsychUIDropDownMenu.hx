package backend.ui;

import backend.ui.PsychUIBox.UIStyleData;
#if FLX_TOUCH
import flixel.input.touch.FlxTouch;
#end

class PsychUIDropDownMenu extends PsychUIInputText {
	public static final CLICK_EVENT = "dropdown_click";

	public var list(default, set):Array<String> = [];
	public var button:FlxSprite;
	public var scrollTrack:FlxSprite;
	public var scrollThumb:FlxSprite;
	public var onSelect:Int->String->Void;

	public var selectedIndex(get, set):Int;
	public var selectedLabel(get, set):String;
	var _selectedIndex:Int = -1;
	var _selectedLabel:String = null;

	var _curFilter:Array<String>;
	var _itemWidth:Float = 0;
	var _maxVisibleItems:Int = 0;
	var _scrollBarWidth:Int = 8;
	var _visibleItems:Int = 0;
	var _opensUpward:Bool = false;
	var _scrollDragging:Bool = false;
	var _pointerPosition:FlxPoint = new FlxPoint();
	#if FLX_TOUCH
	var _touchDragID:Int = -1;
	var _touchDragStartY:Float = 0;
	var _touchDragStartScroll:Int = 0;
	var _touchDragMoved:Bool = false;
	var _clearTouchDragNextFrame:Bool = false;
	static inline var TOUCH_DRAG_DEADZONE:Float = 8;
	#end

	public function new(x:Float, y:Float, list:Array<String>, callback:Int->String->Void, ?width:Float = 100, ?maxVisibleItems:Int = 0) {
		super(x, y);
		blocksPointerInputBehind = true;
		// Dropdowns are searchable inputs too. In particular, Android users need
		// the soft keyboard to filter long character/event lists.
		showSoftKeyboardOnFocus = true;
		if (list == null)
			list = [];

		_itemWidth = width - 2;
		_maxVisibleItems = maxVisibleItems;
		#if mobile
		if (_maxVisibleItems <= 0)
			_maxVisibleItems = 8;
		#end
		setGraphicSize(width, 20);
		updateHitbox();
		textObj.y += 2;

		button = new FlxSprite(behindText.width + 1, 0).loadGraphic(Paths.image('psych-ui/dropdown_button', 'embed'), true, 20, 20);
		button.animation.add('normal', [0], false);
		button.animation.add('pressed', [1], false);
		button.animation.play('normal', true);
		add(button);

		#if mobile
		_scrollBarWidth = 14;
		#end
		scrollTrack = new FlxSprite().makeGraphic(_scrollBarWidth, 1, 0xFF303030);
		scrollThumb = new FlxSprite().makeGraphic(_scrollBarWidth, 1, 0xFFB0B0B0);
		scrollTrack.visible = scrollTrack.active = false;
		scrollThumb.visible = scrollThumb.active = false;
		add(scrollTrack);
		add(scrollThumb);

		onSelect = callback;

		onChange = function(old:String, cur:String) {
			if (old != cur) {
				_curFilter = this.list.filter(function(str:String) return str.startsWith(cur));
				showDropDown(true, 0, _curFilter);
			}
		}
		unfocus = function() {
			showDropDownClickFix();
			showDropDown(false);
		}

		for (option in list)
			addOption(option);

		selectedIndex = 0;
		showDropDown(false);
	}

	function set_selectedIndex(v:Int) {
		_selectedIndex = v;
		if (_selectedIndex < 0 || _selectedIndex >= list.length)
			_selectedIndex = -1;

		_selectedLabel = list[_selectedIndex];
		text = (_selectedLabel != null) ? _selectedLabel : '';
		return _selectedIndex;
	}

	function get_selectedIndex():Int return _selectedIndex;

	function set_selectedLabel(v:String) {
		var id:Int = list.indexOf(v);
		if (id >= 0) {
			_selectedIndex = id;
			_selectedLabel = v;
			text = _selectedLabel;
		} else {
			_selectedIndex = -1;
			_selectedLabel = null;
			text = '';
		}
		return _selectedLabel;
	}

	function get_selectedLabel():String return _selectedLabel;

	var _items:Array<PsychUIDropDownItem> = [];

	public var curScroll:Int = 0;

	override function update(elapsed:Float) {
		#if FLX_TOUCH
		if (_clearTouchDragNextFrame) {
			_clearTouchDragNextFrame = false;
			_touchDragMoved = false;
		}
		#end

		var lastFocus = PsychUIInputText.focusOn;
		var pressedScroll:Bool = FlxG.mouse.justPressed && scrollTrack.visible && FlxG.mouse.overlaps(scrollTrack, camera);
		super.update(elapsed);

		if (pressedScroll) {
			PsychUIInputText.focusOn = this;
			_scrollDragging = true;
			updateScrollFromPointer();
		} else if (_scrollDragging) {
			if (FlxG.mouse.pressed)
				updateScrollFromPointer();
			else
				_scrollDragging = false;
		}

		if (FlxG.mouse.justPressed) {
			if (FlxG.mouse.overlaps(button, camera)) {
				button.animation.play('pressed', true);
				if (lastFocus != this)
					PsychUIInputText.focusOn = this;
				else if (PsychUIInputText.focusOn == this)
					PsychUIInputText.focusOn = null;
			}
		} else if (FlxG.mouse.released && button.animation.curAnim != null && button.animation.curAnim.name != 'normal')
			button.animation.play('normal', true);

		#if FLX_TOUCH
		var buttonTouch:FlxTouch = findTouchOver(button, true, false);
		if (buttonTouch != null) {
			button.animation.play('pressed', true);
			PsychUIInputText.focusOn = lastFocus == this ? null : this;
		} else if (findReleasedTouch() != null && button.animation.curAnim != null && button.animation.curAnim.name != 'normal')
			button.animation.play('normal', true);
		#end

		if (lastFocus != PsychUIInputText.focusOn) {
			if (PsychUIInputText.focusOn == this) {
				text = '';
				_curFilter = list;
			}
			showDropDown(PsychUIInputText.focusOn == this);
		} else if (PsychUIInputText.focusOn == this) {
			var wheel:Int = FlxG.mouse.wheel;
			if (FlxG.keys.justPressed.UP)
				wheel++;
			if (FlxG.keys.justPressed.DOWN)
				wheel--;
			if (wheel != 0)
				showDropDown(true, curScroll - wheel, _curFilter);
			#if FLX_TOUCH
			handleTouchScrolling();
			#end
		}
	}

	function updateScrollFromPointer():Void {
		updateScrollFromY(FlxG.mouse.getWorldPosition(camera, _pointerPosition).y);
	}

	function updateScrollFromY(pointerY:Float):Void {
		var source:Array<String> = _curFilter != null ? _curFilter : list;
		var visibleCount:Int = _visibleItems > 0 ? Std.int(Math.min(_visibleItems, source.length)) : getVisibleCount(source.length);
		var maxScroll:Int = Std.int(Math.max(0, source.length - visibleCount));
		if (maxScroll <= 0)
			return;

		var travel:Float = scrollTrack.height - scrollThumb.height;
		var ratio:Float = FlxMath.bound((pointerY - scrollTrack.y - scrollThumb.height / 2) / Math.max(1, travel), 0, 1);
		showDropDown(true, Math.round(ratio * maxScroll), _curFilter);
	}

	override public function keepFocusOnPointerPress():Bool {
		if (FlxG.mouse.overlaps(button, camera) || (scrollTrack.visible && FlxG.mouse.overlaps(scrollTrack, camera)))
			return true;

		for (item in _items)
			if (item != null && item.visible && item.active && FlxG.mouse.overlaps(item.bg, camera))
				return true;

		#if FLX_TOUCH
		for (touch in FlxG.touches.list) {
			if (touch == null || !touch.justPressed)
				continue;
			if (touch.overlaps(button, camera) || (scrollTrack.visible && touch.overlaps(scrollTrack, camera)))
				return true;
			if (touchOverVisibleItem(touch))
				return true;
		}
		#end
		return false;
	}

	#if FLX_TOUCH
	function findTouchOver(object:FlxSprite, justPressedOnly:Bool, justReleasedOnly:Bool):FlxTouch {
		for (touch in FlxG.touches.list) {
			if (touch == null || (justPressedOnly && !touch.justPressed) || (justReleasedOnly && !touch.justReleased))
				continue;
			if (touch.overlaps(object, camera))
				return touch;
		}
		return null;
	}

	function findReleasedTouch():FlxTouch {
		for (touch in FlxG.touches.list)
			if (touch != null && touch.justReleased)
				return touch;
		return null;
	}

	function findTouchByID(id:Int):FlxTouch {
		for (touch in FlxG.touches.list)
			if (touch != null && touch.touchPointID == id)
				return touch;
		return null;
	}

	function touchOverVisibleItem(touch:FlxTouch):Bool {
		for (item in _items)
			if (item != null && item.visible && item.active && touch.overlaps(item.bg, camera))
				return true;
		return false;
	}

	function handleTouchScrolling():Void {
		if (_touchDragID < 0) {
			for (touch in FlxG.touches.list) {
				if (touch == null || !touch.justPressed)
					continue;

				if (scrollTrack.visible && touch.overlaps(scrollTrack, camera)) {
					updateScrollFromY(touch.getWorldPosition(camera, _pointerPosition).y);
					_touchDragMoved = true;
					return;
				}

				if (touchOverVisibleItem(touch)) {
					_touchDragID = touch.touchPointID;
					_touchDragStartY = touch.getWorldPosition(camera, _pointerPosition).y;
					_touchDragStartScroll = curScroll;
					_touchDragMoved = false;
					return;
				}
			}
			_touchDragMoved = false;
			return;
		}

		var activeTouch:FlxTouch = findTouchByID(_touchDragID);
		if (activeTouch == null) {
			_touchDragID = -1;
			_touchDragMoved = false;
			return;
		}

		var currentY:Float = activeTouch.getWorldPosition(camera, _pointerPosition).y;
		var deltaY:Float = currentY - _touchDragStartY;
		if (activeTouch.pressed && Math.abs(deltaY) >= TOUCH_DRAG_DEADZONE) {
			_touchDragMoved = true;
			var rowHeight:Float = 20;
			for (item in _items) {
				if (item != null && item.height > 0) {
					rowHeight = item.height;
					break;
				}
			}
			showDropDown(true, _touchDragStartScroll - Math.round(deltaY / rowHeight), _curFilter);
		}

		if (activeTouch.justReleased) {
			_touchDragID = -1;
			_clearTouchDragNextFrame = true;
		} else if (!activeTouch.pressed) {
			_touchDragID = -1;
			_touchDragMoved = false;
		}
	}

	public inline function suppressTouchSelection():Bool
		return _touchDragMoved;
	#end

	inline function getVisibleCount(total:Int):Int {
		return _maxVisibleItems > 0 ? Std.int(Math.min(_maxVisibleItems, total)) : total;
	}

	function getRowHeight():Float {
		for (item in _items)
			if (item != null && item.height > 0)
				return item.height;
		return 20;
	}

	function updateMobileLayout(total:Int):Int {
		var wanted:Int = getVisibleCount(total);
		_opensUpward = false;
		#if mobile
		if (wanted > 0 && camera != null) {
			var zoom:Float = Math.abs(camera.zoom);
			if (zoom <= 0)
				zoom = 1;
			var screenY:Float = behindText.getScreenPosition(_pointerPosition, camera).y;
			var rowHeight:Float = getRowHeight() * zoom;
			var margin:Float = 8;
			var below:Int = Math.floor(Math.max(0, camera.y + camera.height - screenY - behindText.height * zoom - margin) / rowHeight);
			var above:Int = Math.floor(Math.max(0, screenY - camera.y - margin) / rowHeight);
			_opensUpward = below < wanted && above > below;
			var available:Int = _opensUpward ? above : below;
			wanted = Std.int(Math.min(wanted, Math.max(1, available)));
		}
		#end
		return wanted;
	}

	private function showDropDownClickFix() {
		if (FlxG.mouse.justPressed) {
			for (item in _items) // extra update to fix a little bug where it wouldnt click on any option if another input text was behind the drop down
				if (item != null && item.active && item.visible)
					item.update(0);
		}
	}

	public function showDropDown(vis:Bool = true, scroll:Int = 0, onlyAllowed:Array<String> = null) {
		if (!vis) {
			text = selectedLabel;
			_curFilter = null;
			#if FLX_TOUCH
			_touchDragID = -1;
			#end
		}

		var totalItems:Int = onlyAllowed != null ? onlyAllowed.length : list.length;
		var visibleCount:Int = updateMobileLayout(totalItems);
		_visibleItems = visibleCount;
		var maxScroll:Int = Std.int(Math.max(0, totalItems - visibleCount));
		curScroll = Std.int(Math.max(0, Math.min(maxScroll, scroll)));
		if (vis) {
			var n:Int = 0;
			for (item in _items) {
				var visibleSlot:Bool = n - curScroll < visibleCount;
				if (onlyAllowed != null) {
					if (onlyAllowed.contains(item.label)) {
						item.active = item.visible = (n >= curScroll && visibleSlot);
						n++;
					} else
						item.active = item.visible = false;
				} else {
					item.active = item.visible = (n >= curScroll && visibleSlot);
					n++;
				}
			}

			var txtY:Float = behindText.y + behindText.height + 1;
			if (_opensUpward) {
				var listHeight:Float = 0;
				for (item in _items)
					if (item.visible)
						listHeight += item.height;
				txtY = behindText.y - listHeight - 1;
			}
			var listTop:Float = txtY;
			for (num => item in _items) {
				if (!item.visible)
					continue;
				item.x = behindText.x;
				item.y = txtY;
				txtY += item.height;
				item.forceNextUpdate = true;
			}
			var bgTop:Float = Math.min(behindText.y - 1, listTop - 1);
			var bgBottom:Float = Math.max(behindText.y + behindText.height + 1, txtY + 1);
			bg.y = bgTop;
			bg.scale.y = bgBottom - bgTop;
			bg.updateHitbox();

			var showScroll:Bool = maxScroll > 0;
			scrollTrack.visible = scrollTrack.active = showScroll;
			scrollThumb.visible = scrollThumb.active = showScroll;
			if (showScroll) {
				var top:Float = listTop;
				var height:Float = Math.max(1, txtY - listTop);
				scrollTrack.setPosition(behindText.x + _itemWidth - _scrollBarWidth, top);
				scrollTrack.setGraphicSize(_scrollBarWidth, height);
				scrollTrack.updateHitbox();

				var thumbHeight:Float = Math.max(20, height * visibleCount / totalItems);
				scrollThumb.setGraphicSize(_scrollBarWidth, thumbHeight);
				scrollThumb.updateHitbox();
				scrollThumb.setPosition(scrollTrack.x, scrollTrack.y + (height - thumbHeight) * curScroll / maxScroll);
			}
		} else {
			for (item in _items)
				item.active = item.visible = false;

			bg.y = behindText.y - 1;
			bg.scale.y = behindText.height + 2;
			bg.updateHitbox();
			scrollTrack.visible = scrollTrack.active = false;
			scrollThumb.visible = scrollThumb.active = false;
			_scrollDragging = false;
		}
	}

	public var broadcastDropDownEvent:Bool = true;

	function clickedOn(num:Int, label:String) {
		selectedIndex = num;
		showDropDown(false);
		if (PsychUIInputText.focusOn == this)
			PsychUIInputText.focusOn = null;
		if (onSelect != null)
			onSelect(num, label);
		if (broadcastDropDownEvent)
			PsychUIEventHandler.event(CLICK_EVENT, this);
	}

	function addOption(option:String) {
		list.push(option);
		var curID:Int = list.length - 1;
		var item:PsychUIDropDownItem = cast recycle(PsychUIDropDownItem, () -> new PsychUIDropDownItem(1, 1, this._itemWidth), true);
		item.cameras = cameras;
		item.label = option;
		item.parentDropDown = this;
		item.visible = item.active = false;
		item.onClick = function() clickedOn(curID, option);
		item.forceNextUpdate = true;
		_items.push(item);
		insert(1, item);
	}

	function set_list(v:Array<String>) {
		var selected:String = selectedLabel;
		showDropDown(false);

		for (item in _items)
			item.kill();

		_items = [];
		list = [];
		for (option in v)
			addOption(option);

		if (selectedLabel != null)
			selectedLabel = selected;
		return v;
	}
}

class PsychUIDropDownItem extends FlxSpriteGroup {
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
	public var selectedStyle:UIStyleData = {
		bgColor: 0xFFDCEBFF,
		textColor: 0xFF003A75,
		bgAlpha: 1
	};

	public var bg:FlxSprite;
	public var text:FlxText;

	public function new(x:Float = 0, y:Float = 0, width:Float = 100) {
		super(x, y);

		bg = new FlxSprite().makeGraphic(1, 1, FlxColor.WHITE);
		bg.setGraphicSize(width, 20);
		bg.updateHitbox();
		add(bg);

		text = new FlxText(0, 0, width, 8);
		text.color = FlxColor.BLACK;
		add(text);
	}

	public var onClick:Void->Void;
	public var forceNextUpdate:Bool = false;

	override function update(elapsed:Float) {
		super.update(elapsed);
		var touchOver:Bool = false;
		var touchReleased:Bool = false;
		#if FLX_TOUCH
		for (touch in FlxG.touches.list) {
			if (touch != null && touch.overlaps(bg, camera)) {
				touchOver = true;
				if (touch.justReleased)
					touchReleased = true;
			}
		}
		#end

		if (FlxG.mouse.justMoved || FlxG.mouse.justPressed || touchOver || touchReleased || forceNextUpdate) {
			var overlapped:Bool = FlxG.mouse.overlaps(bg, camera) || touchOver;

			var selected:Bool = parentDropDown != null && parentDropDown.selectedLabel == label;
			var style = overlapped ? hoverStyle : (selected ? selectedStyle : normalStyle);
			bg.color = style.bgColor;
			text.color = style.textColor;
			bg.alpha = style.bgAlpha;
			forceNextUpdate = false;

			#if FLX_TOUCH
			if (touchReleased) {
				if (parentDropDown == null || !parentDropDown.suppressTouchSelection())
					onClick();
			} else if (!touchOver && overlapped && FlxG.mouse.justPressed)
				onClick();
			#else
			if (overlapped && FlxG.mouse.justPressed)
				onClick();
			#end
		}

		text.x = bg.x;
		text.y = bg.y + bg.height / 2 - text.height / 2;
	}

	public var label(default, set):String;

	function set_label(v:String) {
		label = v;
		text.text = v;
		var itemHeight:Float = text.height + 6;
		#if mobile
		// A 14-ish pixel row is fine for a mouse and miserable for a finger.
		itemHeight = Math.max(30, itemHeight);
		#end
		bg.scale.y = itemHeight;
		bg.updateHitbox();
		return v;
	}
}
