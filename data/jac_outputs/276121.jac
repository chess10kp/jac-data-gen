"""Process orig_data and add any ext_id matches as candidates."""
def populate_candidates(data: dict[str, dict[str, str | int | list[str] | None]]) -> dict[str, dict[str, str | int | None]] {
    candidates = {};
    for `entry in data.values() {
        if not `entry.get('ext_ids') {
            continue;
        }
        base_info = {
            'orig_photo_id': `entry.get('photo_id'),
            'orig_long_id': '{}/{}'.format(
                `entry.get('museum_obj'), `entry.get('db_id')
            ),
            'dupe_photo_id': None,
            'dupe_long_id': None
        };
        for ext_id in `entry.get('ext_ids') {
            candidates[ext_id] = base_info.copy();
            candidates[ext_id]['dupe_long_id'] = ext_id;
        }
    }
    return candidates;
}