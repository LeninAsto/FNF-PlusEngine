package lime.ui;

/**
 * Compatibility enum for Lime versions that only expose Window.vsync.
 */
enum abstract WindowVSyncMode(Int) from Int to Int
{
	var OFF = 0;
	var ON = 1;
	var ADAPTIVE = -1;
}
