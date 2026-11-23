package objects;

import flixel.group.FlxGroup.FlxTypedGroup;

enum abstract StrumLineType(Int) from Int to Int
{
	var OPPONENT = 0;
	var PLAYER = 1;
	var ADDITIONAL = 2;
}

/** Lightweight owner/layout descriptor. Receptors remain drawn by PlayState.strumLineNotes. */
class StrumLine
{
	public var id:String;
	public var index:Int;
	public var type:StrumLineType;
	public var character:String;
	public var receptors:FlxTypedGroup<StrumNote>;
	public var visible:Bool;
	/** Runtime activation. Separate from the chart's visible preference. */
	public var active:Bool = true;
	public var x:Null<Float>;
	public var y:Null<Float>;
	public var scale:Null<Float>;
	public var spacing:Null<Float>;
	public var effectiveScale:Float = 1;
	public var effectiveSpacing:Float = 1;
	public var defaultX:Array<Float> = [];
	public var defaultY:Array<Float> = [];

	public function new(id:String, index:Int, type:StrumLineType, receptors:FlxTypedGroup<StrumNote>, ?character:String = 'none',
		?visible:Bool = true)
	{
		this.id = id;
		this.index = index;
		this.type = type;
		this.receptors = receptors;
		this.character = character == null || character.length == 0 ? 'none' : character.toLowerCase();
		this.visible = visible;
	}

	public inline function receptor(lane:Int):Null<StrumNote>
		return lane >= 0 && lane < receptors.length ? receptors.members[lane] : null;
}
