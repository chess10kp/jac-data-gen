"""Split the dataset according to some partition.

    Parameters
    ----------
    ds :

    partition :


    Returns
    -------

    """
def split(ds: Any, partition: Any) -> object {
    n_data = len(ds);
    partition = [int(((n_data * x) / sum(partition))) for x in partition];
    ds_batched = [];
    idx = 0;
    for p_size in partition {
        ds_batched.append(ds[idx:(idx + p_size)]);
        idx += p_size;
    }
    return ds_batched;
}