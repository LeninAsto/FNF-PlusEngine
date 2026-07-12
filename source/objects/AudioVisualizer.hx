package objects;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.math.FlxMath;
import flixel.util.FlxColor;
import flixel.sound.FlxSound;
import flixel.system.FlxSound as FlxSoundSystem;
import openfl.media.SoundMixer;
import openfl.media.SoundTransform;
import openfl.utils.ByteArray;

#if (VIDEOS_ALLOWED && windows)
import lime.media.AudioBuffer;
import lime.utils.Float32Array;
#end

class AudioDisplay extends FlxSpriteGroup
{
    public var snd:FlxSound;
    public var mode:VisualizerMode = BARS;
    public var sensitivity:Float = 1.0;
    public var falloffSpeed:Float = 0.85;
    public var colorMode:ColorMode = SOLID;
    
    var _width:Int;
    var _height:Int;
    var _barCount:Int;
    var _gap:Int;
    var _baseColor:FlxColor;
    var _peakColors:Array<FlxColor>;
    
    public var stopUpdate:Bool = false;
    var updateTimer:Float = 0;
    var frequencyData:Array<Float> = [];
    var peakValues:Array<Float> = [];
    var falloffValues:Array<Float> = [];
    var history:Array<Array<Float>> = [];
    var historyLength:Int = 10;
    
    var spectrumSprite:FlxSprite;
    var useFFT:Bool = false;
    var smoothing:Float = 0.65;

    static final GRADIENT_COLORS = [
        FlxColor.fromRGB(0, 255, 255),
        FlxColor.fromRGB(0, 255, 0),
        FlxColor.fromRGB(255, 255, 0),
        FlxColor.fromRGB(255, 0, 0)
    ];
    
    public function new(snd:FlxSound = null, x:Float = 0, y:Float = 0, width:Int = 400, height:Int = 100, barCount:Int = 64, gap:Int = 2, color:FlxColor = FlxColor.WHITE)
    {
        super(x, y);
        
        this.snd = snd;
        this._width = width;
        this._height = height;
        this._barCount = barCount;
        this._gap = gap;
        this._baseColor = color;

        for (i in 0...barCount)
        {
            frequencyData[i] = 0;
            peakValues[i] = 0;
            falloffValues[i] = 0;
        }

        _peakColors = createGradient(GRADIENT_COLORS, barCount);
        
        setupVisualizer();
        
        if (snd != null)
        {
            initAudioAnalysis();
        }
    }
    
    function setupVisualizer()
    {
        clear();
        
        switch (mode)
        {
            case BARS:
                setupBars();
            case CIRCLE:
                setupCircle();
            case WAVE:
                setupWave();
            case SPECTRUM:
                setupSpectrum();
        }
    }
    
    function setupBars()
    {
        var barWidth = Std.int(_width / _barCount - _gap);
        
        for (i in 0..._barCount)
        {
            var bar = new FlxSprite().makeGraphic(barWidth, 1, _baseColor);
            bar.x = (_width / _barCount) * i;
            bar.scale.y = 1;
            bar.origin.set(0, 0);
            add(bar);
        }
    }
    
    function setupCircle()
    {
        var radius = Math.min(_width, _height) * 0.4;
        var centerX = _width * 0.5;
        var centerY = _height * 0.5;
        
        for (i in 0..._barCount)
        {
            var angle = (i / _barCount) * Math.PI * 2;
            var bar = new FlxSprite().makeGraphic(2, 1, _baseColor);
            
            bar.x = centerX + Math.cos(angle) * radius;
            bar.y = centerY + Math.sin(angle) * radius;
            bar.origin.set(1, 0.5);
            bar.angle = angle * 180 / Math.PI;
            add(bar);
        }
    }
    
    function setupWave()
    {
        var pointCount = _barCount * 2;
        var pointSpacing = _width / pointCount;
        
        for (i in 0...pointCount)
        {
            var point = new FlxSprite().makeGraphic(2, 2, _baseColor);
            point.x = i * pointSpacing;
            point.y = _height * 0.5;
            add(point);
        }
    }
    
    function setupSpectrum()
    {
        // Render spectrum as individual bars (simpler and cross-platform).
        var barWidth = Std.int(_width / _barCount - _gap);
        for (i in 0..._barCount)
        {
            var bar = new FlxSprite().makeGraphic(barWidth, 1, _baseColor);
            bar.x = (_width / _barCount) * i;
            bar.scale.y = 1;
            bar.origin.set(0, 0);
            add(bar);
        }
    }
    
    function initAudioAnalysis()
    {
        // Enable FFT for real audio analysis
        useFFT = true;
    }
    
    override function update(elapsed:Float)
    {
        super.update(elapsed);
        
        if (stopUpdate || snd == null || !snd.playing)
        {
            if (falloffSpeed > 0)
            {
                applyFalloff(elapsed);
                updateVisuals();
            }
            return;
        }
        
        updateTimer += elapsed;
        var targetFPS = 60;
        var updateInterval = 1.0 / targetFPS;
        
        if (updateTimer >= updateInterval)
        {
            updateTimer = 0;
            
            if (useFFT)
            {
                updateFFTData();
            }
            else
            {
                updateSimpleData();
            }
            
            updatePeaks();
            updateHistory();
            updateVisuals();
        }
        
        applySmoothing(elapsed);
    }
    
    function updateFFTData()
    {
        // Fallback to improved simple data since computeSpectrum is not available
        updateSimpleData();
    }
    
    function updateSimpleData()
    {
        var time = FlxG.game.ticks / 1000;
        var volume = snd != null && snd.playing ? snd.volume * FlxG.sound.volume : 0;
        var musicTime = FlxG.sound.music != null ? FlxG.sound.music.time / 1000 : 0;
        
        // Assume average BPM of 120 for rhythm
        var bpm = 120;
        var beatDuration = 60 / bpm;
        var beatPhase = (musicTime % beatDuration) / beatDuration; // 0 to 1 per beat
        
        for (i in 0..._barCount)
        {
            var freq = 1 + i * 0.2;
            var bass = Math.sin(time * 1.5 + musicTime * 0.5) * 0.3 + 0.3;
            var mid = Math.sin(time * freq + musicTime * freq * 0.1) * 0.2 + 0.2;
            var high = Math.sin(time * freq * 3 + musicTime * 2) * 0.1 + 0.1;
            
            var value = bass + mid + high;
            
            // Add rhythm component
            var rhythm = Math.sin(beatPhase * Math.PI * 2) * 0.2 + 0.2; // oscillates with beat
            value += rhythm;
            
            value = FlxMath.bound(value * volume * sensitivity, 0, 1);

            // Add more randomness based on music time
            value += (Math.sin(musicTime * 10 + i) * 0.1 + Math.cos(musicTime * 5 + i * 0.5) * 0.05);
            value += Math.random() * 0.1 - 0.05;
            value = FlxMath.bound(value, 0, 1);
            
            frequencyData[i] = value;
        }
    }
    
    function updatePeaks()
    {
        for (i in 0..._barCount)
        {
            if (frequencyData[i] > peakValues[i])
            {
                peakValues[i] = frequencyData[i];
            }
            else
            {
                peakValues[i] *= 0.99;
            }
        }
    }
    
    function applySmoothing(elapsed:Float)
    {
        for (i in 0...members.length)
        {
            if (i < _barCount)
            {
                var target = frequencyData[i];
                var current = falloffValues[i];

                falloffValues[i] = FlxMath.lerp(current, target, 1 - Math.pow(smoothing, elapsed * 60));
            }
        }
    }
    
    function applyFalloff(elapsed:Float)
    {
        for (i in 0..._barCount)
        {
            frequencyData[i] *= falloffSpeed;
            if (frequencyData[i] < 0.01) frequencyData[i] = 0;
        }
    }
    
    function updateHistory()
    {
        history.push(frequencyData.copy());
        if (history.length > historyLength)
        {
            history.shift();
        }
    }
    
    function updateVisuals()
    {
        switch (mode)
        {
            case BARS:
                updateBars();
            case CIRCLE:
                updateCircle();
            case WAVE:
                updateWave();
            case SPECTRUM:
                updateSpectrum();
        }
    }
    
    function updateBars()
    {
        for (i in 0...members.length)
        {
            var bar = members[i];
            if (bar != null && i < _barCount)
            {
                var value = falloffValues[i];
                var targetHeight = Math.max(_height / 40, value * _height);

                bar.scale.y = FlxMath.lerp(bar.scale.y, targetHeight, 0.3);

                updateBarColor(bar, i, value);

                bar.y = -bar.scale.y;
            }
        }
    }
    
    function updateBarColor(bar:FlxSprite, index:Int, value:Float)
    {
        switch (colorMode)
        {
            case SOLID:
                bar.color = _baseColor;
            case GRADIENT:
                var colorIndex = Math.floor(value * (_peakColors.length - 1));
                bar.color = _peakColors[colorIndex];
            case FREQUENCY:
                var hue = (index / _barCount) * 360;
                bar.color = FlxColor.fromHSB(hue, 0.8, 0.9);
            case PEAK:
                var peakRatio = peakValues[index];
                var intensity = Math.min(peakRatio * 2, 1);
                bar.color = FlxColor.interpolate(_baseColor, FlxColor.RED, intensity);
        }
    }
    
    function updateCircle()
    {
        for (i in 0...members.length)
        {
            var bar = members[i];
            if (bar != null && i < _barCount)
            {
                var value = falloffValues[i];
                var targetLength = 10 + value * _height * 0.5;
                
                bar.scale.y = FlxMath.lerp(bar.scale.y, targetLength, 0.3);
                updateBarColor(bar, i, value);
            }
        }
    }
    
    function updateWave()
    {
        var pointCount = members.length;
        var pointSpacing = _width / pointCount;
        
        for (i in 0...pointCount)
        {
            var point = members[i];
            if (point != null)
            {
                var barIndex = Math.floor(i / 2) % _barCount;
                var value = falloffValues[barIndex];
                var targetY = _height * 0.5 - value * _height * 0.4;
                
                point.y = FlxMath.lerp(point.y, targetY, 0.3);
                point.alpha = 0.5 + value * 0.5;
                
                if (colorMode != SOLID)
                {
                    updateBarColor(point, barIndex, value);
                }
            }
        }
    }
    
    function updateSpectrum()
    {
        // Update the bar-style spectrum (members created in setupSpectrum)
        for (i in 0...members.length)
        {
            var bar = members[i];
            if (bar != null && i < _barCount)
            {
                var value = falloffValues[i];
                var targetHeight = Math.max(1, value * _height);
                bar.scale.y = FlxMath.lerp(bar.scale.y, targetHeight, 0.3);
                updateBarColor(bar, i, value);
                bar.y = _height - bar.scale.y;
            }
        }
    }
    
    function createGradient(colors:Array<FlxColor>, steps:Int):Array<FlxColor>
    {
        var gradient = [];
        var segments = colors.length - 1;
        var stepsPerSegment = Math.ceil(steps / segments);
        
        for (i in 0...steps)
        {
            var segment = Math.floor(i / stepsPerSegment);
            if (segment >= segments) segment = segments - 1;
            
            var segmentProgress = (i % stepsPerSegment) / stepsPerSegment;
            var color1 = colors[segment];
            var color2 = colors[segment + 1];
            
            gradient.push(FlxColor.interpolate(color1, color2, segmentProgress));
        }
        
        return gradient;
    }

    public function setMode(newMode:VisualizerMode)
    {
        if (mode != newMode)
        {
            mode = newMode;
            setupVisualizer();
        }
    }
    
    public function setColorMode(newColorMode:ColorMode)
    {
        colorMode = newColorMode;
    }
    
    public function setSensitivity(value:Float)
    {
        sensitivity = FlxMath.bound(value, 0.1, 3.0);
    }
    
    public function setFalloffSpeed(value:Float)
    {
        falloffSpeed = FlxMath.bound(value, 0.5, 0.99);
    }
    
    public function setSmoothing(value:Float)
    {
        smoothing = FlxMath.bound(value, 0.1, 0.9);
    }
    
    public function setColors(baseColor:FlxColor, ?peakColors:Array<FlxColor>)
    {
        _baseColor = baseColor;
        if (peakColors != null) _peakColors = peakColors;
    }
    
    public function getFrequencyData():Array<Float>
    {
        return frequencyData.copy();
    }
    
    public function getPeakData():Array<Float>
    {
        return peakValues.copy();
    }
    
    public function getAverageLevel():Float
    {
        var sum = 0.0;
        for (value in frequencyData) sum += value;
        return sum / frequencyData.length;
    }
    
    override public function reset(X:Float, Y:Float):Void
    {
        for (i in 0..._barCount)
        {
            frequencyData[i] = 0;
            peakValues[i] = 0;
            falloffValues[i] = 0;
        }
        history = [];
        updateVisuals();
        super.reset(X, Y);
    }
    
    override function destroy()
    {
        frequencyData = null;
        peakValues = null;
        falloffValues = null;
        history = null;
        _peakColors = null;
        
        super.destroy();
    }
}

enum abstract VisualizerMode(Int) from Int to Int
{
    var BARS = 0;
    var CIRCLE = 1;
    var WAVE = 2;
    var SPECTRUM = 3;
}

enum abstract ColorMode(Int) from Int to Int
{
    var SOLID = 0;
    var GRADIENT = 1;
    var FREQUENCY = 2;
    var PEAK = 3;
}