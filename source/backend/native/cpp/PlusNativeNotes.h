#pragma once

#include <cstddef>
#include <cstdint>

extern "C" {
	void plus_note_windows_batch(const double* strum_times, const double* late_hit_mults,
		const double* early_hit_mults, const std::uint8_t* states, std::uint8_t* output,
		std::size_t count, double song_position, double safe_zone_offset);
}
