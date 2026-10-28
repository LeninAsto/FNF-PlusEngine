#include "PlusNativeAudio.h"

#include <algorithm>
#include <cmath>

namespace {
	inline float sample16(const std::uint8_t* pcm, std::size_t offset)
	{
		const std::uint16_t raw = static_cast<std::uint16_t>(pcm[offset])
			| (static_cast<std::uint16_t>(pcm[offset + 1]) << 8);
		return static_cast<float>(static_cast<std::int16_t>(raw)) / 32768.0f;
	}
}

extern "C" int plus_waveform_peaks(const std::uint8_t* pcm, std::size_t byte_length, int channels,
	int start_frame, int end_frame, int max_rows, float multiply, float* output)
{
	if (pcm == nullptr || output == nullptr || channels <= 0 || max_rows <= 0)
		return 0;

	const std::size_t bytes_per_frame = static_cast<std::size_t>(channels) * 2;
	const int frame_count = static_cast<int>(byte_length / bytes_per_frame);
	start_frame = std::max(0, start_frame);
	end_frame = std::min(frame_count, end_frame);
	if (start_frame >= end_frame)
		return 0;

	const int frames_per_row = std::max(1, (end_frame - start_frame) / max_rows);
	float left_min = 0.0f;
	float left_max = 0.0f;
	float right_min = 0.0f;
	float right_max = 0.0f;
	int rows = 0;

	for (int frame = start_frame; frame < end_frame; ++frame)
	{
		const std::size_t offset = static_cast<std::size_t>(frame) * bytes_per_frame;
		const float left = sample16(pcm, offset);
		left_min = std::min(left_min, left);
		left_max = std::max(left_max, left);

		float right = left;
		if (channels >= 2)
			right = sample16(pcm, offset + 2);
		right_min = std::min(right_min, right);
		right_max = std::max(right_max, right);

		// Preserve the chart editor's established global-frame row boundaries.
		if (frame % frames_per_row == 0)
		{
			const int out = rows * 4;
			output[out] = std::abs(left_min) * multiply;
			output[out + 1] = left_max * multiply;
			output[out + 2] = std::abs(right_min) * multiply;
			output[out + 3] = right_max * multiply;
			left_min = left_max = right_min = right_max = 0.0f;
			if (++rows > max_rows)
				break;
		}
	}
	return rows;
}
