#include "PlusNativeMath.h"

#include <cmath>

extern "C" int plus_native_api_version()
{
	return 3;
}

extern "C" void plus_wave_batch(const float* input, float* output, std::size_t count,
	double time, double frequency, double amplitude)
{
	if (input == nullptr || output == nullptr)
		return;

	for (std::size_t i = 0; i < count; ++i)
	{
		const double value = input[i];
		output[i] = static_cast<float>(value + std::sin((value + time) * frequency) * amplitude);
	}
}
