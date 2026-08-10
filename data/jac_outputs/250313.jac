"""Convert CVAT track data."""
def get_trackdata(tracks: list[dict[str, list[object]]]) -> dict[str, int | dict[int, int]] {
    trackdata = {};
    tracks_size = {};
    trackdata['tracks_number'] = len(tracks);
    for (id, track) in enumerate(tracks) {
        tracks_size[id] = len(track['box']);
    }
    trackdata['tracks_size'] = tracks_size;
    return trackdata;
}