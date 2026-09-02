package flxanimate;

import flixel.util.FlxDestroyUtil;
import flixel.system.FlxAssets.FlxGraphicAsset;
import flxanimate.frames.FlxAnimateFrames;
import flxanimate.data.AnimationData;
import flxanimate.FlxAnimate as OriginalFlxAnimate;
import flxanimate.animate.FlxSymbolDictionary;

class PsychFlxAnimate extends OriginalFlxAnimate
{
	public function loadAtlasEx(img:FlxGraphicAsset, pathOrStr:String = null, myJson:Dynamic = null)
	{
		var animJson:AnimAtlas = null;
		if (myJson is String)
		{
			var trimmed:String = pathOrStr.trim();
			trimmed = trimmed.substr(trimmed.length - 5).toLowerCase();

			if (trimmed == '.json')
				myJson = File.getContent(myJson); // is a path
			animJson = cast haxe.Json.parse(_removeBOM(myJson));
		}
		else
			animJson = cast myJson;

		var isXml:Null<Bool> = null;
		var myData:Dynamic = pathOrStr;

		var trimmed:String = pathOrStr.trim();
		trimmed = trimmed.substr(trimmed.length - 5).toLowerCase();

		if (trimmed == '.json') // Path is json
		{
			myData = File.getContent(pathOrStr);
			isXml = false;
		}
		else if (trimmed.substr(1) == '.xml') // Path is xml
		{
			myData = File.getContent(pathOrStr);
			isXml = true;
		}
		myData = _removeBOM(myData);

		// Automatic if everything else fails
		switch (isXml)
		{
			case true:
				myData = Xml.parse(myData);
			case false:
				myData = haxe.Json.parse(myData);
			case null:
				try
				{
					myData = haxe.Json.parse(myData);
					isXml = false;
					// trace('JSON parsed successfully!');
				}
				catch (e)
				{
					myData = Xml.parse(myData);
					isXml = true;
					// trace('XML parsed successfully!');
				}
		}

		anim._loadAtlas(animJson);
		if (!isXml)
			frames = FlxAnimateFrames.fromSpriteMap(cast myData, img);
		else
			frames = FlxAnimateFrames.fromSparrow(cast myData, img);
		origin = anim.curInstance.symbol.transformationPoint;
	}

	public function addAtlasLibrary(animationJson:String)
	{
		if (animationJson == null || anim == null || anim.library == null)
			return;

		var animJson:AnimAtlas = cast haxe.Json.parse(_removeBOM(animationJson));
		var library:FlxSymbolDictionary = new FlxSymbolDictionary();
		@:privateAccess
		library._parent = anim;

		if (animJson.MD != null && animJson.MD.V != null)
			library.fromJSONEx(animJson);
		else
			library.fromJSON(animJson);

		anim.library.addLibrary(library.getList(), true);
		anim.symbolDictionary = anim.library.getList();
		anim.library.frames = frames;
	}

	public function addByFrameLabelIndices(name:String, frameLabel:String, indices:Array<Int>, frameRate:Float = 0, looped:Bool = true)
	{
		if (anim == null || anim.stageInstance == null || anim.stageInstance.symbol == null)
			return;

		var label = anim.getFrameLabel(frameLabel);
		if (label == null)
		{
			anim.addBySymbolIndices(name, frameLabel, indices, frameRate, looped);
			return;
		}

		var labelIndices:Array<Int> = label.getFrameIndices();
		var mappedIndices:Array<Int> = [];
		for (index in indices)
			if (index >= 0 && index < labelIndices.length)
				mappedIndices.push(labelIndices[index]);

		anim.addBySymbolIndices(name, anim.stageInstance.symbol.name, mappedIndices.length > 0 ? mappedIndices : labelIndices, frameRate, looped);
	}

	public function addByFrameLabel(name:String, frameLabel:String, frameRate:Float = 0, looped:Bool = true)
	{
		if (anim == null || anim.stageInstance == null || anim.stageInstance.symbol == null)
			return;

		if (anim.getFrameLabel(frameLabel) != null)
			anim.addByFrameLabel(name, frameLabel, frameRate, looped);
		else
			anim.addBySymbol(name, frameLabel, frameRate, looped);
	}

	override function draw()
	{
		if (anim.curInstance == null || anim.curSymbol == null)
			return;
		super.draw();
	}

	override function destroy()
	{
		try
		{
			super.destroy();
		}
		catch (e:haxe.Exception)
		{
			anim.curInstance = FlxDestroyUtil.destroy(anim.curInstance);
			anim.stageInstance = FlxDestroyUtil.destroy(anim.stageInstance);
			// anim.metadata = FlxDestroyUtil.destroy(anim.metadata);
			anim.metadata.destroy();
			anim.symbolDictionary = null;
		}
	}

	function _removeBOM(str:String) // Removes BOM byte order indicator
	{
		if (str.charCodeAt(0) == 0xFEFF)
			str = str.substr(1); // myData = myData.substr(2);
		return str;
	}

	public function pauseAnimation()
	{
		if (anim.curInstance == null || anim.curSymbol == null)
			return;
		anim.pause();
	}

	public function resumeAnimation()
	{
		if (anim.curInstance == null || anim.curSymbol == null)
			return;
		anim.play();
	}
}

