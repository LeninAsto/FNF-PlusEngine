package modchart.backend.core;

@:publicFields
@:structInit
final class Node {
	public var input:Array<String> = [];
	public var output:Array<String> = [];
	public var func:NodeFunction = (_, o) -> _;
}

typedef NodeFunction = (Array<Float>, Int) -> Array<Float>;
