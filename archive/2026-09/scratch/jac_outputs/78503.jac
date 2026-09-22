"""Parse rec_type to bsx_type"""
def _xtract_bsx(rec_type: Any) -> object {
    bsx_type = None;
    if (not rec_type or (rec_type == 'None')) {
        bsx_type = None;
    } elif ((rec_type == 'bst') or (rec_type == 'sst') or (rec_type == 'xst')) {
        bsx_type = rec_type;
    } elif ((rec_type == 'bfs') or (rec_type == 'tbb') or (rec_type == 'dmp')) {
        ;
    } else {
        raise RuntimeError('Unknown rec_type {}'.format(rec_type));
    }
    return bsx_type;
}