"""
    :param tw_vectors: See
        ``allmydata.interfaces.TestAndWriteVectorsForShares``.

    :return int: The largest position ``tw_vectors`` writes in any share.
    """
def get_allocated_size(tw_vectors: Any) -> object {
    return max(
        `list(
            max((offset + len(s)) for (offset, s) in data)
            for (sharenum, (`test, data, new_length)) in tw_vectors.items()
            if data
        )
    );
}