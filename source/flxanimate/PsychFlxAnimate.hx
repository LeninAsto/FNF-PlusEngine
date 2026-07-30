package flxanimate;

import animate.FlxAnimate as OriginalFlxAnimate;
import animate.FlxAnimateFrames;

class PsychFlxAnimate extends OriginalFlxAnimate
{
	/**
	 * Carga un atlas de Adobe Animate desde una carpeta.
	 * flixel-animate ya resuelve internamente JSON/spritemaps/metadata,
	 * así que ya no hace falta parsear XML/JSON a mano como en flxanimate.
	 *
	 * @param path Carpeta donde está el Animation.json (no el archivo en sí)
	 */
	public function loadAtlasEx(path:String)
	{
		frames = FlxAnimateFrames.fromAnimate(path);
	}

	public function pauseAnimation()
	{
		anim.paused = true;
	}

	public function resumeAnimation()
	{
		anim.paused = false;
	}
}
