#pragma once

#include <cstddef>

extern "C" {
	int plus_native_api_version();

	void plus_wave_batch(const float* input, float* output, std::size_t count,
		double time, double frequency, double amplitude);
}
