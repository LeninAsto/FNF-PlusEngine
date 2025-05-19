package backend;

import flixel.text.FlxText;
import flixel.tweens.FlxTween;
import flixel.util.FlxTimer;
import flixel.util.FlxColor;
import flixel.FlxG;

import backend.ClientPrefs;

class ComboPopup {
    public var comboTxt:FlxText;
    public var msTxt:FlxText;
    var comboTween:FlxTween = null;
    var msTween:FlxTween = null;
    var popupTimer:FlxTimer = null;
    var flickerTimer:FlxTimer = null;
    var flicker:Bool = false;
    var playbackRate:Float = 1.0;

    public function new(comboTxt:FlxText, msTxt:FlxText, ?playbackRate:Float = 1.0) {
        this.comboTxt = comboTxt;
        this.msTxt = msTxt;
        this.playbackRate = playbackRate;
    }

    public function show(noteRating:String, combo:Int, msOffset:Int) {
        // Color y texto según rating
        var ratingText = noteRating;
        var ratingColor = FlxColor.WHITE;
        switch (noteRating.toLowerCase()) {
            case "marvelous":
                ratingText = "Marvelous!!";
                ratingColor = 0xFFFFC800;
            case "sick":
                ratingText = "Sick!";
                ratingColor = 0xFF7FC9FF;
            case "good":
                ratingText = "Good";
                ratingColor = 0xFF7FFF8E;
            case "bad":
                ratingText = "Bad";
                ratingColor = 0xFFA17FFF;
            case "shit":
                ratingText = "Shit";
                ratingColor = 0xFFFF7F7F;
        }

        comboTxt.text = ratingText + "\nx" + combo;
        comboTxt.color = ratingColor;
        comboTxt.alpha = 1;
        comboTxt.visible = !ClientPrefs.data.hideHud;

        msTxt.text = msOffset + "ms";
        msTxt.color = ratingColor;
        msTxt.alpha = 1;
        msTxt.visible = !ClientPrefs.data.hideHud;

        // Posición según offset de ClientPrefs
        comboTxt.x = (FlxG.width - comboTxt.width) / 2 + ClientPrefs.data.comboOffset[0];
        comboTxt.y = (ClientPrefs.data.downScroll ? 100 : FlxG.height - 250) + ClientPrefs.data.comboOffset[1];
        msTxt.x = (FlxG.width - msTxt.width) / 2 + ClientPrefs.data.comboOffset[2];
        msTxt.y = comboTxt.y + comboTxt.height + 5 + ClientPrefs.data.comboOffset[3];

        // Reinicia timers
        if (popupTimer != null) popupTimer.cancel();
        if (flickerTimer != null) flickerTimer.cancel();
        flicker = false;

        popupTimer = new FlxTimer().start(0.5, function(_) {
            flicker = true;
            flickerTimer = new FlxTimer().start(1, function(_) {
                comboTxt.alpha = 0;
                msTxt.alpha = 0;
                flicker = false;
            });
        });

        bumpText(comboTxt, true);
        bumpText(msTxt, false);
    }

    public function showMiss(missCount:Int) {
        comboTxt.text = "Miss\nx-" + missCount;
        comboTxt.color = FlxColor.RED;
        comboTxt.alpha = 1;
        comboTxt.visible = !ClientPrefs.data.hideHud;

        msTxt.text = "--";
        msTxt.color = FlxColor.RED;
        msTxt.alpha = 1;
        msTxt.visible = !ClientPrefs.data.hideHud;

        // Posición según offset de ClientPrefs
        comboTxt.x = (FlxG.width - comboTxt.width) / 2 + ClientPrefs.data.comboOffset[0];
        comboTxt.y = (ClientPrefs.data.downScroll ? 100 : FlxG.height - 250) + ClientPrefs.data.comboOffset[1];
        msTxt.x = (FlxG.width - msTxt.width) / 2 + ClientPrefs.data.comboOffset[2];
        msTxt.y = comboTxt.y + comboTxt.height + 5 + ClientPrefs.data.comboOffset[3];

        if (popupTimer != null) popupTimer.cancel();
        if (flickerTimer != null) flickerTimer.cancel();
        flicker = false;

        popupTimer = new FlxTimer().start(0.5, function(_) {
            flicker = true;
            flickerTimer = new FlxTimer().start(1, function(_) {
                comboTxt.alpha = 0;
                msTxt.alpha = 0;
                flicker = false;
            });
        });

        bumpText(comboTxt, true);
        bumpText(msTxt, false);
    }
    
    public function bumpText(txt:FlxText, ?isCombo:Bool = false) {
        if (isCombo) {
            if (comboTween != null) comboTween.cancel();
            txt.scale.set(1.8, 1.8);
            comboTween = FlxTween.tween(txt.scale, {x: 1.1, y: 1.1}, 0.3 / playbackRate, {ease: flixel.tweens.FlxEase.expoOut});
        } else {
            if (msTween != null) msTween.cancel();
            txt.scale.set(1.8, 1.8);
            msTween = FlxTween.tween(txt.scale, {x: 1.1, y: 1.1}, 0.3 / playbackRate, {ease: flixel.tweens.FlxEase.expoOut});
        }
    }

    public function onStepHit(curStep:Int) {
        if (flicker) {
            if (curStep % 2 == 0) {
                comboTxt.alpha = 1;
                msTxt.alpha = 1;
            } else {
                comboTxt.alpha = 0;
                msTxt.alpha = 0;
            }
        }
    }
}

