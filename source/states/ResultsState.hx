package states;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.util.FlxStringUtil;
import backend.MusicBeatState;
import backend.Paths;
import backend.LocaleUtils;
import backend.Language;
import backend.Controls;
import backend.Difficulty;
import backend.Mods;
import states.FreeplayState;
import states.StoryMenuState;
import states.MainMenuState;
import sys.io.File;
import sys.FileSystem;

#if mobile
import mobile.backend.TouchUtil;
#end

#if MODS_ALLOWED
import backend.Mods;
#end

class ResultsState extends MusicBeatState
{
    public var menuBG:FlxSprite;
    public var backdropImage:FlxSprite;
    public var flxGroupImage:FlxSprite;
    public var songInstrumental:String = "";
    public var canRetry:Bool = true;
    public var params:Dynamic;

    public var animatedScore:Int = 0;
    public var animatedFlawlesss:Int = 0;
    public var animatedSicks:Int = 0;
    public var animatedGoods:Int = 0;
    public var animatedBads:Int = 0;
    public var animatedShits:Int = 0;
    public var animatedMisses:Int = 0;
    public var animatedCombo:Int = 0;
    public var animatedAccuracy:Float = 0;

    public var scoreText:FlxText;
    public var flawlesss:FlxText;
    public var sicks:FlxText;
    public var goods:FlxText;
    public var bads:FlxText;
    public var shits:FlxText;
    public var misses:FlxText;
    public var comboText:FlxText;
    public var accText:FlxText;

    public static var use24HourFormat:Null<Bool> = true;
    public static var dateFormat:String = "MM/DD/YYYY";
    public static var timeFormat:String = "HH:mm";

    public function new(params:Dynamic)
    {
        super();
        this.params = params;

        LocaleUtils.loadDeviceDateTimeSettings();
    }

    override public function create()
    {
        super.create();

        #if MODS_ALLOWED
        if (params.isMod && params.modFolder != null && params.modFolder != "") {
            backend.Mods.currentModDirectory = params.modFolder;
        }
        #end

        menuBG = new FlxSprite();
        menuBG.loadGraphic(Paths.image('menuBG'));
        menuBG.setGraphicSize(FlxG.width, FlxG.height);
        menuBG.updateHitbox();
        menuBG.alpha = 1.0;
        add(menuBG);

        backdropImage = new FlxSprite();
        backdropImage.loadGraphic(Paths.image('ui/backdrop'));
        backdropImage.setGraphicSize(FlxG.width, FlxG.height + 1);
        backdropImage.updateHitbox();
        backdropImage.alpha = 0.8;
        add(backdropImage);

        flxGroupImage = new FlxSprite();
        flxGroupImage.loadGraphic(Paths.image('ui/flxgroup'));
        flxGroupImage.setGraphicSize(FlxG.width, FlxG.height + 1);
        flxGroupImage.updateHitbox();
        flxGroupImage.alpha = 0.4;
        add(flxGroupImage);

        if (!FlxG.sound.music.playing || FlxG.sound.music.length <= 0) {
            FlxG.sound.playMusic(Paths.music('freakyMenu'), 0.7, true);
        }

        var infoWidth = 700;
        var songAndDiff = '${params.songName} [${params.difficulty}]';
        var modOrGame = params.isMod && params.modFolder != null && params.modFolder != "" ? params.modFolder : "Friday Night Funkin'";
        var now = Date.now();

        var dateStr = LocaleUtils.formatDateTimeAccordingToDevice(now);
        
        var resulText = new FlxText(500, 12, infoWidth, Language.getPhrase('results_title', 'Results'), 60);
        resulText.setFormat(Paths.font("aller.ttf"), 60, FlxColor.WHITE, "right");
        add(resulText);

        var topText = new FlxText(10, 5, infoWidth, songAndDiff, 28);
        topText.setFormat(Paths.font("aller.ttf"), 28, FlxColor.WHITE, "left");
        add(topText);

        var modText = new FlxText(10, 39, infoWidth, modOrGame, 22);
        modText.setFormat(Paths.font("aller.ttf"), 22, FlxColor.WHITE, "left");
        add(modText);

        var playedText = new FlxText(10, 65, infoWidth, Language.getPhrase('results_played_on', 'Played on') + ' $dateStr', 18);
        playedText.setFormat(Paths.font("aller.ttf"), 18, FlxColor.WHITE, "left");
        add(playedText);

        var scoreY = 130;
        var scoreStr = StringTools.lpad("0", "0", 8);
        var scoreLabel = new FlxText(60, scoreY, 400, Language.getPhrase('results_score', 'Score') + ':', 34);
        scoreLabel.setFormat(Paths.font("aller.ttf"), 34, FlxColor.WHITE, "left");
        add(scoreLabel);

        scoreText = new FlxText(240, scoreY - 10, 400, scoreStr, 44);
        scoreText.setFormat(Paths.font("aller.ttf"), 44, FlxColor.WHITE, "left");
        add(scoreText);

        var leftX = 30;
        var rightX = 300;
        var judgY = 235;
        var judgSpacing = 90; // Más espacio

        flawlesss = new FlxText(leftX, judgY, 340, Language.getPhrase('judgement_flawlesss', 'flawlesss') + ': 0', 32);
        flawlesss.setFormat(Paths.font("aller.ttf"), 32, 0xFFA17FFF, "left");
        add(flawlesss);

        sicks = new FlxText(rightX, judgY, 340, Language.getPhrase('judgement_sicks', 'Sicks') + ': 0', 32);
        sicks.setFormat(Paths.font("aller.ttf"), 32, 0xFF7FC9FF, "left");
        add(sicks);

        goods = new FlxText(leftX, judgY + judgSpacing, 340, Language.getPhrase('judgement_goods', 'Goods') + ': 0', 32);
        goods.setFormat(Paths.font("aller.ttf"), 32, 0xFF7FFF8E, "left");
        add(goods);

        bads = new FlxText(rightX, judgY + judgSpacing, 340, Language.getPhrase('judgement_bads', 'Bads') + ': 0', 32);
        bads.setFormat(Paths.font("aller.ttf"), 32, 0xFF888888, "left");
        add(bads);

        shits = new FlxText(leftX, judgY + judgSpacing * 2, 340, Language.getPhrase('judgement_shits', 'Shits') + ': 0', 32);
        shits.setFormat(Paths.font("aller.ttf"), 32, 0xFFFF7F7F, "left");
        add(shits);

        misses = new FlxText(rightX, judgY + judgSpacing * 2, 340, Language.getPhrase('judgement_misses', 'Misses') + ': 0', 32);
        misses.setFormat(Paths.font("aller.ttf"), 32, FlxColor.RED, "left");
        add(misses);

        comboText = new FlxText(leftX, judgY + judgSpacing * 3 - 14, 700, Language.getPhrase('judgement_max_combo', 'Highest Combo') + ': 0', 26);
        comboText.setFormat(Paths.font("aller.ttf"), 32, FlxColor.WHITE, "left");
        add(comboText);

        accText = new FlxText(leftX, judgY + judgSpacing * 3 + 20, 700, Language.getPhrase('results_accuracy', 'Accuracy') + ': 0%', 26);
        accText.setFormat(Paths.font("aller.ttf"), 32, FlxColor.WHITE, "left");
        add(accText);

        var ratingLetter = params.ratingName != null ? params.ratingName : "";
        var ratingFC = params.ratingFC != null ? params.ratingFC : "";
        var ratingW = 400;
        var ratingX = FlxG.width - 525; 
        var ratingY = judgY + 25;
        var ratingText = new FlxText(ratingX, ratingY, ratingW, ratingLetter, 70);
        ratingText.setFormat(Paths.font("aller.ttf"), 70, FlxColor.YELLOW, "center");
        add(ratingText);

        var fcText = new FlxText(ratingX, ratingY + 90, ratingW, ratingFC, 54); 
        fcText.setFormat(Paths.font("aller.ttf"), 54, FlxColor.CYAN, "center");
        add(fcText);

        var yBottom = FlxG.height - 110;
        if (params.isPractice != null && params.isPractice) {
            var practiceText = new FlxText(0, yBottom, FlxG.width, Language.getPhrase('results_practice_mode', 'Played in practice mode'), 22);
            practiceText.setFormat(Paths.font("aller.ttf"), 22, FlxColor.YELLOW, "center");
            add(practiceText);
            yBottom += 28;
        }

        var engineInfo = Language.getPhrase('psych_engine_version', 'Psych Engine v') + MainMenuState.psychEngineVersion + "\n" + Language.getPhrase('fnf_version', 'Friday Night Funkin\' v') + "0.2.8";
        var engineText = new FlxText(0, FlxG.height - 100, FlxG.width, engineInfo, 25);
        engineText.setFormat(Paths.font("aller.ttf"), 25, FlxColor.CYAN, "center");
        add(engineText);

        #if mobile
        var continueText = new FlxText(50, FlxG.height - 75, 0, Language.getPhrase('results_press_enter_mobile', 'Press A\nto Continue'), 26);
        #else
        var continueText = new FlxText(50, FlxG.height - 75, 0, Language.getPhrase('results_press_enter', 'Press Enter\nto Continue'), 26);
        #end
        continueText.setFormat(Paths.font("aller.ttf"), 26, FlxColor.WHITE, "center");
        add(continueText);

        #if mobile
        addTouchPad('NONE', 'A');
        #end
    }

    override public function update(elapsed:Float)
    {
        super.update(elapsed);

        if (animatedScore < params.score) {
            animatedScore += Math.ceil((params.score - animatedScore) * 0.2 + 1);
            if (animatedScore > params.score) animatedScore = params.score;
            scoreText.text = StringTools.lpad(Std.string(animatedScore), "0", 8);
            return;
        }
        scoreText.text = StringTools.lpad(Std.string(animatedScore), "0", 8);

        if (animatedFlawlesss < params.flawlesss) {
            animatedFlawlesss = animateInt(animatedFlawlesss, params.flawlesss);
            flawlesss.text = Language.getPhrase('judgement_flawlesss', 'Flawlesss') + ': $animatedFlawlesss';
            return;
        }
        flawlesss.text = Language.getPhrase('judgement_flawlesss', 'Flawlesss') + ': $animatedFlawlesss';
        if (animatedSicks < params.sicks) {
            animatedSicks = animateInt(animatedSicks, params.sicks);
            sicks.text = Language.getPhrase('judgement_sicks', 'Sicks') + ': $animatedSicks';
            return;
        }
        sicks.text = Language.getPhrase('judgement_sicks', 'Sicks') + ': $animatedSicks';

        if (animatedGoods < params.goods) {
            animatedGoods = animateInt(animatedGoods, params.goods);
            goods.text = Language.getPhrase('judgement_goods', 'Goods') + ': $animatedGoods';
            return;
        }
        goods.text = Language.getPhrase('judgement_goods', 'Goods') + ': $animatedGoods';

        if (animatedBads < params.bads) {
            animatedBads = animateInt(animatedBads, params.bads);
            bads.text = Language.getPhrase('judgement_bads', 'Bads') + ': $animatedBads';
            return;
        }
        bads.text = Language.getPhrase('judgement_bads', 'Bads') + ': $animatedBads';

        if (animatedShits < params.shits) {
            animatedShits = animateInt(animatedShits, params.shits);
            shits.text = Language.getPhrase('judgement_shits', 'Shits') + ': $animatedShits';
            return;
        }
        shits.text = Language.getPhrase('judgement_shits', 'Shits') + ': $animatedShits';

        if (animatedMisses < params.misses) {
            animatedMisses = animateInt(animatedMisses, params.misses);
            misses.text = Language.getPhrase('judgement_misses', 'Misses') + ': $animatedMisses';
            return;
        }
        misses.text = Language.getPhrase('judgement_misses', 'Misses') + ': $animatedMisses';

        if (animatedCombo < params.maxCombo) {
            animatedCombo = animateInt(animatedCombo, params.maxCombo);
            comboText.text = Language.getPhrase('judgement_max_combo', 'Highest Combo') + ': $animatedCombo';
            return;
        }
        comboText.text = Language.getPhrase('judgement_max_combo', 'Highest Combo') + ': $animatedCombo';

        if (animatedAccuracy < params.accuracy) {
            animatedAccuracy += (params.accuracy - animatedAccuracy) * 0.2 + 0.1;
            if (animatedAccuracy > params.accuracy) animatedAccuracy = params.accuracy;
            
            var accPercent:Float = Math.round(animatedAccuracy * 1000) / 10;
            accText.text = Language.getPhrase('results_accuracy', 'Accuracy') + ': ' + Std.string(accPercent) + '%';
            return;
        }
        
        var accPercent:Float = Math.round(animatedAccuracy * 1000) / 10;
        accText.text = Language.getPhrase('results_accuracy', 'Accuracy') + ': ' + Std.string(accPercent) + '%';

        var shouldContinue:Bool = false;
        
        if (FlxG.keys.justPressed.ENTER) shouldContinue = true;
        
        if (controls.ACCEPT) shouldContinue = true;
        
        #if mobile
        if (TouchUtil.justPressed) shouldContinue = true;
        
        if (FlxG.touches.getFirst() != null && FlxG.touches.getFirst().justPressed) shouldContinue = true;
        #end
        
        if (shouldContinue)
        {
            #if MODS_ALLOWED
            backend.Mods.currentModDirectory = '';
            #end
            
            // Si es una semana completa, regresar al Story Menu, sino al Freeplay
            if (params.isWeek != null && params.isWeek == true) {
                MusicBeatState.switchState(new StoryMenuState());
            } else {
                MusicBeatState.switchState(new FreeplayState());
            }
        }
    }

    function animateInt(current:Int, target:Int):Int {
        if (current < target)
            return current + Math.ceil((target - current) * 0.2 + 1);
        return target;
    }
}
