package modchart.engine.modifiers.list;

class Carousel extends Modifier {
	var carouselID:Int;
	var carouselSpeedID:Int;

	public function new(pf) {
		super(pf);

		carouselID = findID('carousel');
		carouselSpeedID = findID('carouselspeed');
	}

	override public function render(curPos:Vector3, params:ModifierParameters) {
		var player = params.player;
		var carouselVal = getUnsafe(carouselID, player);
		
		if (carouselVal == 0)
			return curPos;

		var speed = getUnsafe(carouselSpeedID, player);
		if (speed == 0)
			speed = 1.0;

		var keyCount = getKeyCount(player);
		var playerCount = getPlayerCount();
		var totalKeys = keyCount * playerCount;
		var globalLane = (player * keyCount) + params.lane;
		var spacing = ARROW_SIZE * 1.5;
		var totalWidth = totalKeys * spacing;
		var timeMultiplier = params.songTime * 0.001 * Math.abs(speed);
		var carouselSpeed = timeMultiplier * ARROW_SIZE * Math.abs(carouselVal);
		var initialPosition = globalLane * spacing;
		var carouselOffset;

		if (carouselVal > 0) {
			carouselOffset = carouselSpeed;
		} else {
			carouselOffset = -carouselSpeed;
		}
		
		var carouselPosition = initialPosition + carouselOffset;
		
		carouselPosition = carouselPosition % totalWidth;
		if (carouselPosition < 0) {
			carouselPosition += totalWidth;
		}
		
		var screenCenter = WIDTH * 0.5;
		var carouselCenter = totalWidth * 0.5;
		var leftOffset = ARROW_SIZE * 0.5;
		var newX = screenCenter - carouselCenter + carouselPosition - leftOffset;
		var leftBound = -spacing * 2;
		var rightBound = WIDTH + spacing * 2;
		
		while (newX < leftBound) {
			newX += totalWidth;
		}
		while (newX > rightBound) {
			newX -= totalWidth;
		}
		
		var originalX = getReceptorX(params.lane, player);
		curPos.x += (newX - originalX);

		return curPos;
	}

	override public function shouldRun(params:ModifierParameters):Bool
		return true;
}
