package backend.ui;

import backend.ui.PsychUIBox.UIStyleData;
#if mobile
import flixel.FlxSubState;
#end
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

	public var selectedIndex(default, set):Int = -1;
	public var selectedLabel(default, set):String = null;

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
	var _touchPressedItem:PsychUIDropDownItem;
	static inline var TOUCH_DRAG_DEADZONE:Float = 8;
	#end

	public function new(x:Float, y:Float, list:Array<String>, callback:Int->String->Void, ?width:Float = 100, ?maxVisibleItems:Int = 0) {
		super(x, y);
		showSoftKeyboardOnFocus = false;
		if (list == null)
			list = [];

		_itemWidth = width - 2;
		_maxVisibleItems = maxVisibleItems;
		#if mobile
		_scrollBarWidth = 14;
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
		selectedIndex = v;
		if (selectedIndex < 0 || selectedIndex >= list.length)
			selectedIndex = -1;

		@:bypassAccessor selectedLabel = list[selectedIndex];
		text = (selectedLabel != null) ? selectedLabel : '';
		return selectedIndex;
	}

	function set_selectedLabel(v:String) {
		var id:Int = list.indexOf(v);
		if (id >= 0) {
			@:bypassAccessor selectedIndex = id;
			selectedLabel = v;
			text = selectedLabel;
		} else {
			@:bypassAccessor selectedIndex = -1;
			selectedLabel = null;
			text = '';
		}
		return selectedLabel;
	}

	var _items:Array<PsychUIDropDownItem> = [];

	public var curScroll:Int = 0;

	override function update(elapsed:Float) {
		#if mobile
		updateMobileSelector(elapsed);
		return;
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
		handleTouchInput(lastFocus);
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
		}
	}

	#if mobile
	/**
	 * Android does not use the desktop fly-out list.  It opens a real modal
	 * selector instead, so the state behind it cannot consume a swipe or tap.
	 */
	function updateMobileSelector(elapsed:Float):Void {
		super.update(elapsed);
		showDropDown(false);
		if (MobileDropDownSelector.current != null)
			return;

		for (touch in FlxG.touches.list) {
			if (touch == null || !touch.justPressed)
				continue;
			if (!touch.overlaps(behindText, camera) && !touch.overlaps(button, camera))
				continue;

			PsychUIInputText.focusOn = null;
			button.animation.play('pressed', true);
			var options:Array<String> = list.copy();
			var selector = new MobileDropDownSelector(options, selectedIndex, camera, function(index:Int) {
				if (index >= 0 && index < list.length)
					clickedOn(index, list[index]);
			});
			var targetState:flixel.FlxState = FlxG.state;
			while (targetState.subState != null)
				targetState = targetState.subState;
			targetState.openSubState(selector);
			return;
		}
	}
	#end

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

	#if FLX_TOUCH
	function findTouchByID(id:Int):FlxTouch {
		for (touch in FlxG.touches.list)
			if (touch != null && touch.touchPointID == id)
				return touch;
		return null;
	}

	function getTouchItem(touch:FlxTouch):PsychUIDropDownItem {
		for (item in _items)
			if (item != null && item.visible && item.active && touch.overlaps(item.bg, camera))
				return item;
		return null;
	}

	/**
	 * Mobile owns a touch from press to release.  Letting individual list rows
	 * react to the release used to race the swipe code because FlxSpriteGroup
	 * updates children before this dropdown.  A short gesture picks a row;
	 * a vertical gesture scrolls it instead.
	 */
	function handleTouchInput(lastFocus:PsychUIInputText):Void {
		if (_touchDragID >= 0) {
			var activeTouch:FlxTouch = findTouchByID(_touchDragID);
			if (activeTouch == null) {
				clearTouchGesture();
				return;
			}

			var currentY:Float = activeTouch.getWorldPosition(camera, _pointerPosition).y;
			var deltaY:Float = currentY - _touchDragStartY;
			if (activeTouch.pressed && Math.abs(deltaY) >= TOUCH_DRAG_DEADZONE) {
				_touchDragMoved = true;
				var rowHeight:Float = _touchPressedItem != null ? _touchPressedItem.height : 20;
				showDropDown(true, _touchDragStartScroll - Math.round(deltaY / Math.max(1, rowHeight)), _curFilter);
			}

			if (activeTouch.justReleased) {
				var picked:PsychUIDropDownItem = _touchPressedItem;
				var shouldPick:Bool = !_touchDragMoved && picked != null && picked.visible && activeTouch.overlaps(picked.bg, camera);
				clearTouchGesture();
				if (shouldPick && picked.onClick != null)
					picked.onClick();
			} else if (!activeTouch.pressed)
				clearTouchGesture();
			return;
		}

		for (touch in FlxG.touches.list) {
			if (touch == null || !touch.justPressed)
				continue;

			// Tapping the field or arrow is a predictable open/close toggle.
			if (touch.overlaps(behindText, camera) || touch.overlaps(button, camera)) {
				button.animation.play('pressed', true);
				PsychUIInputText.focusOn = lastFocus == this ? null : this;
				return;
			}

			if (lastFocus != this)
				continue;

			var item:PsychUIDropDownItem = getTouchItem(touch);
			if (item != null || (scrollTrack.visible && touch.overlaps(scrollTrack, camera))) {
				_touchDragID = touch.touchPointID;
				_touchDragStartY = touch.getWorldPosition(camera, _pointerPosition).y;
				_touchDragStartScroll = curScroll;
				_touchDragMoved = false;
				_touchPressedItem = item;
				if (item == null)
					updateScrollFromY(_touchDragStartY);
				return;
			}

			// A tap outside is an explicit cancel, so an editor cannot be left trapped.
			PsychUIInputText.focusOn = null;
			return;
		}
	}

	function clearTouchGesture():Void {
		_touchDragID = -1;
		_touchDragMoved = false;
		_touchPressedItem = null;
	}

	public inline function suppressTouchSelection():Bool
		return _touchDragMoved;
	#end

	inline function getVisibleCount(total:Int):Int {
		return _maxVisibleItems > 0 ? Std.int(Math.min(_maxVisibleItems, total)) : total;
	}

	/** Keeps the popover on screen on phones while leaving desktop layout unchanged. */
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

	function getRowHeight():Float {
		for (item in _items)
			if (item != null && item.height > 0)
				return item.height;
		return 20;
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
			clearTouchGesture();
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
		@:bypassAccessor list.push(option);
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
		#if FLX_TOUCH
		var touchIsActive:Bool = false;
		for (touch in FlxG.touches.list) {
			if (touch != null && (touch.pressed || touch.justPressed || touch.justReleased)) {
				touchIsActive = true;
				break;
			}
		}
		#end

		if (FlxG.mouse.justMoved || FlxG.mouse.justPressed || forceNextUpdate) {
			var overlapped:Bool = FlxG.mouse.overlaps(bg, camera);

			var style = overlapped ? hoverStyle : normalStyle;
			bg.color = style.bgColor;
			text.color = style.textColor;
			bg.alpha = style.bgAlpha;
			forceNextUpdate = false;

			if (overlapped && FlxG.mouse.justPressed #if FLX_TOUCH && !touchIsActive #end)
				onClick();
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
		itemHeight = Math.max(24, itemHeight);
		#end
		bg.scale.y = itemHeight;
		bg.updateHitbox();
		return v;
	}
}

#if mobile
/** Full-screen, touch-only chooser used by PsychUIDropDownMenu on Android. */
private class MobileDropDownSelector extends FlxSubState {
	public static var current:MobileDropDownSelector;

	var options:Array<String>;
	var onPick:Int->Void;
	var uiCamera:FlxCamera;
	var panel:FlxSprite;
	var title:FlxText;
	var hint:FlxText;
	var rows:Array<FlxSprite> = [];
	var labels:Array<FlxText> = [];
	var scrollTrack:FlxSprite;
	var scrollThumb:FlxSprite;
	var rowHeight:Float = 32;
	var firstVisible:Int = 0;
	var selected:Int;
	var visibleRows:Int = 1;
	var touchID:Int = -1;
	var touchStartY:Float = 0;
	var touchStartScroll:Int = 0;
	var touchCandidate:Int = -1;
	var didDrag:Bool = false;
	var pointer:FlxPoint = new FlxPoint();
	static inline var DRAG_DEADZONE:Float = 8;

	public function new(options:Array<String>, selected:Int, uiCamera:FlxCamera, onPick:Int->Void) {
		super(0xA6000000);
		current = this;
		this.options = options == null ? [] : options;
		this.selected = selected;
		this.onPick = onPick;
		this.uiCamera = uiCamera != null ? uiCamera : FlxG.camera;

		var panelWidth:Float = Math.min(560, FlxG.width - 32);
		rowHeight = Math.max(28, Math.min(38, Math.floor(FlxG.height / 17)));
		visibleRows = Std.int(Math.max(1, Math.min(8, Math.min(this.options.length, Math.floor((FlxG.height - 126) / rowHeight)))));
		var panelHeight:Float = 72 + visibleRows * rowHeight + 18;
		var panelX:Float = (FlxG.width - panelWidth) / 2;
		var panelY:Float = (FlxG.height - panelHeight) / 2;

		panel = new FlxSprite(panelX, panelY).makeGraphic(Std.int(panelWidth), Std.int(panelHeight), 0xFF20242C);
		panel.cameras = [uiCamera];
		panel.scrollFactor.set();
		add(panel);

		title = new FlxText(panelX + 16, panelY + 12, panelWidth - 32, 'Select an option', 16);
		title.setFormat(Paths.font('vcr.ttf'), 16, FlxColor.WHITE, CENTER);
		title.cameras = [uiCamera];
		title.scrollFactor.set();
		add(title);

		hint = new FlxText(panelX + 16, panelY + 36, panelWidth - 32, 'Tap to select  •  Swipe to scroll  •  Tap outside to cancel', 8);
		hint.setFormat(Paths.font('vcr.ttf'), 8, 0xFFB9C4D1, CENTER);
		hint.cameras = [uiCamera];
		hint.scrollFactor.set();
		add(hint);

		var listWidth:Int = Std.int(panelWidth - 44);
		for (i in 0...visibleRows) {
			var row = new FlxSprite().makeGraphic(listWidth, Std.int(rowHeight - 2), FlxColor.WHITE);
			row.cameras = [uiCamera];
			row.scrollFactor.set();
			add(row);
			rows.push(row);

			var label = new FlxText(0, 0, listWidth - 14, '', 11);
			label.setFormat(Paths.font('vcr.ttf'), 11, FlxColor.BLACK, LEFT);
			label.cameras = [uiCamera];
			label.scrollFactor.set();
			add(label);
			labels.push(label);
		}

		scrollTrack = new FlxSprite().makeGraphic(12, Std.int(visibleRows * rowHeight - 2), 0xFF11151C);
		scrollTrack.cameras = [uiCamera];
		scrollTrack.scrollFactor.set();
		add(scrollTrack);
		scrollThumb = new FlxSprite().makeGraphic(12, 20, 0xFF7CC7FF);
		scrollThumb.cameras = [uiCamera];
		scrollThumb.scrollFactor.set();
		add(scrollThumb);

		layout();
	}

	override function update(elapsed:Float):Void {
		super.update(elapsed);
		if (FlxG.keys.justPressed.ESCAPE) {
			close();
			return;
		}

		if (touchID >= 0) {
			var touch = findTouch(touchID);
			if (touch == null) {
				clearGesture();
				return;
			}
			var deltaY:Float = touch.getScreenPosition(pointer).y - touchStartY;
			if (touch.pressed && Math.abs(deltaY) >= DRAG_DEADZONE) {
				didDrag = true;
				firstVisible = boundScroll(touchStartScroll - Math.round(deltaY / rowHeight));
				layout();
			}
			if (touch.justReleased) {
				var pick:Int = touchCandidate;
				var canPick:Bool = !didDrag && pick >= 0 && pick < options.length && rowAtTouch(touch) == pick;
				clearGesture();
				if (canPick)
					choose(pick);
			} else if (!touch.pressed)
				clearGesture();
			return;
		}

		for (touch in FlxG.touches.list) {
			if (touch == null || !touch.justPressed)
				continue;
			var pickedRow = rowAtTouch(touch);
			if (pickedRow >= 0 || touch.overlaps(scrollTrack, uiCamera)) {
				touchID = touch.touchPointID;
				touchStartY = touch.getScreenPosition(pointer).y;
				touchStartScroll = firstVisible;
				touchCandidate = pickedRow;
				didDrag = false;
				if (pickedRow < 0)
					setScrollFromTouch(touch);
				return;
			}
			close();
			return;
		}
	}

	function layout():Void {
		var rowX:Float = panel.x + 16;
		var rowY:Float = panel.y + 60;
		for (slot in 0...visibleRows) {
			var index = firstVisible + slot;
			var visible = index < options.length;
			var row = rows[slot];
			var label = labels[slot];
			row.visible = label.visible = visible;
			if (!visible)
				continue;
			row.setPosition(rowX, rowY + slot * rowHeight);
			row.color = index == selected ? 0xFF9FD5FF : (slot % 2 == 0 ? 0xFFF4F6F8 : 0xFFE2E7EC);
			label.text = (index == selected ? '✓  ' : '   ') + options[index];
			label.color = index == selected ? 0xFF003B69 : FlxColor.BLACK;
			label.setPosition(row.x + 6, row.y + (row.height - label.height) / 2);
		}

		var listHeight:Float = visibleRows * rowHeight - 2;
		scrollTrack.setPosition(panel.x + panel.width - 28, rowY);
		scrollTrack.setGraphicSize(12, Std.int(listHeight));
		scrollTrack.updateHitbox();
		var maxScroll = maxScroll();
		var thumbHeight:Float = maxScroll <= 0 ? listHeight : Math.max(24, listHeight * visibleRows / options.length);
		scrollThumb.visible = scrollTrack.visible = maxScroll > 0;
		scrollThumb.setGraphicSize(12, Std.int(thumbHeight));
		scrollThumb.updateHitbox();
		if (maxScroll > 0)
			scrollThumb.setPosition(scrollTrack.x, scrollTrack.y + (listHeight - thumbHeight) * firstVisible / maxScroll);
	}

	function rowAtTouch(touch:FlxTouch):Int {
		for (slot in 0...rows.length)
			if (rows[slot].visible && touch.overlaps(rows[slot], uiCamera))
				return firstVisible + slot;
		return -1;
	}

	function setScrollFromTouch(touch:FlxTouch):Void {
		var max = maxScroll();
		if (max <= 0)
			return;
		var y:Float = touch.getScreenPosition(pointer).y;
		var travel:Float = scrollTrack.height - scrollThumb.height;
		var ratio:Float = FlxMath.bound((y - scrollTrack.y - scrollThumb.height / 2) / Math.max(1, travel), 0, 1);
		firstVisible = boundScroll(Math.round(ratio * max));
		layout();
	}

	inline function maxScroll():Int return Std.int(Math.max(0, options.length - visibleRows));
	inline function boundScroll(value:Int):Int return Std.int(FlxMath.bound(value, 0, maxScroll()));

	function findTouch(id:Int):FlxTouch {
		for (touch in FlxG.touches.list)
			if (touch != null && touch.touchPointID == id)
				return touch;
		return null;
	}

	function clearGesture():Void {
		touchID = -1;
		touchCandidate = -1;
		didDrag = false;
	}

	function choose(index:Int):Void {
		selected = index;
		if (onPick != null)
			onPick(index);
		close();
	}

	override function destroy():Void {
		if (current == this)
			current = null;
		options = null;
		onPick = null;
		rows = null;
		labels = null;
		pointer = null;
		super.destroy();
	}
}
#end
