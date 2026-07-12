package modchart.backend.standalone;

import flixel.FlxCamera;
import flixel.FlxSprite;

interface IAdapter {
	public function onModchartingInitialization():Void;
	public function onModchartingDispose():Void;

	// Song-related stuff
	public function getSongPosition():Float; // Current song position
	// public function getCrochet():Float           // Current beat crochet
	public function getCurrentBeat():Float; // Current beat
	public function getCurrentCrochet():Float; // Current beat
	public function getCurrentScrollSpeed():Float; // Current arrow scroll speed
	public function getBeatFromStep(step:Float):Float;

	// Arrow-related stuff
	public function getDefaultReceptorX(lane:Int, player:Int):Float; // Get default strum x position
	public function getDefaultReceptorY(lane:Int, player:Int):Float; // Get default strum y position
	public function getTimeFromArrow(arrow:FlxSprite):Float; // Get strum time for arrow
	public function isTapNote(sprite:FlxSprite):Bool; // If the sprite is an arrow, return true, if it is an lane/strum, return false
	public function isHoldEnd(sprite:FlxSprite):Bool; // If its the hold end
	public function arrowHit(sprite:FlxSprite):Bool; // If the arrow was hitted
	public function getHoldParentTime(sprite:FlxSprite):Float;

	/**
	 * Get the individual hold fragment length.
	 * 
	 * On most FNF engines, holds divided into fragments/tiles,
	 * each of them has a length of a step, so in this case, this
	 * function should return the length of a step.
	 * 
	 * Also on other FNF engines, the holds uses one single fragment
	 * (two actually, ond for the body and other for the end),
	 * so in that case, this should return the full hold length in ms.
	 * @param sprite : The hold arrow
	 * @return Float
	 */
	public function getHoldLength(sprite:FlxSprite):Float;

	public function getLaneFromArrow(sprite:FlxSprite):Int; // Get lane/note data from arrow
	public function getPlayerFromArrow(sprite:FlxSprite):Int; // Get player from arrow

	public function getKeyCount(?player:Int):Int; // Get total key count from specific player (4 for almost every engine)
	public function getPlayerCount():Int; // Get total player count (2 for almost every engine)

	// Get cameras to render the arrows (camHUD for almost every engine)
	public function getArrowCamera():Array<FlxCamera>;

	// Options section
	public function getHoldSubdivisions(item:FlxSprite):Int; // Hold resolution
	public function setHoldSubdivisions(value:Int):Void;    // Set hold resolution (used by adaptive FPS logic)
	public function getDownscroll():Bool; // Get if it is downscroll

	/**
	 * Get the every arrow/lane indexed by player.
	 * Example:
	 * [
	 *      [ // Player 0
	 *          [strum1, strum2...],
	 *          [arrow1, arrow2...],
	 *          [hold1, hold2....],
	 * 			[splash1, splash2....]
	 *      ],
	 *      [ // Player 2
	 *          [strum1, strum2...],
	 *          [arrow1, arrow2...],
	 *          [hold1, hold2....],
	 * 			[splash1, splash2....]
	 *      ]
	 * ]
	 * @return Array<Array<Array<FlxSprite>>>
	 */
	public function getArrowItems():Array<Array<Array<FlxSprite>>>;
}
