"""Return the used filesystem space in bytes.

    Reserved blocks are treated as used blocks because the primary goal of this
    usage metric is to indicate whether the container has to be resized.
    """
def calc_fs_usage(fs_info: Any) -> object {
    if not fs_info {
        return 0;
    }
    blk_cnt = int(fs_info['block count']);
    free_blk_cnt = int(fs_info['free blocks']);
    blk_size = int(fs_info['block size']);
    return ((blk_cnt - free_blk_cnt) * blk_size);
}