package vlc;

import vlc.VlcBitmap;
import openfl.display.BitmapData;
import openfl.display.Sprite;
import openfl.Lib;

class MP4Handler {
    public var video:VlcBitmap;
    public var bitmapData:BitmapData;
    public var sprite:Sprite;

    public function new(path:String) {
        video = new VlcBitmap(path);
        video.play();
        bitmapData = video.bitmapData;
        sprite = new Sprite();
        sprite.addChild(video);
        Lib.current.addChild(sprite);
    }

    public function playVideo() {
        video.play();
    }

    public function pauseVideo() {
        video.pause();
    }

    public function stopVideo() {
        video.stop();
        if (sprite != null && sprite.parent != null) {
            sprite.parent.removeChild(sprite);
        }
    }

    public function setVolume(vol:Float) {
        video.volume = vol;
    }

    public function setPosition(x:Float, y:Float) {
        sprite.x = x;
        sprite.y = y;
    }

    public function setSize(width:Int, height:Int) {
        video.width = width;
        video.height = height;
    }

    public function getBitmapData():BitmapData {
        return video != null ? video.bitmapData : null;
    }
}