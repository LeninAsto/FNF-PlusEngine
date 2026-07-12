package backend.ui;

import backend.ui.PsychUIBox.UIStyleData;
#if mobile
import backend.MusicBeatSubstate;
#end

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
	public function new(x:Float, y:Float, list:Array<String>, callback:Int->String->Void, ?width:Float = 100)
	{
		super(x, y);
		if(list == null) list = [];

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
	}

	function set_selectedIndex(v:Int)
	{
		selectedIndex = v;
		if(selectedIndex < 0 || selectedIndex >= list.length) selectedIndex = -1;

		@:bypassAccessor selectedLabel = list[selectedIndex];
		text = (selectedLabel != null) ? selectedLabel : '';
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
		}
		else
		{
			@:bypassAccessor selectedIndex = -1;
			selectedLabel = null;
			text = '';
		}
		return selectedLabel;
	}

	var _items:Array<PsychUIDropDownItem> = [];
	public var curScroll:Int = 0;
	override function update(elapsed:Float)
	{
		var lastFocus = PsychUIInputText.focusOn;
		super.update(elapsed);

		#if mobile
		if(handleMobileSelectorInput())
			return;
		#end
		
		if(FlxG.mouse.justPressed)
		{
			var mouseOverButton = FlxG.mouse.overlaps(button, camera);
			var mouseOverDropdown = false;

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
			}
			
			if(mouseOverButton || mouseOverDropdown)
			{
				button.animation.play('pressed', true);

				if(mouseOverButton || mouseOverDropdown)
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
				PsychUIInputText.focusOn = null;
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
				showDropDown(true, curScroll - wheel, _curFilter);
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
		}

		curScroll = Std.int(Math.max(0, Math.min(onlyAllowed != null ? (onlyAllowed.length - 1) : (list.length - 1), scroll)));
		if(vis)
		{
			var n:Int = 0;
			for (item in _items)
			{
				if(onlyAllowed != null)
				{
					if(onlyAllowed.contains(item.label))
					{
						item.active = item.visible = (n >= curScroll);
						n++;
					}
					else item.active = item.visible = false;
				}
				else
				{
					item.active = item.visible = (n >= curScroll);
					n++;
				}
			}

			var txtY:Float = behindText.y + behindText.height + 1;
			for (num => item in _items)
			{
				if(!item.visible) continue;
				item.x = behindText.x;
				item.y = txtY;
				txtY += item.height;
				item.forceNextUpdate = true;
			}
			bg.scale.y = txtY - behindText.y + 2;
			bg.updateHitbox();
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

	#if mobile
	function handleMobileSelectorInput():Bool
	{
		if(FlxG.state == null)
			return false;

		if(FlxG.state.subState != null)
			return true;

		var pressedDropdown:Bool = FlxG.mouse.justPressed && (FlxG.mouse.overlaps(button, camera) || FlxG.mouse.overlaps(this, camera));
		if(!pressedDropdown)
		{
			for(touch in FlxG.touches.list)
			{
				if(touch != null && touch.justPressed && (touch.overlaps(button, camera) || touch.overlaps(this, camera)))
				{
					pressedDropdown = true;
					break;
				}
			}
		}

		if(pressedDropdown)
		{
			button.animation.play('pressed', true);
			PsychUIInputText.focusOn = null;
			showDropDown(false);
			openMobileSelector();
			button.animation.play('normal', true);
		}

		return true;
	}

	function openMobileSelector():Void
	{
		if(list == null || list.length < 1 || FlxG.state == null || FlxG.state.subState != null)
			return;

		FlxG.state.openSubState(new PsychUIDropDownMobileSelector(list.copy(), selectedIndex, function(index:Int, label:String)
		{
			clickedOn(index, label);
		}));
	}
	#end

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
		return v;
	}

	override function destroy()
	{
		super.destroy();
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

#if mobile
class PsychUIDropDownMobileSelector extends MusicBeatSubstate
{
	static inline var DROPDOWN_PAGE_SIZE:Int = 7;

	var options:Array<String>;
	var selectedIndex:Int;
	var onPick:Int->String->Void;
	var currentPage:Int = 0;
	var previousPersistentUpdate:Bool = false;
	var panel:FlxSprite;
	var titleText:FlxText;

	public function new(options:Array<String>, selectedIndex:Int, onPick:Int->String->Void)
	{
		this.options = options != null ? options : [];
		this.selectedIndex = selectedIndex;
		this.onPick = onPick;

		if(FlxG.state != null)
		{
			previousPersistentUpdate = FlxG.state.persistentUpdate;
			FlxG.state.persistentUpdate = false;
		}

		super();
	}

	override function create()
	{
		super.create();

		cameras = [FlxG.cameras.list[FlxG.cameras.list.length - 1]];

		var overlay = new FlxSprite().makeGraphic(1, 1, FlxColor.BLACK);
		overlay.scale.set(FlxG.width, FlxG.height);
		overlay.updateHitbox();
		overlay.alpha = 0.75;
		overlay.cameras = cameras;
		add(overlay);

		var panelWidth:Int = Std.int(Math.min(FlxG.width - 40, 620));
		var panelHeight:Int = Std.int(Math.min(FlxG.height - 60, 80 + (DROPDOWN_PAGE_SIZE * 42) + 80));
		panel = new FlxSprite().makeGraphic(1, 1, FlxColor.BLACK);
		panel.alpha = 0.9;
		panel.scale.set(panelWidth, panelHeight);
		panel.updateHitbox();
		panel.screenCenter();
		panel.cameras = cameras;
		add(panel);

		titleText = new FlxText(panel.x + 20, panel.y + 18, panelWidth - 40, 'Choose an option', 20);
		titleText.alignment = CENTER;
		titleText.cameras = cameras;
		add(titleText);

		currentPage = getPageForIndex(selectedIndex);
		refreshPage();
	}

	function refreshPage():Void
	{
		while(members.length > 3)
			remove(members[members.length - 1], true);

		var panelWidth:Int = Std.int(panel.width);
		var startIndex:Int = currentPage * DROPDOWN_PAGE_SIZE;
		var endIndex:Int = Std.int(Math.min(options.length, startIndex + DROPDOWN_PAGE_SIZE));
		var buttonY:Float = titleText.y + titleText.height + 18;

		for(index in startIndex...endIndex)
		{
			var optionIndex:Int = index;
			var label:String = options[optionIndex];
			var optionButton = new PsychUIButton(panel.x + 20, buttonY, label, function()
			{
				if(onPick != null)
					onPick(optionIndex, label);
				close();
			});
			optionButton.resize(panelWidth - 40, 34);
			optionButton.cameras = cameras;

			if(optionIndex == selectedIndex)
			{
				optionButton.normalStyle.bgColor = 0xFF0066FF;
				optionButton.normalStyle.textColor = FlxColor.WHITE;
			}

			add(optionButton);
			buttonY += 38;
		}

		var totalPages:Int = Std.int(Math.max(1, Math.ceil(options.length / DROPDOWN_PAGE_SIZE)));
		if(totalPages > 1)
		{
			var prevButton = new PsychUIButton(panel.x + 20, panel.y + panel.height - 46, '< Prev', function()
			{
				currentPage = Std.int(Math.max(0, currentPage - 1));
				refreshPage();
			});
			prevButton.resize(110, 28);
			prevButton.cameras = cameras;
			prevButton.active = prevButton.visible = currentPage > 0;
			add(prevButton);

			var nextButton = new PsychUIButton(panel.x + panel.width - 130, panel.y + panel.height - 46, 'Next >', function()
			{
				currentPage = Std.int(Math.min(totalPages - 1, currentPage + 1));
				refreshPage();
			});
			nextButton.resize(110, 28);
			nextButton.cameras = cameras;
			nextButton.active = nextButton.visible = currentPage < totalPages - 1;
			add(nextButton);

			var pageText = new FlxText(panel.x, panel.y + panel.height - 44, Std.int(panel.width), 'Page ${currentPage + 1} / $totalPages', 16);
			pageText.alignment = CENTER;
			pageText.cameras = cameras;
			add(pageText);
		}

		var cancelButton = new PsychUIButton(0, panel.y + panel.height - 46, 'Cancel', close);
		cancelButton.resize(110, 28);
		cancelButton.x = panel.x + (panel.width - cancelButton.width) / 2;
		cancelButton.cameras = cameras;
		add(cancelButton);
	}

	inline function getPageForIndex(index:Int):Int
	{
		if(index < 0)
			return 0;
		return Std.int(index / DROPDOWN_PAGE_SIZE);
	}

	override function close()
	{
		if(FlxG.state != null)
			FlxG.state.persistentUpdate = previousPersistentUpdate;
		super.close();
	}
}
#end
