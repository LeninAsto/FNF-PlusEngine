package modchart.engine.events.types;

class SetEvent extends Event {
	public function new(mod:String, beat:Float, target:Float, player:Int, parent:EventManager) {
		this.name = mod;
		this.target = target;
		this.player = player;

		super(beat, (_) -> {
			setModPercent(mod, target, player);
		}, parent);
		type = SET;
	}
}
