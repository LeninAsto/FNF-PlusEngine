/**
	Week 1's tutorial camera: it pushes in on whoever is singing and pulls back out on Boyfriend.

	This lived in `PlayState.moveCamera` as a `songName == 'tutorial'` special case, which meant the
	engine carried one song's camera for every chart ever made. The tween itself is still the engine's
	(`tweenCamZoom`, a beat-long elastic ease that will not fight a tween already running); all that
	moved here is the decision to run it.
**/
function onMoveCamera(focus:String) {
	if (focus == 'boyfriend')
		PlayState.instance.tweenCamZoom(1);
	else
		PlayState.instance.tweenCamZoom(1.3);
}
