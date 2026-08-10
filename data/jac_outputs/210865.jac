"""
    :param chrompairs:
    :param select:
    :param which:
    :return:
    """
def filter_hdf_paths(chrompairs: Any, select: Any, which: Any) -> object {
    if (which == 'target') {
        load_paths = [
            t[2]
            for t in chrompairs
            if (t[1] == select)
        ];
    } elif (which == 'query') {
        load_paths = [
            t[2]
            for t in chrompairs
            if (t[0] == select)
        ];
    } else {
        raise ValueError(
            'Reference has to be specified as target or query, not as {}'.format(which)
        );
    }
    return load_paths;
}