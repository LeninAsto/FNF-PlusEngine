package objects;

import backend.Controls;
import backend.InputFormatter;
import backend.CoolUtil;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import openfl.display.BitmapData;
import openfl.display.Shape;

using StringTools;

class KeyViewer extends FlxSpriteGroup
{
	public static var instance:KeyViewer;
	
	public var keys:Array<KeyButton> = [];
	public var keyTexts:Array<FlxText> = [];
	public var keyTextLabels:Array<String> = [];
	public var keyCount:Int = 4;
	
	public var pressureBars:Array<PressureBar> = [];
	public var flyingBars:Array<PressureBar> = [];
	
	public var kpsText:FlxText;
	public var totalText:FlxText;
	
	public var hitArray:Array<Date> = [];
	public var kps:Int = 0;
	public var total:Int = 0;
	
	// Referencia a PlayState para acceder a cpuControlled
	private var playState:Dynamic = null;
	
	public function new(x:Float = 50, y:Float = 50, ?playStateRef:Dynamic = null)
	{
		super(x, y);
		instance = this;
		
		keyCount = 4;
		playState = playStateRef;
		
		createKeyViewer();
		centerOnScreen();
		alpha = 0.6;
	}
	
	function createKeyViewer()
	{
		var keySize:Float = 45;
		var spacing:Float = 6;
		var totalWidth:Float = (keySize + spacing) * keyCount - spacing;
		
		// Crear botones de teclas y texto primero
		for (i in 0...keyCount)
		{
			var keyButton = new KeyButton(i * (keySize + spacing), 0, keySize, i);
			keys.push(keyButton);
			add(keyButton);
			
			var keyName:String = getKeyName(i);
			var keyText = new FlxText(keyButton.x, keyButton.y, keySize, keyName, 11); 
			var textColor = FlxColor.WHITE;
			keyText.setFormat(Paths.font("vcr.ttf"), 11, textColor, CENTER);
			alignKeyText(keyText, keyButton, keySize);
			keyText.alpha = 0.6; 
			keyTexts.push(keyText);
			keyTextLabels.push(keyName);
			add(keyText);
		}
		
		for (i in 0...keyCount)
		{
			var pressureBar = new PressureBar(i * (keySize + spacing), 0 - 10, keySize, i);
			pressureBars.push(pressureBar);
			add(pressureBar);
		}
		
		kpsText = new FlxText(0, keySize + 10, totalWidth, "KPS: 0", 14);
		kpsText.setFormat(Paths.font("vcr.ttf"), 14, FlxColor.WHITE, CENTER);
		kpsText.alpha = 0.8;
		add(kpsText);
		
		totalText = new FlxText(0, keySize + 28, totalWidth, "Total: " + total, 14);
		totalText.setFormat(Paths.font("vcr.ttf"), 14, FlxColor.WHITE, CENTER);
		totalText.alpha = 0.8;
		add(totalText);
	}
	
	function getKeyName(keyIndex:Int):String
	{
		var keysArray = ['note_left', 'note_down', 'note_up', 'note_right'];
		
		if (keyIndex < keysArray.length) {
			var keyBind = Controls.instance.getKeyboardBind(keysArray[keyIndex]);
			if (keyBind != null && keyBind.length > 0) {
				var names:Array<String> = [];
				for (boundKey in keyBind) {
					var name = InputFormatter.getKeyName(boundKey);
					if (name != null && name.length > 0 && !names.contains(name))
						names.push(name);
					if (names.length >= 2)
						break;
				}

				if (names.length > 1)
					return names.join("\n");
				if (names.length == 1)
					return names[0];
			}
		}
		
		return "?";
	}
	
	public function keyPressed(keyIndex:Int)
	{
		if (keyIndex >= 0 && keyIndex < keys.length)
		{
			keys[keyIndex].press();
			var keyColor = CoolUtil.colorFromString(ClientPrefs.data.keyViewerColor);
			keyTexts[keyIndex].color = keyColor;
			keyTexts[keyIndex].alpha = 1.0;
			
			pressureBars[keyIndex].startGrowing();
			
			hitArray.unshift(Date.now());
			total++;
			updateTexts();
		}
	}
	
	public function keyReleased(keyIndex:Int)
	{
		if (keyIndex >= 0 && keyIndex < keys.length)
		{
			keys[keyIndex].release();
			keyTexts[keyIndex].color = FlxColor.WHITE;
			keyTexts[keyIndex].alpha = 0.6;
			
			var currentBar = pressureBars[keyIndex];
			if (currentBar.height > 10) {
				currentBar.startFlying();
				flyingBars.push(currentBar);
				
				var keySize:Float = 45;
				var spacing:Float = 6;
				var keyButton = keys[keyIndex];
				var newBar = new PressureBar(keyIndex * (keySize + spacing), keyButton.y - 10, keySize, keyIndex);
				pressureBars[keyIndex] = newBar;
				add(newBar);
			} else {
				currentBar.isGrowing = false;
				currentBar.alpha = 0;
				currentBar.visible = false;
			}
		}
	}
	
	override function update(elapsed:Float)
	{
		super.update(elapsed);
		refreshKeyLabels();
		
		var i = flyingBars.length - 1;
		while (i >= 0)
		{
			var bar = flyingBars[i];
			if (bar != null && bar.isDestroyed) {
				flyingBars.splice(i, 1);
				remove(bar, true);
			}
			i--;
		}
		
		var j = hitArray.length - 1;
		while (j >= 0)
		{
			var time:Date = hitArray[j];
			if (time != null && time.getTime() + 1000 < Date.now().getTime())
				hitArray.remove(time);
			else
				j = -1;
			j--;
		}
		
		var newKps = hitArray.length;
		if (kps != newKps) {
			kps = newKps;
			updateTexts();
		}
	}

	inline function alignKeyText(keyText:FlxText, keyButton:KeyButton, keySize:Float):Void
	{
		keyText.x = keyButton.x;
		keyText.y = keyButton.y + (keySize - keyText.height) / 2;
	}

	function refreshKeyLabels():Void
	{
		final keySize:Float = 45;

		for (i in 0...keyTexts.length)
		{
			final newLabel = getKeyName(i);
			if (keyTextLabels[i] == newLabel)
				continue;

			keyTextLabels[i] = newLabel;
			animateKeyLabelChange(i, newLabel, keySize);
		}
	}

	function animateKeyLabelChange(keyIndex:Int, newLabel:String, keySize:Float):Void
	{
		if (keyIndex < 0 || keyIndex >= keyTexts.length)
			return;

		final keyText = keyTexts[keyIndex];
		final keyButton = keys[keyIndex];
		final pressed = keyButton.isPressed;
		final targetAlpha = pressed ? 1.0 : 0.6;
		final targetColor = pressed ? CoolUtil.colorFromString(ClientPrefs.data.keyViewerColor) : FlxColor.WHITE;

		FlxTween.cancelTweensOf(keyText);
		FlxTween.cancelTweensOf(keyText.scale);

		keyText.text = newLabel;
		keyText.color = targetColor;
		keyText.alpha = 0.2;
		keyText.scale.set(1.25, 1.25);
		alignKeyText(keyText, keyButton, keySize);

		FlxTween.tween(keyText, {alpha: targetAlpha}, 0.14, {ease: FlxEase.quadOut});
		FlxTween.tween(keyText.scale, {x: 1.0, y: 1.0}, 0.18, {
			ease: FlxEase.backOut,
			onUpdate: function(_)
			{
				alignKeyText(keyText, keyButton, keySize);
			}
		});
	}
	
	function updateTexts()
	{
		if (kpsText != null) {
			kpsText.text = "KPS: " + kps;
		}
		if (totalText != null) {
			totalText.text = "Total: " + total;
		}
	}
	
	function getTextColorForBackground(colorName:String):FlxColor
	{
		switch(colorName.toLowerCase())
		{
			case 'white', 'cyan', 'pink', 'orange': 
				return FlxColor.BLACK;
			default: 
				return FlxColor.WHITE;
		}
	}
	
	public function updateKeyColors()
	{
		for (key in keys) {
			if (key.isPressed) {
				var keyColor = CoolUtil.colorFromString(ClientPrefs.data.keyViewerColor);
				key.color = keyColor;
			} else {
				key.color = FlxColor.WHITE; 
			}
		}
		
		for (i in 0...keyTexts.length) {
			if (keys[i].isPressed) {
				var keyColor = CoolUtil.colorFromString(ClientPrefs.data.keyViewerColor);
				keyTexts[i].color = keyColor;
				keyTexts[i].alpha = 1.0;
			} else {
				keyTexts[i].color = FlxColor.WHITE; 
				keyTexts[i].alpha = 0.6; 
			}
		}
	}
	
	public function centerOnScreen()
	{
		var keySize:Float = 45;
		var spacing:Float = 6;
		var totalWidth = (keySize + spacing) * 4 - spacing;
		
		x = (FlxG.width - totalWidth) / 2 + ClientPrefs.data.keyViewerOffset[0];
		y = FlxG.height - 150 + ClientPrefs.data.keyViewerOffset[1];
	}
	
	override function destroy()
	{
		for (bar in flyingBars) {
			if (bar != null) {
				remove(bar, true);
			}
		}
		flyingBars = [];
		
		for (bar in pressureBars) {
			if (bar != null) {
				remove(bar, true);
			}
		}
		pressureBars = [];
		
		super.destroy();
	}
}

class KeyButton extends FlxSprite
{
	public var keyIndex:Int;
	public var isPressed:Bool = false;
	private var originalAlpha:Float = 0.6;
	private var pressTween:FlxTween;
	private var releaseTween:FlxTween;
	
	public function new(x:Float, y:Float, size:Float, keyIndex:Int)
	{
		super(x, y);
		this.keyIndex = keyIndex;
		
		if (Paths.fileExists('images/ui/others/key.png', IMAGE)) {
			loadGraphic(Paths.image('ui/others/key'));
			setGraphicSize(Std.int(size), Std.int(size));
			updateHitbox();
		} else {
			var shape:Shape = new Shape();
			shape.graphics.lineStyle(2, FlxColor.WHITE, 0.8);
			shape.graphics.drawRoundRect(0, 0, size, size, size/6, size/6);
			shape.graphics.lineStyle();
			shape.graphics.beginFill(FlxColor.WHITE, 0.3);
			shape.graphics.drawRoundRect(0, 0, size, size, size/6, size/6);
			shape.graphics.endFill();
			
			var bitmapData:BitmapData = new BitmapData(Std.int(size), Std.int(size), true, 0x00FFFFFF);
			bitmapData.draw(shape);
			loadGraphic(bitmapData);
		}
		
		color = FlxColor.WHITE;
		alpha = originalAlpha;
	}
	
	public function press()
	{
		isPressed = true;
		var keyColor = CoolUtil.colorFromString(ClientPrefs.data.keyViewerColor);
		color = keyColor;
		alpha = 1.0;
		
		if (releaseTween != null) {
			releaseTween.cancel();
			releaseTween = null;
		}
		
		pressTween = FlxTween.tween(scale, {x: 0.85, y: 0.85}, 0.08, {
			ease: FlxEase.quadOut
		});
	}
	
	public function release()
	{
		isPressed = false;
		color = FlxColor.WHITE;
		alpha = originalAlpha;
		
		if (pressTween != null) {
			pressTween.cancel();
			pressTween = null;
		}
		
		releaseTween = FlxTween.tween(scale, {x: 1.0, y: 1.0}, 0.12, {
			ease: FlxEase.elasticOut
		});
	}
	
	override function destroy()
	{
		if (pressTween != null) {
			pressTween.cancel();
			pressTween = null;
		}
		if (releaseTween != null) {
			releaseTween.cancel();
			releaseTween = null;
		}
		super.destroy();
	}
}

class PressureBar extends FlxSprite
{
	public var keyIndex:Int;
	public var isGrowing:Bool = false;
	public var isDestroyed:Bool = false;
	private var maxHeight:Float = 500;
	private var growSpeed:Float = 150;
	private var flyTween:FlxTween;
	private var releaseTween:FlxTween;
	private var fadeTween:FlxTween;
	public var baseWidth:Float; 
	public var baseY:Float; 
	
	public function new(x:Float, y:Float, width:Float, keyIndex:Int)
	{
		super(x, y);
		this.keyIndex = keyIndex;
		this.baseWidth = width;
		this.baseY = y;
		
		var keyColor = CoolUtil.colorFromString(ClientPrefs.data.keyViewerColor);
		makeGraphic(Std.int(width), 1, keyColor);
		
		alpha = 0;
		visible = false;
	}
	
	public function startGrowing()
	{
		isGrowing = true;
		visible = true;
		alpha = 0.8;
		var keyColor = CoolUtil.colorFromString(ClientPrefs.data.keyViewerColor);
		makeGraphic(Std.int(baseWidth), 10, keyColor);
		y = baseY - height;
	}
	
	override function update(elapsed:Float)
	{
		super.update(elapsed);
		
		if (isGrowing && !isDestroyed)
		{
			var newHeight = height + (growSpeed * elapsed);
			if (newHeight > maxHeight) newHeight = maxHeight;
			
			var keyColor = CoolUtil.colorFromString(ClientPrefs.data.keyViewerColor);
			makeGraphic(Std.int(baseWidth), Std.int(newHeight), keyColor);
			
			y = baseY - height;
		}
	}
	
	public function startFlying()
	{
		isGrowing = false;
		
		var currentY = y;
		flyTween = FlxTween.tween(this, {y: currentY - 100}, 1.0, {
			ease: FlxEase.quadOut,
			onComplete: function(tween:FlxTween) {
				isDestroyed = true;
			}
		});
		
		fadeTween = FlxTween.tween(this, {alpha: 0}, 1.0, {
			ease: FlxEase.quadOut
		});
	}
	

	
	override function destroy()
	{
		if (flyTween != null) {
			flyTween.cancel();
			flyTween = null;
		}
		if (fadeTween != null) {
			fadeTween.cancel();
			fadeTween = null;
		}
		super.destroy();
	}
}