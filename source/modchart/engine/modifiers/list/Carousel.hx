package modchart.engine.modifiers.list;

class Carousel extends Modifier {
	var carouselID:Int;
	var carouselSpeedID:Int;
	var carouselStartID:Int;
	var carouselEndID:Int;

	public function new(pf) {
		super(pf);

		carouselID = findID('carousel');
		carouselSpeedID = findID('carouselspeed');
		carouselStartID = findID('carouselstart');
		carouselEndID = findID('carouselend');

		setPercent('carouselstart', Math.NaN, -1);
		setPercent('carouselend', Math.NaN, -1);
	}

	override public function render(curPos:Vector3, params:ModifierParameters) {
		final player = params.player;
		final carouselVal = getUnsafe(carouselID, player);

		if (carouselVal == 0)
			return curPos;

		var speed = getUnsafe(carouselSpeedID, player);
		if (speed == 0)
			speed = 1.0;

		// Shared horizontal carousel with screen wrapping.
		// We move every lane by the same X offset, but we keep each lane's current base position,
		// so any spacing made with transform mods stays intact.
		final timeMultiplier = params.songTime * 0.001 * Math.abs(speed);
		final carouselSpeed = timeMultiplier * ARROW_SIZE * Math.abs(carouselVal);
		final carouselOffset = carouselVal > 0 ? carouselSpeed : -carouselSpeed;
		final spacing = ARROW_SIZE * 2;
		var wrapStart = getUnsafe(carouselStartID, player);
		var wrapEnd = getUnsafe(carouselEndID, player);

		if (Math.isNaN(wrapStart))
			wrapStart = -spacing;
		if (Math.isNaN(wrapEnd))
			wrapEnd = WIDTH + spacing;
		if (wrapEnd <= wrapStart)
			wrapEnd = wrapStart + 1;

		final wrapWidth = wrapEnd - wrapStart;
		var newX = curPos.x + carouselOffset;

		while (newX < wrapStart)
			newX += wrapWidth;
		while (newX > wrapEnd)
			newX -= wrapWidth;

		curPos.x = newX;

		return curPos;
	}

	override public function shouldRun(params:ModifierParameters):Bool
		return true;
}
