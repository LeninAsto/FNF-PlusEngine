package objects;

import openfl.display.Bitmap;
import openfl.display.BitmapData;
import openfl.display.Sprite;
import backend.Paths;

class Watermark extends Sprite {
    public var bitmapData:BitmapData;
    public var bmp:Bitmap;

    public function new(xPos:Float = 0, yPos:Float = 0, alpha:Float = 1) {
        super();
        var flxGraphic = Paths.image("watermark");
        if (flxGraphic != null) {
            bitmapData = flxGraphic.bitmap;
            bmp = new Bitmap(bitmapData);
            bmp.smoothing = true;
            addChild(bmp);
            this.x = xPos;
            this.y = yPos;
            this.alpha = alpha;
        }
    }
}
