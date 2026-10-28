#pragma once

#include <cstddef>
#include <cstdint>

extern "C" {
	int plus_waveform_peaks(const std::uint8_t* pcm, std::size_t byte_length, int channels,
		int start_frame, int end_frame, int max_rows, float multiply, float* output);
}
