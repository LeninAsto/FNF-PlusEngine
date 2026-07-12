package modchart.backend.core;

enum abstract RotationOrder(String) from String to String {
	final X_Y_Z = "x_y_z";
	final X_Z_Y = "x_z_y";
	final Y_X_Z = "y_x_z";
	final Y_Z_X = "y_z_x";
	final Z_X_Y = "z_x_y";
	final Z_Y_X = "z_y_x";

	final X_Y_X = "x_y_x";
	final X_Z_X = "x_z_x";
	final Y_X_Y = "y_x_y";
	final Y_Z_Y = "y_z_y";
	final Z_X_Z = "z_x_z";
	final Z_Y_Z = "z_y_z";
}
