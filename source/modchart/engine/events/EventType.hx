package modchart.engine.events;

enum abstract EventType(String) from String to String {
	public final EMPTY = 'empty';
	public final EASE = 'ease';
	public final ADD = 'add';
	public final SET = 'set';
	public final REPEATER = 'repeater';
}
