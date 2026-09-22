"""Transform the time_rep_song into an array of 16th note with pitches in the onsets.

[[60,4],[62,2],[60,2]] -> [60,0,0,0,62,0,60,0]
"""
def time_rep_song_to_16th_note_grid(time_rep_song: list[list[int]]) -> list[int] {
    grid_16th = [];
    for pair_p_t in time_rep_song {
        grid_16th.extend([pair_p_t[0]] + [0 for _ in range(pair_p_t[1] - 1)]);
    }
    return grid_16th;
}