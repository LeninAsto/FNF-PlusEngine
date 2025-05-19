package substates;

import flixel.FlxG;
import flixel.FlxSubState;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.FlxSprite;
import openfl.utils.Assets;
import states.FreeplayState;
import states.StoryMenuState;
import DateTools;

class ResultsSubState extends FlxSubState
{
    var fromFreeplay:Bool;
    var fromStory:Bool;
    var isPractice:Bool;
    var bgImage:FlxSprite;
    var blackFade:FlxSprite;
    var isMod:Bool;
    var modFolder:String = "";

    public function new(
        score:Int,
        prevHighScore:Int,
        accuracy:Float,
        marvelous:Int, // <--- Nuevo
        sicks:Int,
        goods:Int,
        bads:Int,
        shits:Int,
        misses:Int,
        maxCombo:Int,
        totalNotes:Int,
        songName:String,
        difficulty:String,
        isMod:Bool,
        modFolder:String = "",
        fromFreeplay:Bool = false,
        fromStory:Bool = false,
        isPractice:Bool = false
    )
    {
        super();
        this.fromFreeplay = fromFreeplay;
        this.fromStory = fromStory;
        this.isPractice = isPractice;
        this.isMod = isMod;
        this.modFolder = modFolder;

        // 1. Música de resultados (apenas entra)
        playFreakyMenuMusic(isMod, modFolder);

        // 2. Imagen de fondo progresiva (opcional, puedes quitar si no la quieres)
        bgImage = new FlxSprite().loadGraphic("assets/images/menuBG.png");
        bgImage.setGraphicSize(FlxG.width, FlxG.height);
        bgImage.updateHitbox();
        bgImage.alpha = 1; // Ya no fadea, el fade será el negro
        bgImage.cameras = [FlxG.cameras.list[0]];
        add(bgImage);

        // 3. Fondo negro encima, fade in, en cámara other
        blackFade = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
        blackFade.scrollFactor.set();
        blackFade.alpha = 0; // Empieza transparente
        blackFade.cameras = [FlxG.cameras.list[FlxG.cameras.list.length-1]]; // Cámara other
        add(blackFade);

        // 4. Texto de resultados (encima del negro)
        var now = Date.now();
        var hour = StringTools.lpad(Std.string(now.getHours()), "0", 2);
        var minute = StringTools.lpad(Std.string(now.getMinutes()), "0", 2);
        var day = now.getDate();
        var dayName = DateTools.format(now, "%A");
        var monthName = DateTools.format(now, "%B");
        var year = now.getFullYear();
        var dateText = '$hour:$minute - $dayName, $monthName $day, $year';

        var gameName = isMod ? modFolder : "Friday Night Funkin'";
        var songText = '$songName [$difficulty]';

        function abbreviateScore(score:Int):String {
            if (score >= 1_000_000)
                return Std.string(Math.fround(score / 100_000) / 10) + "M";
            else if (score >= 1_000)
                return Std.string(Math.fround(score / 100) / 10) + "K";
            else
                return '$score';
        }

        var scoreAbbr = abbreviateScore(score);
        var accuracyText = 'Accuracy: ' + StringTools.lpad(Std.string(Math.round(accuracy * 100) / 100), "0", 4) + '%';

        var scoreText = 'Score: $score ($scoreAbbr)';
        if (score > prevHighScore) scoreText += " - New High Score!";

        // Marvelous agregado
        var notesTextArr = [
            'Marvelous: $marvelous',
            'Sicks: $sicks',
            'Goods: $goods',
            'Bads: $bads',
            'Shits: $shits',
            'Misses: $misses'
        ];
        var comboText = 'Highest Combo: $maxCombo / $totalNotes';

        var y = 60;
        var spacing = 36;

        function vcrText(str:String, y:Int, size:Int = 24, color:Int = FlxColor.WHITE):FlxText {
            var t = new FlxText(0, y, FlxG.width, str, size);
            t.setFormat("vcr.ttf", size, color, "center");
            t.cameras = [FlxG.cameras.list[FlxG.cameras.list.length-1]]; // Cámara other
            return t;
        }

        add(vcrText(dateText, y)); y += spacing;
        add(vcrText(gameName, y, 40)); y += spacing + 10;

        // Canción y dificultad más pequeño, dificultad con color
        var diffColor = FlxColor.WHITE;
        switch(difficulty.toLowerCase()) {
            case "easy": diffColor = FlxColor.LIME;
            case "normal": diffColor = FlxColor.YELLOW;
            case "hard": diffColor = FlxColor.RED;
            case "erect": diffColor = FlxColor.PINK;
            case "nightmare": diffColor = FlxColor.PURPLE;
            default: // Opcional: agregar más dificultades aquí
        }
            // Puedes agregar más dificultades aquí
        
        add(vcrText(songName, y, 28)); 
        add(vcrText('[$difficulty]', y + 28, 28, diffColor));
        y += spacing + 28;

        // Espacio extra
        y += 10;

        // Score, accuracy, combo, etc.
        add(vcrText(scoreText, y)); y += spacing;
        add(vcrText(accuracyText, y)); y += spacing;
        var ratingsList = [
            { label: 'Marvelous', value: marvelous, key: "marvelous" },
            { label: 'Sicks',     value: sicks,     key: "sicks"     },
            { label: 'Goods',     value: goods,     key: "goods"     },
            { label: 'Bads',      value: bads,      key: "bads"      },
            { label: 'Shits',     value: shits,     key: "shits"     },
            { label: 'Misses',    value: misses,    key: "misses"    }
        ];

        for (rating in ratingsList) {
            add(vcrText('${rating.label}: ${rating.value}', y, 24, ratingColors.get(rating.key)));
            y += spacing;
        }
        add(vcrText(comboText, y)); y += spacing;

        // Texto de práctica
        if (isPractice) {
            var practiceText = new FlxText(10, 10, 0, "Played in practice mode", 18);
            practiceText.setFormat("vcr.ttf", 18, FlxColor.YELLOW, "left");
            practiceText.cameras = [FlxG.cameras.list[FlxG.cameras.list.length-1]];
            add(practiceText);
        }

        // Texto de continuar
        var continueText = new FlxText(0, FlxG.height - 48, FlxG.width, "Press ENTER or ESC to continue", 20);
        continueText.setFormat("vcr.ttf", 20, FlxColor.GRAY, "center");
        continueText.cameras = [FlxG.cameras.list[FlxG.cameras.list.length-1]];
        add(continueText);
    }

    override public function update(elapsed:Float)
    {
        super.update(elapsed);
        // Fade in progresivo del fondo negro
        if (blackFade.alpha < 1) {
            blackFade.alpha += elapsed * 0.7; // Ajusta la velocidad aquí
            if (blackFade.alpha > 1) blackFade.alpha = 1;
        }
        if (FlxG.keys.justPressed.ENTER || FlxG.keys.justPressed.ESCAPE) {
            playFreakyMenuMusic(isMod, modFolder);
            if (fromFreeplay)
                FlxG.switchState(new FreeplayState());
            else
                close();
        }
    }

    function playFreakyMenuMusic(isMod:Bool, modFolder:String)
    {
        var tried = false;
        var path = isMod ? 'mods/$modFolder/music/freakymenu' : 'assets/music/freakymenu';
        if (Assets.exists(path + ".ogg")) {
            FlxG.sound.playMusic(path + ".ogg", 1, true);
            tried = true;
        }
        if (!tried && Assets.exists("assets/shared/music/freakymenu.ogg")) {
            FlxG.sound.playMusic("assets/shared/music/freakymenu.ogg", 1, true);
            tried = true;
        }
        if (!tried && Assets.exists("assets/music/freakymenu.ogg")) {
            FlxG.sound.playMusic("assets/music/freakymenu.ogg", 1, true);
        }
    }

    var ratingColors:Map<String, Int> = [
        "marvelous" => 0xFFFFC800,
        "sicks"     => 0xFF7FC9FF,
        "goods"     => 0xFF7FFF8E,
        "bads"      => 0xFFA17FFF,
        "shits"     => 0xFFFF7F7F,
        "misses"    => FlxColor.RED
    ];
}

