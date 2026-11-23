#include "PlusNativeNotes.h"

namespace {
	constexpr std::uint8_t state_was_good_hit = 1;
	constexpr std::uint8_t state_already_too_late = 2;
	constexpr std::uint8_t output_can_be_hit = 1;
	constexpr std::uint8_t output_too_late = 2;
}

extern "C" void plus_note_windows_batch(const double* strum_times, const double* late_hit_mults,
	const double* early_hit_mults, const std::uint8_t* states, std::uint8_t* output,
	std::size_t count, double song_position, double safe_zone_offset)
{
	if (strum_times == nullptr || late_hit_mults == nullptr || early_hit_mults == nullptr
		|| states == nullptr || output == nullptr)
		return;

	const double late_limit = song_position - safe_zone_offset;
	for (std::size_t i = 0; i < count; ++i)
	{
		const double time = strum_times[i];
		std::uint8_t result = 0;
		if (time > song_position - safe_zone_offset * late_hit_mults[i]
			&& time < song_position + safe_zone_offset * early_hit_mults[i])
			result |= output_can_be_hit;
		if ((states[i] & state_already_too_late) != 0
			|| (time < late_limit && (states[i] & state_was_good_hit) == 0))
			result |= output_too_late;
		output[i] = result;
	}
}
