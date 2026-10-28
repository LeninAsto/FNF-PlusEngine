#include "PlusNativeGeometry.h"

extern "C" void plus_affine2d_batch(double* xy, std::size_t vertex_count,
	double a, double b, double c, double d, double tx, double ty)
{
	if (xy == nullptr)
		return;

	for (std::size_t i = 0; i < vertex_count; ++i)
	{
		const std::size_t offset = i * 2;
		const double x = xy[offset];
		const double y = xy[offset + 1];
		xy[offset] = x * a + y * c + tx;
		xy[offset + 1] = x * b + y * d + ty;
	}
}
