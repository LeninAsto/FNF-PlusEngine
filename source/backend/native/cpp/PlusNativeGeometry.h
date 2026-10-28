#pragma once

#include <cstddef>

extern "C" {
	void plus_affine2d_batch(double* xy, std::size_t vertex_count,
		double a, double b, double c, double d, double tx, double ty);
}
