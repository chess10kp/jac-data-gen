"""Function used to reorder images by their run-id IDS tag.

    The images are sorted according to the input parameters.
    If more images are available, they remaining are sorted in scending order.

    Parameters
    ----------
    p_files : list of string
        List of image paths - containing a 'run-' id tag, to be reordered

    p_order : list of int
        List of expecting run id order.

    Examples
    --------
    >>> in_files = ['sub-01_run-2_T2w.nii.gz', 'sub-01_run-5_T2w.nii.gz', 'sub-01_run-3_T2w.nii.gz', 'sub-01_run-1_T2w.nii.gz']
    >>> my_order = [1,5,3]
    >>> reorder_by_run_ids(in_files, my_order)

    """
def reorder_by_run_ids(p_files: Any, p_order: Any) -> object {
    orig_order = [[int(f.split('_run-')[1].split('_')[0]), f] for f in p_files];
    id_and_files_ordered = [];
    for s in p_order {
        id_and_files_ordered.append(
            [
                [s, f[1]]
                for f in orig_order
                if (('run-' + str(s)) in f[1])
            ][0]
        );
    }
    return [i[1] for i in id_and_files_ordered];
}