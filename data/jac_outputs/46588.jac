"""Returns a guess at a species based frames of known species and the
   frame with a detection having unknown species."""
def guess_species(known_species: dict[int, str], frame_id: int) -> str | None {
    known_frames = sorted(known_species.keys());
    if not known_frames {
        return None;
    }
    for (i, frame) in enumerate(known_frames) {
        if frame == frame_id {
            return known_species[frame];
        }
        if frame > frame_id {
            if i == 0 {
                return known_species[frame];
            }
            if known_species[frame] == known_species[known_frames[i - 1]] {
                return known_species[frame];
            }
            return None;
        }
    }
    return known_species[known_frames[-1]];
}