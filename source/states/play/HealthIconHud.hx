package states.play;

import flixel.math.FlxMath;
import objects.Bar;
import objects.HealthIcon;

class HealthIconHud
{
	public static function scale(elapsed:Float, rate:Float, p1:HealthIcon, p2:HealthIcon, gf:HealthIcon):Void
	{
		switch (ClientPrefs.data.iconBounceType)
		{
			case 'Old':
				oldScale(elapsed, p1);
				oldScale(elapsed, p2);
				oldScale(elapsed, gf);

			case 'NF':
				lerpScale(elapsed, rate, p1, true);
				lerpScale(elapsed, rate, p2, true);
				lerpScale(elapsed, rate, gf, true);

			default:
				lerpScale(elapsed, rate, p1, false);
				lerpScale(elapsed, rate, p2, false);
				lerpScale(elapsed, rate, gf, false);
		}

		updateHitbox(p1);
		updateHitbox(p2);
		updateHitbox(gf);
	}

	public static function position(bar:Bar, gfSinging:Bool, side:String, swap:Bool, p1:HealthIcon, p2:HealthIcon, gf:HealthIcon):Void
	{
		final offset:Int = 26;
		if (p1 != null)
			p1.x = bar.barCenter + (150 * p1.scale.x - 150) / 2 - offset;
		if (p2 != null)
			p2.x = bar.barCenter - (150 * p2.scale.x) / 2 - offset * 2;

		if (gf == null || !gf.visible)
			return;

		final singingSwap:Bool = swap && gfSinging;
		if (side == 'bf')
		{
			gf.x = bar.barCenter + (150 * gf.scale.x - 150) / 2 - offset + (singingSwap ? 0 : 75);
			if (singingSwap && p1 != null) p1.x += 75;
		}
		else if (side == 'dad')
		{
			gf.x = bar.barCenter - (150 * gf.scale.x) / 2 - offset * 2 - (singingSwap ? 0 : 75);
			if (singingSwap && p2 != null) p2.x -= 75;
		}
	}

	public static function frames(bar:Bar, opponentMode:Bool, side:String, p1:HealthIcon, p2:HealthIcon, gf:HealthIcon):Void
	{
		if (bar == null || !bar.enabled)
			return;

		final pct:Float = FlxMath.bound(bar.percent / 100, 0, 1);
		final bf:Float = opponentMode ? 1 - pct : pct;
		final dad:Float = opponentMode ? pct : 1 - pct;
		setFrame(p1, bf);
		setFrame(p2, dad);
		if (gf != null && gf.visible)
			setFrame(gf, side == 'bf' ? bf : dad);
	}

	static function oldScale(elapsed:Float, icon:HealthIcon):Void
	{
		if (icon != null && (icon.visible || icon.alpha > 0))
			icon.setGraphicSize(Std.int(FlxMath.lerp(150, icon.width, CoolUtil.boundTo(1 - (elapsed * 30), 0, 1))));
	}

	static function lerpScale(elapsed:Float, rate:Float, icon:HealthIcon, nf:Bool):Void
	{
		if (icon == null || !icon.visible)
			return;

		final t:Float = nf ? FlxMath.bound((1 - (elapsed * 9 * rate)) / 1.1, 0, 1) : Math.exp(-elapsed * 9 * rate);
		final value:Float = FlxMath.lerp(1, icon.scale.x, t);
		icon.scale.set(value, value);
	}

	static function updateHitbox(icon:HealthIcon):Void
	{
		if (icon != null)
			icon.updateHitbox();
	}

	static function setFrame(icon:HealthIcon, health:Float):Void
	{
		if (icon == null)
			return;
		if (icon.isAnimated)
		{
			icon.updateIconState(health);
			return;
		}
		if (icon.animation.curAnim != null)
			icon.animation.curAnim.curFrame = staticFrame(health, icon);
	}

	static function staticFrame(health:Float, icon:HealthIcon):Int
	{
		final count:Int = (icon.frames != null && icon.frames.frames != null) ? icon.frames.frames.length : 0;
		if (health < 0.2) return count > 1 ? 1 : 0;
		if (health > 0.8 && count > 2) return 2;
		return 0;
	}
}
